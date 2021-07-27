var path = require("path");
var fs = require("fs");

function exposeExports(path)
{
    var object = require(path);

    for (var name in object)
        if (object.hasOwnProperty(name))
            exports[name] = object[name];
}

exposeExports("jake");

exports.initilize = function(callback) {
    console.log("initilize");

    // This check is only necessary because during the build process blendtask gets created much later.
    var blendTaskPath = "/Users/alfred/Developer/cappuccino/AppKit/Themes/CommonJS/blendtask.j";
    //var blendTaskPath = path.join(path.dirname(module.path), "jake", "blendtask.j");
    console.log("blendTaskPath: " + blendTaskPath);
    if (fs.existsSync(blendTaskPath))
    {
        var anExports = {};
        function localCallback() {
            callback(anExports);
        }
        process.env["CONFIG"] = "Debug";
        require("objj-runtime").OBJJ_INCLUDE_PATHS.push(path.join(path.join($BUILD_DIR, "Debug"), "CommonJS", "cappuccino", "Frameworks"));

        require("objj-runtime").make_narwhal_factory(blendTaskPath, null, null, localCallback)(require, anExports, module, typeof system !== "undefined" && system, console.log);

        //exports.BlendTask = BLEND_TASK.BlendTask;
        //exports.blend = BLEND_TASK.blend;
    }
}