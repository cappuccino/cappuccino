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

function Executable(/*String*/ aCode, /*Array*/ fileDependencies, /*CFURL|String*/ aURL, /*Function*/ aFunction)
{
    if (arguments.length === 0)
        return this;

    this._code = aCode;
    this._function = aFunction || NULL;
    this._URL = makeAbsoluteURL(aURL || new CFURL("(Anonymous" + (AnonymousExecutableCount++) + ")"));

    this._fileDependencies = fileDependencies;
    this._fileDependencyLoadStatus = ExecutableUnloadedFileDependencies;

    this._eventDispatcher = new EventDispatcher(this);

    if (this._function)
        return;

    this.setCode(aCode);
}

exports.Executable = Executable;

Executable.prototype.path = function()
{
    return this.URL().path();
}

Executable.prototype.URL = function()
{
    return this._URL;
}

Executable.prototype.functionParameters = function()
{
    var functionParameters = ["global", "objj_executeFile", "objj_importFile"];

//exportedNames().concat("objj_executeFile", "objj_importFile");

#ifdef COMMONJS
    functionParameters = functionParameters.concat("require", "exports", "module", "system", "print", "window");
#endif

    return functionParameters;
}

Executable.prototype.functionArguments = function()
{
    var functionArguments = [global, this.fileExecuter(), this.fileImporter()];

#ifdef COMMONJS
    functionArguments = functionArguments.concat(Executable.commonJSArguments());
#endif

    return functionArguments;
}

#ifdef COMMONJS
Executable.setCommonJSParameters = function()
{
    this._commonJSParameters = Array.prototype.slice.call(arguments);
}

Executable.commonJSParameters = function()
{
    return this._commonJSParameters || [];
}

Executable.setCommonJSArguments = function()
{
    this._commonJSArguments = Array.prototype.slice.call(arguments);
}

Executable.commonJSArguments = function()
{
    return this._commonJSArguments || [];
}

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
}
#endif

Executable.prototype.execute = function()
{
#if EXECUTION_LOGGING
    CPLog("EXECUTION: " + this.URL());
#endif
    var oldContextBundle = CONTEXT_BUNDLE;

    CONTEXT_BUNDLE = CFBundle.bundleContainingURL(this.URL());

    var result = this._function.apply(global, this.functionArguments());

    CONTEXT_BUNDLE = oldContextBundle;

    return result;
}

Executable.prototype.code = function()
{
    return this._code;
}

Executable.prototype.setCode = function(code)
{
    this._code = code;

    var parameters = this.functionParameters().join(","),
        absoluteString = this.URL().absoluteString();

#if COMMONJS
    if (typeof system !== "undefined" && system.engine === "rhino")
    {
        code = "function(" + parameters + "){" + code + "/**/\n}";
        this._function = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, code, absoluteString, 0, NULL);
    }
    else
    {
#endif
    // "//@ sourceURL=" at the end lets us name our eval'd files for debuggers, etc.
    // * WebKit:  http://pmuellr.blogspot.com/2009/06/debugger-friendly.html
    // * Firebug: http://blog.getfirebug.com/2009/08/11/give-your-eval-a-name-with-sourceurl/
    //if (YES) {
        code += "/**/\n//@ sourceURL=" + "hello" + absoluteString;
        this._function = new Function(parameters, code);
    //} else {
    //    // Firebug only does it for "eval()", not "new Function()". Ugh. Slower.
    //    var functionText = "(function(){"+GET_CODE(aFragment)+"/**/\n})\n//@ sourceURL="+GET_FILE(aFragment).path;
    //    compiled = eval(functionText);
    //}
    this._function.displayName = absoluteString;
#if COMMONJS
    }
#endif
}

Executable.prototype.fileDependencies = function()
{
    return this._fileDependencies;
}

Executable.prototype.scope = function()
{
    return this._scope;
}

Executable.prototype.hasLoadedFileDependencies = function()
{
    return this._fileDependencyLoadStatus === ExecutableLoadedFileDependencies;
}
var globalIteration = 0;

