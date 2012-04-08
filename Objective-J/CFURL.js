/*
 * CFURL.js
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
        "portNumber",
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
        parts[URI_KEYS[index]] = results[index] || NULL;

    parts.portNumber = parseInt(parts.portNumber, 10);

    if (isNaN(parts.portNumber))
        parts.portNumber = -1;

    parts.pathComponents = [];

    if (parts.path)
    {
        var split = parts.path.split("/"),
            pathComponents = parts.pathComponents,
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

#define PARTS(aURL) ((aURL)._parts || CFURLGetParts(aURL))

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

        aURL = aURL.string();
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

DISPLAY_NAME(CFURL);

CFURL.prototype.UID = function()
{
    return this._UID;
};

DISPLAY_NAME(CFURL.prototype.UID);

var URLMap = { };

CFURL.prototype.mappedURL = function()
{
    return URLMap[this.absoluteString()] || this;
};

DISPLAY_NAME(CFURL.prototype.mappedURL);

CFURL.setMappedURLForURL = function(/*CFURL*/ fromURL, /*CFURL*/ toURL)
{
    URLMap[fromURL.absoluteString()] = toURL;
};

DISPLAY_NAME(CFURL.setMappedURLForURL);

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
};

DISPLAY_NAME(CFURL.prototype.schemeAndAuthority);

CFURL.prototype.absoluteString = function()
{
    if (this._absoluteString === undefined)
        this._absoluteString = this.absoluteURL().string();

    return this._absoluteString;
};

DISPLAY_NAME(CFURL.prototype.absoluteString);

CFURL.prototype.toString = function()
{
    return this.absoluteString();
};

DISPLAY_NAME(CFURL.prototype.toString);

function resolveURL(aURL)
{
    aURL = aURL.standardizedURL();

    var baseURL = aURL.baseURL();

    if (!baseURL)
        return aURL;

    var parts = PARTS(aURL),
        resolvedParts,
        absoluteBaseURL = baseURL.absoluteURL(),
        baseParts = PARTS(absoluteBaseURL);

    if (parts.scheme || parts.authority)
        resolvedParts = parts;

    else
    {
        resolvedParts = { };

        resolvedParts.scheme = baseParts.scheme;
        resolvedParts.authority = baseParts.authority;
        resolvedParts.userInfo = baseParts.userInfo;
        resolvedParts.user = baseParts.user;
        resolvedParts.password = baseParts.password;
        resolvedParts.domain = baseParts.domain;
        resolvedParts.portNumber = baseParts.portNumber;

        resolvedParts.queryString = parts.queryString;
        resolvedParts.fragment = parts.fragment;

        var pathComponents = parts.pathComponents;

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
            if (pathComponents.length && (pathComponents[0] === ".." || pathComponents[0] === "."))
                standardizePathComponents(resolvedPathComponents, YES);

            resolvedParts.pathComponents = resolvedPathComponents;
            resolvedParts.path = pathFromPathComponents(resolvedPathComponents, pathComponents.length <= 0 || aURL.hasDirectoryPath());
        }
    }

    var resolvedString = URLStringFromParts(resolvedParts),
        resolvedURL = new CFURL(resolvedString);

    resolvedURL._parts = resolvedParts;
    resolvedURL._standardizedURL = resolvedURL;
    resolvedURL._standardizedString = resolvedString;
    resolvedURL._absoluteURL = resolvedURL;
    resolvedURL._absoluteString = resolvedString;

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

function standardizePathComponents(/*Array*/ pathComponents, /*BOOL*/ inPlace)
{
    var index = 0,
        resultIndex = 0,
        count = pathComponents.length,
        result = inPlace ? pathComponents : [],
        startsWithPeriod = NO;

    for (; index < count; ++index)
    {
        var component = pathComponents[index];

        if (component === "")
             continue;

        if (component === ".")
        {
            startsWithPeriod = resultIndex === 0;

            continue;
        }

        if (component !== ".." || resultIndex === 0 || result[resultIndex - 1] === "..")
        {
            result[resultIndex] = component;

            resultIndex++;

            continue;
        }

        if (resultIndex > 0 && result[resultIndex - 1] !== "/")
            --resultIndex;
    }

    if (startsWithPeriod && resultIndex === 0)
        result[resultIndex++] = ".";

    result.length = resultIndex;

    return result;
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
};

DISPLAY_NAME(CFURL.prototype.absoluteURL);

CFURL.prototype.standardizedURL = function()
{
    if (this._standardizedURL === undefined)
    {
        var parts = PARTS(this),
            pathComponents = parts.pathComponents,
            standardizedPathComponents = standardizePathComponents(pathComponents, NO);

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
            standardizedURL._standardizedURL = standardizedURL;

            this._standardizedURL = standardizedURL;
        }
    }

    return this._standardizedURL;
};

DISPLAY_NAME(CFURL.prototype.standardizedURL);

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
};

DISPLAY_NAME(CFURL.prototype.string);

CFURL.prototype.authority = function()
{
    var authority = PARTS(this).authority;

    if (authority)
        return authority;

    var baseURL = this.baseURL();

    return baseURL && baseURL.authority() || "";
};

