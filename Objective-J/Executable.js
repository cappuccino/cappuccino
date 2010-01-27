/*
 * Executable.js
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

var ExecutableUnloadedFileDependencies  = 0,
    ExecutableLoadingFileDependencies   = 1,
    ExecutableLoadedFileDependencies    = 2;

function Executable(/*String*/ aCode, /*Array*/ fileDependencies, /*String*/ aScope, /*Function*/ aFunction)
{
    if (arguments.length === 0)
        return this;

    this._code = aCode;
    this._function = aFunction || NULL;
    this._scope = aScope || "(Anonymous)";

    this._fileDependencies = fileDependencies;
    this._fileDependencyLoadStatus = ExecutableUnloadedFileDependencies;

    this._eventDispatcher = new EventDispatcher(this);

    if (this._function)
        return;

    var code = this._code;

#if RHINO
    code = "function(\"" + this.functionParameters().join("\",\"" + "\"){" + code + "/**/\n}";

    if (typeof system !== "undefined" && system.engine === "rhino")
        this._function = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, code, this._scope, 0, null);
    else
        this._function = eval("(" + code + ")");
#else
    // "//@ sourceURL=" at the end lets us name our eval'd files for debuggers, etc.
    // * WebKit:  http://pmuellr.blogspot.com/2009/06/debugger-friendly.html
    // * Firebug: http://blog.getfirebug.com/2009/08/11/give-your-eval-a-name-with-sourceurl/
    //if (true) {
        code += "/**/\n//@ sourceURL=" + this._scope;
        this._function = new Function(this.functionParameters(), code);
    //} else {
    //    // Firebug only does it for "eval()", not "new Function()". Ugh. Slower.
    //    var functionText = "(function(){"+GET_CODE(aFragment)+"/**/\n})\n//@ sourceURL="+GET_FILE(aFragment).path;
    //    compiled = eval(functionText);
    //}
    this._function.displayName = this._scope;
#endif

if (code.indexOf("/Users/tolmasky/Desktop/LoadTest/main.j/**/") !== -1)
    throw "why?";
}

Executable.prototype.path = function()
{
    return FILE.cwd();
}

Executable.prototype.functionParameters = function()
{
    return exportedNames().concat("objj_executeFile", "objj_importFile", "__OBJJ_BUNDLE__");
}

Executable.prototype.functionArguments = function()
{
    var path = this.path();

    return exportedValues().concat(fileExecuterForPath(path), fileImporterForPath(path));
}

Executable.prototype.execute = function()
{
    var oldContextBundle = CONTEXT_BUNDLE;

    CONTEXT_BUNDLE = Bundle.bundleContainingPath(this.path());

    this._function.apply(global, this.functionArguments());

    CONTEXT_BUNDLE = oldContextBundle;
}

Executable.prototype.code = function()
{
    return this._code;
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
{console.log("load deps for " + this.scope());
    if (this._fileDependencyLoadStatus !== ExecutableUnloadedFileDependencies)
        return;

    this._fileDependencyLoadStatus = ExecutableLoadingFileDependencies;

    var searchedPaths = { },
        foundExecutablePaths = { },
        fileExecutableSearches = new MutableDictionary(),
        incompleteFileExecutableSearches = new MutableDictionary();

    foundExecutablePaths[this.path()] = this;

    function searchForFileDependencies(/*Executable*/ anExecutable)
    {
        if (anExecutable.hasLoadedFileDependencies())
            return;

        var fileDependencies = anExecutable.fileDependencies(),
            index = 0,
            count = fileDependencies.length;

        for (; index < count; ++index)
        {
            var fileDependency = fileDependencies[index],
                path = fileDependency.path(),
                isLocal = fileDependency.isLocal();
    
            if (isLocal)
                path = FILE.join(anExecutable.path ? FILE.dirname(anExecutable.path()) : FILE.cwd(), path);

            if (searchedPaths[path])
                continue;

            searchedPaths[path] = YES;

            var fileExecutableSearch = new FileExecutableSearch(path, isLocal),
                fileExecutableSearchUID = fileExecutableSearch.UID();

            if (fileExecutableSearches.containsKey(fileExecutableSearchUID))
                continue;

            fileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);

            if (fileExecutableSearch.isComplete())
                searchForFileDependencies(fileExecutableSearch.result());

            else
            {
                incompleteFileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);
    
                fileExecutableSearch.addEventListener("complete", function(/*Event*/ anEvent)
                {
                    var fileExecutableSearch = anEvent.fileExecutableSearch,
                        fileExecutable = fileExecutableSearch.result();
    //console.log("DONE FOR: " + search.UID() + " " + search.resultantFilePath());
                    foundExecutablePaths[fileExecutable.path()] = fileExecutable;
                    incompleteFileExecutableSearches.removeValueForKey(fileExecutableSearch.UID());
    
                    searchForFileDependencies(fileExecutableSearch.result());
                });
            }
        }

        if (incompleteFileExecutableSearches.count() > 0)
        {
            if (globalIteration++ > 200)
                throw "too many.";
            console.log("keep going");
            var keys = incompleteFileExecutableSearches.keys(),
                index = 0,
                count = keys.length;
            for(; index < count; ++index)
                console.log(":::"+keys[index] + " " + incompleteFileExecutableSearches.valueForKey(keys[index])._path);
            return;
}
console.log("what?");
        var fileExecutablesNeedingEventDispatch = [];

        for (var executablePath in foundExecutablePaths)
            if (hasOwnProperty.apply(foundExecutablePaths, [executablePath]))
            {
                var fileExecutable = new FileExecutable(executablePath);
                console.log("no go for... " + fileExecutable.path());
                if (fileExecutable.hasLoadedFileDependencies())
                    continue;

                fileExecutablesNeedingEventDispatch.push(fileExecutable);
                fileExecutable._fileDependencyLoadStatus = FileExecutableLoadedDependencies;
            }
    
        var index = 0,
            count = fileExecutablesNeedingEventDispatch.length;

        for (; index < count; ++index)
        {
            var fileExecutable = fileExecutablesNeedingEventDispatch[index];

            fileExecutable._eventDispatcher.dispatchEvent(
            {
                type:"dependenciesload",
                fileExecutable:fileExecutable
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
