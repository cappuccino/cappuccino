
var CFURLsForCachedUIDs,
    CFURLPartsForURLStrings,
    CFURLCachingEnableCount = 0;

function enableCFURLCaching()
{
    if (++CFURLCachingEnableCount !== 1)
        return;

    CFURLsForCachedUIDs = { };
    CFURLPartsForURLStrings = { };
}

function disableCFURLCaching()
{
    CFURLCachingEnableCount = MAX(CFURLCachingEnableCount - 1, 0);

    if (CFURLCachingEnableCount !== 0)
        return;

    delete CFURLsForCachedUIDs;
    delete CFURLPartsForURLStrings;
}

var URL_RE = new RegExp( /* url */
    "^" +
    "(?:" +
        "([^:/?#]+):" + /* scheme */
    ")?" +
    "(?:" +
        "(//)" + /* authorityRoot */
        "(" + /* authority */
            "(?:" +
                "(" + /* userInfo */
                    "([^:@]*)" + /* user */
                    ":?" +
                    "([^:@]*)" + /* password */
                ")?" +
                "@" +
            ")?" +
            "([^:/?#]*)" + /* domain */
            "(?::(\\d*))?" + /* port */
        ")" +
    ")?" +
    "([^?#]*)" + /*path*/
    "(?:\\?([^#]*))?" + /* queryString */
    "(?:#(.*))?" /*fragment */
);

var URI_KEYS =
[
    "url",
    "scheme",
    "authorityRoot",
    "authority",
        "userInfo",
            "user",
            "password",
        "domain",
        "port",
    "path",
    "queryString",
    "fragment"
];

function CFURLGetParts(/*CFURL*/ aURL)
{
    if (aURL._parts)
        return aURL._parts;

    var URLString = aURL.string(),
        isMHTMLURL = URLString.match(/^mhtml:/);

    if (isMHTMLURL)
        URLString = URLString.substr("mhtml:".length);

    if (CFURLCachingEnableCount > 0 && hasOwnProperty.call(CFURLPartsForURLStrings, URLString))
    {
        aURL._parts = CFURLPartsForURLStrings[URLString];
        return aURL._parts;
    }

    aURL._parts = { };

    var parts = aURL._parts,
        results = URL_RE.exec(URLString),
        index = results.length;

    while (index--)
        parts[URI_KEYS[index]] = results[index] || "";

    parts.pathComponents = [];

    if (parts.path)
    {
        var split = parts.path.split("/"),
            pathComponents = parts.pathComponents;
            index = 0,
            count = split.length;
    
        for (; index < count; ++index)
        {
            var component = split[index];
    
            if (component)
                pathComponents.push(component);
    
            else if (index === 0)
                pathComponents.push("/");
        }
    
        parts.pathComponents = pathComponents;
    }

    if (isMHTMLURL)
    {
        parts.url = "mhtml:" + parts.url;
        parts.scheme = "mhtml:" + parts.scheme;
    }

    if (CFURLCachingEnableCount > 0)
        CFURLPartsForURLStrings[URLString] = parts;

    return parts;
}

GLOBAL(CFURL) = function(/*CFURL|String*/ aURL, /*CFURL*/ aBaseURL)
{
    aURL = aURL || "";

    if (aURL instanceof CFURL)
    {
        if (!aBaseURL)
            return aURL;

        var existingBaseURL = aURL.baseURL();

        if (existingBaseURL)
            aBaseURL = new CFURL(existingBaseURL.absoluteURL(), aBaseURL);

        return new CFURL(aURL.string(), aBaseURL);
    }

    // Use the cache if it's enabled.
    if (CFURLCachingEnableCount > 0)
    {
        var cacheUID = aURL + " " + (aBaseURL && aBaseURL.UID() || "");

        if (hasOwnProperty.call(CFURLsForCachedUIDs, cacheUID))
            return CFURLsForCachedUIDs[cacheUID];

        CFURLsForCachedUIDs[cacheUID] = this;
    }

    if (aURL.match(/^data:/))
    {
        var parts = { },
            index = URI_KEYS.length;

        while (index--)
            parts[URI_KEYS[index]] = "";

        parts.url = aURL;
        parts.scheme = "data";
        parts.pathComponents = [];

        this._parts = parts;
        this._standardizedURL = this;
        this._absoluteURL = this;
    }

    this._UID = objj_generateObjectUID();

    this._string = aURL;
    this._baseURL = aBaseURL;
}

