

Bundle.Unloaded             = 0;
Bundle.Loading              = 1 << 0;
Bundle.LoadingInfoPlist     = 1 << 1;
Bundle.LoadingExecutable    = 1 << 2;
Bundle.LoadingResources     = 1 << 3;
Bundle.Loaded               = 1 << 4;

var BundlesForPaths = { };

function Bundle(/*String*/ aPath)
{
    aPath = FILE.absolute(aPath);

    var existingBundle = BundlesForPaths[aPath];

    if (existingBundle)
        return existingBundle;
console.log("created bundle for " + aPath);
    BundlesForPaths[aPath] = this;

    this._path = aPath;
    this._name = FILE.basename(aPath);
    this._loadStatus = Bundle.Unloaded;
    this._staticResourceNode = NULL;

    this._infoDictionary = NULL;
    this._eventDispatcher = new EventDispatcher(this);
}

Bundle.bundleContainingPath = function(/*String*/ aPath)
{
    aPath = FILE.absolute(aPath);

    while (aPath !== "/")
    {
        var bundle = BundlesForPaths[aPath];
        
        if (bundle)
            return bundle;

        aPath = FILE.dirname(aPath);
    }

    return NULL;
}

Bundle.mainBundle = function()
{
    return new Bundle(FILE.cwd());
}

var bundlesForClasses = { };

function addClassToBundle(aClass, aBundle)
{
    if (aBundle)
        bundlesForClasses[aClass.name] = aBundle;
}

Bundle.bundleForClass = function(/*Class*/ aClass)
{
    return bundlesForClasses[aClass.name] || Bundle.mainBundle();
}

Bundle.prototype.path = function()
{
    return this._path;
}

Bundle.prototype.infoDictionary = function()
{
    return this._infoDictionary;
}

Bundle.prototype.valueForInfoDictionary = function(/*String*/ aKey)
{
    return this._infoDictionary.valueForKey(aKey);
}

Bundle.prototype.executablePath = function()
{
    var executableSubPath = this._infoDictionary.valueForKey("CPBundleExecutable");

    if (executableSubPath)
        return FILE.join(this.path(), this.mostEligibleEnvironment() + ".environment", executableSubPath);

    return NULL;
}

Bundle.prototype.environments = function()
{
    return this._infoDictionary.valueForKey("CPBundleEnvironments") || ["ObjJ"];
}

Bundle.prototype.mostEligibleEnvironment = function(/*Array*/ environments)
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

Bundle.prototype.isLoading = function()
{
    return this._loadStatus & Bundle.Loading;
}

Bundle.prototype.load = function(/*BOOL*/ shouldEvaluate)
{
    if (this._loadStatus !== Bundle.Unloaded)
        return;

    var self = this;

    self._loadStatus = Bundle.Loading | Bundle.LoadingInfoPlist;
/*    print(FILE.cwd());
    print(self.path());
    print(rootNode);
print("will resolve: " + FILE.dirname(self.path()));*/
    rootNode.resolveSubPath(FILE.dirname(self.path()), StaticResourceNode.DirectoryType, function(aStaticResourceNode)
    {//print("found: " + FILE.dirname(self.path()));
        self._staticResourceNode = new StaticResourceNode(FILE.basename(self.path()), aStaticResourceNode, StaticResourceNode.DirectoryType, NO);

        function onsuccess(/*Event*/ anEvent)
        {
            self._loadStatus &= ~Bundle.LoadingInfoPlist;
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

            loadExecutableAndResources(self);
        }

        function onfailure()
        {
            self._loadStatus = Bundle.Unloaded;
            self._eventDispatcher.dispatchEvent(
            {
                type:"error", 
                error: new Error("Could not load bundle at \"" + self.path() + "\"")
            });
        }

        new FileRequest(FILE.join(self.path(), "Info.plist"), onsuccess, onfailure);
    });
}

function loadExecutableAndResources(/*Bundle*/ aBundle)
{
    aBundle._loadStatus |= (aBundle.executablePath() && Bundle.LoadingExecutable);
    //aBundle._loadStatus |= (aBundle.mappedResourcesPath() && Bundle.LoadingResources);

    function failure()
    {
        if (aBundle._loadExecutableRequest)
        {
            aBundle._loadExecutableRequest.abort();
            aBundle._loadExecutableRequest = NULL;
        }

        if (aBundle._loadResourcesRequest)
        {
            aBundle._loadResourcesRequest.abort();
            aBundle._loadResourcesRequest = NULL;
        }

        aBundle._loadStatus = Bundle.Unloaded;

        resolveStaticResourceNode(aBundle._staticResourceNode, NO);

        aBundle._eventDispatcher.dispatchEvent(
        {
            type:"error", 
            error:new Error("Could not recognize executable code format in Bundle " + aBundle),
            bundle:self
        });

        resolveStaticResourceNode(aBundle._staticResourceNode, YES);
    }

    function success()
    {
        if (aBundle._loadStatus === Bundle.Loading)
            aBundle._loadStatus = Bundle.Loaded;

        resolveStaticResourceNode(aBundle._staticResourceNode, NO);

        aBundle._eventDispatcher.dispatchEvent(
        {
            type:"load", 
            bundle:aBundle
        });

        resolveStaticResourceNode(aBundle._staticResourceNode, YES);
    }

    if (aBundle._loadStatus === Bundle.Loading)
        return success();

    if (!aBundle.mostEligibleEnvironment())
        failure();

    if (aBundle._loadStatus & Bundle.LoadingExecutable)
    {
        aBundle._loadExecutableRequest = new HTTPRequest();

        var loadExecutableRequest = aBundle._loadExecutableRequest;

        loadExecutableRequest.onsuccess = function()
        {
            decompileExecutable(aBundle, loadExecutableRequest.responseText());
    
            aBundle._loadStatus &= ~Bundle.LoadingExecutable;
    
            success();
        }
    
        loadExecutableRequest.onfailure = failure;

        loadExecutableRequest.open("GET", aBundle.executablePath(), YES);
        loadExecutableRequest.send("");
    }
}

var STATIC_MAGIC_NUMBER     = "@STATIC",
    MARKER_PATH             = "p",
    MARKER_URI              = "u",
    MARKER_CODE             = "c",
    MARKER_TEXT             = "t",
    MARKER_IMPORT_STD       = 'I',
    MARKER_IMPORT_LOCAL     = 'i';

function decompileExecutable(/*Bundle*/ aBundle, /*String*/ aString)
{
    var stream = new MarkedStream(aString);

    if (stream.magicNumber() !== STATIC_MAGIC_NUMBER)
        aBundle._eventDispatcher.dispatchEvent(
        {
            type:"error",
            error: new Error("Could not recognize executable code format in Bundle " + aBundle)
        });

    if (stream.version() !== "1.0")
        aBundle._eventDispatcher.dispatchEvent(
        {
            type:"error", 
            error: new Error("Could not recognize executable code format in Bundle " + aBundle)
        });

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

//            aBundle._URIMap[text] = URI;
        }

        else if (marker === MARKER_TEXT)
            fileNode.write(text);
    }
}

// Event Managament

Bundle.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

Bundle.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

Bundle.prototype.onerror = function(/*Event*/ anEvent)
{
    throw anEvent.error;
}

exports.Bundle = Bundle;

exports.CFBundle = Bundle;
