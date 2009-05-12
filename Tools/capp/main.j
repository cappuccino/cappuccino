importClass(java.io.FileWriter);
importClass(java.io.FileOutputStream);
importClass(java.io.BufferedWriter);
importClass(java.io.OutputStreamWriter);

@import <Foundation/Foundation.j>

function main()
{
    if (system.args.length < 1)
        return printUsage();

    var index = 0,
        count = system.args.length,
        
        shouldSymbolicallyLink = false,
        justFrameworks = false,
        
        template = "Application",
        destination = "";

    for (; index < count; ++index)
    {
        var argument = system.args[index];
        
        switch (system.args[index])
        {
            case "-l":              shouldSymbolicallyLink = true;
                                    break;
                                    
            case "-h":
            case "--help":          printUsage();
                                    return;
            
            case "-t":
            case "--template":      template = system.args[++index];
                                    break;
                                
            case "-f":
            case "--frameworks":    justFrameworks = true;
                                    break;
                                
            default:                destination = argument;
        }
    }

    var sourceTemplate = new java.io.File(OBJJ_HOME + "/lib/capp/Resources/Templates/" + template),
        destinationProject = new java.io.File(destination);
    
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
        var destinationFrameworks = new java.io.File(aFile.getCanonicalPath()+ "/Frameworks"),
            destinationDebugFrameworks = new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Debug");

        if (!shouldSymbolicallyLink)
        {
            var sourceFrameworks = new java.io.File(OBJJ_HOME + "/lib/Frameworks");
        
            exec(["cp", "-vR", sourceFrameworks.getCanonicalPath(), destinationFrameworks.getCanonicalPath()], true);

            return true;
        }
        
        var BUILD = system.env["CAPP_BUILD"] || system.env["STEAM_BUILD"];
        
        if (!BUILD)
            throw "CAPP_BUILD or STEAM_BUILD must be defined";
        
        // Release Frameworks
        new java.io.File(destinationFrameworks).mkdir();
        
        exec(["ln", "-s",   new java.io.File(BUILD + "/Release/Objective-J").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Objective-J").getCanonicalPath()], true);

        exec(["ln", "-s",   new java.io.File(BUILD + "/Release/Foundation").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Foundation").getCanonicalPath()], true);

        exec(["ln", "-s",   new java.io.File(BUILD + "/Release/AppKit").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/AppKit").getCanonicalPath()], true);

        // Debug Frameworks
        new java.io.File(destinationDebugFrameworks).mkdir();
        
        exec(["ln", "-s",   new java.io.File(BUILD + "/Debug/Objective-J").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Debug/Objective-J").getCanonicalPath()], true);

        exec(["ln", "-s",   new java.io.File(BUILD + "/Debug/Foundation").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Debug/Foundation").getCanonicalPath()], true);

        exec(["ln", "-s",   new java.io.File(BUILD + "/Debug/AppKit").getCanonicalPath(),
                            new java.io.File(aFile.getCanonicalPath() + "/Frameworks/Debug/AppKit").getCanonicalPath()], true);
}

function printUsage()
{
    print("capp /path/to/your/app [options]");
    print("    -l                Symlink the Frameworks folder to your $CAPP_BUILD or $STEAM_BUILD directory");
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

function exec(/*Array*/ command, /*Boolean*/ showOutput)
{
    var line = "",
        output = "",
        
        process = Packages.java.lang.Runtime.getRuntime().exec(command),//jsArrayToJavaArray(command));
        reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getInputStream()));
    
    while (line = reader.readLine())
    {
        if (showOutput)
            Packages.java.lang.System.out.println(line);
        
        output += line + '\n';
    }
    
    reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getErrorStream()));
    
    while (line = reader.readLine())
        Packages.java.lang.System.out.println(line);

    try
    {
        if (process.waitFor() != 0)
            Packages.java.lang.System.err.println("exit value = " + process.exitValue());
    }
    catch (anException)
    {
        Packages.java.lang.System.err.println(anException);
    }
    
    return output;
}

function getFiles(/*File*/ sourceDirectory, /*nil|String|Array<String>*/ extensions, /*Array*/ exclusions)
{
    var matches = [],
        files = sourceDirectory.listFiles(),
        hasMultipleExtensions = typeof extensions !== "string";

    if (files)
    {
        var index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index].getCanonicalFile(),
                name = String(file.getName()),
                isValidExtension = !extensions;
            
            if (exclusions && fileArrayContainsFile(exclusions, file))
                continue;
            
            if (!isValidExtension)
                if (hasMultipleExtensions)
                {
                    var extensionCount = extensions.length;
                    
                    while (extensionCount-- && !isValidExtension)
                    {
                        var extension = extensions[extensionCount];
                        
                        if (name.substring(name.length - extension.length - 1) === ("." + extension))
                            isValidExtension = true;
                    }
                }
                else if (name.substring(name.length - extensions.length - 1) === ("." + extensions))
                    isValidExtension = true;
                
            if (isValidExtension)
                matches.push(file);
            
            if (file.isDirectory())
                matches = matches.concat(getFiles(file, extensions, exclusions));
        }
    }
    
    return matches;
}
