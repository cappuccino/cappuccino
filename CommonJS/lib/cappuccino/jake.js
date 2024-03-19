var path = require("path");
var fs = require("fs");

/* function exposeExports(path)
{
    var object = require(path);

    for (var name in object)
        if (object.hasOwnProperty(name))
            exports[name] = object[name];
}

exposeExports("@objj/jake"); */

var object = JAKE;

for (var name in object) {
    if (object.hasOwnProperty(name)) {
        exports[name] = object[name];
    }
}

exports.initilize = function(callback) {
    // This check is only necessary because during the build process blendtask gets created much later.
    var blendTaskPath = path.join(process.cwd(), "..", "CommonJS", "blendtask.j");

    // var blendTaskPath = path.join(path.dirname(module.path), "jake", "blendtask.j");
    // Should be "{something}/AppKit/Themes/CommonJS/blendtask.j"
    
    if (fs.existsSync(blendTaskPath))
    {
        var anExports = {};
        function localCallback() {
            callback(anExports);
        }
        process.env["CONFIG"] = "Debug";
        ObjectiveJ.OBJJ_INCLUDE_PATHS.push(path.join(path.join($BUILD_DIR, "Debug"), "CommonJS", "cappuccino", "Frameworks"));
        ObjectiveJ.make_narwhal_factory(blendTaskPath, null, null, localCallback)(require, anExports, module, typeof system !== "undefined" && system, console.log);
    }
}