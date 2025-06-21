require("./common.jake");

var fs = require('fs');
var path = require('path');
var childProcess = require("child_process");

const term = ObjectiveJ.term;
const utilsFile = ObjectiveJ.utils.file;

var subprojects = ["Objective-J", "CommonJS", "Foundation", "AppKit", "Tools"];

task ("build", function() {
    childProcess.execSync(["mkdir", "-p", $BUILD_DIR].map(utilsFile.enquote).join(" "), {stdio: 'inherit'});
    childProcess.execSync(['ln', '-sf', '"$PWD"/node_modules', utilsFile.enquote($BUILD_DIR)].join(" "), {stdio: 'inherit'});
});

["build", "clean", "clobber"].forEach(function(aTaskName)
{
    task (aTaskName, function()
    {
        subjake(subprojects, aTaskName);
    });
});

$BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS = path.join($BUILD_CJS_OBJECTIVE_J, "Frameworks", "Debug");

filedir ($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, ["debug", "release"], function()
{
    fs.mkdirSync($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, { recursive: true });

    utilsFile.cp_r(path.join($BUILD_DIR, "Debug", "Objective-J"), path.join($BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, "Objective-J"));
});

$BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS = path.join($BUILD_CJS_CAPPUCCINO, "Frameworks", "Debug");

filedir ($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, ["debug", "release"], function()
{
    fs.mkdirSync($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, { recursive: true });

    utilsFile.cp_r(path.join($BUILD_DIR, "Debug", "Foundation"), path.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "Foundation"));
    utilsFile.cp_r(path.join($BUILD_DIR, "Debug", "AppKit"), path.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "AppKit"));
    utilsFile.cp_r(path.join($BUILD_DIR, "Debug", "BlendKit"), path.join($BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "BlendKit"));
});

task ("CommonJS", [$BUILD_CJS_OBJECTIVE_J_DEBUG_FRAMEWORKS, $BUILD_CJS_CAPPUCCINO_DEBUG_FRAMEWORKS, "debug", "release"], function() {
});

// Install everything in the dist directory
task ("dist", ["CommonJS"], function()
{
    installCopy($BUILD_CJS_OBJECTIVE_J, false);
    installCopy($BUILD_CJS_CAPPUCCINO, false);
});

task ("sudo-dist", ["CommonJS"], function()
{
    installCopy($BUILD_CJS_OBJECTIVE_J, true);
    installCopy($BUILD_CJS_CAPPUCCINO, true);
});

// Install everything in the dist directory (task dist) and
// create symlinks to the 'dist' binaries in the global 'npm prefix' path
task ("install", ["dist"], function()
{
    installGlobal($BUILD_CJS_OBJECTIVE_J, false);
    installGlobal($BUILD_CJS_CAPPUCCINO, false);
});

task ("sudo-install", ["sudo-dist"], function()
{
    installGlobal($BUILD_CJS_OBJECTIVE_J, true);
    installGlobal($BUILD_CJS_CAPPUCCINO, true);
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
    var f = new FileList(path.join(SYSTEM.env.CAPP_BUILD, "**/dataURLs.txt")),
        paths = f.items();

    f = new FileList(path.join(SYSTEM.env.CAPP_BUILD, "**/MHTML*.txt"));
    paths = paths.concat(f.items());

    paths.forEach(function(path)
    {
        fs.rmSync(path);
    });
});

task ("clobber-theme", function()
{
    var f = new FileList(path.join(SYSTEM.env.CAPP_BUILD, "**/Aristo.blend"), path.join(SYSTEM.env.CAPP_BUILD, "**/Aristo2.blend")),
        paths = f.items();

    f = new FileList(path.join(SYSTEM.env.CAPP_BUILD, "Aristo.build"), path.join(SYSTEM.env.CAPP_BUILD, "Aristo2.build"));
    paths = paths.concat(f.items());

    paths.forEach(function(path)
    {
        utilsFile.rm_rf(path);
    });
});

// Documentation

$DOCUMENTATION_BUILD = path.join($BUILD_DIR, "Documentation");

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

task ("docset", function()
      {
    generateDocs(true);
    var documentationDir = path.resolve("Tools", "Documentation");
    var docsetShell = path.join(documentationDir, "support", "docset.sh");

    try {
        // Enquote paths to handle spaces
        childProcess.execSync(`"${docsetShell}" "${documentationDir}"`, { stdio: 'inherit' });
    } catch (e) {
        console.error("Failed to generate docset.");
        process.exit(1);
    }
});

function executableExists(command) {
    try {
        // 'which' is a common command on Unix-like systems (macOS, Linux)
        // 'where' is the equivalent on Windows
        const checkCmd = process.platform === 'win32' ? 'where' : 'which';
        childProcess.execSync(`${checkCmd} ${command}`, { stdio: 'pipe' });
        return true;
    } catch (e) {
        return false;
    }
}

