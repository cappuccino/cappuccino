
var FILE = require("file");
var sprintf = require("printf").sprintf;

var window = exports.window = require("browser/window");

if (system.engine === "rhino")
{
    window.__parent__ = null;
    window.__proto__ = global;
}

// setup OBJJ_HOME, OBJJ_INCLUDE_PATHS, etc
window.OBJJ_HOME = exports.OBJJ_HOME = FILE.resolve(module.path, "..");

var frameworksPath = FILE.resolve(window.OBJJ_HOME, "Frameworks/");

var OBJJ_INCLUDE_PATHS = global.OBJJ_INCLUDE_PATHS = exports.OBJJ_INCLUDE_PATHS = [frameworksPath];

#include "Includes.js"

// Find all narwhal packages with Objective-J frameworks.
exports.objj_frameworks = [];
exports.objj_debug_frameworks = [];

var catalog = require("narwhal/packages").catalog;
for (var name in catalog)
{
    if (!catalog.hasOwnProperty(name))
        continue;

    var info = catalog[name];
    if (!info)
        continue;

    var frameworks = info["objj-frameworks"];
    if (frameworks) {
        if (!Array.isArray(frameworks))
            frameworks = [String(frameworks)];

        exports.objj_frameworks.push.apply(exports.objj_frameworks, frameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }

    var debugFrameworks = info["objj-debug-frameworks"];
    if (debugFrameworks) {
        if (!Array.isArray(debugFrameworks))
            debugFrameworks = [String(debugFrameworks)];

        exports.objj_debug_frameworks.push.apply(exports.objj_debug_frameworks, debugFrameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }
}

// push to the front of the array lowest priority first.
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_frameworks);
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_debug_frameworks);

if (system.env["OBJJ_INCLUDE_PATHS"])
    OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, system.env["OBJJ_INCLUDE_PATHS"].split(":"));

// bring the "window" object into scope.
// TODO: somehow make window object the top scope?
with (window)
{
// runs the objj repl or file provided in args
exports.run = function(args)
{
    var multipleFiles = false;

    if (args)
    {
        // we expect args to be in the format:
        //  1) "objj" path
        //  2) optional "-I" args
        //  3) real or "virtual" main.j
        //  4) optional program arguments

        // copy the args since we're going to modify them
        var argv = args.slice(1);

        if (argv[0] === "--version" || argv[0] === "-v")
        {
            print(exports.fullVersionString());
            return;
        }

        if (argv[0] === "--help" || argv[0] === "-h")
        {
            print("Usage (objj): " + args[0] + " [options] [--] files...");
            print("  -v, --version                  print the current version of objj");
            print("  -I, --objj-include-paths       include a specific framework paths")
            print("  -h, --help                     print this help");
            print("  -m, --multifiles               launch objj on several files")
            return;
        }

        while (argv.length && argv[0].indexOf('-') === 0)
        {
            switch (argv[0])
            {
                case "-I":
                    argv.shift();
                    OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, argv.shift().split(":"));
                    break;

                case "-m":
                    argv.shift();
                    multipleFiles = true;
                    break
            }
        }
    }

    if (argv && argv.length > 0)
    {
        var endCommand = false;

        while (argv.length > 0)
        {
            var arg0 = argv.shift();
            var mainFilePath = FILE.canonical(arg0);

            if (multipleFiles)
            {
                // This is needed to process every files passed in args
                // Otherwise it would stop when an error is raised or we would like to objj the other given files
                try
                {
                    exports.make_narwhal_factory(mainFilePath)(require, { }, module, system, print);
                }
                catch(e)
                {
                    print("\n" + e);
                }
            }
            else
            {
                exports.make_narwhal_factory(mainFilePath)(require, { }, module, system, print);
            }

            if (typeof main === "function")
            {
                main([arg0].concat(argv));
                endCommand = true;
            }

            require("browser/timeout").serviceTimeouts();

            if (!multipleFiles || endCommand)
                break;

            ObjectiveJ.Executable.resetCachedFileExecutableSearchers();
            ObjectiveJ.StaticResource.resetRootResources();
            ObjectiveJ.FileExecutable.resetFileExecutables();
            objj_resetRegisterClasses();
        }
    }
    else
    {
        exports.repl();
    }
}

exports.repl = function()
{
    var READLINE = require("readline");

    var historyPath = FILE.path(system.env["HOME"], ".objj_history");
    var historyFile = null;

    if (historyPath.exists() && READLINE.addHistory) {
        historyPath.read({ charset : "UTF-8" }).split("\n").forEach(function(line) {
            if (line.trim())
                READLINE.addHistory(line);
        });
    }

    try {
        historyFile = historyPath.open("a", { charset : "UTF-8" });
    } catch (e) {
        system.stderr.print("Warning: Can't open history file '"+historyFile+"' for writing.");
    }

    while (true)
    {
        try {
            system.stdout.write("objj> ").flush();

            var line = READLINE.readline();
            if (line && historyFile)
                historyFile.write(line).write("\n").flush();

            var result = exports.objj_eval(line);
            if (result !== undefined)
                print(result);

        } catch (e) {
            print(e);
        }

        require("browser/timeout").serviceTimeouts();
    }
};

// creates a narwhal factory function in the objj module scope
exports.make_narwhal_factory = function(path, basePath, filenameTranslateDictionary)
{
    return function(require, exports, module, system, print)
    {
        Executable.setCommonJSParameters("require", "exports", "module", "system", "print", "window");
        Executable.setCommonJSArguments(require, exports, module, system, print, window);
        filenameTranslateDictionary && Executable.setFilenameTranslateDictionary(filenameTranslateDictionary);
        Executable.fileImporterForURL(basePath ? basePath : FILE.dirname(path))(path, YES);
    }
};

} // end "with"

var pkg = null;
function getPackage() {
    if (!pkg)
        pkg = JSON.parse(FILE.path(module.path).dirname().dirname().join("package.json").read({ charset : "UTF-8" }));
    return pkg;
}

exports.version = function() { return getPackage()["version"]; }
exports.revision = function() { return getPackage()["cappuccino-revision"]; }
exports.timestamp = function() { return new Date(getPackage()["cappuccino-timestamp"]); }

exports.fullVersionString = function() {
    return sprintf("objective-j %s (%04d-%02d-%02d %s)",
        exports.version(),
        exports.timestamp().getUTCFullYear(),
        exports.timestamp().getUTCMonth()+1,
        exports.timestamp().getUTCDate(),
        exports.revision().slice(0,6)
    );
}

global.ObjectiveJ = {};

for (var key in exports)
    if (Object.prototype.hasOwnProperty.call(exports, key))
        global.ObjectiveJ[key] = exports[key];

if (require.main == module.id)
    exports.run(system.args);
