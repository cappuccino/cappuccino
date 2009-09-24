
var ENV = require("system").env,
    ARGV = require("system").args,
    FILE = require("file"),
    OS = require("os"),
    
    Jake = require("jake");

global.task = Jake.task;
global.directory = Jake.directory;
//global.file = Jake.file;
global.filedir = Jake.filedir;

/*
def gem_command
    case RUBY_PLATFORM
    when /win32/
        'gem.bat'
    when /java/
        'jruby -S gem'
    else
        'gem'
    end
end

begin
    require 'rubygems'
    require 'plist'
rescue LoadError
    puts 'Plist gem not installed, installing...'
    cmd = "#{gem_command} install plist"
    puts cmd
    puts %x(#{cmd})
end
*/
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

global.$CONFIGURATION              = ENV['CONFIG'];
global.$BUILD_DIR                  = ENV['BUILD_PATH'];
global.$PRODUCT_DIR                = FILE.join($BUILD_DIR, $CONFIGURATION);
global.$ENVIRONMENT_DIR            = FILE.join($BUILD_DIR, $CONFIGURATION, 'env');
global.$ENVIRONMENT_NARWHAL_BIN_DIR= FILE.join($ENVIRONMENT_DIR, 'bin', '');
global.$ENVIRONMENT_BIN_DIR        = FILE.join($ENVIRONMENT_DIR, 'packages', 'objj', 'bin');
global.$ENVIRONMENT_LIB_DIR        = FILE.join($ENVIRONMENT_DIR, 'packages', 'objj', 'lib') ;
global.$ENVIRONMENT_FRAMEWORKS_DIR = FILE.join($ENVIRONMENT_LIB_DIR, 'Frameworks');

global.$HOME_DIR        = FILE.absolute(FILE.dirname(module.path));
global.$LICENSE_FILE    = FILE.absolute(FILE.join(FILE.dirname(module.path), 'LICENSE'));

var objectiveJLibJS = FILE.join($BUILD_DIR, $CONFIGURATION, "CommonJS", "objective-j", "lib-js");

if (FILE.exists(objectiveJLibJS))
{
    require.paths.unshift(objectiveJLibJS);

    var OBJECTIVE_J_JAKE = require("objective-j/jake");

    global.bundle = OBJECTIVE_J_JAKE.bundle;
    global.framework = OBJECTIVE_J_JAKE.framework;
    global.BundleTask = OBJECTIVE_J_JAKE.BundleTask;
}

global.rm_rf = function(/*String*/ aFilename)
{
    try { FILE.rmtree(aFilename); }
    catch (anException) { }
}

global.cp_r = function(/*String*/ from, /*String*/ to)
{
    FILE.copyTree(from, to);
}

global.cp = function(/*String*/ from, /*String*/ to)
{
    FILE.copy(from, to);
}

if(!global.COMMON_DO_ONCE)
{
    COMMON_DO_ONCE = true
    
//    $LOAD_PATH << File.join($HOME_DIR, 'Tools', 'Rake', 'lib')
    ENV["PATH"] = $ENVIRONMENT_NARWHAL_BIN_DIR + ":" + ENV["PATH"];
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

$OBJJ_TEMPLATE_EXECUTABLE   = FILE.join($HOME_DIR, 'Tools', 'Rake', 'lib', 'objj-executable')
/*
def make_objj_executable(path)
    cp($OBJJ_TEMPLATE_EXECUTABLE, path)
    File.chmod(0755, path)
    symlink_executable(path)
end
*/
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
    OS.system(serializedENV() + " " + ARGV[0] + " " + aTaskName);
    //system %{#{$serialized_env} #{$0} #{task_name}}
    //rake abort if ($? != 0)
}
