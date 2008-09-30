import <Foundation/CPLog.j>

import "objj-analysis-tools.j"

CPLogRegister(CPLogPrint);


function main()
{
    if (args.length < 2)
    {
        print("Usage: press input_base_file.j output_directory");
        return;
    }
    
    var rootPath = args[0],
        sourceDirectory = dirname(rootPath) || ".",
        outputDirectory = args[1];
    
    var cx = Packages.org.mozilla.javascript.Context.enter(),
        scope = makeObjjScope(cx);
    
    var frameworks = rootPath.substring(0, rootPath.lastIndexOf("/")+1) + "Frameworks/";
    scope.OBJJ_INCLUDE_PATHS = [frameworks];

    CPLog.info("OBJJ_INCLUDE_PATHS="+scope.OBJJ_INCLUDE_PATHS);
    
    // phase 1: get global defines
    
    var globals = findGlobalDefines(cx, scope, rootPath);
    
    // coalesce the results
    var dependencies = coalesceGlobalDefines(globals);
    
    // phase 2: walk the import tree to determine exactly which files need to be included
    
    var requiredFiles = {};
    
    if (scope.objj_files[rootPath])
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
        
        traverseDependencies(context, scope.objj_files[rootPath]);
        
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
                    else if (file.fragments[i].type & FRAGMENT_IMPORT)
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
                            else if (file.fragments[i].type & FRAGMENT_FILE)
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
    
    var sourceDirectoryFile = new Packages.java.io.File(sourceDirectory),
        outputDirectoryFile = new Packages.java.io.File(outputDirectory);
        
    copyDirectory(sourceDirectoryFile, outputDirectoryFile);
    
    for (var path in outputFiles)
    {
        var file = new java.io.File(outputDirectoryFile, path);
        
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

function copyDirectory(src, dst)
{
    CPLog.trace("Copying directory " + src);
    
    dst.mkdirs();

    var files = src.listFiles();
    for (var i = 0; i < files.length; i++)
    {
        if (files[i].isFile())
            copyFile(files[i], new Packages.java.io.File(dst, files[i].getName()));
        else if (files[i].isDirectory())
            copyDirectory(files[i], new Packages.java.io.File(dst, files[i].getName()));
    }
}

function copyFile(src, dst)
{
    CPLog.trace("Copying file " + src);
    
    var input = (new Packages.java.io.FileInputStream(src)).getChannel(),
        output = (new Packages.java.io.FileOutputStream(dst)).getChannel();

    input.transferTo(0, input.size(), output);

    input.close();
    output.close();
}

function dirname(path)
{
    return path.substring(0, path.lastIndexOf("/"));
}

function basename(path)
{
    return path.substring(path.lastIndexOf("/") + 1);
}

function pathRelativeTo(target, relativeTo)
{
    var components = [],
        targetParts = target.split("/"),
        relativeParts = relativeTo.split("/");

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
        
    return components.join("/");
}

main();
