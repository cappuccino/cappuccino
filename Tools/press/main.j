require("narwhal").ensureEngine("rhino");

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "objj-analysis-tools.j"
@import "cib-analysis-tools.j"

var ARGS = require("args");
var FILE = require("file");
var OS = require("os");
var DOM = require("browser/dom");
var UTIL = require("util");

var stream = require("term").stream;

var serializer = new DOM.XMLSerializer();

var parser = new ARGS.Parser();

parser.usage("INPUT_PROJECT OUTPUT_PROJECT");
parser.help("Optimizes Cappuccino applications for deployment to the web.");

parser.option("-m", "--main", "main")
    .def("main.j")
    .set()
    .help("The relative path (from INPUT_PROJECT) to the main file (default: 'main.j')");

parser.option("-F", "--framework", "frameworks")
    .def(["Frameworks"])
    .push()
    .help("Add a frameworks directory, relative to INPUT_PROJECT (default: ['Frameworks'])");

parser.option("-E", "--environment", "environments")
    .def(['Browser'])
    .push()
    .help("Add a platform name (default: ['Browser'])");

parser.option("-l", "--flatten", "flatten")
    .def(false)
    .set(true)
    .help("Flatten all code into a single Application.js file and attempt add script tag to index.html (useful for Adobe AIR and CDN deployment)");

parser.option("-f", "--force", "force")
   .def(false)
   .set(true)
   .help("Force overwriting OUTPUT_PROJECT if it exists");

parser.option("-n", "--nostrip", "strip")
    .def(true)
    .set(false)
    .help("Do not strip any files");

parser.option("-p", "--pngcrush", "png")
    .def(false)
    .set(true)
    .help("Run pngcrush on all PNGs (pngcrush must be installed!)");

parser.option("-v", "--verbose", "verbose")
    .def(false)
    .set(true)
    .help("Verbose logging");

parser.helpful();

function main(args)
{
    var options = parser.parse(args);

    if (options.args.length < 2) {
        parser.printUsage(options);
        return;
    }

    //if (options.verbose)
        CPLogRegister(CPLogPrint);
    //else
    //    CPLogRegisterRange(CPLogPrint, "fatal", "info");

    // HACK: ensure trailing slashes for "relative" to work correctly
    var rootPath = FILE.path(options.args[0]).join("").absolute();
    var outputPath = FILE.path(options.args[1]).join("").absolute();

    if (outputPath.exists()) {
        if (options.force) {
            // FIXME: why doesn't this work?!
            //outputPath.rmtree();
            OS.system(["rm", "-rf", outputPath]);
        } else {
            CPLog.error("OUTPUT_PROJECT " + outputPath + " exists. Use -f to overwrite.");
            OS.exit(1);
        }
    }

    press(rootPath, outputPath, options);
}

function press(rootPath, outputPath, options) {
    CPLog.info("===========================================");
    CPLog.info("Application root:    " + rootPath);
    CPLog.info("Output directory:    " + outputPath);

    var outputFiles = {};

    // analyze and gather files for each environment:
    options.environments.forEach(function(environment) {
        pressEnvironment(rootPath, outputFiles, environment, options);
    });

    // phase 4: copy everything and write out the new files
    CPLog.error("PHASE 4: copy to output ("+rootPath+" to "+outputPath+")");

    FILE.copyTree(rootPath, outputPath);

    for (var path in outputFiles) {
        var file = outputPath.join(rootPath.relative(path));

        var parent = file.dirname();
        if (!parent.exists()) {
            CPLog.warn(parent + " doesn't exist, creating directories.");
            parent.mkdirs();
        }

        if (typeof outputFiles[path] !== "string")
            outputFiles[path] = outputFiles[path].join("");

        CPLog.info((file.exists() ? "Overwriting: " : "Writing:     ") + file);
        FILE.write(file, outputFiles[path], { charset : "UTF-8" });
    }

    // strip known unnecessary files
    // outputPath.glob("**/Frameworks/Debug").forEach(function(debugFramework) {
    //     outputPath.join(debugFramework).rmtree();
    // });
    // outputPath.join("index-debug.html").remove();

    if (options.png) {
        pngcrushDirectory(outputPath);
    }
}

