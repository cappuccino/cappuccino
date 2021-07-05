
var rootResources = { };

var currentCompilerFlags = {};
var currentGccCompilerFlags = "";

function StaticResource(/*CFURL*/ aURL, /*StaticResource*/ aParent, /*BOOL*/ isDirectory, /*BOOL*/ isResolved, /*Dictionary*/ aFilenameTranslateDictionary)
{
    this._parent = aParent;
    this._eventDispatcher = new EventDispatcher(this);

    var name = aURL.absoluteURL().lastPathComponent() || aURL.schemeAndAuthority();

    this._name = name;
    this._URL = aURL; //new CFURL(aName, aParent && aParent.URL().asDirectoryPathURL());
    this._isResolved = !!isResolved;
    this._filenameTranslateDictionary = aFilenameTranslateDictionary;

    if (isDirectory)
        this._URL = this._URL.asDirectoryPathURL();

    if (!aParent)
        rootResources[name] = this;

    this._isDirectory = !!isDirectory;
    this._isNotFound = NO;

    if (aParent)
        aParent._children[name] = this;

    if (isDirectory)
        this._children = { };

    else
        this._contents = "";
}

StaticResource.rootResources = function()
{
    return rootResources;
};

StaticResource.resetRootResources = function()
{
    rootResources = {};
    FunctionCache = {};
};

StaticResource.prototype.filenameTranslateDictionary = function()
{
    return this._filenameTranslateDictionary || {};
};

exports.StaticResource = StaticResource;

function resolveStaticResource(/*StaticResource*/ aResource)
{
    aResource._isResolved = YES;
    aResource._eventDispatcher.dispatchEvent(
    {
        type:"resolve",
        staticResource:aResource
    });
}

StaticResource.prototype.resolve = function(/*BOOL*/ dontCompile, /*Array*/ compileIncludeFileArray)
{
    if (this.isDirectory())
    {
        var bundle = new CFBundle(this.URL());

        // Eat any errors.
        bundle.onerror = function() { };

        // The bundle will actually resolve this node.
        bundle.load(NO);
    }
    else
    {
        var self = this;

        function onsuccess(/*anEvent*/ anEvent)
        {
            var fileContents = anEvent.request.responseText(),
                aURL = self.URL(),
                extension = aURL.pathExtension().toLowerCase();

            self._contents = fileContents;

            if (fileContents.match(/^@STATIC;/))
            {
                self.decompile();
                resolveStaticResource(self);
            }
            else if (!dontCompile && (extension === "j" || !extension) && !fileContents.match(/^{/))
            {
                // Copy compiler options as this can be recursive and/or asynchronous.
                // Specially acornOptions.preprocessGetIncludeFile that has a variable 'self' that needs to be referencing the resource.
                var compilerOptions = Object.assign({}, currentCompilerFlags || {}),
                    acornOptions = compilerOptions.acornOptions;

                if (acornOptions)
                    compilerOptions.acornOptions = Object.asign({}, acornOptions);

                // If no include files are set use the include files from the bundle, if any.
                if (!compilerOptions.includeFiles)
                    compilerOptions.includeFiles = compileIncludeFileArray;

                self.cachedIncludeFileSearchResultsContent = {};
                self.cachedIncludeFileSearchResultsURL = {};
                compile(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary, function(aResource) {
                    resolveStaticResource(aResource);
                });
            }
            else
            {
                resolveStaticResource(self);
            }
        }

        function onfailure()
        {
            self._isNotFound = YES;
            resolveStaticResource(self);
        }

        var url = this.URL(),
            aFilenameTranslateDictionary = this.filenameTranslateDictionary();

        if (aFilenameTranslateDictionary)
        {
            var urlString = url.toString(),
                lastPathComponent = url.lastPathComponent(),
                basePath = urlString.substring(0, urlString.length - lastPathComponent.length),
                translatedName = aFilenameTranslateDictionary[lastPathComponent];

            if (translatedName && urlString.slice(-translatedName.length) !== translatedName)
                url = new CFURL(basePath + translatedName);  // FIXME: do an add component to url or something better....
        }
        new FileRequest(url, onsuccess, onfailure);
    }
};

var compile = function(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary, success)
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
                    compile(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary, success);
            }

            if (isQuoted || isAbsoluteURL)
            {
                var translateDictionary;

                if (!isAbsoluteURL) {
                    includeURL = new CFURL(includeURL, new CFURL(((aFilenameTranslateDictionary && aFilenameTranslateDictionary[aURL.lastPathComponent()]) || "."), referenceURL));
                }

                StaticResource.resolveResourceAtURL(includeURL, NO, completed, null, true); // true = don't compile any loaded resource
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
            // Also tell the completed function to compile when finished as it has not yet done so.
            // If fetching the resources are synchronous the result will be found above and the completion function
            // should not compile again.
            compileWhenCompleted = YES;
            return null;
        }
    };

    var includeFiles = compilerOptions && compilerOptions.includeFiles,
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
                compile(self, fileContents, aURL, compilerOptions, aFilenameTranslateDictionary, success);
            });

            // Now we need to bail out as the compile completion function has already been
            // called (synchronous) or will be called in the future (asynchronous)
            return;
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

    // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
    var compiler = (exports.ObjJCompiler || ObjJCompiler).compileFileDependencies(fileContents, aURL, compilerOptions);
    var warningsAndErrors = compiler.warningsAndErrors;

    // Kind of a hack but if we get a file not found error on a #include the get include function above should have asked for the resource
    // so we should be able to just bail out and wait for the the next call to compile when the include file is loaded (resolved)
    if (warningsAndErrors && warningsAndErrors.length === 1 && warningsAndErrors[0].message.indexOf("file not found") > -1)
        return;

    if (Executable.printWarningsAndErrors(compiler, exports.messageOutputFormatInXML)) {
        throw "Compilation error";
    }

    var fileDependencies = compiler.dependencies.map(function (aFileDep) {
        return new FileDependency(new CFURL(aFileDep.url), aFileDep.isLocal);
    });

    self._fileDependencies = fileDependencies;
    self._compiler = compiler;

    success(self);
}

