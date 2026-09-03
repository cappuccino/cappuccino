#!/usr/bin/env node
/*
 * serve.js
 * Tests/Manual
 *
 * Regenerates index.html, then serves this directory over plain HTTP,
 * so tests run in any browser -- not only Safari via file://.
 *
 * No npm dependencies -- Node core modules only. Ctrl-C to stop.
 *
 * Writes ./index.html: links every manual test app's source entry
 * points, plus its Build/Debug and Build/Release product entry
 * points when they exist.
 *
 * No npm dependencies -- Node core modules only.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

const http = require("http");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
const { generateIndex } = require("./generate-index.js");

const ROOT = __dirname;
const PORT = 8347;

const MIME_TYPES = {
    ".html": "text/html",
    ".htm": "text/html",
    ".js": "application/javascript",
    ".sj": "application/javascript",
    ".css": "text/css",
    ".json": "application/json",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".svg": "image/svg+xml",
    ".txt": "text/plain",
    ".plist": "text/plain"
};

function resolveRequestPath(url)
{
    var decoded = decodeURIComponent(url.split("?")[0]);
    var resolved = path.normalize(path.join(ROOT, decoded));

    // Reject traversal outside ROOT.
    if (resolved !== ROOT && !resolved.startsWith(ROOT + path.sep))
        return null;

    return resolved;
}

function serveFile(filePath, res)
{
    fs.readFile(filePath, function(err, data)
    {
        if (err)
        {
            res.writeHead(404, { "Content-Type": "text/plain" });
            res.end("404 Not Found: " + filePath);
            return;
        }

        var type = MIME_TYPES[path.extname(filePath).toLowerCase()] || "application/octet-stream";
        res.writeHead(200, { "Content-Type": type });
        res.end(data);
    });
}

const server = http.createServer(function(req, res)
{
    var filePath = resolveRequestPath(req.url);

    if (!filePath)
    {
        res.writeHead(403, { "Content-Type": "text/plain" });
        res.end("403 Forbidden");
        return;
    }

    fs.stat(filePath, function(err, stats)
    {
        if (!err && stats.isDirectory())
            filePath = path.join(filePath, "index.html");

        serveFile(filePath, res);
    });
});

generateIndex();

server.listen(PORT, function()
{
    var url = "http://localhost:" + PORT + "/index.html";
    console.log("Serving " + ROOT + " at " + url);
    console.log("Ctrl-C to stop.");
    exec("open " + url);
});