function pressEnvironment(rootPath, outputFiles, environment, options) {

    var mainPath = String(rootPath.join(options.main));
    var frameworks = options.frameworks.map(function(framework) { return rootPath.join(framework); });

    CPLog.info("===========================================");
    CPLog.info("Main file:           " + mainPath)
    CPLog.info("Frameworks:          " + frameworks);
    CPLog.info("Environment:         " + environment);

    var analyzer = new ObjectiveJRuntimeAnalyzer(rootPath);

    var _OBJJ = analyzer.require("objective-j");

    // include paths:
    analyzer.context.global.OBJJ_INCLUDE_PATHS = frameworks;
    // environments:
    _OBJJ.environments = function() { return [environment, "ObjJ"] };

    // build list of cibs to inspect for dependent classes
    // FIXME: what's the best way to determine which cibs to look in?
    var cibs = FILE.glob(rootPath.join("**", "*.cib")).filter(function(path) { return !(/Frameworks/).test(path); });

    // phase 1: get global defines
    CPLog.error("PHASE 1: Loading application...");

    analyzer.initializeGlobalRecorder();

    analyzer.load(mainPath);

    analyzer.finishLoading();

    // coalesce the results
    var dependencies = analyzer.mapGlobalsToFiles();

    // log identifer => files defining
    CPLog.trace("Global defines:");
    Object.keys(dependencies).sort().forEach(function(identifier) {
        CPLog.trace("    " + identifier + " => " + rootPath.relative(dependencies[identifier]));
    });

    // phase 2: walk the dependency tree (both imports and references) to determine exactly which files need to be included
    CPLog.error("PHASE 2: Walk dependency tree...");

    var requiredFiles = null;

    if (options.nostrip)
    {
        // all files are required. no need for analysis
        throw "nostrip not implemented"
        // requiredFiles = scope.objj_files;
    }
    else
    {
        CPLog.warn("Analyzing dependencies...");

        requiredFiles = {};

        var context = {
            ignoreFrameworkImports : true, // ignores "XXX/XXX.j" imports
            importCallback: function(importing, imported) { requiredFiles[imported] = true; },
            referenceCallback: function(referencing, referenced) { requiredFiles[referenced] = true; },
            importedFiles: {},
            referencedFiles: {}
        }

        requiredFiles[mainPath] = true;

        mainExecutable = analyzer.executableForImport(mainPath);

        // check the code
        analyzer.traverseDependencies(context, mainExecutable);

        // check the cibs
        var globalsToFiles = analyzer.mapGlobalsToFiles();
        cibs.forEach(function(cibPath) {
            var cibClasses = findCibClassDependencies(cibPath);
            CPLog.debug("CIB: " + rootPath.relative(cibPath) + " => " + cibClasses);

            var referencedFiles = {};
            markFilesReferencedByTokens(cibClasses, globalsToFiles, referencedFiles);
            analyzer.checkReferenced(context, null, referencedFiles);
        });

        var count = 0,
            total = 0;
        // var allFiles = analyzer.gatherDependencies(mainExecutable);
        // for (var path in allFiles) {
        for (var path in requiredFiles) {
            // mark all ".keytheme"s as required
            if (/\.keyedtheme$/.test(path))
                requiredFiles[path] = true;

            if (requiredFiles[path])
            {
                CPLog.debug("Included: " + rootPath.relative(path));
                count++;
            }
            else
            {
                CPLog.info("Excluded: " + rootPath.relative(path));
            }
            total++;
        }
        CPLog.warn("Total required files: " + count + " out of " + total);
    }

    // phase 3b: rebuild .sj files with correct imports, copy .j files
    CPLog.error("PHASE 3b: Rebuild .sj");

    for (var path in requiredFiles)
    {
        var executable = analyzer.executableForImport(path),
            bundle = _OBJJ.CFBundle.bundleContainingPath(executable.path()),
            fileContents = executable.code(),
            relativePath = FILE.relative(FILE.join(bundle.path(), ""), executable.path());
            
        print("=======================================");
        print("    executable="+executable.path())
        print("    bundle="+bundle.path())
        print("    relativePath="+relativePath);
        print("    infoDictionary="+bundle.infoDictionary());
        print("    fileContents.length="+fileContents.length);

        if (executable.path() !== path)
            CPLog.warn("Sanity check failed (file path): " + executable.path() + " vs. " + path);

        if (bundle && bundle.infoDictionary())
        {
            var executablePath = bundle.executablePath();
            print("    executablePath="+executablePath);
            
            if (executablePath)
            {
                if (!outputFiles[executablePath])
                {
                    outputFiles[executablePath] = [];
                    outputFiles[executablePath].push("@STATIC;1.0;");
                }

                outputFiles[executablePath].push("p;" + relativePath.length + ";" + relativePath);
                outputFiles[executablePath].push("t;" +  fileContents.length + ";" +  fileContents);
            }
            else
            {
                CPLog.info("Passing .j through: " + rootPath.relative(path));
            }
        }
        else
            CPLog.warn("No bundle (or info dictionary for) " + rootPath.relative(path));
    }
}

function pngcrushDirectory(directory) {
    var directoryPath = FILE.path(directory);
    var pngs = directoryPath.glob("**/*.png");

    system.stderr.print("Running pngcrush on " + pngs.length + " pngs:");
    pngs.forEach(function(dst) {
        var dstPath = directoryPath.join(dst);
        var tmpPath = FILE.path(dstPath+".tmp");

        var p = OS.popen(["pngcrush", "-rem", "alla", "-reduce", /*"-brute",*/ dstPath, tmpPath]);
        if (p.wait()) {
            CPLog.warn("pngcrush failed. Ensure it's installed and on your PATH.");
        }
        else {
            FILE.move(tmpPath, dstPath);
            system.stderr.write(".").flush();
        }
    });
    system.stderr.print("");
}

function pathRelativeTo(target, relativeTo)
{
    // TODO: fix FILE.relative to always treat the source as a directory
    return FILE.relative(FILE.join(relativeTo, ""), target);
}
