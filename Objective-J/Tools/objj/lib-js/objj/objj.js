var File = require("file");
var window = require("browser/window");

// variables to be exported from the module, for use in objjc, etc
var exported = [
    "objj_preprocess",
    "FRAGMENT_FILE", "FRAGMENT_LOCAL",
    "MARKER_CODE", "MARKER_IMPORT_STD", "MARKER_IMPORT_LOCAL",
    "OBJJ_PREPROCESSOR_DEBUG_SYMBOLS"
];

// setup OBJJ_HOME, OBJJ_INCLUDE_PATHS, etc
var OBJJ_HOME = exports.OBJJ_HOME = File.resolve(module.path, "..", ".."),
    frameworksPath = File.resolve(OBJJ_HOME, "lib/", "Frameworks/"),
    objectivejPath = File.resolve(frameworksPath, "Objective-J/", "rhino.platform/", "Objective-J.js");

window.OBJJ_INCLUDE_PATHS = [frameworksPath];
if (system.env["OBJJ_INCLUDE_PATHS"])
    window.OBJJ_INCLUDE_PATHS = system.env["OBJJ_INCLUDE_PATHS"].split(":").concat(window.OBJJ_INCLUDE_PATHS);

// bring the "window" object into scope.
// TODO: somehow make window object the top scope?
with (window)
{
    // read and eval Objective-J.js with the module's scope
    eval(File.read(objectivejPath, { charset:"UTF-8" }));
    
    // export desired variables. must eval variable name to obtain a reference
    for (var i = 0; i < exported.length; i++)
        exports[exported[i]] = eval(exported[i]);

/*
    objj_set_evaluator(function(code) {
        return function(OBJJ_CURRENT_BUNDLE) {
            with (window) {
                return eval("function(OBJJ_CURRENT_BUNDLE){"+code+"}");
            }
        }
    });
*/

// runs the objj repl or file provided in args
exports.run = function(args)
{
    args = args || [];
    window.args = args;
    
    // FIXME: ARGS
    args.shift();

    if (args.length > 0)
    {
        while (args.length && args[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS = args.shift().substr(2).split(':').concat(OBJJ_INCLUDE_PATHS);
                
        var mainFilePath = File.canonical(args.shift());
    
        objj_import(mainFilePath, YES, function() {
            if (typeof main === "function")
                main.apply(main, args);
        });
    }
    else
    {
        while (true)
        {
            try {
                system.stdout.write("objj> ").flush();

                var input = system.stdin.readLine(),
                    result = objj_eval(input);
                
                if (result !== undefined)
                    print(result);
                    
            } catch (e) {
                print(e);
            }
            
            require("browser/timeout").serviceTimeouts();
        }
    }

    require("browser/timeout").serviceTimeouts();
}

// synchronously evals Objective-J code
var objj_eval = exports.objj_eval = function(code)
{
    var result = eval(objj_preprocess_sync(code));
    
    //require("browser/timeout").serviceTimeouts();
    
    return result;
}

// prepocesses Objective-J code into JavaScript, which will perform imports synchronously when eval'd
var objj_preprocess_sync = function(code)
{
    var fragments = objj_preprocess(code, new objj_bundle(), new objj_file(), OBJJ_PREPROCESSOR_DEBUG_SYMBOLS)

    var preprocessed = [];

    fragments.forEach(function(fragment) {
        if (fragment.type & FRAGMENT_CODE)
            preprocessed.push(fragment.info);
        else if (fragment.type & FRAGMENT_LOCAL)
            preprocessed.push("objj_import_sync('"+fragment.info+"',YES);");
        else
            preprocessed.push("objj_import_sync('"+fragment.info+"',NO);");
    });
    
    return preprocessed.join("\n");
}

// synchronously perform an import
var objj_import_sync = function(pathOrPaths, isLocal)
{
    var context = new objj_context();
    context.pushFragment(fragment_create_file(pathOrPaths, new objj_bundle(), isLocal, NULL));
    context.evaluate();

    // HACK: need a real synchronous require
    // FIXME: this is bad. not really synchronous. shouldn't have to call serviceTimeouts.
    require("browser/timeout").serviceTimeouts();
}

// creates a narwhal factory function in the objj module scope
exports.make_narwhal_factory = function(code) {
    // TODO: integrate better with objj load system so relative paths work
    var OBJJ_CURRENT_BUNDLE = new objj_bundle();
    
    return eval(
        "(function(require,exports,module,system,print){" +
        objj_preprocess_sync(code) +
        "/**/\n})"
    );
}

} // end "with"

if (require.main == module.id)
    exports.run(system.args);
