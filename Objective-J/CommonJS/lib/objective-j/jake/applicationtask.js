
var FILE = require("file"),
    OS = require("os"),
    Jake = require("jake"),
    BundleTask = require("objective-j/jake/bundletask").BundleTask;

function ApplicationTask(aName)
{
    BundleTask.apply(this, arguments);

    if (FILE.exists("index.html"))
        this._indexFilePath = "index.html";
    else
        this._indexFilePath = null;
    
    if (FILE.exists("Frameworks"))
        this._frameworksPath = "Frameworks";
    else
        this._frameworksPath = null;
}

ApplicationTask.__proto__ = BundleTask;
ApplicationTask.prototype.__proto__ = BundleTask.prototype;

ApplicationTask.prototype.packageType = function()
{
    return "APPL";
}

ApplicationTask.prototype.defineTasks = function()
{
    BundleTask.prototype.defineTasks.apply(this, arguments);

    this.defineFrameworksTask();
    this.defineIndexFileTask();
}

ApplicationTask.prototype.setIndexFilePath = function(aFilePath)
{
    this._indexFilePath = aFilePath;
}

ApplicationTask.prototype.indexFilePath = function()
{
    return this._indexFilePath;
}

ApplicationTask.prototype.setFrameworksPath = function(aFrameworksPath)
{
    // The default will use local app frameworks
    // Pass in ENV["CAPP_BUILD"] to use your built frameworks
    // Pass in "capp" to use installed frameworks
    
    this._frameworksPath = aFrameworksPath;
}

ApplicationTask.prototype.frameworksPath = function()
{
    return this._frameworksPath;
}

ApplicationTask.prototype.defineFrameworksTask = function()
{
    // FIXME: platform requires...
    if (!this._frameworksPath && this.environments().indexOf(require("objective-j/jake/environment").Browser) === -1)
        return;
    
    var buildPath = this.buildProductPath(),
        newFrameworks = FILE.join(buildPath, "Frameworks"),
        thisTask = this;
    
    Jake.fileCreate(newFrameworks, function()
    {
        if (thisTask._frameworksPath === "capp")
            OS.system("capp gen -f --force " + buildPath);
        else if (thisTask._frameworksPath)
        {
            if (FILE.exists(newFrameworks))
                FILE.rmtree(newFrameworks);
            
            FILE.copyTree(thisTask._frameworksPath, newFrameworks);
        }
    });
    
    this.enhance([newFrameworks]);
}

ApplicationTask.prototype.buildIndexFilePath = function()
{
    return FILE.join(this.buildProductPath(), FILE.basename(this.indexFilePath()));
}

ApplicationTask.prototype.defineIndexFileTask = function()
{
    if (!this._indexFilePath)
        return;

    var indexFilePath = this.indexFilePath(),
        buildIndexFilePath = this.buildIndexFilePath();

    Jake.filedir (buildIndexFilePath, [indexFilePath], function()
    {
        FILE.copy(indexFilePath, buildIndexFilePath);
    });

    this.enhance([buildIndexFilePath]);
}

exports.ApplicationTask = ApplicationTask;

exports.app = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return ApplicationTask.defineTask(aName, aFunction);
}
