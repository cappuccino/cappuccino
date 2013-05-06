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

var CFBundlesForURLStrings   = { },
    CFBundlesForClasses      = { },
    CFBundlesWithIdentifiers = { },
    CFCacheBuster       = new Date().getTime(),
    CFTotalBytesLoaded  = 0,
    CPApplicationSizeInBytes = 0;

GLOBAL(CFBundle) = function(/*CFURL|String*/ aURL)
{
    aURL = makeAbsoluteURL(aURL).asDirectoryPathURL();

    var URLString = aURL.absoluteString(),
        existingBundle = CFBundlesForURLStrings[URLString];

    if (existingBundle)
        return existingBundle;

    CFBundlesForURLStrings[URLString] = this;

    this._bundleURL = aURL;
    this._resourcesDirectoryURL = new CFURL("Resources/", aURL);

    this._staticResource = NULL;
    this._isValid = NO;

    this._loadStatus = CFBundleUnloaded;
    this._loadRequests = [];

    this._infoDictionary = new CFDictionary();

    this._eventDispatcher = new EventDispatcher(this);
}

DISPLAY_NAME(CFBundle);

CFBundle.environments = function()
{
    // Passed in by GCC.
    return ENVIRONMENTS;
};

DISPLAY_NAME(CFBundle.environments);

CFBundle.bundleContainingURL = function(/*CFURL|String*/ aURL)
{
    aURL = new CFURL(".", makeAbsoluteURL(aURL));

    var previousURLString,
        URLString = aURL.absoluteString();

    while (!previousURLString || previousURLString !== URLString)
    {
        var bundle = CFBundlesForURLStrings[URLString];

        if (bundle && bundle._isValid)
            return bundle;

        aURL = new CFURL("..", aURL);
        previousURLString = URLString;
        URLString = aURL.absoluteString();
    }

    return NULL;
};

DISPLAY_NAME(CFBundle.bundleContainingURL);

CFBundle.mainBundle = function()
{
    return new CFBundle(mainBundleURL);
};

DISPLAY_NAME(CFBundle.mainBundle);

function addClassToBundle(aClass, aBundle)
{
    if (aBundle)
        CFBundlesForClasses[aClass.name] = aBundle;
}

function resetBundle()
{
    CFBundlesForURLStrings   = { };
    CFBundlesForClasses      = { };
    CFBundlesWithIdentifiers = { };
    //CFCacheBuster       = new Date().getTime(),
    CFTotalBytesLoaded  = 0;
    CPApplicationSizeInBytes = 0;
}

CFBundle.bundleForClass = function(/*Class*/ aClass)
{
    return CFBundlesForClasses[aClass.name] || CFBundle.mainBundle();
};

DISPLAY_NAME(CFBundle.bundleForClass);

CFBundle.bundleWithIdentifier = function(/*String*/ bundleID)
{
    return CFBundlesWithIdentifiers[bundleID] || NULL;
};

DISPLAY_NAME(CFBundle.bundleWithIdentifier);

CFBundle.prototype.bundleURL = function()
{
    return this._bundleURL.absoluteURL();
};

DISPLAY_NAME(CFBundle.prototype.bundleURL);

CFBundle.prototype.resourcesDirectoryURL = function()
{
    return this._resourcesDirectoryURL;
};

DISPLAY_NAME(CFBundle.prototype.resourcesDirectoryURL);

CFBundle.prototype.resourceURL = function(/*String*/ aResourceName, /*String*/ aType, /*String*/ aSubDirectory)
 {
    if (aType)
        aResourceName = aResourceName + "." + aType;

    if (aSubDirectory)
        aResourceName = aSubDirectory + "/" + aResourceName;

    var resourceURL = (new CFURL(aResourceName, this.resourcesDirectoryURL())).mappedURL();

    return resourceURL.absoluteURL();
};

DISPLAY_NAME(CFBundle.prototype.resourceURL);

CFBundle.prototype.mostEligibleEnvironmentURL = function()
{
    if (this._mostEligibleEnvironmentURL === undefined)
        this._mostEligibleEnvironmentURL = new CFURL(this.mostEligibleEnvironment() + ".environment/", this.bundleURL());

    return this._mostEligibleEnvironmentURL;
}

DISPLAY_NAME(CFBundle.prototype.mostEligibleEnvironmentURL);

CFBundle.prototype.executableURL = function()
{
    if (this._executableURL === undefined)
    {
        var executableSubPath = this.valueForInfoDictionaryKey("CPBundleExecutable");

        if (!executableSubPath)
            this._executableURL = NULL;
        else
            this._executableURL = new CFURL(executableSubPath, this.mostEligibleEnvironmentURL());
    }

    return this._executableURL;
};

DISPLAY_NAME(CFBundle.prototype.executableURL);

CFBundle.prototype.infoDictionary = function()
{
    return this._infoDictionary;
};

DISPLAY_NAME(CFBundle.prototype.infoDictionary);

CFBundle.prototype.valueForInfoDictionaryKey = function(/*String*/ aKey)
{
    return this._infoDictionary.valueForKey(aKey);
};

DISPLAY_NAME(CFBundle.prototype.valueForInfoDictionaryKey);

