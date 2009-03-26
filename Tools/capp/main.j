
importClass(java.lang.System);
importClass(java.io.File);
importClass(java.io.FileWriter);
importClass(java.io.FileOutputStream);
importClass(java.io.BufferedWriter);
importClass(java.io.OutputStreamWriter);

@import <Foundation/Foundation.j>

function main()
{
    if (arguments.length < 1)
        return printUsage();

    var index = 0,
        count = arguments.length,
        
        shouldSymbolicallyLink = false,
        justFrameworks = false,
        
        template = "Application",
        destination = "";

    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (arguments[index])
        {
            case "-l":              shouldSymbolicallyLink = true;
                                    break;
                                    
            case "-h":
            case "--help":          printUsage();
                                    return;
            
            case "-t":
            case "--template":      template = arguments[++index];
                                    break;
                                
            case "-f":
            case "--frameworks":    justFrameworks = true;
                                    break;
                                
            default:                destination = argument;
        }
    }

    var sourceTemplate = new File(OBJJ_HOME + "/lib/capp/Resources/Templates/" + template),
        destinationProject = new File(destination);
    
    if (!destinationProject.exists())
    {
        if (!justFrameworks)
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
        }
        
        createFrameworksInFile(destinationProject, shouldSymbolicallyLink);
    }
    else
        print("Directory already exists");
}

function createFrameworksInFile(/*File*/ aFile, /*Boolean*/ shouldSymbolicallyLink)
{
        var destinationFrameworks = new File(aFile.getCanonicalPath()+ "/Frameworks"),
            destinationDebugFrameworks = new File(aFile.getCanonicalPath() + "/Frameworks/Debug");

        if (!shouldSymbolicallyLink)
        {
            var sourceFrameworks = new File(OBJJ_HOME + "/lib/Frameworks");
        
            exec(["cp", "-vR", sourceFrameworks.getCanonicalPath(), destinationFrameworks.getCanonicalPath()], true);

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

function printUsage()
{
    print("capp /path/to/your/app [options]");
    print("    -l                Symlink the Frameworks folder to your $STEAM_BUILD directory");
    print("    -t, --template    Specify the template name to use (listed in capp/Resources/Templates)");
    print("    -f, --frameworks  Create only frameworks, not a full application");
    print("    -h, --help        Print usage");
}


function writeContentsToFile(/*String*/ aString, /*File*/ aFile)
{
    var writer = new BufferedWriter(new FileWriter(aFile));

    writer.write(aString);

    writer.close();
}
