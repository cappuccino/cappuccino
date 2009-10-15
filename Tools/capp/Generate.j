
@import "Configuration.j"

var OS = require("OS"),
    SYSTEM = require("system"),
    FILE = require("file"),
    OBJJ = require("objective-j");


function gen(/*va_args*/)
{
    var index = 0,
        count = arguments.length,

        shouldSymbolicallyLink = false,
        justFrameworks = false,
        noConfig = false,
        force = false,
        
        template = "Application",
        destination = "";

    for (; index < count; ++index)
    {
        var argument = arguments[index];

        switch (argument)
        {

            case "-l":              shouldSymbolicallyLink = true;
                                    break;

            case "-t":
            case "--template":      template = arguments[++index];
                                    break;
                                
            case "-f":
            case "--frameworks":    justFrameworks = true;
                                    break;

            case "--noconfig":      noConfig = true;
                                    break;

            case "--force":         force = true;
                                    break;

            default:                destination = argument;
        }
    }

    if (destination.length === 0)
        destination = justFrameworks ? "." : "Untitled";

    var sourceTemplate = null;

    if (FILE.isAbsolute(template))
        sourceTemplate = FILE.join(template);
    else
        sourceTemplate = FILE.join(OBJJ.OBJJ_HOME, "lib", "capp", "Resources", "Templates", template);
    
    var configFile = FILE.join(sourceTemplate, "template.config"),
        config = {};

    if (FILE.isFile(configFile))
        config = JSON.parse(FILE.read(configFile, { charset:"UTF-8" }));

    var destinationProject = destination,
        configuration = noConfig ? [Configuration defaultConfiguration] : [Configuration userConfiguration];

    if (justFrameworks)
        createFrameworksInFile(destinationProject, shouldSymbolicallyLink, force);

    else if (!FILE.exists(destinationProject))
    {
        // FIXME???
        OS.system("cp -vR " + sourceTemplate + " " + destinationProject);

        // FIXME: *JUST* for fixed glob
        require("jake");

        var files = FILE.glob(FILE.join(destinationProject, "**", "*")),
            index = 0,
            count = files.length,
            name = FILE.basename(destinationProject),
            orgIdentifier = [configuration valueForKey:@"organization.identifier"] || "";

        [configuration setTemporaryValue:name forKey:@"project.name"];
        [configuration setTemporaryValue:orgIdentifier + '.' +  toIdentifier(name) forKey:@"project.identifier"];
        [configuration setTemporaryValue:toIdentifier(name) forKey:@"project.nameasidentifier"];

        for (; index < count; ++index)
        {
            var path = files[index];

            if (FILE.isDirectory(path))
                continue;

            var contents = FILE.read(path, { charset : "UTF-8" }),
                key = nil,
                keyEnumerator = [configuration keyEnumerator];

            // FIXME: HACK
            if (path.indexOf('.gif') !== -1)
                continue;

            while (key = [keyEnumerator nextObject])
                contents = contents.replace(new RegExp("__" + key + "__", 'g'), [configuration valueForKey:key]);

            FILE.write(path, contents, { charset: "UTF-8"});
        }

        var frameworkDestination = destinationProject;

        if (config.FrameworksPath)
            frameworkDestination = FILE.join(frameworkDestination, config.FrameworksPath);

        createFrameworksInFile(frameworkDestination, shouldSymbolicallyLink);
    }
    else
        print("Directory already exists");
}


function createFrameworksInFile(/*String*/ aFile, /*Boolean*/ shouldSymbolicallyLink, /*Boolean*/ force)
{
    if (!FILE.isDirectory(aFile))
        throw new Error("Can't create Frameworks. Directory does not exist: " + aFile);
        
    var destinationFrameworks = FILE.join(aFile, "Frameworks"),
        destinationDebugFrameworks = FILE.join(aFile, "Frameworks", "Debug");
        
    if (FILE.exists(destinationFrameworks))
    {
        if (force)
        {
            print("Updating existing Frameworks directory.");
            
            FILE.rmTree(destinationFrameworks);
        }
        else
        {
            print("Frameworks directory already exists. Use --force to overwrite.");
            return;
        }
    }
    else    
        print("Creating Frameworks directory in " + destinationFrameworks + ".");

    if (!shouldSymbolicallyLink)
    {
        var sourceFrameworks = FILE.join(OBJJ.OBJJ_HOME + "lib", "Frameworks");
    
        FILE.copyTree(sourceFrameworks, destinationFrameworks);

        return;
    }
    
    var BUILD = SYSTEM.env["CAPP_BUILD"] || SYSTEM.env["STEAM_BUILD"];
    
    if (!BUILD)
        throw "CAPP_BUILD or STEAM_BUILD must be defined";

    // Release Frameworks
    FILE.mkdirs(destinationFrameworks);

    FILE.symlink(FILE.join(BUILD, "Release", "Objective-J"), FILE.join(destinationFrameworks, "Objective-J"));
    FILE.symlink(FILE.join(BUILD, "Release", "Foundation"), FILE.join(destinationFrameworks, "Foundation"));
    FILE.symlink(FILE.join(BUILD, "Release", "AppKit"), FILE.join(destinationFrameworks, "AppKit"));

    // Debug Frameworks
    FILE.mkdirs(destinationDebugFrameworks);

    FILE.symlink(FILE.join(BUILD, "Debug", "Objective-J"), FILE.join(destinationDebugFrameworks, "Objective-J"));
    FILE.symlink(FILE.join(BUILD, "Debug", "Foundation"), FILE.join(destinationDebugFrameworks, "Foundation"));
    FILE.symlink(FILE.join(BUILD, "Debug", "AppKit"), FILE.join(destinationDebugFrameworks, "AppKit"));
}

function toIdentifier(/*String*/ aString)
{
    var identifier = "",
        index = 0,
        count = aString.length,
        capitalize = NO,
        firstRegex = new RegExp("^[a-zA-Z_$]"),
        regex = new RegExp("^[a-zA-Z_$0-9]");

    for (; index < count; ++index)
    {
        var character = aString.charAt(index);

        if ((index === 0) && firstRegex.test(character) || regex.test(character))
        {
            if (capitalize)
                identifier += character.toUpperCase();
            else
                identifier += character;

            capitalize = NO;
        }
        else
            capitalize = YES;
    }

    return identifier;
}
