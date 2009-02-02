function createFrameworks()
{
    var shouldSymbolicallyLink = false,
        index = 0,
        count = arguments.length,
        
        destination = "";

    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (arguments[index])
        {
            case "-l":  shouldSymbolicallyLink = true;
                        break;
            
            default:    destination = argument;
        }
    }

    createFrameworksInFile(new File(destination), shouldSymbolicallyLink);
}

function createFrameworksInFile(/*File*/ aFile, /*Boolean*/ shouldSymbolicallyLink)
{
        var destinationFrameworks = new File(aFile.getCanonicalPath()+ "/Frameworks"),
            destinationDebugFrameworks = new File(aFile.getCanonicalPath() + "/Frameworks/Debug");

        if (!shouldSymbolicallyLink)
        {
            var sourceFrameworks = new File(OBJJ_HOME + "/lib/Frameworks"),
                sourceDebugFrameworks = new File(OBJJ_HOME + "/lib/Frameworks-Debug");
        
            exec(["cp", "-vR", sourceFrameworks.getCanonicalPath(), destinationFrameworks.getCanonicalPath()], true);
            exec(["cp", "-vR", sourceDebugFrameworks.getCanonicalPath(), destinationDebugFrameworks.getCanonicalPath()], true);
            
            return true;
        }
        
        var STEAM_BUILD = System.getenv("STEAM_BUILD");
        
        // Release Frameworks
        new File(destinationFrameworks).mkdir();
        
        exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/Objective-J").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/Objective-J").getCanonicalPath()], true);

        exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/Foundation").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/Foundation").getCanonicalPath()], true);

        exec(["ln", "-s",   new File(STEAM_BUILD + "/Release/AppKit").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/AppKit").getCanonicalPath()], true);

        // Debug Frameworks
        new File(destinationDebugFrameworks).mkdir();
        
        exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/Objective-J").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/Debug/Objective-J").getCanonicalPath()], true);

        exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/Foundation").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/Debug/Foundation").getCanonicalPath()], true);

        exec(["ln", "-s",   new File(STEAM_BUILD + "/Debug/AppKit").getCanonicalPath(),
                            new File(aFile.getCanonicalPath() + "/Frameworks/Debug/AppKit").getCanonicalPath()], true);
}