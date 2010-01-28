var FILE = require("file");

/*
    param context includes
        scope:                  the objective-j scope
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

    var referencedFiles = {},
        importedFiles = {};

    CPLog.debug("Processing " + file.fragments.length + " fragments in " + context.rootPath.relative(file.path));
    for (var i = 0; i < file.fragments.length; i++)
    {
        var fragment = file.fragments[i];

        if (fragment.type & FRAGMENT_CODE)
        {
            var referencedTokens = uniqueTokens(fragment.info);
            
            markFilesReferencedByTokens(referencedTokens, context.dependencies, referencedFiles);
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
    checkImported(context, file.path, importedFiles);

    if (context.importedFiles)
        context.importedFiles[file.path] = importedFiles;

    // check each referenced file
    checkReferenced(context, file.path, referencedFiles);

    if (context.referencedFiles)
        context.referencedFiles[file.path] = referencedFiles;
}

function checkImported(context, path, importedFiles) {
    for (var importedFile in importedFiles)
    {
        if (importedFile != path)
        {
            if (context.importCallback)
                context.importCallback(path, importedFile);

            if (context.scope.objj_files[importedFile])
                traverseDependencies(context, context.scope.objj_files[importedFile]);
            else
                CPLog.error("Missing imported file: " + importedFile);
        }
    }
}

function checkReferenced(context, path, referencedFiles) {
    for (var referencedFile in referencedFiles)
    {
        if (referencedFile != path)
        {
            if (context.referenceCallback)
                context.referenceCallback(path, referencedFile, referencedFiles[referencedFile]);

            if (context.scope.objj_files.hasOwnProperty(referencedFile))
                traverseDependencies(context, context.scope.objj_files[referencedFile]);
            else
                CPLog.error("Missing referenced file: " + referencedFile);
        }
    }
}

// returns a unique list of tokens for a piece of code.
// ideally this should return identifiers only
function uniqueTokens(code) {
    // FIXME: this breaks for indentifiers containing "$" since it's considered a distinct token by the parser
    var lexer = new objj_lexer(code, null);

    var token, tokens = {};
    while (token = lexer.skip_whitespace()) {
        tokens[token] = true;
    }

    return Object.keys(tokens);
}

/*
    params:
        tokens (in):                list of tokens to mark as required
        tokenDependenciesMap (in):  map from tokens to files which define those tokens
        referencedFiles (out):      map of required files (to map of tokens defined in that file)
*/
function markFilesReferencedByTokens(tokens, tokenDependenciesMap, referencedFiles) {
    tokens.forEach(function(token) {
        if (tokenDependenciesMap.hasOwnProperty(token))
        {
            var files = tokenDependenciesMap[token];
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
    });
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

@implementation PressBundleDelgate : CPObject
{
    Function didFinishLoadingCallback;
}
- (id)initWithCallback:(Function)aCallback
{
    if (self = [super init]) {
        didFinishLoadingCallback = aCallback;
    }
    return self;
}
- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    print("didFinishLoading: "+aBundle);
    if (didFinishLoadingCallback)
        didFinishLoadingCallback(aBundle);
}
@end

// given a fresh scope and the path to a root source file, determine which files define each global variable
function findGlobalDefines(context, mainPath, evaledFragments, bundleCallback)
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

    var bundleDelegate = [[PressBundleDelgate alloc] initWithCallback:bundleCallback];
    var bundlePaths = [];

    (context.eval("("+(function(mainPath, bundleDelegate, bundlePaths) {
        with (require("objective-j").window) {
            objj_import(mainPath, true, function() {
                bundlePaths = bundlePaths || [];

                // load default theme bundle
                // var themePath = [[CPBundle bundleForClass:[CPApplication class]] pathForResource:[CPApplication defaultThemeName]];
                // var themeBundle = [[CPBundle alloc] initWithPath:themePath + "/Info.plist"];
                // [themeBundle loadWithDelegate:bundleDelegate];

                // load additional bundles
                bundlePaths.forEach(function(bundlePath) {
                    var bundle = [[CPBundle alloc] initWithPath:bundlePath];
                    [bundle loadWithDelegate:bundleDelegate];
                });
            });
        }
    })+")"))(mainPath, bundleDelegate, bundlePaths);

    // run the "event loop"
    context.scope.require('browser/timeout').serviceTimeouts();

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
function setupObjectiveJ(context, debug)
{
    // set these properties required for Narwhal bootstrapping
    context.global.NARWHAL_HOME = system.prefix;
    context.global.NARWHAL_ENGINE_HOME = FILE.join(system.prefix, "engines", "rhino");

    // load the bootstrap.js for narwhal-rhino
    var bootstrapPath = FILE.join(context.global.NARWHAL_ENGINE_HOME, "bootstrap.js");
    context.evalFile(bootstrapPath);

    // get the Objective-J module from this scope, return the window object.
    var OBJJ = context.global.require("objective-j");

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