CFBundle.prototype.identifier = function()
{
    return this._infoDictionary.valueForKey("CPBundleIdentifier");
};

DISPLAY_NAME(CFBundle.prototype.identifier);

CFBundle.prototype.hasSpritedImages = function()
{
    var environments = this._infoDictionary.valueForKey("CPBundleEnvironmentsWithImageSprites") || [],
        index = environments.length,
        mostEligibleEnvironment = this.mostEligibleEnvironment();

    while (index--)
        if (environments[index] === mostEligibleEnvironment)
            return YES;

    return NO;
};

DISPLAY_NAME(CFBundle.prototype.hasSpritedImages);

CFBundle.prototype.environments = function()
{
    return this._infoDictionary.valueForKey("CPBundleEnvironments") || ["ObjJ"];
};

DISPLAY_NAME(CFBundle.prototype.environments);

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
};

DISPLAY_NAME(CFBundle.prototype.mostEligibleEnvironment);

CFBundle.prototype.isLoading = function()
{
    return this._loadStatus & CFBundleLoading;
};

DISPLAY_NAME(CFBundle.prototype.isLoading);

CFBundle.prototype.isLoaded = function()
{
    return !!(this._loadStatus & CFBundleLoaded);
};

DISPLAY_NAME(CFBundle.prototype.isLoaded);

CFBundle.prototype.load = function(/*BOOL*/ shouldExecute)
{
    if (this._loadStatus !== CFBundleUnloaded)
        return;

    this._loadStatus = CFBundleLoading | CFBundleLoadingInfoPlist;

    var self = this,
        bundleURL = this.bundleURL(),
        parentURL = new CFURL("..", bundleURL);

    if (parentURL.absoluteString() === bundleURL.absoluteString())
        parentURL = parentURL.schemeAndAuthority();

    StaticResource.resolveResourceAtURL(parentURL, YES, function(aStaticResource)
    {
        var resourceName = bundleURL.lastPathComponent();

        self._staticResource =  aStaticResource._children[resourceName] ||
                                new StaticResource(bundleURL, aStaticResource, YES, NO);

        function onsuccess(/*Event*/ anEvent)
        {
            self._loadStatus &= ~CFBundleLoadingInfoPlist;

            var infoDictionary = anEvent.request.responsePropertyList();

            self._isValid = !!infoDictionary || CFBundle.mainBundle() === self;

            if (infoDictionary)
            {
                self._infoDictionary = infoDictionary;

                var identifier = self._infoDictionary.valueForKey("CPBundleIdentifier");

                if (identifier)
                    CFBundlesWithIdentifiers[identifier] = self;
            }

            if (!self._infoDictionary)
            {
                finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + path + "\""));

                return;
            }

            if (self === CFBundle.mainBundle() && self.valueForInfoDictionaryKey("CPApplicationSize"))
                CPApplicationSizeInBytes = self.valueForInfoDictionaryKey("CPApplicationSize").valueForKey("executable") || 0;

            loadExecutableAndResources(self, shouldExecute);
        }

        function onfailure()
        {
            self._isValid = CFBundle.mainBundle() === self;
            self._loadStatus = CFBundleUnloaded;

            finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + self.bundleURL() + "\""));
        }

        new FileRequest(new CFURL("Info.plist", self.bundleURL()), onsuccess, onfailure);
    });
};

DISPLAY_NAME(CFBundle.prototype.load);

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
        if ((typeof CPApp === "undefined" || !CPApp || !CPApp._finishedLaunching) &&
             typeof OBJJ_PROGRESS_CALLBACK === "function" && CPApplicationSizeInBytes)
        {
            OBJJ_PROGRESS_CALLBACK(MAX(MIN(1.0, CFTotalBytesLoaded / CPApplicationSizeInBytes), 0.0), CPApplicationSizeInBytes, aBundle.bundlePath());
        }

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
    var executableURL = aBundle.executableURL();

    if (!executableURL)
        return;

    aBundle._loadStatus |= CFBundleLoadingExecutable;

    new FileRequest(executableURL, function(/*Event*/ anEvent)
    {
        try
        {
            CFTotalBytesLoaded += anEvent.request.responseText().length;
            decompileStaticFile(aBundle, anEvent.request.responseText(), executableURL);
            aBundle._loadStatus &= ~CFBundleLoadingExecutable;
            success();
        }
        catch(anException)
        {
            failure(anException);
        }
    }, failure);
}

function spritedImagesTestURLStringForBundle(/*Bundle*/ aBundle)
{
    return "mhtml:" + new CFURL("MHTMLTest.txt", aBundle.mostEligibleEnvironmentURL());
}

