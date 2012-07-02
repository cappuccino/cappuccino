var FILE = require("file");
var OBJJ = require("objective-j");
var Context = require("interpreter").Context;

ObjectiveJRuntimeAnalyzer = function(rootPath)
{
    this.rootPath = rootPath;
    this.rootURL = new CFURL(String(rootPath));

    this.context = new Context();

    this.scope = setupObjectiveJ(this.context);

    this.require = this.context.global.require;

    this.mainBundleURL = new this.context.global.CFURL("file:" + this.rootPath);

    var _OBJJ = this.require("objective-j");

    // TODO: deprecate these
    _OBJJ.Executable.prototype.path = function() {
        var url = this.URL();
        return url ? url.absoluteURL().path() : null;
    };
    _OBJJ.FileDependency.prototype.path = function() {
        var url = this.URL();
        return url ? url.path() : null;
    };
    this.context.global.CFBundle.prototype.executablePath = function() {
        var url = this.executableURL();
        return url ? url.absoluteURL().path() : null;
    };

    this.require("cappuccino/objj-flatten-additions");

    if (!this.context.global.CFHTTPRequest._lookupCachedRequest)
        print("Warning: CFHTTPRequest._lookupCachedRequest. Need to import objj-flatten-additions module.");

    var requestedURLs = this.requestedURLs = {};
    var _lookupCachedRequest = this.context.global.CFHTTPRequest._lookupCachedRequest;
    this.context.global.CFHTTPRequest._lookupCachedRequest = function(aURL) {
        var path = new CFURL(aURL, this.rootURL).absoluteURL().path();
        requestedURLs[path] = true;
        return _lookupCachedRequest.apply(null, arguments);
    };
};

ObjectiveJRuntimeAnalyzer.prototype.setIncludePaths = function(includePaths) {
    this.context.global.OBJJ_INCLUDE_PATHS = includePaths;
};

ObjectiveJRuntimeAnalyzer.prototype.setEnvironments = function(environments) {
    this.context.global.CFBundle.environments = function() { return environments; };
};

ObjectiveJRuntimeAnalyzer.prototype.makeAbsoluteURL = function(/*CFURL|String*/ aURL)
{
    if (aURL instanceof this.context.global.CFURL && aURL.scheme())
        return aURL;

    return new this.context.global.CFURL(aURL, this.mainBundleURL);
};

ObjectiveJRuntimeAnalyzer.prototype.initializeGlobalRecorder = function()
{
    this.initializeGlobalRecorder = function(){}; // run once

    this.ignore = cloneProperties(this.scope, true);

    this.files = {};
    var evaluatingPaths = [];

    var before = null;
    var currentFile = null;

    var self = this;

    // a function to record changes to the global, then reset the scope
    function recordAndReset() {
        // system.stderr.write(".").flush();

        var after = cloneProperties(self.scope);

        if (before && currentFile) {
            self.files[currentFile] = self.files[currentFile] || {};
            self.files[currentFile].globals = self.files[currentFile].globals || {};

            diff({
                before : before,
                after : after,
                ignore : self.ignore,
                added : self.files[currentFile].globals,
                changed : self.files[currentFile].globals
            });
        }
        else if (!currentFile) {
            // I don't know why this happens. It shouldn't.
            // CPLog.debug("currentFile is null.");
        }

        before = after;
    }

    var _OBJJ = this.require("objective-j");
    var _fileExecuterForURL = _OBJJ.Executable.fileExecuterForURL;
    _OBJJ.Executable.fileExecuterForURL = function(/*CFURL*/ referenceURL)
    {
        referenceURL = self.makeAbsoluteURL(referenceURL);
        var referencePath = referenceURL.absoluteURL().path()
        var fileExecutor = _fileExecuterForURL.apply(this, arguments);
        return function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*BOOL*/ shouldForce) {
            var aPath = typeof aURL === "string" ? aURL : aURL.absoluteURL().path();

            recordAndReset();

            evaluatingPaths.push(currentFile);

            // NOTE: we distinguish local and library imports using absolute and relative paths.
            // we resolve the library paths later (in "mergeLibraryImports()") since doing it here seems
            // to change the resulting recorded globals.
            if (isQuoted && !FILE.isAbsolute(aPath))
                currentFile = FILE.normal(FILE.join(referencePath, aPath));
            else
                currentFile = aPath;

            system.stderr.write(">").flush();
            fileExecutor.apply(this, arguments);
            system.stderr.write("<").flush();

            recordAndReset();

            currentFile = evaluatingPaths.pop();
        };
    };
};

