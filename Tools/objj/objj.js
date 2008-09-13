debug = false;
args = arguments;

var OBJJ_LIB = arguments[0];

arguments.splice(0, 1);

if (typeof window == "undefined")
{
    print("Loading Objective-J bridge.");
    load(OBJJ_LIB+'/bridge.js');
}

if (typeof objj_import == "undefined")
{
    print("Loading Objective-J.");
    load(OBJJ_LIB+'/Frameworks/Objective-J/Objective-J.js');
}

var OBJJ_INCLUDE_PATHS_STRING = getEnv("OBJJ_INCLUDE_PATHS");
if (OBJJ_INCLUDE_PATHS_STRING)
{
    OBJJ_INCLUDE_PATHS = OBJJ_INCLUDE_PATHS_STRING.split(":");
}
else
{
    OBJJ_INCLUDE_PATHS = [OBJJ_LIB+'/Frameworks'];
}

if (arguments.length > 0)
{
	var main_file = arguments[0];
	arguments.splice(0, 1);
	
	if (debug)
		print("Loading: " + main_file);
		
	objj_import(main_file, NO);
	
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
