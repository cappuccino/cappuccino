
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

    if (!responseXML && window.ActiveXObject)
    {
        var responseText = this.responseText(),
            XMLData = new ActiveXObject("Microsoft.XMLDOM");

        XMLData.loadXML(responseText.substr(responseText.indexOf(".dtd\">") + 6));

        return XMLData;
    }

    return responseXML;
}

HTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();

    if (PropertyList.sniffedFormatOfString(responseText) === PropertyList.FormatXML_v1_0)
        return PropertyList.createFromXML(this.responseXML());

    return PropertyList.createFromString(responseText);
}

HTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
}

var methods = ["open", "send", "abort", "setRequestHeader", "getResponseHeader", "getAllResponseHeaders"],
    count = methods.length;

while (count--)
    (function()
    {
        var method = methods[count];

        HTTPRequest.prototype[methods[count]] = function()
        {
            var nativeRequest = this._nativeRequest;

            return nativeRequest[method].apply(nativeRequest, arguments);
        }
    })();

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