function spritedImagesURLForBundle(/*Bundle*/ aBundle)
{
    if (CFBundleSupportedSpriteType === CFBundleDataURLSpriteType)
        return new CFURL("dataURLs.txt", aBundle.mostEligibleEnvironmentURL());

    if (CFBundleSupportedSpriteType === CFBundleMHTMLSpriteType ||
        CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
        return new CFURL("MHTMLPaths.txt", aBundle.mostEligibleEnvironmentURL());

    return NULL;
}

function loadSpritedImagesForBundle(/*Bundle*/ aBundle, success, failure)
{
    if (!aBundle.hasSpritedImages())
        return;

    aBundle._loadStatus |= CFBundleLoadingSpritedImages;

    if (!CFBundleHasTestedSpriteSupport())
        return CFBundleTestSpriteSupport(spritedImagesTestURLStringForBundle(aBundle), function()
        {
            loadSpritedImagesForBundle(aBundle, success, failure);
        });

    var spritedImagesURL = spritedImagesURLForBundle(aBundle);

    if (!spritedImagesURL)
    {
        aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
        return success();
    }

    new FileRequest(spritedImagesURL, function(/*Event*/ anEvent)
    {
        try
        {
            CFTotalBytesLoaded += anEvent.request.responseText().length;
            decompileStaticFile(aBundle, anEvent.request.responseText(), spritedImagesURL);
            aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
        }
        catch(anException)
        {
            failure(anException);
        }

        success();
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

    CFBundleSpriteSupportListeners.push(function()
    {
        var size = 0,
            sizeDictionary = CFBundle.mainBundle().valueForInfoDictionaryKey("CPApplicationSize");

        if (!sizeDictionary)
            return;

        switch (CFBundleSupportedSpriteType)
        {
            case CFBundleDataURLSpriteType:
                size = sizeDictionary.valueForKey("data");
                break;

            case CFBundleMHTMLSpriteType:
            case CFBundleMHTMLUncachedSpriteType:
                size = sizeDictionary.valueForKey("mhtml");
                break;
        }

        CPApplicationSizeInBytes += size;
    });

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
    // If we don't support Images, then clearly we don't support sprites.
    if (!("Image" in global) || spriteTypes.length < 2)
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
    };

    image.onerror = function()
    {
        CFBundleTestSpriteTypes(spriteTypes.slice(2));
    };

    image.src = spriteTypes[1];
}

function executeBundle(/*Bundle*/ aBundle, /*Function*/ aCallback)
{
    var staticResources = [aBundle._staticResource];

    function executeStaticResources(index)
    {
        for (; index < staticResources.length; ++index)
        {
            var staticResource = staticResources[index];

            if (staticResource.isNotFound())
                continue;

            if (staticResource.isFile())
            {
                var executable = new FileExecutable(staticResource.URL());

                if (executable.hasLoadedFileDependencies())
                    executable.execute();

                else
                {
                    executable.loadFileDependencies(function()
                    {
                        executeStaticResources(index);
                    });

                    return;
                }
            }
            else //if (staticResource.isDirectory())
            {
                // We don't want to execute resources.
                if (staticResource.URL().absoluteString() === aBundle.resourcesDirectoryURL().absoluteString())
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
        throw new Error("Could not read static file: " + aPath);

    if (stream.version() !== "1.0")
        throw new Error("Could not read static file: " + aPath);

    var marker,
        bundleURL = aBundle.bundleURL(),
        file = NULL;

    while (marker = stream.getMarker())
    {
        var text = stream.getString();

        if (marker === MARKER_PATH)
        {
            var fileURL = new CFURL(text, bundleURL),
                parent = StaticResource.resourceAtURL(new CFURL(".", fileURL), YES);

            file = new StaticResource(fileURL, parent, NO, YES);
        }

        else if (marker === MARKER_URI)
        {
            var URL = new CFURL(text, bundleURL),
                mappedURLString = stream.getString();

            if (mappedURLString.indexOf("mhtml:") === 0)
            {
                mappedURLString = "mhtml:" + new CFURL(mappedURLString.substr("mhtml:".length), bundleURL);

                if (CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
                {
                    var exclamationIndex = mappedURLString.indexOf("!"),
                        firstPart = mappedURLString.substring(0, exclamationIndex),
                        lastPart = mappedURLString.substring(exclamationIndex);

                    mappedURLString = firstPart + "?" + CFCacheBuster + lastPart;
                }
            }

            CFURL.setMappedURLForURL(URL, new CFURL(mappedURLString));

            // The unresolved directories must not be bundles.
            var parent = StaticResource.resourceAtURL(new CFURL(".", URL), YES);

            new StaticResource(URL, parent, NO, YES);
        }

        else if (marker === MARKER_TEXT)
            file.write(text);
    }
}

// Event Managament

CFBundle.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
};

DISPLAY_NAME(CFBundle.prototype.addEventListener);

CFBundle.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
};

DISPLAY_NAME(CFBundle.prototype.removeEventListener);

CFBundle.prototype.onerror = function(/*Event*/ anEvent)
{
    throw anEvent.error;
};

DISPLAY_NAME(CFBundle.prototype.onerror);

CFBundle.prototype.bundlePath = function()
{
    return this.bundleURL().path();
};

CFBundle.prototype.path = function()
{
    CPLog.warn("CFBundle.prototype.path is deprecated, use CFBundle.prototype.bundlePath instead.");
    return this.bundlePath.apply(this, arguments);
};

CFBundle.prototype.pathForResource = function(aResource)
{
    return this.resourceURL(aResource).absoluteString();
};
