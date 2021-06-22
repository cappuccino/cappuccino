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

// var SYSTEM = require("system");
// var FILE = require("file");
// var OS = require("os");
// var UTIL = require("narwhal/util");
// var stream = require("narwhal/term").stream;

console.log("at the top of common.jake");
var fs = require('fs');
var child_process = require('child_process');
var path = require('path');

// for testing
var JAKE = require("../jake/lib/jake.js");

requiresSudo = false;

process.argv.slice(1).forEach(function(arg)
{
    if (arg === "sudo-install")
        requiresSudo = true;
});

// Set up development environment variables.
// record the initial process.env so we know which need to be serialized later

var envInitial = Object.freeze(JSON.parse(JSON.stringify(process.env)));

process.env["BUILD_PATH"] = path.resolve(
    process.env["BUILD_PATH"] ||
    process.env["CAPP_BUILD"] || // Global Cappuccino build directory.
    process.env["STEAM_BUILD"] || // Maintain backwards compatibility with steam.
    path.join(path.dirname(module.path), "Build") // Just build here.
);

if (!process.env["CAPP_BUILD"] && process.env["STEAM_BUILD"])
    console.error("STEAM_BUILD environment variable is deprecated; Please use CAPP_BUILD instead.");

if (!process.env["CONFIG"])
    process.env["CONFIG"] = "Release";

global.ENV  = process.env;

// changed approach, now we try to port jake from narwhal to node instead

/* newJakeTaskWrapper = function() {
    console.log("nu har vi kört taskwrappern");
    var nArgs = arguments.length;
    desc(arguments[0])
    if (nArgs == 3) {
        jake.task(arguments[0], arguments[1], arguments[2]);
    } else if (nArgs == 2) {
        jake.task(arguments[0], arguments[1]);
    } else {
        jake.task(arguments[0]);
    }
}

newJakeFiledirWrapper = function() {
    console.log("nu har vi kört file or dir wrappern");
    var nArgs = arguments.length;
    desc(arguments[0]);
    if (!path.extname(arguments[0])) {    
        jake.directory(arguments[0]);
        if (nArgs == 3) {
            jake.file(arguments[0], arguments[1], arguments[2]);
        } else if (nArgs == 2) {
            jake.file(arguments[0], arguments[1]);
        } else {
            jake.file(arguments[0]);
        }
    } else {
        if (nArgs == 3) {
            jake.file(arguments[0], arguments[1], arguments[2]);
        } else if (nArgs == 2) {
            jake.file(arguments[0], arguments[1]);
        } else {
            jake.file(arguments[0]);
        }
    }
} */

global.task = JAKE.task;
global.directory = JAKE.directory;
global.file = JAKE.file;
global.filedir = JAKE.filedir;
global.FileList = JAKE.FileList;

global.$CONFIGURATION                   = process.env['CONFIG'];
global.$INLINE_MSG_SEND                 = process.env['INLINE_MSG_SEND'];
global.$BUILD_DIR                       = process.env['BUILD_PATH'];
global.$BUILD_CONFIGURATION_DIR         = path.join($BUILD_DIR, $CONFIGURATION);

global.$BUILD_CJS_OBJECTIVE_J           = path.join($BUILD_CONFIGURATION_DIR, "CommonJS", "objective-j");

global.$BUILD_CJS_CAPPUCCINO            = path.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino");
global.$BUILD_CJS_CAPPUCCINO_BIN        = path.join($BUILD_CJS_CAPPUCCINO, "bin");
global.$BUILD_CJS_CAPPUCCINO_LIB        = path.join($BUILD_CJS_CAPPUCCINO, "lib");
global.$BUILD_CJS_CAPPUCCINO_FRAMEWORKS = path.join($BUILD_CJS_CAPPUCCINO, "Frameworks");

// for testing
global.CLEAN = require("../jake/lib/jake/clean.js").CLEAN;
global.CLOBBER = require("../jake/lib/jake/clean.js").CLOBBER;
global.CLEAN.include(path.join(global.$BUILD_DIR, "*.build"));
global.CLOBBER.include(global.$BUILD_DIR);

global.$HOME_DIR        = path.resolve(path.dirname(module.path));
global.$LICENSE_FILE    = path.resolve(path.join(path.dirname(module.path), 'LICENSE'));

