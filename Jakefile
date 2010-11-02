
require("./common.jake");

var FILE = require("file"),
    SYSTEM = require("system"),
    OS = require("os"),
    UTIL = require("narwhal/util"),
    jake = require("jake"),
    stream = require("narwhal/term").stream;

var subprojects = ["Objective-J", "CommonJS", "Foundation", "AppKit", "Tools"];

["build", "clean", "clobber"].forEach(function(aTaskName)
{
    task (aTaskName, function()
    {
        subjake(subprojects, aTaskName);
    });
});

$BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS = FILE.join($BUILD_CJS_OBJECTIVE_J, "Frameworks", "Debug");


filedir ($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, ["debug", "release"], function()
{
    FILE.mkdirs($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS);

    cp_r(FILE.join($BUILD_DIR, "Debug", "Objective-J"), FILE.join($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, "Objective-J"));
});

$BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS = FILE.join($BUILD_CJS_CAPPUCCINO, "Frameworks", "Debug");

filedir ($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, ["debug", "release"], function()
{
    FILE.mkdirs($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS);

    cp_r(FILE.join($BUILD_DIR, "Debug", "Foundation"), FILE.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "Foundation"));
    cp_r(FILE.join($BUILD_DIR, "Debug", "AppKit"), FILE.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "AppKit"));
    cp_r(FILE.join($BUILD_DIR, "Debug", "BlendKit"), FILE.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "BlendKit"));
});

task ("CommonJS", [$BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, $BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "debug", "release"]);

task ("install", ["CommonJS"], function()
{
    // FIXME: require("narwhal/tusk/install").install({}, $COMMONJS);
    // Doesn't work due to some weird this.print business.
    if (OS.system(["tusk", "install", "--force", $BUILD_CJS_OBJECTIVE_J, $BUILD_CJS_CAPPUCCINO])) {
        stream.print("\0red(Installation failed, possibly because you do not have permissions.\0)");
        stream.print("\0red(Try re-running using '\0yellow(jake sudo-install\0)'.\0)");
        OS.exit(1); //rake abort if ($? != 0)
    }
});

task ("sudo-install", ["CommonJS"], function()
{
    // FIXME: require("narwhal/tusk/install").install({}, $COMMONJS);
    // Doesn't work due to some weird this.print business.
    if (OS.system(["sudo", "tusk", "install", "--force", $BUILD_CJS_OBJECTIVE_J, $BUILD_CJS_CAPPUCCINO]))
    {
        // Attempt a hackish work-around for sudo compiled with the --with-secure-path option
        if (OS.system("sudo bash -c 'source " + getShellConfigFile() + "; tusk install --force " + $BUILD_CJS_OBJECTIVE_J + " " + $BUILD_CJS_CAPPUCCINO + "'"))
            OS.exit(1); //rake abort if ($? != 0)
    }
});

task ("install-symlinks",  function()
{
    installSymlink($BUILD_CJS_OBJECTIVE_J);
    installSymlink($BUILD_CJS_CAPPUCCINO);
});

function installSymlink(sourcePath) {
    var TUSK = require("narwhal/tusk");
    var INSTALL = require("narwhal/tusk/commands/install");

    var packageName = FILE.basename(sourcePath);
    var packageDir = TUSK.getPackagesDirectory().join(packageName);
    stream.print("Symlinking \0cyan(" + packageDir + "\0) to \0cyan(" + sourcePath + "\0)");

    FILE.symlink(sourcePath, packageDir);
    INSTALL.finishInstall(packageDir);
}

// Documentation

$DOCUMENTATION_BUILD = FILE.join($BUILD_DIR, "Documentation");

task ("docs", ["documentation"]);

task ("documentation", function()
{
    // try to find a doxygen executable in the PATH;
    var doxygen = executableExists("doxygen");

    // If the Doxygen application is installed on Mac OS X, use that
    if (!doxygen && executableExists("mdfind"))
    {
        var p = OS.popen(["mdfind", "kMDItemContentType == 'com.apple.application-bundle' && kMDItemCFBundleIdentifier == 'org.doxygen'"]);
        if (p.wait() === 0)
        {
            var doxygenApps = p.stdout.read().split("\n");
            if (doxygenApps[0])
                doxygen = FILE.join(doxygenApps[0], "Contents/Resources/doxygen");
        }
    }

    if (doxygen && FILE.exists(doxygen))
    {
        stream.print("\0green(Using " + doxygen + " for doxygen binary.\0)");

        var documentationDir = FILE.join("Tools", "Documentation");

        if (OS.system([FILE.join(documentationDir, "make_headers.sh")]))
            OS.exit(1); //rake abort if ($? != 0)

        if (!OS.system([doxygen, FILE.join(documentationDir, "Cappuccino.doxygen")]))
        {
            rm_rf($DOCUMENTATION_BUILD);
            mv("debug.txt", FILE.join("Documentation", "debug.txt"));
            mv("Documentation", $DOCUMENTATION_BUILD);
        }

        OS.system(["ruby", FILE.join(documentationDir, "cleanup_headers")]);
    }
    else
        stream.print("\0yellow(Doxygen not installed, skipping documentation generation.\0)");
});

