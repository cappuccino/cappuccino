

var FILE = require("file");

function exposeExports(path)
{
    var object = require(path);

    for (var name in object)
        if (object.hasOwnProperty(name))
            exports[name] = object[name];
}

exposeExports("objective-j/jake");

// This check is only necessary because during the build process blendtask gets created much later.
if (FILE.exists(FILE.join(FILE.dirname(module.path), "jake", "blendtask.j")))
{
    var BLEND_TASK = require("cappuccino/jake/blendtask");

    exports.BlendTask = BLEND_TASK.BlendTask;
    exports.blend = BLEND_TASK.blend;
}
