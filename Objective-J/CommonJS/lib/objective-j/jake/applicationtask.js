
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

    this._shouldGenerateCacheManifest = false;
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
    this.defineCacheManifestTask();
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

ApplicationTask.prototype.setShouldGenerateCacheManifest = function(shouldGenerateCacheManifest)
{
    this._shouldGenerateCacheManifest = shouldGenerateCacheManifest;
}

ApplicationTask.prototype.shouldGenerateCacheManifest = function()
{
    return this._shouldGenerateCacheManifest;
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
            OS.system(["capp", "gen", "-f", "--force", buildPath]);
        else if (thisTask._frameworksPath)
        {
            if (FILE.exists(newFrameworks))
                FILE.rmtree(newFrameworks);

            // If there is a Frameworks/Source directory, move it temporarily
            // so it doesn't get copied.
            var sourcePath = FILE.join(thisTask._frameworksPath, "Source"),
                hasSource = FILE.exists(sourcePath),
                tempPath = FILE.join(FILE.cwd(), ".__capp_Frameworks_Source__");

            if (hasSource)
                FILE.move(sourcePath, tempPath);

            FILE.copyTree(thisTask._frameworksPath, newFrameworks);

            if (hasSource)
                FILE.move(tempPath, sourcePath);
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

ApplicationTask.prototype.defineCacheManifestTask = function()
{
    if (!this.shouldGenerateCacheManifest())
        return;

    var productPath = FILE.join(this.buildProductPath(), "");
    var indexFilePath = this.buildIndexFilePath();

    // TODO: can we conditionally generate based on outdated files?
    var manifestPath = FILE.join(productPath, "app.manifest");
    Jake.task(manifestPath, function() {
        require("../cache-manifest").generateManifest(productPath, { index : indexFilePath });
    });

    this.enhance([manifestPath]);
}

exports.ApplicationTask = ApplicationTask;

exports.app = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return ApplicationTask.defineTask(aName, aFunction);
}
