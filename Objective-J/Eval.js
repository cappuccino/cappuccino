GLOBAL(objj_eval) = function(/*String*/ aString)
{
#if COMMONJS
    var url = FILE.join(FILE.cwd(), "/");
    Executable.setCommonJSParameters("require", "exports", "module", "system", "print", "window");
    Executable.setCommonJSArguments(require, exports, module, system, print, window);
#else
    var url = exports.pageURL;
#endif

    // Temporarily switch the loader to sychronous mode since objj_eval must be synchronous
    // therefore you shouldn't use @imports in objj_eval the browser
    var asyncLoaderSaved = exports.asyncLoader;
    exports.asyncLoader = NO;

    var executable = exports.preprocess(aString, url, 0);

    if (!executable.hasLoadedFileDependencies())
        executable.loadFileDependencies();

    // here we setup a scope object containing the free variables that would normally be arguments to the module function
    global._objj_eval_scope = {};

    global._objj_eval_scope.objj_executeFile = Executable.fileExecuterForURL(url);
    global._objj_eval_scope.objj_importFile = Executable.fileImporterForURL(url);
#if COMMONJS
    global._objj_eval_scope.require = require;
    global._objj_eval_scope.exports = exports;
    global._objj_eval_scope.module  = module;
    global._objj_eval_scope.system  = system;
    global._objj_eval_scope.print   = print;
    global._objj_eval_scope.window  = window;
#endif

    // A bit of a hack. Executable compiles the code itself into a function, but we want
    // the raw code to eval here so we can get the result.
    // No known way to get the result of a statement except via eval.
    var code = "with(_objj_eval_scope){" + executable._code + "\n//*/\n}";

    var result;
#if COMMONJS
    if (typeof system !== "undefined" && system.engine === "rhino")
        result = Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(global, code, "objj_eval", 0, NULL);
    else
#endif
        result = eval(code);

    // restore async loader setting
    exports.asyncLoader = asyncLoaderSaved;

    return result;
}

// deprecated, use global
exports.objj_eval = objj_eval;