StaticResource.prototype.decompile = function()
{
    var content = this.contents(),
        aURL = this.URL(),
        stream = new MarkedStream(content);
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

    this._fileDependencies = dependencies;
    this._function = StaticResource._lookupCachedFunction(aURL);
    this._sourceMap = sourceMap;
    this._contents = code;
}

StaticResource.setCurrentGccCompilerFlags = function(/*String*/ compilerFlags)
{
    if (currentGccCompilerFlags === compilerFlags) return;

    currentGccCompilerFlags = compilerFlags;

    // '(exports.ObjJCompiler || ObjJCompiler)' is a temporary fix so it can work both in the Narwhal (exports.ObjJCompiler) and Node (ObjJCompiler) world
    var objjcFlags = (exports.ObjJCompiler || ObjJCompiler).parseGccCompilerFlags(compilerFlags);

    StaticResource.setCurrentCompilerFlags(objjcFlags);
}

StaticResource.currentGccCompilerFlags = function(/*String*/ compilerFlags)
{
    return currentGccCompilerFlags;
}

StaticResource.setCurrentCompilerFlags = function(/*JSObject*/ compilerFlags)
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

StaticResource.currentCompilerFlags = function(/*JSObject*/ compilerFlags)
{
    return currentCompilerFlags;
}

var FunctionCache = { };

StaticResource._cacheFunction = function(/*CFURL|String*/ aURL, /*Function*/ fn)
{
    aURL = typeof aURL === "string" ? aURL : aURL.absoluteString();
    FunctionCache[aURL] = fn;
}

StaticResource._lookupCachedFunction = function(/*CFURL|String*/ aURL)
{
    aURL = typeof aURL === "string" ? aURL : aURL.absoluteString();
    return FunctionCache[aURL];
}

StaticResource.prototype.name = function()
{
    return this._name;
};

