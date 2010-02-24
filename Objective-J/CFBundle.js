/*
 * CFBundle.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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

var CFBundleUnloaded                = 0,
    CFBundleLoading                 = 1 << 0,
    CFBundleLoadingInfoPlist        = 1 << 1,
    CFBundleLoadingExecutable       = 1 << 2,
    CFBundleLoadingSpritedImages    = 1 << 3,
    CFBundleLoaded                  = 1 << 4;

var CFBundlesForPaths   = { },
    CFBundlesForClasses = { },
    CFCacheBuster = new Date().getTime();

GLOBAL(CFBundle) = function(/*String*/ aPath)
{
    aPath = FILE.absolute(aPath);

    var existingBundle = CFBundlesForPaths[aPath];

    if (existingBundle)
        return existingBundle;

    CFBundlesForPaths[aPath] = this;

    this._path = aPath;
    this._name = FILE.basename(aPath);
    this._staticResource = NULL;

    this._loadStatus = CFBundleUnloaded;
    this._loadRequests = [];

    this._infoDictionary = NULL;
    this._URIMap = { };

    this._eventDispatcher = new EventDispatcher(this);
}

CFBundle.environments = function()
{
    // Passed in by GCC.
    return ENVIRONMENTS;
}

CFBundle.bundleContainingPath = function(/*String*/ aPath)
{
    aPath = FILE.absolute(aPath);

    while (aPath !== "/")
    {
        var bundle = CFBundlesForPaths[aPath];

        if (bundle)
            return bundle;

        aPath = FILE.dirname(aPath);
    }

    return NULL;
}

CFBundle.mainBundle = function()
{
    return new CFBundle(FILE.cwd());
}

function addClassToBundle(aClass, aBundle)
{
    if (aBundle)
        CFBundlesForClasses[aClass.name] = aBundle;
}

CFBundle.bundleForClass = function(/*Class*/ aClass)
{
    return CFBundlesForClasses[aClass.name] || CFBundle.mainBundle();
}

CFBundle.prototype.path = function()
{
    return this._path;
}

CFBundle.prototype.infoDictionary = function()
{
    return this._infoDictionary;
}

CFBundle.prototype.valueForInfoDictionary = function(/*String*/ aKey)
{
    return this._infoDictionary.valueForKey(aKey);
}

CFBundle.prototype.resourcesPath = function()
{
    return FILE.join(this.path(), "Resources");
}

CFBundle.prototype.pathForResource = function(/*String*/ aPath)
{
    var mappedPath = this._URIMap[FILE.join("Resources", aPath)];

    if (mappedPath)
        return mappedPath;

    // If not, return the trivial path.
    return FILE.join(this.resourcesPath(), aPath);
}

CFBundle.prototype.executablePath = function()
{
    var executableSubPath = this._infoDictionary.valueForKey("CPBundleExecutable");

    if (executableSubPath)
        return FILE.join(this.path(), this.mostEligibleEnvironment() + ".environment", executableSubPath);

    return NULL;
}

CFBundle.prototype.hasSpritedImages = function()
{
    var environments = this._infoDictionary.valueForKey("CPBundleEnvironmentsWithImageSprites") || [],
        index = environments.length,
        mostEligibleEnvironment = this.mostEligibleEnvironment();

    while (index--)
        if (environments[index] === mostEligibleEnvironment)
            return YES;

    return NO;
}

CFBundle.prototype.environments = function()
{
    return this._infoDictionary.valueForKey("CPBundleEnvironments") || ["ObjJ"];
}

CFBundle.prototype.mostEligibleEnvironment = function(/*Array*/ environments)
{
    environments = environments || this.environments();

    var objj_environments = CFBundle.environments(),
        index = 0,
        count = objj_environments.length,
        innerCount = environments.length;

    // Ugh, no indexOf, no objects-in-common.
    for(; index < count; ++index)
    {
        var innerIndex = 0,
            environment = objj_environments[index];

        for (; innerIndex < innerCount; ++innerIndex)
            if(environment === environments[innerIndex])
                return environment;
    }

    return NULL;
}

CFBundle.prototype.isLoading = function()
{
    return this._loadStatus & CFBundleLoading;
}

CFBundle.prototype.load = function(/*BOOL*/ shouldExecute)
{
    if (this._loadStatus !== CFBundleUnloaded)
        return;

    this._loadStatus = CFBundleLoading | CFBundleLoadingInfoPlist;

    var self = this;

    rootResource.resolveSubPath(FILE.dirname(self.path()), YES, function(aStaticResource)
    {
        var path = self.path();

        // If this bundle exists at the root path, no need to create a node.
        if (path === "/")
            self._staticResource = rootResource;

        else
        {
            var name = FILE.basename(path);

            self._staticResource = aStaticResource._children[name];

            if (!self._staticResource)
                self._staticResource = new StaticResource(name, aStaticResource, YES, NO);
        }

        function onsuccess(/*Event*/ anEvent)
        {
            self._loadStatus &= ~CFBundleLoadingInfoPlist;
            self._infoDictionary = anEvent.request.responsePropertyList();

            if (!self._infoDictionary)
            {
                finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + path + "\""));

                return;
            }

            loadExecutableAndResources(self, shouldExecute);
        }

        function onfailure()
        {
            self._loadStatus = CFBundleUnloaded;

            finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + path + "\""));
        }

        new FileRequest(FILE.join(path, "Info.plist"), onsuccess, onfailure);
    });
}

