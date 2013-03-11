
var FILE = require("file"),
    OS = require("os"),
    UTIL = require("narwhal/util"),
    TERM = require("narwhal/term"),
    Jake = require("jake"),
    CLEAN = require("jake/clean").CLEAN,
    CLOBBER = require("jake/clean").CLOBBER,
    base64 = require("base64"),
    ObjectiveJ = require("objective-j"),
    environment = require("objective-j/jake/environment"),
    task = Jake.task;

var Task = Jake.Task,
    filedir = Jake.filedir;

function isImage(/*String*/ aFilename)
{
    return UTIL.has([".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"], FILE.extension(aFilename).toLowerCase());
}

function mimeType(/*String*/ aFilename)
{
    return  {
                ".png"  : "image/png",
                ".jpg"  : "image/jpeg",
                ".jpeg" : "image/jpeg",
                ".gif"  : "image/gif",
                ".tif"  : "image/tiff",
                ".tiff" : "image/tiff"
            }[FILE.extension(aFilename).toLowerCase()];
}

function BundleTask(aName, anApplication)
{
    Task.apply(this, arguments);

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
    this._buildPath = FILE.cwd();

    this._replacedFiles = { };
    this._nib2cibFlags = null;

    this._infoPlistPath = "Info.plist";
    this._principalClass = null;
}

BundleTask.__proto__ = Task;
BundleTask.prototype.__proto__ = Task.prototype;

BundleTask.defineTask = function(/*String*/ aName, /*Function*/ aFunction)
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
            this._sources = { };

        // If a single envirnment was passed in...
        if (!Array.isArray(environments))
            environments = [environments];

        environments.forEach(function(anEnvironment)
        {
            this._sources[anEnvironment] = sources;
        }, this);
    }
};

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

BundleTask.prototype.setFlattensSources = function(/*Boolean*/ shouldFlattenSources)
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

BundleTask.prototype.setBuildPath = function(aBuildPath)
{
    this._buildPath = aBuildPath;
},

BundleTask.prototype.buildPath = function()
{
    return this._buildPath;
};

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
    return FILE.join(this.buildPath(), this.productName());
};

BundleTask.prototype.buildIntermediatesProductPath = function()
{
    return this.buildIntermediatesPath() || FILE.join(this.buildPath(), this.productName() + ".build");
};

BundleTask.prototype.buildProductStaticPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", this.productName() + ".sj");
};

BundleTask.prototype.buildProductMHTMLPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLPaths.txt");
};

BundleTask.prototype.buildProductMHTMLDataPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLData.txt");
};

BundleTask.prototype.buildProductMHTMLTestPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", "MHTMLTest.txt");
};

