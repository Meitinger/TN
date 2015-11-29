<%@ WebHandler Language="C#" Class="SqlHandler" %>

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
using System.Data.SqlClient;
using System.Globalization;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Xml;

public class SqlHandler : IHttpHandler
{
    private static readonly Regex ErrorParser = new Regex(@"^(?<message>.+)\s\[TN\](\[(?<table>.+)\]((?<column>.+))?)?$", RegexOptions.ExplicitCapture);

    private string ToJson(object o)
    {
        // format null natively
        if (o == null)
            return "null";

        // format boolean natively
        if (o is Boolean)
            return ((bool)o) ? "true" : "false";

        // format dates as ISO 8601 strings
        if (o is DateTime)
            return ((DateTime)o).ToString("'\"'yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z\"'", System.Globalization.CultureInfo.InvariantCulture);

        // format real numbers natively and ensure a fraction
        if (o is Decimal || o is Double)
        {
            var str = ((IFormattable)o).ToString(null, CultureInfo.InvariantCulture);
            if (str.IndexOf('.') > -1)
                return str;
            return str + ".0";
        }

        // format integers natively
        if (o is Byte || o is Int16 || o is Int32 || o is Int64)
            return ((IFormattable)o).ToString(null, CultureInfo.InvariantCulture);

        // format guids as hyphenated strings
        if (o is Guid)
            return '"' + ((Guid)o).ToString("D", CultureInfo.InvariantCulture) + '"';

        // format binaries as hexadecimals strings
        if (o is Byte[])
        {
            var val = (Byte[])o;
            var builder = new StringBuilder(1 + 2 + val.Length * 2 + 1);
            builder.Append("\"0x");
            for (var i = 0; i < val.Length; i++)
                builder.Append(val[i].ToString("X2", CultureInfo.InvariantCulture));
            builder.Append('"');
            return builder.ToString();
        }

        // escape strings
        if (o is Char[] || o is String)
        {
            var builder = new StringBuilder();
            builder.Append('"');
            foreach (var ch in (IEnumerable<Char>)o)
            {
                switch (ch)
                {
                    case '\\':
                        builder.Append("\\\\");
                        break;
                    case '"':
                        builder.Append("\\\"");
                        break;
                    case '\b':
                        builder.Append("\\b");
                        break;
                    case '\f':
                        builder.Append("\\f");
                        break;
                    case '\n':
                        builder.Append("\\n");
                        break;
                    case '\r':
                        builder.Append("\\r");
                        break;
                    case '\t':
                        builder.Append("\\t");
                        break;
                    default:
                        if (ch < 0x0020)
                        {
                            builder.Append("\\u");
                            builder.Append(((ushort)ch).ToString("X4"));
                        }
                        else
                            builder.Append(ch);
                        break;
                }
            }
            builder.Append('"');
            return builder.ToString();
        }

        // mapped SQL 2008 types not implemented
        throw new NotImplementedException();
    }

    public void ProcessRequest(HttpContext context)
    {
        // get the command string
        var commandString = context.Request.QueryString["q"];
        if (string.IsNullOrWhiteSpace(commandString))
            throw new ArgumentNullException("q");

        // set the output type
        context.Response.ContentType = "application/json";
        context.Response.Charset = "UTF-8";

        // prepare the response and error variables
        var response = new StringBuilder();
        var commandNumber = 0;
        try
        {
            // impersonate the user and open the connection
            using (var impersonatedContext = ((WindowsIdentity)context.User.Identity).Impersonate())
            using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
            {
                connection.Open();
                using (var transaction = connection.BeginTransaction(System.Data.IsolationLevel.Serializable))
                using (var command = new SqlCommand(commandString, connection, transaction))
                {
                    // add all parameters
                    foreach (var parameterName in context.Request.Form.AllKeys)
                        command.Parameters.AddWithValue(parameterName, context.Request.Form[parameterName]);

                    // execute the query
                    commandNumber++;
                    using (var reader = command.ExecuteReader())
                    {
                        // write each result set
                        response.Append('[');
                        var firstSet = true;
                        do
                        {
                            if (firstSet)
                                firstSet = false;
                            else
                                response.Append(',');

                            // write the number of records affect and the records
                            response.Append("{\"RecordsAffected\":");
                            response.Append(ToJson(reader.RecordsAffected));
                            response.Append(",\"Records\":[");
                            var firstRow = true;
                            while (reader.Read())
                            {
                                if (firstRow)
                                    firstRow = false;
                                else
                                    response.Append(',');

                                // write all visible fields
                                response.Append('{');
                                var firstRowCol = true;
                                for (var i = 0; i < reader.VisibleFieldCount; i++)
                                {
                                    if (firstRowCol)
                                        firstRowCol = false;
                                    else
                                        response.Append(',');
                                    response.Append(ToJson(reader.GetName(i)));
                                    response.Append(':');
                                    response.Append(ToJson(reader.IsDBNull(i) ? null : reader.GetValue(i)));
                                }
                                response.Append('}');
                            }

                            // close the records and increment the command counter
                            response.Append("]}");
                            commandNumber++;
                        }
                        while (reader.NextResult());
                        response.Append(']');
                    }
                }
            }
        }
        catch (SqlException e)
        {
            // serialize general error properties
            response.Length = 0;
            response.Append('{');
            response.Append("\"Number\":").Append(ToJson(e.Number));
            response.Append(",\"CommandNumber\":").Append(ToJson(commandNumber));
            response.Append(",\"Message\":").Append(ToJson(e.Message));
            response.Append(",\"LineNumber\":").Append(ToJson(e.LineNumber));
            response.Append(",\"Severity\":").Append(ToJson(e.Class));
            response.Append(",\"State\":").Append(ToJson(e.State));
            response.Append('}');
        }

        // write the response
        context.Response.Write(response);
    }

    public bool IsReusable
    {
        get { return true; }
    }
}
