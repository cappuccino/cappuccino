 /*
 * Generate.j
 * capp
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "Configuration.j"

/* var OS = require("os"),
    SYSTEM = require("system"),
    FILE = require("file"); */

var stream = ObjectiveJ.term.stream;

var parser = new (ObjectiveJ.parser.Parser)();
var utilsFile = ObjectiveJ.utils.file;

var fs = require("fs");
var node_path = require("path");
var child_process = require("child_process");

parser.usage("DESTINATION_DIRECTORY");

parser.help("Generate a Cappuccino project or Frameworks directory");

parser.option("-t", "--template", "template")
    .set()
    .def("Application")
    .help("Selects a project template to use (default: Application).");

parser.option("-f", "--frameworks", "justFrameworks")
    .set(true)
    .help("Only generate or update Frameworks directory.");

parser.option("-F", "--framework", "framework", "frameworks")
    .def([])
    .push()
    .help("Additional framework to copy/symlink (default: Objective-J, Foundation, AppKit)");

parser.option("-T", "--theme", "theme", "themes")
    .def([])
    .push()
    .help("Additional Theme to copy/symlink into Resource (default: nothing)");

parser.option("--no-frameworks", "noFrameworks")
    .set(true)
    .help("Don't copy any default frameworks (can be overridden with -F)");

parser.option("--symlink", "symlink")
    .set(true)
    .help("Creates a symlink to each framework instead of copying.");

parser.option("--build", "useCappBuild")
    .set(true)
    .help("Uses frameworks in the $CAPP_BUILD.");

parser.option("-l")
    .action(function(o) { o.symlink = o.useCappBuild = true; })
    .help("Enables both the --symlink and --build options.");

parser.option("--force", "force")
    .set(true)
    .help("Overwrite update existing frameworks.");

parser.option("--noconfig", "noconfig")
    .set(true)
    .help("Use the default configuration, ignore your configuration.");

parser.option("--list-templates", "listTemplates")
    .set(true)
    .help("Lists available templates.");

parser.option("--list-frameworks", "listFrameworks")
    .set(true)
    .help("Lists available frameworks.");

parser.helpful();

// FIXME: better way to do this:
/* var CAPP_HOME = require("narwhal/packages").catalog["cappuccino"].directory,
    templatesDirectory = node_path.join(CAPP_HOME, "lib", "capp", "Resources", "Templates"); */

var templatesDirectory;

function gen(/*va_args*/)
{
    var mainBundlePath = arguments[0];
    templatesDirectory = node_path.join(mainBundlePath, "..", "Resources", "Templates");
    var args = ["capp gen"].concat(Array.prototype.slice.call(arguments, 1));
    var options = parser.parse(args, null, null, true);

    if (options.args.length > 1)
    {
        parser.printUsage(options);
        process.exit(1);
    }

    if (options.listTemplates)
    {
        listTemplates();
        return;
    }

    if (options.listFrameworks)
    {
        listFrameworks();
        return;
    }

    var destination = options.args[0];

    if (!destination)
    {
        if (options.justFrameworks)
            destination = ".";

        else
        {
            parser.printUsage(options);
            process.exit(1);
        }
    }
    var sourceTemplate = null;

    if (node_path.isAbsolute(options.template))
        sourceTemplate = options.template;
    else
        sourceTemplate = node_path.join(templatesDirectory, options.template);

    if (!fs.lstatSync(sourceTemplate).isDirectory())
    {
        stream.print(colorize("Error: ", "red") + "The template " + logPath(sourceTemplate) + " cannot be found. Available templates are:");
        listTemplates();
        process.exit(1);
    }

    var configFile = node_path.join(sourceTemplate, "template.config"),
        config = {};

    if (fs.existsSync(configFile))
        config = JSON.parse(fs.readFileSync(configFile, { encoding: "utf8" }));
        //config = JSON.parse(FILE.read(configFile, { charset:"UTF-8" }));

    var destinationProject = destination,
        configuration = options.noconfig ? [Configuration defaultConfiguration] : [Configuration userConfiguration],
        frameworks = options.frameworks,
        themes = options.themes;


    if (!options.noFrameworks)
        frameworks.push("Objective-J", "Foundation", "AppKit");


    if (options.justFrameworks)
    {
        createFrameworksInFile(frameworks, destinationProject, options.symlink, options.useCappBuild, options.force);
        createThemesInFile(themes, destinationProject, options.symlink, options.force);
    }
    else if (!fs.existsSync(destinationProject))
    {
        utilsFile.copyRecursiveSync(sourceTemplate, destinationProject);

        var files = (new ObjectiveJ.utils.filelist.FileList(node_path.join(destinationProject, "**", "*"))).toArray(),
            count = files.length,
            name = node_path.basename(destinationProject),
            orgIdentifier = [configuration valueForKey:@"organization.identifier"] || "";

        [configuration setTemporaryValue:name forKey:@"project.name"];
        [configuration setTemporaryValue:orgIdentifier + '.' +  toIdentifier(name) forKey:@"project.identifier"];
        [configuration setTemporaryValue:toIdentifier(name) forKey:@"project.nameasidentifier"];

        for (var index = 0; index < count; ++index)
        {
            var path = files[index];

            if (fs.lstatSync(path).isDirectory())
                continue;

            if (node_path.basename(path) === ".DS_Store")
                continue;

            // Don't do this for images.
            if ([".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"].indexOf(node_path.extname(path).toLowerCase()) !== -1)
                continue;

            try
            {
                var contents = fs.readFileSync(path, { encoding: "utf8" }),
                //var contents = FILE.read(path, { charset : "UTF-8" }),
                    key = null,
                    keyEnumerator = [configuration keyEnumerator];

                function escapeRegex(string) {
                    return string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
                }

                while ((key = [keyEnumerator nextObject]) !== nil)
                    contents = contents.replace(new RegExp("__" + escapeRegex(key) + "__", 'g'), [configuration valueForKey:key]);

                fs.writeFileSync(path, contents, { encoding: "utf8" });
                //FILE.write(path, contents, { charset: "UTF-8"});
            }
            catch (anException)
            {
                warn("An error occurred (" + anException.toString() + ") while applying the " + (options.noconfig ? "default" : "user") + " configuration to: " + logPath(path));
            }
        }

        var frameworkDestination = destinationProject;

        if (config.FrameworksPath)
            frameworkDestination = node_path.join(frameworkDestination, config.FrameworksPath);

        createFrameworksInFile(frameworks, frameworkDestination, options.symlink, options.useCappBuild);

        var themeDestination = destinationProject;

        if (themes.length)
            createThemesInFile(themes, themeDestination, options.symlink);
    }

    else
    {
        fail("The directory " + node_path.resolve(destinationProject) + " already exists.");
    }

    executePostInstallScript(destinationProject);
}

