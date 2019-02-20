/*
 * Executable.js
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


var ExecutableUnloadedFileDependencies         = 0,
    ExecutableLoadingFileDependencies          = 1,
    ExecutableLoadedFileDependencies           = 2,
    ExecutableCantStartLoadYetFileDependencies = 3,
    AnonymousExecutableCount            = 0;

function Executable(/*String*/ aCode, /*Array*/ fileDependencies, /*CFURL|String*/ aURL, /*Function*/ aFunction, /*ObjJCompiler*/aCompiler, /*Dictionary*/ aFilenameTranslateDictionary, /* Base64 String */ sourceMap)
{
    if (arguments.length === 0)
        return this;

    this._code = aCode;
    this._function = aFunction || null;
    this._URL = makeAbsoluteURL(aURL || new CFURL("(Anonymous" + (AnonymousExecutableCount++) + ")"));

    this._compiler = aCompiler || null;

    this._fileDependencies = fileDependencies;
    this._filenameTranslateDictionary = aFilenameTranslateDictionary;

    if (sourceMap)
        this._base64EncodedSourceMap = sourceMap;

    // This is a little hacky but if fileDependencies is null we can start loading file dependencies yet
    if (!fileDependencies)
    {
        this._fileDependencyStatus = ExecutableCantStartLoadYetFileDependencies;
        this._fileDependencyCallbacks = [];
    }
    else if (fileDependencies.length)
    {
        this._fileDependencyStatus = ExecutableUnloadedFileDependencies;
        this._fileDependencyCallbacks = [];
    }
    else
    {
        this._fileDependencyStatus = ExecutableLoadedFileDependencies;
    }

    if (this._function)
        return;

    if (!aCompiler)
        this.setCode(aCode);
}

exports.Executable = Executable;

Executable.prototype.path = function()
{
    return this.URL().path();
};

Executable.prototype.URL = function()
{
    return this._URL;
};

DISPLAY_NAME(Executable.prototype.URL);

Executable.prototype.functionParameters = function()
{
    var functionParameters = ["global", "objj_executeFile", "objj_importFile"];

//exportedNames().concat("objj_executeFile", "objj_importFile");

#ifdef COMMONJS
    functionParameters = functionParameters.concat("require", "exports", "module", "system", "print", "window");
#endif

    return functionParameters;
};

DISPLAY_NAME(Executable.prototype.functionParameters);

Executable.prototype.functionArguments = function()
{
    var functionArguments = [global, this.fileExecuter(), this.fileImporter()];

#ifdef COMMONJS
    functionArguments = functionArguments.concat(Executable.commonJSArguments());
#endif

    return functionArguments;
};

DISPLAY_NAME(Executable.prototype.functionArguments);

#ifdef COMMONJS
Executable.setCommonJSParameters = function()
{
    this._commonJSParameters = Array.prototype.slice.call(arguments);
};

Executable.commonJSParameters = function()
{
    return this._commonJSParameters || [];
};

Executable.setCommonJSArguments = function()
{
    this._commonJSArguments = Array.prototype.slice.call(arguments);
};

Executable.commonJSArguments = function()
{
    return this._commonJSArguments || [];
};

Executable.setFilenameTranslateDictionary = function(dict)
{
    this._filenameTranslateDictionary = dict;
};

Executable.filenameTranslateDictionary = function()
{
    return this._filenameTranslateDictionary || {};
};


Executable.prototype.toMarkedString = function()
{
    var markedString = "@STATIC;1.0;",
        dependencies = this.fileDependencies(),
        index = 0,
        count = dependencies.length;

    for (; index < count; ++index)
        markedString += dependencies[index].toMarkedString();

    var sourceMap = this._base64EncodedSourceMap;

    if (sourceMap) {
        markedString += MARKER_SOURCE_MAP + ";" + sourceMap.length + ";" + sourceMap;
    }

    var code = this.code();

    return markedString + MARKER_TEXT + ";" + code.length + ";" + code;
};
#endif

