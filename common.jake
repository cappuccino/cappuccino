
function ensurePackageUpToDate(packageName, requiredVersion)
{
    var packageInfo = require("packages").catalog[packageName];
    if (!packageInfo)
    {
        print("You are missing package \"" + packageName + "\", version " + requiredVersion + " or later. Please install using \"tusk install "+packageName+"\" and re-run jake");
        require("os").exit(1);
    }

    // newer versions of packages provide already split versions
    var version = typeof packageInfo.version === "string" ? packageInfo.version.split(".") : packageInfo;

    if (typeof requiredVersion === "string")
        requiredVersion = requiredVersion.split(".");

    if (version && require("util").compare(version, requiredVersion) !== -1)
        return;

    print("Your copy of " + packageName + " is out of date (version " + version + "). Update? yes or no:");

    var response = system.stdin.readLine();

    if (response !== "yes\n")
    {
        print("Jake aborted.");
        require("os").exit(1);
    }

    require("os").system("NARWHAL_ENGINE_HOME='' NARWHAL_ENGINE=rhino tusk install --force " + packageName);
}

// UPDATE THESE TO PICK UP CORRESPONDING CHANGES IN DEPENDENCIES
ensurePackageUpToDate("jake", "0.1.2");
ensurePackageUpToDate("browserjs", "0.1.1");

var Jake = require("jake");

global.ENV  = require("system").env;
global.ARGV = require("system").args
global.FILE = require("file");
global.OS   = require("os");

global.task = Jake.task;
global.directory = Jake.directory;
//global.file = Jake.file;
global.filedir = Jake.filedir;
global.FileList = Jake.FileList;

global.CLEAN = require("jake/clean").CLEAN;
global.CLOBBER = require("jake/clean").CLOBBER;


// Read in and set up development environment variables.
if (!ENV["BUILD_PATH"])
{
    // Global Cappuccino build directory
    if (ENV["CAPP_BUILD"])
        ENV["BUILD_PATH"] = ENV["CAPP_BUILD"];

    // Maintain backwards compatibility with steam.
    else if(ENV["STEAM_BUILD"])
        ENV["BUILD_PATH"] = ENV["STEAM_BUILD"];

    // Just build here.
    else 
        ENV["BUILD_PATH"] = FILE.join(FILE.dirname(module.path), 'Build');
}

ENV["BUILD_PATH"] = FILE.absolute(ENV["BUILD_PATH"]);

if (!ENV["CONFIG"])
    ENV["CONFIG"] = "Release";

global.$CONFIGURATION                   = ENV['CONFIG'];
global.$BUILD_DIR                       = ENV['BUILD_PATH'];
global.$BUILD_CONFIGURATION_DIR         = FILE.join($BUILD_DIR, $CONFIGURATION);

global.$BUILD_CJS_OBJECTIVE_J           = FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "objective-j");

global.$BUILD_CJS_CAPPUCCINO            = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "cappuccino");
global.$BUILD_CJS_CAPPUCCINO_BIN        = FILE.join($BUILD_CJS_CAPPUCCINO, "bin");
global.$BUILD_CJS_CAPPUCCINO_LIB        = FILE.join($BUILD_CJS_CAPPUCCINO, "lib");
global.$BUILD_CJS_CAPPUCCINO_FRAMEWORKS = FILE.join($BUILD_CJS_CAPPUCCINO, "Frameworks");

global.$HOME_DIR        = FILE.absolute(FILE.dirname(module.path));
global.$LICENSE_FILE    = FILE.absolute(FILE.join(FILE.dirname(module.path), 'LICENSE'));

function partial_require(path, exports)
{
    var lib = FILE.join(path, "lib");

    if (!FILE.exists(lib))
        return false;

    require.paths.unshift(lib);

    if (FILE.exists(FILE.join(path, "package.json")))
    {
        var catalog = require("json").parse(FILE.read(FILE.join(path, "package.json"), { charset:"UTF8" }));

        if (catalog.preload)
        {
            if (!Array.isArray(catalog.preload))
                catalog.preload = [catalog.preload];

            catalog.preload.forEach(function(preload)
            {
                require(preload);
            });
        }
    }

    var bin = FILE.join(path, "bin"),
        system = OS.system;

    // FIXME: is there a better way to do this???
    OS.system = function(aCommand)
    {
        if (Array.isArray(aCommand))
            aCommand = aCommand.map(OS.enquote).join(" ");
        
        return system("PATH=" + OS.enquote(bin) + ":$PATH " + aCommand);
    }

    return true;
}

