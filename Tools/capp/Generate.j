
@import "Configuration.j"

var File = require("file");

var FILE = File;
var OBJJ = require("objj/objj");
var SYSTEM = require("system");

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
    if (File.isAbsolute(template))
        sourceTemplate = new java.io.File(template);
    else
        sourceTemplate = new java.io.File(OBJJ_HOME + "/lib/capp/Resources/Templates/" + template);
    
    var configFile = File.join(sourceTemplate, "template.config"),
        config = {};
    if (File.isFile(configFile))
        config = JSON.parse(File.read(configFile));
    
    var destinationProject = new java.io.File(destination),
        configuration = noConfig ? [Configuration defaultConfiguration] : [Configuration userConfiguration];

    if (justFrameworks)
        createFrameworksInFile(String(destinationProject.getCanonicalPath()), shouldSymbolicallyLink, force);

    else if (!destinationProject.exists())
    {
        exec(["cp", "-vR", sourceTemplate.getCanonicalPath(), destinationProject.getCanonicalPath()], true);

        var files = getFiles(destinationProject),
            index = 0,
            count = files.length,
            name = String(destinationProject.getName()),
            orgIdentifier = [configuration valueForKey:@"organization.identifier"] || "";

        [configuration setTemporaryValue:name forKey:@"project.name"];
        [configuration setTemporaryValue:orgIdentifier + '.' +  toIdentifier(name) forKey:@"project.identifier"];
        [configuration setTemporaryValue:toIdentifier(name) forKey:@"project.nameasidentifier"];

        for (; index < count; ++index)
        {
            var path = files[index],
                contents = File.read(path, { charset : "UTF-8" }),
                key = nil,
                keyEnumerator = [configuration keyEnumerator];

            // FIXME: HACK
            if (path.indexOf('.gif') !== -1)
                continue;

            while (key = [keyEnumerator nextObject])
                contents = contents.replace(new RegExp("__" + key + "__", 'g'), [configuration valueForKey:key]);

            File.write(path, contents, { charset: "UTF-8"});
        }

        var frameworkDestination = destinationProject.getCanonicalPath();
        if (config.FrameworksPath)
            frameworkDestination = File.join(frameworkDestination, config.FrameworksPath);

        createFrameworksInFile(frameworkDestination, shouldSymbolicallyLink);
    }
    else
        print("Directory already exists");
}

function createFrameworksInFile(/*String*/ aFile, /*Boolean*/ symlink, /*Boolean*/ force)
{
    var destination = FILE.path(aFile);
    
    if (!destination.isDirectory())
        throw new Error("Can't create Frameworks. Directory does not exist: " + destination);
    
    if (symlink && !(SYSTEM.env["CAPP_BUILD"] || SYSTEM.env["STEAM_BUILD"]))
        throw "CAPP_BUILD or STEAM_BUILD must be defined";

    var installedFrameworks = FILE.path(FILE.join(OBJJ.OBJJ_HOME, "lib", "Frameworks")),
        builtFrameworks = FILE.path(SYSTEM.env["CAPP_BUILD"] || SYSTEM.env["STEAM_BUILD"]);
    
    var sourceFrameworks = symlink ? builtFrameworks.join("Release") : installedFrameworks,
        sourceDebugFrameworks = symlink ? builtFrameworks.join("Debug") : installedFrameworks.join("Debug");
        
    var destinationFrameworks = destination.join("Frameworks"),
        destinationDebugFrameworks = destination.join("Frameworks", "Debug");
    
    print("Creating Frameworks directory in " + destinationFrameworks + ".");
    
    //destinationFrameworks.mkdirs(); // redundant
    destinationDebugFrameworks.mkdirs();
    
    ["Objective-J", "Foundation", "AppKit"].forEach(function(framework) {
        installFramework(
            sourceFrameworks.join(framework),
            destinationFrameworks.join(framework),
            force, symlink);
        installFramework(
            sourceDebugFrameworks.join(framework),
            destinationDebugFrameworks.join(framework),
            force, symlink);
    });
}

function installFramework(source, dest, force, symlink) {
    if (dest.exists()) {
        if (force) {
            dest.rmtree();
        } else {
            print("Warning: " + dest + " already exists. Use --force to overwrite.");
            return;
        }
    }
    if (source.exists()) {
        print((symlink ? "Symlinking " : "Copying ") + source + " to " + dest);
        if (symlink)
            FILE.symlink(source, dest);
        else
            FILE.copyTree(source, dest);
    }
    else
        print("Warning: "+source+" doesn't exist.");
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
