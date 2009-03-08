var objjPath    = OBJJ_LIB+'/Frameworks-Rhino/Objective-J/Objective-J.js',
    bridgePath  = OBJJ_LIB+'/bridge.js',
    envPath     = "/Users/tlrobinson/280North/git/cappuccino/Tools/press/env.js";
    
/*
    param context includes
        scope:                  a global variable containing objj_files hash
        processedFiles:         hash containing file paths which have already been analyzed
        dependencies:           hash mapping from paths to an array of global variables defined by that file
        [importCallback]:       callback function that is called for each imported file (takes importing file path, and imported file path parameters)
        [referencedCallback]:   callback function that is called for each referenced file (takes referencing file path, referenced file path parameters, and list of tokens)
        [importedFiles]:        hash that will contain a mapping of file names to a hash of imported files
        [referencedFiles]:      hash that will contain a mapping of file names to a hash of referenced files (which contains a hash of tokens referenced)
        
    param file is an objj_file object containing path, fragments, content, bundle, etc
*/
function traverseDependencies(context, file)
{
    if (context.processedFiles[file.path])
        return;
    context.processedFiles[file.path] = true;
    
    var ignoreImports = false;
    if (context.ignoreAllImports)
    {
        CPLog.warn("Ignoring all import fragments. ("+file.path+")");
        ignoreImports = true;
    }
    else if (context.ignoreFrameworkImports)
    {
        var matches = file.path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$")); // Matches "ZZZ/ZZZ.j" (e.x. AppKit/AppKit.j and Foundation/Foundation.j)
        if (matches && matches[1] === matches[2])
        {
            CPLog.warn("Framework import file! Ignoring all import fragments. ("+file.path+")");
            ignoreImports = true;
        }
    }
    
    // if fragments are missing, preprocess the contents
    if (!file.fragments)
    {
        if (file.included)
            CPLog.warn(file.path + " is included but missing fragments");
        else
            CPLog.warn("Preprocessing " + file.path);
        
        file.fragments = objj_preprocess(file.contents, file.bundle, file);
    }
        
    // sprite: look for pngs in the Resources directory
    if (!context.bundleImages)
        context.bundleImages = {};
    
    if (!context.bundleImages[file.bundle.path])
    {
        var resourcesFile = new java.io.File(dirname(file.bundle.path) + "/Resources");
        if (resourcesFile.exists())
        {
            context.bundleImages[file.bundle.path] = {};
            
            var pngFiles = find(resourcesFile, (new RegExp("\\.png$")));
            for (var i = 0; i < pngFiles.length; i++)
            {
                var path = pathRelativeTo(pngFiles[i].getCanonicalPath(), resourcesFile.getCanonicalPath());
                context.bundleImages[file.bundle.path][path] = 1;
            }
        }
    }
    var images = context.bundleImages[file.bundle.path];
    
    var referencedFiles = {},
        importedFiles = {};
    
    CPLog.debug("Processing " + file.path + " fragments ("+file.fragments.length+")");
    for (var i = 0; i < file.fragments.length; i++)
    {
        var fragment = file.fragments[i];
        
        if (fragment.type & FRAGMENT_CODE)
        {
            var lexer = new objj_lexer(fragment.info, NULL);
            
            var token;
            while (token = lexer.skip_whitespace())
            {
                if (context.dependencies[token])
                {
                    var files = context.dependencies[token];
                    for (var j = 0; j < files.length; j++)
                    {
                        // don't record references to self
                        if (files[j] != file.path)
                        {
                            if (!referencedFiles[files[j]])
                                referencedFiles[files[j]] = {};

                            referencedFiles[files[j]][token] = true;
                        }
                    }
                }
                
                var matches = token.match(new RegExp("^['\"](.*)['\"]$"));
                if (matches && images && images[matches[1]])
                    images[matches[1]] = (images[matches[1]] | 2);
            }
        }
        else if (fragment.type & FRAGMENT_FILE)
        {
            if (ignoreImports)
            {
                fragment.conditionallyIgnore = true;
            }
            else
            {
                var importedFile = findImportInObjjFiles(context.scope, fragment);
                if (importedFile)
                {
                    // should never import self, but just in case?
                    if (importedFile != file.path)
                        importedFiles[importedFile] = true;
                    else
                        CPLog.error("Ignoring self import (why are you importing yourself!?): " + file.path);
                }
                else
                    CPLog.error("Couldn't find file for import " + fragment.info + "("+fragment.type+")");
            }
        }
    }
    
    // check each imported file
    for (var importedFile in importedFiles)
    {
        if (importedFile != file.path)
        {
            if (context.importCallback)
                context.importCallback(file.path, importedFile);

            if (context.scope.objj_files[importedFile])
                traverseDependencies(context, context.scope.objj_files[importedFile]);
            else
                CPLog.error("Missing imported file: " + importedFile);
        }
    }
    
    if (context.importedFiles)
        context.importedFiles[file.path] = importedFiles;
    
    // check each referenced file
    for (var referencedFile in referencedFiles)
    {
        if (referencedFile != file.path)
        {
            if (context.referenceCallback)
                context.referenceCallback(file.path, referencedFile, referencedFiles[referencedFile]);
                
            if (context.scope.objj_files[referencedFile])
                traverseDependencies(context, context.scope.objj_files[referencedFile]);
            else
                CPLog.error("Missing referenced file: " + referencedFile);
        }
    }
    
    if (context.referencedFiles)
        context.referencedFiles[file.path] = referencedFiles;
}

