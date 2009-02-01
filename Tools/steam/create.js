function create()
{   
    if (arguments.length < 1)
        printUsage("create");
        
    var link = false,
        index = 0,
        count = arguments.length,
        
        destination = NULL,
        justFrameworks = false;

    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (arguments[index])
        {
            case "-l":  link = true;
                        break;
            case "-f":  justFrameworks = true;
                        break;
            default:    destination = argument;
        }
    }

    var sourceNewApplication = new File(OBJJ_HOME + "/lib/NewApplication"),
        destinationNewApplication = new File(destination),
        sourceFrameworks = new File(OBJJ_HOME + "/lib/Frameworks"),
        sourceDebugFrameworks = new File(OBJJ_HOME + "/lib/Frameworks-Debug"),
        destinationFrameworks = new File(destination + "/Frameworks"),
        destinationDebugFrameworks = new File(destination + "/Frameworks/Debug");
    
    System.out.println(sourceNewApplication.getCanonicalPath() + "," + destinationNewApplication.getCanonicalPath() + "," + sourceFrameworks.getCanonicalPath() + "," + destinationFrameworks.getCanonicalPath());
    
    if (justFrameworks || !destinationNewApplication.exists())
    {
        if (!justFrameworks)
            exec(["cp", "-vR", sourceNewApplication.getCanonicalPath(), destinationNewApplication.getCanonicalPath()], true);
        
        if (!link)
        {
            exec(["cp", "-vR", sourceFrameworks.getCanonicalPath(), destinationFrameworks.getCanonicalPath()], true);
            exec(["cp", "-vR", sourceDebugFrameworks.getCanonicalPath(), destinationDebugFrameworks.getCanonicalPath()], true);
        }
        else
        {
            var STEAM_BUILD = System.getenv("STEAM_BUILD");
            
            // Release Frameworks
            new File(destinationFrameworks).mkdir();
            
            exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/Objective-J").getCanonicalPath(),
                                new File(destination + "/Frameworks/Objective-J").getCanonicalPath()], true);

            exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/Foundation").getCanonicalPath(),
                                new File(destination + "/Frameworks/Foundation").getCanonicalPath()], true);

            exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/AppKit").getCanonicalPath(),
                                new File(destination + "/Frameworks/AppKit").getCanonicalPath()], true);

            // Debug Frameworks
            new File(destinationDebugFrameworks).mkdir();
            
            exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/Objective-J").getCanonicalPath(),
                                new File(destination + "/Frameworks/Debug/Objective-J").getCanonicalPath()], true);

            exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/Foundation").getCanonicalPath(),
                                new File(destination + "/Frameworks/Debug/Foundation").getCanonicalPath()], true);

            exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/AppKit").getCanonicalPath(),
                                new File(destination + "/Frameworks/Debug/AppKit").getCanonicalPath()], true);
        }
    }
    else
        System.out.println("Directory already exists");
}
