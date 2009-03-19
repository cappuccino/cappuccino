@import <Foundation/Foundation.j>

@import "objj-analysis-tools.j"

var defaultMain = "main.j",
    defaultFrameworks = "Frameworks";

var usageMessage =
"Usage: press root_directory output_directory [options]\n\
        --main path         The relative path (from root_directory) to the main file (default: 'main.j')\n\
        --frameworks path   The relative path (from root_directory) to the frameworks directory (default: 'Frameworks')\n\
        --png               Run pngcrush on all PNGs (pngcrush must be installed!)\n\
        --flatten           Flatten all code into a single Application.js file and attempt add script tag to index.html (useful for Adobe AIR and CDN deployment)\n\
        --nostrip           Don't strip any files\n\
        --v                 Verbose";

function main()
{
    var rootDirectory = null,
        outputDirectory = null,
        mainFilename = null,
        frameworksDirectory = null,
        optimizePNG = false,
        flatten = false,
        noStrip = false,
        verbose = false;
    
    var usageError = false;
    while (args.length && !usageError)
    {
        var arg = args.shift();
        switch(arg)
        {
            case "--main":
                if (args.length)
                    mainFilename = args.shift();
                else
                    usageError = true;
                break;
            case "--frameworks":
                if (args.length)
                    frameworksDirectory = args.shift().replace(/\/$/, "");
                else
                    usageError = true;
                break;
            case "--png":
                optimizePNG = true;
                break;
            case "--flatten":
                flatten = true;
                break;
            case "--nostrip":
                noStrip = true;
                break;
            case "--v":
                verbose = true;
                break;
            default:
                if (rootDirectory == null)
                    rootDirectory = arg.replace(/\/$/, "");
                else if (outputDirectory == null)
                    outputDirectory = arg.replace(/\/$/, "");
                else
                    usageError = true;
        }
    }
    
    if (verbose)
        CPLogRegister(CPLogPrint);
    else
        CPLogRegisterRange(CPLogPrint, "fatal", "info");
        
    if (usageError || rootDirectory == null || outputDirectory == null)   
    {
        print(usageMessage);
        return;
    }
    
    rootDirectory = absolutePath(rootDirectory);
    
    // determine main and frameworks paths
    var mainPath = rootDirectory + "/" + (mainFilename || defaultMain),
        frameworksPath = rootDirectory + "/" + (frameworksDirectory || defaultFrameworks);
        
    CPLog.info("Application root:    " + rootDirectory);
    CPLog.info("Output directory:    " + outputDirectory);
    CPLog.info("Main file:           " + mainPath)
    CPLog.info("Frameworks:          " + frameworksPath);
    
    // get a Rhino context
    var cx = Packages.org.mozilla.javascript.Context.getCurrentContext(),
        scope = makeObjjScope(cx);
    
    // set OBJJ_INCLUDE_PATHS to include the frameworks path
    scope.OBJJ_INCLUDE_PATHS = [frameworksPath];
    
    // flattening bookkeeping. keep track of the bundles and evaled code (in the correct order!)
    var bundleArchives = [],
        evaledFragments = [];

    scope.objj_search.prototype.didReceiveBundleResponseOriginal = scope.objj_search.prototype.didReceiveBundleResponse;
    scope.objj_search.prototype.didReceiveBundleResponse = function(aResponse) {
        //CPLog.trace("RESPONSE: " + aResponse);
    
        var __fakeResponse = {
            success : aResponse.success,
            filePath : pathRelativeTo(aResponse.filePath, rootDirectory)
        };
    
        if (aResponse.success)
        {
            var xmlOutput = new Packages.java.io.ByteArrayOutputStream();
            outputTransformer(xmlOutput, aResponse.xml, "UTF-8");
            //__fakeResponse.xml = String(xmlOutput.toString());
            __fakeResponse.text = CPPropertyListCreate280NorthData(CPPropertyListCreateFromXMLData({ string:String(xmlOutput.toString())})).string;
            //CPLog.trace("SERIALIZED: " + __fakeResponse.xml.substring(0,100));
        }
        
        bundleArchives.push(__fakeResponse);
    
        this.didReceiveBundleResponseOriginal.apply(this, arguments);
    }
    
    // phase 1: get global defines
    CPLog.error("PHASE 1: Loading application...");
    
    var globals = findGlobalDefines(cx, scope, mainPath, evaledFragments);
    
    // coalesce the results
    var dependencies = coalesceGlobalDefines(globals);
    
    // Log 
    CPLog.trace("Global defines:");
    for (var i in dependencies)
        CPLog.trace("    " + i + " => " + dependencies[i]);
    
    // phase 2: walk the dependency tree (both imports and references) to determine exactly which files need to be included
    CPLog.error("PHASE 2: Walk dependency tree...");
    
    var requiredFiles = {};
    
    if (noStrip)
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
        
        var context = {
            scope : scope,
            dependencies : dependencies,
            processedFiles : {},
            ignoreFrameworkImports : true,
            importCallback : function(importing, imported) {
                requiredFiles[imported] = true;
            },
            referenceCallback : function(referencing, referenced) {
                requiredFiles[referenced] = true;
            }
        }
        
        requiredFiles[mainPath] = true;
        traverseDependencies(context, scope.objj_files[mainPath]);
        
        var count = 0,
            total = 0;
        for (var path in scope.objj_files)
        {
            if (requiredFiles[path])
            {
                CPLog.debug("Included: " + path);
                count++;
            }
            else
            {
                CPLog.info("Excluded: " + path);
            }    
            total++;
        }
        CPLog.warn("Total required files: " + count + " out of " + total);
        
        // FIXME: sprite images
        //for (var i in context.bundleImages)
        //{
        //    var images = context.bundleImages[i];
        //    
        //    CPLog.debug("Bundle images for " + i);
        //    for (var j in images)
        //        CPLog.trace(j + " = " + images[j]);
        //}
    }
    
    var outputFiles = {};
    
    if (flatten)
    {
        // phase 3a: build single Application.js file (and modified index.html)
        CPLog.error("PHASE 3a: Flattening...");
        
        var applicationJS = [],
            indexHTML = readFile(rootDirectory + "/index.html");
        
        // shim for faking bundle stuff. kind of a giant hack.
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
        
        // add fake bundle response bookkeeping
        applicationJS.push("var __fakeDidReceiveBundleResponse = " + String(fakeDidReceiveBundleResponse));
        applicationJS.push("var __fakeBundleArchives = " + CPJSObjectCreateJSON(bundleArchives) + ";");
        applicationJS.push("for (var i = 0; i < __fakeBundleArchives.length; i++) __fakeDidReceiveBundleResponse(__fakeBundleArchives[i]);")
        
        // add each fragment, wrapped in a function, along with OBJJ_CURRENT_BUNDLE bookkeeping
        for (var i = 0; i < evaledFragments.length; i++)
        {
            if (requiredFiles[evaledFragments[i].file.path])
            {
                applicationJS.push("(function() {");
                applicationJS.push("var OBJJ_CURRENT_BUNDLE = objj_bundles['"+pathRelativeTo(evaledFragments[i].bundle.path, rootDirectory)+"'];");
                applicationJS.push(evaledFragments[i].info);
                applicationJS.push("})();");
            }
            else
            {
                CPLog.info("Stripping " + evaledFragments[i].file.path);
            }
        }
        
        // call main once the page has loaded
        applicationJS.push(
            "if (window.addEventListener) \
                window.addEventListener('load', main, false); \
            else if (window.attachEvent) \
                window.attachEvent('onload', main);"
        );
        
        // comment out any OBJJ_MAIN_FILE defintions or objj_import() calls
        indexHTML = indexHTML.replace(/(\bOBJJ_MAIN_FILE\s*=|\bobjj_import\s*\()/g, '//$&');
        
        // add a script tag for Application.js at the very end of the <head> block
        indexHTML = indexHTML.replace(/([ \t]*)(<\/head>)/, '$1    <script src = "Application.js" type = "text/javascript"></script>\n$1$2');
        
        // output Application.js and index.html
        outputFiles[rootDirectory + "/Application.js"] = applicationJS.join("\n");
        outputFiles[rootDirectory + "/index.html"] = indexHTML;
    }
    else
    {
        // phase 3b: rebuild .sj files with correct imports, copy .j files
        CPLog.error("PHASE 3b: Rebuild .sj");

        var bundles = {};
        
        for (var path in requiredFiles)
        {
            var file = scope.objj_files[path],
                filename = basename(path),
                directory = dirname(path);
    
            if (file.path != path)
                CPLog.warn("Sanity check failed (file path): " + file.path + " vs. " + path);
    
            if (file.bundle)
            {
                var bundleDirectory = dirname(file.bundle.path);
        
                if (!bundles[file.bundle.path])
                    bundles[file.bundle.path] = file.bundle;
            
                if (bundleDirectory != directory)
                    CPLog.warn("Sanity check failed (directory path): " + directory + " vs. " + bundleDirectory);
        
                // if it's in a .sj
                var dict = file.bundle.info,
                    replacedFiles = [dict objectForKey:"CPBundleReplacedFiles"];
                if (replacedFiles && [replacedFiles containsObject:filename])
                {
                    var staticPath = bundleDirectory + "/" + [dict objectForKey:"CPBundleExecutable"];
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
                                CPLog.info("Ignoring import fragment " + file.fragments[i].info + " in " + path);
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
                CPLog.warn("No bundle for " + path)
        }

        // phase 3.5: fix bundle plists
        CPLog.error("PHASE 3.5: fix bundle plists");
        
        for (var path in bundles)
        {
            var directory = dirname(path),
                dict = bundles[path].info,
                replacedFiles = [dict objectForKey:"CPBundleReplacedFiles"];
            
            CPLog.info("Modifying .sj: " + path);
            
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
    
    // phase 4: copy everything and write out the new files
    CPLog.error("PHASE 4: copy to output");
    
    var rootDirectoryFile = new Packages.java.io.File(rootDirectory),
        outputDirectoryFile = new Packages.java.io.File(outputDirectory);
    
    // FIXME: intelligently copy only what we need (Resources directories?)
    copyDirectory(rootDirectoryFile, outputDirectoryFile, optimizePNG);
    
    for (var path in outputFiles)
    {
        var file = new java.io.File(outputDirectoryFile, pathRelativeTo(path, rootDirectory));
        
        var parent = file.getParentFile();
        if (!parent.exists())
        {
            CPLog.warn(parent + " doesn't exist, creating directories.");
            parent.mkdirs();
        }
        
        CPLog.info("Writing out " + file);
        
        var writer = new java.io.BufferedWriter(new java.io.FileWriter(file));
        
        if (typeof outputFiles[path] == "string")
            writer.write(outputFiles[path]);
        else
            writer.write(outputFiles[path].join("")); 
        
        writer.close();
    }
}

// Helper Utilities

// TODO: moved elsewhere?

function copyDirectory(src, dst, optimizePNG)
{
    CPLog.trace("Copying directory " + src);
    
    dst.mkdirs();

    var files = src.listFiles();
    for (var i = 0; i < files.length; i++)
    {
        if (files[i].isFile())
            copyFile(files[i], new Packages.java.io.File(dst, files[i].getName()), optimizePNG);
        else if (files[i].isDirectory())
            copyDirectory(files[i], new Packages.java.io.File(dst, files[i].getName()), optimizePNG);
    }
}

function copyFile(src, dst, optimizePNG)
{
    if (optimizePNG && (/.png$/).test(src.getName()))
    {
        CPLog.warn("Optimizing .png " + src);
        exec(["pngcrush", "-rem", "alla", "-reduce", /*"-brute",*/ src.getAbsolutePath(), dst.getAbsolutePath()]);
    }
    else
    {
        CPLog.trace("Copying file " + src);
        
        var input = (new Packages.java.io.FileInputStream(src)).getChannel(),
            output = (new Packages.java.io.FileOutputStream(dst)).getChannel();

        input.transferTo(0, input.size(), output);

        input.close();
        output.close();
    }
}

function dirname(path)
{
    return path.substring(0, path.lastIndexOf("/"));
}

function basename(path)
{
    return path.substring(path.lastIndexOf("/") + 1);
}

function absolutePath(path)
{
    return String((new Packages.java.io.File(path)).getCanonicalPath());
}

function pathRelativeTo(target, relativeTo)
{
    var components = [],
        targetParts = target.split("/"),
        relativeParts = relativeTo ? relativeTo.split("/") : [];

    var i = 0;
    while (i < targetParts.length)
    {
        if (targetParts[i] != relativeParts[i])
            break;
        i++;
    }
    
    for (var j = i; j < relativeParts.length; j++)
        components.push("..");
    
    for (var j = i; j < targetParts.length; j++)
        components.push(targetParts[j]);
    
    var result = components.join("/");
    
    return result;
}

function exec()
{
    var printOutput = false;
    
    var runtime = Packages.java.lang.Runtime.getRuntime()
	var p = runtime.exec.apply(runtime, arguments);
	
	var stdout = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream())),
	    stdoutString = "",
	    stderr = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream())),
	    stderrString = "";
	
	var done = false;
	while (!done)
	{
	    done = true;
	    if (s = stdout.readLine())
	    {
    	    stdoutString += s;
    	    if (printOutput)
        	    CPLog.info("exec: " + s);
        	done = false;
	    }
	    if (s = stderr.readLine())
    	{
    	    stderrString += s;
    	    //if (printOutput)
        	    CPLog.warn("exec: " + s);
        	done = false;
    	}
	}

	var code = p.waitFor();
		
	return { code : code, stdout : stdoutString, stderr : stderrString };
}

function outputTransformer(os, document, encoding, standalone)
{
	var domSource       = new Packages.javax.xml.transform.dom.DOMSource(document);
	var streamResult    = new Packages.javax.xml.transform.stream.StreamResult(os);
	var tf              =     Packages.javax.xml.transform.TransformerFactory.newInstance();

	var serializer = tf.newTransformer();
	serializer.setOutputProperty(Packages.javax.xml.transform.OutputKeys.VERSION, "1.0");
	serializer.setOutputProperty(Packages.javax.xml.transform.OutputKeys.INDENT, "yes");
	if (encoding)
		serializer.setOutputProperty(Packages.javax.xml.transform.OutputKeys.ENCODING, encoding);
	if (standalone)
		serializer.setOutputProperty(Packages.javax.xml.transform.OutputKeys.STANDALONE,	(standalone ? "yes" : "no"));

	String(serializer.transform(domSource, streamResult));
}

main();
