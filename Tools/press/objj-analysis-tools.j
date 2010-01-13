var FILE = require("file");

/*
    param context includes
        scope:                  a global variable containing objj_files hash
        ctx:                    js context
        dependencies:           hash mapping from paths to an array of global variables defined by that file
        [importCallback]:       callback function that is called for each imported file (takes importing file path, and imported file path parameters)
        [referencedCallback]:   callback function that is called for each referenced file (takes referencing file path, referenced file path parameters, and list of tokens)
        [importedFiles]:        hash that will contain a mapping of file names to a hash of imported files
        [referencedFiles]:      hash that will contain a mapping of file names to a hash of referenced files (which contains a hash of tokens referenced)
        [processedFiles]:       hash containing file paths which have already been analyzed

    param file is an objj_file object containing path, fragments, content, bundle, etc
*/
function traverseDependencies(context, file)
{
    if (!context.processedFiles)
        context.processedFiles = {};

    if (context.processedFiles[file.path])
        return;
    context.processedFiles[file.path] = true;

    var ignoreImports = false;
    if (context.ignoreAllImports)
    {
        CPLog.warn("Ignoring all import fragments. ("+context.rootPath.relative(file.path)+")");
        ignoreImports = true;
    }
    else if (context.ignoreFrameworkImports)
    {
        var matches = file.path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$")); // Matches "ZZZ/ZZZ.j" (e.x. AppKit/AppKit.j and Foundation/Foundation.j)
        if (matches && matches[1] === matches[2])
        {
            CPLog.warn("Framework import file! Ignoring all import fragments. ("+context.rootPath.relative(file.path)+")");
            ignoreImports = true;
        }
    }

    // if fragments are missing, preprocess the contents
    if (!file.fragments)
    {
        if (file.included)
            CPLog.warn(context.rootPath.relative(file.path) + " is included but missing fragments");
        else
            CPLog.warn("Preprocessing " + context.rootPath.relative(file.path));

        file.fragments = objj_preprocess(file.contents, file.bundle, file);
    }

    // sprite: look for pngs in the Resources directory
    if (!context.bundleImages)
        context.bundleImages = {};

    if (!context.bundleImages[file.bundle.path])
    {
        var resourcesPath = FILE.path(file.bundle.path).dirname().join("/Resources");
        if (resourcesPath.exists())
        {
            context.bundleImages[file.bundle.path] = {};

            resourcesPath.glob("**/*.png").forEach(function(png) {
                var pngPath = resourcesPath.join(png);
                var relativePath = pathRelativeTo(pngPath.absolute(), resourcesPath.absolute());

                // this is used as a bit mask, not a boolean
                context.bundleImages[file.bundle.path][relativePath] = 1;
            });
        }
    }
    var images = context.bundleImages[file.bundle.path];

    var referencedFiles = {},
        importedFiles = {};

    CPLog.debug("Processing " + file.fragments.length + " fragments in " + context.rootPath.relative(file.path));
    for (var i = 0; i < file.fragments.length; i++)
    {
        var fragment = file.fragments[i];

        if (fragment.type & FRAGMENT_CODE)
        {
            var lexer = new objj_lexer(fragment.info, NULL);

            var token;
            while (token = lexer.skip_whitespace())
            {
                if (context.dependencies.hasOwnProperty(token))
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
                        CPLog.error("Ignoring self import (why are you importing yourself?!): " + context.rootPath.relative(file.path));
                }
                else
                    CPLog.error("Couldn't find file for import " + fragment.info + " ("+fragment.type+")");
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

            if (context.scope.objj_files.hasOwnProperty(referencedFile))
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
function findGlobalDefines(context, mainPath, evaledFragments)
{
    var ignore = cloneProperties(context.scope, true);
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
    var fragment_evaluate_file_original = context.scope.fragment_evaluate_file;
    context.scope.fragment_evaluate_file = function(aFragment) {
        return fragment_evaluate_file_original(aFragment);
    }

    // OVERRIDE fragment_evaluate_code
    var fragment_evaluate_code_original = context.scope.fragment_evaluate_code;
    context.scope.fragment_evaluate_code = function(aFragment) {

        CPLog.debug("Evaluating " + context.rootPath.relative(aFragment.file.path) + " (" + context.rootPath.relative(aFragment.bundle.path) + ")");

        var before = cloneProperties(context.scope);

        if (evaledFragments)
        {
            evaledFragments.push(aFragment);
        }

        var result = fragment_evaluate_code_original(aFragment);

        var definedGlobals = {};
        diff(before, context.scope, ignore, definedGlobals, definedGlobals, null);
        dependencies[aFragment.file.path] = definedGlobals;

        return result;
    }

    runWithScope(context, function(importName) {
        objj_import(importName, true, function() {
            // Doesn't work due to lack of complete browser environment
            //[_CPAppBootstrapper loadDefaultTheme];
            
            var themePath = [[CPBundle bundleForClass:[CPApplication class]] pathForResource:[CPApplication defaultThemeName]];
            var themeBundle = [[CPBundle alloc] initWithPath:themePath + "/Info.plist"];
            [themeBundle loadWithDelegate:nil];
            // FIXME: doesn't use objj_search mechanism. need to hook CPBundle or CPURLConnection instead.
        });
    }, [mainPath]);

    return dependencies;
}

// takes a hash mapping from file names to hashes of global names defined in each file
//    globals = { fileName { globalName : true }}
// returns a hash mapping from global names to arrays of file names in which those globals are defined
//    dependencies = { globalName : [fileName] }
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

// create a new scope loaded with Narwhal and Objective-J
function makeObjjScope(ctx, debug)
{
    // init standard JS scope objects
    var scope = ctx.initStandardObjects();

    // set these properties required for Narwhal bootstrapping
    scope.NARWHAL_HOME = system.prefix;
    scope.NARWHAL_ENGINE_HOME = FILE.join(system.prefix, "engines", "rhino");

    // load the bootstrap.js for narwhal-rhino
    var bootstrapPath = FILE.join(scope.NARWHAL_ENGINE_HOME, "bootstrap.js");
    ctx.evaluateReader(scope,
        new Packages.java.io.FileReader(bootstrapPath),
        "bootstrap.js",
        1,
        null
    );

    // get the Objective-J module from this scope, return the window object.
    var OBJJ = scope.require("objective-j");

    addMockBrowserEnvironment(OBJJ.window);

    return OBJJ.window;
}

// add a mock browser environment to the provided scope
function addMockBrowserEnvironment(scope)
{
    // TODO: complete this. or use env.js?

    if (!scope.window)
        scope.window = scope;

    if (!scope.location)
        scope.location = {};

    if (!scope.location.href)
        scope.location.href = "";

    if (!scope.Element)
        scope.Element = function() {
            this.style = {}
        }

    if (!scope.document)
        scope.document = {
            createElement : function() {
                return new scope.Element();
            }
        }
}

// run a function within the given scope (func can be a function object if the source of the function is returned by toString() as it is by default)
function runWithScope(context, func, args)
{
    var functionInScope = context.ctx.compileFunction(context.scope, String(func), "<runWithScope>", 1, null);

    var result = functionInScope.apply(context.scope, args);

    context.scope.require('browser/timeout').serviceTimeouts();

    return result;
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