BundleTask.prototype.buildProductDataURLPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", "dataURLs.txt");
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

    if (infoPlistPath && FILE.exists(infoPlistPath))
        infoPlist = CFPropertyList.propertyListFromString(FILE.read(infoPlistPath, { charset:"UTF-8" }));
    else
        infoPlist = new CFMutableDictionary();

    // FIXME: Should all of these unconditionally overwrite?
    infoPlist.setValueForKey("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValueForKey("CPBundleName", this.productName());
    infoPlist.setValueForKey("CPBundleIdentifier", this.identifier());
    infoPlist.setValueForKey("CPBundleVersion", this.version());
    infoPlist.setValueForKey("CPBundlePackageType", this.packageType());
    infoPlist.setValueForKey("CPBundleEnvironments", this.environments().map(function(anEnvironment)
    {
        return anEnvironment.name();
    }));
    infoPlist.setValueForKey("CPBundleExecutable", this.productName() + ".sj");

    var environmentsWithImageSprites = this.environments().filter(
    function(anEnvironment)
    {
        return anEnvironment.spritesImages() && task(this.buildProductDataURLPathForEnvironment(anEnvironment)).prerequisites().filter(isImage).length > 0;
    }, this).map(function(anEnvironment)
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
    var infoPlistProductPath = FILE.join(this.buildProductPath(), "Info.plist"),
        bundleTask = this;

    filedir (infoPlistProductPath, function()
    {
        FILE.write(infoPlistProductPath, CFPropertyList.stringFromPropertyList(bundleTask.infoPlist(), CFPropertyList.Format280North_v1_0), { charset:"UTF-8" });
    });

    var infoPlistPath = this.infoPlistPath();

    if (infoPlistPath && FILE.exists(infoPlistPath))
        filedir (infoPlistProductPath, [infoPlistPath]);

    // FIXME: ? We do this because adding a .j file should cause Info.plist to be updated.
    // Any better way to handle this? Perhaps this should happen unconditionally.
    this.environments().forEach(function(/*Environment*/ anEnvironment)
    {
        if (!anEnvironment.spritesImages())
            return;

        filedir (infoPlistProductPath, this.buildProductStaticPathForEnvironment(anEnvironment));
    }, this);

    this.enhance([infoPlistProductPath]);
};

BundleTask.License  =   {
                            LGPL_v2_1   : "LGPL_v2_1",
                            MIT         : "MIT"
                        };

var LICENSES_PATH   = FILE.join(FILE.absolute(FILE.dirname(module.path)), "LICENSES"),
    LICENSE_PATHS   =   {
                            "LGPL_v2_1" : FILE.join(LICENSES_PATH, "LGPL-v2.1"),
                            "MIT"       : FILE.join(LICENSES_PATH, "MIT")
                        };

BundleTask.prototype.defineLicenseTask = function()
{
    var license = this.license();

    if (!license)
        return;

    var licensePath = LICENSE_PATHS[license];
        licenseProductPath = FILE.join(this.buildProductPath(), "LICENSE");

    filedir (licenseProductPath, [licensePath], function()
    {
        FILE.copy(licensePath, licenseProductPath);
    });

    this.enhance([licenseProductPath]);
};

BundleTask.prototype.resourcesPath = function()
{
    return FILE.join(this.buildProductPath(), "Resources", "");
};

// Don't sprite images larger than 32KB, IE 8 doesn't like it.
BundleTask.isSpritable = function(aResourcePath) {
    return isImage(aResourcePath) && FILE.size(aResourcePath) < 32768 &&
           ("data:" + mimeType(aResourcePath) + ";base64," +
            base64.encode(FILE.read(aResourcePath, "b"))).length < 32768;
};

BundleTask.prototype.defineResourceTask = function(aResourcePath, aDestinationPath)
{
    if (this.spritesResources() && BundleTask.isSpritable(aResourcePath))
    {
        this.environments().forEach(function(/*Environment*/ anEnvironment)
        {
            if (!anEnvironment.spritesImages())
                return;

            var folder = anEnvironment.name() + ".environment",
                spritedDestinationPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Resources", FILE.relative(this.resourcesPath(), aDestinationPath));

            filedir (spritedDestinationPath, function()
            {
                FILE.write(spritedDestinationPath, base64.encode(FILE.read(aResourcePath, "b")), { charset:"UTF-8" });
            });

            filedir (this.buildProductDataURLPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir (this.buildProductMHTMLPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir (this.buildProductMHTMLDataPathForEnvironment(anEnvironment), [spritedDestinationPath]);
            filedir (this.buildProductMHTMLTestPathForEnvironment(anEnvironment), [spritedDestinationPath]);

        }, this);
    }

    var extension = FILE.extension(aResourcePath),
        extensionless = aResourcePath.substr(0, aResourcePath.length - extension.length);
    // NOT:
    // (extname === ".cib" && (FILE.exists(extensionless + '.xib') || FILE.exists(extensionless + '.nib') && !this._preventsNib2Cib) ||
    // (extname === ".xib" || extname === ".nib") && !this.shouldIncludeNibsAndXibs())
    if ((extension !== ".cib" || !FILE.exists(extensionless + ".xib") && !FILE.exists(extensionless + ".nib") || this._preventsNib2Cib) &&
        ((extension !== ".xib" && extension !== ".nib") || this.includesNibsAndXibs()))
    {
        filedir (aDestinationPath, [aResourcePath], function()
        {
            if (FILE.exists(aDestinationPath))
                try { FILE.rmtree(aDestinationPath); } catch (anException) { }

            if (FILE.isDirectory(aResourcePath))
                FILE.copyTree(aResourcePath, aDestinationPath);
            else
                FILE.copy(aResourcePath, aDestinationPath);
        });

        this.enhance([aDestinationPath]);
    }

    if ((extension === ".xib" || extension === ".nib") && !this._preventsNib2Cib)
    {
        var cibDestinationPath = FILE.join(FILE.dirname(aDestinationPath), FILE.basename(aDestinationPath, extension)) + ".cib";

        var nib2cibFlags = this.nib2cibFlags();

        if (!nib2cibFlags)
            nib2cibFlags = "";

        else if (nib2cibFlags.join)
            nib2cibFlags = nib2cibFlags.join(" ");

        filedir (cibDestinationPath, [aResourcePath], function()
        {
            OS.system("nib2cib " + aResourcePath + " "  + cibDestinationPath + " " + nib2cibFlags);
        });

        this.enhance([cibDestinationPath]);
    }
};

function directoryInCommon(filenames)
{
    var aCommonDirectory = null;

    filenames.forEach(function(aFilename)
    {
        var directory = FILE.dirname(aFilename);

        if (directory === ".")
            directory = "";

        // Empty string is an acceptable common directory.
        if (aCommonDirectory === null)
            aCommonDirectory = directory;

        else
        {
            var index = 0,
                count = Math.min(directory.length, aFilename.length);

            for (; index < count && aCommonDirectory.charAt(index) === directory.charAt(index); ++index) ;

            aCommonDirectory = directory.substr(0, index);
        }
    });

    return aCommonDirectory;
}

BundleTask.prototype.defineResourceTasks = function()
{
    if (!this._resources)
        return;

    var resources = [],
        basePath = null;

    // Resolve resources. Consider any file passed in as a resource.
    this._resources.forEach(function(aResourcePath)
    {
        if (FILE.isDirectory(aResourcePath))
        {
            // Add the directory itself as well since it is a legitimate resource as well.
            resources = resources.concat(aResourcePath, FILE.glob(aResourcePath + "/**"));
        }
        else
            resources.push(aResourcePath);
    });

    resources = UTIL.unique(resources);

    if (resources.length <= 0)
        return;

    var basePathLength = directoryInCommon(resources).length,
        resourcesPath = this.resourcesPath();

    resources.forEach(function(aResourcePath)
    {
        this.defineResourceTask(aResourcePath, FILE.join(resourcesPath, aResourcePath.substring(basePathLength)));
    }, this);
};

var RESOURCES_PATH  = FILE.join(FILE.absolute(FILE.dirname(module.path)), "RESOURCES"),
    MHTMLTestPath   = FILE.join(RESOURCES_PATH, "MHTMLTest.txt");

BundleTask.prototype.defineSpritedImagesTask = function()
{
    this.environments().forEach(function(/*Environment*/ anEnvironment)
    {
        if (!anEnvironment.spritesImages())
            return;

        var folder = anEnvironment.name() + ".environment",
            resourcesPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Resources", "");

        var productName = this.productName(),
            dataURLPath = this.buildProductDataURLPathForEnvironment(anEnvironment);

        filedir (dataURLPath, function(aTask)
        {
            var prerequisites = aTask.prerequisites().filter(isImage);

            if (!prerequisites.length)
            {
                if (FILE.exists(dataURLPath))
                    FILE.remove(dataURLPath);

                return;
            }

            TERM.stream.print("Creating data URLs file... \0green(" + dataURLPath +"\0)");

            var dataURLStream = FILE.open(dataURLPath, "w+", { charset:"UTF-8" });

            dataURLStream.write("@STATIC;1.0;");

            prerequisites.forEach(function(aFilename)
            {
                var resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename);

                dataURLStream.write("u;" + resourcePath.length + ";" + resourcePath);

                var contents =  "data:" + mimeType(aFilename) +
                                ";base64," + FILE.read(aFilename, "b").decodeToString("UTF-8");

                dataURLStream.write(contents.length + ";" + contents);
            });

            dataURLStream.write("e;");
            dataURLStream.close();
        });

        this.enhance([dataURLPath]);

        var MHTMLPath = this.buildProductMHTMLPathForEnvironment(anEnvironment);

        filedir (MHTMLPath, function(aTask)
        {
            var prerequisites = aTask.prerequisites().filter(isImage);

            if (!prerequisites.length)
            {
                if (FILE.exists(MHTMLPath))
                    FILE.remove(MHTMLPath);

                return;
            }

            TERM.stream.print("Creating MHTML paths file... \0green(" + MHTMLPath +"\0)");

            var MHTMLStream = FILE.open(MHTMLPath, "w+", { charset:"UTF-8" });

            MHTMLStream.write("@STATIC;1.0;");

            prerequisites.forEach(function(aFilename)
            {
                var resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename),
                    MHTMLResourcePath = "mhtml:" + FILE.join(folder, "MHTMLData.txt!") + resourcePath;

                MHTMLStream.write("u;" + resourcePath.length + ";" + resourcePath);
                MHTMLStream.write(MHTMLResourcePath.length + ";" + MHTMLResourcePath);
            });

            MHTMLStream.close();
        });

        this.enhance([MHTMLPath]);

        var MHTMLDataPath = this.buildProductMHTMLDataPathForEnvironment(anEnvironment);

        filedir (MHTMLDataPath, function(aTask)
        {
            var prerequisites = aTask.prerequisites().filter(isImage);

            if (!prerequisites.length)
            {
                if (FILE.exists(MHTMLDataPath))
                    FILE.remove(MHTMLDataPath);

                return;
            }

            TERM.stream.print("Creating MHTML images file... \0green(" + MHTMLDataPath +"\0)");

            var MHTMLDataStream = FILE.open(MHTMLDataPath, "w+", { charset:"UTF-8" });

            MHTMLDataStream.write("/*\r\nContent-Type: multipart/related; boundary=\"_ANY_STRING_WILL_DO_AS_A_SEPARATOR\"\r\n\r\n");

            prerequisites.forEach(function(aFilename)
            {
                var resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename);

                MHTMLDataStream.write("--_ANY_STRING_WILL_DO_AS_A_SEPARATOR\r\n");
                MHTMLDataStream.write("Content-Location:" + resourcePath + "\r\nContent-Transfer-Encoding:base64\r\n\r\n");
                MHTMLDataStream.write(FILE.read(aFilename, "b").decodeToString("UTF-8"));
                MHTMLDataStream.write("\r\n");
            });

            MHTMLDataStream.write("*/");
            MHTMLDataStream.close();
        });

        this.enhance([MHTMLDataPath]);

        var MHTMLTestDestinationPath = this.buildProductMHTMLTestPathForEnvironment(anEnvironment);

        filedir (MHTMLTestDestinationPath, function(aTask)
        {
            TERM.stream.print("Copying MHTML test file... \0green(" + MHTMLTestDestinationPath +"\0)");

            FILE.copy(MHTMLTestPath, MHTMLTestDestinationPath);
        });

        this.enhance([MHTMLTestDestinationPath]);
    }, this);
};

