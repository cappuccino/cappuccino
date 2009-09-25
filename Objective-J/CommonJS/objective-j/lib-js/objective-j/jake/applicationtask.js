
BundleTask = require("objective-j/jake/bundletask").BundleTask;

function ApplicationTask(aName)
{
    BundleTask.apply(this, arguments);
}

ApplicationTask.__proto__ = BundleTask;
ApplicationTask.prototype.__proto__ = BundleTask.prototype;

ApplicationTask.prototype.packageTask = function()
{
    return "APPL";
}

exports.ApplicationTask = ApplicationTask;

exports.app = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return ApplicationTask.defineTask(aName, aFunction);
}