ObjectiveJRuntimeAnalyzer.prototype.load = function(path)
{
    this.require("objective-j").objj_eval(
        "("+(function(path) {
            objj_importFile(path, true, function() {
                print("Done importing and evaluating: " + path);
            });
        })+")"
    )(path);
};

ObjectiveJRuntimeAnalyzer.prototype.finishLoading = function(path)
{
    // run the "event loop"
    this.require('browser/timeout').serviceTimeouts();
};

ObjectiveJRuntimeAnalyzer.prototype.mapGlobalsToFiles = function()
{
    this.mergeLibraryImports();

    // takes a hash mapping from file names to hashes of global names defined in each file
    //    globals = { fileName { globalName : true }}
    // returns a hash mapping from global names to arrays of file names in which those globals are defined
    //    dependencies = { globalName : [fileName] }
    var globals = {};
    for (var fileName in this.files) {
        for (var globalName in this.files[fileName].globals)
            (globals[globalName] = globals[globalName] || []).push(fileName);
    }
    return globals;
};

ObjectiveJRuntimeAnalyzer.prototype.mapFilesToGlobals = function()
{
    this.mergeLibraryImports();

    var files = {};
    for (var fileName in this.files) {
        files[fileName] = {};
        for (var globalName in this.files[fileName].globals)
            files[fileName][globalName] = true;
    }
    return files;
};

// this method resolves library imports and merges their recorded globals with the canonical
// file object for each file
ObjectiveJRuntimeAnalyzer.prototype.mergeLibraryImports = function()
{
    for (var relativePath in this.files) {
        if (FILE.isRelative(relativePath)) {
            var absolutePath = this.executableForImport(relativePath, false).path();
            CPLog.debug("Merging " + relativePath + " => " + absolutePath);

            this.files[absolutePath] = this.files[absolutePath] || {};
            this.files[absolutePath].globals = this.files[absolutePath].globals || {};

            for (var global in this.files[relativePath].globals) {
                this.files[absolutePath].globals[global] = true;
            }
            delete this.files[relativePath];
        }
    }
};

// returns an executable for the import path, or null if none exists
ObjectiveJRuntimeAnalyzer.prototype.executableForImport = function(path, isLocal)
{
    if (isLocal === undefined) isLocal = true;
    var _OBJJ = this.require("objective-j"),
        fileExecutable = nil,
        URL = new this.context.global.CFURL(path);

    _OBJJ.Executable.fileExecutableSearcherForURL(URL)(URL, isLocal, function(/*FileExecutable*/ aFileExecutable)
    {
        fileExecutable = aFileExecutable;
    });

    return fileExecutable;
};

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
ObjectiveJRuntimeAnalyzer.prototype.traverseDependencies = function(executable, context)
{
    context = context || {};

    context.processedFiles  = context.processedFiles  || {};
    context.importedFiles   = context.importedFiles   || {};
    context.referencedFiles = context.referencedFiles || {};
    context.ignoredImports  = context.ignoredImports   || {};

    var path = executable.path();

    if (context.processedFiles[path])
        return;

    context.processedFiles[path] = true;

    var ignoreImports = false;
    if (context.ignoreAllImports)
    {
        // CPLog.warn("Ignoring all import fragments. ("+this.rootPath.relative(path)+")");
        ignoreImports = true;
    }
    else if (context.ignoreFrameworkImports)
    {
        var matches = path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$")); // Matches "ZZZ/ZZZ.j" (e.x. AppKit/AppKit.j and Foundation/Foundation.j)
        if (matches && matches[1] === matches[2])
        {
            // CPLog.warn("Framework import file! Ignoring all import fragments. ("+this.rootPath.relative(path)+")");
            ignoreImports = true;
        }
    }

    var referencedFiles = {},
        importedFiles = {};

    if (context.progressCallback)
        context.progressCallback(this.rootPath.relative(path), path);

    // code
    var code = executable.code();
    var referencedTokens = uniqueTokens(code);

    markFilesReferencedByTokens(referencedTokens, this.mapGlobalsToFiles(), referencedFiles);
    delete referencedFiles[path];

    // imports
    if (ignoreImports)
    {
        if (context.ignoreImportsCallback)
            context.ignoreImportsCallback(this.rootPath.relative(path), path);
        context.ignoredImports[path] = true;
    }
    else
    {
        executable.fileDependencies().forEach(function(fileDependency) {
            var dependencyExecutable = null;
            if (fileDependency.isLocal())
                dependencyExecutable = this.executableForImport(FILE.normal(FILE.join(FILE.dirname(path), fileDependency.path())), true);
            else
                dependencyExecutable = this.executableForImport(fileDependency.path(), false);

            if (dependencyExecutable)
            {
                var importedFile = dependencyExecutable.path();
                // should never import self, but just in case?
                if (importedFile !== path)
                    importedFiles[importedFile] = true;
                else
                    CPLog.error("Ignoring self import (why are you importing yourself?!): " + this.rootPath.relative(importedFile));
            }
            else
                CPLog.error("Couldn't find file for import " + fileDependency.path() + " ("+fileDependency.isLocal()+")");
        }, this);
    }

    // check each imported file
    this.checkImported(context, path, importedFiles);

    context.importedFiles[path] = importedFiles;

    // check each referenced file
    this.checkReferenced(context, path, referencedFiles);

    context.referencedFiles[path] = referencedFiles;

    return context;
};

