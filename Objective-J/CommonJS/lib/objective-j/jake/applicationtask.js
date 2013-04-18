
var FILE = require("file"),
    OS = require("os"),
    TERM = require("narwhal/term"),
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

    var FileList = Jake.FileList,
        ENV = require("system").env

    // this list appears in jake//lib/jake/applications.js but I can't work out how to import it properly
    // also, there seems to be some case confusion....
    var jakefiles = ["jakefile", /*"Jakefile",*/ "jakefile.js", /*"Jakefile.js",*/ "jakefile.j", /*"Jakefile.j"*/];
    var extensions = new FileList(this._frameworksPath+"/*/");
    var env = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug"
    extensions.forEach(function( aFilename)
    {
        var found = false;
        for (var i=0; i < jakefiles.length; i++) {
            if (FILE.exists(FILE.join(aFilename, jakefiles[i]))) {
                found = true;
            }
        }
        if (found) {
            TERM.stream.print('Calling subjake process for '+aFilename+' and type '+env);
            Jake.subjake([aFilename], "build", ENV);

            // Now copy to the frameworks folder
            TERM.stream.print('Copying framework to main build folder');
            var dirname = new FileList(aFilename+"/Build/Release/*");
            if (dirname.length > 1) {
                TERM.stream.print('Found more than one name in the build directory');
                TERM.stream.print('Exiting');
                return;
            } else {
                Jake.fileCreate(newFrameworks, function() {
                    if (!FILE.exists(newFrameworks)) {
                        TERM.stream.print(newFrameworks+' does not exist; creating.');
                        FILE.mkdir(newFrameworks);
                    }
                    var files = new FileList(aFilename+'/Build/Release/*');
                    files.forEach(function(morefile) {
                        var newname = FILE.split(morefile)[1]; // ::FIXME::
                        TERM.stream.print('Copying '+morefile+' to '+newFrameworks+'/'+newname);
                        FILE.copyTree(morefile, FILE.join(newFrameworks,newname));
                    });
                });
            }
        } else {
            var fwname = FILE.split(aFilename).pop();
            Jake.fileCreate(newFrameworks, function() {
                var newpath = FILE.join(newFrameworks, fwname, "");
                var oldpath = FILE.join(aFilename, "");
                TERM.stream.print('Attempting to copy '+oldpath+' to '+newpath);
                if (!FILE.exists(newFrameworks)) {
                    TERM.stream.print(newFrameworks+' does not exist; creating.');
                    FILE.mkdir(newFrameworks);
                }
                if (!FILE.exists(newpath)) {
                    TERM.stream.print(newpath+' does not exist; creating.');
                    FILE.mkdir(newpath);
                }
                var files = new FileList(oldpath+'*');
                files.forEach(function(morefile) {
                    var morename = FILE.split(morefile).pop();
                    TERM.stream.print('Copying '+morefile+' to '+newpath+morename);
                    FILE.copyTree(morefile, FILE.join(newpath,morename));
                });
            });
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
