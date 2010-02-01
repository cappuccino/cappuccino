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

#if COMMONJS
    code = "function(" + this.functionParameters().join(" , ") + "){" + code + "/**/\n}";

    if (typeof system !== "undefined" && system.engine === "rhino")
        this._function = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, code, this._scope, 0, NULL);
    else
        this._function = eval("(" + code + ")");
#else
    // "//@ sourceURL=" at the end lets us name our eval'd files for debuggers, etc.
    // * WebKit:  http://pmuellr.blogspot.com/2009/06/debugger-friendly.html
    // * Firebug: http://blog.getfirebug.com/2009/08/11/give-your-eval-a-name-with-sourceurl/
    //if (YES) {
        code += "/**/\n//@ sourceURL=" + this._scope;
        this._function = new Function(this.functionParameters(), code);
    //} else {
    //    // Firebug only does it for "eval()", not "new Function()". Ugh. Slower.
    //    var functionText = "(function(){"+GET_CODE(aFragment)+"/**/\n})\n//@ sourceURL="+GET_FILE(aFragment).path;
    //    compiled = eval(functionText);
    //}
    this._function.displayName = this._scope;
#endif
}

Executable.prototype.path = function()
{
    return FILE.join(FILE.cwd(), "(Anonymous)");
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
    var dirname = FILE.dirname(this.path()),
        functionArguments = [global, fileExecuterForPath(dirname), fileImporterForPath(dirname)];

//functionArguments = exportedValues().concat(fileExecuterForPath(path), fileImporterForPath(path));

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
#endif

Executable.prototype.execute = function()
{
#if EXECUTION_LOGGING
    CPLog("EXECUTION: " + this.path());
#endif
    var oldContextBundle = CONTEXT_BUNDLE;

    CONTEXT_BUNDLE = CFBundle.bundleContainingPath(this.path());

    var result = this._function.apply(global, this.functionArguments());

    CONTEXT_BUNDLE = oldContextBundle;

    return result;
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
{
#if DEPENDENCY_LOGGING
    CPLog("DEPENDENCY: initiated by " + this.scope());
#endif
    if (this._fileDependencyLoadStatus !== ExecutableUnloadedFileDependencies)
        return;

    this._fileDependencyLoadStatus = ExecutableLoadingFileDependencies;

    var searchedPaths = [{ }, { }],
        foundExecutablePaths = { },
        fileExecutableSearches = new CFMutableDictionary(),
        incompleteFileExecutableSearches = new CFMutableDictionary(),
        executablesNeedingEventDispatch = [this];

    function searchForFileDependencies(/*Executable*/ anExecutable)
    {
        if (anExecutable.hasLoadedFileDependencies())
            return;

        var executables = [anExecutable],
            executableIndex = 0,
            executableCount = executables.length;

        for (; executableIndex < executableCount; ++executableIndex)
        {
            var executable = executables[executableIndex],
                cwd = FILE.dirname(executable.path()),
                fileDependencies = executable.fileDependencies(),
                fileDependencyIndex = 0,
                fileDependencyCount = fileDependencies.length;

            for (; fileDependencyIndex < fileDependencyCount; ++fileDependencyIndex)
            {
                var fileDependency = fileDependencies[fileDependencyIndex],
                    isLocal = fileDependency.isLocal(),
                    path = importablePath(fileDependency.path(), isLocal, cwd);

                if (searchedPaths[isLocal ? 1 : 0][path])
                    continue;

                searchedPaths[isLocal ? 1 : 0][path] = YES;

                var fileExecutableSearch = new FileExecutableSearch(path, isLocal),
                    fileExecutableSearchUID = fileExecutableSearch.UID();

                if (fileExecutableSearches.containsKey(fileExecutableSearchUID))
                    continue;

                fileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);

                if (fileExecutableSearch.isComplete())
                {
                    var newFileExecutable = fileExecutableSearch.result();

                    foundExecutablePaths[newFileExecutable.path()] = executable;
                    executables.push(newFileExecutable);
                    ++executableCount;
                }

                else
                {
                    incompleteFileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);

                    fileExecutableSearch.addEventListener("complete", function( anEvent)
                    {
                        var fileExecutableSearch = anEvent.fileExecutableSearch,
                            fileExecutable = fileExecutableSearch.result();

                        foundExecutablePaths[fileExecutable.path()] = fileExecutable;
                        incompleteFileExecutableSearches.removeValueForKey(fileExecutableSearch.UID());

                        searchForFileDependencies(fileExecutable);
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

        for (var executablePath in foundExecutablePaths)
            if (hasOwnProperty.apply(foundExecutablePaths, [executablePath]))
            {
                var fileExecutable = new FileExecutable(executablePath);
                //CPLog("no go for... " + fileExecutable.path());
                if (fileExecutable.hasLoadedFileDependencies())
                    continue;

                executablesNeedingEventDispatch.push(fileExecutable);
                fileExecutable._fileDependencyLoadStatus = FileExecutableLoadedDependencies;
            }

        var index = 0,
            count = executablesNeedingEventDispatch.length;

        for (; index < count; ++index)
        {
            var fileExecutable = executablesNeedingEventDispatch[index];

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

exports.Executable = Executable;
