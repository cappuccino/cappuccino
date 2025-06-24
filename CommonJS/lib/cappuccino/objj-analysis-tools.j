// A modification to objj-analysis-tools.j, modernized for Node.js.
// It uses the standard Node.js environment and built-in modules, removing
// all dependencies on the Narwhal/Rhino runtime.

const path = require('path');
const OBJJ = require("objective-j");
require("cappuccino/objj-flatten-additions");

ObjectiveJRuntimeAnalyzer = function(rootPath)
{
    this.rootPath = rootPath;
    this.rootURL = new CFURL(String(rootPath));

    this.scope = setupObjectiveJ();

    this.mainBundleURL = new global.CFURL("file:" + this.rootPath);

    this.FileExecutable = OBJJ.FileExecutable;

    // TODO: deprecate these
    OBJJ.Executable.prototype.path = function() {
        var url = this.URL();
        return url ? url.absoluteURL().path() : null;
    };
    OBJJ.FileDependency.prototype.path = function() {
        var url = this.URL();
        return url ? url.path() : null;
    };
    global.CFBundle.prototype.executablePath = function() {
        var url = this.executableURL();
        return url ? url.absoluteURL().path() : null;
    };
    
    // In the browser, we want just these three arguments passed to anonymous functions.
    // The normal CommonJS version passes many more.
    OBJJ.Executable.prototype.functionParameters = function() {
        return ["global", "objj_executeFile", "objj_importFile"];
    };

    global.CPLogPopup = function() {};

    if (!global.CFHTTPRequest._lookupCachedRequest)
        console.warn("Warning: CFHTTPRequest._lookupCachedRequest. Need to import objj-flatten-additions module.");

    var requestedURLs = this.requestedURLs = {};
    var _lookupCachedRequest = global.CFHTTPRequest._lookupCachedRequest;
    global.CFHTTPRequest._lookupCachedRequest = function(aURL) {
        var reqPath = new CFURL(aURL, this.rootURL).absoluteURL().path();
        requestedURLs[reqPath] = true;
        return _lookupCachedRequest.apply(null, arguments);
    };
};

ObjectiveJRuntimeAnalyzer.prototype.setIncludePaths = function(includePaths) {
    global.OBJJ_INCLUDE_PATHS = includePaths;
};

ObjectiveJRuntimeAnalyzer.prototype.setEnvironments = function(environments) {
    global.CFBundle.environments = function() { return environments; };
};

ObjectiveJRuntimeAnalyzer.prototype.makeAbsoluteURL = function(/*CFURL|String*/ aURL)
{
    if (aURL instanceof global.CFURL && aURL.scheme())
        return aURL;

    return new global.CFURL(aURL, this.mainBundleURL);
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

    function recordAndReset() {
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
        before = after;
    }

    var _fileExecuterForURL = OBJJ.Executable.fileExecuterForURL;
    OBJJ.Executable.fileExecuterForURL = function(/*CFURL*/ referenceURL)
    {
        referenceURL = self.makeAbsoluteURL(referenceURL);
        var referencePath = referenceURL.absoluteURL().path()
        var fileExecutor = _fileExecuterForURL.apply(this, arguments);
        return function(/*CFURL*/ aURL, /*BOOL*/ isQuoted, /*BOOL*/ shouldForce) {
            var aPath = typeof aURL === "string" ? aURL : aURL.absoluteURL().path();

            recordAndReset();

            evaluatingPaths.push(currentFile);

            if (isQuoted && !path.isAbsolute(aPath))
                currentFile = path.normalize(path.join(path.dirname(referencePath), aPath));
            else
                currentFile = aPath;

            process.stderr.write(">");
            fileExecutor.apply(this, arguments);
            process.stderr.write("<");

            recordAndReset();

            currentFile = evaluatingPaths.pop();
        };
    };
};

ObjectiveJRuntimeAnalyzer.prototype.load = function(filePath)
{
    OBJJ.objj_eval(
        "("+(function(p) {
            objj_importFile(p, true, function() {
                console.log("Done importing and evaluating: " + p);
            });
        })+")"
    )(filePath);
};

ObjectiveJRuntimeAnalyzer.prototype.finishLoading = function()
{
    // This was previously `require('browser/timeout').serviceTimeouts()`.
    // In a Node.js environment, the event loop runs automatically.
    // Any async operations started by objj_eval will complete without
    // needing a manual tick, so this function is now effectively a no-op.
};

