/*
 * Objective-J.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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

var FILE = require("file");
var MD5 = require("md5");
var FileList = (require("jake")).FileList;
var BundleTask = (require("objective-j/jake/bundletask")).BundleTask;
exports.generateManifest = function(productPath, options)
{
    options = options || {};
    indexFilePath = options.index || FILE.join(productPath, "index.html");
    if (!FILE.isFile(indexFilePath))
    {
        print("Warning: Skipping cache manifest generation, no index file at " + indexFilePath);
        return;
    }    var index = FILE.read(indexFilePath, {charset: "UTF-8"});
    var manifestName = "app.manifest";
    var manifestPath = FILE.join(productPath, manifestName);
    var manifestAttribute = 'manifest="' + manifestName + '"';
    print("Generating cache manifest: " + manifestPath);
    var manifestOut = FILE.open(manifestPath, "w", {charset: "UTF-8"});
    manifestOut.print("CACHE MANIFEST");
    manifestOut.print("");
    manifestOut.print("CACHE:");
    var list = new FileList(FILE.join(productPath, "**", "*"));
    list.exclude(manifestPath);
    list.exclude("**/.DS_Store", "**/.htaccess");
    list.exclude("**/LICENSE");
    list.exclude("**/MHTML*");
    list.exclude("**/CommonJS.environment/*");
    list.exclude("**/*.cur");
    if (index.indexOf('"Frameworks/Debug"') < 0)
        list.exclude("**/Frameworks/Debug/*");
    if (options.exclude)
        options.exclude.forEach(list.exclude.bind(list));
    list.forEach(    function(path)
    {
        if (FILE.isFile(path))
        {
            var relative = FILE.relative(productPath, path);
            if (BundleTask.isSpritable(path) && index.indexOf(relative) < 0)
                return;
            var hash = (MD5.hash(FILE.read(path, "b"))).decodeToString("base16");
            manifestOut.print("# " + hash);
            manifestOut.print(relative);
        }    });
    manifestOut.print("");
    manifestOut.print("NETWORK:");
    manifestOut.print("*");
    manifestOut.close();
    var matchTag = index.match(/<html[^>]*>/i);
    if (matchTag)
    {
        var htmlTag = matchTag[0];
        var newHTMLTag = null;
        var matchAttr = htmlTag.match(/manifest\s*=\s*"([^"]*)"/i);
        if (matchAttr)
        {
            if (matchAttr[1] !== manifestName)
            {
                newHTMLTag = htmlTag.replace(matchAttr[0], manifestAttribute);
            }        }        else
        {
            newHTMLTag = htmlTag.replace(/>$/, " " + manifestAttribute + ">");
        }        if (newHTMLTag)
        {
            print("Replacing html tag: \n    " + htmlTag + "\nwith:\n    " + newHTMLTag);
            var newIndex = index.replace(htmlTag, newHTMLTag);
            if (newIndex === index)
            {
                print("Warning: No change!");
            }            else
            {
                FILE.write(indexFilePath, newIndex, {charset: "UTF-8"});
            }        }    }    else
    {
        print("Warning: Couldn't find <html> tag in " + indexFilePath);
    }    var htaccessPath = FILE.join(productPath, ".htaccess");
    var htaccess = FILE.isFile(htaccessPath) ? FILE.read(htaccessPath, {charset: "UTF-8"}) : "";
    var htaccessOut = FILE.open(htaccessPath, "w", {charset: "UTF-8"});
    htaccessOut.print(htaccess);
    var openTag = "<Files " + manifestName + ">";
    if (htaccess.indexOf(openTag) < 0)
    {
        htaccessOut.print("");
        htaccessOut.print(openTag);
        htaccessOut.print("\tHeader set Content-Type text/cache-manifest");
        htaccessOut.print("</Files>");
    }    htaccessOut.close();
};
