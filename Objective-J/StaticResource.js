
var FILE =
#ifdef COMMONJS
require("file");
#else
{
    absolute: function(/*String*/ aPath)
    {
        aPath = FILE.normal(aPath);

        if (FILE.isAbsolute(aPath))
            return aPath;

        return FILE.join(FILE.cwd(), aPath);
    },

    basename: function(/*String*/ aPath)
    {
        var components = FILE.split(FILE.normal(aPath));

        return components[components.length - 1];
    },

    extension: function(/*String*/ aPath)
    {
        aPath = FILE.basename(aPath);
        aPath = aPath.replace(/^\.*/, '');
        var index = aPath.lastIndexOf(".");
        return index <= 0 ? "" : aPath.substring(index);
    },

    cwd: function()
    {
        return FILE._cwd;
    },

    normal: function(/*String*/ aPath)
    {
        if (!aPath)
            return "";

        var components = aPath.split("/"),
            results = [],
            index = 0,
            count = components.length,
            isRoot = aPath.charAt(0) === "/";

        for (; index < count; ++index)
        {
            var component = components[index];

            // These simply remain in the current directory.
            if (component === "" || component === ".")
                continue;

            if (component !== "..")
            {
                results.push(component);
                continue;
            }

            var resultsCount = results.length;

            // If we have a valid previous component, "climb" it.
            if (resultsCount > 0 && results[resultsCount - 1] !== "..")
                results.pop();

            // If this isn't a root listing, and we are preceded by only ..'s, or
            // nothing at all, then add it since it makes sense for relative paths.
            else if (!isRoot && resultsCount === 0 || results[resultsCount - 1] === "..")
                results.push(component);
        }

        return (isRoot ? "/" : "") + results.join("/");
    },

    dirname: function(/*String*/ aPath)
    {
        var aPath = FILE.normal(aPath),
            components = FILE.split(aPath);

        if (components.length === 2)
            components.unshift("");

        return FILE.join.apply(FILE, components.slice(0, components.length - 1));
    },

    isAbsolute: function(/*String*/ aPath)
    {
        return aPath.charAt(0) === "/";
    },

    join: function()
    {
        if (arguments.length === 1 && arguments[0] === "")
            return "/";

        return FILE.normal(Array.prototype.join.call(arguments, "/"));
    },
    
    split: function(/*String*/ aPath)
    {
        return FILE.normal(aPath).split("/");
    }
}

var DOMBaseElement = document.getElementsByTagName("base")[0];

if (DOMBaseElement)
    FILE._cwd = FILE.dirname(DOMBaseElement.getAttribute("href"));
else
    FILE._cwd = FILE.dirname(window.location.pathname);

#endif

StaticResource.FileType             = 0;
StaticResource.DirectoryType        = 1;
StaticResource.NotFoundType         = 2;

function StaticResource(/*String*/ aName, /*StaticResource*/ aParent, /*Type*/ aType, /*BOOL*/ isResolved)
{
    this._parent = aParent;
    this._eventDispatcher = new EventDispatcher(this);

    this._name = aName;
    this._isResolved = !!isResolved;
    this._path = FILE.join(aParent ? aParent.path() : "", aName);

    this._type = aType;

    if (aParent)
        aParent._children[aName] = this;

    if (aType === StaticResource.DirectoryType)
        this._children = { };

    else if (aType === StaticResource.FileType)
        this._contents = "";
}

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
    if (this.type() === StaticResource.DirectoryType)
    {
        var bundle = new CFBundle(this.path());

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
            self._type = StaticResource.NotFoundType;
            resolveStaticResource(self);
        }

        new FileRequest(this.path(), onsuccess, onfailure);
    }
}

StaticResource.prototype.name = function()
{
    return this._name;
}

StaticResource.prototype.path = function()
{
    return this._path;
}

StaticResource.prototype.contents = function()
{
    return this._contents;
}

StaticResource.prototype.children = function()
{
    return this._children;
}

StaticResource.prototype.type = function()
{
    return this._type;
}

StaticResource.prototype.parent = function()
{
    return this._parent;
}

StaticResource.prototype.isResolved = function()
{
    return this._isResolved;
}

StaticResource.prototype.write = function(/*String*/ aString)
{
    this._contents += aString;
}

