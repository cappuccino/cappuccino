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
var INTERPRETER = require("interpreter");

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
    .def(['W3C'])//, 'IE7', 'IE8'])
    .push()
    .help("Add a platform name (default: ['W3C', 'IE7', 'IE8'])");

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
            outputPath.rmtree();
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

    // get a Rhino context
    var context = new INTERPRETER.Context();
    var scope = setupObjectiveJ(context);

    scope.OBJJ_INCLUDE_PATHS = frameworks;
    scope.OBJJ_ENVIRONMENTS = [environment, "ObjJ"];

    // build list of cibs to inspect for dependent classes
    // FIXME: what's the best way to determine which cibs to look in?
    var cibs = FILE.glob(rootPath.join("**", "*.cib")).filter(function(path) { return !(/Frameworks/).test(path); });

    // flattening bookkeeping. keep track of the bundles and evaled code (in the correct order!)
    var bundleArchiveResponses = [];
    var exectuableResponses = [];
    var evaledFragments = [];

    // here we hook into didReceiveBundleResponse to record the responses for --flattening
    functionHookBefore(scope.objj_search.prototype, "didReceiveBundleResponse", function(aResponse) {
        var response = {
            success : aResponse.success,
            filePath : rootPath.relative(aResponse.filePath).toString()
        };

        if (aResponse.success) {
            var xmlString = serializer.serializeToString(aResponse.xml);
            response.text = CPPropertyListCreate280NorthData(CPPropertyListCreateFromXMLData({ string: xmlString })).string;
        }

        bundleArchiveResponses.push(response);
    });

    functionHookBefore(scope.objj_search.prototype, "didReceiveExecutableResponse", function(aResponse) {
        exectuableResponses.push(aResponse);
    });

    // lets just use the Context object as our con
    context.rootPath = rootPath;
    context.scope = scope;

    // phase 1: get global defines
    CPLog.error("PHASE 1: Loading application...");

    var globals = findGlobalDefines(context, mainPath, evaledFragments);

    // coalesce the results
    var dependencies = coalesceGlobalDefines(globals);

    // log identifer => files defining
    CPLog.trace("Global defines:");
    Object.keys(dependencies).sort().forEach(function(identifier) {
        CPLog.trace("    " + identifier + " => " + rootPath.relative(dependencies[identifier]));
    });

    // phase 2: walk the dependency tree (both imports and references) to determine exactly which files need to be included
    CPLog.error("PHASE 2: Walk dependency tree...");

    var requiredFiles = {};

    if (options.nostrip)
    {
        // all files are required. no need for analysis
        requiredFiles = scope.objj_files;
    }
    else
    {
        if (!scope.objj_files[mainPath])
        {
            CPLog.error("Root file not loaded!");
            return;
        }

        CPLog.warn("Analyzing dependencies...");

        context.dependencies = dependencies;
        context.ignoreFrameworkImports = true; // ignores "XXX/XXX.j" imports
        context.importCallback = function(importing, imported) { requiredFiles[imported] = true; };
        context.referenceCallback = function(referencing, referenced) { requiredFiles[referenced] = true; }

        requiredFiles[mainPath] = true;

        // check the code
        traverseDependencies(context, scope.objj_files[mainPath]);

        // check the cibs
        cibs.forEach(function(cibPath) {
            var cibClasses = findCibClassDependencies(cibPath);
            CPLog.debug(cibPath + " => " + cibClasses);

            var referencedFiles = {};
            markFilesReferencedByTokens(cibClasses, context.dependencies, referencedFiles);
            checkReferenced(context, null, referencedFiles);

            print(UTIL.repr(referencedFiles));
        });

        var count = 0,
            total = 0;
        for (var path in scope.objj_files)
        {
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

    if (options.flatten)
    {
        // phase 3a: build single Application.js file (and modified index.html)
        CPLog.error("PHASE 3a: Flattening...");

        var applicationScriptName = "Application-"+environment+".js";
        var indexHTMLName = "index-"+environment+".html";

        // Shim for faking bundle responses.
        // We're just defining it here so we can serialize the function. It's not used within press.
        // **************************************************
        var fakeDidReceiveBundleResponse = function(aResponse)
        {
            var bundle = new objj_bundle();

            bundle.path = aResponse.filePath;

            if (aResponse.success)
            {
                var data = new objj_data();
                data.string = aResponse.text;
                bundle.info = CPPropertyListCreateFrom280NorthData(data);
                //bundle.info = CPPropertyListCreateFromXMLData({ string : aResponse.xml });
            }
            else
                bundle.info = new objj_dictionary();

            objj_bundles[aResponse.filePath] = bundle;
        }
        var setupURIMaps = function(URIMaps) {
            var DIRECTORY = function(aPath) { return (aPath).substr(0, (aPath).lastIndexOf('/') + 1); };
            for (var bundleName in URIMaps) {
                if (objj_bundles[bundleName]) {
                    var URIMap = URIMaps[bundleName];
                    objj_bundles[bundleName]._URIMap = {};
                    for (var source in URIMap) {
                        var URI = URIMap[source];
                        if (URI.toLowerCase().indexOf("mhtml:") === 0)
                            objj_bundles[bundleName]._URIMap[source] = "mhtml:" + DIRECTORY(window.location.href) + '/' + URI.substr("mhtml:".length);
                    }
                } else
                    console.log("no bundle for " + bundleName);
            }
        }
        // **************************************************

        var applicationScript = [];

        var URIMaps = {};
        Object.keys(scope.objj_bundles).forEach(function(bundleName) {
            var bundle = scope.objj_bundles[bundleName];
            var path = rootPath.relative(bundle.path);
            if (bundle._URIMap) {
                URIMaps[path] = {};
                Object.keys(bundle._URIMap).forEach(function(source) {
                    var destination = bundle._URIMap[source];
                    var match;
                    if (match = destination.match(/^mhtml:[^!]*!(.*)$/))
                        destination = "mhtml:" + applicationScriptName + "!" + match[1];
                    URIMaps[path][source] = destination;
                });
            }
        });

        // add fake bundle response bookkeeping
        applicationScript.push("(function() {")
        applicationScript.push("    var didReceiveBundleResponse = " + String(fakeDidReceiveBundleResponse));
        applicationScript.push("    var setupURIMaps = " + String(setupURIMaps));
        applicationScript.push("    var bundleArchiveResponses = " + JSON.stringify(bundleArchiveResponses) + ";");
        applicationScript.push("    for (var i = 0; i < bundleArchiveResponses.length; i++)");
        applicationScript.push("        didReceiveBundleResponse(bundleArchiveResponses[i]);");
        applicationScript.push("    var URIMaps = " + JSON.stringify(URIMaps) + ";");
        applicationScript.push("    setupURIMaps(URIMaps);");
        applicationScript.push("})();");

        // add each fragment, wrapped in a function, along with OBJJ_CURRENT_BUNDLE bookkeeping
        evaledFragments.forEach(function(fragment) {
            if (requiredFiles[fragment.file.path])
            {
                applicationScript.push("(function(OBJJ_CURRENT_BUNDLE) {");
                applicationScript.push(fragment.info);
                applicationScript.push("})(objj_bundles['"+rootPath.relative(fragment.bundle.path)+"']);");
            }
            else
            {
                CPLog.info("Stripping " + rootPath.relative(fragment.file.path));
            }
        });

        // call main once the page has loaded. FIXME: assumes synchronous script loading?
        applicationScript.push("if (window.addEventListener)");
        applicationScript.push("    window.addEventListener('load', main, false);")
        applicationScript.push("else if (window.attachEvent)")
        applicationScript.push("    window.attachEvent('onload', main);");

        // MHTML
        // TODO: combine multiple MHTMLs
        exectuableResponses.forEach(function(aResponse) {
            var mhtmlStart = aResponse.text.lastIndexOf("/*");
            var mhtmlEnd = aResponse.text.lastIndexOf("*/");
            if (mhtmlStart >= 0 && mhtmlEnd > mhtmlStart) {
                applicationScript.push(aResponse.text.slice(mhtmlStart, mhtmlEnd+2));
            }
        });

        var indexHTML = FILE.read(FILE.join(rootPath, "index.html"), { charset : "UTF-8" });

        // comment out any OBJJ_MAIN_FILE defintions or objj_import() calls
        indexHTML = indexHTML.replace(/(\bOBJJ_MAIN_FILE\s*=|\bobjj_import\s*\()/g, '//$&');

        // add a script tag for Application.js at the very end of the <head> block
        indexHTML = indexHTML.replace(/([ \t]*)(<\/head>)/, '$1    <script src = "'+applicationScriptName+'" type = "text/javascript"></script>\n$1$2');

        // output Application.js and index.html
        outputFiles[rootPath.join(applicationScriptName)] = applicationScript.join("\n");
        outputFiles[rootPath.join(indexHTMLName)] = indexHTML;
    }
    else
    {
        // phase 3b: rebuild .sj files with correct imports, copy .j files
        CPLog.error("PHASE 3b: Rebuild .sj");

        var bundles = {};

        for (var path in requiredFiles)
        {
            var file = scope.objj_files[path],
                filename = FILE.basename(path),
                directory = FILE.dirname(path);

            if (file.path != path)
                CPLog.warn("Sanity check failed (file path): " + file.path + " vs. " + path);

            if (file.bundle)
            {
                var bundleDirectory = FILE.path(file.bundle.path).dirname();

                if (!bundles[file.bundle.path])
                    bundles[file.bundle.path] = file.bundle;

                if (bundleDirectory != directory)
                    CPLog.warn("Sanity check failed (directory path): " + directory + " vs. " + bundleDirectory);

                // if it's in a .sj
                var dict = file.bundle.info,
                    bundlePlatforms = [dict objectForKey:"CPBundlePlatforms"],
                    replacedFilePlatforms = [dict objectForKey:"CPBundleReplacedFiles"];

                // compute the platform used for this bundle
                var platform = "";
                if (bundlePlatforms)
                    platform = [bundlePlatforms firstObjectCommonWithArray:scope.OBJJ_PLATFORMS];

                var replacedFiles = [replacedFilePlatforms objectForKey:platform];
                if (replacedFiles && [replacedFiles containsObject:filename])
                {
                    var staticPath = bundleDirectory.join(platform + ".platform", [dict objectForKey:"CPBundleExecutable"]);
                    if (!outputFiles[staticPath])
                    {
                        outputFiles[staticPath] = [];
                        outputFiles[staticPath].push("@STATIC;1.0;");
                    }
                    outputFiles[staticPath].push("p;");
                    outputFiles[staticPath].push(filename.length+";");
                    outputFiles[staticPath].push(filename);

                    for (var i = 0; i < file.fragments.length; i++)
                    {
                        if (file.fragments[i].type & FRAGMENT_CODE)
                        {
                            outputFiles[staticPath].push("c;");
                            outputFiles[staticPath].push(file.fragments[i].info.length+";");
                            outputFiles[staticPath].push(file.fragments[i].info);
                        }
                        else if (file.fragments[i].type & FRAGMENT_FILE)
                        {
                            var ignoreFragment = false;
                            if (file.fragments[i].conditionallyIgnore)
                            {
                                var importPath = findImportInObjjFiles(scope, file.fragments[i]);
                                if (!importPath || !requiredFiles[importPath])
                                {
                                    ignoreFragment = true;
                                }
                            }

                            if (!ignoreFragment)
                            {
                                if (file.fragments[i].type & FRAGMENT_LOCAL)
                                {
                                    var relativePath = pathRelativeTo(file.fragments[i].info, directory)

                                    outputFiles[staticPath].push("i;");
                                    outputFiles[staticPath].push(relativePath.length+";");
                                    outputFiles[staticPath].push(relativePath);
                                }
                                else
                                {
                                    outputFiles[staticPath].push("I;");
                                    outputFiles[staticPath].push(file.fragments[i].info.length+";");
                                    outputFiles[staticPath].push(file.fragments[i].info);
                                }
                            }
                            else
                                CPLog.info("Ignoring import fragment " + file.fragments[i].info + " in " + rootPath.relative(path));
                        }
                        else
                            CPLog.error("Unknown fragment type");
                    }
                }
                // always output individual .j files
                else
                {
                    outputFiles[path] = file.contents;
                }
            }
            else
                CPLog.warn("No bundle for " + rootPath.relative(path))
        }

        // phase 3.5: fix bundle plists
        CPLog.error("PHASE 3.5: fix bundle plists");

        for (var path in bundles)
        {
            var directory = FILE.dirname(path),
                dict = bundles[path].info,
                replacedFiles = [dict objectForKey:"CPBundleReplacedFiles"];

            CPLog.info("Modifying .sj: " + rootPath.relative(path));

            if (replacedFiles)
            {
                var newReplacedFiles = [];
                [dict setObject:newReplacedFiles forKey:"CPBundleReplacedFiles"];

                for (var i = 0; i < replacedFiles.length; i++)
                {
                    var replacedFilePath = directory + "/" + replacedFiles[i]
                    if (!requiredFiles[replacedFilePath])
                    {
                        CPLog.info("Removing: " + replacedFiles[i]);
                    }
                    else
                    {
                        //CPLog.info("Keeping: " + replacedFiles[i]);
                        newReplacedFiles.push(replacedFiles[i]);
                    }
                }
            }
            outputFiles[path] = CPPropertyListCreateXMLData(dict).string;
        }
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

function functionHookBefore(object, property, func)
{
    var original = object[property];
    object[property] = function() {
        func.apply(this, arguments);
        var result = original.apply(this, arguments);
        return result;
    }
}

function pathRelativeTo(target, relativeTo)
{
    // TODO: fix FILE.relative to always treat the source as a directory
    return FILE.relative(FILE.join(relativeTo, ""), target);
}
