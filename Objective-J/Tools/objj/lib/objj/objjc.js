var File = require("file");
var window = require("browser/window");

var exported = ["OBJJ_HOME", "objj_preprocess",
    "FRAGMENT_FILE", "FRAGMENT_LOCAL",
    "MARKER_CODE", "MARKER_IMPORT_STD", "MARKER_IMPORT_LOCAL",
    "OBJJ_PREPROCESSOR_DEBUG_SYMBOLS"];

var OBJJ_HOME = system.prefix + "/..";

with (window)
{
    eval(File.read(OBJJ_HOME+"/lib/Frameworks/Objective-J/rhino.platform/Objective-J.js").toString());

    for (var i = 0; i < exported.length; i++)
        exports[exported[i]] = eval(exported[i]);
}
