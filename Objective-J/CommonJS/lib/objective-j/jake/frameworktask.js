
BundleTask = require("objective-j/jake/bundletask").BundleTask;

function FrameworkTask(aName)
{
    BundleTask.apply(this, arguments);
}

FrameworkTask.__proto__ = BundleTask;
FrameworkTask.prototype.__proto__ = BundleTask.prototype;

FrameworkTask.prototype.packageType = function()
{
    return "FMWK";
}

exports.FrameworkTask = FrameworkTask;

exports.framework = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return FrameworkTask.defineTask(aName, aFunction);
}