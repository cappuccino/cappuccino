/*
 * command.jake
 * toolchain
 *
 * Copyright 2012 The Cappuccino Foundation
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

var SYSTEM = require("system"),
    FILE = require("file"),
    OS = require("os"),
    UTIL = require("narwhal/util"),
    stream = require("narwhal/term").stream,

    requiresSudo = false;

SYSTEM.args.slice(1).forEach(function(arg)
{
    if (arg === "sudo-install")
        requiresSudo = true;
});

function ensurePackageUpToDate(packageName, requiredVersion, options)
{
    options = options || {};

    var packageInfo = require("narwhal/packages").catalog[packageName];
    if (!packageInfo)
    {
        if (options.optional)
            return;

        print("You are missing package \"" + packageName + "\", version " + requiredVersion + " or later. Please install using \"tusk install "+ packageName +"\" and re-run jake");
        OS.exit(1);
    }

    var version = packageInfo.version;
    if (typeof version === "string")
        version = version.split(".");

    if (typeof requiredVersion === "string")
        requiredVersion = requiredVersion.split(".");

    if (version && UTIL.compare(version, requiredVersion) !== -1)
        return;

    print("Your copy of " + packageName + " is out of date (" + (version || ["0"]).join(".") + " installed, " + requiredVersion.join(".") + " required).");

    if (!options.noupdate)
    {
        print("Update? Existing package will be overwritten. yes or no:");

        if (!SYSTEM.env["CAPP_AUTO_UPGRADE"] && system.stdin.readLine() !== "yes\n")
        {
            print("Jake aborted.");
            OS.exit(1);
        }

        if (requiresSudo)
        {
            if (OS.system(["sudo", "tusk", "install", "--force", packageName]))
            {
                // Attempt a hackish work-around for sudo compiled with the --with-secure-path option
                if (OS.system("sudo bash -c 'source " + getShellConfigFile() + "; tusk install --force "+ packageName))
                    OS.exit(1); //rake abort if ($? != 0)
            }
        }
        else
            OS.system(["tusk", "install", "--force", packageName]);
    }

    if (options.after)
    {
        options.after(packageInfo.directory);
    }

    if (options.message)
    {
        print(options.message);
        OS.exit(1);
    }
}

// UPDATE THESE TO PICK UP CORRESPONDING CHANGES IN DEPENDENCIES
ensurePackageUpToDate("jake",           "0.3");
ensurePackageUpToDate("browserjs",      "0.1.1");
ensurePackageUpToDate("shrinksafe",     "0.2");
ensurePackageUpToDate("narwhal",        "0.3.1", {
    noupdate : true,
    message : "Update Narwhal by re-running bootstrap.sh, or pulling the latest from git (see: http://github.com/280north/narwhal)."
});
ensurePackageUpToDate("narwhal-jsc",    "0.3", {
    optional : true,
    after : function(dir) {
        if (OS.system("cd " + OS.enquote(dir) + " && make webkit")) {
            print("Problem building narwhal-jsc.");
            OS.exit(1);
        }
    }
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

global.ENV  = SYSTEM.env;
global.ARGV = SYSTEM.args;
global.FILE = FILE;
global.OS   = OS;

global.task = JAKE.task;
global.directory = JAKE.directory;
global.file = JAKE.file;
global.filedir = JAKE.filedir;
global.FileList = JAKE.FileList;

global.$CONFIGURATION                   = SYSTEM.env['CONFIG'];
global.$BUILD_DIR                       = SYSTEM.env['BUILD_PATH'];
global.$BUILD_CONFIGURATION_DIR         = FILE.join($BUILD_DIR, $CONFIGURATION);

global.$BUILD_CJS_OBJECTIVE_J           = FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "objective-j");

global.$BUILD_CJS_CAPPUCCINO            = FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino");
global.$BUILD_CJS_CAPPUCCINO_BIN        = FILE.join($BUILD_CJS_CAPPUCCINO, "bin");
global.$BUILD_CJS_CAPPUCCINO_LIB        = FILE.join($BUILD_CJS_CAPPUCCINO, "lib");
global.$BUILD_CJS_CAPPUCCINO_FRAMEWORKS = FILE.join($BUILD_CJS_CAPPUCCINO, "Frameworks");

global.CLEAN = require("jake/clean").CLEAN;
global.CLOBBER = require("jake/clean").CLOBBER;
global.CLEAN.include(FILE.join(global.$BUILD_DIR, "*.build"));
global.CLOBBER.include(global.$BUILD_DIR);

global.$HOME_DIR        = FILE.absolute(FILE.dirname(module.path));
global.$LICENSE_FILE    = FILE.absolute(FILE.join(FILE.dirname(module.path), 'LICENSE'));

global.FIXME_fileDependency = function(destinationPath, sourcePath)
{
    file(destinationPath, [sourcePath], function()
    {
        FILE.touch(destinationPath);
    });
};

// logic to determine which packages should be loaded but are not.
// used in serializedENV()
function additionalPackages()
{
    var builtObjectiveJPackage = FILE.path($BUILD_CONFIGURATION_DIR).join("CommonJS", "objective-j", "");
    var builtCappuccinoPackage = FILE.path($BUILD_CONFIGURATION_DIR).join("CommonJS", "cappuccino", "");

    var packages = [];

    // load built objective-j if exists, otherwise unbuilt
    if (builtObjectiveJPackage.join("package.json").exists()) {
        if (!packageInCatalog(builtObjectiveJPackage))
            packages.push(builtObjectiveJPackage);
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
    var catalog = require("narwhal/packages").catalog;
    for (var name in catalog)
        if (String(catalog[name].directory) === String(path))
            return true;
    return false;
}

serializedENV = function()
{
    var envNew = {};

    // add changed keys to the new ENV
    Object.keys(SYSTEM.env).forEach(function(key)
    {
        if (SYSTEM.env[key] !== envInitial[key])
            envNew[key] = SYSTEM.env[key];
    });

    // pseudo-HACK: add NARWHALOPT with packages we should ensure are loaded
    var packages = additionalPackages();

    if (packages.length)
    {
        envNew["NARWHALOPT"] = packages.map(function(p) { return "-p " + OS.enquote(p); }).join(" ");
        envNew["PATH"] = packages.map(function(p) { return FILE.join(p, "bin"); }).concat(SYSTEM.env["PATH"]).join(":");
    }

    return Object.keys(envNew).map(function(key)
    {
        return key + "=" + OS.enquote(envNew[key]);
    }).join(" ");
};

function getShellConfigFile()
{
    var homeDir = SYSTEM.env["HOME"] + "/";
    // use order outlined by http://hayne.net/MacDev/Notes/unixFAQ.html#shellStartup
    var possibilities = [homeDir + ".bash_profile",
                         homeDir + ".bash_login",
                         homeDir + ".profile",
                         homeDir + ".bashrc"];

    for (var i = 0; i < possibilities.length; i++)
    {
        if (FILE.exists(possibilities[i]))
            return possibilities[i];
    }
}

function reforkWithPackages()
{
    if (additionalPackages().length > 0)
    {
        var cmd = serializedENV() + " " + system.args.map(OS.enquote).join(" ");
        //print("REFORKING: " + cmd);
        OS.exit(OS.system(cmd));
    }
}

reforkWithPackages();

function handleSetupEnvironmentError(e)
{
    if (String(e).indexOf("require error") == -1)
    {
        print("setupEnvironment warning: " + e);
        //throw e;
    }
}

function setupEnvironment()
{
    try
    {
        require("objective-j").OBJJ_INCLUDE_PATHS.push(FILE.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino", "Frameworks"));
    }
    catch (e)
    {
        handleSetupEnvironmentError(e);
    }
}

setupEnvironment();

global.rm_rf = function(/*String*/ aFilename)
{
    try { FILE.rmtree(aFilename); }
    catch (anException) { }
};

