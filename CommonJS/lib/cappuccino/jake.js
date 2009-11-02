// This check is only necessary because during the build process blendtask gets created much later.
if (FILE.exists(FILE.join(FILE.dirname(module.path), "jake", "blendtask.j")))
{
    var BLEND_TASK = require("cappuccino/jake/blendtask");

    exports.BlendTask = BLEND_TASK.BlendTask;
    exports.blend = BLEND_TASK.blend;
}
