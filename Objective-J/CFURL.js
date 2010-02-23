// Based on the regex in RFC2396 Appendix B.
var URI_RE = /^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;

GLOBAL(CFURL) = function(/*CFURL|String*/ aURLOrString, /*CFURL*/ aBaseURL)
{
    if (aURLOrString instanceof CFURL)
        return new CFURL(aURLOrString.string(), aBaseURL);

    this._string = aURLOrString;

    var result = (aURLOrString || "").match(URI_RE);

    this._baseURL = aBaseURL;

    this._scheme = result[2] || NULL;
    this._authority = result[4] || NULL;
    this._path = result[5] || NULL;
    this._queryString = result[7] || NULL;
    this._fragment = result[9] || NULL;
}

CFURL.prototype.absoluteString = function()
{
    return this.absoluteURL().string();
}

CFURL.prototype.toString = function()
{
    return this.absoluteString();
}

CFURL.prototype.absoluteURL = function()
{
    if (this._absoluteURL === undefined)
    {
        var baseURL = this._baseURL;

        this._absoluteURL = baseURL ? resolve(baseURL.string(), this.string()) : this;
    }

    return this._absoluteURL;
}

CFURL.prototype.string = function()
{
    return this._string;
}

CFURL.prototype.authority = function()
{
    return this._authority;
}

CFURL.prototype.hasDirectoryPath = function()
{
    var path = this._path;

    if (!path)
        return NO;

    return path.charAt(path.length - 1) === "/";
}

CFURL.prototype.hostName = function()
{
    return this._authority;
}

CFURL.prototype.fragment = function()
{
    return this._fragment;
}

CFURL.prototype.lastPathComponent = function()
{
    var path = this.path();

    if (!path)
        return "";

    // Root is a special case.
    if (path === "/")
        return "/";

    // Remove the trailing slash, since "path/directory/" and "path/directory" should both return a.
    var components = path.replace(/\/$/g, "").split("/");

    return components[components.length - 1];
}

CFURL.prototype.path = function()
{
    return this._path;
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
    return this._queryString;
}

CFURL.prototype.scheme = function()
{
    return this._scheme;
}

CFURL.prototype.baseURL = function()
{
    return this._baseURL;
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
