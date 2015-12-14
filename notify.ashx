<%@ WebHandler Language="C#" Class="NotifyHandler" %>

/* Copyright (C) 2015, Manuel Meitinger
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web;

public class NotifyHandler : IHttpHandler
{
    private const int NotificationTimeout = 40; // time a client waits in seconds
    private const int ReceiveTimeout = 60; // RECEIVE TIMEOUT in seconds
    private static readonly Dictionary<string, EventWaitHandle> WaitHandles = new Dictionary<string, EventWaitHandle>();
    private static bool IsRunning = false;

    static void Notify(object unused)
    {
        // ensure only one instance is running
        lock (WaitHandles)
        {
            if (IsRunning)
                return;
            IsRunning = true;
        }

        // open a connection and prepare the commands
        using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
        using (var waitCommand = new SqlCommand("WAITFOR (RECEIVE TOP (1) conversation_handle, CAST(message_body AS xml).value('declare namespace qn=\"http://schemas.microsoft.com/SQL/Notifications/QueryNotification\"; (/qn:QueryNotification/qn:Message)[1]','nvarchar(max)') FROM SqlDependencyQueue), TIMEOUT @Timeout", connection))
        using (var endCommand = new SqlCommand("END CONVERSATION @Conversation", connection))
        {
            connection.Open();
            var timeoutParam = waitCommand.Parameters.Add("Timeout", SqlDbType.Int);
            waitCommand.Prepare();
            var conversationParam = endCommand.Parameters.Add("Conversation", SqlDbType.UniqueIdentifier);
            endCommand.Prepare();

            // set the timeout
            waitCommand.CommandTimeout = ReceiveTimeout + ReceiveTimeout / 2;
            timeoutParam.Value = ReceiveTimeout * 1000;

            // repeat until there are no more waiting requests
            for (; ; )
            {
                lock (WaitHandles)
                {
                    if (WaitHandles.Count == 0)
                    {
                        IsRunning = false;
                        break;
                    }
                }

                // get the notification message
                string message;
                Guid conversation;
                using (var reader = waitCommand.ExecuteReader())
                {
                    if (!reader.Read())
                        continue;
                    message = !reader.IsDBNull(1) ? reader.GetString(1) : null;
                    conversation = reader.GetGuid(0);
                }

                // get and notify the wait handle
                if (message != null)
                {
                    EventWaitHandle waitHandle;
                    lock (WaitHandles)
                        if (WaitHandles.TryGetValue(message, out waitHandle))
                            waitHandle.Set();
                }

                // end the conversation
                conversationParam.Value = conversation;
                endCommand.ExecuteNonQuery();
            }
        }
    }

    public void ProcessRequest(HttpContext context)
    {
        // get the last event id known to the client
        var lastEventId = context.Request.QueryString["lastEventId"];
        if (string.IsNullOrWhiteSpace(lastEventId))
            throw new ArgumentNullException("lastEventId");
        long lastClientId;
        if (!long.TryParse(lastEventId, NumberStyles.Integer, CultureInfo.InvariantCulture, out lastClientId))
            throw new ArgumentException(new FormatException().Message, "lastEventId");
        if (lastClientId < -1)
            throw new ArgumentOutOfRangeException("lastEventId");

        // set the output encoding
        context.Response.ContentType = "application/json";
        context.Response.Charset = "UTF-8";

        // open the connection
        using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
        {
            connection.Open();

            // intialize the return variable and determine what to do
            var results = new DataTable();
            if (lastClientId == -1)
            {
                // query the latest id only
                using (var command = new SqlCommand("SELECT MAX(ID) FROM dbo.Version", connection))
                {
                    var result = command.ExecuteScalar();
                    lastClientId = result != DBNull.Value ? (long)result : 0;
                }
            }
            else
            {
                // initialize the version command and wait handle
                using (var notifyCommand = new SqlCommand("SELECT ID FROM dbo.Version WHERE ID > @ID", connection))
                using (var eventCommand = new SqlCommand("SELECT ID, Zeile.value('local-name((/*)[1])','sysname') AS [Table], Zeile.value('(/*/ID)[1]','int') AS [Row], Zeile.value('(/*/Version)[1]','varbinary(8)') AS [Version] FROM dbo.Version WHERE ID > @ID ORDER BY ID DESC", connection))
                using (var waitHandle = new ManualResetEvent(false))
                {
                    notifyCommand.Parameters.AddWithValue("ID", lastClientId);
                    eventCommand.Parameters.AddWithValue("ID", lastClientId);

                    // add the notification
                    var messageId = Guid.NewGuid().ToString();
                    notifyCommand.Notification = new System.Data.Sql.SqlNotificationRequest(messageId, "Service=SqlDependencyService", NotificationTimeout);
                    lock (WaitHandles)
                        WaitHandles.Add(messageId, waitHandle);
                    try
                    {
                        // execute the notification query
                        bool hasNewEvents;
                        using (var reader = notifyCommand.ExecuteReader())
                            hasNewEvents = reader.HasRows;

                        // check if no rows were returned
                        if (!hasNewEvents)
                        {
                            // ensure the dispatcher is started
                            if (!IsRunning)
                                ThreadPool.QueueUserWorkItem(Notify);

                            // wait for a notification
                            hasNewEvents = waitHandle.WaitOne(NotificationTimeout * 1000);
                        }

                        // receive the new events
                        if (hasNewEvents)
                        {
                            using (var reader = eventCommand.ExecuteReader())
                                results.Load(reader);
                            if (results.Rows.Count > 0)
                                lastClientId = results.AsEnumerable().First().Field<long>("ID");
                        }
                    }
                    finally
                    {
                        // remove the notify object
                        lock (WaitHandles)
                            WaitHandles.Remove(messageId);
                    }
                }
            }

            // notify the client
            context.Response.Write("{\"LastEventId\":");
            context.Response.Write(lastClientId.ToString(CultureInfo.InvariantCulture));
            context.Response.Write(",\"Events\":{");
            if (results.Rows.Count > 0)
            {
                var isFirstEvent = true;
                foreach (var table in results.AsEnumerable().GroupBy(r => r.Field<string>("Table"), StringComparer.Ordinal))
                {
                    if (isFirstEvent)
                        isFirstEvent = false;
                    else
                        context.Response.Write(',');
                    context.Response.Write("\"");
                    context.Response.Write(table.Key);
                    context.Response.Write("\":{");
                    var isFirstId = true;
                    foreach (var row in table.GroupBy(r => r.Field<int>("Row")))
                    {
                        if (isFirstId)
                            isFirstId = false;
                        else
                            context.Response.Write(',');
                        context.Response.Write("\"");
                        context.Response.Write(row.Key.ToString(CultureInfo.InvariantCulture));
                        context.Response.Write("\":");
                        var latestRow = row.First();
                        if (!latestRow.IsNull("Version"))
                        {
                            context.Response.Write("\"0x");
                            foreach (var b in latestRow.Field<byte[]>("Version"))
                                context.Response.Write(b.ToString("X2", CultureInfo.InvariantCulture));
                            context.Response.Write("\"");
                        }
                        else
                            context.Response.Write("null");
                    }
                    context.Response.Write("}");
                }
            }
            context.Response.Write("}}");
        }
    }

    public bool IsReusable
    {
        get { return true; }
    }
}