function createFrameworksInFile(/*Array*/ frameworks, /*String*/ aFile, /*Boolean*/ symlink, /*Boolean*/ build, /*Boolean*/ force)
{
    var destination = node_path.resolve(aFile);

    if (!fs.lstatSync(destination).isDirectory())
        fail("Cannot create Frameworks. The directory does not exist: " + destination);

    var destinationFrameworks = node_path.join(destination, "Frameworks"),
        destinationDebugFrameworks = node_path.join(destination, "Frameworks", "Debug");

    stream.print("Creating Frameworks directory in " + logPath(destinationFrameworks) + "...");

    fs.mkdirSync(destinationDebugFrameworks, { recursive: true });

    if (build)
    {
        if (!(process.env["CAPP_BUILD"]))
            fail("$CAPP_BUILD must be defined to use the --build or -l option.");

        var builtFrameworks = process.env["CAPP_BUILD"],
            sourceFrameworks = node_path.join(builtFrameworks, "Release"),
            sourceDebugFrameworks = node_path.join(builtFrameworks, "Debug");

        frameworks.forEach(function(framework)
        {
            installFramework(node_path.join(sourceFrameworks, framework), node_path.join(destinationFrameworks, framework), force, symlink);
            installFramework(node_path.join(sourceDebugFrameworks, framework), node_path.join(destinationDebugFrameworks, framework), force, symlink);
        });
    }
    else
    {
        // Frameworks. Search frameworks paths
        frameworks.forEach(function(framework) {
            var objjHome = ObjectiveJ.OBJJ_HOME;
            // Need a special case for Objective-J
            if (framework === "Objective-J"){
                // Objective-J. Take from OBJJ_HOME.
                var objjPath = node_path.join(objjHome, "..", "objective-j", "Frameworks", "Objective-J");
                var objjDebugPath = node_path.join(objjHome, "..", "objective-j", "Frameworks", "Debug", "Objective-J");

                installFramework(objjPath, node_path.join(destinationFrameworks, "Objective-J"), force, symlink);
                installFramework(objjDebugPath, node_path.join(destinationDebugFrameworks, "Objective-J"), force, symlink);

                return;
            }

            var frameworkPath = node_path.join(objjHome, "Frameworks", framework);
            installFramework(frameworkPath, node_path.join(destinationFrameworks, framework), force, symlink);

            var frameworkDebugPath = node_path.join(objjHome, "Frameworks", "Debug", framework);
            installFramework(frameworkDebugPath, node_path.join(destinationDebugFrameworks, framework), force, symlink);

/*             if (!found)
                warn("Couldn't find the framework: " + logPath(framework));


            if (!found)
                warn("Couldn't find the debug framework: " + logPath(framework)); */
        });
    }
}

