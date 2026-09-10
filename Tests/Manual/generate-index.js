#!/usr/bin/env node
/*
 * generate-index.js
 * Tests/Manual
 *
 * Created by David Richardson, September 7, 2026
 * Copyright 2026, David Richardson. All rights reserved.
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

const fs = require("fs");
const path = require("path");

const ROOT = __dirname;

// Cappuccino logotype embedded as a Base64 PNG Data URL
const CAPPUCCINO_LOGO_DATA_URL = "data:image/png;base64,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";

function listAppDirs()
{
    return fs.readdirSync(ROOT, { withFileTypes: true })
    .filter(function(entry)
            {
        if (!entry.isDirectory())
            return false;
        if (entry.name.charAt(0) === ".")
            return false;
        if (entry.name === "Frameworks")
            return false;

        var dir = path.join(ROOT, entry.name);
        return fs.existsSync(path.join(dir, "Info.plist")) ||
        fs.existsSync(path.join(dir, "index.html"));
    })
    .map(function(entry) { return entry.name; })
    .sort();
}

function findBuiltProduct(appDir, configuration)
{
    var configDir = path.join(ROOT, appDir, "Build", configuration);

    if (!fs.existsSync(configDir))
        return null;

    var entries = fs.readdirSync(configDir, { withFileTypes: true })
    .filter(function(entry) { return entry.isDirectory(); });

    for (var i = 0; i < entries.length; i++)
    {
        var candidate = path.join(configDir, entries[i].name, "index.html");

        if (fs.existsSync(candidate))
            return path.join(appDir, "Build", configuration, entries[i].name, "index.html");
    }

    return null;
}

function escapeHtml(s)
{
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function link(href, label, badgeClass)
{
    return "<a class=\"badge " + badgeClass + "\" href=\"" + encodeURI(href) + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + escapeHtml(label) + "</a>";
}

function buildIndexHtml()
{
    var appDirs = listAppDirs();

    var rows = appDirs.map(function(appDir)
                           {
        var links = [];

        if (fs.existsSync(path.join(ROOT, appDir, "index.html")))
            links.push(link(path.join(appDir, "index.html"), "source", "badge-source"));

        if (fs.existsSync(path.join(ROOT, appDir, "index-debug.html")))
            links.push(link(path.join(appDir, "index-debug.html"), "source debug", "badge-source-debug"));

        var debugProduct = findBuiltProduct(appDir, "Debug");
        if (debugProduct)
            links.push(link(debugProduct, "built debug", "badge-built-debug"));

        var releaseProduct = findBuiltProduct(appDir, "Release");
        if (releaseProduct)
            links.push(link(releaseProduct, "built release", "badge-built-release"));

        return "<tr><td><strong>" + escapeHtml(appDir) + "</strong></td><td>" + links.join("") + "</td></tr>";
    });

    var css = `
        :root { --bg: #ffffff; --text: #333333; --border: #e1e4e8; --row-alt: #f6f8fa; --row-hover: #f0f3f6; }
        body { font-family: "IBM Plex Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 14px; color: var(--text); max-width: 960px; margin: 0 auto; padding: 2rem; background: #fbfbfb; }
        .container { background: var(--bg); border: 1px solid var(--border); border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .header {
            background-color: #242a35;
            background-image: repeating-linear-gradient(
                -45deg,
                rgba(255, 255, 255, 0.03),
                rgba(255, 255, 255, 0.03) 1px,
                transparent 1px,
                transparent 4px
            );
            color: #ffffff;
            padding: 18px 24px;
            border-bottom: 1px solid #1a1e27;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 10px;
        }

        .brand img {
            height: 38px;
            width: auto;
            display: block;
        }

        .brand h1 {
            margin: 0;
            font-size: 19px;
            font-weight: 600;
            line-height: 1;
            color: #ffffff;
            letter-spacing: -0.01em;
        }

        .header p {
            margin: 0;
            color: #9aa5b5;
            font-size: 13px;
        }

        input[type="text"] {
            width: 100%;
            padding: 9px 14px;
            margin-top: 14px;
            background-color: #171b22;
            color: #e6edf3;
            border: 1px solid #0d1015;
            border-radius: 5px;
            font-family: inherit;
            font-size: 13px;
            box-sizing: border-box;
            outline: none;
            box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.5);
            transition: border-color 0.15s ease, background-color 0.15s ease;
        }

        input[type="text"]::placeholder {
            color: #626e7f;
        }

        input[type="text"]:focus {
            background-color: #1c212a;
            border-color: #3b4556;
            box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.6), 0 0 0 1px #3b4556;
        }

        table { width: 100%; border-collapse: collapse; table-layout: fixed; }
        th, td { padding: 12px 20px; text-align: left; vertical-align: middle; border-bottom: 1px solid var(--border); }
        th { background: var(--bg); font-weight: 600; color: #586069; position: sticky; top: 0; z-index: 10; box-shadow: 0 1px 2px rgba(0,0,0,0.05); }
        th:first-child { width: 35%; }
        tbody tr:nth-child(even) { background: var(--row-alt); }
        tbody tr:hover { background: var(--row-hover); }
        tbody tr:last-child td { border-bottom: none; }
        .badge { display: inline-block; padding: 4px 10px; margin: 2px 6px 2px 0; border-radius: 2em; font-size: 12px; font-weight: 600; text-decoration: none; color: white; transition: opacity 0.2s; }
        .badge:hover { opacity: 0.85; }
        .badge-source { background-color: #2d7d46; }
        .badge-source-debug { background-color: #0066cc; }
        .badge-built-debug { background-color: #0066cc; }
        .badge-built-release { background-color: #6a737d; }
    `;

    var js = `
        function filterTable() {
            var filter = document.getElementById("search").value.toUpperCase();
            var rows = document.querySelectorAll("tbody tr");
            for (var i = 0; i < rows.length; i++) {
                var cell = rows[i].getElementsByTagName("td")[0];
                if (cell) {
                    var txtValue = cell.textContent || cell.innerText;
                    rows[i].style.display = txtValue.toUpperCase().indexOf(filter) > -1 ? "" : "none";
                }
            }
        }
    `;

    return "<!DOCTYPE html>\n" +
    "<html>\n<head>\n<meta charset=\"utf-8\">\n<title>Manual Tests</title>\n" +
    "<style>" + css + "</style>\n</head>\n<body>\n" +
    "<div class=\"container\">\n" +
    "  <div class=\"header\">\n" +
    "    <div class=\"brand\">\n" +
    "      <img src=\"" + CAPPUCCINO_LOGO_DATA_URL + "\" alt=\"Cappuccino Logo\">\n" +
    "      <h1>Manual Integration Tests</h1>\n" +
    "    </div>\n" +
    "    <p>" + appDirs.length + " applications. Generated by generate-index.js.</p>\n" +
    "    <input type=\"text\" id=\"search\" onkeyup=\"filterTable()\" placeholder=\"Filter applications by name...\">\n" +
    "  </div>\n" +
    "  <table>\n" +
    "    <thead><tr><th>Application</th><th>Entry Points</th></tr></thead>\n" +
    "    <tbody>\n" + rows.join("\n") + "\n    </tbody>\n" +
    "  </table>\n" +
    "</div>\n" +
    "<script>\n" + js + "\n</script>\n" +
    "</body>\n</html>\n";
}

function generateIndex()
{
    var html = buildIndexHtml();
    fs.writeFileSync(path.join(ROOT, "index.html"), html);
    return html;
}

module.exports = { generateIndex: generateIndex };

if (require.main === module)
{
    generateIndex();
    console.log("Wrote " + path.join(ROOT, "index.html"));
}
