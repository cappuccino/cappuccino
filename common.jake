var SYSTEM = require("system");
var FILE = require("file");
var OS = require("os");
var UTIL = require("util");

function ensurePackageUpToDate(packageName, requiredVersion, options)
{
    options = options || {};
    
    var packageInfo = require("packages").catalog[packageName];
    if (!packageInfo)
    {
        print("You are missing package \"" + packageName + "\", version " + requiredVersion + " or later. Please install using \"tusk install "+packageName+"\" and re-run jake");
        OS.exit(1);
    }

    var version = packageInfo.version;
    if (typeof version === "string")
        version = version.split(".");
        
    if (typeof requiredVersion === "string")
        requiredVersion = requiredVersion.split(".");

    if (version && UTIL.compare(version, requiredVersion) !== -1)
        return;

    print("Your copy of " + packageName + " is out of date (" + (version||["0"]).join(".") + " installed, " + requiredVersion.join(".") + " required).");

    if (!options.noupdate)
    {
        print("Update? yes or no:");
        if (system.stdin.readLine() !== "yes\n")
        {
            print("Jake aborted.");
            OS.exit(1);
        }
        OS.system(["tusk", "install", "--force", packageName]);
    }
    
    if (options.message)
    {
        print(options.message)
        OS.exit(1);
    }
}

// UPDATE THESE TO PICK UP CORRESPONDING CHANGES IN DEPENDENCIES
ensurePackageUpToDate("jake",           "0.1.2");
ensurePackageUpToDate("browserjs",      "0.1.1");
ensurePackageUpToDate("narwhal",        "0.2.1", {
    noupdate : true,
    message : "Update Narwhal to 0.2.1 by running bootstrap.sh, or pulling the latest from git (see: http://github.com/280north/narwhal)."
});
ensurePackageUpToDate("narwhal-jsc",    "0.1.1", {
    message : "Rebuild narwhal-jsc by changing to the narwhal-jsc package directory and running \"make webkit\"."
});

var JAKE = require("jake");

// Set up development environment variables.

// record the initial SYSTEM.env so we know which need to be serialized later
var envInitial = Object.freeze(UTIL.copy(SYSTEM.env));

SYSTEM.env["BUILD_PATH"] = FILE.absolute(
    SYSTEM.env["BUILD_PATH"] ||
    SYSTEM.env["CAPP_BUILD"] || // Global Cappuccino build directory.
    SYSTEM.env["STEAM_BUILD"] || // Maintain backwards compatibility with steam.
    FILE.join(FILE.dirname(module.path), "Build") // Just build here.
);

if (!SYSTEM.env["CAPP_BUILD"] && SYSTEM.env["STEAM_BUILD"])
    system.stderr.print("STEAM_BUILD environment variable is deprecated; Please use CAPP_BUILD instead.");

if (!SYSTEM.env["CONFIG"])
    SYSTEM.env["CONFIG"] = "Release";

// TODO: deprecate these globals
global.ENV  = SYSTEM.env;
global.ARGV = SYSTEM.args
global.FILE = FILE;
global.OS   = OS;

global.task = JAKE.task;
global.directory = JAKE.directory;
//global.file = JAKE.file;
global.filedir = JAKE.filedir;
global.FileList = JAKE.FileList;

global.CLEAN = require("jake/clean").CLEAN;
global.CLOBBER = require("jake/clean").CLOBBER;

global.$CONFIGURATION                   = SYSTEM.env['CONFIG'];
global.$BUILD_DIR                       = SYSTEM.env['BUILD_PATH'];
global.$BUILD_CONFIGURATION_DIR         = FILE.join($BUILD_DIR, $CONFIGURATION);

global.$BUILD_CJS_OBJECTIVE_J           = FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "objective-j");

global.$BUILD_CJS_CAPPUCCINO            = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "cappuccino");
global.$BUILD_CJS_CAPPUCCINO_BIN        = FILE.join($BUILD_CJS_CAPPUCCINO, "bin");
global.$BUILD_CJS_CAPPUCCINO_LIB        = FILE.join($BUILD_CJS_CAPPUCCINO, "lib");
global.$BUILD_CJS_CAPPUCCINO_FRAMEWORKS = FILE.join($BUILD_CJS_CAPPUCCINO, "Frameworks");

global.$HOME_DIR        = FILE.absolute(FILE.dirname(module.path));
global.$LICENSE_FILE    = FILE.absolute(FILE.join(FILE.dirname(module.path), 'LICENSE'));


// logic to determine which packages should be loaded but are not.
// used in serializedENV()
function additionalPackages()
{
    var unbuiltObjectiveJPackage = FILE.path($HOME_DIR).join("Objective-J", "CommonJS", "");
    var builtObjectiveJPackage = FILE.path($BUILD_CONFIGURATION_DIR).join("CommonJS", "objective-j", "");
    var builtCappuccinoPackage = FILE.path($BUILD_CONFIGURATION_DIR).join("CommonJS", "cappuccino", "");
    
    var packages = [];
    
    // load built objective-j if exists, otherwise unbuilt
    // FIXME: this isn't quite correct. sometimes we want the unbuilt one to have priority.
    if (builtObjectiveJPackage.join("package.json").exists()) {
        if (!packageInCatalog(builtObjectiveJPackage))
            packages.push(builtObjectiveJPackage);
    } else {
        if (!packageInCatalog(unbuiltObjectiveJPackage))
            packages.push(unbuiltObjectiveJPackage);
    }
    
    // load built cappuccino if it exists
    if (builtCappuccinoPackage.join("package.json").exists()) {
        if (!packageInCatalog(builtCappuccinoPackage))
            packages.push(builtCappuccinoPackage);
    }
    
    return packages;
}

