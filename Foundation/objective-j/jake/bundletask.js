/*
 * Objective-J.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

var /* FILE = require("file"),
    OS = require("os"),
    UTIL = require("narwhal/util"),
    TERM = require("narwhal/term"), 
    base64 = require("base64"),
    Jake = require("jake"),*/
    CLEAN = require("../../../common.jake").CLEAN,
    CLOBBER = require("../../../common.jake").CLOBBER,
    ObjectiveJ = require("objj-runtime"),
    environment = require("./environment");

/*     task = Jake.task;
var Task = Jake.Task,
    filedir = Jake.filedir; */

var jake = require("jake");
var fs = require("fs-extra");
var glob = require("glob");

var Task = jake.Task;
const { task } = require("../../../common.jake");
const { filedir } = require("../../../common.jake");

var path = require("path");
var child_process = require("child_process");

function isImage(aFilename)
{
    return [".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"].includes(path.extname(aFilename).toLowerCase());
}
function mimeType(aFilename)
{
    return {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".gif": "image/gif", ".tif": "image/tiff", ".tiff": "image/tiff"}[(path.extname(aFilename)).toLowerCase()];
}
function BundleTask(aName, anApplication)
{
    Task.apply(this, arguments);
    var ignoreCommonJS = system.env["CAPP_IGNORE_COMMONJS_ENV"];
    if (ignoreCommonJS && ignoreCommonJS.toLowerCase() == "no" || ignoreCommonJS == "1")
        this.setEnvironments([environment.Browser]);
    else
        this.setEnvironments([environment.Browser, environment.CommonJS]);
    this._author = null;
    this._email = null;
    this._summary = null;
    this._license = null;
    this._sources = null;
    this._resources = null;
    this._spritesResources = true;
    this._identifier = null;
    this._version = 0.1;
    this._compilerFlags = null;
    this._flattensSources = false;
    this._includesNibsAndXibs = false;
    this._preventsNib2Cib = false;
    this._productName = this.name();
    this._buildIntermediatesPath = null;
    this._buildPath = process.cwd();
    this._replacedFiles = {};
    this._nib2cibFlags = null;
    this._infoPlistPath = "Info.plist";
    this._principalClass = null;
}
BundleTask.__proto__ = Task;
BundleTask.prototype.__proto__ = Task.prototype;
BundleTask.defineTask = function(aName, aFunction)
{
    var bundleTask = Task.defineTask.apply(this, [aName]);
    if (aFunction)
        aFunction(bundleTask);
    bundleTask.defineTasks();
    return bundleTask;
};
BundleTask.prototype.setEnvironments = function(environments)
{
    if (arguments.length < 1)
        this._environments = [];
    else if (arguments.length > 1)
        this._environments = Array.prototype.slice.apply(environments);
    else if (typeof environments.slice === "function")
        this._environments = environments.slice();
    else
        this._environments = [environments];
};
BundleTask.prototype.environments = function()
{
    return this._environments;
};
BundleTask.prototype.setAuthor = function(anAuthor)
{
    this._author = anAuthor;
};
BundleTask.prototype.author = function()
{
    return this._author;
};
BundleTask.prototype.setEmail = function(anEmail)
{
    this._email = anEmail;
};
BundleTask.prototype.email = function()
{
    return this._email;
};
BundleTask.prototype.setSummary = function(aSummary)
{
    this._summary = aSummary;
};
BundleTask.prototype.summary = function()
{
    return this._summary;
};
BundleTask.prototype.setIdentifier = function(anIdentifier)
{
    this._identifier = anIdentifier;
};
BundleTask.prototype.identifier = function()
{
    return this._identifier;
};
BundleTask.prototype.setVersion = function(aVersion)
{
    this._version = aVersion;
};
BundleTask.prototype.version = function()
{
    return this._version;
};
BundleTask.prototype.setSources = function(sources, environments)
{
    if (!environments)
        this._sources = sources;
    else
    {
        if (!this._sources)
            this._sources = {};
        if (!Array.isArray(environments))
            environments = [environments];
        environments.forEach(        function(anEnvironment)
        {
            this._sources[anEnvironment] = sources;
        }, this);
    }};
