/*
 * CFHTTPRequest.js
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

var asynchronousTimeoutCount = 0,
    asynchronousTimeoutId = null,
    asynchronousFunctionQueue = [];

function Asynchronous(/*Function*/ aFunction)
{
    var currentAsynchronousTimeoutCount = asynchronousTimeoutCount;

    if (asynchronousTimeoutId === null)
    {
        window.setNativeTimeout(function()
        {
            var queue = asynchronousFunctionQueue,
                index = 0,
                count = asynchronousFunctionQueue.length;

            ++asynchronousTimeoutCount;
            asynchronousTimeoutId = null;
            asynchronousFunctionQueue = [];

            for (; index < count; ++index)
                queue[index]();
        }, 0);
    }

    return function()
    {
        var args = arguments;

        if (asynchronousTimeoutCount > currentAsynchronousTimeoutCount)
            aFunction.apply(this, args);
        else
            asynchronousFunctionQueue.push(function() { aFunction.apply(this, args) });
    };
}

var NativeRequest = null;

// We check ActiveXObject first, because we require local file access and
// overrideMimeType feature (which the native XMLHttpRequest does not have in IE).
if (window.ActiveXObject !== undefined)
{
    // DON'T try 4.0 and 5.0: http://bit.ly/microsoft-msxml-explanation
    var MSXML_XMLHTTP_OBJECTS = ["Msxml2.XMLHTTP.3.0", "Msxml2.XMLHTTP.6.0"],
        index = MSXML_XMLHTTP_OBJECTS.length;

    while (index--)
    {
        try
        {
            var MSXML_XMLHTTP = MSXML_XMLHTTP_OBJECTS[index];

            new ActiveXObject(MSXML_XMLHTTP);

            NativeRequest = function()
            {
                return new ActiveXObject(MSXML_XMLHTTP);
            }

            break;
        }
        catch (anException)
        {
        }
    }
}

if (!NativeRequest)
    NativeRequest = window.XMLHttpRequest;

GLOBAL(CFHTTPRequest) = function()
{
    this._eventDispatcher = new EventDispatcher(this);
    this._nativeRequest = new NativeRequest();

    var self = this;

    this._nativeRequest.onreadystatechange = function()
    {
        determineAndDispatchHTTPRequestEvents(self);
    }
}

CFHTTPRequest.UninitializedState    = 0;
CFHTTPRequest.LoadingState          = 1;
CFHTTPRequest.LoadedState           = 2;
CFHTTPRequest.InteractiveState      = 3;
CFHTTPRequest.CompleteState         = 4;

CFHTTPRequest.prototype.status = function()
{
    try
    {
        return this._nativeRequest.status || 0;
    }
    catch (anException)
    {
        return 0;
    }
}

CFHTTPRequest.prototype.statusText = function()
{
    try
    {
        return this._nativeRequest.statusText || "";
    }
    catch (anException)
    {
        return "";
    }
}

CFHTTPRequest.prototype.readyState = function()
{
    return this._nativeRequest.readyState;
}

CFHTTPRequest.prototype.success = function()
{
    var status = this.status();

    if (status >= 200 && status < 300)
        return YES;

    // file:// requests return with status 0, to know if they succeeded, we
    // need to know if there was any content.
    return status === 0 && this.responseText() && this.responseText().length;
}

CFHTTPRequest.prototype.responseXML = function()
{
    var responseXML = this._nativeRequest.responseXML;

    if (responseXML && (NativeRequest === window.XMLHttpRequest))
        return responseXML;

    return parseXML(this.responseText());
}

CFHTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();

    if (CFPropertyList.sniffedFormatOfString(responseText) === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(this.responseXML());

    return CFPropertyList.propertyListFromString(responseText);
}

CFHTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
}

CFHTTPRequest.prototype.setRequestHeader = function(/*String*/ aHeader, /*Object*/ aValue)
{
    return this._nativeRequest.setRequestHeader(aHeader, aValue);
}

CFHTTPRequest.prototype.getResponseHeader = function(/*String*/ aHeader)
{
    return this._nativeRequest.getResponseHeader(aHeader);
}

CFHTTPRequest.prototype.getAllResponseHeaders = function()
{
    return this._nativeRequest.getAllResponseHeaders();
}

CFHTTPRequest.prototype.overrideMimeType = function(/*String*/ aMimeType)
{
    if ("overrideMimeType" in this._nativeRequest)
        return this._nativeRequest.overrideMimeType(aMimeType);
}

CFHTTPRequest.prototype.open = function(/*...*/)
{
    return this._nativeRequest.open(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]);
}

CFHTTPRequest.prototype.send = function(/*Object*/ aBody)
{
    try
    {
        return this._nativeRequest.send(aBody);
    }
    catch (anException)
    {
        // FIXME: Do something more complex, with 404's?
        this._eventDispatcher.dispatchEvent({ type:"failure", request:this });
    }
}

CFHTTPRequest.prototype.abort = function()
{
    return this._nativeRequest.abort();
}

CFHTTPRequest.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

CFHTTPRequest.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

function determineAndDispatchHTTPRequestEvents(/*CFHTTPRequest*/ aRequest)
{
    var eventDispatcher = aRequest._eventDispatcher;

    eventDispatcher.dispatchEvent({ type:"readystatechange", request:aRequest});

    var nativeRequest = aRequest._nativeRequest,
        readyState = ["uninitialized", "loading", "loaded", "interactive", "complete"][aRequest.readyState()];

    eventDispatcher.dispatchEvent({ type:readyState, request:aRequest});

    if (readyState === "complete")
    {
        var status = "HTTP" + aRequest.status();

        eventDispatcher.dispatchEvent({ type:status, request:aRequest });

        var result = aRequest.success() ? "success" : "failure";

        eventDispatcher.dispatchEvent({ type:result, request:aRequest });
    }
}

function FileRequest(/*CFURL*/ aURL, onsuccess, onfailure)
{
#ifdef BROWSER
    var request = new CFHTTPRequest();

    request.onsuccess = Asynchronous(onsuccess);
    request.onfailure = Asynchronous(onfailure);

    if (aURL.pathExtension() === "plist")
        request.overrideMimeType("text/xml");

    request.open("GET", aURL.absoluteString(), YES);
    request.send("");
#else
    var FILE = require("file"),
        filePath = aURL.absoluteURL().path();

    if (!FILE.exists(filePath))
        return onfailure();

    this._responseText = FILE.read(filePath, { charset:"UTF-8" });

    onsuccess({ type:"success", request:this });
#endif
}

#ifdef COMMONJS
FileRequest.prototype.responseText = function()
{
    return this._responseText;
}

FileRequest.prototype.responseXML = function()
{
    return new DOMParser().parseFromString(anXMLString, "text/xml");
}

FileRequest.prototype.responsePropertyList = function()
{
    return CFPropertyList.propertyListFromString(this.responseText());
}
#endif