function generateDocs(/* boolean */ noFrame)
{
    var doxygen = null;

    // try to find a doxygen executable in the PATH;
    if (executableExists("doxygen")) {
        doxygen = "doxygen";
    }
    // If the Doxygen application is installed on Mac OS X, use that
    else if (process.platform === 'darwin' && executableExists("mdfind"))
    {
        try
        {
            var findResult = childProcess.execSync("mdfind \"kMDItemContentType == 'com.apple.application-bundle' && kMDItemCFBundleIdentifier == 'org.doxygen'\"", { encoding: 'utf8' });
            var doxygenApps = findResult.trim().split("\n");
            if (doxygenApps[0] && fs.existsSync(doxygenApps[0])) {
                var potentialPath = path.join(doxygenApps[0], "Contents/Resources/doxygen");
                // Verify the executable exists and is executable
                fs.accessSync(potentialPath, fs.constants.X_OK);
                doxygen = potentialPath;
            }
        }
        catch (e) {
            // mdfind failed, found nothing, or the result was not executable. Do nothing.
        }
    }

    if (!doxygen)
    {
        console.log("Doxygen not installed or not found, skipping documentation generation.");
        return;
    }

    console.log("Using " + doxygen + " for doxygen binary.");
    console.log("Pre-processing source files...");

    var documentationDir = path.resolve("Tools", "Documentation");
    var preProcessorsDir = path.join(documentationDir, "preprocess");

    try {
        var processors = fs.readdirSync(preProcessorsDir).sort();

        for (var i = 0; i < processors.length; ++i) {
            var processorPath = path.join(preProcessorsDir, processors[i]);
            childProcess.execSync(`"${processorPath}" "${documentationDir}"`, { stdio: 'inherit' });
        }

        var doxygenConfigFile = path.join(documentationDir, "Cappuccino.doxygen");
        var doxygenConfigBackup = doxygenConfigFile + ".bak";

        if (noFrame)
        {
            console.log("Disabling treeview for no-frame documentation.");
            childProcess.execSync(`sed -i.bak 's/GENERATE_TREEVIEW.*=.*YES/GENERATE_TREEVIEW = NO/' "${doxygenConfigFile}"`);
        }
        else if (fs.existsSync(doxygenConfigBackup)) {
            fs.renameSync(doxygenConfigBackup, doxygenConfigFile);
        }

        console.log("Running Doxygen...");
        childProcess.execSync(`"${doxygen}" "Cappuccino.doxygen"`, { stdio: 'inherit', cwd: documentationDir });

        // Restore the original doxygen settings if a backup exists
        if (fs.existsSync(doxygenConfigBackup)) {
            fs.renameSync(doxygenConfigBackup, doxygenConfigFile);
        }

        console.log("Post-processing generated documentation...");

        var postProcessorsDir = path.join(documentationDir, "postprocess");
        var htmlOutputDir = path.join(documentationDir, "html");
        processors = fs.readdirSync(postProcessorsDir).sort();

        for (var i = 0; i < processors.length; ++i) {
            var processorPath = path.join(postProcessorsDir, processors[i]);
            childProcess.execSync(`"${processorPath}" "${documentationDir}" "${htmlOutputDir}"`, { stdio: 'inherit' });
        }

        var generatedDocsSource = path.join(documentationDir, "Documentation");

        if (fs.existsSync(generatedDocsSource)) {
            if (!fs.existsSync($BUILD_DIR)) {
                fs.mkdirSync($BUILD_DIR, { recursive: true });
            }

            if (fs.existsSync($DOCUMENTATION_BUILD)) {
                fs.rmSync($DOCUMENTATION_BUILD, { recursive: true, force: true });
            }

            var debugTxtSource = path.join(documentationDir, "debug.txt");
            if (fs.existsSync(debugTxtSource)) {
                var debugTxtDest = path.join(generatedDocsSource, "debug.txt");
                fs.renameSync(debugTxtSource, debugTxtDest);
            }

            fs.renameSync(generatedDocsSource, $DOCUMENTATION_BUILD);

            var customCSS = path.join(documentationDir, "doxygen.css");
            var destCSS = path.join($DOCUMENTATION_BUILD, "html", "doxygen.css");
            if(fs.existsSync(customCSS)) {
                fs.copyFileSync(customCSS, destCSS);
            }
            console.log("Documentation successfully built in " + $DOCUMENTATION_BUILD);
        } else {
            console.error("Doxygen ran but did not produce the expected 'Documentation' directory.");
        }
    } catch (e) {
        console.error("An error occurred during documentation generation:");
        console.error(e.message);
        // Clean up partially generated files
        var generatedDocsSource = path.join(documentationDir, "Documentation");
        if (fs.existsSync(generatedDocsSource)) {
            fs.rmSync(generatedDocsSource, { recursive: true, force: true });
        }
        process.exit(1);
    }
}