global.cp_r = function(/*String*/ from, /*String*/ to)
{
    if (FILE.exists(to))
        rm_rf(to);

    if (FILE.isDirectory(from))
        FILE.copyTree(from, to);
    else
    {
        try
        {
            FILE.copy(from, to);
        }
        catch (e)
        {
            print(e + FILE.exists(from) + " " + FILE.exists(FILE.dirname(to)));
        }
    }
};

global.cp = function(/*String*/ from, /*String*/ to)
{
    FILE.copy(from, to);
//    FILE.chmod(to, FILE.mod(from));
};

global.mv = function(/*String*/ from, /*String*/ to)
{
    FILE.move(from, to);
};

global.subjake = function(/*Array<String>*/ directories, /*String*/ aTaskName)
{
    if (!Array.isArray(directories))
        directories = [directories];

    directories.forEach(function(/*String*/ aDirectory)
    {
        if (FILE.isDirectory(aDirectory) && FILE.isFile(FILE.join(aDirectory, "Jakefile")))
        {
            var cmd = "cd " + OS.enquote(aDirectory) + " && " + serializedENV() + " " + OS.enquote(SYSTEM.args[0]) + " " + OS.enquote(aTaskName),
                returnCode = OS.system(cmd);

            if (returnCode)
                OS.exit(returnCode);
        }
        else
            print("warning: subjake missing: " + aDirectory + " (this is not necessarily an error, " + aDirectory + " may be optional)");
    });
};

