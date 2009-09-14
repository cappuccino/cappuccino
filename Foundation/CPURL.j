
@import <Foundation/CPObject.j>

CPURLNameKey                        = @"CPURLNameKey";
CPURLLocalizedNameKey               = @"CPURLLocalizedNameKey";
CPURLIsRegularFileKey               = @"CPURLIsRegularFileKey";
CPURLIsDirectoryKey                 = @"CPURLIsDirectoryKey";
CPURLIsSymbolicLinkKey              = @"CPURLIsSymbolicLinkKey";
CPURLIsVolumeKey                    = @"CPURLIsVolumeKey";
CPURLIsPackageKey                   = @"CPURLIsPackageKey";
CPURLIsSystemImmutableKey           = @"CPURLIsSystemImmutableKey";
CPURLIsUserImmutableKey             = @"CPURLIsUserImmutableKey";
CPURLIsHiddenKey                    = @"CPURLIsHiddenKey";
CPURLHasHiddenExtensionKey          = @"CPURLHasHiddenExtensionKey";
CPURLCreationDateKey                = @"CPURLCreationDateKey";
CPURLContentAccessDateKey           = @"CPURLContentAccessDateKey";
CPURLContentModificationDateKey     = @"CPURLContentModificationDateKey";
CPURLAttributeModificationDateKey   = @"CPURLAttributeModificationDateKey";
CPURLLinkCountKey                   = @"CPURLLinkCountKey";
CPURLParentDirectoryURLKey          = @"CPURLParentDirectoryURLKey";
CPURLVolumeURLKey                   = @"CPURLTypeIdentifierKey";
CPURLTypeIdentifierKey              = @"CPURLTypeIdentifierKey";
CPURLLocalizedTypeDescriptionKey    = @"CPURLLocalizedTypeDescriptionKey";
CPURLLabelNumberKey                 = @"CPURLLabelNumberKey";
CPURLLabelColorKey                  = @"CPURLLabelColorKey";
CPURLLocalizedLabelKey              = @"CPURLLocalizedLabelKey";
CPURLEffectiveIconKey               = @"CPURLEffectiveIconKey";
CPURLCustomIconKey                  = @"CPURLCustomIconKey";

@implementation CPURL : CPObject
{
    CPURL       _base @accessors(readonly, property=baseURL);
    CPString    _relative @accessors(readonly, property=relativeString);

    CPDictionary    _resourceValues;
}

- (id)initWithScheme:(CPString)scheme host:(CPString)host path:(CPString)path
{
    var uri = new URI();
    uri.scheme = scheme;
    uri.authority = host;
    uri.path = path;
    [self initWithString:uri.toString()];
}

- (id)initWithString:(CPString)URLString
{
    return [self initWithString:URLString relativeToURL:nil];
}

+ (id)URLWithString:(CPString)URLString
{
    return [[self alloc] initWithString:URLString];
}

- (id)initWithString:(CPString)URLString relativeToURL:(CPURL)baseURL
{
    if (!URI_RE.test(URLString))
        return nil;
    
    if (self)
    {
        _base = baseURL;
        _relative = URLString;
        _resourceValues = [CPDictionary dictionary];
    }

    return self;
}

+ (id)URLWithString:(CPString)URLString relativeToURL:(CPURL)baseURL
{
    return [[self alloc] initWithString:URLString relativeToURL:baseURL];
}

- (CPURL)absoluteURL
{
    var absStr = [self absoluteString];
    
    if (absStr !== _relative)
        return [[CPURL alloc] initWithString:absStr];
    
    return self;
}

- (CPString)absoluteString
{
    return resolve([_base absoluteString] || "", _relative);
}

// if absolute, returns same as absoluteString
- (CPString)relativeString
{
    return _relative;
}

- (CPString)path
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).path || nil) : nil;
}

// if absolute, returns the same as path
- (CPString)relativePath
{
    return URI_RE.test(_relative) ? (parse(_relative).path || nil) : nil;
}


- (CPString)scheme
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).protocol || nil) : nil;
}

- (CPString)user
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).user || nil) : nil;
}

- (CPString)password
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).password || nil) : nil;
}

- (CPString)host
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).domain || nil) : nil;
}

- (CPString)port
{
    var str = [self absoluteString];
    if (URI_RE.test(str)) {
        var port = parse(str).port;
        if (port)
            return parseInt(port, 10);
    }
    return nil;
}

- (CPString)parameterString
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).query || nil) : nil;
}

- (CPString)fragment
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).anchor || nil) : nil;
}