Executable.prototype.execute = function()
{
#if EXECUTION_LOGGING
    CPLog("EXECUTION: " + this.URL());
#endif

    if (this._compiler)
    {
        var fileDependencies = this.fileDependencies(),
            index = 0,
            count = fileDependencies.length;

        this._compiler.pushImport(this.URL().lastPathComponent());
        for (; index < count; ++index)
        {
            var fileDependency = fileDependencies[index],
                isQuoted = fileDependency.isLocal(),
                URL = fileDependency.URL();

            this.fileExecuter()(URL, isQuoted);
        }
        this._compiler.popImport();

        this.setCode(this._compiler.compilePass2(), this._compiler.map());

        if (FileExecutable.printWarningsAndErrors(this._compiler, exports.messageOutputFormatInXML))
            throw "Compilation error";

        this._compiler = null;
    }

    var oldContextBundle = CONTEXT_BUNDLE;

    // FIXME: Should we have stored this?
    CONTEXT_BUNDLE = CFBundle.bundleContainingURL(this.URL());

    var result = this._function.apply(global, this.functionArguments());

    CONTEXT_BUNDLE = oldContextBundle;

    return result;
};

DISPLAY_NAME(Executable.prototype.execute);

Executable.prototype.code = function()
{
    return this._code;
};

DISPLAY_NAME(Executable.prototype.code);

Executable.prototype.setCode = function(code, sourceMap)
{
    this._code = code;

    var parameters = this.functionParameters().join(",");
    var sourceMapBase64;

#if COMMONJS
    if (typeof system !== "undefined" && system.engine === "rhino")
    {
        code = "function(" + parameters + "){" + code + "/**/\n}";
        this._function = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, code, this.URL().absoluteString(), 0, NULL);
    }
    else
    {
#endif
#if DEBUG
        // Check if base64 source map is available
        sourceMapBase64 = this._base64EncodedSourceMap;

    // "//# sourceURL=" at the end lets us name our eval'd files for debuggers, etc.
    // * WebKit:  http://pmuellr.blogspot.com/2009/06/debugger-friendly.html
    // * Firebug: http://blog.getfirebug.com/2009/08/11/give-your-eval-a-name-with-sourceurl/
    //if (YES) {
        var absoluteString = this.URL().absoluteString();

        code += "/**/\n//# sourceURL=" + absoluteString + "s";

        if (sourceMap)
        {
            if (typeof btoa === 'function')
                sourceMapBase64 = btoa(UTF16ToUTF8(sourceMap));
            else if (typeof Buffer === 'function')
                sourceMapBase64 = new Buffer(sourceMap).toString("base64");
        }

        if (sourceMapBase64) {
            // The new Function constructor will add a function header before the first line
            // The compiler adds two newlines as the first character to the code to get the source
            // mapping correct. We have to remove it here. As Javascript engines adds diffentent
            // amount of lines at the top we need to calculate how many.

            // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
            code = code.substring((exports.ObjJCompiler || ObjJCompiler).numberOfLinesAtTopOfFunction());
            this._base64EncodedSourceMap = sourceMapBase64;
            code += "\n//# sourceMappingURL=data:application/json;charset=utf-8;base64," + sourceMapBase64;
        }
    //} else {
    //    // Firebug only does it for "eval()", not "new Function()". Ugh. Slower.
    //    var functionText = "(function(){"+GET_CODE(aFragment)+"/**/\n})\n//# sourceURL="+GET_FILE(aFragment).path;
    //    compiled = eval(functionText);
    //}
#endif
        this._function = new Function(parameters, code);
#if DEBUG
    this._function.displayName = absoluteString;
#endif
#if COMMONJS
    }
#endif
}

DISPLAY_NAME(Executable.prototype.setCode);

Executable.prototype.fileDependencies = function()
{
    return this._fileDependencies;
}

DISPLAY_NAME(Executable.prototype.fileDependencies);

Executable.prototype.setFileDependencies = function(newValue)
{
    this._fileDependencies = newValue;
}

DISPLAY_NAME(Executable.prototype.setFileDependencies);

Executable.prototype.hasLoadedFileDependencies = function()
{
    return this._fileDependencyStatus === ExecutableLoadedFileDependencies;
}

DISPLAY_NAME(Executable.prototype.hasLoadedFileDependencies);

var fileDependencyLoadCount = 0,
    fileDependencyExecutables = [],
    fileDependencyMarkers = { };

