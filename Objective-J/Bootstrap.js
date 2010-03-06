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


function makeAbsoluteURL(/*CFURL|String*/ aURL)
{
    return new CFURL(aURL, mainBundleURL);
}

#ifdef COMMONJS
var mainBundleURL = new CFURL("file:" + require("file").cwd());
#elif defined(BROWSER)
// To determine where our application lives, start with the current URL of the page.
var pageURL = new CFURL(window.location.href),

// Look for any <base> tags and choose the last one (which is the one that will take effect).
    DOMBaseElements = document.getElementsByTagName("base"),
    DOMBaseElementsCount = DOMBaseElements.length;

if (DOMBaseElementsCount > 0)
{
    var DOMBaseElement = DOMBaseElements[DOMBaseElementsCount - 1],
        DOMBaseElementHref = DOMBaseElement && DOMBaseElement.getAttribute("href");

    // If we have one, use it instead.
    if (DOMBaseElementHref)
        pageURL = new CFURL(DOMBaseElementHref, pageURL);
}

// Turn the main file into a URL.
var mainFileURL = new CFURL(window.OBJJ_MAIN_FILE || "main.j"),

// The main bundle is the containing folder of the main file.
    mainBundleURL = new CFURL(".", new CFURL(mainFileURL, pageURL)).absoluteURL();

StaticResource.resourceAtURL(new CFURL("..", mainBundleURL).absoluteURL(), YES);

exports.bootstrap = function()
{
    resolveMainBundleURL();
}

function resolveMainBundleURL()
{
    StaticResource.resolveResourceAtURL(mainBundleURL, YES, function(/*StaticResource*/ aResource)
    {
        var includeURLs = StaticResource.includeURLs(),
            index = 0,
            count = includeURLs.length;

        for (; index < count; ++index)
            aResource.resourceAtURL(includeURLs[index], YES);

        Executable.fileImporterForURL(mainBundleURL)(mainFileURL, YES, function()
        {
            afterDocumentLoad(main);
        });
    });
}

var documentLoaded = NO;

function afterDocumentLoad(/*Function*/ aFunction)
{
    if (documentLoaded)
        return aFunction();

    if (window.addEventListener)
        window.addEventListener("load", aFunction, NO);

    else if (window.attachEvent)
        window.attachEvent("onload", aFunction);
}

afterDocumentLoad(function()
{
    documentLoaded = YES;
});

if (typeof OBJJ_AUTO_BOOTSTRAP === "undefined" || OBJJ_AUTO_BOOTSTRAP)
    exports.bootstrap();

#endif
