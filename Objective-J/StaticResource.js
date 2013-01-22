
var rootResources = { };

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

function countProp(x) {
    var count = 0;
    for (var k in x) {
        if (x.hasOwnProperty(k)) {
            ++count;
        }
    }
    return count;
}

StaticResource.resetRootResources = function()
{
    rootResources = {};
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

StaticResource.prototype.resolve = function()
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
            self._contents = anEvent.request.responseText();
            resolveStaticResource(self);
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

StaticResource.resolveResourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ isDirectory, /*Function*/ aCallback, /*Dictionary*/ aFilenameTranslateDictionary)
{
    aURL = makeAbsoluteURL(aURL).absoluteURL();

    resolveResourceComponents(rootResourceForAbsoluteURL(aURL), isDirectory, aURL.pathComponents(), 0, aCallback, aFilenameTranslateDictionary);
};

StaticResource.prototype.resolveResourceAtURL = function(/*CFURL|String*/ aURL, /*BOOL*/ isDirectory, /*Function*/ aCallback)
{
    StaticResource.resolveResourceAtURL(new CFURL(aURL, this.URL()).absoluteURL(), isDirectory, aCallback);
};

function resolveResourceComponents(/*StaticResource*/ aResource, /*BOOL*/ isDirectory, /*Array*/ components, /*Integer*/ index, /*Function*/ aCallback, /*Dictionry*/ aFilenameTranslateDictionary)
{
    var count = components.length;

    for (; index < count; ++index)
    {
        var name = components[index],
            child = hasOwnProperty.call(aResource._children, name) && aResource._children[name];

        // If the child doesn't exist, create and resolve it.
        if (!child)
        {
            child = new StaticResource(new CFURL(name, aResource.URL()), aResource, index + 1 < count || isDirectory , NO, aFilenameTranslateDictionary);
            child.resolve();
        }

        // If this resource is still being resolved, just wait and rerun this same method when it's ready.
        if (!child.isResolved())
            return child.addEventListener("resolve", function()
            {
                // Continue resolving once this is done.
                resolveResourceComponents(aResource, isDirectory, components, index, aCallback, aFilenameTranslateDictionary);
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
