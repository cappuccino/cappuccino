
var asynchronousTimeoutCount = 0,
    asynchronousTimeoutId = null,
    asynchronousFunctionQueue = [];

function Asynchronous(/*Function*/ aFunction)
{
    currentAsynchronousTimeoutCount = asynchronousTimeoutCount;

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

function HTTPRequest()
{
    this._eventDispatcher = new EventDispatcher(this);
    this._nativeRequest = new NativeRequest();

    var self = this;

    this._nativeRequest.onreadystatechange = function()
    {
        determineAndDispatchHTTPRequestEvents(self);
    }
}

HTTPRequest.UninitializedState  = 0;
HTTPRequest.LoadingState        = 1;
HTTPRequest.LoadedState         = 2;
HTTPRequest.InteractiveState    = 3;
HTTPRequest.CompleteState       = 4;

HTTPRequest.prototype.status = function()
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

HTTPRequest.prototype.statusText = function()
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

HTTPRequest.prototype.readyState = function()
{
    return this._nativeRequest.readyState;
}

HTTPRequest.prototype.success = function()
{
    var status = this.status();

    if (status >= 200 && status < 300)
        return YES;

    // file:// requests return with status 0, to know if they succeeded, we 
    // need to know if there was any content.
    return status === 0 && this.responseText() && this.responseText().length;
}

HTTPRequest.prototype.responseXML = function()
{
    var responseXML = this._nativeRequest.responseXML;

    if (responseXML && (NativeRequest === XMLHttpRequest))
        return responseXML;

    return parseXML(this.responseText());
}

HTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();

    if (CFPropertyList.sniffedFormatOfString(responseText) === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(this.responseXML());

    return CFPropertyList.propertyListFromString(responseText);
}

HTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
}

HTTPRequest.prototype.setRequestHeader = function(/*String*/ aHeader, /*Object*/ aValue)
{
    return this._nativeRequest.setRequestHeader(aHeader, aValue);
}

HTTPRequest.prototype.getResponseHeader = function(/*String*/ aHeader)
{
    return this._nativeRequest.getResponseHeader(aHeader);
}

HTTPRequest.prototype.getAllResponseHeaders = function()
{
    return this._nativeRequest.getAllResponseHeaders();
}

HTTPRequest.prototype.overrideMimeType = function(/*String*/ aMimeType)
{
    if ("overrideMimeType" in this._nativeRequest)
        return this._nativeRequest.overrideMimeType(aMimeType);
}

HTTPRequest.prototype.open = function(/*...*/)
{
    return this._nativeRequest.open(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]);
}

HTTPRequest.prototype.send = function(/*Object*/ aBody)
{
    return this._nativeRequest.send(aBody);
}

HTTPRequest.prototype.abort = function()
{
    return this._nativeRequest.abort();
}

HTTPRequest.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

HTTPRequest.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

function determineAndDispatchHTTPRequestEvents(/*HTTPRequest*/ aRequest)
{
    var eventDispatcher = aRequest._eventDispatcher;

    eventDispatcher.dispatchEvent({ type: "readystatechange", request: aRequest});

    var nativeRequest = aRequest._nativeRequest,
        readyState = ["uninitialized", "loading", "loaded", "interactive", "complete"][aRequest.readyState()];

    eventDispatcher.dispatchEvent({ type: readyState, request: aRequest});

    if (readyState === "complete")
    {
        var status = "HTTP" + aRequest.status();

        eventDispatcher.dispatchEvent({ type: status, request: aRequest});

        var result = aRequest.success() ? "success" : "failure";

        eventDispatcher.dispatchEvent({ type: result, request: aRequest});
    }
}

function FileRequest(/*String*/ aFilePath, onsuccess, onfailure)
{
#ifdef BROWSER
    var request = new HTTPRequest();

    request.onsuccess = Asynchronous(onsuccess);
    request.onfailure = Asynchronous(onfailure);

    if (FILE.extension(aFilePath) === ".plist")
        request.overrideMimeType("text/xml");

    request.open("GET", aFilePath, YES);
    request.send("");
#else
    if (!FILE.exists(aFilePath))
        return onfailure();

    this._responseText = FILE.read(aFilePath, { charset: "UTF-8" });

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

exports.HTTPRequest = HTTPRequest;
