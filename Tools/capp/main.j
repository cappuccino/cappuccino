
@import <Foundation/Foundation.j>

@import "Configuration.j"
@import "Generate.j"


function main(args)
{
    args.shift();
    
    if (args.length < 1)
        return printUsage();

    var index = 0,
        count = args.length;

    for (; index < count; ++index)
    {
        var argument = args[index];
        
        switch (argument)
        {
            case "version":
            case "--version":   return print("capp version 0.8.0");

            case "-h":
            case "--help":      return printUsage();

            case "config":      return config.apply(this, args.slice(index + 1));

            case "gen":         return gen.apply(this, args.slice(index + 1));
            
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
    print("    gen PATH          Generate new project at PATH from a predefined template");
    print("    -l                Symlink the Frameworks folder to your $CAPP_BUILD or $STEAM_BUILD directory");
    print("    -t, --template    Specify the template name to use (listed in capp/Resources/Templates)");
    print("    -f, --frameworks  Create only frameworks, not a full application");
    print("    --force           Overwrite Frameworks directory if it already exists");
    print("    --symlink         Create a symlink to the source Frameworks");
    print("    --build           Source the Frameworks directory files from your $CAPP_BUILD or $STEAM_BUILD directory");
    print("");
    print("    config ");
    print("    name value        Set a value for a given key");
    print("    -l, --list        List all variables set in config file.");
    print("    --get name        Get the value for a given key");
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
            var file = files[index],
                name = FILE.basename(file),
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
                
            if (FILE.isDirectory(file))
                matches = matches.concat(getFiles(file, extensions, exclusions));
            else if (isValidExtension)
                matches.push(file);
        }
    }
    
    return matches;
}
