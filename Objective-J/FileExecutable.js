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

    this._hasExecuted = NO;

    if (fileContents.match(/^@STATIC;/))
        executable = decompile(fileContents, aURL);
    else if ((extension === "j" || !extension) && !fileContents.match(/^{/))
    {
        var compilerOptions = currentCompilerFlags || {};

        this.cachedIncludeFileSearchResultsContent = {};
        this.cachedIncludeFileSearchResultsURL = {};
        compile(this, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary);
        return;
    }
    else
        executable = new Executable(fileContents, [], aURL);

    Executable.apply(this, [executable.code(), executable.fileDependencies(), aURL, executable._function, executable._compiler, aFilenameTranslateDictionary]);
}

exports.FileExecutable = FileExecutable;

FileExecutable.prototype = new Executable();

var compile = function(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary)
{
    var acornOptions = compilerOptions.acornOptions || (compilerOptions.acornOptions = {});

    acornOptions.preprocessGetIncludeFile = function(filePath, isQuoted) {
        var referenceURL = new CFURL(".", aURL), // Remove the filename from the url
            includeURL = new CFURL(filePath);

        var cacheUID = (isQuoted && referenceURL || "") + includeURL,
            cachedResult = self.cachedIncludeFileSearchResultsContent[cacheUID];

        if (!cachedResult) {
            var isAbsoluteURL = (includeURL instanceof CFURL) && includeURL.scheme(),
                compileWhenCompleted = NO;

            function completed(/*StaticResource*/ aStaticResource) {
                var includeString = aStaticResource && aStaticResource.contents(),
                    lastCharacter = includeString && includeString.charCodeAt(includeString.length - 1);

                if (includeString == null) throw new Error("Can't load file " + includeURL);
                // Add a new line if the last character is not. If the last thing is a '#define' of other preprocess
                // token it will not be handled correctly if we don't have a end of line at the end.
                if (lastCharacter !== 10 && lastCharacter !== 13 && lastCharacter !== 8232 && lastCharacter !== 8233) {
                    includeString += '\n';
                }

                self.cachedIncludeFileSearchResultsContent[cacheUID] = includeString;
                self.cachedIncludeFileSearchResultsURL[cacheUID] = aStaticResource.URL();

                if (compileWhenCompleted)
                    compile(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary);
            }

            if (isQuoted || isAbsoluteURL)
            {
                if (!isAbsoluteURL)
                    includeURL = new CFURL(includeURL, new CFURL((aFilenameTranslateDictionary[aURL.lastPathComponent()] || "."), referenceURL));

                StaticResource.resolveResourceAtURL(includeURL, NO, completed);
            }
            else
                StaticResource.resolveResourceAtURLSearchingIncludeURLs(includeURL, completed);

            // Now we try to get the cached result again. If we get it then the completed function has already
            // executed and we can return the include dictionary.
            cachedResult = self.cachedIncludeFileSearchResultsContent[cacheUID];
        }

        if (cachedResult) {
            return {include: cachedResult, sourceFile: self.cachedIncludeFileSearchResultsURL[cacheUID]};
        } else {
            // When the file is not available (resolved) return null to tell the parser to throw an exception to exit
            // Also tell the completed function to compile when finished.
            compileWhenCompleted = YES
            return null;
        }
    };

    var includeFiles = currentCompilerFlags && currentCompilerFlags.includeFiles,
        allPreIncludesResolved = true;

    acornOptions.preIncludeFiles = [];

    if (includeFiles) for (var i = 0, size = includeFiles.length; i < size; i++)
    {
        var includeFileUrl = makeAbsoluteURL(includeFiles[i]);

        try
        {
            // try to get all pre include files that acorn will parse before the file from 'aURL'
            var aResource = StaticResource.resourceAtURL(makeAbsoluteURL(includeFileUrl));
        }
        catch (e)
        {
            // Ok, the file is not available (resolved). Resolve all of the files and try again when available.
            StaticResource.resolveResourcesAtURLs(includeFiles.map(function(u) {return makeAbsoluteURL(u)}), function() {
                compile(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary);
            });

            allPreIncludesResolved = false;
            break;
        }

        if (aResource)
        {
            if (aResource.isNotFound()) {
                throw new Error("--include file not found " + includeUrl);
            }

            var includeString = aResource.contents();
            var lastCharacter = includeString.charCodeAt(includeString.length - 1);

            // Add a new line if the last character is not. If the last thing is a '#define' of other preprocess
            // token it will not be handled correctly if we don't have a end of line at the end.
            if (lastCharacter !== 10 && lastCharacter !== 13 && lastCharacter !== 8232 && lastCharacter !== 8233)
                includeString += '\n';
            acornOptions.preIncludeFiles.push({include: includeString, sourceFile: includeFileUrl.toString()});
        }
    }

    if (allPreIncludesResolved)
    {
        // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
        var compiler = (exports.ObjJCompiler || ObjJCompiler).compileFileDependencies(fileContents, aURL, compilerOptions);
        var warningsAndErrors = compiler.warningsAndErrors;

        // Kind of a hack but if we get a file not found error on a #include the get include function above should have asked for the resource
        // so we should be able to just bail out and wait for the the next call to compile when the include file is loaded (resolved)
        if (warningsAndErrors && warningsAndErrors.length === 1 && warningsAndErrors[0].message.indexOf("file not found") > -1)
            return;

        if (FileExecutable.printWarningsAndErrors(compiler, exports.messageOutputFormatInXML))
            throw "Compilation error";

        var fileDependencies = compiler.dependencies.map(function (aFileDep) {
            return new FileDependency(new CFURL(aFileDep.url), aFileDep.isLocal);
        });
    }

    if (self.isExecutableCantStartLoadYetFileDependencies())
    {
        // Include files that was not loaded has cancelled the compiler so we are already an initialized Executable.
        // Just set the status so we can start loading the file dependencies.
        self.setFileDependencies(fileDependencies);
        self.setExecutableUnloadedFileDependencies();
        self.loadFileDependencies();
    }
    else if (self._fileDependencyStatus == null)
    {
        // Are we still a FileExecutable. Call 'super' init method to make us a initilized subclass of an Executable.
        executable = new Executable(compiler && compiler.jsBuffer ? compiler.jsBuffer.toString() : null, fileDependencies, aURL, null, compiler);
        Executable.apply(self, [executable.code(), executable.fileDependencies(), aURL, executable._function, executable._compiler, aFilenameTranslateDictionary]);
    }
}

DISPLAY_NAME(compile);

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
        dependencies = [],
        sourceMap;

    while (marker = stream.getMarker())
    {
        var text = stream.getString();

        if (marker === MARKER_TEXT)
            code += text;

        else if (marker === MARKER_IMPORT_STD)
            dependencies.push(new FileDependency(new CFURL(text), NO));

        else if (marker === MARKER_IMPORT_LOCAL)
            dependencies.push(new FileDependency(new CFURL(text), YES));

        else if (marker === MARKER_SOURCE_MAP)
            sourceMap = text;
    }

    var fn = FileExecutable._lookupCachedFunction(aURL);

    if (fn)
        return new Executable(code, dependencies, aURL, fn, null, null, sourceMap);

    return new Executable(code, dependencies, aURL, null, null, null, sourceMap);
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

    // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
    var objjcFlags = (exports.ObjJCompiler || ObjJCompiler).parseGccCompilerFlags(compilerFlags);

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
