
@import "Configuration.j"

var OS = require("os"),
    SYSTEM = require("system"),
    FILE = require("file"),
    OBJJ = require("objective-j");

// FIXME: better way to do this:
var CAPP_HOME = require("packages").catalog["cappuccino"].directory;

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
        sourceTemplate = FILE.join(CAPP_HOME, "lib", "capp", "Resources", "Templates", template);

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
        FILE.copyTree(sourceTemplate, destinationProject);

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

            if (FILE.basename(path) === ".DS_Store")
                continue;

            // Don't do this for images.
            if ([".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"].indexOf(FILE.extension(path).toLowerCase()) !== -1)
                continue;

            try
            {
                var contents = FILE.read(path, { charset : "UTF-8" }),
                    key = nil,
                    keyEnumerator = [configuration keyEnumerator];

                while (key = [keyEnumerator nextObject])
                    contents = contents.replace(new RegExp("__" + RegExp.escape(key) + "__", 'g'), [configuration valueForKey:key]);

                FILE.write(path, contents, { charset: "UTF-8"});
            }
            catch (anException)
            {
                print("Copying and modifying " + path + " failed.");
            }
        }

        var frameworkDestination = destinationProject;

        if (config.FrameworksPath)
            frameworkDestination = FILE.join(frameworkDestination, config.FrameworksPath);

        createFrameworksInFile(frameworkDestination, shouldSymbolicallyLink);
    }
    else
        print("Directory already exists");
}

function createFrameworksInFile(/*String*/ aFile, /*Boolean*/ symlink, /*Boolean*/ force)
{
    var destination = FILE.path(FILE.absolute(aFile));
    var frameworks = ["Foundation", "AppKit"];
    
    if (!destination.isDirectory())
        throw new Error("Can't create Frameworks. Directory does not exist: " + destination);

    var destinationFrameworks = destination.join("Frameworks"),
        destinationDebugFrameworks = destination.join("Frameworks", "Debug");

    print("Creating Frameworks directory in " + destinationFrameworks + ".");

    //destinationFrameworks.mkdirs(); // redundant
    destinationDebugFrameworks.mkdirs();

    if (symlink) {
        if (!(SYSTEM.env["CAPP_BUILD"] || SYSTEM.env["STEAM_BUILD"]))
            throw "CAPP_BUILD or STEAM_BUILD must be defined";

        var builtFrameworks = FILE.path(SYSTEM.env["CAPP_BUILD"] || SYSTEM.env["STEAM_BUILD"]);

        var sourceFrameworks = builtFrameworks.join("Release"),
            sourceDebugFrameworks = builtFrameworks.join("Debug");

        frameworks.concat("Objective-J").forEach(function(framework) {
            installFramework(sourceFrameworks.join(framework), destinationFrameworks.join(framework), force, true);
            installFramework(sourceDebugFrameworks.join(framework), destinationDebugFrameworks.join(framework), force, true);
        });
    }
    else {
        // Objective-J. Take from OBJJ_HOME.
        var objjHome = FILE.path(OBJJ.OBJJ_HOME);
        var objjPath = objjHome.join("Frameworks", "Objective-J");
        var objjDebugPath = objjHome.join("Frameworks", "Debug", "Objective-J");
        
        installFramework(objjPath, destinationFrameworks.join("Objective-J"), force, false);
        installFramework(objjDebugPath, destinationDebugFrameworks.join("Objective-J"), force, false);
        
        // Frameworks. Search frameworks paths
        frameworks.forEach(function(framework) {
            var found;
            
            for (var i = 0, found = false; !found && i < OBJJ.objj_frameworks.length; i++) {
                var sourceFramework = FILE.path(OBJJ.objj_frameworks[i]).join(framework);
                if (FILE.isDirectory(sourceFramework)) {
                    installFramework(sourceFramework, destinationFrameworks.join(framework), force, false);
                    found = true;
                }
            }
            if (!found)
                print("Warning: Couldn't find framework \"" + framework +"\"");
            
            for (var i = 0, found = false; !found && i < OBJJ.objj_debug_frameworks.length; i++) {
                var sourceDebugFramework = FILE.path(OBJJ.objj_debug_frameworks[i]).join(framework);
                if (FILE.isDirectory(sourceDebugFramework)) {
                    installFramework(sourceDebugFramework, destinationDebugFrameworks.join(framework), force, false);
                    found = true;
                }
            }
            if (!found)
                print("Warning: Couldn't find debug framework \"" + framework +"\"");
        });
    }
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
