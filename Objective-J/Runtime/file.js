/*
 * file.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

// Notes: requests may return immediately (i.e. in IE when a file has been cached).  Don't assume 
// One line of code thus follows another, it may call the callback first!

// FIXME: If we ever have bundles that replace only some files, we will definitely run into problems.
// Look inside bundleResponseCallback.


var OBJJ_ENVIRONMENTS = ENVIRONMENTS;

#ifdef PLATFORM_USERAGENT
var userAgent = window.navigator.userAgent;

if (userAgent.indexOf("MSIE") !== -1)
{
    if (userAgent.indexOf("MSIE 8") !== -1)
        OBJJ_ENVIRONMENTS.unshift("IE8");
    else
        OBJJ_ENVIRONMENTS.unshift("IE7");
}
else
    OBJJ_ENVIRONMENTS.unshift("W3C");
#endif

#define DIRECTORY(aPath) (aPath).substr(0, (aPath).lastIndexOf('/') + 1)

function objj_mostEligibleEnvironmentFromArray(environments)
{
    var index = 0,
        count = OBJJ_ENVIRONMENTS.length,
        innerCount = environments.length;

    // Ugh, no indexOf, no objects-in-common.
    for(; index < count; ++index)
    {
        var innerIndex = 0,
            environment = OBJJ_ENVIRONMENTS[index];
        
        for (; innerIndex < innerCount; ++innerIndex)
            if(environment === environments[innerIndex])
                return environment;
    }

    return NULL;
}

var OBJJFileNotFoundException       = "OBJJFileNotFoundException",
    OBJJExecutableNotFoundException = "OBJJExecutableNotFoundException";

var objj_files              = { },
    objj_bundles            = { },
    objj_bundlesForClass    = { },
    objj_searches           = { };

var OBJJ_NO_FILE            = {};

if (typeof OBJJ_INCLUDE_PATHS === "undefined")
    OBJJ_INCLUDE_PATHS  = ["Frameworks", "SomethingElse"];

var OBJJ_BASE_URI           = "";

IF (OPERA)

var DOMBaseElement = document.getElementsByTagName("base")[0];
    
if (DOMBaseElement)
    OBJJ_BASE_URI = DIRECTORY(DOMBaseElement.getAttribute('href'));

ENDIF

function objj_file()
{
    this.path       = NULL;
    this.bundle     = NULL;

    this.included   = NO;

    this.contents   = NULL;
    this.fragments  = NULL;
}

function objj_bundle()
{
    this.path       = NULL;
    this.info       = NULL;

    this._URIMap    = { };

    this.__address  = _objj_generateObjectHash();
}

function objj_getBundleWithPath(aPath)
{
    return objj_bundles[aPath];
}

function objj_setBundleForPath(aPath, aBundle)
{
    objj_bundles[aPath] = aBundle;
}

function objj_bundleForClass(aClass)
{
    return objj_bundlesForClass[aClass.name];
}

function objj_addClassForBundle(aClass, aBundle)
{
    objj_bundlesForClass[aClass.name] = aBundle;
}

function objj_request_file(aFilePath, shouldSearchLocally, aCallback)
{
    new objj_search(aFilePath, shouldSearchLocally, aCallback).attemptNextSearchPath();
}

var objj_search = function(aFilePath, shouldSearchLocally, aCallback)
{
    this.filePath = aFilePath;
    
    this.bundle                 = NULL;
    this.bundleObservers        = [];
    
    this.searchPath             = NULL;
    this.searchedPaths          = [];
    this.includePathsIndex      = shouldSearchLocally ? -1 : 0;
    
    this.searchRequest          = NULL;
    
    this.didCompleteCallback    = aCallback;
}

objj_search.prototype.nextSearchPath = function()
{
    // FIXME: Path searching should be more complex (go up directories, etc).
    var path = objj_standardize_path((this.includePathsIndex == -1 ? "" : OBJJ_INCLUDE_PATHS[this.includePathsIndex] + '/') + this.filePath);
    
    ++this.includePathsIndex;
    
    return path;
}

objj_search.prototype.attemptNextSearchPath = function()
{
    var searchPath = this.nextSearchPath(),
        file = objj_files[searchPath];

    objj_alert("Will attempt to find " + this.filePath + " at " + searchPath);
        
    // If a file for this search path already exists, then it has already been downloaded.
    // If there is a callback, we can just call it, if not, we can simply return.
    if (file)
    {
        objj_alert("The file request at " + this.filePath + " has already been downloaded at " + searchPath);
        // FIXME: Do we need this for everything?
#if RHINO
        var index = 0,
            count = this.searchedPaths.length;
            
        for (; index < count; ++index)
            objj_files[this.searchedPaths[index]] = file;
#endif
        if (this.didCompleteCallback)
            this.didCompleteCallback(file);
            
        return;
    }
    
    var existingSearch = objj_searches[searchPath];

    // If there is already an ongoing search for this search path, then we can let it find 
    // the file for us.  Make sure to assign it our callback, if we have one, since only 
    // one search can have a callback at a time.
    if (existingSearch)
    {
        if (this.didCompleteCallback)
            existingSearch.didCompleteCallback = this.didCompleteCallback;
        
        return;
    }
    
    // At this point we have a legitimate search, so we should take note of this search path
    // in our search paths.
    this.searchedPaths.push(this.searchPath = searchPath);
    
    // Before we kick off our ajax requests, see whether this directory already has 
    // a bundle associated with it.
    var infoPath = objj_standardize_path(DIRECTORY(searchPath) + "Info.plist"),
        bundle = objj_bundles[infoPath];
    
    // If there is, then simply look for the file in question.
    if (bundle)
    {
        this.bundle = bundle;
        this.request(searchPath, this.didReceiveSearchResponse);
    }
    else
    {
        // If there isn't a bundle associated with this directory, then we also have to 
        // search for an Info.plist.
        var existingBundleSearch = objj_searches[infoPath];
        
        // Again, if a search already exists for this bundle, then add ourselves to the list 
        // of observers for when this bundle is either found or created.
        if (existingBundleSearch)
        {
            --this.includePathsIndex;
            this.searchedPaths.pop();
             if (this.searchedPaths.length)
                 this.searchPath = this.searchedPaths[this.searchedPaths.length - 1];
             else
                 this.searchPath = NULL;

            existingBundleSearch.bundleObservers.push(this);
            return;
        }
        // If not, then look for it.
        else
        {
            this.bundleObservers.push(this);
            this.request(infoPath, this.didReceiveBundleResponse);
            
            // Requests may return immediately, so by this point, we may have already gotten the bundle and replaced the file.
            if (!this.searchReplaced)
                this.searchRequest = this.request(searchPath, this.didReceiveSearchResponse);
        }   
    }
}

IF (ACTIVE_X)

objj_search.responseCallbackLock = NO;
objj_search.responseCallbackQueue = [];

objj_search.removeResponseCallbackForFilePath = function(aFilePath)
{
    var queue = objj_search.responseCallbackQueue,
        index = queue.length;
        
    while (index--)
        if (queue[index][3] == aFilePath)
        {
            queue.splice(index, 1);
            return;
        }
}

objj_search.serializeResponseCallback = function(aMethod, aSearch, aResponse, aFilePath)
{
    var queue = objj_search.responseCallbackQueue;
    
    queue.push([aMethod, aSearch, aResponse, aFilePath]);

    if (objj_search.responseCallbackLock)
        return;
    objj_search.responseCallbackLock = YES;

    while (queue.length)
    {
        var callback = queue[0];
        queue.splice(0, 1);

        callback[0].apply(callback[1], [callback[2]]);
    }
    
    objj_search.responseCallbackLock = NO;
}

ENDIF

objj_search.prototype.request = function(aFilePath, aMethod)
{
    var search = this,
        isPlist = aFilePath.substr(aFilePath.length - 6, 6) == ".plist",
        request = objj_request_xmlhttp(),
        response = objj_response_xmlhttp();

    response.filePath = aFilePath;

    request.onreadystatechange = function()
    {
        if (request.readyState == 4)
        {   
            if (response.success = (request.status != 404 && request.responseText && request.responseText.length) ? YES : NO)
            {
                if (window.files_total)
                {
                    if (!window.files_loaded)
                        window.files_loaded = 0;
                        
                    window.files_loaded += request.responseText.length;
                    
                    if (window.update_progress)
                        window.update_progress(window.files_loaded / window.files_total);
                }
                    
                if (isPlist)
                    response.xml = objj_standardize_xml(request);
                else
                    response.text = request.responseText;
            }
            
            if (ACTIVE_X)
                objj_search.serializeResponseCallback(aMethod, search, response, aFilePath);
            else
                aMethod.apply(search, [response]);
        }
    }

    objj_searches[aFilePath] = this; 

    if (request.overrideMimeType && isPlist)
        request.overrideMimeType('text/xml');
        
    if (OPERA && aFilePath.charAt(0) != '/')
        aFilePath = OBJJ_BASE_URI + aFilePath;

    try
    {
        // unclear whether plusses are reserved in the URI path
        //request.open("GET", aFilePath.replace(/\+/g, "%2B"), YES);
        request.open("GET", aFilePath, YES);
        request.send("");
    }
    catch (anException)
    {
        response.success = NO;
        
        if (ACTIVE_X)
            objj_search.serializeResponseCallback(aMethod, search, response, aFilePath);
        else
            aMethod.apply(search, [response]);
    }
    
    return request;
}

objj_search.prototype.didReceiveSearchResponse = function(aResponse)
{
    // If we do not have a bundle yet, we cannot appropriately 
    // handle this response, so wait.
    if (!this.bundle)
    {
        this.cachedSearchResponse = aResponse;
        return;
    }
    
    if (aResponse.success)
    {
        file = new objj_file();
    
        file.path = aResponse.filePath;
        file.bundle = this.bundle
        file.contents = aResponse.text;
        
        this.complete(file);
    }
    else if (this.includePathsIndex < OBJJ_INCLUDE_PATHS.length)
    {
        // Clear out the bundle since it will no longer be valid.
        // FIXME: FIXME: FIXME: WARNING: Wouldn't it be cleaner to just always do this in attemptNextSearchPath?
        this.bundle = NULL;
        this.attemptNextSearchPath();
    }
    else
        objj_exception_throw(new objj_exception(OBJJFileNotFoundException, "*** Could not locate file named \"" + this.filePath + "\" in search paths."));
}

objj_search.prototype.didReceiveBundleResponse = function(aResponse)
{
    var bundle = new objj_bundle();
    
    bundle.path = aResponse.filePath;
    
    if (aResponse.success)
        bundle.info = CPPropertyListCreateFromXMLData(aResponse.xml);
    else
        bundle.info = new objj_dictionary();
    
    objj_bundles[aResponse.filePath] = bundle;
    
    var executablePath = dictionary_getValue(bundle.info, "CPBundleExecutable");
    
    if (executablePath)
    {
        var environment = objj_mostEligibleEnvironmentFromArray(dictionary_getValue(bundle.info, "CPBundleEnvironments"));
        
        executablePath = environment + ".environment/" + executablePath;

        this.request(DIRECTORY(aResponse.filePath) + executablePath, this.didReceiveExecutableResponse);
        
        // FIXME: Is this the right approach?
        // Request the compiled file regardless of whether our current inquiry 
        var directory = DIRECTORY(aResponse.filePath),
            replacedFiles = dictionary_getValue(dictionary_getValue(bundle.info, "CPBundleReplacedFiles"), environment),
            index = 0,
            count = replacedFiles.length;
        
        for (; index < count; ++index)
        {
            // Halt any forward searches of these files from taking place.
            objj_searches[directory + replacedFiles[index]] = this;
            
            if (directory + replacedFiles[index] == this.searchPath)
            {
                this.searchReplaced = YES;
                
                if (!this.cachedSearchResponse && this.searchRequest)
                    this.searchRequest.abort();
                    
                if (ACTIVE_X)
                    objj_search.removeResponseCallbackForFilePath(this.searchPath);
            }
        }
    }
    this.bundle = bundle;
    var observers = this.bundleObservers,
        index = 0,
        count = observers.length;
            
    for(; index < count; ++index)
    {
        var observer = observers[index];
      
        // Force the observer to just attempt the path all over again, 
        // since it may have been replaced by the executable.
        // FIXME: we should be just reattempting the ones that collided.
        if (observer != this)
            observer.attemptNextSearchPath();
            
        // If we have a cached response and the search has not been 
        // replaced by the executable, then let it proceed.
        else if (this.cachedSearchResponse && !this.searchReplaced)
            this.didReceiveSearchResponse(this.cachedSearchResponse);
    }
    
    this.bundleObservers = [];
}

objj_search.prototype.didReceiveExecutableResponse = function(aResponse)
{
    if (!aResponse.success)
        objj_exception_throw(new objj_exception(OBJJExecutableNotFoundException, "*** The specified executable could not be located at \"" + this.filePath + "\"."));
    
    var files = objj_decompile(aResponse.text, this.bundle),
        index = 0,
        count = files.length,
        length = this.filePath.length;
    
    for (; index < count; ++index)
    {
        var file = files[index],
            path = file.path;
        
        if (this.filePath == path.substr(path.length - length))
            this.complete(file);
        else
            objj_files[path] = file;
    }
}

objj_search.prototype.complete = function(aFile)
{
    var index = 0,
        count = this.searchedPaths.length;
        
    for (; index < count; ++index)
    {
        objj_files[this.searchedPaths[index]] = aFile;
        //FIXME: uncomment this:
        //delete objj_inquiries[anInquiry.searchedPaths[index]];
    }
    
    if (this.didCompleteCallback)
        this.didCompleteCallback(aFile);
}

// objj_standardize_path
//
// Standardizes the input path by removing extrenenous components and resolving 
// references to parent directories.

function objj_standardize_path(aPath)
{
    if (aPath.indexOf("/./") != -1 && aPath.indexOf("//") != -1 && aPath.indexOf("/../") != -1)
        return aPath;

    var index = 0,
        components = aPath.split('/');

    for(;index < components.length; ++index)
        if(components[index] == "..")
        {
            components.splice(index - 1, 2);
            index -= 2;
        }
        else if(index != 0 && !components[index].length || components[index] == '.' || components[index] == "..")
            components.splice(index--, 1);
    
    return components.join('/');
}

IF (ACTIVE_X)

var objj_standardize_xml = function(aRequest)
{
    var XMLData = new ActiveXObject("Microsoft.XMLDOM");
    XMLData.loadXML(aRequest.responseText.substr(aRequest.responseText.indexOf(".dtd\">") + 6));
    
    return XMLData;
}

ELSE

var objj_standardize_xml = function(aRequest)
{
    return aRequest.responseXML;
}

ENDIF

function objj_response_xmlhttp()
{
    return new Object;
}

// objj_request_xmlhttp()
//
// To be used as a browser-independent implementation of XMLHttpRequest. 
// Currently known to support Safari, Firefox, IE 6/7, and Opera.
//
// Throws a primitive exception if XMLHttpRequests are not supported on 
// the given browser.

IF (NATIVE_XMLHTTPREQUEST)

var objj_request_xmlhttp = function()
{
    return new XMLHttpRequest();
}

ELIF (ACTIVE_X)

// DON'T try 4.0 and 5.0.  Should we be trying anything other than 3.0 and 6.0?
// http://blogs.msdn.com/xmlteam/archive/2006/10/23/using-the-right-version-of-msxml-in-internet-explorer.aspx
var MSXML_XMLHTTP_OBJECTS = [ "Microsoft.XMLHTTP", "Msxml2.XMLHTTP", "Msxml2.XMLHTTP.3.0", "Msxml2.XMLHTTP.6.0" ],//"Msxml2.XMLHTTP.4.0", "Msxml2.XMLHTTP.5.0" ],
    index = MSXML_XMLHTTP_OBJECTS.length;

while (index--)
{
    try
    {
        new ActiveXObject(MSXML_XMLHTTP_OBJECTS[index]);
        break;
    }
    catch (anException)
    {
    }
}

var MSXML_XMLHTTP = MSXML_XMLHTTP_OBJECTS[index];

delete index;
delete MSXML_XMLHTTP_OBJECTS;

var objj_request_xmlhttp = function()
{
    return new ActiveXObject(MSXML_XMLHTTP);
}

ENDIF


var OBJJUnrecognizedFormatException = "OBJJUnrecognizedFormatException";

var STATIC_MAGIC_NUMBER     = "@STATIC",
    MARKER_PATH             = "p",
    MARKER_URI              = "u",
    MARKER_CODE             = "c",
    MARKER_BUNDLE           = "b",
    MARKER_TEXT             = "t",
    MARKER_IMPORT_STD       = 'I',
    MARKER_IMPORT_LOCAL     = 'i';

var STATIC_EXTENSION        = "sj";

function objj_decompile(aString, bundle)
{
    var stream = new objj_markedStream(aString);
    
    if (stream.magicNumber() != STATIC_MAGIC_NUMBER)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format in bundle: "+bundle));
    
    if (stream.version() != 1.0)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format in bundle: "+bundle));
    
    var file = NULL,
        files = [],
        marker;
    
    while (marker = stream.getMarker())   
    {
        var text = stream.getString();
        
        switch (marker)
        {
            case MARKER_PATH:           if (file && file.contents && file.path === file.bundle.path)
                                            file.bundle.info = CPPropertyListCreateWithData({string:file.contents});

                                        file = new objj_file();
                                        file.path = DIRECTORY(bundle.path) + text;
                                        file.bundle = bundle;
                                        file.fragments = [];
                                        
                                        files.push(file);
                                        
                                        objj_files[file.path] = file;
                                        
                                        break;

            case MARKER_URI:            var URI = stream.getString();
                                        if (URI.toLowerCase().indexOf("mhtml:") === 0)
                                            URI = "mhtml:" + DIRECTORY(window.location.href) + '/' + DIRECTORY(bundle.path) + '/' + URI.substr("mhtml:".length);
                                        bundle._URIMap[text] = URI;

                                        break;

            case MARKER_BUNDLE:         var bundlePath = DIRECTORY(bundle.path) + '/' + text;
            
                                        file.bundle = objj_getBundleWithPath(bundlePath);
                                        
                                        if (!file.bundle)
                                        {
                                            file.bundle = new objj_bundle();
                                            file.bundle.path = bundlePath;
                                            
                                            objj_setBundleForPath(file.bundle, bundlePath);
                                        }
                                        
                                        break;
                                        
            case MARKER_TEXT:           file.contents = text;
                                        break;
                                        
            case MARKER_CODE:           file.fragments.push(fragment_create_code(text, bundle, file));
                                        break;
            case MARKER_IMPORT_STD:     file.fragments.push(fragment_create_file(text, bundle, NO, file));
                                        break;
            case MARKER_IMPORT_LOCAL:   file.fragments.push(fragment_create_file(text, bundle, YES, file));
                                        break;
        }
    }
    
    if (file && file.contents && file.path === file.bundle.path)
        file.bundle.info = CPPropertyListCreateWithData({string:file.contents});
    
    return files;    
}
