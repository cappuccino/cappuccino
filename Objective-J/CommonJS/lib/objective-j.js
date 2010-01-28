var FILE = require("file");

var window = exports.window = require("browser/window");

if (system.engine === "rhino")
{
    window.__parent__ = null;
    window.__proto__ = global;
}

// setup OBJJ_HOME, OBJJ_INCLUDE_PATHS, etc
window.OBJJ_HOME = exports.OBJJ_HOME = FILE.resolve(module.path, "..");

var frameworksPath = FILE.resolve(window.OBJJ_HOME, "Frameworks/"),
    objectivejPath = FILE.resolve(frameworksPath, "Objective-J/", "CommonJS.environment/", "Objective-J.js");

var OBJJ_INCLUDE_PATHS = window.OBJJ_INCLUDE_PATHS = exports.OBJJ_INCLUDE_PATHS = [];

// Find all narwhal packages with Objective-J frameworks.
exports.objj_frameworks = [];
exports.objj_debug_frameworks = [];

var catalog = require("packages").catalog;
for (var name in catalog)
{
    if (!catalog.hasOwnProperty(name))
        continue;

    var info = catalog[name];
    if (!info)
        continue;

    var frameworks = info["objj-frameworks"];
    if (frameworks) {
        if (!Array.isArray(frameworks))
            frameworks = [String(frameworks)];

        exports.objj_frameworks.push.apply(exports.objj_frameworks, frameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }

    var debugFrameworks = info["objj-debug-frameworks"];
    if (debugFrameworks) {
        if (!Array.isArray(debugFrameworks))
            debugFrameworks = [String(debugFrameworks)];

        exports.objj_debug_frameworks.push.apply(exports.objj_debug_frameworks, debugFrameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }
}

// push to the front of the array lowest priority first.
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_frameworks);
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_debug_frameworks);

if (system.env["OBJJ_INCLUDE_PATHS"])
    OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, system.env["OBJJ_INCLUDE_PATHS"].split(":"));

// bring the "window" object into scope.
// TODO: somehow make window object the top scope?
with (window)
{
    var objectivejSource = FILE.read(objectivejPath, { charset:"UTF-8" });

    // read and eval Objective-J.js with the module's scope
    if (system.engine === "rhino")
        Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(window, objectivejSource, objectivejPath, 0, null);
    else
        eval(objectivejSource);

    // export desired variables. must eval variable name to obtain a reference.
    [
        "objj_preprocess",
        "FRAGMENT_FILE", "FRAGMENT_LOCAL",
        "MARKER_CODE", "MARKER_IMPORT_STD", "MARKER_IMPORT_LOCAL",
        "OBJJ_PREPROCESSOR_DEBUG_SYMBOLS",
        "objj_data",
        "CPPropertyListCreateData", "CPPropertyListCreateFromData",
        "kCFPropertyListXMLFormat_v1_0", "kCFPropertyList280NorthFormat_v1_0",
        "objj_dictionary"
    ].forEach(function(v) {
        exports[v] = eval(v);
    });
        
    // extra macros
    exports.SET_CONTEXT = function(aFragment, aContext) { aFragment.context = aContext; }
    exports.GET_CONTEXT = function(aFragment) { return aFragment.context; }

    exports.SET_TYPE = function(aFragment, aType) { aFragment.type = aType; }
    exports.GET_TYPE = function(aFragment) { return aFragment.type; }

    exports.GET_CODE = function(aFragment) { return aFragment.info; }
    exports.SET_CODE = function(aFragment, aCode) { aFragment.info = aCode; }

    exports.GET_PATH = function(aFragment) { return aFragment.info; }
    exports.SET_PATH = function(aFragment, aPath) { aFragment.info = aPath; }

    exports.GET_BUNDLE = function(aFragment) { return aFragment.bundle; }
    exports.SET_BUNDLE = function(aFragment, aBundle) { aFragment.bundle = aBundle; }

    exports.GET_FILE = function(aFragment) { return aFragment.file; }
    exports.SET_FILE = function(aFragment, aFile) { aFragment.file = aFile; }

    exports.IS_FILE = function(aFragment) { return (aFragment.type & FRAGMENT_FILE); }
    exports.IS_LOCAL = function(aFragment) { return (aFragment.type & FRAGMENT_LOCAL); }
    exports.IS_IMPORT = function(aFragment) { return (aFragment.type & FRAGMENT_IMPORT); }

// runs the objj repl or file provided in args
exports.run = function(args)
{
    if (args && args.length > 1)
    {
        // we expect args to be in the format:
        //  1) "objj" path
        //  2) optional "-I" args
        //  3) real or "virtual" main.j
        //  4) optional program arguments

        // copy the args since we're going to modify them
        var argv = args.slice(1);

        while (argv.length && argv[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS = argv.shift().substr(2).split(':').concat(OBJJ_INCLUDE_PATHS);

        var arg0 = argv.shift();
        var mainFilePath = FILE.canonical(arg0);

        objj_import(mainFilePath, YES, function() {
            if (typeof main === "function")
                main([arg0].concat(argv));
        });

        require("browser/timeout").serviceTimeouts();
    }
    else
    {
        while (true)
        {
            try {
                system.stdout.write("objj> ").flush();

                var result = objj_eval(require("readline").readline());

                if (result !== undefined)
                    print(result);
                    
            } catch (e) {
                print(e);
            }
            
            require("browser/timeout").serviceTimeouts();
        }
    }
}

// synchronously evals Objective-J code
var objj_eval = exports.objj_eval = function(code)
{
    if (system.engine === "rhino")
        var result = Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(window, objj_preprocess_sync(code), "objj_eval", 0, null);
    else
        var result = eval(objj_preprocess_sync(code));
    
    //require("browser/timeout").serviceTimeouts();
    
    return result;
}

// prepocesses Objective-J code into JavaScript, which will perform imports synchronously when eval'd
window.objj_preprocess_sync = function(code, path)
{
    var fragments = objj_preprocess(code, new objj_bundle(), new objj_file(), OBJJ_PREPROCESSOR_DEBUG_SYMBOLS)

    var preprocessed = [];

    fragments.forEach(function(fragment) {
        if (fragment.type & FRAGMENT_CODE)
            preprocessed.push(fragment.info);
        else if (fragment.type & FRAGMENT_LOCAL)
            preprocessed.push("objj_import_sync('"+(path ? FILE.join(FILE.dirname(path), fragment.info) : fragment.info)+"',YES);");
        else
            preprocessed.push("objj_import_sync('"+fragment.info+"',NO);");
    });
    
    return preprocessed.join("\n");
}

// FIXME: Why does this need to be global?
// synchronously perform an import
window.objj_import_sync = function(pathOrPaths, isLocal)
{
    var context = new objj_context();
    context.pushFragment(fragment_create_file(pathOrPaths, new objj_bundle(), isLocal, NULL));
    context.evaluate();

    // HACK: need a real synchronous require
    // FIXME: this is bad. not really synchronous. shouldn't have to call serviceTimeouts.
    require("browser/timeout").serviceTimeouts();
}

// creates a narwhal factory function in the objj module scope
exports.make_narwhal_factory = function(code, path) {
    var OBJJ_CURRENT_BUNDLE = new objj_bundle();
    
    var factoryText = "function(require,exports,module,system,print){" + objj_preprocess_sync(code, path) + "/**/\n}";

    if (system.engine === "rhino")
        return Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, factoryText, path, 0, null);

    // eval requires parenthesis, but parenthesis break compileFunction.
    else
        return eval("(" + factoryText + ")");
}

} // end "with"

if (require.main == module.id)
    exports.run(system.args);