Executable.prototype.loadFileDependencies = function(aCallback)
{
    var status = this._fileDependencyStatus;

    if (aCallback)
    {
        if (status === ExecutableLoadedFileDependencies)
            return aCallback();

        this._fileDependencyCallbacks.push(aCallback);
    }

    if (status === ExecutableUnloadedFileDependencies)
    {
        if (fileDependencyLoadCount)
            throw "Can't load";

        loadFileDependenciesForExecutable(this);
    }
}

DISPLAY_NAME(Executable.prototype.loadFileDependencies);

Executable.prototype.setExecutableUnloadedFileDependencies = function()
{
    if (this._fileDependencyStatus === ExecutableCantStartLoadYetFileDependencies)
        this._fileDependencyStatus = ExecutableUnloadedFileDependencies;
}

DISPLAY_NAME(Executable.prototype.setExecutableUnloadedFileDependencies);

Executable.prototype.isExecutableCantStartLoadYetFileDependencies = function()
{
    return this._fileDependencyStatus === ExecutableCantStartLoadYetFileDependencies;
}

DISPLAY_NAME(Executable.prototype.setExecutableUnloadedFileDependencies);

function loadFileDependenciesForExecutable(/*Executable*/ anExecutable)
{
    fileDependencyExecutables.push(anExecutable);
    anExecutable._fileDependencyStatus = ExecutableLoadingFileDependencies;

    var fileDependencies = anExecutable.fileDependencies(),
        index = 0,
        count = fileDependencies.length,
        referenceURL = anExecutable.referenceURL(),
        referenceURLString = referenceURL.absoluteString(),
        fileExecutableSearcher = anExecutable.fileExecutableSearcher();

    fileDependencyLoadCount += count;

    for (; index < count; ++index)
    {
        var fileDependency = fileDependencies[index],
            isQuoted = fileDependency.isLocal(),
            URL = fileDependency.URL(),
            marker = (isQuoted && (referenceURLString + " ") || "") + URL;

        if (fileDependencyMarkers[marker])
        {
            if (--fileDependencyLoadCount === 0)
                fileExecutableDependencyLoadFinished();

            continue;
        }

        fileDependencyMarkers[marker] = YES;
        fileExecutableSearcher(URL, isQuoted, fileExecutableSearchFinished);
    }
}

function fileExecutableSearchFinished(/*FileExecutable*/ aFileExecutable)
{
    --fileDependencyLoadCount;

    if (aFileExecutable._fileDependencyStatus === ExecutableUnloadedFileDependencies)
        loadFileDependenciesForExecutable(aFileExecutable);

    else if (fileDependencyLoadCount === 0)
        fileExecutableDependencyLoadFinished();
}

function fileExecutableDependencyLoadFinished()
{
    var executables = fileDependencyExecutables,
        index = 0,
        count = executables.length;

    fileDependencyExecutables = [];

    for (; index < count; ++index)
        executables[index]._fileDependencyStatus = ExecutableLoadedFileDependencies;

    for (index = 0; index < count; ++index)
    {
        var executable = executables[index],
            callbacks = executable._fileDependencyCallbacks,
            callbackIndex = 0,
            callbackCount = callbacks.length;

        for (; callbackIndex < callbackCount; ++callbackIndex)
            callbacks[callbackIndex]();

        executable._fileDependencyCallbacks = [];
    }
}

Executable.prototype.referenceURL = function()
{
    if (this._referenceURL === undefined)
        // Removed the filename (if any) from the path to get the directory
        this._referenceURL = new CFURL(".", this.URL());

    return this._referenceURL;
}

DISPLAY_NAME(Executable.prototype.referenceURL);

Executable.prototype.fileImporter = function()
{
    return Executable.fileImporterForURL(this.referenceURL());
}

DISPLAY_NAME(Executable.prototype.fileImporter);

Executable.prototype.fileExecuter = function()
{
    return Executable.fileExecuterForURL(this.referenceURL());
}

DISPLAY_NAME(Executable.prototype.fileExecuter);

Executable.prototype.fileExecutableSearcher = function()
{
    return Executable.fileExecutableSearcherForURL(this.referenceURL());
}

DISPLAY_NAME(Executable.prototype.fileExecutableSearcher);

var cachedFileExecuters = { };

