debug = false;
args = arguments;

// FIXME: remove Rhino/Java dependencies
var OBJJ_LIB = Packages.java.lang.System.getenv("OBJJ_LIB");

if (typeof window == "undefined")
{
    print("Loading Objective-J bridge.");
    load(OBJJ_LIB+'/bridge.js');
}

if (typeof objj_import == "undefined")
{
    print("Loading Objective-J.");
    load(OBJJ_LIB+'/Frameworks-Rhino/Objective-J/Objective-J.js');
}

var OBJJ_INCLUDE_PATHS_STRING = getEnv("OBJJ_INCLUDE_PATHS");
if (OBJJ_INCLUDE_PATHS_STRING)
{
    OBJJ_INCLUDE_PATHS = OBJJ_INCLUDE_PATHS_STRING.split(":");
}
else
{
    OBJJ_INCLUDE_PATHS = [OBJJ_LIB+'/Frameworks-Rhino'];
}

try {
    if (args.length > 0)
    {
    	var mainFilename = args.shift();
    	
    	mainFile = new Packages.java.io.File(mainFilename);
    	if (!mainFile.exists())
    	{
    	    print(mainFile.getAbsolutePath() + " not found.")
    	    Packages.java.System.exit(1);
    	}
    	
    	var mainFilePath = mainFile.getAbsolutePath();

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
} catch (e) {
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
        e.rhinoException.printStackTrace();
    }
}