// Downloads

task ("downloads", ["starter_download"]);

$STARTER_README                 = FILE.join('Tools', 'READMEs', 'STARTER-README');
$STARTER_BOOTSTRAP              = 'bootstrap.sh';
$STARTER_DOWNLOAD               = FILE.join($BUILD_DIR, 'Cappuccino', 'Starter');
$STARTER_DOWNLOAD_APPLICATION   = FILE.join($STARTER_DOWNLOAD, 'NewApplication');
$STARTER_DOWNLOAD_README        = FILE.join($STARTER_DOWNLOAD, 'README');
$STARTER_DOWNLOAD_BOOTSTRAP     = FILE.join($STARTER_DOWNLOAD, 'bootstrap.sh');

task ("starter_download", [$STARTER_DOWNLOAD_APPLICATION, $STARTER_DOWNLOAD_README, $STARTER_DOWNLOAD_BOOTSTRAP, "documentation"], function()
{
    if (FILE.exists($DOCUMENTATION_BUILD))
    {
        rm_rf(FILE.join($STARTER_DOWNLOAD, 'Documentation'));
        cp_r(FILE.join($DOCUMENTATION_BUILD, 'html', '.'), FILE.join($STARTER_DOWNLOAD, 'Documentation'));
    }
});

filedir ($STARTER_DOWNLOAD_APPLICATION, ["CommonJS"], function()
{
    rm_rf($STARTER_DOWNLOAD_APPLICATION);
    FILE.mkdirs($STARTER_DOWNLOAD);

    if (OS.system(["capp", "gen", $STARTER_DOWNLOAD_APPLICATION, "-t", "Application", "--noconfig"]))
        // FIXME: uncomment this: we get conversion errors
        OS.exit(1); // rake abort if ($? != 0)
        //{}
    // No tools means no objective-j gem
    // FILE.rm(FILE.join($STARTER_DOWNLOAD_APPLICATION, 'Rakefile'))
});

filedir ($STARTER_DOWNLOAD_README, [$STARTER_README], function()
{
    cp($STARTER_README, $STARTER_DOWNLOAD_README);
});

filedir ($STARTER_DOWNLOAD_BOOTSTRAP, [$STARTER_BOOTSTRAP], function()
{
    var bootstrap = FILE.read($STARTER_BOOTSTRAP, { charset : "UTF-8" }).replace('install_capp=""', 'install_capp="yes"');
    FILE.write($STARTER_DOWNLOAD_BOOTSTRAP, bootstrap, { charset : "UTF-8" });
    OS.system(["chmod", "+x", $STARTER_DOWNLOAD_BOOTSTRAP]);
});

// Deployment

task ("deploy", ["downloads", "demos"], function()
{
    var cappuccino_output_path = FILE.join($BUILD_DIR, 'Cappuccino');

    // zip the starter pack
    var starter_zip_output = FILE.join($BUILD_DIR, 'Cappuccino', 'Starter.zip');
    rm_rf(starter_zip_output);

    OS.system("cd " + OS.enquote(cappuccino_output_path) + " && zip -ry -8 Starter.zip Starter");
});