- (BOOL)isEqual:(id)anObject
{
    // Is checking if baseURL isEqual correct? Does "identical" mean same object or equivalent values?
    return [self relativeString] === [anObject relativeString] &&
        ([self baseURL] === [anObject baseURL] || [[self baseURL] isEqual:[anObject baseURL]]);
}

- (CPString)lastPathComponent
{
    var path = [self path];
    return path ? path.split("/").pop() : nil;
}

- (CPString)pathExtension
{
    var path = [self path],
        ext = path.match(/\.(\w+)$/);
    return ext ? ext[1] : "";
}

- (CPURL)standardizedURL
{
    return [CPURL URLWithString:format(parse(_relative)) relativeToURL:_base];
}

- (BOOL)isFileURL
{
    return [self scheme] === "file";
}

- (CPString)description
{
    return [self absoluteString];
}

- (id)resourceValueForKey:(CPString)aKey
{
    return [_resourceValues objectForKey:aKey];
}

- (id)setResourceValue:(id)anObject forKey:(CPString)aKey
{
    [_resourceValues setObject:anObject forKey:aKey];
}

@end

@implementation CPURL (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    _base = [aCoder decodeObjectForKey:"CPURLBaseKey"];
    _relative = [aCoder decodeObjectForKey:"CPURLRelativeKey"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_base forKey:"CPURLBaseKey"];
    [aCoder encodeObject:_relative forKey:"CPURLRelativeKey"];
}

@end

// original code: http://code.google.com/p/js-uri/

