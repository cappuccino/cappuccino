var File = require("file");
var window = require("browser/window");

var OBJJ_HOME = system.prefix + "/..";

window.OBJJ_INCLUDE_PATHS = [OBJJ_HOME+"/lib/Frameworks/"];
if (system.env["OBJJ_INCLUDE_PATHS"])
    window.OBJJ_INCLUDE_PATHS = system.env["OBJJ_INCLUDE_PATHS"].split(":").concat(window.OBJJ_INCLUDE_PATHS);
    
//if (system.args.length > 0)
//    window.OBJJ_MAIN_FILE = String((new Packages.java.io.File(args.shift())).getAbsolutePath());

window.args = system.args;

with (window)
{
    eval(File.read(OBJJ_HOME+"/lib/Frameworks/Objective-J/rhino.platform/Objective-J.js").toString());

    if (system.args.length > 0)
    {
        while (system.args.length && system.args[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS = system.args.shift().substr(2).split(':').concat(OBJJ_INCLUDE_PATHS);
                    
        var mainFilePath = String((new Packages.java.io.File(args.shift())).getAbsolutePath());
        
        objj_import(mainFilePath, YES, function() {
            if (typeof main === "function")
                main.apply(main, args);
        });
    }
    else
    {
        var br = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(Packages.java.lang.System["in"], "UTF-8"));

        while (true)
        {
            try {
                Packages.java.lang.System.out.print("objj> ");

                var input = String(br.readLine()),
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
