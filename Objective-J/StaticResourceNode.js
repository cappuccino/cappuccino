
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

            // If we are at the beginning and this isn't a root listing, 
            // add it since it makes sense for relative paths.
            else if (!isRoot && resultsCount < 0)
                results.push(component);
        }

        return (isRoot ? "/" : "") + results.join("/");
    },

    dirname: function(/*String*/ aPath)
    {
        var aPath = FILE.normal(aPath);

        if (aPath === "/")
            return aPath;

        var components = FILE.split(aPath);

        return FILE.join.apply(FILE, components.slice(0, components.length - 1));
    },

    isAbsolute: function(/*String*/ aPath)
    {
        return aPath.charAt(0) === "/";
    },

    join: function()
    {
        return Array.prototype.join.apply(arguments, ["/"]);
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

StaticResourceNode.FileType             = 0;
StaticResourceNode.DirectoryType        = 1;
StaticResourceNode.NotFoundType         = 2;

function StaticResourceNode(/*String*/ aName, /*StaticResourceNode*/ aParentNode, /*Type*/ aType, /*BOOL*/ isResolved)
{
    this._parentNode = aParentNode;
    this._rootNode = aParentNode ? aParentNode._rootNode : this;
    this._eventDispatcher = new EventDispatcher(this);

    this._name = aName;
    this._isResolved = isResolved;

    if (!aParentNode)
        this._path = "/";

    else if (aParentNode === this._rootNode)
        this._path = "/" + aName;

    else
        this._path = aParentNode.path() + "/" + aName;

    this._type = aType;

    if (aParentNode)
        aParentNode._childNodes[aName] = this;

    if (aType === StaticResourceNode.DirectoryType)
        this._childNodes = { };

    else if (aType === StaticResourceNode.FileType)
    {
        this._contents = "";

        if (!isResolved)
            this.resolveAsFile();
    }
}

StaticResourceNode.prototype.name = function()
{
    return this._name;
}

StaticResourceNode.prototype.path = function()
{
    return this._path;
}

StaticResourceNode.prototype.contents = function()
{
    return this._contents;
}

StaticResourceNode.prototype.type = function()
{
    return this._type;
}

StaticResourceNode.prototype.parentNode = function()
{
    return this._parentNode;
}

StaticResourceNode.prototype.rootNode = function()
{
    return this._rootNode;
}

StaticResourceNode.prototype.isResolved = function()
{
    return this._isResolved;
}

function resolveStaticResourceNode(/*StaticResourceNode*/ aStaticResourceNode, /*BOOL*/ shouldDispatchEvent)
{
    aStaticResourceNode._isResolved = YES;
    
    if (shouldDispatchEvent)
        aStaticResourceNode._eventDispatcher.dispatchEvent(
        {
            type:"resolve",
            staticResourceNode:aStaticResourceNode
        });
}

StaticResourceNode.prototype.write = function(/*String*/ aString)
{
    this._contents += aString;
}

StaticResourceNode.prototype.resolveAsFile = function()
{
    var self = this;

    function onsuccess(/*anEvent*/ anEvent)
    {
        self._type = StaticResourceNode.FileType;
        self._contents = anEvent.request.responseText();

        resolveStaticResourceNode(self, YES);
    }

    function onfailure()
    {
        self._type = StaticResourceNode.NotFoundType;

        resolveStaticResourceNode(self, YES);
    }

    new FileRequest(this.path(), onsuccess, onfailure);
}

StaticResourceNode.prototype.resolveSubPath = function(/*String*/ aPath, /*Type*/ aType, /*Function*/ aCallback)
{
    aPath = FILE.normal(aPath);

    if (aPath === "/")
        return aCallback(rootNode);

    if (!FILE.isAbsolute(aPath))
        aPath = FILE.join(this.path(), aPath);

    var components = FILE.split(aPath),
        index = this === this.rootNode() ? 1 : FILE.split(this.path()).length;

    resolvePathComponents(this, aType, components, index, aCallback);
}

function resolvePathComponents(/*StaticResourceNode*/ startNode, /*Type*/aType, /*Array*/ components, /*Integer*/ index, /*Function*/ aCallback)
{
    var count = components.length,
        parentNode = startNode;

    function continueResolution()
    {
        resolvePathComponents(parentNode, aType, components, index, aCallback);
    }

    for (; index < count; ++index)
    {
        var name = components[index],
            childNode = parentNode._childNodes[name];
//CPLog(index + " " + components + ":" + (childNode && childNode.isResolved()) + ":");
//CPLog(name + " of " + parentNode.name() + " " + (childNode && childNode.name()));
//CPLog(parentNode._childNodes);
// + "(" + components  + ")" + " " + index + "/" + count + ":" + (childNode && childNode.name()) +">" + (childNode ? 1:0) + " " + (childNode && childNode.isResolved()));

        if (!childNode)
        {

            if (index + 1 < count || aType === StaticResourceNode.DirectoryType)
            {
                var bundle = new CFBundle(components.slice(0, index + 1).join("/"));

                // Eat any errors.
                bundle.onerror = function() { };

                bundle.addEventListener("load", continueResolution);
                bundle.addEventListener("error", continueResolution);

                bundle.load(NO);
            }
            else
            {
                childNode = new StaticResourceNode(name, parentNode, StaticResourceNode.FileType, NO);

                if (childNode.isResolved())
                    continueResolution();
                else
                    childNode.addEventListener("resolve", continueResolution);
            }

            return;            
        }
        else if (childNode.isResolved())
        {
            // If we've already determined that this file doesn't exist...
            if (childNode.isNotFound())
                return aCallback(null, new Error("File not found: " + components.join("/")));

            // If we have no more path components...
            if (index + 1 >= count)
                return aCallback(childNode);

            // Make sure this is a directory
            if (childNode.type() !== StaticResourceNode.DirectoryType)
                return aCallback(null, new Error("File is not a directory: " + components.join("/"))); 

            // Do nothing: simply allow the loop to progress to the next child.
        }
        // If this node is still being resolved, just wait and rerun this same method when it's ready.
        else
        {
            childNode.addEventListener("resolve", continueResolution);
            return;
        }

        parentNode = childNode;
    }
}

StaticResourceNode.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}

