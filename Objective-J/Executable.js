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


var ExecutableUnloadedFileDependencies  = 0,
    ExecutableLoadingFileDependencies   = 1,
    ExecutableLoadedFileDependencies    = 2,
    AnonymousExecutableCount            = 0;

function Executable(/*String*/ aCode, /*Array*/ fileDependencies, /*CFURL|String*/ aURL, /*Function*/ aFunction, /*ObjJCompiler*/aCompiler, /*Dictionary*/ aFilenameTranslateDictionary)
{
    if (arguments.length === 0)
        return this;

    this._code = aCode;
    this._function = aFunction || null;
    this._URL = makeAbsoluteURL(aURL || new CFURL("(Anonymous" + (AnonymousExecutableCount++) + ")"));

    this._compiler = aCompiler || null;

    this._fileDependencies = fileDependencies;
    this._filenameTranslateDictionary = aFilenameTranslateDictionary;

    if (fileDependencies.length)
    {
        this._fileDependencyStatus = ExecutableUnloadedFileDependencies;
        this._fileDependencyCallbacks = [];
    }
    else
        this._fileDependencyStatus = ExecutableLoadedFileDependencies;

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

        this.setCode(this._compiler.compilePass2());
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

Executable.prototype.setCode = function(code)
{
    this._code = code;

    var parameters = this.functionParameters().join(",");

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
    // "//@ sourceURL=" at the end lets us name our eval'd files for debuggers, etc.
    // * WebKit:  http://pmuellr.blogspot.com/2009/06/debugger-friendly.html
    // * Firebug: http://blog.getfirebug.com/2009/08/11/give-your-eval-a-name-with-sourceurl/
    //if (YES) {
        var absoluteString = this.URL().absoluteString();

        code += "/**/\n//@ sourceURL=" + absoluteString;
    //} else {
    //    // Firebug only does it for "eval()", not "new Function()". Ugh. Slower.
    //    var functionText = "(function(){"+GET_CODE(aFragment)+"/**/\n})\n//@ sourceURL="+GET_FILE(aFragment).path;
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
        cachedFileExecutableSearcher = cachedFileExecutableSearchers[referenceURLString],
        aFilenameTranslateDictionary = Executable.filenameTranslateDictionary ? Executable.filenameTranslateDictionary() : null;
        cachedSearchResults = { };

    if (!cachedFileExecutableSearcher)
    {
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
                    var compilingFileUrl = ObjJAcornCompiler ? ObjJAcornCompiler.currentCompileFile : null;
                    throw new Error("Could not load file at " + aURL + (compilingFileUrl ? " when compiling " + compilingFileUrl : ""));
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