Executable.fileExecuterForURL = function(/*CFURL|String*/ aURL)
{
    var referenceURL = makeAbsoluteURL(aURL),
        referenceURLString = referenceURL.absoluteString(),
        cachedFileExecuter = cachedFileExecuters[referenceURLString];

    if (!cachedFileExecuter)
    {
        cachedFileExecuter = function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*BOOL*/ shouldForce)
        {
            Executable.fileExecutableSearcherForURL(referenceURL)(aURL, isQuoted,
            function(/*FileExecutable*/ aFileExecutable)
            {
                if (!aFileExecutable.hasLoadedFileDependencies())
                    throw "No executable loaded for file at URL " + aURL;

                aFileExecutable.execute(shouldForce);
            });
        }

        cachedFileExecuters[referenceURLString] = cachedFileExecuter;
    }

    return cachedFileExecuter;
}

DISPLAY_NAME(Executable.fileExecuterForURL);

var cachedFileImporters = { };

Executable.fileImporterForURL = function(/*CFURL|String*/ aURL)
{
    var referenceURL = makeAbsoluteURL(aURL),
        referenceURLString = referenceURL.absoluteString(),
        cachedFileImporter = cachedFileImporters[referenceURLString];

    if (!cachedFileImporter)
    {
        cachedFileImporter = function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*Function*/ aCallback)
        {
            // We make heavy use of URLs throughout this process, so cache them!
            enableCFURLCaching();

            Executable.fileExecutableSearcherForURL(referenceURL)(aURL, isQuoted,
            function(/*FileExecutable*/ aFileExecutable)
            {
                aFileExecutable.loadFileDependencies(function()
                {
                    aFileExecutable.execute();

                    // No more need to cache these.
                    disableCFURLCaching();

                    if (aCallback)
                        aCallback();
                });
            });
        }

        cachedFileImporters[referenceURLString] = cachedFileImporter;
    }

    return cachedFileImporter;
}

DISPLAY_NAME(Executable.fileImporterForURL);

var cachedFileExecutableSearchers = { },
    cachedFileExecutableSearchResults = { };

function countProp(x) {
    var count = 0;
    for (var k in x) {
        if (x.hasOwnProperty(k)) {
            ++count;
        }
    }
    return count;
}

Executable.resetCachedFileExecutableSearchers = function()
{
    cachedFileExecutableSearchers = { };
    cachedFileExecutableSearchResults = { };
    cachedFileImporters = { };
    cachedFileExecuters = { };
    fileDependencyMarkers = { };
}

Executable.fileExecutableSearcherForURL = function(/*CFURL*/ referenceURL)
{
    var referenceURLString = referenceURL.absoluteString(),
        cachedFileExecutableSearcher = cachedFileExecutableSearchers[referenceURLString];

    if (!cachedFileExecutableSearcher)
    {
        var aFilenameTranslateDictionary = Executable.filenameTranslateDictionary ? Executable.filenameTranslateDictionary() : null;

        cachedFileExecutableSearcher = function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*Function*/ success)
        {
            var cacheUID = (isQuoted && referenceURL || "") + aURL,
                cachedResult = cachedFileExecutableSearchResults[cacheUID];

            if (cachedResult)
                return completed(cachedResult);

            var isAbsoluteURL = (aURL instanceof CFURL) && aURL.scheme();

            if (isQuoted || isAbsoluteURL)
            {
                if (!isAbsoluteURL)
                    aURL = new CFURL(aURL, referenceURL);

                StaticResource.resolveResourceAtURL(aURL, NO, completed, aFilenameTranslateDictionary);
            }
            else
                StaticResource.resolveResourceAtURLSearchingIncludeURLs(aURL, completed);

            function completed(/*StaticResource*/ aStaticResource)
            {
                if (!aStaticResource)
                {
                    // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
                    var compilingFileUrl = (exports.ObjJCompiler || ObjJCompiler) ? (exports.ObjJCompiler || ObjJCompiler).currentCompileFile : null;
                    throw new Error("Could not load file at " + aURL + (compilingFileUrl ? " when compiling " + compilingFileUrl : "") + "\nwith includeURLs: " + StaticResource.includeURLs());
                }

                cachedFileExecutableSearchResults[cacheUID] = aStaticResource;

                success(new FileExecutable(aStaticResource.URL(), aFilenameTranslateDictionary));
            }
        };

        cachedFileExecutableSearchers[referenceURLString] = cachedFileExecutableSearcher;
    }

    return cachedFileExecutableSearcher;
}