global.executableExists = function(/*String*/ executableName)
{
    var paths = SYSTEM.env["PATH"].split(':');
    for (var i = 0; i < paths.length; i++) {
        var path = FILE.join(paths[i], executableName);
        if (FILE.exists(path))
            return path;
    }
    return null;
};

$OBJJ_TEMPLATE_EXECUTABLE = FILE.join($HOME_DIR, "Objective-J", "CommonJS", "objj-executable");

global.make_objj_executable = function(aPath)
{
    cp($OBJJ_TEMPLATE_EXECUTABLE, aPath);
    FILE.chmod(aPath, 0755);
};

global.symlink_executable = function(source)
{
    relative = FILE.relative($ENVIRONMENT_NARWHAL_BIN_DIR, source);
    destination = FILE.join($ENVIRONMENT_NARWHAL_BIN_DIR, FILE.basename(source));
    FILE.symlink(relative, destination);
};

global.getCappuccinoVersion = function()
{
    var versionFile = FILE.path(module.path).dirname().join("version.json");
    return JSON.parse(versionFile.read({ charset : "UTF-8" })).version;
};

global.setPackageMetadata = function(packagePath)
{
    var pkg = JSON.parse(FILE.read(packagePath, { charset : "UTF-8" }));

    var p = OS.popen(["git", "rev-parse", "--verify", "HEAD"]);
    if (p.wait() === 0) {
        var sha = p.stdout.read().split("\n")[0];
        if (sha.length === 40)
            pkg["cappuccino-revision"] = sha;
    }

    pkg["cappuccino-timestamp"] = new Date().getTime();
    pkg["version"] = getCappuccinoVersion();

    stream.print("    Version:   \0purple(" + pkg["version"] + "\0)");
    stream.print("    Revision:  \0purple(" + pkg["cappuccino-revision"] + "\0)");
    stream.print("    Timestamp: \0purple(" + pkg["cappuccino-timestamp"] + "\0)");

    FILE.write(packagePath, JSON.stringify(pkg, null, 4), { charset : "UTF-8" });
};

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
};

global.installSymlink = function(sourcePath)
{
    if (!FILE.isDirectory(sourcePath))
        return;

    var packageName = FILE.basename(sourcePath),
        targetPath = FILE.join(SYSTEM.prefix, "packages", packageName);

    if (FILE.isDirectory(targetPath))
        FILE.rmtree(targetPath);
    else if (FILE.linkExists(targetPath))
        FILE.remove(targetPath);

    stream.print("Symlinking \0cyan(" + targetPath + "\0) ==> \0cyan(" + sourcePath + "\0)");
    FILE.symlink(sourcePath, targetPath);

    var binPath = FILE.Path(FILE.join(targetPath, "bin"));

    if (binPath.isDirectory())
    {
        var narwhalBin = FILE.Path(FILE.join(SYSTEM.prefix, "bin"));

        binPath.list().forEach(function (name)
        {
            var binary = binPath.join(name);
            binary.chmod(0755);

            var target = narwhalBin.join(name),
                relative = FILE.relative(target, binary);

            if (target.linkExists())
                target.remove();

            FILE.symlink(relative, target);
        });
    }
};