global.FIXME_fileDependency = function(destinationPath, sourcePath)
{
    file(destinationPath, [sourcePath], function()
    {
        var time = new Date();     
        try {
            fs.utimesSync(destinationPath, time, time);
        } catch (err) {
            fs.closeSync(fs.openSync(destinationPath, 'w'));
        }
    });
};

// logic to determine which packages should be loaded but are not.
// used in serializedENV()
function additionalPackages()
{
    console.log("in additionalPackages");
    var builtObjectiveJPackage = path.join(path.resolve($BUILD_CONFIGURATION_DIR), "CommonJS", "objective-j");
    var builtCappuccinoPackage = path.join(path.resolve($BUILD_CONFIGURATION_DIR), "CommonJS", "cappuccino");

    var packages = [];
    // load built objective-j if exists, otherwise unbuilt
    if (!fs.existsSync(path.join(builtObjectiveJPackage, "package.json"))) {
        //if (!packageInCatalog(builtObjectiveJPackage))
            packages.push(builtObjectiveJPackage);
    }

    // load built cappuccino if it exists
    if (!fs.existsSync(path.join(builtCappuccinoPackage, "package.json"))) {
        //if (!packageInCatalog(builtCappuccinoPackage))
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

// FIXA: vi tar denna från narwhal
function enquote(word) {
    return "'" + String(word).replace(/'/g, "'\"'\"'") + "'";
}

serializedENV = function()
{
    var envNew = {};

    // add changed keys to the new ENV
    Object.keys(process.env).forEach(function(key)
    {
        if (process.env[key] !== envInitial[key])
            envNew[key] = process.env[key];
    });

    // pseudo-HACK: add NARWHALOPT with packages we should ensure are loaded
    var packages = additionalPackages();

    if (packages.length)
    {
        envNew["NARWHALOPT"] = packages.map(function(p) { return "-p " + enquote(p); }).join(" ");
        envNew["PATH"] = packages.map(function(p) { return path.join(p, "bin"); }).concat(process.env["PATH"]).join(":");
    }

    return Object.keys(envNew).map(function(key)
    {
        return key + "=" + enquote(envNew[key]);
    }).join(" ");
};

function getShellConfigFile()
{
    var homeDir = process.env["HOME"] + "/";
    // use order outlined by http://hayne.net/MacDev/Notes/unixFAQ.html#shellStartup
    var possibilities = [homeDir + ".bash_profile",
                         homeDir + ".bash_login",
                         homeDir + ".profile",
                         homeDir + ".bashrc"];

    for (var i = 0; i < possibilities.length; i++)
    { 
        if (fs.existsSync(possibilities[i]))
            return possibilities[i];
    }
}

function reforkWithPackages()
{
    console.log("in reforkWithPackages");
    if (additionalPackages().length > 0)
    {
        var cmd = serializedENV() + " " + process.argv.map(enquote).join(" ");
        console.log("cmd: " + cmd);
        // FIXA: oklart om detta är rätt
        child_process.execSync(cmd, {stdio: 'inherit'});
        process.exit();
    }
}

// reforkWithPackages();

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
        //require("objective-j").OBJJ_INCLUDE_PATHS.push(path.join($BUILD_CONFIGURATION_DIR, "CommonJS", "cappuccino", "Frameworks"));
    }
    catch (e)
    {
        handleSetupEnvironmentError(e);
    }
}

setupEnvironment();

global.rm_rf = function(/*String*/ aFilename)
{
    try { fs.rm(aFilename, {recursive: true, force: true}); }
    catch (anException) { }
};

// FIXA: stackoverflow, men denna göra ju typ det som cp_r nedan gör
function copyRecursiveSync (src, dest) {
    var exists = fs.existsSync(src);
    var stats = exists && fs.statSync(src);
    var isDirectory = exists && stats.isDirectory();
    if (isDirectory) {
      fs.mkdirSync(dest);
      fs.readdirSync(src).forEach(function(childItemName) {
        copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
      });
    } else {
      fs.copyFileSync(src, dest);
    }
  };

  