function findImportInObjjFiles(scope, fragment)
{
    var importPath = null;

    if (fragment.type & FRAGMENT_LOCAL)
    {
        var searchPath = fragment.info;
        //CPLog.trace("Looking for " + searchPath);
        //for (var i in scope.objj_files) CPLog.debug("    " + i);
        
        if (scope.objj_files[searchPath])
        {
            importPath = searchPath;
        }
    }
    else
    {
        var count = scope.OBJJ_INCLUDE_PATHS.length;
        while (count--)
        {
            var searchPath = scope.OBJJ_INCLUDE_PATHS[count].replace(new RegExp("\\/$"), "") + "/" + fragment.info;
            if (scope.objj_files[searchPath])
            {
                importPath = searchPath;
                break;
            }
        }
    }
    
    return importPath;
}

// given a fresh scope and the path to a root source file, determine which files define each global variable
function findGlobalDefines(context, scope, rootPath, evaledFragments)
{
    addMockBrowserEnvironment(scope);
    
    var ignore = cloneProperties(scope, true);
    ignore['bundle'] = true;
    
    var dependencies = {};
    
    //scope.fragment_evaluate_file_original = scope.fragment_evaluate_file;
    //scope.fragment_evaluate_file = function(aFragment)
    //{
    //    //CPLog.trace("Loading "+aFragment.info);
    //    
    //    var result = scope.fragment_evaluate_file_original(aFragment);
    //    
    //    return result;
    //}
    
    // OVERRIDE fragment_evaluate_file
    var fragment_evaluate_file_original = scope.fragment_evaluate_file;
    scope.fragment_evaluate_file = function(aFragment) {
        return fragment_evaluate_file_original(aFragment);
    }

    // OVERRIDE fragment_evaluate_code
    var fragment_evaluate_code_original = scope.fragment_evaluate_code;
    scope.fragment_evaluate_code = function(aFragment) {
        
        CPLog.debug("Evaling "+aFragment.file.path + " / " + aFragment.bundle.path);
    
        var before = cloneProperties(scope);
        
        if (evaledFragments)
        {
            evaledFragments.push(aFragment);
        }
        
        var result = fragment_evaluate_code_original(aFragment);
    
        var definedGlobals = {};
        diff(before, scope, ignore, definedGlobals, definedGlobals, null);
        dependencies[aFragment.file.path] = definedGlobals;
    
        return result;
    }


    runWithScope(context, scope, function(importName) {    
        objj_import(importName, true, NULL);
    }, [rootPath]);
    
    return dependencies;
}

function coalesceGlobalDefines(globals)
{
    var dependencies = {};
    for (var fileName in globals)
    {
        var fileGlobals = globals[fileName];
        
        for (var globalName in fileGlobals)
        {
            if (!dependencies[globalName])
                dependencies[globalName] = [];
            dependencies[globalName].push(fileName);
        }
    }
    return dependencies;
}

// create a new scope loaded with Objective-J
function makeObjjScope(context, debug)
{
    // init standard js scope objects
    var scope = context.initStandardObjects();

    if (debug)
    {
        scope.objj_alert = print;
        scope.debug = true;
    }
    
    // give the scope "print"
    scope.print = function(value) { Packages.java.lang.System.out.println(String(value)); };
    
    // load and eval fake browser environment
    //var envSource = readFile(envPath);
    //if (envSource)
    //    context.evaluateString(scope, envSource, "env.js", 1, null);
    //else
    //     CPLog.warn("Missing env.js");
        
    // load and eval the bridge
    var bridgeSource = readFile(bridgePath);
    if (bridgeSource)
        context.evaluateString(scope, bridgeSource, "bridge.js", 1, null);
    else
        CPLog.warn("Missing bridge.js");

    // load and eval obj-j
    var objjSource = readFile(objjPath);
    if (objjSource)
        context.evaluateString(scope, objjSource, "Objective-J.js", 1, null);
    else
        CPLog.warn("Missing Objective-J.js");
    
    return scope;
}

// run a function within the given scope (func can be a function object if the source of the function is returned by toString() as it is by default)
function runWithScope(context, scope, func, arguments)
{
    scope.__runWithScopeArgs = arguments || [];

    var code = "("+func+").apply(this, this.__runWithScopeArgs); serviceTimeouts();";

    return context.evaluateString(scope, code, "<cmd>", 1, null);
}

// add a mock browser environment to the provided scope
function addMockBrowserEnvironment(scope)
{
    // TODO: complete this. or use env.js?
    
    scope.Element = function() {
        this.style = {}
    }
    
    scope.document = {
        createElement : function() {
            return new scope.Element();
        }
    }
}

// does a shallow copy of an object. if onlyList is true, it sets each property to "true" instead of the actual value
function cloneProperties(object, onlyList)
{
    var results = {}
    for (var memeber in object)
        results[memeber] = onlyList ? true : object[memeber];
    return results;
}

function diff(objectA, objectB, ignore, added, changed, deleted)
{
    for (var i in objectB)
        if (added && !ignore[i] && typeof objectA[i] == "undefined")
            added[i] = true;
    for (var i in objectB)
        if (changed && !ignore[i] && typeof objectA[i] != "undefined" && typeof objectB[i] != "undefined" && objectA[i] !== objectB[i])
            changed[i] = true;
    for (var i in objectA)
        if (deleted && !ignore[i] && typeof objectB[i] == "undefined")
            deleted[i] = true;
}

function allKeys(object)
{
    var result = [];
    for (var i in object)
        result.push(i)
    return result.sort();
}

function find(src, regex)
{
    var results = [];
    var files = src.listFiles();
    for (var i = 0; i < files.length; i++)
    {
        if (files[i].isFile() && regex.test(files[i].getAbsolutePath()))
            results.push(files[i]);
        else if (files[i].isDirectory())
            results = Array.prototype.concat.apply(results, find(files[i], regex));
    }
    return results;
}