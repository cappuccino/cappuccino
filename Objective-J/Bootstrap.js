
var cwd = FILE.cwd(),
    root = new StaticResourceNode("", NULL, StaticResourceNode.DirectoryType, cwd !== "/"),
    rootNode = root;

#ifdef BROWSER
if (root.isResolved())
{
    root.nodeAtSubPath(FILE.dirname(cwd), YES);
    resolveCWD();
}
else
{
    root.resolve();
    root.addEventListener("resolve", resolveCWD);
}

function resolveCWD()
{
    root.resolveSubPath(cwd, StaticResourceNode.DirectoryType, function(/*StaticResource*/ aResource)
    {
        var includePaths = exports.includePaths(),
            index = 0,
            count = includePaths.length;

        for (; index < count; ++index)
            aResource.nodeAtSubPath(FILE.normal(includePaths[index]), YES);

        if (typeof OBJJ_MAIN_FILE === "undefined")
            OBJJ_MAIN_FILE = "main.j";

        fileImporterForPath(cwd)(OBJJ_MAIN_FILE || "main.j", YES, function()
        {
            afterDocumentLoad(main);
        });
    });
}

function afterDocumentLoad(/*Function*/ aFunction)
{
    if (documentLoaded)
        return aFunction();

    if (window.addEventListener)
        window.addEventListener("load", aFunction, NO);

    else if (window.attachEvent)
        window.attachEvent("onload", aFunction);
}

var documentLoaded = NO;

afterDocumentLoad(function()
{
    documentLoaded = YES;
});
#endif

exports.rootNode = rootNode;

makeExportsGlobal();
