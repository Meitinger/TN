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

        // set the output encoding
        context.Response.ContentType = "application/json";
        context.Response.Charset = "UTF-8";

        // prepare the connection
        using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
        using (var command = new SqlCommand("SELECT [ID], Zeile.value('local-name((/*)[1])','sysname') AS [Table], Zeile.value('(/*/ID)[1]','int') AS [Row] FROM dbo.Version WHERE ID > @ID", connection))
        {
            command.Parameters.AddWithValue("ID", lastClientId);

            // check if we need to wait
            long newLastServerId;
            var results = new DataTable();
            var doWaitHere = false;
            lock (waitLock)
            {
                // only do something special if we know there are no newer records
                if (lastServerId <= lastClientId)
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

                // check if we need to wait
                if (results.Rows.Count == 0)
                {

                    // return if we can't wait (this can only happen if events have been deleted)
                    if (!doWaitHere)
                        return;

                    // wait for a message and return if we've reached the timeout instead
                    using (var waitCommand = new SqlCommand("WAITFOR (RECEIVE CAST(message_body AS XML) FROM SqlDependencyQueue), TIMEOUT " + Timeout, connection))
                    {
                        waitCommand.CommandTimeout = Timeout / 500;
                        using (var reader = waitCommand.ExecuteReader())
                            if (!reader.HasRows)
                                return;
                    }

                    // remove the notification and run the query again
                    command.Notification = null;
                    using (var reader = command.ExecuteReader())
                        results.Load(reader);

                    // give up if we still got nothing (again, this should not happen)
                    if (results.Rows.Count == 0)
                        return;
                }

                // update the last known server id
                newLastServerId = results.AsEnumerable().Max(r => r.Field<long>("ID"));
                lock (waitLock)
                {
                    if (newLastServerId > lastServerId)
                        lastServerId = newLastServerId;
                }
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

            // notify the client
            context.Response.Write("{\"LastEventId\":");
            context.Response.Write(newLastServerId.ToString(CultureInfo.InvariantCulture));
            context.Response.Write(",\"Events\":{");
            var isFirstEvent = true;
            foreach (var group in results.AsEnumerable().GroupBy(r => r.Field<string>("Table"), StringComparer.Ordinal))
            {
                if (isFirstEvent)
                    isFirstEvent = false;
                else
                    context.Response.Write(',');
                context.Response.Write("\"");
                context.Response.Write(group.Key);
                context.Response.Write("\":[");
                var isFirstId = true;
                foreach (var id in group.Select(r => r.Field<int>("Row")).Distinct())
                {
                    if (isFirstId)
                        isFirstId = false;
                    else
                        context.Response.Write(',');
                    context.Response.Write(id.ToString(CultureInfo.InvariantCulture));
                }
                context.Response.Write("]");
            }
            context.Response.Write("}}");
        }
    }

    public bool IsReusable
    {
        get { return true; }
    }
}