// checks to see if a path is in the package catalog
function packageInCatalog(path)
{
    var catalog = require("packages").catalog;
    for (var name in catalog)
        if (String(catalog[name].directory) === String(path))
            return true;
    return false;
}

function serializedENV()
{
    var envNew = {};
    
    // add changed keys to the new ENV
    Object.keys(SYSTEM.env).forEach(function(key) {
        if (SYSTEM.env[key] !== envInitial[key])
            envNew[key] = SYSTEM.env[key];
    });

    // pseudo-HACK: add NARWHALOPT with packages we should ensure are loaded
    var packages = additionalPackages();
    if (packages.length)
        envNew["NARWHALOPT"] = packages.map(function(p) { return "-p " + p; }).join(" ");

    return Object.keys(envNew).map(function(key) {
        return key + "=" + OS.enquote(envNew[key]);
    }).join(" ");
}

function reforkWithPackages()
{
    if (additionalPackages().length > 0) {
        var cmd = serializedENV() + " " + system.args.map(OS.enquote).join(" ");
        //print("REFORKING: " + cmd);
        OS.exit(OS.system(cmd));
    }
}

reforkWithPackages();

function setupEnvironment()
{
    // TODO: deprecate these globals
    try {
        var OBJECTIVE_J_JAKE = require("objective-j/jake");
        
        global.app = OBJECTIVE_J_JAKE.app;
        global.bundle = OBJECTIVE_J_JAKE.bundle;
        global.framework = OBJECTIVE_J_JAKE.framework;

        global.BundleTask = OBJECTIVE_J_JAKE.BundleTask;
    } catch (e) {
        //print("setupEnvironment (app, bundle, framework, BundleTask): " + e);
    }
    
    try {
        require("objective-j").OBJJ_INCLUDE_PATHS.push(FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino", "Frameworks"));
    } catch (e) {
        //print("setupEnvironment (OBJJ_INCLUDE_PATHS): " + e);
    }
    
    try {
        var CAPPUCCINO_JAKE = require("cappuccino/jake");
        if (CAPPUCCINO_JAKE.blend)
            global.blend = CAPPUCCINO_JAKE.blend;
        //else
        //    print("no blend!")
    }
    catch (e) {
        //print("setupEnvironment (blend): " + e);
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

global.subjake = function(/*Array<String>*/ directories, /*String*/ aTaskName)
{
    if (!Array.isArray(directories))
        directories = [directories];

    directories.forEach(function(/*String*/ aDirectory)
    {
        if (FILE.isDirectory(aDirectory) && FILE.isFile(FILE.join(aDirectory, "Jakefile")))
        {
            var returnCode = OS.system("cd " + aDirectory + " && " + serializedENV() + " " + SYSTEM.args[0] + " " + aTaskName);
            if (returnCode)
                OS.exit(returnCode);
        }
        else
            print("warning: subjake missing: " + aDirectory + " (this is not necessarily an error, " + aDirectory + " may be optional)");
    });
}

global.executableExists = function(/*String*/ aFileName)
{
    return SYSTEM.env["PATH"].split(':').some(function(/*String*/ aPath)
    {
        return FILE.exists(FILE.join(aPath, aFileName));
    });
}

$OBJJ_TEMPLATE_EXECUTABLE = FILE.join($HOME_DIR, "Objective-J", "CommonJS", "objj-executable");

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

function spawnJake(/*String*/ aTaskName)
{
    if (OS.system(serializedENV() + " " + SYSTEM.args[0] + " " + aTaskName))
        OS.exit(1);//rake abort if ($? != 0)
}

// built in tasks

task ("build");
task ("default", "build");

task ("release", function()
{
    SYSTEM.env["CONFIG"] = "Release";
    spawnJake("build");
});

task ("debug", function()
{
    SYSTEM.env["CONFIG"] = "Debug";
    spawnJake("build");
});

task ("all", ["debug", "release"]);

task ("clean-debug", function()
{
    SYSTEM.env['CONFIG'] = 'Debug'
    spawnJake("clean");
});

task ("cleandebug", ["clean-debug"]);

task ("clean-release", function()
{
    SYSTEM.env["CONFIG"] = "Release";
    spawnJake("clean");
});

task ("cleanrelease", ["clean-release"]);

task ("clean-all", ["clean-debug", "clean-release"]);
task ("cleanall", ["clean-all"]);

task ("clobber-debug", function()
{
    SYSTEM.env["CONFIG"] = "Debug";
    spawnJake("clobber");
});

task ("clobberdebug", ["clobber-debug"]);

task ("clobber-release", function()
{
    SYSTEM.env["CONFIG"] = "Release";
    spawnJake("clobber");
});

task ("clobberrelease", ['clobber-release']);

task ("clobber-all", ["clobber-debug", "clobber-release"]);
task ("clobberall", ["clobber-all"]);