CFURL.displayName = "CFURL";

var URLMap = { };

CFURL.prototype.UID = function()
{
    return this._UID;
}

CFURL.prototype.mappedURL = function()
{
    return URLMap[this.absoluteString()] || this;
}

CFURL.setMappedURLForURL = function(/*CFURL*/ fromURL, /*CFURL*/ toURL)
{
    URLMap[fromURL.absoluteString()] = toURL;
}

CFURL.prototype.schemeAndAuthority = function()
{
    var string = "",
        scheme = this.scheme();

    if (scheme)
        string += scheme + ":";

    var authority = this.authority();

    if (authority)
        string += "//" + authority;

    return string;
}

CFURL.prototype.absoluteString = function()
{
    return this.absoluteURL().string();
}

CFURL.prototype.toString = function()
{
    return this.absoluteString();
}

function resolveURL(aURL)
{
    aURL = aURL.standardizedURL();

    var baseURL = aURL.baseURL();

    if (!baseURL)
        return aURL;

    var parts = CFURLGetParts(aURL),
        resolvedParts,
        baseParts = CFURLGetParts(baseURL.absoluteURL());

    if (parts.scheme || parts.authority)
        resolvedParts = parts;
    
    else
    {
        resolvedParts = { };

        resolvedParts.scheme = baseParts.scheme;
        resolvedParts.authority = baseParts.authority;
        resolvedParts.queryString = parts.queryString;
        resolvedParts.fragment = parts.fragment;

        var pathComponents = parts.pathComponents

        if (pathComponents.length && pathComponents[0] === "/")
        {
            resolvedParts.path = parts.path;
            resolvedParts.pathComponents = pathComponents;
        }
    
        else
        {
            var basePathComponents = baseParts.pathComponents,
                resolvedPathComponents = basePathComponents.concat(pathComponents);

            // If baseURL is a file, then get rid of that file from the path components.
            if (!baseURL.hasDirectoryPath() && basePathComponents.length)
                resolvedPathComponents.splice(basePathComponents.length - 1, 1);

            // If this doesn't start with a "..", then we're simply appending to already standardized paths.
            if (pathComponents.length && pathComponents[0] === "..")
                standardizePathComponents(resolvedPathComponents);

            resolvedParts.pathComponents = resolvedPathComponents;
            resolvedParts.path = pathFromPathComponents(resolvedPathComponents, pathComponents.length <= 0 || aURL.hasDirectoryPath());
        }
    }

    var resolvedString = URLStringFromParts(resolvedParts),
        resolvedURL = new CFURL(resolvedString);

    resolvedURL._parts = resolvedParts;
    resolvedURL._standardizedURL = resolvedURL;
    resolvedURL._absoluteURL = resolvedURL;

    return resolvedURL;
}

function pathFromPathComponents(/*Array*/ pathComponents, /*BOOL*/ isDirectoryPath)
{
    var path = pathComponents.join("/");

    if (path.length && path.charAt(0) === "/")
        path = path.substr(1);

    if (isDirectoryPath)
        path += "/";

    return path;
}

function standardizePathComponents(/*Array*/ pathComponents)
{
    var index = 0,
        resultIndex = 0,
        count = pathComponents.length;

    for (; index < count; ++index)
    {
        var component = pathComponents[index];

        if (component === "" || component === ".")
             continue;

        if (component !== ".." || resultIndex === 0 || pathComponents[resultIndex - 1] === "..")
        {
            //if (resultIndex !== index)
                pathComponents[resultIndex] = component;

            resultIndex++;

            continue;
        }

        if (resultIndex > 0 && pathComponents[resultIndex - 1] !== "/")
            --resultIndex;
    }

    pathComponents.length = resultIndex;
}

function URLStringFromParts(/*Object*/ parts)
{
    var string = "",
        scheme = parts.scheme;

    if (scheme)
        string += scheme + ":";

    var authority = parts.authority;

    if (authority)
        string += "//" + authority;

    string += parts.path;

    var queryString = parts.queryString;

    if (queryString)
        string += "?" + queryString;

    var fragment = parts.fragment;

    if (fragment)
        string += "#" + fragment;

    return string;
}

CFURL.prototype.absoluteURL = function()
{
    if (this._absoluteURL === undefined)
        this._absoluteURL = resolveURL(this);

    return this._absoluteURL;
}

