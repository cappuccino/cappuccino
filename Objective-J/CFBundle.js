
var CFBundleUnloaded                = 0,
    CFBundleLoading                 = 1 << 0,
    CFBundleLoadingInfoPlist        = 1 << 1,
    CFBundleLoadingExecutable       = 1 << 2,
    CFBundleLoadingSpritedImages    = 1 << 3,
    CFBundleLoaded                  = 1 << 4;

var CFBundlesForPaths   = { },
    CFBundlesForClasses = { },
    CFCacheBuster = new Date().getTime();

function CFBundle(/*String*/ aPath)
{
    aPath = FILE.absolute(aPath);

    var existingBundle = CFBundlesForPaths[aPath];

    if (existingBundle)
        return existingBundle;

    CFBundlesForPaths[aPath] = this;

    this._path = aPath;
    this._name = FILE.basename(aPath);
    this._staticResourceNode = NULL;

    this._loadStatus = CFBundleUnloaded;
    this._loadRequests = [];

    this._infoDictionary = NULL;
    this._URIMap = { };

    this._eventDispatcher = new EventDispatcher(this);
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

    var objj_environments = exports.environments(),
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

    var self = this;

    self._loadStatus = CFBundleLoading | CFBundleLoadingInfoPlist;

    rootNode.resolveSubPath(FILE.dirname(self.path()), StaticResourceNode.DirectoryType, function(aStaticResourceNode)
    {
        self._staticResourceNode = new StaticResourceNode(FILE.basename(self.path()), aStaticResourceNode, StaticResourceNode.DirectoryType, NO);

        function onsuccess(/*Event*/ anEvent)
        {
            self._loadStatus &= ~CFBundleLoadingInfoPlist;
            self._infoDictionary = anEvent.request.responsePropertyList();

            if (!self._infoDictionary)
            {
                self._eventDispatcher.dispatchEvent(
                {
                    type:"error", 
                    error: new Error("Could not load bundle at \"" + self.path() + "\"")
                });

                return;
            }

            loadExecutableAndResources(self, shouldExecute);
        }

        function onfailure()
        {
            self._staticResourceNode._isResolved = YES;
            self._loadStatus = CFBundleUnloaded;
            self._eventDispatcher.dispatchEvent(
            {
                type:"error", 
                error: new Error("Could not load bundle at \"" + self.path() + "\"")
            });
        }

        new FileRequest(FILE.join(self.path(), "Info.plist"), onsuccess, onfailure);
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

    function failure()
    {
        var loadRequests = aBundle._loadRequests,
            count = loadRequests.length;

        while (count--)
            loadRequests[count].abort();

        this._loadRequests = [];

        aBundle._loadStatus = CFBundleUnloaded;

        resolveStaticResourceNode(aBundle._staticResourceNode, NO);

        aBundle._eventDispatcher.dispatchEvent(
        {
            type:"error", 
            error:new Error("Could not recognize executable code format in Bundle " + aBundle),
            bundle:aBundle
        });

        resolveStaticResourceNode(aBundle._staticResourceNode, YES);
    }

    function success()
    {
        if (aBundle._loadStatus === CFBundleLoading)
            aBundle._loadStatus = CFBundleLoaded;
        else
            return;

        // Set resolved to true here in case during evaluation this bundle 
        // needs to resolve another bundle which in turn needs it to be resolved (cycle).
        resolveStaticResourceNode(aBundle._staticResourceNode, NO);

        function complete()
        {
            aBundle._eventDispatcher.dispatchEvent(
            {
                type:"load", 
                bundle:aBundle
            });
    
            resolveStaticResourceNode(aBundle._staticResourceNode, YES);
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
            decompileStaticFile(aBundle, anEvent.request.responseText())
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
            decompileStaticFile(aBundle, anEvent.request.responseText());
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
        MHTMLPath,
        CFBundleMHTMLUncachedSpriteType,
        MHTMLPath+"?"+CFCacheBuster]);
}

function CFBundleNotifySpriteSupportListeners()
{
    var count = CFBundleSpriteSupportListeners.length;

    while (count--)
        CFBundleSpriteSupportListeners[count]();
}

function CFBundleTestSpriteTypes(/*Array*/ spriteTypes)
{
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
        if (spriteTypes.length === 2)
        {
            CFBundleSupportedSpriteType = CFBundleNoSpriteType;
            CFBundleNotifySpriteSupportListeners();
        }
        else
            CFBundleTestSpriteType(spriteTypes.slice(2));
    }

    image.src = spriteTypes[1];
}

function spritedImagesTestPathForBundle(/*Bundle*/ aBundle)
{
    return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTMLTest.txt");
}

function spritedImagesPathForBundle(/*Bundle*/ aBundle)
{
    if (CFBundleSupportedSpriteType === CFBundleDataURLSpriteType)
        return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "dataURLs.txt");

    if (CFBundleSupportedSpriteType === CFBundleMHTMLSpriteType)
        return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTML.txt");

    if (CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
        return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTML.txt?" + CFCacheBuster);
    
    return NULL;
}

CFBundle.dataContentsAtPath = function(/*String*/ aPath)
{
    var data = new CFMutableData();

    data.setEncodedString(rootNode.nodeAtSubPath(aPath).contents());

    return data;
}

function executeBundle(/*Bundle*/ aBundle)
{
    var staticResources = [aBundle._staticResourceNode];

    function executeStaticResources(staticResources, index)
    {
        for (; index < staticResources.length; ++index)
        {
            var staticResource = staticResources[index];

            if (staticResource.type() === StaticResourceNode.FileType)
            {
                var executable = new FileExecutable(staticResource.path());

                if (staticResource.hasLoadedFileDependencies())
                    executable.execute();

                else
                {
                    executable.addEventListeners("dependenciesload", function()
                    {
                        executeStaticResources(index);
                    });
                    return;
                }
            }
            else
                staticResources = staticResources.concat(staticResource.children());
        }
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

function decompileStaticFile(/*Bundle*/ aBundle, /*String*/ aString)
{
    var stream = new MarkedStream(aString);

    if (stream.magicNumber() !== STATIC_MAGIC_NUMBER)
        throw new Error("Could not read static file.");

    if (stream.version() !== "1.0")
        throw new Error("Could not read static file.");

    var marker,
        bundlePath = aBundle.path();

    while (marker = stream.getMarker())   
    {
        var text = stream.getString();

        if (marker === MARKER_PATH)
        {
            var absolutePath = FILE.join(bundlePath, text),
                parentNode = rootNode.nodeAtSubPath(FILE.dirname(absolutePath), YES);

            fileNode = new StaticResourceNode(FILE.basename(absolutePath), parentNode, StaticResourceNode.FileType, YES);
        }

        else if (marker === MARKER_URI)
        {
            var URI = stream.getString();

            if (URI.toLowerCase().indexOf("mhtml:") === 0)
                URI = "mhtml:" + FILE.join(bundlePath, URI.substr("mhtml:".length));

            aBundle._URIMap[text] = URI;

            // The unresolved directories must not be bundles.
            rootNode.nodeAtSubPath(FILE.join(bundlePath, FILE.dirname(text)), YES);
        }

        else if (marker === MARKER_TEXT)
            fileNode.write(text);
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

exports.CFBundle = CFBundle;