global.cp_r = function(/*String*/ from, /*String*/ to)
{
    if (fs.existsSync(to))
        rm_rf(to);

    if (fs.lstatSync(from).isDirectory())
        copyRecursiveSync(from, to);
    else
    {
        
        try
        {
            fs.copyFileSync(from, to);
        }
        catch (e)
        {
            print(e + fs.existsSync(from) + " " + fs.existsSync(path.dirname(to)));
        }
    }
};

global.cp = function(/*String*/ from, /*String*/ to)
{
    fs.copyFileSync(from, to)
//    FILE.chmod(to, FILE.mod(from));
};

global.mv = function(/*String*/ from, /*String*/ to)
{
    fs.renameSync(from, to);
};

// FIXA: kör command och returnera exitkoden
function systemSync(command) 
{   
    console.log("i systemSync");
    console.log("command: " + command)
    
    try {
        child_process.execSync(command, {stdio: 'inherit'});
        console.log("exited gracefully")
        return 0;
    } catch (error) {
        console.log(error);
        console.log(error.output.toString());
        return error.status;
    }
}

global.subjake = function(/*Array<String>*/ directories, /*String*/ aTaskName)
{
    
    if (!Array.isArray(directories))
        directories = [directories];
    
    directories.forEach(function(/*String*/ aDirectory)
    {
        if (fs.lstatSync(aDirectory).isDirectory() && fs.lstatSync(path.join(aDirectory, "Jakefile")).isFile())
        {
            // just for testing
            var cmd = "cd " + enquote(aDirectory) + " && " + serializedENV() + " " + "/Users/alfred/Developer/jake/bin/jake" + " " + enquote(aTaskName);
            var returnCode = systemSync(cmd);
                
            if (returnCode)
                process.exit(returnCode);
        }
        else
            print("warning: subjake missing: " + aDirectory + " (this is not necessarily an error, " + aDirectory + " may be optional)");
    });
};

global.executableExists = function(/*String*/ executableName)
{
    var paths = process.env["PATH"].split(':');
    for (var i = 0; i < paths.length; i++) {
        path.join(paths[i], executableName);
        var p = path.join(paths[i], executableName);
        if (fs.existsSync(p))
            return p
    }
    return null;
};

$OBJJ_TEMPLATE_EXECUTABLE = path.join($HOME_DIR, "Objective-J", "CommonJS", "objj-executable");

global.make_objj_executable = function(aPath)
{
    cp($OBJJ_TEMPLATE_EXECUTABLE, aPath);
    fs.chmodSync(aPath, 0o755);
};

global.symlink_executable = function(source)
{
    rel = path.relative($ENVIRONMENT_NARWHAL_BIN_DIR, source);
    dest = path.join($ENVIRONMENT_NARWHAL_BIN_DIR, path.basename(source));
    fs.symlinkSync(rel, dest);
};

global.getCappuccinoVersion = function()
{
    console.log("sahfgdkjdkjfhgskjdhfgd");
    var versionFile = path.join(module.path, "version.json");
    return JSON.parse(fs.readFileSync(versionFile, { encoding: "utf8" })).version;
};