CFURL.prototype.standardizedURL = function()
{
    if (this._standardizedURL === undefined)
    {
        var parts = CFURLGetParts(this),
            pathComponents = parts.pathComponents,
            standardizedPathComponents = pathComponents.slice();

        standardizePathComponents(standardizedPathComponents);

        var standardizedPath = pathFromPathComponents(standardizedPathComponents, this.hasDirectoryPath());

        if (parts.path === standardizedPath)
            this._standardizedURL = this;

        else
        {
            var standardizedParts = CFURLPartsCreateCopy(parts);

            standardizedParts.pathComponents = standardizedPathComponents;
            standardizedParts.path = standardizedPath;

            var standardizedURL = new CFURL(URLStringFromParts(standardizedParts), this.baseURL());

            standardizedURL._parts = standardizedParts;
            standardizedURL._standardizedParts = standardizedURL;

            this._standardizedURL = standardizedURL;
        }
    }

    return this._standardizedURL;
}

function CFURLPartsCreateCopy(parts)
{
    var copiedParts = { },
        count = URI_KEYS.length;
    
    while (count--)
    {
        var partName = URI_KEYS[count];

        copiedParts[partName] = parts[partName];
    }

    return copiedParts;
}

CFURL.prototype.string = function()
{
    return this._string;
}

CFURL.prototype.authority = function()
{
    var authority = CFURLGetParts(this).authority;

    if (authority)
        return authority;

    var baseURL = this.baseURL();

    return baseURL && baseURL.authority() || "";
}

CFURL.prototype.hasDirectoryPath = function()
{
    var path = this.path();

    if (!path)
        return NO;

    if (path.charAt(path.length - 1) === "/")
        return YES;

    var lastPathComponent = this.lastPathComponent();

    return lastPathComponent === "." || lastPathComponent === "..";
}

CFURL.prototype.hostName = function()
{
    return this.authority();
}

CFURL.prototype.fragment = function()
{
    return CFURLGetParts(this).fragment;
}

CFURL.prototype.lastPathComponent = function()
{
    var pathComponents = this.pathComponents(),
        pathComponentCount = pathComponents.length;

    if (!pathComponentCount)
        return "";

    return pathComponents[pathComponentCount - 1];
}

CFURL.prototype.path = function()
{
    return CFURLGetParts(this).path;
}

CFURL.prototype.pathComponents = function()
{
    return CFURLGetParts(this).pathComponents;
}

CFURL.prototype.pathExtension = function()
{
    var lastPathComponent = this.lastPathComponent();

    if (!lastPathComponent)
        return NULL;

    lastPathComponent = lastPathComponent.replace(/^\.*/, '');

    var index = lastPathComponent.lastIndexOf(".");

    return index <= 0 ? "" : lastPathComponent.substring(index + 1);
}

CFURL.prototype.queryString = function()
{
    return CFURLGetParts(this).queryString;
}

CFURL.prototype.scheme = function()
{
    var scheme = CFURLGetParts(this).scheme;

    if (scheme)
        return scheme;

    var baseURL = this.baseURL();

    return baseURL && baseURL.scheme() || "";
}

CFURL.prototype.user = function()
{
    return CFURLGetParts(this).user;
}

CFURL.prototype.password = function()
{
    return CFURLGetParts(this).password;
}

CFURL.prototype.port = function()
{
    return CFURLGetParts(this).port;
}

CFURL.prototype.domain = function()
{
    return CFURLGetParts(this).domain;
}

CFURL.prototype.baseURL = function()
{
    return this._baseURL;
}

CFURL.prototype.asDirectoryPathURL = function()
{
    if (this.hasDirectoryPath())
        return this;

    return new CFURL(this.lastPathComponent() + "/", this);
}

function CFURLGetResourcePropertiesForKeys(/*CFURL*/ aURL)
{
    if (!aURL._resourcePropertiesForKeys)
        aURL._resourcePropertiesForKeys = new CFMutableDictionary();

    return aURL._resourcePropertiesForKeys;
}

CFURL.prototype.resourcePropertyForKey = function(/*String*/ aKey)
{
    return CFURLGetResourcePropertiesForKeys(this).valueForKey(aKey);
}

CFURL.prototype.setResourcePropertyForKey = function(/*String*/ aKey, /*id*/ aValue)
{
    CFURLGetResourcePropertiesForKeys(this).setValueForKey(aKey, aValue);
}

CFURL.prototype.staticResourceData = function()
{
    var data = new CFMutableData();

    data.setRawString(StaticResource.resourceAtURL(this).contents());

    return data;
}
