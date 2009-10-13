
var FILE = require("file");


var BUNDLE_TASK = require("objective-j/jake/bundletask");

exports.BundleTask = BUNDLE_TASK.BundleTask;
exports.bundle = BUNDLE_TASK.bundle;

var FRAMEWORK_TASK = require("objective-j/jake/frameworktask");

exports.FrameworkTask = FRAMEWORK_TASK.FrameworkTask;
exports.framework = FRAMEWORK_TASK.framework;

var APPLICATION_TASK = require("objective-j/jake/applicationtask");

exports.ApplicationTask = APPLICATION_TASK.ApplicationTask;
exports.app = APPLICATION_TASK.app;

// This check is only necessary because during the build process blendtask gets created much later.
if (FILE.exists(FILE.join(FILE.dirname(module.path), "jake", "blendtask.j")))
{
    var BLEND_TASK = require("objective-j/jake/blendtask");

    exports.BlendTask = BLEND_TASK.BlendTask;
    exports.blend = BLEND_TASK.blend;
}