StaticResource.prototype.resolveSubPath = function(/*String*/ aPath, /*Type*/ aType, /*Function*/ aCallback)
{
    aPath = FILE.normal(aPath);

    if (aPath === "/")
        return aCallback(rootResource);

    if (!FILE.isAbsolute(aPath))
        aPath = FILE.join(this.path(), aPath);

    var components = FILE.split(aPath),
        index = this === rootResource ? 1 : FILE.split(this.path()).length;

    resolvePathComponents(this, aType, components, index, aCallback);
}

function resolvePathComponents(/*StaticResource*/ startResource, /*Type*/aType, /*Array*/ components, /*Integer*/ index, /*Function*/ aCallback)
{
    var count = components.length,
        parent = startResource;

    function continueResolution()
    {
        resolvePathComponents(parent, aType, components, index, aCallback);
    }

    for (; index < count; ++index)
    {
        var name = components[index],
            child = parent._children[name];
//CPLog(index + " " + components + ":" + (childNode && childNode.isResolved()) + ":");
//CPLog(name + " of " + parentNode.name() + " " + (childNode && childNode.name()));
//CPLog(parentNode._childNodes);
// + "(" + components  + ")" + " " + index + "/" + count + ":" + (childNode && childNode.name()) +">" + (childNode ? 1:0) + " " + (childNode && childNode.isResolved()));

        if (!child)
        {
            var type = index + 1 < count || aType === StaticResource.DirectoryType ? StaticResource.DirectoryType : StaticResource.FileType;

            child = new StaticResource(name, parent, type, NO);
            child.resolve();
        }

        // If this resource is still being resolved, just wait and rerun this same method when it's ready.
        if (!child.isResolved())
            return child.addEventListener("resolve", continueResolution);

        // If we've already determined that this file doesn't exist...
        if (child.isNotFound())
            return aCallback(null, new Error("File not found: " + components.join("/")));

        // If we have more path components and this is not a directory...
        if ((index + 1 < count) && child.type() !== StaticResource.DirectoryType)
            return aCallback(null, new Error("File is not a directory: " + components.join("/")));

        parent = child;
    }

    return aCallback(parent);
}

StaticResource.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

StaticResource.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

StaticResource.prototype.isNotFound = function()
{
    return this.type() === StaticResource.NotFoundType;
}

StaticResource.prototype.toString = function(/*BOOL*/ includeNotFounds)
{
    if (this.isNotFound())
        return "<file not found: " + this.name() + ">";

    var string = this.parent() ? this.name() : "/",
        type = this.type();

    if (type === StaticResource.DirectoryType)
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
}

StaticResource.prototype.nodeAtSubPath = function(/*String*/ aPath, /*BOOL*/ shouldResolveAsDirectories)
{
    aPath = FILE.normal(aPath);

    var components = FILE.split(FILE.isAbsolute(aPath) ? aPath : FILE.join(this.path(), aPath)),
        index = 1,
        count = components.length,
        parent = rootResource;

    for (; index < count; ++index)
    {
        var name = components[index];

        if (hasOwnProperty.call(parent._children, name))
            parent = parent._children[name];

        else if (shouldResolveAsDirectories)
            parent = new StaticResource(name, parent, StaticResource.DirectoryType, YES);

        else
            throw NULL;
    }

    return parent;
}

StaticResource.resolveStandardNodeAtPath = function(/*String*/ aPath, /*Function*/ aCallback)
{
    var includePaths = exports.includePaths(),
        resolveStandardNodeAtPath = function(/*String*/ aPath, /*int*/ anIndex)
        {
            var searchPath = FILE.absolute(FILE.join(includePaths[anIndex], FILE.normal(aPath)));

            rootResource.resolveSubPath(searchPath, StaticResource.FileType, function(/*StaticResource*/ aStaticResource)
            {
                if (!aStaticResource)
                {
                    if (anIndex + 1< includePaths.length)
                        resolveStandardNodeAtPath(aPath, anIndex + 1);
                    else
                        aCallback(NULL);
    
                    return;
                }
    
                aCallback(aStaticResource);
            });
        };

    resolveStandardNodeAtPath(aPath, 0);
}

exports.includePaths = function()
{
    return global.OBJJ_INCLUDE_PATHS || ["Frameworks", "Frameworks/Debug"];
}

StaticResource.cwd = FILE.cwd();

exports.StaticResource = StaticResource;