function installFramework(source, dest, force, symlink)
{
    if (fs.existsSync(dest)){
        if (force) {
            fs.rmSync(dest, { recursive: true });
        } else {
            warn(logPath(dest) + " already exists. Use --force to overwrite.");
            return;
        }
    }

    if (fs.existsSync(source)) {
        stream.print((symlink ? "Symlinking " : "Copying ") + logPath(source) + " ==> " + logPath(dest));
        if (symlink) {
            fs.symlinkSync(source, dest);
        } else {
            utilsFile.copyRecursiveSync(source, dest);
        }
    } else {
        warn("Cannot find: " + logPath(source));
    }
}

function createThemesInFile(/*Array*/ themes, /*String*/ aFile, /*Boolean*/ symlink, /*Boolean*/ force)
{
    var destination = node_path.resolve(aFile);

    if (!fs.lstatSync(destination).isDirectory())
        fail("Cannot create Themes. The directory does not exist: " + destination);

    var destinationThemes = node_path.join(destination, "Resources");

    stream.print("Creating Themes in " + logPath(destinationThemes) + "...");

    if (!(process.env["CAPP_BUILD"]))
        fail("$CAPP_BUILD must be defined to use the --theme or -T option.");

    var themesBuild = node_path.join(process.env["CAPP_BUILD"], "Release"),
        sources = [];

    themes.forEach(function(theme)
    {
        var themeFolder = theme + ".blend",
            path = node_path.join(themesBuild, themeFolder);
        if (!fs.lstatSync(path).isDirectory())
            fail("Cannot find theme " + themeFolder + " in " + themesBuild);

        sources.push([path, themeFolder])
    });

    sources.forEach(function(source)
    {
        installTheme(source[0], node_path.join(destinationThemes, source[1]), force, symlink);
    });
}

function installTheme(source, dest, force, symlink)
{
    if (fs.existsSync(dest))
    {
        if (force)
            fs.rmSync(dest, { recursive: true });

        else
        {
            warn(logPath(dest) + " already exists. Use --force to overwrite.");
            return;
        }
    }

    if (fs.existsSync(source))
    {
        stream.print((symlink ? "Symlinking " : "Copying ") + logPath(source) + " ==> " + logPath(dest));

        if (symlink)
            fs.symlinkSync(source, dest);
        else
            utilsFile.copyRecursiveSync(source, dest);
    }
    else
        warn("Cannot find: " + logPath(source));
}

function toIdentifier(/*String*/ aString)
{
    var identifier = "",
        count = aString.length,
        capitalize = NO,
        firstRegex = new RegExp("^[a-zA-Z_$]"),
        regex = new RegExp("^[a-zA-Z_$0-9]");

    for (var index = 0; index < count; ++index)
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

function listTemplates()
{
    fs.readdirSync(templatesDirectory).forEach(function(templateName)
    {
        stream.print(templateName);
    });
}

function listFrameworks()
{
    stream.print("Frameworks:");

    ObjectiveJ.objj_frameworks.forEach(function(frameworksDirectory)
    {
        stream.print("  " + frameworksDirectory);

        fs.readdirSync(frameworksDirectory).forEach(function(templateName)
        {
            stream.print("    + " + templateName);
        });
    });

    stream.print("Frameworks (Debug):");

    ObjectiveJ.objj_debug_frameworks.forEach(function(frameworksDirectory)
    {
        stream.print("  " + frameworksDirectory);

        fs.readdirSync(frameworksDirectory).forEach(function(frameworkName)
        {
            stream.print("    + " + frameworkName);
        });
    });
}

function executePostInstallScript(/*String*/ destinationProject)
{
    var path = node_path.join(destinationProject, "postinstall");

    if (fs.existsSync(path))
    {
        stream.print(colorize("Executing postinstall script...", "cyan"));
        child_process.execSync("/bin/sh" + " " + path + " " + destinationProject); // Use sh in case it isn't marked executable
        fs.rmSync(path);
    }
}

function colorize(message, color)
{
    return "\0" + color + "(" + message + "\0)";
}

function logPath(path)
{
    return colorize(path, "cyan");
}

function warn(message)
{
    stream.print(colorize("Warning: ", "yellow") + message);
}

function fail(message)
{
    stream.print(colorize(message, "red"));
    process.exit(1);
}
