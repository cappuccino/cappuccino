
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
        colorPrint("Installation failed, possibly because you do not have permissions.", "red");
        colorPrint("Try re-running using '" + colorize("jake sudo-install", "yellow") + "'.", "red");
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
        sudo("tusk install --force " + $BUILD_CJS_OBJECTIVE_J + " " + $BUILD_CJS_CAPPUCCINO);
    }
});

task ("install-symlinks", function()
{
    installSymlink($BUILD_CJS_OBJECTIVE_J);
    installSymlink($BUILD_CJS_CAPPUCCINO);
});

task ("install-debug-symlinks", function()
{
    SYSTEM.env.CONFIG = "Debug";
    spawnJake("install-symlinks");
});

task ("clean-sprites", function()
{
    var f = new FileList(FILE.join(SYSTEM.env.CAPP_BUILD, "**/dataURLs.txt")),
        paths = f.items();

    f = new FileList(FILE.join(SYSTEM.env.CAPP_BUILD, "**/MHTML*.txt"));
    paths = paths.concat(f.items());

    paths.forEach(function(path)
    {
        FILE.remove(path);
    });
});

task ("clobber-theme", function()
{
    var f = new FileList(FILE.join(SYSTEM.env.CAPP_BUILD, "**/Aristo.blend"), FILE.join(SYSTEM.env.CAPP_BUILD, "**/Aristo2.blend")),
        paths = f.items();

    f = new FileList(FILE.join(SYSTEM.env.CAPP_BUILD, "Aristo.build"), FILE.join(SYSTEM.env.CAPP_BUILD, "Aristo2.build"));
    paths = paths.concat(f.items());

    paths.forEach(function(path)
    {
        rm_rf(path);
    });
});

// Documentation

$DOCUMENTATION_BUILD = FILE.join($BUILD_DIR, "Documentation");

task ("docs", ["documentation"]);

task ("documentation", function()
{
    generateDocs(false);
});

task ("docs-no-frame", ["documentation-no-frame"]);

task ("documentation-no-frame", function()
{
    generateDocs(true);
});

