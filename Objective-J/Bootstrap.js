
makeExportsGlobal();

var rootNode = new StaticResourceNode("", null, StaticResourceNode.DirectoryType, YES),
    cwd = FILE.cwd();

rootNode.nodeAtSubPath(FILE.dirname(cwd), YES);
rootNode.resolveSubPath(cwd, StaticResourceNode.DirectoryType, function(cwdNode)
{
    var includePaths = exports.includePaths(),
        index = 0,
        count = includePaths.length;

    for (; index < count; ++index)
        cwdNode.nodeAtSubPath(FILE.normal(includePaths[index]), YES);
#ifdef BROWSER
    OBJJ_MAIN_FILE = "main.j";

    fileImporterForPath(FILE.join(cwd, "main.j"))("main.j", YES, function()
    {
        afterDocumentLoad(main);
    });
#endif
});

#ifdef BROWSER
function afterDocumentLoad(/*Function*/ aFunction)
{
    if (documentLoaded)
        return aFunction();

    if (window.addEventListener)
        window.addEventListener("load", aFunction, false);

    else if (window.attachEvent)
        window.attachEvent("onload", aFunction);
}

var documentLoaded = NO;

afterDocumentLoad(function()
{
    documentLoaded = YES;
});
#endif
