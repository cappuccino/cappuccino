import <Foundation/CPLog.j>

import "objj-analysis-tools.j"

CPLogRegister(CPLogPrint);

var defaultMain = "main.j",
    defaultFrameworks = "Frameworks";

function main()
{
    var rootDirectory = null,
        outputDirectory = null,
        mainFilename = null,
        frameworksDirectory = null,
        optimizePNG = false;
    
    var usageError = false;
    while (args.length && !usageError)
    {
        var arg = args.shift();
        switch(arg)
        {
            case "--png":
                optimizePNG = true;
                break;
            case "--main":
                if (args.length)
                    mainFile = args.shift();
                else
                    usageError = true;
                break;
            case "--frameworks":
                if (args.length)
                    frameworksDirectory = args.shift().replace(/\/$/, "");
                else
                    usageError = true;
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
    
    if (rootDirectory == null || outputDirectory == null)   
    {
        print("Usage: press root_directory output_directory [--main override_main.j] [--frameworks override_frameworks] [--png]");
        return;
    }
    
    rootDirectory = absolutePath(rootDirectory);
    
    // determine main and frameworks paths
    var mainPath = rootDirectory + "/" + (mainFilename || defaultMain),
        frameworksPath = rootDirectory + "/" + (frameworksDirectory || defaultFrameworks);
        
    CPLog.info("root=" + rootDirectory);
    CPLog.info("output=" + outputDirectory);
    CPLog.info("main=" + mainPath)
    CPLog.info("frameworks=" + frameworksPath);
    
    // get Rhino context
    var cx = Packages.org.mozilla.javascript.Context.getCurrentContext(), //Packages.org.mozilla.javascript.Context.enter(),
        scope = makeObjjScope(cx);
    
    // set OBJJ_INCLUDE_PATHS to include the frameworks path
    scope.OBJJ_INCLUDE_PATHS = [frameworksPath];
    CPLog.info("OBJJ_INCLUDE_PATHS="+scope.OBJJ_INCLUDE_PATHS);
    
    // phase 1: get global defines
    var globals = findGlobalDefines(cx, scope, mainPath);
    
    // coalesce the results
    var dependencies = coalesceGlobalDefines(globals);
    
    // phase 2: walk the dependency tree (both imports and references) to determine exactly which files need to be included
    
    var requiredFiles = {};
    
    if (scope.objj_files[mainPath])
    {
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
                CPLog.info("Included: " + path);
                count++;
            }
            else
            {
                CPLog.warn("Excluded: " + path);
            }    
            total++;
        }
        CPLog.error("Total required files: " + count + " out of " + total);
    }
    else
    {
        CPLog.error("Root file not loaded!");
        return;
    }
        
    // phase 3: rebuild .sj files with correct imports, copy .j files
    
    var outputFiles = {};
    for (var path in requiredFiles)
    {
        var file = scope.objj_files[path],
            filename = basename(path),
            directory = dirname(path);
        
        if (file.path != path)
            CPLog.warn("Sanity check (file path): " + file.path + " vs. " + path);
        
        if (file.bundle)
        {
            var bundleDirectory = dirname(file.bundle.path);
        
            if (bundleDirectory != directory)
                CPLog.warn("Sanity check (directory path): " + directory + " vs. " + bundleDirectory);
            
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
                            CPLog.warn("Ignoring import fragment " + file.fragments[i].info + " in " + path);
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
    
    // phase 4: copy everything and write out the new files
    
    var rootDirectoryFile = new Packages.java.io.File(rootDirectory),
        outputDirectoryFile = new Packages.java.io.File(outputDirectory);
        
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

main();
