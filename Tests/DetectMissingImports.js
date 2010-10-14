var FILE     = require("file"),
    FileList = require("jake").FileList,
    OS       = require("os"),
    stream   = require("narwhal/term").stream;

var cPreprocessedFileContents = function(aFilePath) 
{
    var gcc   = OS.popen("gcc -E -x c -P -DPLATFORM_COMMONJS " + OS.enquote(aFilePath), { charset:"UTF-8" }),
        chunk,
        fileContents = "";

    while (chunk = gcc.stdout.read())
        fileContents += chunk;
    
    return fileContents;
};

var checkImportsForFile = function (fileName)
{
    var classNames = [],
        errorMessageHashSet = {},
        matches = fileName.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));

    if (!FILE.exists(fileName) ||
        FILE.isDirectory(fileName) ||
        fileName.indexOf("+") !== -1 ||
        (matches && matches[1] === matches[2]))
        return;

    // this is a hackish way to clear the previous file's @imports
    for (var g in global)
        if (g !== "SyntaxError")
            delete global[g];

    // reload Objective-J and get a reference to its StaticResource export at
    // the same time
    global.StaticResource = require.force("objective-j").StaticResource;

    ObjectiveJ.OBJJ_INCLUDE_PATHS = [FILE.canonical(".")];

    var og_resolveResourceAtURL = StaticResource.resolveResourceAtURL;

    // this function gets called for all "File.j" imports
    // in case the import can't be resolved, use JAKE.FileList to try and find
    // it.
    StaticResource.resolveResourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ isDirectory, /*Function*/ aCallback)
    {
        var og_callback = arguments[2];
        arguments[2] = function (resource)
        {
            if (!resource)
            {
                var basename = FILE.basename(aURL.toString()),
                    newURL = (new FileList("Foundation/**/" + basename)).include("AppKit/**/" + basename).items()[0];


                if (newURL)
                    return og_resolveResourceAtURL(FILE.canonical(newURL), isDirectory, og_callback)
                else
                    og_callback(resource);
            }
            else
                og_callback(resource);
            
        };

        og_resolveResourceAtURL.apply(this, arguments);
    };

    // this function gets called for <Framework/File.j> imports
    // since this script looks at the un-compiled frameworks,
    // some trickery for finding the correct file is sometimes necessary
    var resolveResourceAtURLSearchingIncludeURLs = function (/*CFURL*/ aURL, /*Number*/ anIndex, /*Function*/ aCallback)
    {
        var includeURLs = StaticResource.includeURLs(),
            searchURL = new CFURL(aURL, includeURLs[anIndex]).absoluteURL();

        og_resolveResourceAtURL(searchURL, NO, function(/*StaticResource*/ aStaticResource)
        {
            if (!aStaticResource)
            {
                if (anIndex + 1 < includeURLs.length)
                    resolveResourceAtURLSearchingIncludeURLs(aURL, anIndex + 1, aCallback);
                else
                {
                    var basename = FILE.basename(aURL),
                        newURL = (new FileList("Foundation/**/" + basename)).include("AppKit/**/" + basename).items()[0];
            
                    if (newURL)
                        resolveResourceAtURLSearchingIncludeURLS(FILE.canonical(newURL), anIndex, aCallback);
                    else
                        aCallback(NULL);
                }

                return;
            }

            aCallback(aStaticResource);
        });
    }
    StaticResource.resolveResourceAtURLSearchingIncludeURLs = function(/*CFURL*/ aURL, /*Function*/ aCallback)
    {
        resolveResourceAtURLSearchingIncludeURLs(aURL, 0, aCallback);
    }; 

    // find all the @implementations by running through the CPP and then
    // calling ObjectiveJ.preprocess with a decorated @implementation handler
    // on the Preprocessor
    var fileNameContents = cPreprocessedFileContents(fileName);
    var og_objj_implementation = ObjectiveJ.Preprocessor.prototype.implementation;
    ObjectiveJ.Preprocessor.prototype.implementation = function (tokens)
    {
        var className = tokens.skip_whitespace();
        if (classNames.indexOf(className) === -1)
            classNames.push(className);

        tokens.skip_whitespace(YES);

        og_objj_implementation.apply(this, arguments);
    };

    ObjectiveJ.preprocess(fileNameContents);

    // reset the preprocessor's @implementation handler
    ObjectiveJ.Preprocessor.prototype.implementation = og_objj_implementation;

    // do automatic CPP runs on @imported files
    // to resolve #includes and conditional compilation
    CFHTTPRequest.prototype.responseText = function ()
    {
        if (this._URL.slice(-2) === ".j")
        {
            var tmpFile = FILE.canonical(FILE.join(FILE.dirname(this._URL.split(":")[1]), ".detect_missing_imports"));

            // hackishly give the file a window object
            FILE.write(tmpFile, "window = {};\n" + this._nativeRequest.responseText);
            var result = cPreprocessedFileContents(tmpFile);
            FILE.remove(tmpFile);
        }
        else
            result = this._nativeRequest.responseText;
        return result;
    };

    try 
    {
        objj_importFile(FILE.canonical(fileName), YES);
    }
    catch (e)
    {
        if (e.name === "ReferenceError")
            stream.print("\0yellow(Detected missing @import in \"" + fileName + "\": " + e.message + "\0)");
        else
            throw e;
    }

    for(var j = 0, jj = classNames.length; j < jj; ++j) 
    {
        var className = classNames[j],
            cls = objj_getClass(className);
        if (cls && cls.super_class)
        {
            // instance methods
            var method_dtable = cls.method_dtable;
            for (var methodName in method_dtable)
            {
                if (method_dtable.hasOwnProperty(methodName))
                {
                    try
                    {
                        var instance = objj_msgSend(cls, "alloc");
                        objj_msgSend(instance, methodName, method_dtable[methodName].types.slice(1));
                    }
                    catch (e)
                    {
                        if (e.name === "ReferenceError")
                        {
                            var hashKey = fileName + e.message;
                            if (!errorMessageHashSet[hashKey])
                            {
                                stream.print("\0yellow(Detected missing @import in \"" + fileName + "\": " + e.message +  " (Context: [" + className + " " + methodName + "])\0)");
                                errorMessageHashSet[hashKey] = true;   
                            }
                        }
                    }
                }
            }

            // class methods
            method_dtable = cls.isa.method_dtable;
            for (var methodName in method_dtable)
            {
                if (method_dtable.hasOwnProperty(methodName))
                {
                    try
                    {
                        objj_msgSend(cls, methodName);
                    }
                    catch (e)
                    {
                        if (e.name === "ReferenceError")
                        {
                            var hashKey = fileName + e.message;
                            if (!errorMessageHashSet[hashKey])
                            {
                                stream.print("\0yellow(Detected missing @import in \"" + fileName + "\": " + e.message +  " (Context: [" + className + " " + methodName + "])\0)");
                                errorMessageHashSet[hashKey] = true;
                            }
                        }
                    }
                }
            }
        }
    }
};

(new FileList("Foundation/**.j").include("AppKit/**.j")).forEach(function (aFile)
{
    checkImportsForFile(aFile);
});
