function create()
{   
    if (arguments.length < 1)
        printUsage("create");
        
    var shouldSymbolicallyLink = false,
        index = 0,
        count = arguments.length,
        
        template = "Application",
        destination = "";

    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (arguments[index])
        {
            case "-l":          shouldSymbolicallyLink = true;
                                break;
            
            case "--template":  template = arguments[++index];
                                break;
                                
            default:            destination = argument;
        }
    }

    var sourceTemplate = new File(OBJJ_HOME + "/lib/steam/Templates/" + template),
        destinationProject = new File(destination);
    
    if (!destinationProject.exists())
    {
        exec(["cp", "-vR", sourceTemplate.getCanonicalPath(), destinationProject.getCanonicalPath()], true);
        
        var files = getFiles(destinationProject, ['j', "plist", "html"]),
            index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index],
                contents = readFile(file);
            
            contents = contents.replace(/__Product__/g, destinationProject.getName());
            
            writeContentsToFile(contents, file);
        }
        
        createFrameworksInFile(destinationProject, shouldSymbolicallyLink);
    }
    else
        System.out.println("Directory already exists");
}