ObjectiveJRuntimeAnalyzer.prototype.checkImported = function(context, path, importedFiles) {
    for (var importedFile in importedFiles)
    {
        if (importedFile !== path)
        {
            if (context.importCallback)
                context.importCallback(path, importedFile);

            var executable = this.executableForImport(importedFile, true);
            if (executable)
                this.traverseDependencies(executable, context);
            else
                CPLog.error("Missing imported file: " + importedFile);
        }
    }
};

ObjectiveJRuntimeAnalyzer.prototype.checkReferenced = function(context, path, referencedFiles) {
    for (var referencedFile in referencedFiles)
    {
        if (referencedFile !== path)
        {
            if (context.referenceCallback)
                context.referenceCallback(path, referencedFile, referencedFiles[referencedFile]);

            var executable = this.executableForImport(referencedFile, true);
            if (executable)
                this.traverseDependencies(executable, context);
            else
                CPLog.error("Missing referenced file: " + referencedFile);
        }
    }
};

ObjectiveJRuntimeAnalyzer.prototype.fileExecutables = function() {
    var _OBJJ = this.require("objective-j");
    return _OBJJ.FileExecutablesForPaths;
};

// returns a unique list of tokens for a piece of code.
// ideally this should return identifiers only
function uniqueTokens(code)
{
    // FIXME: this breaks for indentifiers containing "$" since it's considered a distinct token by the lexer
    var lexer = new OBJJ.Lexer(code, null);

    var token, tokens = {};
    while (token = lexer.skip_whitespace()) {
        tokens[token] = true;
    }

    return Object.keys(tokens);
}

/*
    params:
        tokens (in):                list of tokens to mark as required
        globalsToFiles (in):        map from tokens to files which define those tokens
        referencedFiles (out):      map of required files (to map of tokens defined in that file)
*/
function markFilesReferencedByTokens(tokens, globalsToFiles, referencedFiles)
{
    tokens.forEach(function(token) {
        if (globalsToFiles.hasOwnProperty(token))
        {
            var files = globalsToFiles[token];
            for (var i = 0; i < files.length; i++)
            {
                referencedFiles[files[i]] = referencedFiles[files[i]] || {};
                referencedFiles[files[i]][token] = true;
            }
        }
    });
}

// create a new scope loaded with Narwhal and Objective-J
function setupObjectiveJ(context)
{
    // set these properties required for Narwhal bootstrapping
    context.global.NARWHAL_HOME = system.prefix;
    context.global.NARWHAL_ENGINE_HOME = FILE.join(system.prefix, "engines", "rhino");

    // load the bootstrap.js for narwhal-rhino
    var bootstrapPath = FILE.join(context.global.NARWHAL_ENGINE_HOME, "bootstrap.js");
    context.evalFile(bootstrapPath);

    context.global.require("browser");

    // get the Objective-J module from this scope, return the window object.
    var OBJJ = context.global.require("objective-j");

    // TODO: move this to browserjs and/or remove browser dependency in Objective-J/AppKit
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
        };

    if (!scope.document)
        scope.document = {
            createElement : function() {
                return new scope.Element();
            }
        };
}

// does a shallow copy of an object. if onlyList is true, it sets each property to "true" instead of the actual value
function cloneProperties(object, onlyList)
{
    var results = {}
    for (var memeber in object)
        results[memeber] = onlyList ? true : object[memeber];
    return results;
}

function diff(o)
{
    for (var i in o.after)
        if (o.added && !o.ignore[i] && typeof o.before[i] == "undefined")
            o.added[i] = true;
    for (var i in o.after)
        if (o.changed && !o.ignore[i] && typeof o.before[i] != "undefined" && typeof o.after[i] != "undefined" && o.before[i] !== o.after[i])
            o.changed[i] = true;
    for (var i in o.before)
        if (o.deleted && !o.ignore[i] && typeof o.after[i] == "undefined")
            o.deleted[i] = true;
}