task ("demos", function()
{
    var demosDir = FILE.join($BUILD_DIR, "CappuccinoDemos"),
        zipDir = FILE.join(demosDir, "demos.zip"),
        demosQuoted = OS.enquote(demosDir),
        zipQuoted = OS.enquote(zipDir);

    rm_rf(demosDir);
    FILE.mkdirs(demosDir);

    OS.system("curl -L http://github.com/280north/cappuccino-demos/zipball/master > "+zipQuoted);
    OS.system("(cd "+demosQuoted+" && unzip "+zipQuoted+" -d demos)");

    require("objective-j");

    function Demo(aPath)
    {
        this._path = aPath;
        this._plist = CFPropertyList.readPropertyListFromFile(FILE.join(aPath, 'Info.plist'));
    }

    Demo.prototype.plist = function(key)
    {
        if (key)
            return this._plist.valueForKey(key);
        return this._plist;
    }

    Demo.prototype.name = function()
    {
        return this.plist("CPBundleName");
    }

    Demo.prototype.path = function()
    {
        return this._path;
    }

    Demo.prototype.excluded = function()
    {
        return !!this.plist("CPDemoExcluded");
    }

    Demo.prototype.toString = function()
    {
        return this.name();
    }

    FILE.glob(FILE.join(demosDir, "demos", "**/Info.plist")).map(function(demoPath){
        return new Demo(FILE.dirname(demoPath))
    }).filter(function(demo){
        return !demo.excluded();
    }).forEach(function(demo)
    {
        // copy frameworks into the demos
        cp_r(FILE.join($STARTER_DOWNLOAD_APPLICATION, "Frameworks"), FILE.join(demo.path(), "Frameworks"));
        rm_rf(FILE.join(demo.path(), "Frameworks", "Debug"));

        var outputPath = demo.name().replace(/\s/g, "-")+".zip";
        OS.system("cd "+OS.enquote(FILE.dirname(demo.path()))+" && zip -ry -8 "+OS.enquote(outputPath)+" "+OS.enquote(FILE.basename(demo.path())));

        // remove the frameworks
        rm_rf(FILE.join(demo.path(), "Frameworks"));
    });
});

// Testing

task("test", ["CommonJS", "test-only"]);

task("test-only", function()
{
    var tests = new FileList('Tests/**/*Test.j');
    var cmd = ["ojtest"].concat(tests.items());

    var code = OS.system(serializedENV() + " " + cmd.map(OS.enquote).join(" "));
    if (code !== 0)
        OS.exit(code);

    OS.system(serializedENV() + " " + ["js", "Tests/DetectMissingImports.js"].map(OS.enquote).join(" "));
});

task("push-packages", ["push-cappuccino", "push-objective-j"]);

task("push-cappuccino", function() {
    pushPackage(
        $BUILD_CJS_CAPPUCCINO,
        "git@github.com:280north/cappuccino-package.git",
        SYSTEM.env["PACKAGE_BRANCH"]
    );
});

task("push-objective-j", function() {
    pushPackage(
        $BUILD_CJS_OBJECTIVE_J,
        "git@github.com:280north/objective-j-package.git",
        SYSTEM.env["PACKAGE_BRANCH"]
    );
});

function pushPackage(path, remote, branch)
{
    branch = branch || "master";

    var pushPackagesPath = FILE.path(".push-package");

    pushPackagesPath.mkdirs();

    var packagePath = pushPackagesPath.join(remote.replace(/[^\w]/g, "_"));

    stream.print("Pushing \0blue(" + path + "\0) to "+branch+" of \0blue(" + remote + "\0)");

    if (packagePath.isDirectory())
        OS.system(buildCmd([["cd", packagePath], ["git", "fetch"]]));
    else
        OS.system(["git", "clone", remote, packagePath]);

    if (OS.system(buildCmd([["cd", packagePath], ["git", "checkout", "origin/"+branch]]))) {
        if (OS.system(buildCmd([
            ["cd", packagePath],
            ["git", "symbolic-ref", "HEAD", "refs/heads/"+branch],
            ["rm", ".git/index"],
            ["git", "clean", "-fdx"]
        ])))
            throw "pushPackage failed";
    }

    if (OS.system("cd "+OS.enquote(packagePath)+" && git rm --ignore-unmatch -r * && rm -rf *"))
        throw "pushPackage failed";
    if (OS.system("cp -R "+OS.enquote(path)+"/* "+OS.enquote(packagePath)+"/."))
        throw "pushPackage failed";

    var pkg = JSON.parse(packagePath.join("package.json").read({ charset : "UTF-8" }));

    stream.print("    Version:   \0purple(" + pkg["version"] + "\0)");
    stream.print("    Revision:  \0purple(" + pkg["cappuccino-revision"] + "\0)");
    stream.print("    Timestamp: \0purple(" + pkg["cappuccino-timestamp"] + "\0)");

    var cmd = [
        ["cd", packagePath],
        ["git", "add", "."],
        ["git", "commit", "-m", "version="+pkg.version+"; revision="+pkg["cappuccino-revision"]+"; timestamp="+pkg["cappuccino-timestamp"]+";"]
    ];
    if (pkg["cappuccino-revision"])
        cmd.push(["git", "tag", "rev-"+pkg["cappuccino-revision"].slice(0,6)]);

    OS.system(buildCmd(cmd));

    if (OS.system(buildCmd([
        ["cd", packagePath],
        ["git", "push", "--tags", "origin", "HEAD:"+branch]
    ])))
        throw "pushPackage failed";
}

function buildCmd(arrayOfCommands)
{
    return arrayOfCommands.map(function(cmd) {
        return cmd.map(OS.enquote).join(" ");
    }).join(" && ");
}

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