ObjectiveJRuntimeAnalyzer.prototype.mapGlobalsToFiles = function()
{
    this.mergeLibraryImports();
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

ObjectiveJRuntimeAnalyzer.prototype.mergeLibraryImports = function()
{
    for (var relativePath in this.files) {
        if (!path.isAbsolute(relativePath)) {
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

ObjectiveJRuntimeAnalyzer.prototype.executableForImport = function(filePath, isLocal)
{
    if (isLocal === undefined) isLocal = true;
    var fileExecutable = nil,
        URL = new global.CFURL(filePath);

    OBJJ.Executable.fileExecutableSearcherForURL(URL)(URL, isLocal, function(/*FileExecutable*/ aFileExecutable)
    {
        fileExecutable = aFileExecutable;
    });

    return fileExecutable;
};

ObjectiveJRuntimeAnalyzer.prototype.traverseDependencies = function(executable, context)
{
    context = context || {};
    context.processedFiles  = context.processedFiles  || {};
    context.importedFiles   = context.importedFiles   || {};
    context.referencedFiles = context.referencedFiles || {};
    context.ignoredImports  = context.ignoredImports  || {};

    var executablePath = executable.path();

    if (context.processedFiles[executablePath])
        return;

    context.processedFiles[executablePath] = true;
    var ignoreImports = false;
    
    // (Rest of the logic is compatible and remains the same)
    var referencedFiles = {},
        importedFiles = {};

    var code = executable.code();
    var referencedTokens = uniqueTokens(code);

    markFilesReferencedByTokens(referencedTokens, this.mapGlobalsToFiles(), referencedFiles);
    delete referencedFiles[executablePath];

    executable.fileDependencies().forEach(function(fileDependency) {
        var dependencyExecutable = null;
        if (fileDependency.isLocal())
            dependencyExecutable = this.executableForImport(path.normalize(path.join(path.dirname(executablePath), fileDependency.path())), true);
        else
            dependencyExecutable = this.executableForImport(fileDependency.path(), false);

        if (dependencyExecutable)
        {
            var importedFile = dependencyExecutable.path();
            if (importedFile !== executablePath)
                importedFiles[importedFile] = true;
        }
        else
            CPLog.error("Couldn't find file for import " + fileDependency.path() + " ("+fileDependency.isLocal()+")");
    }, this);

    this.checkImported(context, executablePath, importedFiles);
    context.importedFiles[executablePath] = importedFiles;
    this.checkReferenced(context, executablePath, referencedFiles);
    context.referencedFiles[executablePath] = referencedFiles;

    return context;
};

ObjectiveJRuntimeAnalyzer.prototype.checkImported = function(context, filePath, importedFiles) {
    for (var importedFile in importedFiles) {
        if (importedFile !== filePath) {
            if (context.importCallback) context.importCallback(filePath, importedFile);
            var executable = this.executableForImport(importedFile, true);
            if (executable) this.traverseDependencies(executable, context);
        }
    }
};

ObjectiveJRuntimeAnalyzer.prototype.checkReferenced = function(context, filePath, referencedFiles) {
    for (var referencedFile in referencedFiles) {
        if (referencedFile !== filePath) {
            if (context.referenceCallback) context.referenceCallback(filePath, referencedFile, referencedFiles[referencedFile]);
            var executable = this.executableForImport(referencedFile, true);
            if (executable) this.traverseDependencies(executable, context);
        }
    }
};

// (Helper functions below are mostly compatible, with minor tweaks)
function uniqueTokens(code) {
    var lexer = new OBJJ.Lexer(code, null);
    var token, tokens = {};
    while (token = lexer.skip_whitespace()) {
        tokens[token] = true;
    }
    return Object.keys(tokens);
}

function markFilesReferencedByTokens(tokens, globalsToFiles, referencedFiles) {
    tokens.forEach(function(token) {
        if (globalsToFiles.hasOwnProperty(token)) {
            var files = globalsToFiles[token];
            for (var i = 0; i < files.length; i++) {
                referencedFiles[files[i]] = referencedFiles[files[i]] || {};
                referencedFiles[files[i]][token] = true;
            }
        }
    });
}

function setupObjectiveJ() {
    addMockBrowserEnvironment(OBJJ.window);
    for (var property in OBJJ.window) {
        if (global[property] === undefined)
            global[property] = OBJJ.window[property];
    }
    return OBJJ.window;
}

function addMockBrowserEnvironment(scope) {
    if (!scope.window) scope.window = scope;
    if (!scope.location) scope.location = { href: "" };
    if (!scope.Element) scope.Element = function() { this.style = {} };
    if (!scope.document) scope.document = { createElement : function() { return new scope.Element(); } };
}

function cloneProperties(object, onlyList) {
    var results = {}
    for (var member in object)
        results[member] = onlyList ? true : object[member];
    return results;
}

function diff(o) {
    for (var i in o.after) if (o.added && !o.ignore[i] && typeof o.before[i] == "undefined") o.added[i] = true;
    for (var i in o.after) if (o.changed && !o.ignore[i] && typeof o.before[i] != "undefined" && typeof o.after[i] != "undefined" && o.before[i] !== o.after[i]) o.changed[i] = true;
    for (var i in o.before) if (o.deleted && !o.ignore[i] && typeof o.after[i] == "undefined") o.deleted[i] = true;
}

// Export the class for use in other Node.js modules
module.exports = { ObjectiveJRuntimeAnalyzer };