DISPLAY_NAME(Executable.fileExecutableSearcherForURL);

/*
 * Adaption to javascript by Malte Tancred   2012 from ConvertUTF.[ch] by Unicode, Inc.
 * Speed improvements by     Martin Carlberg 2016
 *
 * Original copyright follows.
 */

/*
 * Copyright 2001-2004 Unicode, Inc.
 *
 * Disclaimer
 *
 * This source code is provided as is by Unicode, Inc. No claims are
 * made as to fitness for any particular purpose. No warranties of any
 * kind are expressed or implied. The recipient agrees to determine
 * applicability of information provided. If this file has been
 * purchased on magnetic or optical media from Unicode, Inc., the
 * sole remedy for any claim will be exchange of defective media
 * within 90 days of receipt.
 *
 * Limitations on Rights to Redistribute This Code
 *
 * Unicode, Inc. hereby grants the right to freely use the information
 * supplied in this file in the creation of products supporting the
 * Unicode Standard, and to make copies of this file in any form
 * for internal or external distribution as long as this notice
 * remains attached.
 */

/* ---------------------------------------------------------------------

   Conversions between UTF32, UTF-16, and UTF-8. Source code file.
   Author: Mark E. Davis, 1994.
   Rev History: Rick McGowan, fixes & updates May 2001.
   Sept 2001: fixed const & error conditions per
   mods suggested by S. Parent & A. Lillich.
   June 2002: Tim Dodd added detection and handling of incomplete
   source sequences, enhanced error detection, added casts
   to eliminate compiler warnings.
   July 2003: slight mods to back out aggressive FFFE detection.
   Jan 2004: updated switches in from-UTF8 conversions.
   Oct 2004: updated to use UNI_MAX_LEGAL_UTF32 in UTF-32 conversions.

   See the header file "ConvertUTF.h" for complete documentation.

------------------------------------------------------------------------ */
var SURROGATE_HIGH_START = 0xD800;
var SURROGATE_HIGH_END =   0xDBFF;
var SURROGATE_LOW_START =  0xDC00;
var SURROGATE_LOW_END =    0xDFFF;
var REPLACEMENT_CHAR =     0xFFFD;
var FIRSTBYTEMARK =        [0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC];

function UTF16ToUTF8(source) {
    var target = "";
    var currentPos = 0;
    for (var i = 0; i < source.length; i++) {
        var c = source.charCodeAt(i);
        if (c < 0x80) continue;

        if (i > currentPos)
            target += source.substring(currentPos, i);

        if (c >= SURROGATE_HIGH_START && c <= SURROGATE_HIGH_END) {
            i++;
            if (i < source.length) {
                var c2 = source.charCodeAt(i);
                if (c2 >= SURROGATE_LOW_START && c2 <= SURROGATE_LOW_END) {
                    c = ((c - SURROGATE_HIGH_START) << 10) + (c2 - SURROGATE_LOW_START) + 0x10000;
                } else {
                    // illegal second surrogate char
                    return null;
                }
            } else {
                // missing second surrogate in pair
                return null;
            }
        } else if (c >= SURROGATE_LOW_START && c <= SURROGATE_LOW_END) {
            // stray surrogate
            return null;
        }

        currentPos = i + 1;
        enc = [];

        var cc = c;

        if (cc >= 0x110000) { cc = 0x800; c = REPLACEMENT_CHAR; }
        if (cc >= 0x10000)  { enc.unshift(String.fromCharCode((c | 0x80) & 0xBF)); c >>= 6; }
        if (cc >= 0x800)    { enc.unshift(String.fromCharCode((c | 0x80) & 0xBF)); c >>= 6; }
        if (cc >= 0x80)     { enc.unshift(String.fromCharCode((c | 0x80) & 0xBF)); c >>= 6; }

        enc.unshift(String.fromCharCode( c | FIRSTBYTEMARK[enc.length]));

        target += enc.join("");
    }

    if (currentPos === 0) return source;

    if (i > currentPos)
        target += source.substring(currentPos, i);

    return target;
}

DISPLAY_NAME(UTF16ToUTF8);