global.spawnJake = function(/*String*/ aTaskName)
{
    if (OS.system(serializedENV() + " " + SYSTEM.args[0] + " " + aTaskName))
        OS.exit(1);//rake abort if ($? != 0)
};

var normalizeCommand = function(/*Array or String*/ command)
{
    if (Array.isArray(command))
        return command.map(function (arg)
        {
            return OS.enquote(arg);
        }).join(" ");
    else
        return command;
};

global.sudo = function(/*Array or String*/ command)
{
    // First try without sudo
    command = normalizeCommand(command);

    var returnCode = OS.system(command + " >/dev/null 2>&1");

    if (returnCode)
    {
        // if this is set, then disable the use of sudo.
        // This is very usefull for CI scripts and stuff like that
        if (SYSTEM.env["CAPP_NOSUDO"] == 1)
            return returnCode;

        return OS.system("sudo -p '\nEnter your admin password: ' " + command);
    }


    return 0;
};

global.exec = function(/*Array or String*/ command, quiet)
{
    command = normalizeCommand(command) + (quiet === true ? " >/dev/null 2>&1" : "");
    return OS.system(command);
};

global.copyManPage = function(/*String*/ name, /*int*/ section)
{
    var manDir = "/usr/local/share/man/man" + section,
        pageFile = name + "." + section,
        manPagePath = FILE.join(manDir, pageFile);

    if (!FILE.exists(manPagePath) || FILE.mtime(pageFile) > FILE.mtime(manPagePath))
    {
        if (!FILE.isDirectory(manDir))
        {
            if (sudo(["mkdir", "-p", "-m", "0755", manDir]))
                stream.print("\0red(Unable to create the man directory.\0)");
        }

        if (sudo(["cp", "-f", pageFile, manDir]))
            stream.print("\0red(Unable to copy the man file.\0)");
    }
};

global.xcodebuildCanListSDKs = function()
{
    return global.exec("xcodebuild -showsdks", true) === 0;
};

global.xcodebuildHasTenPointFiveSDK = function()
{
    if (xcodebuildCanListSDKs())
        return global.exec("xcodebuild -showsdks | grep 'macosx10.5'", true) === 0;

    return FILE.exists(FILE.join("/", "Developer", "SDKs", "MacOSX10.5.sdk"));
};

global.colorize = function(/* String */ message, /* String */ color)
{
    var matches = color.match(/(bold(?: |\+))?(.+)/);

    if (!matches)
        return;

    message = "\0" + matches[2] + "(" + message + "\0)";

    if (matches[1])
        message = "\0bold(" + message + "\0)";

    return message;
};

global.colorPrint = function(/* String */ message, /* String */ color)
{
    stream.print(colorize(message, color));
};

var minUlimit = 1024;

global.checkUlimit = function()
{
    var ulimitPath = executableExists("ulimit");

    if (!ulimitPath)
        return;

    var p = OS.popen([ulimitPath, "-n"]);

    if (p.wait() === 0)
    {
        var limit = p.stdout.read().split("\n")[0];

        if (Number(limit) < minUlimit)
        {
            stream.print("\0red(\0bold(ERROR:\0)\0) Cappuccino may need to open more files than this terminal session currently allows (" + limit + "). Add the following line to your login configuration file (.bash_profile, .bashrc, etc.), start a new terminal session, then try again:\n");
            stream.print("ulimit -n " + minUlimit);
            OS.exit(1);
        }
    }
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

task ("sudo-install-symlinks", function()
{
    sudo("jake install-symlinks");
});

task ("sudo-install-debug-symlinks", function()
{
    sudo("jake install-debug-symlinks");
});

task ("clean-debug", function()
{
    SYSTEM.env['CONFIG'] = 'Debug';
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
