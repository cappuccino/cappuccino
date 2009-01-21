if (typeof debug == "undefined")
    debug = false;

//window

if (!this.window)
    this.window = this;

// DOMParser

/*function DOMParser() {};
DOMParser.prototype.parseFromString = function(text, contentType) {
	return new DOMDocument(
		new Packages.org.xml.sax.InputSource(
			new Packages.java.io.StringReader(text)));
};*/

// Image

function Image() { }

// print, alert, prompt, confirm

if (!this.print)
{
    if (this.Packages)
    {
        this.print = function(object)
        {
            Packages.java.lang.System.out.println(String(object));
        }
    }
}

window.alert = function(obj)
{
    if (this.print)
        print(String(obj));
}
// FIXME: prompt user for response?
window.confirm = function(obj)
{
    window.alert(obj);
    return true;
}
window.prompt  = function(obj)
{ 
    window.alert(obj);
    return "";
}

// setTimeout, setInterval, clearTimeout, clearInterval

// This implementation is single-threaded (like browsers) but requires a call to serviceTimeouts()
// Also includes beginning of a multithreaded implementation (commented out)

window.setNativeTimeout = function(callback, delay)
{
    return _scheduleTimeout(callback, delay, false);
}

window.setTimeout = window.setNativeTimeout;

window.setNativeInterval = function(callback, delay)
{
    return _scheduleTimeout(callback, delay, true);
}

window.setInterval = window.setInterval;

window.clearTimeout = function(id)
{
    if (_timeouts[id])
        _timeouts[id] = null;
}
window.clearInterval = window.clearTimeout;

var _nextId = 0,
    _timeouts = {},
    _pendingTimeouts = [];

var _scheduleTimeout = function(callback, delay, repeat)
{
    var date = new Date(new Date().getTime() + delay);

	if (typeof callback == "function")
		var func = callback;
	else if (typeof callback == "string")
		var func = new Function(callback);
	else
		return;

	var timeout = {
        callback: func,
    	date: date,
    	repeat: repeat,
    	interval: delay,
    	id : _nextId++
    }

    _timeouts[timeout.id] = timeout;
    _pendingTimeouts.push(timeout);

//	if (!_timersBlock)
//	    serviceTimeouts();

	return timeout.id;
}

var _sortTimeouts = function()
{
    
}

//var _timersBlock = false,
//    _timerThread = null,
//    _nextTimeout = null;

function serviceTimeouts()
{
    while (_pendingTimeouts.length > 0)
    {
        _pendingTimeouts = _pendingTimeouts.sort(function (a,b) { return a.date - b.date; });
        
        var timeout = _pendingTimeouts.shift();
        if (_timeouts[timeout.id])
        {
        	var wait = timeout.date - new Date();

        	if (wait > 0)
        	{
        	    //if (_timersBlock)
        	    //{
        	        Packages.java.lang.Thread.sleep(wait);
        	    //}
        	    //else
        	    //{
        	    //    _pendingTimeouts.splice(0, 0, timeout);
        	    //    
        	    //    if (!_nextTimeout || _nextTimeout > timeout.date)
        	    //    {
                //        _nextTimeout = timeout.date;
                //        
            	//        
            	//        _timerThread = new java.lang.Thread(new java.lang.Runnable({
                //			run: function() {
                //    	        Packages.java.lang.Thread.sleep(wait);
                //    	        _nextTimeout = null;
                //			    serviceTimeouts();
                //			}
                //		}));
                //		
                //		_timerThread.start();
        	    //    }    
                //		
                //	return;
        	    //}
        	}

            // perform the callback
        	timeout.callback();
    	
    	    // if its an interval, reschedule it, otherwise clear it
        	if (timeout.repeat)
        	{
        	    var now = new Date(),
        	        proposed = new Date(timeout.date.getTime() + timeout.interval);
        	    timeout.date = (proposed < now) ? now : proposed;
        	    _pendingTimeouts.push(timeout);
        	}
        	else
                _timeouts[timeout.id] = null;
        }
    }
}

// load

if (!this.load)
{
    alert("Setting up 'load()'");
    this.load = function(path)
    {
        var contents = readFile(path);
        if (typeof Packages !== "undefined")
            return Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(window, contents, path, 0, null);
        else
            return eval(contents);
    }
}

// readFile