// Based on the regex in RFC2396 Appendix B.
var URI_RE = /^(?:([^:\/?\#]+):)?(?:\/\/([^\/?\#]*))?([^?\#]*)(?:\?([^\#]*))?(?:\#(.*))?/;

/**
 * Uniform Resource Identifier (URI) - RFC3986
 */
var URI = function(str) {
    if (!str) str = "";
    var result = str.match(URI_RE);
    this.scheme = result[1] || null;
    this.authority = result[2] || null;
    this.path = result[3] || null;
    this.query = result[4] || null;
    this.fragment = result[5] || null;
}

/**
 * Convert the URI to a String.
 */
URI.prototype.toString = function () {
    var str = "";
 
    if (this.scheme)
        str += this.scheme + ":";

    if (this.authority)
        str += "//" + this.authority;

    if (this.path)
        str += this.path;

    if (this.query)
        str += "?" + this.query;

    if (this.fragment)
        str += "#" + this.fragment;
 
    return str;
}

var parse = function(uri) {
    return new URI(uri);
}

var unescape =  function(str, plus) {
    return decodeURI(str).replace(/\+/g, " ");
}

var unescapeComponent = function(str, plus) {
    return decodeURIComponent(str).replace(/\+/g, " ");
}

// from Chiron's HTTP module:

/**** keys
    members of a parsed URI object.
*/
var keys = [
    "url",
    "protocol",
    "authorityRoot",
    "authority",
        "userInfo",
            "user",
            "password",
        "domain",
            "domains",
        "port",
    "path",
        "root",
        "directory",
            "directories",
        "file",
    "query",
    "anchor"
];

/**** expressionKeys
    members of a parsed URI object that you get
    from evaluting the strict regular expression.
*/
var expressionKeys = [
    "url",
    "protocol",
    "authorityRoot",
    "authority",
        "userInfo",
            "user",
            "password",
        "domain",
        "port",
    "path",
        "root",
        "directory",
        "file",
    "query",
    "anchor"
];

/**** strictExpression
*/
var strictExpression = new RegExp( /* url */
    "^" +
    "(?:" +
        "([^:/?#]+):" + /* protocol */
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
    "(" + /* path */
        "(/?)" + /* root */
        "((?:[^?#/]*/)*)" +
        "([^?#]*)" + /* file */
    ")" +
    "(?:\\?([^#]*))?" + /* query */
    "(?:#(.*))?" /*anchor */
);

/**** Parser
    returns a URI parser function given
    a regular expression that renders 
    `expressionKeys` and returns an `Object`
    mapping all `keys` to values.
*/
var Parser = function (expression) {
    return function (url) {
        if (typeof url == "undefined")
            throw new Error("HttpError: URL is undefined");
        if (typeof url != "string") return new Object(url);

        var items = {};
        var parts = expression.exec(url);

        for (var i = 0; i < parts.length; i++) {
            items[expressionKeys[i]] = parts[i] ? parts[i] : "";
        }

        items.root = (items.root || items.authorityRoot) ? '/' : '';

        items.directories = items.directory.split("/");
        if (items.directories[items.directories.length - 1] == "") {
            items.directories.pop();
        }

        /* normalize */
        var directories = [];
        for (var i = 0; i < items.directories.length; i++) {
            var directory = items.directories[i];
            if (directory == '.') {
            } else if (directory == '..') {
                if (directories.length && directories[directories.length - 1] != '..')
                    directories.pop();
                else
                    directories.push('..');
            } else {
                directories.push(directory);
            }
        }
        items.directories = directories;

        items.domains = items.domain.split(".");

        return items;
    };
};

/**** parse
    a strict URI parser.
*/
var parse = Parser(strictExpression);

/**** format
    accepts a parsed URI object and returns
    the corresponding string.
*/
var format = function (object) {
    if (typeof(object) == 'undefined')
        throw new Error("UrlError: URL undefined for urls#format");
    if (object instanceof String || typeof(object) == 'string')
        return object;
    var domain =
        object.domains ?
        object.domains.join(".") :
        object.domain;
    var userInfo = (
            object.user ||
            object.password 
        ) ?
        (
            (object.user || "") + 
            (object.password ? ":" + object.password : "") 
        ) :
        object.userInfo;
    var authority = (
            userInfo ||
            domain ||
            object.port
        ) ? (
            (userInfo ? userInfo + "@" : "") +
            (domain || "") + 
            (object.port ? ":" + object.port : "")
        ) :
        object.authority;
    var directory =
        object.directories ?
        object.directories.join("/") :
        object.directory;
    var path =
        directory || object.file ?
        (
            (directory ? directory + "/" : "") +
            (object.file || "")
        ) :
        object.path;
    return (
        (object.protocol ? object.protocol + ":" : "") +
        (authority ? "//" + authority : "") +
        (object.root || (authority && path) ? "/" : "") +
        (path ? path : "") +
        (object.query ? "?" + object.query : "") +
        (object.anchor ? "#" + object.anchor : "")
    ) || object.url || "";
};

/**** resolveObject
    returns an object representing a URL resolved from
    a relative location and a source location.
*/
var resolveObject = function (source, relative) {
    if (!source) 
        return relative;

    source = parse(source);
    relative = parse(relative);

    if (relative.url == "")
        return source;

    delete source.url;
    delete source.authority;
    delete source.domain;
    delete source.userInfo;
    delete source.path;
    delete source.directory;

    if (
        relative.protocol && relative.protocol != source.protocol ||
        relative.authority && relative.authority != source.authority
    ) {
        source = relative;
    } else {
        if (relative.root) {
            source.directories = relative.directories;
        } else {

            var directories = relative.directories;
            for (var i = 0; i < directories.length; i++) {
                var directory = directories[i];
                if (directory == ".") {
                } else if (directory == "..") {
                    if (source.directories.length) {
                        source.directories.pop();
                    } else {
                        source.directories.push('..');
                    }
                } else {
                    source.directories.push(directory);
                }
            }

            if (relative.file == ".") {
                relative.file = "";
            } else if (relative.file == "..") {
                source.directories.pop();
                relative.file = "";
            }
        }
    }

    if (relative.root)
        source.root = relative.root;
    if (relative.protcol)
        source.protocol = relative.protocol;
    if (!(!relative.path && relative.anchor))
        source.file = relative.file;
    source.query = relative.query;
    source.anchor = relative.anchor;

    return source;
};

/**** relativeObject
    returns an object representing a relative URL to
    a given target URL from a source URL.
*/
var relativeObject = function (source, target) {
    target = parse(target);
    source = parse(source);

    delete target.url;

    if (
        target.protocol == source.protocol &&
        target.authority == source.authority
    ) {
        delete target.protocol;
        delete target.authority;
        delete target.userInfo;
        delete target.user;
        delete target.password;
        delete target.domain;
        delete target.domains;
        delete target.port;
        if (
            !!target.root == !!source.root && !(
                target.root &&
                target.directories[0] != source.directories[0]
            )
        ) {
            delete target.path;
            delete target.root;
            delete target.directory;
            while (
                source.directories.length &&
                target.directories.length &&
                target.directories[0] == source.directories[0]
            ) {
                target.directories.shift();
                source.directories.shift();
            }
            while (source.directories.length) {
                source.directories.shift();
                target.directories.unshift('..');
            }

            if (!target.root && !target.directories.length && !target.file && source.file)
                target.directories.push('.');

            if (source.file == target.file)
                delete target.file;
            if (source.query == target.query)
                delete target.query;
            if (source.anchor == target.anchor)
                delete target.anchor;
        }
    }

    return target;
};

/**** resolve
    returns a URL resovled to a relative URL from a source URL.
*/
var resolve = function (source, relative) {
    return format(resolveObject(source, relative));
};

/**** relative
    returns a relative URL to a target from a source.
*/
var relative = function (source, target) {
    return format(relativeObject(source, target));
};