BundleTask.prototype.defineStaticTask = function()
{
    this.environments().forEach(function(/*Environment*/ anEnvironment)
    {
        var folder = anEnvironment.name() + ".environment",
            sourcesPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Sources", ""),
            resourcesPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Resources", ""),
            staticPath = this.buildProductStaticPathForEnvironment(anEnvironment),
            flattensSources = this.flattensSources(),
            productName = this.productName();

        filedir (staticPath, function(aTask)
        {
            TERM.stream.print("Creating static file... \0green(" + staticPath +"\0)");

            var fileStream = FILE.open(staticPath, "w+", { charset:"UTF-8" });

            fileStream.write("@STATIC;1.0;");

            aTask.prerequisites().forEach(function(aFilename)
            {
                // Our prerequisites will contain directories due to filedir.
                if (!FILE.isFile(aFilename))
                    return;

                var dirname = FILE.dirname(aFilename);

                if (aFilename.indexOf(sourcesPath) === 0)
                {
                    var relativePath = flattensSources ? FILE.basename(aFilename) : FILE.relative(sourcesPath, aFilename);

                    // FIXME: We need to do this for now due to file.read adding newlines in Rhino. Revert when fixed.
                    //fileStream.write(FILE.read(aFilename, "b").decodeToString("UTF-8"));
                    fileStream.write("p;" + relativePath.length + ";" + relativePath);

                    var fileContents = FILE.read(aFilename, "b").decodeToString("UTF-8");

                    fileStream.write("t;" + fileContents.length + ";" + fileContents);
                }

                else if (aFilename.indexOf(resourcesPath) === 0 && !isImage(aFilename))
                {
                    var resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename);

                    fileStream.write("p;");

                    contents = FILE.read(aFilename, "b").decodeToString("UTF-8");

                    fileStream.write(resourcePath.length + ";" + resourcePath + contents);
                }
            }, this);

            fileStream.write("e;");
            fileStream.close();

           // Make sure all classes are removed and all FileExecutables are removed.
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

    this.environments().forEach(function(/*Environment*/ anEnvironment)
    {
        var environmentSources = sources,
            folder = anEnvironment.name() + ".environment",
            sourcesPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Sources", ""),
            staticPath = this.buildProductStaticPathForEnvironment(anEnvironment);

        if (!Array.isArray(environmentSources) && environmentSources.constructor !== Jake.FileList)
        {
            environmentSources = environmentSources[anEnvironment];

            if (!environmentSources)
                return;
        }

        var replacedFiles = [],
            environmentCompilerFlags = anEnvironment.compilerFlags().join(" ") + " " + compilerFlags,
            flattensSources = this.flattensSources(),
            basePath = directoryInCommon(environmentSources),
            basePathLength = basePath.length,
            translateFilenameToPath = {},
            otherwayTranslateFilenameToPath = {};

        // Create a filename to filename path dictionary. (For example: CPArray.j -> CPArray/CPArray.j)
        environmentSources.forEach(function(/*String*/ aFilename)
        {
            translateFilenameToPath[flattensSources ? FILE.basename(aFilename) : aFilename] = aFilename;
            otherwayTranslateFilenameToPath[aFilename] = flattensSources ? FILE.basename(aFilename) : aFilename;
        }, this);

        var e = {};

        environmentSources.forEach(function(/*String*/ aFilename)
        {
           // Make sure all classes are removed and all FileExecutables are removed.
            ObjectiveJ.Executable.resetCachedFileExecutableSearchers();
            ObjectiveJ.StaticResource.resetRootResources();
            ObjectiveJ.FileExecutable.resetFileExecutables();
            objj_resetRegisterClasses();

            if (!FILE.exists(aFilename))
                return;

            var relativePath = aFilename.substring(basePathLength ? basePathLength + 1 : basePathLength),
                compiledEnvironmentSource = FILE.join(sourcesPath, relativePath);

            filedir (compiledEnvironmentSource, [aFilename], function()
            {
                // This ugly fix to make Cappuccino compile with rhino can be removed when the compiler is not loading classes into the runtime
                var rhinoUglyFix = false;
                if (system.engine === "rhino")
                {
                    if (typeof document == "undefined") {
                        document = {
                            createElement: function(x)
                            {
                                return {innerText: "", style: {}};
                            }
                        };
                        rhinoUglyFix = true;
                    }

                    if (typeof navigator == "undefined")
                    {
                        navigator =  { "userAgent": "fakenavigator" };
                        rhinoUglyFix = true;
                    }
                }

                var compile;
                // if this file doesn't exist or isn't a .j file, don't preprocess it.
                if (FILE.extension(aFilename).toLowerCase() !== ".j")
                {
                    TERM.stream.write("Including [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)").flush();
                    var compiled = FILE.read(aFilename, { charset:"UTF-8" });
                }
                else
                {
                    var translatedFilename = translateFilenameToPath[aFilename] ? translateFilenameToPath[aFilename] : aFilename,
                        otherwayTranslatedFilename = otherwayTranslateFilenameToPath[aFilename] ? otherwayTranslateFilenameToPath[aFilename] : aFilename,
                        theTranslatedFilename = otherwayTranslatedFilename ? otherwayTranslatedFilename : translatedFilename,
                        absolutePath = FILE.absolute(theTranslatedFilename),
                        basePath = absolutePath.substring(0, absolutePath.length - theTranslatedFilename.length);

                    // Here we set the current compiler flags so the load system will know what compiler flags to use
                    ObjectiveJ.setCurrentCompilerFlags(environmentCompilerFlags);
                    // Here we tell the CFBundle to load frameworks for the current build enviroment and not the enviroment that is running
                    CFBundle.environments = function() {return [anEnvironment.name(), "ObjJ"]};
                    ObjectiveJ.make_narwhal_factory(absolutePath, basePath, translateFilenameToPath)(require, e, module, system, print);
                    TERM.stream.write("Compiling [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)").flush();

                    var otherwayTranslatedFilename = otherwayTranslateFilenameToPath[aFilename] ? otherwayTranslateFilenameToPath[aFilename] : aFilename,
                        translatedFilename = translateFilenameToPath[aFilename] ? translateFilenameToPath[aFilename] : aFilename,
                        executer = new ObjectiveJ.FileExecutable(otherwayTranslatedFilename);

                    var compiled = executer.toMarkedString();
                }

                if (rhinoUglyFix)
                    delete document;

                TERM.stream.print(Array(Math.round(compiled.length / 1024) + 3).join("."));
                FILE.write(compiledEnvironmentSource, compiled, { charset:"UTF-8" });
            });

            filedir (staticPath, [compiledEnvironmentSource]);


            replacedFiles.push(flattensSources ? FILE.basename(aFilename) : relativePath);
        }, this);

        this._replacedFiles[anEnvironment] = replacedFiles;
   }, this);
};

exports.BundleTask = BundleTask;

exports.bundle = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BundleTask.defineTask(aName, aFunction);
};
