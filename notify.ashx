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
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web;

public class NotifyHandler : IHttpHandler
{
    private const int Timeout = 40000;
    private static readonly object waitLock = new object();
    private static bool isWaiting = false;
    private static long lastServerId = 0;

    public void ProcessRequest(HttpContext context)
    {
        // get the last event id known to the client
        var lastEventId = context.Request.QueryString["lastEventId"];
        if (string.IsNullOrWhiteSpace(lastEventId))
            throw new ArgumentNullException("lastEventId");
        long lastClientId;
        if (!long.TryParse(lastEventId, NumberStyles.Integer, CultureInfo.InvariantCulture, out lastClientId))
            throw new ArgumentException(new FormatException().Message, "lastEventId");
        lock (waitLock)
            if (lastClientId < -1 || lastClientId > lastServerId)
                throw new ArgumentOutOfRangeException("lastEventId");

        // set the output encoding
        context.Response.ContentType = "application/json";
        context.Response.Charset = "UTF-8";

        // prepare the connection
        using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
        {
            // intialize the return variables and determine what to do
            long newLastServerId;
            var results = new DataTable();
            if (lastClientId == -1)
            {
                // query the latest id only
                connection.Open();
                using (var lastIdCommand = new SqlCommand("SELECT MAX(ID) FROM dbo.Version", connection))
                    newLastServerId = (long?)lastIdCommand.ExecuteScalar() ?? 0;
            }
            else
            {
                // initialize the version command
                using (var command = new SqlCommand("SELECT [ID], Zeile.value('local-name((/*)[1])','sysname') AS [Table], Zeile.value('(/*/ID)[1]','int') AS [Row], Zeile.value('(/*/Version)[1]','varbinary(8)') AS [Version] FROM dbo.Version WHERE ID > @ID", connection))
                {
                    command.Parameters.AddWithValue("ID", lastClientId);

                    // check if we need to wait
                    var doWaitHere = false;
                    lock (waitLock)
                    {
                        // only do something special if we know there are no newer records
                        if (lastClientId == lastServerId)
                        {
                            // if we're not waiting wait here, otherwise wait for the waiting client
                            if (!isWaiting)
                            {
                                isWaiting = true;
                                doWaitHere = true;
                            }
                            else
                                Monitor.Wait(waitLock);
                        }
                    }
                    try
                    {
                        // open the connection and add the notification if necessary
                        connection.Open();
                        if (doWaitHere)
                            command.Notification = new System.Data.Sql.SqlNotificationRequest(Guid.NewGuid().ToString(), "Service=SqlDependencyService", Timeout);

                        // execute the query
                        using (var reader = command.ExecuteReader())
                            results.Load(reader);

                        // check if we need to wait (also check if we can wait in case events have been deleted)
                        if (results.Rows.Count == 0 && doWaitHere)
                        {
                            // wait for a message and return if we've reached the timeout instead
                            bool hasEvents;
                            using (var waitCommand = new SqlCommand("WAITFOR (RECEIVE * FROM SqlDependencyQueue), TIMEOUT " + Timeout, connection))
                            {
                                waitCommand.CommandTimeout = Timeout / 500;
                                using (var reader = waitCommand.ExecuteReader())
                                    hasEvents = reader.HasRows;
                            }

                            // remove the notification and run the query again if new events arrived
                            if (hasEvents)
                            {
                                command.Notification = null;
                                using (var reader = command.ExecuteReader())
                                    results.Load(reader);
                            }
                        }

                        // update the last known server id
                        newLastServerId = results.Rows.Count > 0 ? results.AsEnumerable().Max(r => r.Field<long>("ID")) : lastClientId;
                    }
                    finally
                    {
                        // stop waiting and notify all other clients
                        if (doWaitHere)
                        {
                            lock (waitLock)
                            {
                                isWaiting = false;
                                Monitor.PulseAll(waitLock);
                            }
                        }
                    }
                }
            }

            // update the internal id
            lock (waitLock)
            {
                if (newLastServerId > lastServerId)
                    lastServerId = newLastServerId;
            }

            // notify the client
            context.Response.Write("{\"LastEventId\":");
            context.Response.Write(newLastServerId.ToString(CultureInfo.InvariantCulture));
            context.Response.Write(",\"Events\":{");
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
                    var lastRow = row.Last();
                    if (!lastRow.IsNull("Version"))
                    {
                        context.Response.Write("\"0x");
                        foreach (var b in lastRow.Field<byte[]>("Version"))
                            context.Response.Write(b.ToString("X2", CultureInfo.InvariantCulture));
                        context.Response.Write("\"");
                    }
                    else
                        context.Response.Write("null");
                }
                context.Response.Write("}");
            }
            context.Response.Write("}}");
        }
    }

    public bool IsReusable
    {
        get { return true; }
    }
}
