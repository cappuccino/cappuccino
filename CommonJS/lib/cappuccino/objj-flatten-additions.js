
var URLCache = { };

var CFHTTPRequest_open = CFHTTPRequest.prototype.open;
CFHTTPRequest.prototype.open = function(/*String*/ method, /*String*/ url, /*Boolean*/ async, /*String*/ user, /*String*/ password)
{
    var cachedRequest = CFHTTPRequest._lookupCachedRequest(url);
    if (cachedRequest)
    {
        var self = this;
        this._nativeRequest = cachedRequest;
        this._nativeRequest.onreadystatechange = function()
        {
            ObjectiveJ.determineAndDispatchHTTPRequestEvents(self);
        };
    }
    return CFHTTPRequest_open.apply(this, arguments);
}

CFHTTPRequest._cacheRequest = function(/*CFURL|String*/ aURL, /*Number*/ status, /*Object*/ headers, /*String*/ body)
{
    URLCache[aURL] = new MockXMLHttpRequest(status, headers, body);
}

CFHTTPRequest._lookupCachedRequest = function(/*CFURL|String*/ aURL)
{
    return URLCache[aURL];
}

function MockXMLHttpRequest(status, headers, body)
{
    this.readyState         = CFHTTPRequest.UninitializedState;
    this.status             = status || 200;
    this.statusText         = "";
    this.responseText       = body || "";
    this._responseHeaders   = headers || {};
};
MockXMLHttpRequest.prototype.open = function(method, url, async, user, password)
{
    this.readyState = CFHTTPRequest.LoadingState;
    this.async = async;
};
MockXMLHttpRequest.prototype.send = function(body)
{
    var self = this;
    self.responseText = self.responseText.toString();
    function complete() {
        for (self.readyState = CFHTTPRequest.LoadedState; self.readyState <= CFHTTPRequest.CompleteState; self.readyState++)
            self.onreadystatechange();
    }
    (self.async ? ObjectiveJ.Asynchronous(complete) : complete)();
};
MockXMLHttpRequest.prototype.onreadystatechange       = function() {};
MockXMLHttpRequest.prototype.abort                    = function() {};
MockXMLHttpRequest.prototype.setRequestHeader         = function(header, value) {};
MockXMLHttpRequest.prototype.getAllResponseHeaders    = function() { return this._responseHeaders; };
MockXMLHttpRequest.prototype.getResponseHeader        = function(header) { return this._responseHeaders[header]; };
MockXMLHttpRequest.prototype.overrideMimeType         = function(mimetype) {};
