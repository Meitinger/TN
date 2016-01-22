<%@ WebHandler Language="C#" Class="DownloadHandler" %>
<%@ Assembly Name="System.IO.Compression, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" %>

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
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Security.Principal;
using System.Text;
using System.Web;

public class DownloadHandler : IHttpHandler
{
    // wrapper class to provide the current stream position for ZipArchive
    private class ZipOutputStream : Stream
    {
        private readonly Stream underlyingStream;
        private long position;

        public ZipOutputStream(Stream underlyingStream)
        {
            if (underlyingStream == null)
                throw new ArgumentNullException("underlyingStream");
            this.underlyingStream = underlyingStream;
        }

        public override bool CanRead { get { return false; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return true; } }

        public override long Length { get { return position; } }

        public override long Position
        {
            get { return position; }
            set { throw new NotImplementedException(); }
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            underlyingStream.Write(buffer, offset, count);
            position += count;
        }

        public override void Flush()
        {
            underlyingStream.Flush();
        }

        public override int Read(byte[] buffer, int offset, int count) { throw new NotImplementedException(); }
        public override long Seek(long offset, SeekOrigin origin) { throw new NotImplementedException(); }
        public override void SetLength(long value) { throw new NotImplementedException(); }
    }

    public void ProcessRequest(HttpContext context)
    {
        // impersonate the user and open the connection
        using (var impersonatedContext = ((WindowsIdentity)context.User.Identity).Impersonate())
        using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["tn"].ConnectionString))
        {
            connection.Open();
            using (var command = new SqlCommand())
            {
                // add all parameters to the command
                command.Connection = connection;
                command.CommandType = System.Data.CommandType.StoredProcedure;
                for (var i = 0; i < context.Request.QueryString.Count; i++)
                {
                    var key = context.Request.QueryString.GetKey(i);
                    var value = context.Request.QueryString.Get(i);
                    if (key == "@")
                        command.CommandText = value;
                    else
                        command.Parameters.AddWithValue(key, value);
                }

                // make sure the name has been set before querying the database
                if (string.IsNullOrWhiteSpace(command.CommandText))
                    throw new ArgumentNullException("@");
                command.CommandText = "Download" + command.CommandText;
                using (var reader = command.ExecuteReader())
                {
                    // get the archive description and set the headers
                    if (!reader.Read())
                        throw new HttpException(404, "not found");
                    var disposition = new StringBuilder("attachment");
                    if (!reader.IsDBNull(reader.GetOrdinal("LastModified")))
                    {
                        disposition.Append("; modification-date=\"");
                        disposition.Append(reader.GetDateTime(reader.GetOrdinal("LastModified")).ToUniversalTime().ToString("r"));
                        disposition.Append("\"");
                    }
                    disposition.Append("; filename=");
                    disposition.Append(reader.GetString(reader.GetOrdinal("FileName")));
                    context.Response.HeaderEncoding = Encoding.GetEncoding(reader.GetString(reader.GetOrdinal("Encoding")));
                    context.Response.Headers["Content-Disposition"] = disposition.ToString();
                    context.Response.ContentType = reader.GetString(reader.GetOrdinal("ContentType"));

                    // add all files to the archive
                    using (var zipArchive = new ZipArchive(new ZipOutputStream(context.Response.OutputStream), ZipArchiveMode.Create, true, context.Response.HeaderEncoding))
                    {
                        while (reader.NextResult())
                        {
                            // get the file description
                            if (!reader.Read())
                                throw new InvalidDataException("File description is empty.");
                            var fileName = reader.GetString(reader.GetOrdinal("FileName"));
                            var encoding = Encoding.GetEncoding(reader.GetString(reader.GetOrdinal("Encoding")));
                            var cultureInfo = CultureInfo.CreateSpecificCulture(reader.GetString(reader.GetOrdinal("Culture")));
                            var separator = reader.GetString(reader.GetOrdinal("Separator"));
                            var header = reader.GetBoolean(reader.GetOrdinal("Header"));

                            // fetch the content but skip empty files
                            if (!reader.NextResult())
                                throw new InvalidDataException("File content is missing.");
                            if (reader.FieldCount == 0)
                                continue;

                            // create the zip entry
                            if (string.IsNullOrEmpty(fileName))
                                fileName = Path.GetRandomFileName();
                            var zipEntry = zipArchive.CreateEntry(fileName);
                            using (var writer = new StreamWriter(zipEntry.Open(), encoding))
                            {
                                // write the header
                                if (header)
                                {
                                    writer.Write(reader.GetName(0));
                                    for (var i = 1; i < reader.FieldCount; i++)
                                    {
                                        writer.Write(separator);
                                        writer.Write(reader.GetName(i));
                                    }
                                    writer.WriteLine();
                                }

                                // write the content
                                while (reader.Read())
                                {
                                    if (!reader.IsDBNull(0))
                                        writer.Write(Convert.ToString(reader[0], cultureInfo));
                                    for (var i = 1; i < reader.FieldCount; i++)
                                    {
                                        writer.Write(separator);
                                        if (!reader.IsDBNull(i))
                                            writer.Write(Convert.ToString(reader[i], cultureInfo));
                                    }
                                    writer.WriteLine();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public bool IsReusable
    {
        get { return true; }
    }
}
