/*
 * FileExecutable.js
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

var FileExecutablesForURLStrings = { };

var currentCompilerFlags = {};
var currentGccCompilerFlags = "";

function FileExecutable(/*CFURL|String*/ aURL, /*Dictionary*/ aFilenameTranslateDictionary)
{
    aURL = makeAbsoluteURL(aURL);

    var URLString = aURL.absoluteString(),
        existingFileExecutable = FileExecutablesForURLStrings[URLString];

    if (existingFileExecutable)
        return existingFileExecutable;

    FileExecutablesForURLStrings[URLString] = this;

    var fileContents = StaticResource.resourceAtURL(aURL).contents(),
        executable = NULL,
        extension = aURL.pathExtension().toLowerCase();

    if (fileContents.match(/^@STATIC;/))
        executable = decompile(fileContents, aURL);
    else if ((extension === "j" || !extension) && !fileContents.match(/^{/))
    {
        var compiler = exports.ObjJCompiler.compileFileDependencies(fileContents, aURL, currentCompilerFlags || {});

        if (FileExecutable.printWarningsAndErrors(compiler, exports.messageOutputFormatInXML))
            throw "Compilation error";

        var fileDependencies = compiler.dependencies.map(function (aFileDep) {
            return new FileDependency(new CFURL(aFileDep.url), aFileDep.isLocal);
        });
        executable = new Executable(compiler.jsBuffer ? compiler.jsBuffer.toString() : null, fileDependencies, compiler.URL, null, compiler);
    }
    else
        executable = new Executable(fileContents, [], aURL);

    Executable.apply(this, [executable.code(), executable.fileDependencies(), aURL, executable._function, executable._compiler, aFilenameTranslateDictionary]);

    this._hasExecuted = NO;
}

exports.FileExecutable = FileExecutable;

FileExecutable.prototype = new Executable();

#ifdef COMMONJS
FileExecutable.allFileExecutables = function()
{
    var URLString,
        fileExecutables = [];

    for (URLString in FileExecutablesForURLStrings)
        if (hasOwnProperty.call(FileExecutablesForURLStrings, URLString))
            fileExecutables.push(FileExecutablesForURLStrings[URLString]);

    return fileExecutables;
}
#endif

FileExecutable.resetFileExecutables = function()
{
    FileExecutablesForURLStrings = { };
    FunctionCache = { };
}

FileExecutable.prototype.execute = function(/*BOOL*/ shouldForce)
{
    if (this._hasExecuted && !shouldForce)
        return;

    this._hasExecuted = YES;

    Executable.prototype.execute.call(this);
}

DISPLAY_NAME(FileExecutable.prototype.execute);

FileExecutable.prototype.hasExecuted = function()
{
    return this._hasExecuted;
}

DISPLAY_NAME(FileExecutable.prototype.hasExecuted);

function decompile(/*String*/ aString, /*CFURL*/ aURL)
{
    var stream = new MarkedStream(aString);
/*
    if (stream.version !== "1.0")
        return;
*/
    var marker = NULL,
        code = "",
        dependencies = [];

    while (marker = stream.getMarker())
    {
        var text = stream.getString();

        if (marker === MARKER_TEXT)
            code += text;

        else if (marker === MARKER_IMPORT_STD)
            dependencies.push(new FileDependency(new CFURL(text), NO));

        else if (marker === MARKER_IMPORT_LOCAL)
            dependencies.push(new FileDependency(new CFURL(text), YES));
    }

    var fn = FileExecutable._lookupCachedFunction(aURL);

    if (fn)
        return new Executable(code, dependencies, aURL, fn);

    return new Executable(code, dependencies, aURL);
}

var FunctionCache = { };

FileExecutable._cacheFunction = function(/*CFURL|String*/ aURL, /*Function*/ fn)
{
    aURL = typeof aURL === "string" ? aURL : aURL.absoluteString();
    FunctionCache[aURL] = fn;
}

FileExecutable._lookupCachedFunction = function(/*CFURL|String*/ aURL)
{
    aURL = typeof aURL === "string" ? aURL : aURL.absoluteString();
    return FunctionCache[aURL];
}

FileExecutable.setCurrentGccCompilerFlags = function(/*String*/ compilerFlags)
{
    if (currentGccCompilerFlags === compilerFlags) return;

    currentGccCompilerFlags = compilerFlags;

    var args = compilerFlags.split(" "),
        count = args.length,
        objjcFlags = {};

    for (var index = 0; index < count; ++index)
    {
        var argument = args[index];

        if (argument.indexOf("-g") === 0)
            objjcFlags.includeMethodFunctionNames = true;
        else if (argument.indexOf("-O") === 0) {
            objjcFlags.inlineMsgSendFunctions = true;
            // FIXME: currently we are sending in '-O2' when we want InlineMsgSend. Here we only check if it is '-O...'.
            // Maybe we should have some other option for this
            if (argument.length > 2)
                objjcFlags.inlineMsgSendFunctions = true;
        }
        //else if (argument.indexOf("-G") === 0)
            //objjcFlags |= ObjJAcornCompiler.Flags.Generate;
        else if (argument.indexOf("-T") === 0) {
            objjcFlags.includeIvarTypeSignatures = false;
            objjcFlags.includeMethodArgumentTypeSignatures = false;
        }
    }

    FileExecutable.setCurrentCompilerFlags(objjcFlags);
}

FileExecutable.currentGccCompilerFlags = function(/*String*/ compilerFlags)
{
    return currentGccCompilerFlags;
}

FileExecutable.setCurrentCompilerFlags = function(/*JSObject*/ compilerFlags)
{
    currentCompilerFlags = compilerFlags;
    // Here we set the default flags if they are not included. We do this as the default values
    // in the compiler might not be what we want.
    if (currentCompilerFlags.transformNamedFunctionDeclarationToAssignment == null)
        currentCompilerFlags.transformNamedFunctionDeclarationToAssignment = true;
    if (currentCompilerFlags.sourceMap == null)
        currentCompilerFlags.sourceMap = false;
    if (currentCompilerFlags.inlineMsgSendFunctions == null)
        currentCompilerFlags.inlineMsgSendFunctions = false;
}

FileExecutable.currentCompilerFlags = function(/*JSObject*/ compilerFlags)
{
    return currentCompilerFlags;
}

/*!
    This funtion prints all errors and warnings for the provieded compiler. It returns true if there
    are any errors in the list. it will print it in xml format if printXML is 'true'
 */
FileExecutable.printWarningsAndErrors = function(/*ObjJCompiler*/ compiler, /*BOOL*/ printXML)
{
    var warnings = [],
        anyErrors = false;

    for (var i = 0; i < compiler.warningsAndErrors.length; i++)
    {
        var warning = compiler.warningsAndErrors[i],
            message = compiler.prettifyMessage(warning);

        // Set anyErrors to 'true' if there are any errors in the list
        anyErrors = anyErrors || warning.messageType === "ERROR";
#ifdef BROWSER
        console.log(message);
#else
        if (printXML)
        {
            var dict = new CFMutableDictionary();
            if (warning.messageOnLine != null) dict.addValueForKey('line', warning.messageOnLine)
            if (warning.path != null) dict.addValueForKey('sourcePath', new CFURL(warning.path).path())
            if (message != null) dict.addValueForKey('message', message)

            warnings.push(dict);
        }
        else
        {
            print(message);
        }
#endif
    }

#ifndef BROWSER
    if (warnings.length && printXML)
        try {
            print(CFPropertyListCreateXMLData(warnings, kCFPropertyListXMLFormat_v1_0).rawString());
        } catch (e) {
            print ("XML encode error: " + e);
        }
#endif

    return anyErrors;
}

// Set the compiler flags to empty dictionary so the default values are correct.
FileExecutable.setCurrentCompilerFlags({});
