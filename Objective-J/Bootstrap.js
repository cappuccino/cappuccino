
makeExportsGlobal();

var rootNode = new StaticResourceNode("", NULL, StaticResourceNode.DirectoryType, YES),
    cwd = FILE.cwd();
#ifndef COMMONJS
rootNode.nodeAtSubPath(FILE.dirname(cwd), YES);
rootNode.resolveSubPath(cwd, StaticResourceNode.DirectoryType, function(cwdNode)
{

    var includePaths = exports.includePaths(),
        index = 0,
        count = includePaths.length;

    for (; index < count; ++index)
        cwdNode.nodeAtSubPath(FILE.normal(includePaths[index]), YES);
#ifdef BROWSER
    if (typeof OBJJ_MAIN_FILE === "undefined")
        OBJJ_MAIN_FILE = "main.j";

    fileImporterForPath(cwd)(OBJJ_MAIN_FILE, YES, function()
    {
        afterDocumentLoad(main);
    });
#endif
});
#endif

#ifdef BROWSER
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