// Downloads

task ("downloads", ["starter_download"]);

$STARTER_README                 = path.join('Tools', 'READMEs', 'STARTER-README');
$STARTER_BOOTSTRAP              = 'bootstrap.sh';
$STARTER_DOWNLOAD               = path.join($BUILD_DIR, 'Cappuccino', 'Starter');
$STARTER_DOWNLOAD_APPLICATION   = path.join($STARTER_DOWNLOAD, 'NewApplication');
$STARTER_DOWNLOAD_README        = path.join($STARTER_DOWNLOAD, 'README');
$STARTER_DOWNLOAD_BOOTSTRAP     = path.join($STARTER_DOWNLOAD, 'bootstrap.sh');

task ("starter_download", [$STARTER_DOWNLOAD_APPLICATION, $STARTER_DOWNLOAD_README, $STARTER_DOWNLOAD_BOOTSTRAP, "documentation"], function()
{
    if (FILE.exists($DOCUMENTATION_BUILD))
    {
        utilsFile.rm_rf(path.join($STARTER_DOWNLOAD, 'Documentation'));
        utilsFile.cp_r(path.join($DOCUMENTATION_BUILD, 'html', '.'), path.join($STARTER_DOWNLOAD, 'Documentation'));
    }
});

filedir ($STARTER_DOWNLOAD_APPLICATION, ["CommonJS"], function()
{
    utilsFile.rm_rf($STARTER_DOWNLOAD_APPLICATION);
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
    utilsFile.cp($STARTER_README, $STARTER_DOWNLOAD_README);
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
    var cappuccino_output_path = path.join($BUILD_DIR, 'Cappuccino');

    // zip the starter pack
    var starter_zip_output = path.join($BUILD_DIR, 'Cappuccino', 'Starter.zip');
    utilsFile.rm_rf(starter_zip_output);

    OS.system("cd " + OS.enquote(cappuccino_output_path) + " && zip -ry -8 Starter.zip Starter");
});

task ("demos", function()
{
    var demosDir = path.join($BUILD_DIR, "CappuccinoDemos"),
        zipDir = path.join(demosDir, "demos.zip"),
        demosQuoted = OS.enquote(demosDir),
        zipQuoted = OS.enquote(zipDir);

    utilsFile.rm_rf(demosDir);
    FILE.mkdirs(demosDir);

    OS.system("curl -L http://github.com/cappuccino/cappuccino-demos/zipball/master > " + zipQuoted);
    OS.system("(cd " + demosQuoted + " && unzip " + zipQuoted + " -d demos)");

    require("objective-j");

    function Demo(aPath)
    {
        this._path = aPath;
        this._plist = CFPropertyList.readPropertyListFromFile(path.join(aPath, 'Info.plist'));
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

    FILE.glob(path.join(demosDir, "demos", "**/Info.plist")).map(function(demoPath){
        return new Demo(FILE.dirname(demoPath));
    }).filter(function(demo){
        return !demo.excluded();
    }).forEach(function(demo)
    {
        // copy frameworks into the demos
        utilsFile.cp_r(path.join($STARTER_DOWNLOAD_APPLICATION, "Frameworks"), path.join(demo.path(), "Frameworks"));
        utilsFile.rm_rf(path.join(demo.path(), "Frameworks", "Debug"));

        var outputPath = demo.name().replace(/\s/g, "-") + ".zip";
        OS.system("cd " + OS.enquote(FILE.dirname(demo.path()))+" && zip -ry -8 " + OS.enquote(outputPath) + " " + OS.enquote(FILE.basename(demo.path())));

        // remove the frameworks
        utilsFile.rm_rf(path.join(demo.path(), "Frameworks"));
    });
});

// Testing

task("test", ["CommonJS", "test-only"]);

task("test-only", function()
{
    var tests = new FileList('Tests/**/*Test.j');
    var cmd = ["ojtest"].concat(tests.items());
    var cmdString = cmd.map(utilsFile.enquote).join(" ");

    try
    {
        childProcess.execSync(serializedENV() + " " + cmdString, {stdio: 'inherit'});
    }
    catch (e)
    {
        process.exit(1);
    }
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

    term.stream.print("    Version:   " + colorize(pkg.version, "purple"));
    term.stream.print("    Revision:  " + colorize(pkg["cappuccino-revision"], "purple"));
    term.stream.print("    Timestamp: " + colorize(pkg["cappuccino-timestamp"], "purple"));

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
