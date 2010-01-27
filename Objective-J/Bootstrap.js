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
#ifndef RHINO
    fileImporterForPath(FILE.join(cwd, "main.j"))("main.j", YES, function()
    {
        console.log(rootNode.toString(true));
        console.log("done.");
    });
#endif
});