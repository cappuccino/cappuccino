
BundleTask = require("objective-j/bundletask").BundleTask;

function FrameworkTask()
{
    BundleTask.apply(this, arguments);
}

FrameworkTask.__proto__ = BundleTask;
FrameworkTask.prototype.__proto__ = BundleTask;

FrameworkTask.prototype.packageTask = function()
{
    return "FMWK";
}

exports.FrameworkTask = FrameworkTask;

exports.framework = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return Framework.defineTask(aName, aFunction);
}