importClass(java.io.FileWriter);
importClass(java.io.FileOutputStream);
importClass(java.io.BufferedWriter);
importClass(java.io.OutputStreamWriter);

@import <Foundation/Foundation.j>

@import "Configuration.j"
@import "Generate.j"


function main()
{
    if (system.args.length < 1)
        return printUsage();

    var index = 0,
        count = system.args.length;

    for (; index < count; ++index)
    {
        var argument = system.args[index];
        
        switch (argument)
        {
            case "version":
            case "--version":   return print("capp version 0.7.0");

            case "-h":
            case "--help":      return printUsage();

            case "config":      return config.apply(this, system.args.slice(index + 1));

            case "gen":         return gen.apply(this, system.args.slice(index + 1));
            
            default:            print("unknown command " + argument);
        }
    }
}

function printUsage()
{
    print("capp [--version] COMMAND [ARGS]");
    print("    --version         Print version");
    print("    -h, --help        Print usage");
    print("");
    print(ANSITextApplyProperties("    gen", ANSI_BOLD) + " PATH          Generate new project at PATH from a predefined template");
    print("    -l                Symlink the Frameworks folder to your $CAPP_BUILD or $STEAM_BUILD directory");
    print("    -t, --template    Specify the template name to use (listed in capp/Resources/Templates)");
    print("    -f, --frameworks  Create only frameworks, not a full application");
    print("");
    print(ANSITextApplyProperties("    config ", ANSI_BOLD));
    print("    name value        Set a value for a given key");
    print("    -l, --list        List all variables set in config file.");
    print("    --get name        Get the value for a given key");
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
                
            if (file.isDirectory())
                matches = matches.concat(getFiles(file, extensions, exclusions));
            else if (isValidExtension)
                matches.push(String(file.getCanonicalPath()));
        }
    }
    
    return matches;
}