function finishBundleLoadingWithError(/*CFBundle*/ aBundle, /*Event*/ anError)
{
    resolveStaticResource(aBundle._staticResource);

    aBundle._eventDispatcher.dispatchEvent(
    {
        type:"error",
        error:anError,
        bundle:aBundle
    });
}

function loadExecutableAndResources(/*Bundle*/ aBundle, /*BOOL*/ shouldExecute)
{
    if (!aBundle.mostEligibleEnvironment())
        return failure();

    loadExecutableForBundle(aBundle, success, failure);
    loadSpritedImagesForBundle(aBundle, success, failure);

    if (aBundle._loadStatus === CFBundleLoading)
        return success();

    function failure(/*Error*/ anError)
    {
        var loadRequests = aBundle._loadRequests,
            count = loadRequests.length;

        while (count--)
            loadRequests[count].abort();

        this._loadRequests = [];

        aBundle._loadStatus = CFBundleUnloaded;

        finishBundleLoadingWithError(aBundle, anError || new Error("Could not recognize executable code format in Bundle " + aBundle));
    }

    function success()
    {
        if (aBundle._loadStatus === CFBundleLoading)
            aBundle._loadStatus = CFBundleLoaded;
        else
            return;

        // Set resolved to true here in case during evaluation this bundle
        // needs to resolve another bundle which in turn needs it to be resolved (cycle).
        resolveStaticResource(aBundle._staticResource);

        function complete()
        {
            aBundle._eventDispatcher.dispatchEvent(
            {
                type:"load",
                bundle:aBundle
            });
        }

        if (shouldExecute)
            executeBundle(aBundle, complete);
        else
            complete();
    }
}

function loadExecutableForBundle(/*Bundle*/ aBundle, success, failure)
{
    if (!aBundle.executablePath())
        return;

    aBundle._loadStatus |= CFBundleLoadingExecutable;

    new FileRequest(aBundle.executablePath(), function(/*Event*/ anEvent)
    {
        try
        {
            decompileStaticFile(aBundle, anEvent.request.responseText(), aBundle.executablePath());
            aBundle._loadStatus &= ~CFBundleLoadingExecutable;
            success();
        }
        catch(anException)
        {
            failure(anException);
        }
    }, failure);
}

function loadSpritedImagesForBundle(/*Bundle*/ aBundle, success, failure)
{
    if (!aBundle.hasSpritedImages())
        return;

    aBundle._loadStatus |= CFBundleLoadingSpritedImages;

    if (!CFBundleHasTestedSpriteSupport())
        return CFBundleTestSpriteSupport(spritedImagesTestPathForBundle(aBundle), function()
        {
            loadSpritedImagesForBundle(aBundle, success, failure);
        });

    var spritedImagesPath = spritedImagesPathForBundle(aBundle);

    if (!spritedImagesPath)
    {
        aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
        return success();
    }

    new FileRequest(spritedImagesPath, function(/*Event*/ anEvent)
    {
        try
        {
            decompileStaticFile(aBundle, anEvent.request.responseText(), spritedImagesPath);
            aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
            success();
        }
        catch(anException)
        {
            failure(anException);
        }
    }, failure);
}

var CFBundleSpriteSupportListeners  = [],
    CFBundleSupportedSpriteType     = -1,
    CFBundleNoSpriteType            = 0,
    CFBundleDataURLSpriteType       = 1,
    CFBundleMHTMLSpriteType         = 2,
    CFBundleMHTMLUncachedSpriteType = 3;

function CFBundleHasTestedSpriteSupport()
{
    return CFBundleSupportedSpriteType !== -1;
}

function CFBundleTestSpriteSupport(/*String*/ MHTMLPath, /*Function*/ aCallback)
{
    if (CFBundleHasTestedSpriteSupport())
        return;

    CFBundleSpriteSupportListeners.push(aCallback);

    if (CFBundleSpriteSupportListeners.length > 1)
        return;

    CFBundleTestSpriteTypes([
        CFBundleDataURLSpriteType,
        "data:image/gif;base64,R0lGODlhAQABAIAAAMc9BQAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==",
        CFBundleMHTMLSpriteType,
        MHTMLPath+"!test",
        CFBundleMHTMLUncachedSpriteType,
        MHTMLPath+"?"+CFCacheBuster+"!test"
    ]);
}

function CFBundleNotifySpriteSupportListeners()
{
    var count = CFBundleSpriteSupportListeners.length;

    while (count--)
        CFBundleSpriteSupportListeners[count]();
}

