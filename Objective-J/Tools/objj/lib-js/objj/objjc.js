var File = require("file");
var window = require("browser/window");

require("./regexp-rhino-patch");

var exported = ["OBJJ_HOME", "objj_preprocess",
    "FRAGMENT_FILE", "FRAGMENT_LOCAL",
    "MARKER_CODE", "MARKER_IMPORT_STD", "MARKER_IMPORT_LOCAL",
    "OBJJ_PREPROCESSOR_DEBUG_SYMBOLS"];

var OBJJ_HOME = File.resolve(module.path, "..", ".."),
    FRAMEWORKS = File.resolve(OBJJ_HOME, "lib/", "Frameworks/"),
    OBJECTIVEJ = File.resolve(FRAMEWORKS, "Objective-J/", "rhino.platform/", "Objective-J.js");

with (window)
{
    eval(File.read(OBJECTIVEJ, { charset:"UTF-8" }).toString());

    for (var i = 0; i < exported.length; i++)
        exports[exported[i]] = eval(exported[i]);
}