global.setupEnvironment = function()
{
    if (partial_require(FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "objective-j")) ||
        partial_require(FILE.join($HOME_DIR, "Objective-J", "CommonJS")))
    {
        var OBJECTIVE_J_JAKE = require("objective-j/jake");

        global.app = OBJECTIVE_J_JAKE.app;
        global.bundle = OBJECTIVE_J_JAKE.bundle;
        global.framework = OBJECTIVE_J_JAKE.framework;

        global.BundleTask = OBJECTIVE_J_JAKE.BundleTask;
    }

    if (partial_require(FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino")))
    {
        require("objective-j");
        require("browser/window").OBJJ_INCLUDE_PATHS.push(FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino", "Frameworks"));

        try
        {
            var CAPPUCCINO_JAKE = require("cappuccino/jake");

            if (CAPPUCCINO_JAKE.blend)
                global.blend = CAPPUCCINO_JAKE.blend;
        }
        catch (anException)
        {
        }
    }
}

setupEnvironment();

global.rm_rf = function(/*String*/ aFilename)
{
    try { FILE.rmtree(aFilename); }
    catch (anException) { }
}

global.cp_r = function(/*String*/ from, /*String*/ to)
{
    if (FILE.exists(to))
        rm_rf(to);

    if (FILE.isDirectory(from))
        FILE.copyTree(from, to);
    else{try{
        FILE.copy(from, to);}catch(e) { print(e + FILE.exists(from) + " " + FILE.exists(FILE.dirname(to))); }}
}

global.cp = function(/*String*/ from, /*String*/ to)
{
    FILE.copy(from, to);
//    FILE.chmod(to, FILE.mod(from));  
}

global.mv = function(/*String*/ from, /*String*/ to)
{
    FILE.move(from, to);
}

function serializedENV()
{
    var serialized = "";

    if (ENV["CONFIG"])
        serialized += "CONFIG=\"" + ENV["CONFIG"] + "\"";

    if (ENV["BUILD_DIR"])
        serialized += "BUILD_DIR=\"" + ENV["BUILD_DIR"] + "\"";

    return serialized;
}

global.subjake = function(/*Array<String>*/ directories, /*String*/ aTaskName)
{
    if (!Array.isArray(directories))
        directories = [directories];

    directories.forEach(function(/*String*/ aDirectory)
    {
        if (FILE.isDirectory(aDirectory) && FILE.isFile(FILE.join(aDirectory, "Jakefile")))
        {
            var returnCode = OS.system("cd " + aDirectory + " && " + serializedENV() + " " + ARGV[0] + " " + aTaskName);
            if (returnCode)
                OS.exit(returnCode);
        }
        else
            print("warning: subjake missing: " + aDirectory + " (this is not necessarily an error, " + aDirectory + " may be optional)");
    });
}

global.executableExists = function(/*String*/ aFileName)
{
    return ENV["PATH"].split(':').some(function(/*String*/ aPath)
    {
        return FILE.exists(FILE.join(aPath, aFileName));
    });
}

$OBJJ_TEMPLATE_EXECUTABLE   = FILE.join($HOME_DIR, "Objective-J", "CommonJS", "objj-executable");

global.make_objj_executable = function(aPath)
{
    cp($OBJJ_TEMPLATE_EXECUTABLE, aPath);
    FILE.chmod(aPath, 0755);
}

global.symlink_executable = function(source)
{
    relative = FILE.relative($ENVIRONMENT_NARWHAL_BIN_DIR, source);
    destination = FILE.join($ENVIRONMENT_NARWHAL_BIN_DIR, FILE.basename(source));
    FILE.symlink(relative, destination);
}

task ("build");
task ("default", "build");

task ("release", function()
{
    ENV["CONFIG"] = "Release";
    spawnJake("build");
});

task ("debug", function()
{
    ENV["CONFIG"] = "Debug";
    spawnJake("build");
});

task ("all", ["debug", "release"]);

task ("clean-debug", function()
{
    ENV['CONFIG'] = 'Debug'
    spawnJake("clean");
});

task ("cleandebug", ["clean-debug"]);

task ("clean-release", function()
{
    ENV["CONFIG"] = "Release";
    spawnJake("clean");
});

task ("cleanrelease", ["clean-release"]);

task ("clean-all", ["clean-debug", "clean-release"]);
task ("cleanall", ["clean-all"]);

task ("clobber-debug", function()
{
    ENV["CONFIG"] = "Debug";
    spawnJake("clobber");
});

task ("clobberdebug", ["clobber-debug"]);

task ("clobber-release", function()
{
    ENV["CONFIG"] = "Release";
    spawnJake("clobber");
});

task ("clobberrelease", ['clobber-release']);

task ("clobber-all", ["clobber-debug", "clobber-release"]);
task ("clobberall", ["clobber-all"]);

function spawnJake(/*String*/ aTaskName)
{
    if (OS.system(serializedENV() + " " + ARGV[0] + " " + aTaskName))
        OS.exit(1);//rake abort if ($? != 0)
}

global.subtasks = function(subprojects, taskNames)
{
    taskNames.forEach(function(aTaskName)
    {
        var subtaskName = aTaskName + "_subprojects";

        task (aTaskName, [subtaskName]);

        task (subtaskName, function()
        {
            subjake(subprojects, aTaskName);
        });
    });
}