StaticResource.prototype.URL = function()
{
    return this._URL;
};

StaticResource.prototype.contents = function()
{
    return this._contents;
};

StaticResource.prototype.children = function()
{
    return this._children;
};

StaticResource.prototype.parent = function()
{
    return this._parent;
};

StaticResource.prototype.isResolved = function()
{
    return this._isResolved;
};

StaticResource.prototype.write = function(/*String*/ aString)
{
    this._contents += aString;
};

function rootResourceForAbsoluteURL(/*CFURL*/ anAbsoluteURL)
{
    var schemeAndAuthority = anAbsoluteURL.schemeAndAuthority(),
        resource = rootResources[schemeAndAuthority];

    if (!resource)
        resource = new StaticResource(new CFURL(schemeAndAuthority), NULL, YES, YES);

    return resource;
}

StaticResource.resourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ resolveAsDirectoriesIfNecessary)
{
    aURL = makeAbsoluteURL(aURL).absoluteURL();

    var resource = rootResourceForAbsoluteURL(aURL),
        components = aURL.pathComponents(),
        index = 0,
        count = components.length;

    for (; index < count; ++index)
    {
        var name = components[index];

        if (hasOwnProperty.call(resource._children, name))
            resource = resource._children[name];

        else if (resolveAsDirectoriesIfNecessary)
        {
            // We do this because on Windows the path may start with C: and be
            // misinterpreted as a scheme.
            if (name !== "/")
                name = "./" + name;

            resource = new StaticResource(new CFURL(name, resource.URL()), resource, YES, YES);
        }
        else
            throw new Error("Static Resource at " + aURL + " is not resolved (\"" + name + "\")");
    }

    return resource;
};

StaticResource.prototype.resourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ resolveAsDirectoriesIfNecessary)
{
    return StaticResource.resourceAtURL(new CFURL(aURL, this.URL()), resolveAsDirectoriesIfNecessary);
};

/*!
 *  Returns an object with all the resources. Can not be directories.
 */
StaticResource.resolveResourcesAtURLs = function(/*Array of CFURL|String*/ URLs, /*Function*/ aCallback)
{
    var count = URLs.length,
        allResources = {};

    for (var i = 0, size = count; i < size; i++)
    {
        var url = URLs[i];

        StaticResource.resolveResourceAtURL(url, NO, function(aResource) {
            allResources[url] = aResource;

            if (--count === 0)
                aCallback(allResources);
        });
    }
}

StaticResource.resolveResourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ isDirectory, /*Function*/ aCallback, /*Dictionary*/ aFilenameTranslateDictionary, /*BOOL*/ dontCompile)
{
    aURL = makeAbsoluteURL(aURL).absoluteURL();

    resolveResourceComponents(rootResourceForAbsoluteURL(aURL), isDirectory, aURL.pathComponents(), 0, aCallback, aFilenameTranslateDictionary, null, dontCompile);
};

StaticResource.prototype.resolveResourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ isDirectory, /*Function*/ aCallback)
{
    StaticResource.resolveResourceAtURL(new CFURL(aURL, this.URL()).absoluteURL(), isDirectory, aCallback);
};

