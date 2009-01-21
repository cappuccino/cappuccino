debug = false;
args = arguments;

// FIXME: remove these Rhino/Java dependencies
var OBJJ_LIB = Packages.java.lang.System.getenv("OBJJ_LIB"); // chicken/egg problem, getenv is defined in bridge.js

if (!this.window)
{
    print("Loading Objective-J bridge.");
    load(OBJJ_LIB+'/bridge.js');
}

if (!this.objj_import)
{
    print("Loading Objective-J.");
    load(OBJJ_LIB+'/Frameworks-Rhino/Objective-J/Objective-J.js');
}

var defaultFrameworks = OBJJ_LIB+'/Frameworks-Rhino';
OBJJ_INCLUDE_PATHS = [defaultFrameworks];

var OBJJ_INCLUDE_PATHS_STRING = getenv("OBJJ_INCLUDE_PATHS");

if (OBJJ_INCLUDE_PATHS_STRING)
{
    OBJJ_INCLUDE_PATHS = OBJJ_INCLUDE_PATHS_STRING.split(":");
    OBJJ_INCLUDE_PATHS.push(defaultFrameworks);
}

try
{
    if (args.length > 0)
    {
    	var mainFilePath = args.shift();
    	
        // convert from relative to absolute path
    	if (this.Packages)
    	    mainFilePath = (new Packages.java.io.File(mainFilePath)).getAbsolutePath();

    	if (debug)
    		print("Loading: " + mainFilePath);

    	objj_import(mainFilePath, YES);

    	serviceTimeouts();

    	if (debug)
    		print("Done!");
    }
    else if (typeof objj_console != "undefined")
    {
    	if (debug)
    		print("Starting Objective-J console.");

    	objj_console();
    }
    else
    {
    	print("Error: No file provided or console  available.")
    }
}
catch (e)
{
    print("OBJJ EXCEPTION: " + e);
    print("    Name:    " + e.name);
    print("    Message: " + e.message);
    print("    File:    " + e.fileName);
    print("    Line:    " + e.lineNumber);
    if (e.javaException)
    {
        print("    Java Exception: " + e.javaException);
        e.javaException.printStackTrace();
    }
    if (e.rhinoException)
    {
        print("    Rhino Exception: " + e.rhinoException);
        
        print(" *** Message:       " + e.rhinoException.getMessage());
        print(" *** Source name:   " + e.rhinoException.sourceName());
        print(" *** Line number:   " + e.rhinoException.lineNumber());
        print(" *** Column number: " + e.rhinoException.columnNumber());
        print(" *** Line Source:   " + e.rhinoException.lineSource());
        
        // print the JavaScript stack trace with line numbers:
        print(" *** Filtered stack trace:");
        var bos = new Packages.java.io.ByteArrayOutputStream();
        e.rhinoException.printStackTrace(new Packages.java.io.PrintStream(bos));
        var stack = String(bos.toString()).split("\n").slice(1);
        for (var i = 0; i < stack.length; i++) {
            var match;
            if (match = stack[i].match(/_c[0-9]+\((.+)\)/))
                print(match[1]);
        }

        print(" *** Script stack trace:\n" + e.rhinoException.getScriptStackTrace());
        
        print(" *** Raw stack trace:");
        e.rhinoException.printStackTrace();
    }
}
