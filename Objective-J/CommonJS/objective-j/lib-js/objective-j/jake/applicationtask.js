
var Jake = require("jake"),
    BundleTask = require("objective-j/jake/bundletask").BundleTask;

function ApplicationTask(aName)
{
    BundleTask.apply(this, arguments);

    if (require("file").exists("index.html"))
        this._indexFilePath = "index.html";
    else
        this._indexFilePath = null;
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

ApplicationTask.prototype.defineFrameworksTask = function()
{
    // FIXME: platform requires...
    if (this.platforms().indexOf(BundleTask.Platform.Browser) === -1)
        return;

    var frameworks = FILE.join(this.buildProductPath(), "Frameworks"),
        thisTask = this;

    Jake.fileCreate(frameworks, function()
    {
        OS.system("capp gen -f " + thisTask.buildProductPath());
    });

    this.enhance([frameworks]);
}

ApplicationTask.prototype.defineIndexFileTask = function()
{
    if (!this._indexFilePath)
        return;

    var indexFilePath = this.indexFilePath(),
        buildIndexFilePath = FILE.join(this.buildProductPath(), FILE.basename(this.indexFilePath()));

    Jake.filedir (buildIndexFilePath, [indexFilePath], function()
    {
        cp(indexFilePath, buildIndexFilePath);
    });

    this.enhance([buildIndexFilePath]);
}

exports.ApplicationTask = ApplicationTask;

exports.app = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return ApplicationTask.defineTask(aName, aFunction);
}