function resolveResourceComponents(/*StaticResource*/ aResource, /*BOOL*/ isDirectory, /*Array*/ components, /*Integer*/ index, /*Function*/ aCallback, /*Dictionary*/ aFilenameTranslateDictionary, /*Array*/ compileIncludeFileArray, /*BOOL*/ dontCompile)
{
    var count = components.length;

    for (; index < count; ++index)
    {
        var name = components[index],
            child = hasOwnProperty.call(aResource._children, name) && aResource._children[name];

        // If the child doesn't exist, create and resolve it.
        if (!child)
        {
            var translationDictionary = nil;
            if (aFilenameTranslateDictionary == null) {
                var bundle = new CFBundle(aResource.URL());

                if (bundle != null) {
                    var bundleTranslationDictionary = bundle.valueForInfoDictionaryKey("CPFileTranslationDictionary");

                    if (bundleTranslationDictionary != null) {
                        translationDictionary = bundleTranslationDictionary.toJSObject();
                    }

                    var bundleIncludeFileArray = bundle.valueForInfoDictionaryKey("CPCompileIncludeFileArray");

                    if (bundleIncludeFileArray != null) {
                        compileIncludeFileArray = bundleIncludeFileArray.map(function(includeFilePath) {
                            return new CFURL(includeFilePath, aResource.URL());
                        });
                    }
                }
            }

            var u = new CFURL(name, aResource.URL());

            child = new StaticResource(u, aResource, index + 1 < count || isDirectory , NO, translationDictionary || aFilenameTranslateDictionary);
            child.resolve(dontCompile, compileIncludeFileArray);
        }

        // If this resource is still being resolved, just wait and rerun this same method when it's ready.
        if (!child.isResolved())
            return child.addEventListener("resolve", function()
            {
                // Continue resolving once this is done.
                resolveResourceComponents(aResource, isDirectory, components, index, aCallback, aFilenameTranslateDictionary, compileIncludeFileArray, dontCompile);
            });

        // If we've already determined that this file doesn't exist...
        if (child.isNotFound())
            return aCallback(null, new Error("File not found: " + components.join("/")));

        // If we have more path components and this is not a directory...
        if ((index + 1 < count) && child.isFile())
            return aCallback(null, new Error("File is not a directory: " + components.join("/")));

        aResource = child;
    }

    aCallback(aResource);
}

function resolveResourceAtURLSearchingIncludeURLs(/*CFURL*/ aURL, /*Number*/ anIndex, /*Function*/ aCallback)
{
    var includeURLs = StaticResource.includeURLs(),
        searchURL = new CFURL(aURL, includeURLs[anIndex]).absoluteURL();

    StaticResource.resolveResourceAtURL(searchURL, NO, function(/*StaticResource*/ aStaticResource)
    {
        if (!aStaticResource)
        {
            if (anIndex + 1 < includeURLs.length)
                resolveResourceAtURLSearchingIncludeURLs(aURL, anIndex + 1, aCallback);
            else
                aCallback(NULL);

            return;
        }

        aCallback(aStaticResource);
    });
}

StaticResource.resolveResourceAtURLSearchingIncludeURLs = function(/*CFURL*/ aURL, /*Function*/ aCallback)
{
    resolveResourceAtURLSearchingIncludeURLs(aURL, 0, aCallback);
};

StaticResource.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
};

StaticResource.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
};

StaticResource.prototype.isNotFound = function()
{
    return this._isNotFound;
};

StaticResource.prototype.isFile = function()
{
    return !this._isDirectory;
};

StaticResource.prototype.isDirectory = function()
{
    return this._isDirectory;
};

StaticResource.prototype.toString = function(/*BOOL*/ includeNotFounds)
{
    if (this.isNotFound())
        return "<file not found: " + this.name() + ">";

    var string = this.name();

    if (this.isDirectory())
    {
        var children = this._children;

        for (var name in children)
            if (children.hasOwnProperty(name))
            {
                var child = children[name];

                if (includeNotFounds || !child.isNotFound())
                    string += "\n\t" + children[name].toString(includeNotFounds).split('\n').join("\n\t");
            }
    }

    return string;
};

var includeURLs = NULL;

StaticResource.includeURLs = function()
{
    if (includeURLs !== NULL)
        return includeURLs;

    includeURLs = [];

    if (!global.OBJJ_INCLUDE_PATHS && !global.OBJJ_INCLUDE_URLS)
        includeURLs = ["Frameworks", "Frameworks/Debug"];
    else
        includeURLs = (global.OBJJ_INCLUDE_PATHS || []).concat(global.OBJJ_INCLUDE_URLS || []);

    var count = includeURLs.length;

    while (count--)
        includeURLs[count] = new CFURL(includeURLs[count]).asDirectoryPathURL();

    return includeURLs;
};

// Set the compiler flags to empty dictionary so the default values are correct.
StaticResource.setCurrentCompilerFlags({});
