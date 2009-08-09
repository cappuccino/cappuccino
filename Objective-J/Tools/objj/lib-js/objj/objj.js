var File = require("file");
var window = require("browser/window");

var OBJJ_HOME = File.resolve(module.path, "..", ".."),
    FRAMEWORKS = File.resolve(OBJJ_HOME, "lib/", "Frameworks/"),
    OBJECTIVEJ = File.resolve(FRAMEWORKS, "Objective-J/", "rhino.platform/", "Objective-J.js");

window.OBJJ_INCLUDE_PATHS = [FRAMEWORKS];
if (system.env["OBJJ_INCLUDE_PATHS"])
    window.OBJJ_INCLUDE_PATHS = system.env["OBJJ_INCLUDE_PATHS"].split(":").concat(window.OBJJ_INCLUDE_PATHS);
    
//if (system.args.length > 0)
//    window.OBJJ_MAIN_FILE = File.canonical(args.shift());

window.args = system.args;

// FIXME: ARGS
system.args.shift();

with (window)
{
    eval(File.read(OBJECTIVEJ, { charset:"UTF-8" }));

    if (system.args.length > 0)
    {
        while (system.args.length && system.args[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS = system.args.shift().substr(2).split(':').concat(OBJJ_INCLUDE_PATHS);
                    
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
                    fragments = objj_preprocess(input, new objj_bundle(), new objj_file(), OBJJ_PREPROCESSOR_DEBUG_SYMBOLS),
                    count = fragments.length,
                    ctx = (new objj_context);

                if (count == 1 && (fragments[0].type & FRAGMENT_CODE))
                {
                    var fragment = fragments[0];
                    var result = eval(fragment.info);
                    if (result != undefined)
                        print(result);
                }
                else if (count > 0)
                {
                    while (count--)
                    {
                        var fragment = fragments[count];

                        if (fragment.type & FRAGMENT_FILE)
                            objj_request_file(fragment.info, (fragment.type & FRAGMENT_LOCAL), NULL);

                        ctx.pushFragment(fragment);
                    }

                    ctx.schedule();
                }

                require("browser/timeout").serviceTimeouts();
            } catch (e) {
                print(e);
            }
        }
    }
    
    require("browser/timeout").serviceTimeouts();
}
