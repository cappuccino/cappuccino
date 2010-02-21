/*
 * Bootstrap.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

var cwd = FILE.cwd(),
    rootResource = new StaticResource("", NULL, YES, cwd !== "/");

StaticResource.root = rootResource;

#ifdef BROWSER
if (rootResource.isResolved())
{
    rootResource.nodeAtSubPath(FILE.dirname(cwd), YES);
    resolveCWD();
}
else
{
    rootResource.resolve();
    rootResource.addEventListener("resolve", resolveCWD);
}

function resolveCWD()
{
    rootResource.resolveSubPath(cwd, YES, function(/*StaticResource*/ aResource)
    {
        var includePaths = StaticResource.includePaths(),
            index = 0,
            count = includePaths.length;

        for (; index < count; ++index)
            aResource.nodeAtSubPath(FILE.normal(includePaths[index]), YES);

        if (typeof OBJJ_MAIN_FILE === "undefined")
            OBJJ_MAIN_FILE = "main.j";

        Executable.fileImporterForPath(cwd)(OBJJ_MAIN_FILE || "main.j", YES, function()
        {
            afterDocumentLoad(main);
        });
    });
}

function afterDocumentLoad(/*Function*/ aFunction)
{
    if (documentLoaded)
        return aFunction();

    if (window.addEventListener)
        window.addEventListener("load", aFunction, NO);

    else if (window.attachEvent)
        window.attachEvent("onload", aFunction);
}

var documentLoaded = NO;

afterDocumentLoad(function()
{
    documentLoaded = YES;
});
#endif
