
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

global.$CONFIGURATION               = ENV['CONFIG'];
global.$BUILD_DIR                   = ENV['BUILD_PATH'];
global.$COMMONJS_PRODUCT            = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "objective-j");
global.$COMMONJS_PRODUCT_BIN        = FILE.join($COMMONJS_PRODUCT, "bin");
global.$COMMONJS_PRODUCT_LIB        = FILE.join($COMMONJS_PRODUCT, "lib");
global.$COMMONJS_PRODUCT_FRAMEWORKS = FILE.join($COMMONJS_PRODUCT_LIB, "Frameworks");


global.$PRODUCT_DIR                = FILE.join($BUILD_DIR, $CONFIGURATION);
global.$ENVIRONMENT_DIR            = FILE.join($BUILD_DIR, $CONFIGURATION, 'env');
global.$ENVIRONMENT_NARWHAL_BIN_DIR= FILE.join($ENVIRONMENT_DIR, 'bin', '');
global.$ENVIRONMENT_BIN_DIR        = FILE.join($ENVIRONMENT_DIR, 'packages', 'objj', 'bin');
global.$ENVIRONMENT_LIB_DIR        = FILE.join($ENVIRONMENT_DIR, 'packages', 'objj', 'lib') ;
global.$ENVIRONMENT_FRAMEWORKS_DIR = FILE.join($ENVIRONMENT_LIB_DIR, 'Frameworks');

global.$HOME_DIR        = FILE.absolute(FILE.dirname(module.path));
global.$LICENSE_FILE    = FILE.absolute(FILE.join(FILE.dirname(module.path), 'LICENSE'));

var objectiveJLibJS = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "objective-j", "lib-js");

if (!FILE.exists(objectiveJLibJS))
    objectiveJLibJS = FILE.join($HOME_DIR, "Objective-J", "CommonJS", "objective-j", "lib-js");

require.paths.unshift(objectiveJLibJS);

require("objective-j/loader");

var OBJECTIVE_J_JAKE = require("objective-j/jake");

global.app = OBJECTIVE_J_JAKE.app;
global.bundle = OBJECTIVE_J_JAKE.bundle;
global.framework = OBJECTIVE_J_JAKE.framework;

if (OBJECTIVE_J_JAKE.blend)
    global.blend = OBJECTIVE_J_JAKE.blend;

global.BundleTask = OBJECTIVE_J_JAKE.BundleTask;

var objectiveJBin = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "objective-j", "bin")

if (!FILE.exists(objectiveJBin))
    objectiveJBin = FILE.join($HOME_DIR, "Objective-J", "CommonJS", "objective-j", "bin");

if (FILE.exists(objectiveJBin))
{
    var system = OS.system;

    // FIXME: is there a better way to do this???
    OS.system = function(aCommand)
    {
        system("PATH=" + OS.enquote(objectiveJBin) + ":$PATH " + aCommand)
    }
}

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
}

global.mv = function(/*String*/ from, /*String*/ to)
{
    FILE.move(from, to);
}

//require 'objective-j'

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
            OS.system("cd " + aDirectory + " && " + serializedENV() + " " + ARGV[0] + " " + aTaskName);
        //rake abort if ($? != 0)
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
        var subtaskName = taskNames + "_subprojects";

        task (aTaskName, [subtaskName]);

        task (subtaskName, function()
        {
            subjake(subprojects, aTaskName);
        });
    });
}