BundleTask.prototype.sources = function()
{
    return this._sources;
};
BundleTask.prototype.setResources = function(resources)
{
    this._resources = resources;
};
BundleTask.prototype.resources = function(resources)
{
    this._resources = resources;
};
BundleTask.prototype.setSpritesResources = function(shouldSpriteResources)
{
    this._spritesResources = shouldSpriteResources;
};
BundleTask.prototype.spritesResources = function()
{
    return this._spritesResources;
};
BundleTask.prototype.setIncludesNibsAndXibs = function(shouldIncludeNibsAndXibs)
{
    this._includesNibsAndXibs = shouldIncludeNibsAndXibs;
};
BundleTask.prototype.includesNibsAndXibs = function()
{
    return this._includesNibsAndXibs;
};
BundleTask.prototype.setPreventsNib2Cib = function(shouldPreventNib2Cib)
{
    this._preventsNib2Cib = shouldPreventNib2Cib;
};
BundleTask.prototype.preventsNib2Cib = function()
{
    return this._preventsNib2Cib;
};
BundleTask.prototype.setProductName = function(aProductName)
{
    this._productName = aProductName;
};
BundleTask.prototype.productName = function()
{
    return this._productName;
};
BundleTask.prototype.setInfoPlistPath = function(anInfoPlistPath)
{
    this._infoPlistPath = anInfoPlistPath;
};
BundleTask.prototype.infoPlistPath = function()
{
    return this._infoPlistPath;
};
BundleTask.prototype.setPrincipalClass = function(aPrincipalClass)
{
    this._principalClass = aPrincipalClass;
};
BundleTask.prototype.principalClass = function()
{
    return this._principalClass;
};
BundleTask.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
};
BundleTask.prototype.compilerFlags = function()
{
    return this._compilerFlags;
};
BundleTask.prototype.setNib2cibFlags = function(flags)
{
    this._nib2cibFlags = flags;
};
BundleTask.prototype.setNib2CibFlags = BundleTask.prototype.setNib2cibFlags;
BundleTask.prototype.nib2cibFlags = function()
{
    return this._nib2cibFlags;
};
BundleTask.prototype.flattensSources = function()
{
    return this._flattensSources;
};
BundleTask.prototype.setFlattensSources = function(shouldFlattenSources)
{
    this._flattensSources = shouldFlattenSources;
};
BundleTask.prototype.setLicense = function(aLicense)
{
    this._license = aLicense;
};
BundleTask.prototype.license = function()
{
    return this._license;
};
(BundleTask.prototype.setBuildPath = function(aBuildPath)
{
    this._buildPath = aBuildPath;
}, BundleTask.prototype.buildPath = function()
{
    return this._buildPath;
});
BundleTask.prototype.setBuildIntermediatesPath = function(aBuildPath)
{
    this._buildIntermediatesPath = aBuildPath;
};
BundleTask.prototype.buildIntermediatesPath = function()
{
    return this._buildIntermediatesPath || this.buildPath();
};
BundleTask.prototype.buildProductPath = function()
{
    return path.join(this.buildPath(), this.productName());
};
BundleTask.prototype.buildIntermediatesProductPath = function()
{
    return this.buildIntermediatesPath() || path.join(this.buildPath(), this.productName() + ".build");
};
BundleTask.prototype.buildProductStaticPathForEnvironment = function(anEnvironment)
{
    return path.join(this.buildProductPath(), anEnvironment.name() + ".environment", this.productName() + ".sj");
};
BundleTask.prototype.buildProductMHTMLPathForEnvironment = function(anEnvironment)
{
    return path.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLPaths.txt");
};
BundleTask.prototype.buildProductMHTMLDataPathForEnvironment = function(anEnvironment)
{
    return path.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLData.txt");
};
BundleTask.prototype.buildProductMHTMLTestPathForEnvironment = function(anEnvironment)
{
    return path.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLTest.txt");
};
BundleTask.prototype.buildProductDataURLPathForEnvironment = function(anEnvironment)
{
    return path.join(this.buildProductPath(), anEnvironment.name() + ".environment", "dataURLs.txt");
};
BundleTask.prototype.defineTasks = function()
{
    this.defineResourceTasks();
    this.defineSourceTasks();
    this.defineInfoPlistTask();
    this.defineLicenseTask();
    this.defineStaticTask();
    this.defineSpritedImagesTask();
    CLEAN.include(this.buildIntermediatesProductPath());
    CLOBBER.include(this.buildProductPath());
};
BundleTask.prototype.packageType = function()
{
    return 1;
};
BundleTask.prototype.infoPlist = function()
{
    var infoPlistPath = this.infoPlistPath(),
        infoPlist;
    
    if (infoPlistPath && fs.existsSync(infoPlistPath))
        infoPlist = CFPropertyList.propertyListFromString(fs.readFileSync(infoPlistPath, {encoding: "utf8"}));
    else
        infoPlist = new CFMutableDictionary();
    infoPlist.setValueForKey("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValueForKey("CPBundleName", this.productName());
    infoPlist.setValueForKey("CPBundleIdentifier", this.identifier());
    infoPlist.setValueForKey("CPBundleVersion", this.version());
    infoPlist.setValueForKey("CPBundlePackageType", this.packageType());
    infoPlist.setValueForKey("CPBundleEnvironments", (this.environments()).map(    function(anEnvironment)
    {
        return anEnvironment.name();
    }));
    infoPlist.setValueForKey("CPBundleExecutable", this.productName() + ".sj");
    var environmentsWithImageSprites = ((this.environments()).filter(    function(anEnvironment)
    {
        return anEnvironment.spritesImages() && (((task(this.buildProductDataURLPathForEnvironment(anEnvironment))).prerequisites()).filter(isImage)).length > 0;
    }, this)).map(    function(anEnvironment)
    {
        return anEnvironment.name();
    });
    infoPlist.setValueForKey("CPBundleEnvironmentsWithImageSprites", environmentsWithImageSprites);
    var principalClass = this.principalClass();
    if (principalClass)
        infoPlist.setValueForKey("CPPrincipalClass", principalClass);
    return infoPlist;
};
BundleTask.prototype.defineInfoPlistTask = function()
{
    var infoPlistProductPath = path.join(this.buildProductPath(), "Info.plist"),
        bundleTask = this;
    filedir(infoPlistProductPath,     function()
    {
        fs.writeFileSync(infoPlistProductPath, CFPropertyList.stringFromPropertyList(bundleTask.infoPlist(), CFPropertyList.Format280North_v1_0), { encoding: "utf8"});
    });
    var infoPlistPath = this.infoPlistPath();
    if (infoPlistPath && fs.existsSync(infoPlistPath))
        filedir(infoPlistProductPath, [infoPlistPath]);
    (this.environments()).forEach(    function(anEnvironment)
    {
        if (!anEnvironment.spritesImages())
            return;
        filedir(infoPlistProductPath, this.buildProductStaticPathForEnvironment(anEnvironment));
    }, this);
    this.enhance([infoPlistProductPath]);
};
BundleTask.License = {LGPL_v2_1: "LGPL_v2_1", MIT: "MIT"};

var LICENSES_PATH = path.join(path.resolve(path.extname(module.path)), "LICENSES"),
    LICENSE_PATHS = {"LGPL_v2_1": path.join(LICENSES_PATH, "LGPL-v2.1"), "MIT": path.join(LICENSES_PATH, "MIT")};
BundleTask.prototype.defineLicenseTask = function()
{
    var license = this.license();
    if (!license)
        return;
    var licensePath = LICENSE_PATHS[license];
    licenseProductPath = path.join(this.buildProductPath(), "LICENSE");
    filedir(licenseProductPath, [licensePath],     function()
    {
        fs.copyFileSync(licensePath, licenseProductPath);
    });
    this.enhance([licenseProductPath]);
};
BundleTask.prototype.resourcesPath = function()
{
    return path.join(this.buildProductPath(), "Resources", "");
};
BundleTask.isSpritable = function(aResourcePath) {
    return isImage(aResourcePath) && fs.lstatSync(aResourcePath).size < 32768 && ("data:" + mimeType(aResourcePath) + ";base64," + Buffer.from(fs.readFileSync(aResourcePath)).toString("base64")).length < 32768;
};
BundleTask.prototype.defineResourceTask = function(aResourcePath, aDestinationPath)
{
    if (this.spritesResources() && BundleTask.isSpritable(aResourcePath))
    {
        (this.environments()).forEach(        function(anEnvironment)
        {
            if (!anEnvironment.spritesImages())
                return;
            var folder = anEnvironment.name() + ".environment",
                spritedDestinationPath = path.join(this.buildIntermediatesProductPath(), folder, "Resources", path.relative(this.resourcesPath(), aDestinationPath));
            filedir(spritedDestinationPath,             function()
            {
                fs.writeFileSync(spritedDestinationPath, Buffer.from(fs.readFileSync(aResourcePath)).toString("base64"), { encoding: "utf8" });
            });
            filedir(this.buildProductDataURLPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir(this.buildProductMHTMLPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir(this.buildProductMHTMLDataPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir(this.buildProductMHTMLTestPathForEnvironment(anEnvironment), [spritedDestinationPath]);
        }, this);
    }    var extension = path.extname(aResourcePath),
        extensionless = aResourcePath.substr(0, aResourcePath.length - extension.length);
    if ((extension !== ".cib" || !fs.existsSync(extensionless + ".xib") && !fs.existsSync(extensionless + ".nib") || this._preventsNib2Cib) && (extension !== ".xib" && extension !== ".nib" || this.includesNibsAndXibs()))
    {
        filedir(aDestinationPath, [aResourcePath],         function()
        {
            if (fs.existsSync(aDestinationPath))
                try {
                    fs.rmSync(aDestinationPath, { recursive: true });
                }
                catch(anException) {
                }
            if (fs.lstatSync(aResourcePath).isDirectory())
                fs.copySync(aResourcePath, aDestinationPath, { recursive: true });
            else
                fs.copySync(aResourcePath, aDestinationPath);
        });
        this.enhance([aDestinationPath]);
    }    if ((extension === ".xib" || extension === ".nib") && !this._preventsNib2Cib)
    {
        var cibDestinationPath = path.join(path.dirname(aDestinationPath), path.basename(aDestinationPath, extension)) + ".cib";
        var nib2cibFlags = this.nib2cibFlags();
        if (!nib2cibFlags)
            nib2cibFlags = "";
        else if (nib2cibFlags.join)
            nib2cibFlags = nib2cibFlags.join(" ");
        filedir(cibDestinationPath, [aResourcePath],         function()
        {
            child_process.execSync("nib2cib " + aResourcePath + " " + cibDestinationPath + " " + nib2cibFlags);
        });
        this.enhance([cibDestinationPath]);
    }};
function directoryInCommon(filenames)
{
    var aCommonDirectory = null;
    filenames.forEach(    function(aFilename)
    {
        var directory = path.dirname(aFilename);
        if (directory === ".")
            directory = "";
        if (aCommonDirectory === null)
            aCommonDirectory = directory;
        else
        {
            var index = 0,
                count = Math.min(directory.length, aFilename.length);
            for (; index < count && aCommonDirectory.charAt(index) === directory.charAt(index); ++index);
            aCommonDirectory = directory.substr(0, index);
        }    });
    return aCommonDirectory;
}
BundleTask.prototype.defineResourceTasks = function()
{
    if (!this._resources)
        return;
    var resources = [],
        basePath = null;
    this._resources.forEach(    function(aResourcePath)
    {
        if (fs.lstatSync(aResourcePath).isDirectory())
        {
            resources = resources.concat(aResourcePath, glob.sync(aResourcePath + "/**"));
        }        else
            resources.push(aResourcePath);
    });
    // TODO: too lazy to look this up, assuming it returns the array without duplicates
    // resources = UTIL.unique(resources);
    resources = [... new Set(resources)];
    if (resources.length <= 0)
        return;
    var basePathLength = (directoryInCommon(resources)).length,
        resourcesPath = this.resourcesPath();
    resources.forEach(    function(aResourcePath)
    {
        this.defineResourceTask(aResourcePath, path.join(resourcesPath, aResourcePath.substring(basePathLength)));
    }, this);
};
var RESOURCES_PATH = path.join(path.resolve(path.dirname(module.path)), "RESOURCES"),
    MHTMLTestPath = path.join(RESOURCES_PATH, "MHTMLTest.txt");
BundleTask.prototype.defineSpritedImagesTask = function()
{
    (this.environments()).forEach(    function(anEnvironment)
    {
        if (!anEnvironment.spritesImages())
            return;
        var folder = anEnvironment.name() + ".environment",
            resourcesPath = path.join(this.buildIntermediatesProductPath(), folder, "Resources", "");
        var productName = this.productName(),
            dataURLPath = this.buildProductDataURLPathForEnvironment(anEnvironment);
        filedir(dataURLPath, function(aTask){
            var prerequisites = (aTask.prerequisites()).filter(isImage);
            if (!prerequisites.length)
            {
                if (fs.existsSync(dataURLPath))
                    fs.removeSync(dataURLPath);
                return;
            }          
            
            console.log("Creating data URLs file... \0green(" + dataURLPath + "\0)");
            var dataURLStream = fs.openSync(dataURLPath, "w+");
            fs.writeSync(dataURLStream, "@STATIC;1.0;");

            prerequisites.forEach(function(aFilename)
            {
                var resourcePath = "Resources/" + path.relative(resourcesPath, aFilename);
                fs.writeFileSync(dataURLStream, "u;" + resourcePath.length + ";" + resourcePath, {encoding: "utf8"});
                var contents = "data:" + mimeType(aFilename) + ";base64," + fs.readFileSync(aFilename).toString("utf8");
                fs.writeFileSync(dataURLStream, contents.length + ";" + contents, { encoding: "utf8" });
            });

            fs.writeFileSync(dataURLStream, "e;", { encoding: "utf8"});
            fs.closeSync(dataURLStream);
        });
        this.enhance([dataURLPath]);
        var MHTMLPath = this.buildProductMHTMLPathForEnvironment(anEnvironment);
        filedir(MHTMLPath,         function(aTask)
        {
            var prerequisites = (aTask.prerequisites()).filter(isImage);
            if (!prerequisites.length)
            {
                if (fs.existsSync(MHTMLPath))
                    fs.rmSync(MHTMLPath);
                return;
            }

            console.log("Creating MHTML paths file... \0green(" + MHTMLPath + "\0)");
            var MHTMLStream = fs.openSync(MHTMLPath, "w+");
            fs.writeSync(MHTMLStream, "@STATIC;1.0;");

            prerequisites.forEach(            function(aFilename)
            {
                var resourcePath = "Resources/" + path.relative(resourcesPath, aFilename),
                    MHTMLResourcePath = "mhtml:" + path.join(folder, "MHTMLData.txt!") + resourcePath;
                MHTMLStream.write("u;" + resourcePath.length + ";" + resourcePath);
                MHTMLStream.write(MHTMLResourcePath.length + ";" + MHTMLResourcePath);
            });
            fs.closeSync(MHTMLStream);
            MHTMLStream.close();
        });
        this.enhance([MHTMLPath]);
        var MHTMLDataPath = this.buildProductMHTMLDataPathForEnvironment(anEnvironment);
        filedir(MHTMLDataPath,         function(aTask)
        {
            var prerequisites = (aTask.prerequisites()).filter(isImage);
            if (!prerequisites.length)
            {
                if (fs.existsSync(MHTMLDataPath))
                    fs.rmSync(MHTMLDataPath);
                return;
            }
            console.log("Creating MHTML images file... \0green(" + MHTMLDataPath + "\0)");
            //var MHTMLDataStream = FILE.open(MHTMLDataPath, "w+", {charset: "UTF-8"});
            var MHTMLDataStream = fs.openSync(MHTMLDataPath, "w+");
            MHTMLDataStream.write("/*\r\nContent-Type: multipart/related; boundary=\"_ANY_STRING_WILL_DO_AS_A_SEPARATOR\"\r\n\r\n");
            prerequisites.forEach(            function(aFilename)
            {
                var resourcePath = "Resources/" + path.relative(resourcesPath, aFilename);
                MHTMLDataStream.write("--_ANY_STRING_WILL_DO_AS_A_SEPARATOR\r\n");
                MHTMLDataStream.write("Content-Location:" + resourcePath + "\r\nContent-Transfer-Encoding:base64\r\n\r\n");
                MHTMLDataStream.write(fs.readFileSync(aFilename).toString("utf8"));
                MHTMLDataStream.write("\r\n");
            });
            MHTMLDataStream.write("*/");
            MHTMLDataStream.close();
        });
        this.enhance([MHTMLDataPath]);
        var MHTMLTestDestinationPath = this.buildProductMHTMLTestPathForEnvironment(anEnvironment);
        filedir(MHTMLTestDestinationPath,         function(aTask)
        {
            console.log("Copying MHTML test file... \0green(" + MHTMLTestDestinationPath + "\0)");
            fs.copyFileSync(MHTMLTestPath, MHTMLTestDestinationPath);
        });
        this.enhance([MHTMLTestDestinationPath]);
    }, this);
};
BundleTask.prototype.defineStaticTask = function()
{
    (this.environments()).forEach(    function(anEnvironment)
    {
        var folder = anEnvironment.name() + ".environment",
            sourcesPath = path.join(this.buildIntermediatesProductPath(), folder, "Sources", ""),
            resourcesPath = path.join(this.buildIntermediatesProductPath(), folder, "Resources", ""),
            staticPath = this.buildProductStaticPathForEnvironment(anEnvironment),
            flattensSources = this.flattensSources(),
            productName = this.productName();
        filedir(staticPath,         function(aTask)
        {
            console.log("Creating static file... \0green(" + staticPath + "\0)");
            //TERM.stream.print("Creating static file... \0green(" + staticPath + "\0)");
            var fileStream = fs.openSync(staticPath, "w+");
            fileStream.write("@STATIC;1.0;");
            (aTask.prerequisites()).forEach(            function(aFilename)
            {
                if (!fs.lstatSync(aFilename).isFile())
                    return;
                var dirname = path.dirname(aFilename);
                if (aFilename.indexOf(sourcesPath) === 0)
                {
                    var relativePath = flattensSources ? path.basename(aFilename) : path.relative(sourcesPath, aFilename);
                    fileStream.write("p;" + relativePath.length + ";" + relativePath);
                    var fileContents = fs.readFileSync(aFilename).toString("utf8");
                    fileStream.write("t;" + fileContents.length + ";" + fileContents);
                }                else if (aFilename.indexOf(resourcesPath) === 0 && !isImage(aFilename))
                {
                    var resourcePath = "Resources/" + path.relative(resourcesPath, aFilename);
                    fileStream.write("p;");
                    contents = fs.readFileSync(aFilename).toString("utf8");
                    fileStream.write(resourcePath.length + ";" + resourcePath + contents);
                }            }, this);
            fileStream.write("e;");
            fileStream.close();
            ObjectiveJ.Executable.resetCachedFileExecutableSearchers();
            ObjectiveJ.StaticResource.resetRootResources();
            ObjectiveJ.FileExecutable.resetFileExecutables();
            objj_resetRegisterClasses();
        });
        this.enhance([staticPath]);
    }, this);
};
BundleTask.prototype.defineSourceTasks = function()
{
    var sources = this.sources();
    if (!sources)
        return;
    var compilerFlags = this.compilerFlags(),
        flattensSources = this.flattensSources();
    if (!compilerFlags)
        compilerFlags = "";
    else if (compilerFlags.join)
        compilerFlags = compilerFlags.join(" ");
    (this.environments()).forEach(    function(anEnvironment)
    {
        var environmentSources = sources,
            folder = anEnvironment.name() + ".environment",
            sourcesPath = path.join(this.buildIntermediatesProductPath(), folder, "Sources", ""),
            staticPath = this.buildProductStaticPathForEnvironment(anEnvironment);
        if (!Array.isArray(environmentSources) && environmentSources.constructor !== jake.FileList)
        {
            environmentSources = environmentSources[anEnvironment];
            if (!environmentSources)
                return;
        }        var replacedFiles = [],
            environmentCompilerFlags = (anEnvironment.compilerFlags()).join(" ") + " " + compilerFlags,
            flattensSources = this.flattensSources(),
            basePath = directoryInCommon(environmentSources),
            basePathLength = basePath.length,
            translateFilenameToPath = {},
            otherwayTranslateFilenameToPath = {};
        environmentSources.forEach(        function(aFilename)
        {
            translateFilenameToPath[flattensSources ? path.basename(aFilename) : aFilename] = aFilename;
            otherwayTranslateFilenameToPath[aFilename] = flattensSources ? path.basename(aFilename) : aFilename;
        }, this);
        var e = {};
        environmentSources.forEach(        function(aFilename)
        {
            ObjectiveJ.Executable.resetCachedFileExecutableSearchers();
            ObjectiveJ.StaticResource.resetRootResources();
            ObjectiveJ.FileExecutable.resetFileExecutables();
            objj_resetRegisterClasses();
            if (!fs.existsSync(aFilename))
                return;
            var relativePath = aFilename.substring(basePathLength ? basePathLength + 1 : basePathLength),
                compiledEnvironmentSource = path.join(sourcesPath, relativePath);
            filedir(compiledEnvironmentSource, [aFilename],             function()
            {
                var rhinoUglyFix = false;
                if (system.engine === "rhino")
                {
                    if (typeof document == "undefined")
                    {
                        document = {createElement:                         function(x)
                        {
                            return {innerText: "", style: {}};
                        }};
                        rhinoUglyFix = true;
                    }                    if (typeof navigator == "undefined")
                    {
                        navigator = {"userAgent": "fakenavigator"};
                        rhinoUglyFix = true;
                    }                }                var compile;
                if ((path.extname(aFilename)).toLowerCase() !== ".j")
                {
                    console.log("Including [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)");
                    //(TERM.stream.write("Including [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)")).flush();
                    var compiled = fs.readFileSync(aFilename, { encoding: "utf8"});
                }                else
                {
                    var translatedFilename = translateFilenameToPath[aFilename] ? translateFilenameToPath[aFilename] : aFilename,
                        otherwayTranslatedFilename = otherwayTranslateFilenameToPath[aFilename] ? otherwayTranslateFilenameToPath[aFilename] : aFilename,
                        theTranslatedFilename = otherwayTranslatedFilename ? otherwayTranslatedFilename : translatedFilename,
                        absolutePath = path.absolute(theTranslatedFilename),
                        basePath = absolutePath.substring(0, absolutePath.length - theTranslatedFilename.length);
                    ObjectiveJ.FileExecutable.setCurrentGccCompilerFlags(environmentCompilerFlags);
                    CFBundle.environments =                     function()
                    {
                        return [anEnvironment.name(), "ObjJ"];
                    };
                    ObjectiveJ.make_narwhal_factory(absolutePath, basePath, translateFilenameToPath)(require, e, module, system, print);
                    console.log("Compiling [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)");
                    //(TERM.stream.write("Compiling [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)")).flush();
                    var otherwayTranslatedFilename = otherwayTranslateFilenameToPath[aFilename] ? otherwayTranslateFilenameToPath[aFilename] : aFilename,
                        translatedFilename = translateFilenameToPath[aFilename] ? translateFilenameToPath[aFilename] : aFilename,
                        executer = new ObjectiveJ.FileExecutable(otherwayTranslatedFilename);
                    var compiled = executer.toMarkedString();
                }                if (rhinoUglyFix)
                    delete document;
                console.log(compiledEnvironmentSource);
                console.log((Array(Math.round(compiled.length / 1024) + 3)).join("."));
                fs.writeFileSync(compiledEnvironmentSource, compiled, { encoding: "utf8"});
            });
            filedir(staticPath, [compiledEnvironmentSource]);
            replacedFiles.push(flattensSources ? path.basename(aFilename) : relativePath);
        }, this);
        this._replacedFiles[anEnvironment] = replacedFiles;
    }, this);
};
exports.BundleTask = BundleTask;
exports.bundle = function(aName, aFunction)
{
    return BundleTask.defineTask(aName, aFunction);
};