if (!this.readFile)
{
    if (this.File)
    {
        alert("Setting up 'readFile()' for SpiderMonkey");
        this.readFile = function(path)
        {
        	var f = new File(path);
	        
	        if (!f.canRead)
	        {
	            if (debug)
	                alert("can't read: " + f.path);
	                
	            return "";
	        }
	
	        if (debug)
	            alert("reading: " + f.path);
	
	        f.open("read", "text");
	        
	        var result = f.readAll().join("\n");
	        
	        f.close();
	        
        	return result;
        }
    }
    else if (this.Packages)
    {
        alert("Setting up 'readFile()' for Rhino");
        this.readFile = function(path, characterCoding)
        {
        	var f = new Packages.java.io.File(path);
	
	        if (!f.canRead())
	        {
	            if (debug)
	                alert("can't read: " + f.path);
	                
	            return "";
	        }
	
	        if (debug)
	            alert("reading: " + f.getAbsolutePath());
	
        	var fis = new Packages.java.io.FileInputStream(f),
        	    b = Packages.java.lang.reflect.Array.newInstance(Packages.java.lang.Byte.TYPE, fis.available());
        	
        	fis.read(b);
        	fis.close();

            if (characterCoding)
                return String(new Packages.java.lang.String(b, characterCoding));
            else
                return String(new Packages.java.lang.String(b));
        }
    }
    else
    {
        alert("Warning: No 'readFile' implementation available.")
    }
}

var hex_lookup = "0123456789abcdef";
function bytesToHexString(buf)
{
    var buffer = "";
	for (var i = 0 ; i < buf.length; i++)
		buffer += hex_lookup[(buf[i] >> 4) & 0x0F] + hex_lookup[buf[i] & 0x0F];
	return buffer;
}

// Rhino utilities
if (this.Packages) {
    alert("Setting up Rhino utilties");

    jsArrayToJavaArray = function(js_array, type)
    {
        var java_class = null;
        var java_converter = null;

        switch (type || ((js_array && js_array.length > 0) && typeof js_array[0]))
        {
            case "string":
            case "String":
                java_class = Packages.java.lang.String;
                java_converter = Packages.java.lang.String.valueOf;
                break;
            case "Boolean":
                java_class = Packages.java.lang.Boolean;
                java_converter = Packages.java.lang.Boolean.valueOf;
                break;
            case "boolean":
                java_class = Packages.java.lang.Boolean.TYPE;
                java_converter = function(input) { return Packages.java.lang.Boolean.valueOf(input).booleanValue(); };
                break;
            default:
                return null;
        }

        if (js_array && js_array.length > 0)
        {
            var java_array = Packages.java.lang.reflect.Array.newInstance(java_class, js_array.length);
            for (var i = 0; i < js_array.length; i++)
                java_array[i] = java_converter ? java_converter(js_array[i]) : js_array[i];
            return java_array;
        }

        return Packages.java.lang.reflect.Array.newInstance(java_class, 0);
    }
    
    jsObjectToJavaHashMap = function(js_object)
    {
        var map = Packages.java.util.HashMap();
        for (var i in js_object)
            map.put(i, js_object[i]);
        return map;
    }
    
	objj_console = function()
	{
		var br = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(Packages.java.lang.System["in"], "UTF-8"));
		
		keepgoing = true;
		while (keepgoing)
		{
			try {
				Packages.java.lang.System.out.print("objj> ");
			
				var input = String(br.readLine()),
				    fragments = objj_preprocess(input, new objj_bundle(), new objj_file(), OBJJ_PREPROCESSOR_DEBUG_SYMBOLS),
		            count = fragments.length,
					ctx = (new objj_context);

				if (count == 1 && (fragments[0].type & FRAGMENT_CODE))
				{
					var fragment = fragments[0];
			        var result = eval(fragment.info);
					if (result != undefined)
						print(result);
				}
		        else if (count > 0)
				{
			        while (count--)
			        {
			            var fragment = fragments[count];

			            if (fragment.type & FRAGMENT_FILE)
			                objj_request_file(fragment.info, (fragment.type & FRAGMENT_LOCAL), NULL);

			            ctx.pushFragment(fragment);
			        }
					
					ctx.schedule();
				}
			
				serviceTimeouts();
			} catch (e) {
				print(e);
			}
		}
	};

    var _documentBuilderFactory = Packages.javax.xml.parsers.DocumentBuilderFactory.newInstance();
    // setValidating to false doesn't seem to prevent it from downloading the DTD, but lets do it anyway
    _documentBuilderFactory.setValidating(false);
    
    _documentBuilder = _documentBuilderFactory.newDocumentBuilder();
    // prevent the Java XML parser from downloading the plist DTD from Apple every time we parse a plist
    _documentBuilder.setEntityResolver(new Packages.org.xml.sax.EntityResolver({
        resolveEntity: function(publicId, systemId) {
            //Packages.java.lang.System.out.println("publicId=" + publicId + " systemId=" + systemId);
            
            // TODO: return a local copy of the DTD?
            if (String(systemId) == "http://www.apple.com/DTDs/PropertyList-1.0.dtd")
                return new Packages.org.xml.sax.InputSource(new Packages.java.io.StringReader(""));
                
            return null;
        } 
    }));
    // throw an exception on error
    _documentBuilder.setErrorHandler(function(exception, methodName) {
    	throw exception;
    });

    copyInputStreamToOutputStream = function(is, os)
    {
        var buf = Packages.java.lang.reflect.Array.newInstance(Packages.java.lang.Byte.TYPE, 1024*10);
        var len = 0;
        while ((len = is.read(buf)) != -1)
        {
            os.write(buf, 0, len);
        }
    }
    var lineEnd = "\r\n";
    var twoHyphens = "--";
    var boundary = "----------------------------b453b5d52446";
    //var boundary = "----CappuccinoBoundary" + (new Date().getTime());
    multipartRequest = function(method, url, headers, parts)
    {
        var bufferSize = 1024*10,
    	    buffer = Packages.java.lang.reflect.Array.newInstance(Packages.java.lang.Byte.TYPE, bufferSize);

    	var url = new Packages.java.net.URL(url),
    	    connection = url.openConnection();

    	connection.setDoOutput(true);
    	connection.setDoInput(true);
    	connection.setRequestMethod(method);

        for (var i in headers)
        {
            print(i+":"+headers[i]);
            connection.setRequestProperty(i, headers[i]);
        }

        connection.setRequestProperty("Content-Type", "multipart/form-data; boundary="+ boundary);

        var output = new Packages.java.io.DataOutputStream(connection.getOutputStream());

    	for (var i = 0; parts && i < parts.length; i++)
    	{
    	    var part = parts[i];

        	output.writeBytes(twoHyphens + boundary + lineEnd);

        	if (part.headers)
            {
                for (var header in part.headers)
                {
            	    output.writeBytes(header +": " + part.headers[header] + lineEnd);
                }
            }
            output.writeBytes(lineEnd);

            if (part.data)
            {
                output.writeBytes(part.data);
            }
            else if (part.stream)
            {
                var	n;
            	while ((n = part.stream.read(buffer, 0, bufferSize)) > 0)
            	{
            		output.write(buffer, 0, n) 
            	}
            }

        	output.writeBytes(lineEnd);
    	}

    	output.writeBytes(twoHyphens + boundary + twoHyphens + lineEnd);
    	output.flush();
    	output.close();

    	var buffer,
    	    input = new Packages.java.io.DataInputStream(connection.getInputStream()),
            result = new Packages.java.lang.StringBuffer();

    	while (null != (buffer = input.readLine()))
    		result.append(buffer);

    	input.close();

        return String(result.toString());
    }
    
    parseXMLString = function(string) {
        return (_documentBuilder.parse(
            new Packages.org.xml.sax.InputSource(
                new Packages.java.io.StringReader(string))).getDocumentElement());
    }
}