function CFBundleTestSpriteTypes(/*Array*/ spriteTypes)
{
    if (spriteTypes.length < 2)
    {
        CFBundleSupportedSpriteType = CFBundleNoSpriteType;
        CFBundleNotifySpriteSupportListeners();
        return;
    }

    var image = new Image();

    image.onload = function()
    {
        if (image.width === 1 && image.height === 1)
        {
            CFBundleSupportedSpriteType = spriteTypes[0];
            CFBundleNotifySpriteSupportListeners();
        }
        else
            image.onerror();
    }

    image.onerror = function()
    {
        CFBundleTestSpriteTypes(spriteTypes.slice(2));
    }

    image.src = spriteTypes[1];
}

function mhtmlBasePath()
{
#ifdef BROWSER
    //FIXME: URL stuff is kind of broken
    return window.location.protocol + "//" + window.location.hostname + (window.location.port ? (":" + window.location.port) : "");
#else
    return "";
#endif
}

function spritedImagesTestPathForBundle(/*Bundle*/ aBundle)
{
    return "mhtml:" + mhtmlBasePath() + FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTMLTest.txt");
}

function spritedImagesPathForBundle(/*Bundle*/ aBundle)
{
    if (CFBundleSupportedSpriteType === CFBundleDataURLSpriteType)
        return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "dataURLs.txt");

    if (CFBundleSupportedSpriteType === CFBundleMHTMLSpriteType || CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
        return mhtmlBasePath() + FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTMLPaths.txt");

    return NULL;
}

CFBundle.dataContentsAtPath = function(/*String*/ aPath)
{
    var data = new CFMutableData();

    data.setRawString(rootResource.nodeAtSubPath(aPath).contents());

    return data;
}

function executeBundle(/*Bundle*/ aBundle, /*Function*/ aCallback)
{
    var staticResources = [aBundle._staticResource],
        resourcesPath = aBundle.resourcesPath();

    function executeStaticResources(index)
    {
        for (; index < staticResources.length; ++index)
        {
            var staticResource = staticResources[index];

            if (staticResource.isNotFound())
                continue;

            if (staticResource.isFile())
            {
                var executable = new FileExecutable(staticResource.path());

                if (executable.hasLoadedFileDependencies())
                    executable.execute();

                else
                {
                    executable.addEventListener("dependenciesload", function()
                    {
                        executeStaticResources(index);
                    });
                    executable.loadFileDependencies();
                    return;
                }
            }
            else //if (staticResource.isDirectory())
            {
                // We don't want to execute resources.
                if (staticResource.path() === aBundle.resourcesPath())
                    continue;

                var children = staticResource.children();

                for (var name in children)
                    if (hasOwnProperty.call(children, name))
                        staticResources.push(children[name]);
            }
        }

        aCallback();
    }

    executeStaticResources(0);
}

var STATIC_MAGIC_NUMBER     = "@STATIC",
    MARKER_PATH             = "p",
    MARKER_URI              = "u",
    MARKER_CODE             = "c",
    MARKER_TEXT             = "t",
    MARKER_IMPORT_STD       = 'I',
    MARKER_IMPORT_LOCAL     = 'i';

function decompileStaticFile(/*Bundle*/ aBundle, /*String*/ aString, /*String*/ aPath)
{
    var stream = new MarkedStream(aString);

    if (stream.magicNumber() !== STATIC_MAGIC_NUMBER)
        throw new Error("Could not read static file: "+aPath);

    if (stream.version() !== "1.0")
        throw new Error("Could not read static file: "+aPath);

    var marker,
        bundlePath = aBundle.path(),
        file = NULL;

    while (marker = stream.getMarker())
    {
        var text = stream.getString();

        if (marker === MARKER_PATH)
        {
            var absolutePath = FILE.join(bundlePath, text),
                parent = rootResource.nodeAtSubPath(FILE.dirname(absolutePath), YES);

            file = new StaticResource(FILE.basename(absolutePath), parent, NO, YES);
        }

        else if (marker === MARKER_URI)
        {
            var URI = stream.getString();

            if (URI.toLowerCase().indexOf("mhtml:") === 0)
            {
                URI = "mhtml:" + mhtmlBasePath() + FILE.join(bundlePath, URI.substr("mhtml:".length));

                if (CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
                {
                    var exclamationIndex = URI.indexOf("!"),
                        firstPart = URI.substring(0, exclamationIndex),
                        lastPart = URI.substring(exclamationIndex);

                    URI = firstPart + "?" + CFCacheBuster + lastPart;
                }
            }
            aBundle._URIMap[text] = URI;

            // The unresolved directories must not be bundles.
            var parent = rootResource.nodeAtSubPath(FILE.join(bundlePath, FILE.dirname(text)), YES);

            new StaticResource(FILE.basename(text), parent, NO, YES);
        }

        else if (marker === MARKER_TEXT)
            file.write(text);
    }
}

// Event Managament

CFBundle.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

CFBundle.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

CFBundle.prototype.onerror = function(/*Event*/ anEvent)
{
    throw anEvent.error;
}