global.setPackageMetadata = function(packagePath)
{
    var pkg = JSON.parse(fs.readFileSync(packagePath, { encoding: "utf8" } ));

    try {
        var output = child_process.execSync("git rev-parse --verify HEAD");
        var sha = output.toString().split("\n")[0];
        if (sha.length === 40)
            pkg["cappuccino-revision"] = sha;

    } catch (error) {
        console.log(error.output.toString());
        console.log("setPackageMetadata error " + error.status);
    }

    pkg["cappuccino-timestamp"] = new Date().getTime();
    pkg["version"] = getCappuccinoVersion();

    console.log("    Version:   \0purple(" + pkg["version"] + "\0)");
    console.log("    Revision:  \0purple(" + pkg["cappuccino-revision"] + "\0)");
    console.log("    Timestamp: \0purple(" + pkg["cappuccino-timestamp"] + "\0)");

    fs.writeFileSync(packagePath, JSON.stringify(pkg, null, 4), 'utf8');
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

// FIXA: Oklar metod
global.installSymlink = function(sourcePath)
{
    if (!fs.lstatSync(sourcePath).isDirectory())
        return;


    var packageName = path.basename(sourcePath),
        targetPath = path.join(SYSTEM.prefix, "packages", packageName);
    
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

global.installCopy = function(sourcePath, useSudo)
{
    if (!fs.lstatSync(sourcePath).isDirectory())
        return;

    var packageName = path.basename(sourcePath),
        targetPath = path.join(SYSTEM.prefix, "packages", packageName);

    if (fs.lstatSync(targetPath).isDirectory())
        fs.rmSync(targetPath, {recursive: true, force: true});
    else if (fs.fstatSync(targetPath).isSymbolicLink() || fs.existsSync(targetPath))
        fs.rmSync(targetPath);

    stream.print("Copying \0cyan(" + sourcePath + "\0) ==> \0cyan(" + targetPath + "\0)");

    // hacky way to do a sudo copy.
    if (useSudo)
        child_process.execSync(["sudo", "cp", "-r", sourcePath, targetPath].join(" "));
    else
        copyRecursiveSync(sourcePath, targetPath);

    var binPath = path.resolve(path.join(targetPath, "bin"))

    if (fs.lstatSync(binPath).isDirectory())
    {
        fs.readdirSync(binPath).forEach(function (name)
        {
            var binary = path.join(binPath, name);
            fs.chmodSync(binary, 0o755);
        });
    }
};

global.spawnJake = function(/*String*/ aTaskName)
{
    console.log("i spawnJake");
    // for testing
    if (systemSync(serializedENV() + " " + "/Users/alfred/Developer/jake/bin/jake" + " " + aTaskName))
        console.log("exited in spawnJake with code 1");
        process.exit(1);    //rake abort if ($? != 0)
};

var normalizeCommand = function(/*Array or String*/ command)
{
    if (Array.isArray(command))
        return command.map(function (arg)
        {
            return enquote(arg);
        }).join(" ");
    else    
        return command;
};

global.sudo = function(/*Array or String*/ command)
{
    // First try without sudo
    command = normalizeCommand(command);

    var returnCode = systemSync(command + " >/dev/null 2>&1");

    if (returnCode)
    {
        // if this is set, then disable the use of sudo.
        // This is very usefull for CI scripts and stuff like that
        if (process.env["CAPP_NOSUDO"] == 1)
            return returnCode;

        return systemSync("sudo -p '\nEnter your admin password: ' " + command);
    }


    return 0;
};

global.exec = function(/*Array or String*/ command, quiet)
{
    command = normalizeCommand(command) + (quiet === true ? " >/dev/null 2>&1" : "");
    return systemSync(command);
};

global.copyManPage = function(/*String*/ name, /*int*/ section)
{
    var manDir = "/usr/local/share/man/man" + section,
        pageFile = name + "." + section,
        manPagePath = path.join(manDir, pageFile);

    
    
    if (!fs.existsSync(manPagePath) || fs.lstatSync(pageFile).mtime > fs.lstatSync(manPagePath).mtime)
    {
        if (!fs.lstatSync(manDir).isDirectory())
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

    return fs.existsSync(path.join("/", "Developer", "SDKs", "MacOSX10.5.sdk"));
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

// built in tasks

task ("build");
task ("default", "build");

task ("release", function()
{
    process.env["CONFIG"] = "Release";
    spawnJake("build");
});

task ("debug", function()
{
    console.log("Hello!");
    process.env["CONFIG"] = "Debug";
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
    process.env['CONFIG'] = 'Debug';
    spawnJake("clean");
});

task ("cleandebug", ["clean-debug"]);

task ("clean-release", function()
{
    process.env["CONFIG"] = "Release";
    spawnJake("clean");
});

task ("cleanrelease", ["clean-release"]);

task ("clean-all", ["clean-debug", "clean-release"]);
task ("cleanall", ["clean-all"]);

task ("clobber-debug", function()
{
    process.env["CONFIG"] = "Debug";
    spawnJake("clobber");
});

task ("clobberdebug", ["clobber-debug"]);

task ("clobber-release", function()
{
    process.env["CONFIG"] = "Release";
    spawnJake("clobber");
});

task ("clobberrelease", ['clobber-release']);

task ("clobber-all", ["clobber-debug", "clobber-release"]);
task ("clobberall", ["clobber-all"]);