function generateDocs(/* boolean */ noFrame)
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

    if (!doxygen || !FILE.exists(doxygen))
    {
        colorPrint("Doxygen not installed, skipping documentation generation.", "yellow");
        return;
    }

    colorPrint("Using " + doxygen + " for doxygen binary.", "green");
    colorPrint("Pre-processing source files...", "green");

    var documentationDir = FILE.canonical(FILE.join("Tools", "Documentation")),
        processors = FILE.glob(FILE.join(documentationDir, "preprocess/*"));

    for (var i = 0; i < processors.length; ++i)
        if (OS.system([processors[i], documentationDir]))
            return;

    if (noFrame)
    {
        // Back up the default settings, turn off the treeview
        if (OS.system(["sed", "-i", ".bak", "s/GENERATE_TREEVIEW.*=.*YES/GENERATE_TREEVIEW = NO/", FILE.join(documentationDir, "Cappuccino.doxygen")]))
            return;
    }
    else if (FILE.exists(FILE.join(documentationDir, "Cappuccino.doxygen.bak")))
        mv(FILE.join(documentationDir, "Cappuccino.doxygen.bak"), FILE.join(documentationDir, "Cappuccino.doxygen"));

    var doxygenDidSucceed = !OS.system([doxygen, FILE.join(documentationDir, "Cappuccino.doxygen")]);

    // Restore the original doxygen settings
    if (FILE.exists(FILE.join(documentationDir, "Cappuccino.doxygen.bak")))
        mv(FILE.join(documentationDir, "Cappuccino.doxygen.bak"), FILE.join(documentationDir, "Cappuccino.doxygen"));

    colorPrint("Post-processing generated documentation...", "green");

    processors = FILE.glob(FILE.join(documentationDir, "postprocess/*"));

    for (var i = 0; i < processors.length; ++i)
        if (OS.system([processors[i], documentationDir, FILE.join("Documentation", "html")]))
        {
            rm_rf("Documentation");
            return;
        }

    if (doxygenDidSucceed)
    {
        if (!FILE.isDirectory($BUILD_DIR))
            FILE.mkdirs($BUILD_DIR);

        rm_rf($DOCUMENTATION_BUILD);
        mv("debug.txt", FILE.join("Documentation", "debug.txt"));
        mv("Documentation", $DOCUMENTATION_BUILD);

        // There is a bug in doxygen 1.7.x preventing loading correctly the custom CSS
        // So let's do it manually
        cp(FILE.join(documentationDir, "doxygen.css"), FILE.join($DOCUMENTATION_BUILD, "html", "doxygen.css"));
    }
}

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

    OS.system("curl -L http://github.com/cappuccino/cappuccino-demos/zipball/master > " + zipQuoted);
    OS.system("(cd " + demosQuoted + " && unzip " + zipQuoted + " -d demos)");

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
    };

    Demo.prototype.name = function()
    {
        return this.plist("CPBundleName");
    };

    Demo.prototype.path = function()
    {
        return this._path;
    };

    Demo.prototype.excluded = function()
    {
        return !!this.plist("CPDemoExcluded");
    };

    Demo.prototype.toString = function()
    {
        return this.name();
    };

    FILE.glob(FILE.join(demosDir, "demos", "**/Info.plist")).map(function(demoPath){
        return new Demo(FILE.dirname(demoPath));
    }).filter(function(demo){
        return !demo.excluded();
    }).forEach(function(demo)
    {
        // copy frameworks into the demos
        cp_r(FILE.join($STARTER_DOWNLOAD_APPLICATION, "Frameworks"), FILE.join(demo.path(), "Frameworks"));
        rm_rf(FILE.join(demo.path(), "Frameworks", "Debug"));

        var outputPath = demo.name().replace(/\s/g, "-") + ".zip";
        OS.system("cd " + OS.enquote(FILE.dirname(demo.path()))+" && zip -ry -8 " + OS.enquote(outputPath) + " " + OS.enquote(FILE.basename(demo.path())));

        // remove the frameworks
        rm_rf(FILE.join(demo.path(), "Frameworks"));
    });
});

// Testing

task("test", ["CommonJS", "test-only"]);

task("test-only", function()
{
    var tests = new FileList('Tests/**/*Test.j'),
        cmd = ["ojtest"].concat(tests.items()),
        code = OS.system(serializedENV() + " " + cmd.map(OS.enquote).join(" "));

    if (code !== 0)
        OS.exit(code);
});

task("check-missing-imports", function()
{
    var code = OS.system(serializedENV() + " " + ["js", "Tests/DetectMissingImports.js"].map(OS.enquote).join(" "));

    if (code !== 0)
        OS.exit(code);
});

task("push-packages", ["push-cappuccino", "push-objective-j"]);

task("push-cappuccino", function() {
    pushPackage(
        $BUILD_CJS_CAPPUCCINO,
        "git@github.com:280north/cappuccino-package.git",
        SYSTEM.env.PACKAGE_BRANCH
    );
});

task("push-objective-j", function() {
    pushPackage(
        $BUILD_CJS_OBJECTIVE_J,
        "git@github.com:280north/objective-j-package.git",
        SYSTEM.env.PACKAGE_BRANCH
    );
});

function pushPackage(path, remote, branch)
{
    branch = branch || "master";

    var pushPackagesPath = FILE.path(".push-package");

    pushPackagesPath.mkdirs();

    var packagePath = pushPackagesPath.join(remote.replace(/[^\w]/g, "_"));

    stream.print("Pushing " + colorize(path, "blue") + " to " + branch + " of " + colorize(remote, "blue"));

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

    stream.print("    Version:   " + colorize(pkg.version, "purple"));
    stream.print("    Revision:  " + colorize(pkg["cappuccino-revision"], "purple"));
    stream.print("    Timestamp: " + colorize(pkg["cappuccino-timestamp"], "purple"));

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
