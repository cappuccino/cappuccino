
@import "Configuration.j"

var File = require("file");


function gen(/*va_args*/)
{
    var index = 0,
        count = arguments.length,

        shouldSymbolicallyLink = false,
        justFrameworks = false,
        noConfig = false,
        
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

            default:                destination = argument;
        }
    }

    if (!justFrameworks && destination.length === 0)
        destination = "Untitled";

    var sourceTemplate = new java.io.File(OBJJ_HOME + "/lib/capp/Resources/Templates/" + template),
        destinationProject = new java.io.File(destination),
        configuration = noConfig ? [Configuration defaultConfiguration] : [Configuration userConfiguration];

    if (!destinationProject.exists())
    {
        if (!justFrameworks)
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

                while (key = [keyEnumerator nextObject])
                    contents = contents.replace(new RegExp("__" + key + "__", 'g'), [configuration valueForKey:key]);

                File.write(path, contents, { charset: "UTF-8"});
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
    
        exec(["cp", "-R", sourceFrameworks.getCanonicalPath(), destinationFrameworks.getCanonicalPath()], true);

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
