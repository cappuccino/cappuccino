debug = false;
args = arguments;

var helpersBase = arguments[0];
var STEAM_BUILD = arguments[1];
arguments.splice(0, 2);

if (typeof window == "undefined")
{
    print("Loading Objective-J bridge.");
    load(helpersBase+'/bridge.js');
}

if (typeof objj_import == "undefined")
{
    print("Loading Objective-J.");
    load(STEAM_BUILD+'/Objective-J.build/Release/Rhino/Objective-J.js');
}

OBJJ_INCLUDE_PATHS = [STEAM_BUILD+'/Release'];

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
