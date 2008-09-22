   ////////////
  // window //
 ////////////

if (!this.window)
    this.window = this;

   ///////////////
  // DOMParser //
 ///////////////

/*function DOMParser() {};
DOMParser.prototype.parseFromString = function(text, contentType) {
	return new DOMDocument(
		new Packages.org.xml.sax.InputSource(
			new Packages.java.io.StringReader(text)));
};*/

function Image() { }

   ///////////////////////
  // window.setTimeout //
 ///////////////////////

function setTimeout(code, delay) {
	var func;
	
	if (typeof code == "function")
		func = code;
	else if (typeof code == "string")
		func = function () { eval(code); };
	else
		return;
		
	pendingTimeouts.push(func);
}

pendingTimeouts = [];

function pendingTimeout() {
	return pendingTimeouts.length > 0;
}

function serviceTimeout() {
	if (pendingTimeout()) {
		func = pendingTimeouts.shift();
		return func();
	}
}

function serviceTimeouts() {
	while (pendingTimeout()) {
		serviceTimeout();
	}
}

   ////////////////////////////
  // alert, prompt, confirm //
 ////////////////////////////

if (typeof alert == "undefined")
{
    alert = function(obj) {
        if (typeof debug != "undefined" && debug) {
            var result = typeof Packages != "undefined" ? Packages.java.lang.Thread.currentThread().getName() + ": " + obj : String(obj);

            if (typeof print != "undefined")
                print(result);
            else if (typeof Packages != "undefined")
    	        Packages.java.lang.System.out.println(result);
        }
    }
    confirm = function(obj) { alert(obj); return true; }
    prompt  = function(obj) { alert(obj); return ""; }
}


   ////////////////////
  // readFile, load //
 ////////////////////

if (typeof readFile == "undefined") {
    if (typeof File != "undefined") {
        alert("Setting up \"readFile()\" for Spidermonkey");
        this.readFile = function(path) {
        	var f = new File(path);
	        
	        if (!f.canRead) {
	            //alert("can't read: " + f.path)
	            return "";
	        }
	
	        //alert("reading: " + f.path);
	
	        f.open("read", "text");
	        
	        var result = f.readAll().join("\n");
	        
	        f.close();
	        
        	return result;
        }
    }
    else if (typeof Packages != "undefined") {
        alert("Setting up \"readFile()\" for Rhino");
        readFile = function(path, characterCoding) {
        	var f = new Packages.java.io.File(path);
	
	        if (!f.canRead()) {
	            alert("can't read: " + f.path)
	            return "";
	        }
	
	        alert("reading: " + f.getAbsolutePath());
	
        	var fis = new Packages.java.io.FileInputStream(f);
        	
        	var b = Packages.java.lang.reflect.Array.newInstance(Packages.java.lang.Byte.TYPE, fis.available());
        	fis.read(b);
        	
        	fis.close();

            if (characterCoding)
                return String(new Packages.java.lang.String(b, characterCoding));
            else
                return String(new Packages.java.lang.String(b));
        }
    }
    else {
        alert("Warning: No \"readFile\" implementation available.")
    }
}

if (typeof load == "undefined") {
    alert("Setting up \"load()\"");
    load = function(path) {
        return eval(readFile(path));
    }
}

   /////////////
  // inspect //
 /////////////

function insp(obj) {
    for (var i in obj)
        alert(i + " ("+(typeof obj[i])+")");
}
function inspect(obj) {
	var a = [];
	for (var i in obj)
		a.push({name:i, type:(typeof obj[i])});
	a = a.sort(function(a,b) { return a.name.localeCompare(b.name); });
	for (var i = 0; i < a.length; i++)
		alert(a[i].name + " ("+a[i].type+")");
}

function time(fn) {
    var start = new Date();
    
    fn();
    
    var elapsed = ((new Date()) - start) / 1000;
    var minutes = Math.floor(elapsed/60);
    var seconds = elapsed - minutes * 60;
    
    alert("real\t"+minutes+"m"+seconds+"s");
}

function recordGlobals() {
    GLOBALS_BEFORE = {};
    for (var i in this)
        GLOBALS_BEFORE[i] = true;
}
function printGlobalsDiff() {
    for (var i in this)
        if (GLOBALS_BEFORE[i] == undefined)
            alert("NEW: " + i);
    for (var i in GLOBALS_BEFORE)
        if (this[i] == undefined)
            alert("MISSING: " + i);
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
if (typeof Packages != "undefined") {
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
		var br = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(Packages.java.lang.System["in"]));
		
		keepgoing = true;
		while (keepgoing)
		{
			try {
				Packages.java.lang.System.out.print("objj> ");
			
				var input = br.readLine();
				
				var fragments = objj_preprocess(String(input)),
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

function getEnv(variable)
{
    if (typeof Packages != "undefined")
        return String(Packages.java.lang.System.getenv().get(variable) || "") || null;
    else if (typeof environment != "undefined")
        return environment[variable] || null;
    return null;
}

OBJJ_HOME = getEnv("OBJJ_HOME");
if (!OBJJ_HOME)
{
    OBJJ_HOME = "/usr/local/share/objj";
    alert("OBJJ_HOME environment variable not set, defaulting to " + OBJJ_HOME);
}

   ////////////////////
  // XMLHttpRequest //
 ////////////////////

function XMLHttpRequest() {
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
XMLHttpRequest.prototype.abort = function() {
	this.readyState = 0;
}
XMLHttpRequest.prototype.open = function(method, url, async, username, password) {
	this.readyState = 1;

	this.method		= method;
	this.url		= url;
	this.async		= async;
	this.username	= username;
	this.password	= password;
}
XMLHttpRequest.prototype.send = function(body) {
	this.readyState = 3;
	
	this.responseText = "";
	this.responseXML = null;
	
	try {
		this.responseText = readFile(this.url);
		alert("xhr response:  " + this.url + " (length="+this.responseText.length+")");
	} catch (e) {
	    alert("xhr exception: " + this.url);
    	this.responseText = "";
		this.responseXML = null;
	}    
	
	if (this.responseText.length > 0) {
		try {
			this.responseXML = _documentBuilder.parse(new Packages.org.xml.sax.InputSource(new Packages.java.io.StringReader(this.responseText)));
		} catch (e) {
			this.responseXML = null;
		}
	    this.status = 200;
	}
	else {
	    alert("xhr empty:     " + this.url);
	    this.status = 404;
	}
	
	this.readyState = 4;
	
    if (this.onreadystatechange)
    {
         if (this.async)
             setTimeout(this.onreadystatechange, 0);
         else
             this.onreadystatechange();
    }
}
XMLHttpRequest.prototype.getResponseHeader = function(header) {
	return (this.readyState < 3) ? "" : "";
}
XMLHttpRequest.prototype.getAllResponseHeaders = function() {
	return (this.readyState < 3) ? null : "";
}
XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
}

objj_request_xmlhttp = function()
{
    return new XMLHttpRequest();
}