StaticResourceNode.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}

StaticResourceNode.prototype.isNotFound = function()
{
    return this.type() === StaticResourceNode.NotFoundType;
}

StaticResourceNode.prototype.toString = function(/*BOOL*/ includeNotFounds)
{
    if (this.isNotFound())
        return "<file not found: " + this.name() + ">";

    var string = this.parentNode() ? this.name() : "/",
        type = this.type();

    if (type === StaticResourceNode.DirectoryType)
    {
        var childNodes = this._childNodes;

        for (var name in childNodes)
            if (childNodes.hasOwnProperty(name))
            {
                var childNode = childNodes[name];

                if (includeNotFounds || !childNode.isNotFound())
                    string += "\n\t" + childNodes[name].toString(includeNotFounds).split('\n').join("\n\t");
            }
    }

    return string;
}

StaticResourceNode.prototype.nodeAtSubPath = function(/*String*/ aPath, /*BOOL*/ shouldResolveAsDirectories)
{
    aPath = FILE.normal(aPath);

    var components = FILE.split(FILE.isAbsolute(aPath) ? aPath : FILE.join(this.path(), aPath)),
        index = 1,
        count = components.length,
        parentNode = this.rootNode();

    for (; index < count; ++index)
    {
        var name = components[index];

        if (hasOwnProperty.apply(parentNode._childNodes, [name]))
            parentNode = parentNode._childNodes[name];

        else if (shouldResolveAsDirectories)
            parentNode = new StaticResourceNode(name, parentNode, StaticResourceNode.DirectoryType, YES);

        else
            throw NULL;
    }

    return parentNode;
}

StaticResourceNode.resolveStandardNodeAtPath = function(/*String*/ aPath, /*Function*/ aCallback)
{
    var includePaths = exports.includePaths(),
        resolveStandardNodeAtPath = function(/*String*/ aPath, /*int*/ anIndex)
        {
            var searchPath = FILE.absolute(FILE.join(includePaths[anIndex], FILE.normal(aPath)));

            rootNode.resolveSubPath(searchPath, StaticResourceNode.FileType, function(/*StaticResourceNode*/ aStaticResourceNode)
            {
                if (!aStaticResourceNode)
                {
                    if (anIndex + 1< includePaths.length)
                        resolveStandardNodeAtPath(aPath, anIndex + 1);
                    else
                        aCallback(NULL);
    
                    return;
                }
    
                aCallback(aStaticResourceNode);
            });
        };

    resolveStandardNodeAtPath(aPath, 0);
}

exports.includePaths = function()
{
    return global.OBJJ_INCLUDE_PATHS || ["Frameworks", "Frameworks/Debug"];
}
