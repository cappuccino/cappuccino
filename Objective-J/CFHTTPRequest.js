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
            asynchronousFunctionQueue.push(function()
            {
                aFunction.apply(this, args);
            });
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
            };

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
    this._isOpen = false;
    this._requestHeaders = {};
    this._mimeType = null;

    this._eventDispatcher = new EventDispatcher(this);
    this._nativeRequest = new NativeRequest();

    var self = this;
    this._stateChangeHandler = function()
    {
        determineAndDispatchHTTPRequestEvents(self);
    };

    this._nativeRequest.onreadystatechange = this._stateChangeHandler;

    if (CFHTTPRequest.AuthenticationDelegate !== nil)
        this._eventDispatcher.addEventListener("HTTP403", function()
            {
                CFHTTPRequest.AuthenticationDelegate(self);
            });
}

CFHTTPRequest.UninitializedState    = 0;
CFHTTPRequest.LoadingState          = 1;
CFHTTPRequest.LoadedState           = 2;
CFHTTPRequest.InteractiveState      = 3;
CFHTTPRequest.CompleteState         = 4;

//override to forward all CFHTTPRequest authorization failures to a single function
CFHTTPRequest.AuthenticationDelegate = nil;

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
};

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
};

CFHTTPRequest.prototype.readyState = function()
{
    return this._nativeRequest.readyState;
};

CFHTTPRequest.prototype.success = function()
{
    var status = this.status();

    if (status >= 200 && status < 300)
        return YES;

    // file:// requests return with status 0, to know if they succeeded, we
    // need to know if there was any content.
    return status === 0 && this.responseText() && this.responseText().length;
};

CFHTTPRequest.prototype.responseXML = function()
{
    var responseXML = this._nativeRequest.responseXML;

    if (responseXML && (NativeRequest === window.XMLHttpRequest))
        return responseXML;

    return parseXML(this.responseText());
};

CFHTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();

    if (CFPropertyList.sniffedFormatOfString(responseText) === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(this.responseXML());

    return CFPropertyList.propertyListFromString(responseText);
};

CFHTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
};

CFHTTPRequest.prototype.setRequestHeader = function(/*String*/ aHeader, /*Object*/ aValue)
{
    this._requestHeaders[aHeader] = aValue;
};

CFHTTPRequest.prototype.getResponseHeader = function(/*String*/ aHeader)
{
    return this._nativeRequest.getResponseHeader(aHeader);
};

CFHTTPRequest.prototype.getAllResponseHeaders = function()
{
    return this._nativeRequest.getAllResponseHeaders();
};

CFHTTPRequest.prototype.overrideMimeType = function(/*String*/ aMimeType)
{
    this._mimeType = aMimeType;
};

CFHTTPRequest.prototype.open = function(/*String*/ aMethod, /*String*/ aURL, /*Boolean*/ isAsynchronous, /*String*/ aUser, /*String*/ aPassword)
{
    this._isOpen = true;
    this._URL = aURL;
    this._async = isAsynchronous;
    this._method = aMethod;
    this._user = aUser;
    this._password = aPassword;
    return this._nativeRequest.open(aMethod, aURL, isAsynchronous, aUser, aPassword);
};

CFHTTPRequest.prototype.send = function(/*Object*/ aBody)
{
    if (!this._isOpen)
    {
        delete this._nativeRequest.onreadystatechange;
        this._nativeRequest.open(this._method, this._URL, this._async, this._user, this._password);
        this._nativeRequest.onreadystatechange = this._stateChangeHandler;
    }

    for (var i in this._requestHeaders)
    {
        if (this._requestHeaders.hasOwnProperty(i))
            this._nativeRequest.setRequestHeader(i, this._requestHeaders[i]);
    }

    if (this._mimeType && "overrideMimeType" in this._nativeRequest)
        this._nativeRequest.overrideMimeType(this._mimeType);

    this._isOpen = false;

    try
    {
        return this._nativeRequest.send(aBody);
    }
    catch (anException)
    {
        // FIXME: Do something more complex, with 404's?
        this._eventDispatcher.dispatchEvent({ type:"failure", request:this });
    }
};

CFHTTPRequest.prototype.abort = function()
{
    this._isOpen = false;
    return this._nativeRequest.abort();
};

CFHTTPRequest.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
};

CFHTTPRequest.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
};

function determineAndDispatchHTTPRequestEvents(/*CFHTTPRequest*/ aRequest)
{
    var eventDispatcher = aRequest._eventDispatcher;

    eventDispatcher.dispatchEvent({ type:"readystatechange", request:aRequest});

    var nativeRequest = aRequest._nativeRequest,
        readyStates = ["uninitialized", "loading", "loaded", "interactive", "complete"];

    if (readyStates[aRequest.readyState()] === "complete")
    {
        var status = "HTTP" + aRequest.status();
        eventDispatcher.dispatchEvent({ type:status, request:aRequest });

        var result = aRequest.success() ? "success" : "failure";
        eventDispatcher.dispatchEvent({ type:result, request:aRequest });

        eventDispatcher.dispatchEvent({ type:readyStates[aRequest.readyState()], request:aRequest});
    }
    else
        eventDispatcher.dispatchEvent({ type:readyStates[aRequest.readyState()], request:aRequest});
}

function FileRequest(/*CFURL*/ aURL, onsuccess, onfailure)
{
    var request = new CFHTTPRequest();

    if (aURL.pathExtension() === "plist")
        request.overrideMimeType("text/xml");

#if COMMONJS
    if (aURL.pathExtension().toLowerCase() === "j")
    {
        var aFilePath = aURL.toString().substring(5),
            OS = require("os"),
            gccFlags = require("objective-j").currentCompilerFlags(),
            gcc = OS.popen("gcc -E -x c -P " + (gccFlags ? gccFlags : "") + " " + OS.enquote(aFilePath), { charset:"UTF-8" }),
            chunk,
            fileContents = "";

        while (chunk = gcc.stdout.read())
            fileContents += chunk;

        if (fileContents.length > 0)
        {
            request._nativeRequest.responseText = fileContents;
            onsuccess({request: request});
        }
        else
        {
            onfailure({request: request});
        }
        return;
    }
#endif

    if (exports.asyncLoader)
    {
        request.onsuccess = Asynchronous(onsuccess);
        request.onfailure = Asynchronous(onfailure);
    }
    else
    {
        request.onsuccess = onsuccess;
        request.onfailure = onfailure;
    }

    request.open("GET", aURL.absoluteString(), exports.asyncLoader);
    request.send("");
}

#ifdef BROWSER
exports.asyncLoader = YES;
#else
exports.asyncLoader = NO;
#endif

// FIXME: Get rid of these when we no longer need Mock requests in flatten.
exports.Asynchronous = Asynchronous;
exports.determineAndDispatchHTTPRequestEvents = determineAndDispatchHTTPRequestEvents;
