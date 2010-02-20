
var cwd = FILE.cwd(),
    rootResource = new StaticResource("", NULL, YES, cwd !== "/");

StaticResource.root = rootResource;

#ifdef BROWSER
if (rootResource.isResolved())
{
    rootResource.nodeAtSubPath(FILE.dirname(cwd), YES);
    resolveCWD();
}
else
{
    rootResource.resolve();
    rootResource.addEventListener("resolve", resolveCWD);
}

function resolveCWD()
{
    rootResource.resolveSubPath(cwd, YES, function(/*StaticResource*/ aResource)
    {
        var includePaths = StaticResource.includePaths(),
            index = 0,
            count = includePaths.length;

        for (; index < count; ++index)
            aResource.nodeAtSubPath(FILE.normal(includePaths[index]), YES);

        if (typeof OBJJ_MAIN_FILE === "undefined")
            OBJJ_MAIN_FILE = "main.j";

        Executable.fileImporterForPath(cwd)(OBJJ_MAIN_FILE || "main.j", YES, function()
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