Executable.prototype.loadFileDependencies = function()
{
#if DEPENDENCY_LOGGING
    CPLog("DEPENDENCY: initiated by " + this.scope());
#endif
    if (this._fileDependencyLoadStatus !== ExecutableUnloadedFileDependencies)
        return;

    this._fileDependencyLoadStatus = ExecutableLoadingFileDependencies;

    var searchedURLStrings = [{ }, { }],
        fileExecutableSearches = new CFMutableDictionary(),
        incompleteFileExecutableSearches = new CFMutableDictionary(),
        loadingExecutables = { };

    function searchForFileDependencies(/*Executable*/ anExecutable)
    {
        var executables = [anExecutable],
            executableIndex = 0,
            executableCount = executables.length;

        for (; executableIndex < executableCount; ++executableIndex)
        {
            var executable = executables[executableIndex];

            if (executable.hasLoadedFileDependencies())
                continue;

            var executableURLString = executable.URL().absoluteString();

            loadingExecutables[executableURLString] = executable;

            var referenceURL = new CFURL(".", executable.URL()),
                fileDependencies = executable.fileDependencies(),
                fileDependencyIndex = 0,
                fileDependencyCount = fileDependencies.length;

            for (; fileDependencyIndex < fileDependencyCount; ++fileDependencyIndex)
            {
                var fileDependency = fileDependencies[fileDependencyIndex],
                    isLocal = fileDependency.isLocal(),
                    URL = fileDependency.URL();

                if (isLocal)
                    URL = new CFURL(URL, referenceURL);

                var URLString = URL.absoluteString();

                if (searchedURLStrings[isLocal ? 1 : 0][URLString])
                    continue;

                searchedURLStrings[isLocal ? 1 : 0][URLString] = YES;

                var fileExecutableSearch = new FileExecutableSearch(URL, isLocal),
                    fileExecutableSearchUID = fileExecutableSearch.UID();

                if (fileExecutableSearches.containsKey(fileExecutableSearchUID))
                    continue;

                fileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);

                if (fileExecutableSearch.isComplete())
                {
                    executables.push(fileExecutableSearch.result());
                    ++executableCount;
                }

                else
                {
                    incompleteFileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);

                    fileExecutableSearch.addEventListener("complete", function( anEvent)
                    {
                        var fileExecutableSearch = anEvent.fileExecutableSearch;

                        incompleteFileExecutableSearches.removeValueForKey(fileExecutableSearch.UID());

                        searchForFileDependencies(fileExecutableSearch.result());
                    });
                }
            }
        }

        if (incompleteFileExecutableSearches.count() > 0)
#if !DEPENDENCY_LOGGING
            return;
#else
        {
            CPLog("DEPENDENCY: more dependencies: ");
            CPLog(incompleteFileExecutableSearches.toString());
            return;
        }

        CPLog("DEPENDENCY: Ended");
#endif

        for (var URLString in loadingExecutables)
            if (hasOwnProperty.call(loadingExecutables, URLString))
                loadingExecutables[URLString]._fileDependencyLoadStatus = ExecutableLoadedFileDependencies;

        for (var URLString in loadingExecutables)
            if (hasOwnProperty.call(loadingExecutables, URLString))
            {
                var executable = loadingExecutables[URLString];

                executable._eventDispatcher.dispatchEvent(
                {
                    type:"dependenciesload",
                    executable:executable
                });
            }
    }

    searchForFileDependencies(this);
}

Executable.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ aListener)
{
    this._eventDispatcher.addEventListener(anEventName, aListener);
}

Executable.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ aListener)
{
    this._eventDispatcher.removeEventListener(anEventName, aListener);
}

Executable.prototype.fileImporter = function()
{
    return Executable.fileImporterForURL(new CFURL(".", this.URL()));
}

Executable.prototype.fileExecuter = function()
{
    return Executable.fileExecuterForURL(new CFURL(".", this.URL()));
}

var cachedFileExecutersForURLStrings = { };

Executable.fileExecuterForURL = function(/*CFURL|String*/ aURL)
{
    var referenceURL = makeAbsoluteURL(aURL),
        referenceURLString = referenceURL.absoluteString(),
        cachedFileExecuter = cachedFileExecutersForURLStrings[referenceURLString];

    if (!cachedFileExecuter)
    {
        cachedFileExecuter = function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*BOOL*/ shouldForce)
        {
            aURL = new CFURL(aURL, isQuoted ? referenceURL : NULL);

            var fileExecutableSearch = new FileExecutableSearch(aURL, isQuoted),
                fileExecutable = fileExecutableSearch.result();

            if (!fileExecutable.hasLoadedFileDependencies())
                throw "No executable loaded for file at URL " + aURL;

            fileExecutable.execute(shouldForce);
        }

        cachedFileExecutersForURLStrings[referenceURLString] = cachedFileExecuter;
    }

    return cachedFileExecuter;
}

var cachedImportersForURLStrings = { };

Executable.fileImporterForURL = function(/*CFURL|String*/ aURL)
{
    var referenceURL = makeAbsoluteURL(aURL),
        referenceURLString = referenceURL.absoluteString(),
        cachedImporter = cachedImportersForURLStrings[referenceURLString];

    if (!cachedImporter)
    {
        cachedImporter = function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*Function*/ aCallback)
        {
            // We make heavy use of URLs throughout this process, so cache them!
            enableCFURLCaching();

            aURL = new CFURL(aURL, isQuoted ? referenceURL : NULL);

            var fileExecutableSearch = new FileExecutableSearch(aURL, isQuoted);

            function searchComplete(/*FileExecutableSearch*/ aFileExecutableSearch)
            {
                var fileExecutable = aFileExecutableSearch.result(),
                    executeAndCallback = function ()
                    {
                        fileExecutable.execute();

                        // No more need to cache these.
                        disableCFURLCaching();

                        if (aCallback)
                            aCallback();
                    }

                if (!fileExecutable.hasLoadedFileDependencies())
                {
                    fileExecutable.addEventListener("dependenciesload", executeAndCallback);
                    fileExecutable.loadFileDependencies();
                }
                else
                    executeAndCallback();
            }

            if (fileExecutableSearch.isComplete())
                searchComplete(fileExecutableSearch);
            else
                fileExecutableSearch.addEventListener("complete", function(/*Event*/ anEvent)
                {
                    searchComplete(anEvent.fileExecutableSearch);
                });
        }

        cachedImportersForURLStrings[referenceURLString] = cachedImporter;
    }

    return cachedImporter;
}