DISPLAY_NAME(CFURL.prototype.authority);

CFURL.prototype.hasDirectoryPath = function()
{
    var hasDirectoryPath = this._hasDirectoryPath;

    if (hasDirectoryPath === undefined)
    {
        var path = this.path();

        if (!path)
            return NO;

        if (path.charAt(path.length - 1) === "/")
            return YES;

        var lastPathComponent = this.lastPathComponent();

        hasDirectoryPath = lastPathComponent === "." || lastPathComponent === "..";

        this._hasDirectoryPath = hasDirectoryPath;
    }

    return hasDirectoryPath;
};

DISPLAY_NAME(CFURL.prototype.hasDirectoryPath);

CFURL.prototype.hostName = function()
{
    return this.authority();
};

DISPLAY_NAME(CFURL.prototype.hostName);

CFURL.prototype.fragment = function()
{
    return PARTS(this).fragment;
};

DISPLAY_NAME(CFURL.prototype.fragment);

CFURL.prototype.lastPathComponent = function()
{
    if (this._lastPathComponent === undefined)
    {
        var pathComponents = this.pathComponents(),
            pathComponentCount = pathComponents.length;

        if (!pathComponentCount)
            this._lastPathComponent = "";

        else
            this._lastPathComponent = pathComponents[pathComponentCount - 1];
    }

    return this._lastPathComponent;
};

DISPLAY_NAME(CFURL.prototype.lastPathComponent);

CFURL.prototype.path = function()
{
    return PARTS(this).path;
};

DISPLAY_NAME(CFURL.prototype.path);

CFURL.prototype.pathComponents = function()
{
    return PARTS(this).pathComponents;
};

DISPLAY_NAME(CFURL.prototype.pathComponents);

CFURL.prototype.pathExtension = function()
{
    var lastPathComponent = this.lastPathComponent();

    if (!lastPathComponent)
        return NULL;

    lastPathComponent = lastPathComponent.replace(/^\.*/, '');

    var index = lastPathComponent.lastIndexOf(".");

    return index <= 0 ? "" : lastPathComponent.substring(index + 1);
};

DISPLAY_NAME(CFURL.prototype.pathExtension);

CFURL.prototype.queryString = function()
{
    return PARTS(this).queryString;
};

DISPLAY_NAME(CFURL.prototype.queryString);

CFURL.prototype.scheme = function()
{
    var scheme = this._scheme;

    if (scheme === undefined)
    {
        scheme = PARTS(this).scheme;

        if (!scheme)
        {
            var baseURL = this.baseURL();

            scheme = baseURL && baseURL.scheme();
        }

        this._scheme = scheme;
    }

    return scheme;
};

DISPLAY_NAME(CFURL.prototype.scheme);

CFURL.prototype.user = function()
{
    return PARTS(this).user;
};

DISPLAY_NAME(CFURL.prototype.user);

CFURL.prototype.password = function()
{
    return PARTS(this).password;
};

DISPLAY_NAME(CFURL.prototype.password);

CFURL.prototype.portNumber = function()
{
    return PARTS(this).portNumber;
};

DISPLAY_NAME(CFURL.prototype.portNumber);

CFURL.prototype.domain = function()
{
    return PARTS(this).domain;
};

DISPLAY_NAME(CFURL.prototype.domain);

CFURL.prototype.baseURL = function()
{
    return this._baseURL;
};

DISPLAY_NAME(CFURL.prototype.baseURL);

CFURL.prototype.asDirectoryPathURL = function()
{
    if (this.hasDirectoryPath())
        return this;

    var lastPathComponent = this.lastPathComponent();

    // We do this because on Windows the path may start with C: and be
    // misinterpreted as a scheme.
    if (lastPathComponent !== "/")
        lastPathComponent = "./" + lastPathComponent;

    return new CFURL(lastPathComponent + "/", this);
};

DISPLAY_NAME(CFURL.prototype.asDirectoryPathURL);

function CFURLGetResourcePropertiesForKeys(/*CFURL*/ aURL)
{
    if (!aURL._resourcePropertiesForKeys)
        aURL._resourcePropertiesForKeys = new CFMutableDictionary();

    return aURL._resourcePropertiesForKeys;
}

CFURL.prototype.resourcePropertyForKey = function(/*String*/ aKey)
{
    return CFURLGetResourcePropertiesForKeys(this).valueForKey(aKey);
};

DISPLAY_NAME(CFURL.prototype.resourcePropertyForKey);

CFURL.prototype.setResourcePropertyForKey = function(/*String*/ aKey, /*id*/ aValue)
{
    CFURLGetResourcePropertiesForKeys(this).setValueForKey(aKey, aValue);
};

DISPLAY_NAME(CFURL.prototype.setResourcePropertyForKey);

CFURL.prototype.staticResourceData = function()
{
    var data = new CFMutableData();

    data.setRawString(StaticResource.resourceAtURL(this).contents());

    return data;
};

DISPLAY_NAME(CFURL.prototype.staticResourceData);