// Environment variables

function getenv(variable)
{
    if (this.Packages)
        return String(Packages.java.lang.System.getenv().get(variable) || "") || null;
    else if (this.environment)
        return environment[variable] || null;
    return null;
}


// XMLHttpRequest

function XMLHttpRequest()
{
	this.readyState		= 0;
	this.responseText	= "";
	this.responseXML	= null;
	this.status			= null;
	this.statusText		= null;
	
	this.onreadystatechange = null;
	
	this.method		= null;
	this.url		= null;
	this.async		= null;
	this.username	= null;
	this.password	= null;
}
XMLHttpRequest.prototype.abort = function()
{
	this.readyState = 0;
}
XMLHttpRequest.prototype.open = function(method, url, async, username, password)
{
	this.readyState = 1;

	this.method		= method;
	this.url		= url;
	this.async		= async;
	this.username	= username;
	this.password	= password;
}
XMLHttpRequest.prototype.send = function(body)
{
	this.readyState = 3;
	
	this.responseText = "";
	this.responseXML = null;
	
	try
	{
		this.responseText = readFile(this.url, "UTF-8"); // FIXME: should we really assume this is UTF-8?
		
		if (debug)
		    alert("xhr response:  " + this.url + " (length="+this.responseText.length+")");
	}
	catch (e)
	{
	    if (debug)
	        alert("xhr exception: " + this.url);
    	this.responseText = "";
		this.responseXML = null;
	}    
	
	if (this.responseText.length > 0)
	{
		try
		{
			this.responseXML = _documentBuilder.parse(new Packages.org.xml.sax.InputSource(new Packages.java.io.StringReader(this.responseText)));
		}
		catch (e)
		{
			this.responseXML = null;
		}
	    this.status = 200;
	}
	else {
	    if (debug)
	        alert("xhr empty:     " + this.url);
	    this.status = 404;
	}
	
	this.readyState = 4;
	
    if (this.onreadystatechange)
    {
         if (this.async)
             setNativeTimeout(this.onreadystatechange, 0);
         else
             this.onreadystatechange();
    }
}
XMLHttpRequest.prototype.getResponseHeader = function(header)
{
	return (this.readyState < 3) ? "" : "";
}
XMLHttpRequest.prototype.getAllResponseHeaders = function()
{
	return (this.readyState < 3) ? null : "";
}
XMLHttpRequest.prototype.setRequestHeader = function(name, value)
{
}

objj_request_xmlhttp = function()
{
    return new XMLHttpRequest();
}


OBJJ_HOME = getenv("OBJJ_HOME");
if (!OBJJ_HOME)
{
    OBJJ_HOME = "/usr/local/share/objj";
    alert("OBJJ_HOME environment variable not set, defaulting to " + OBJJ_HOME);
}