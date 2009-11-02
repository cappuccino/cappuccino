
var FILE = require("file"),
    OS = require("os"),
    UTIL = require("util"),
    Jake = require("jake"),
    CLEAN = require("jake/clean").CLEAN,
    CLOBBER = require("jake/clean").CLOBBER,
    base64 = require("base64");

var Task = Jake.Task,
    filedir = Jake.filedir;

function BundleTask(aName, anApplication)
{
    Task.apply(this, arguments);

    this._author = null;
    this._email = null;
    this._summary = null;

    this._license = null;
    this._platforms = [BundleTask.Platform.ObjJ];
    this._sources = null;
    this._resources = null;
    this._spritesResources = true;
    this._identifier = null;
    this._version = 0.1;

    this._compilerFlags = null;
    this._flattensSources = false;
    this._includesNibsAndXibs = false;

    this._productName = this.name();

    this._buildIntermediatesPath = null;
    this._buildPath = FILE.cwd();

    this._replacedFiles = { };
    this._nib2cibFlags = null;

    this._infoPlistPath = null;
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
}

BundleTask.Platform =   {
                            "ObjJ"      : "ObjJ",
                            "CommonJS"  : "CommonJS",
                            "Browser"   : "Browser"
                        };

BundleTask.PLATFORM_DEFAULT_FLAGS = {
                                        "ObjJ"      : [],
                                        "CommonJS"  : ['-DPLATFORM_RHINO -DPLATFORM_COMMONJS'],
                                        "Browser"   : ['-DPLATFORM_BROWSER', '-DPLATFORM_DOM']
                                    };

BundleTask.prototype.setAuthor = function(anAuthor)
{
    this._author = anAuthor;
}

BundleTask.prototype.author = function()
{
    return this._author;
}

BundleTask.prototype.setEmail = function(anEmail)
{
    this._email = anEmail;
}

BundleTask.prototype.email = function()
{
    return this._email;
}

BundleTask.prototype.setSummary = function(aSummary)
{
    this._summary = aSummary;
}

BundleTask.prototype.summary = function()
{
    return this._summary;
}

BundleTask.prototype.setIdentifier = function(anIdentifier)
{
    this._identifier = anIdentifier;
}

BundleTask.prototype.identifier = function()
{
    return this._identifier;
}

BundleTask.prototype.setVersion = function(aVersion)
{
    this._version = aVersion;
}

BundleTask.prototype.version = function()
{
    return this._version;
}

BundleTask.prototype.setPlatforms = function(platforms)
{
    this._platforms = platforms;
}

BundleTask.prototype.platforms = function()
{
    return this._platforms;
}

BundleTask.prototype.setSources = function(sources)
{
    this._sources = sources;
}

BundleTask.prototype.sources = function()
{
    return this._sources;
}

BundleTask.prototype.setResources = function(resources)
{
    this._resources = resources;
}

BundleTask.prototype.resources = function(resources)
{
    this._resources = resources;
}

BundleTask.prototype.setSpritesResources = function(shouldSpriteResources)
{
    this._spritesResources = shouldSpriteResources;
}

BundleTask.prototype.spritesResources = function()
{
    return this._spritesResources;
}

BundleTask.prototype.setIncludesNibsAndXibs = function(shouldIncludeNibsAndXibs)
{
    this._includesNibsAndXibs = shouldIncludeNibsAndXibs;
}

BundleTask.prototype.includesNibsAndXibs = function()
{
    return this._includesNibsAndXibs;
}

BundleTask.prototype.setProductName = function(aProductName)
{
    this._productName = aProductName;
}

BundleTask.prototype.productName = function()
{
    return this._productName;
}

BundleTask.prototype.setInfoPlistPath = function(anInfoPlistPath)
{
    this._infoPlistPath = anInfoPlistPath;
}

BundleTask.prototype.infoPlistPath = function()
{
    return this._infoPlistPath;
}

BundleTask.prototype.setPrincipalClass = function(aPrincipalClass)
{
    this._principalClass = aPrincipalClass;
}

BundleTask.prototype.principalClass = function()
{
    return this._principalClass;
}

BundleTask.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
}

BundleTask.prototype.compilerFlags = function()
{
    return this._compilerFlags;
}

BundleTask.prototype.setNib2cibFlags = function(flags)
{
    this._nib2cibFlags = flags;
}

BundleTask.prototype.setNib2CibFlags = BundleTask.prototype.setNib2cibFlags;

BundleTask.prototype.nib2cibFlags = function()
{
    return this._nib2cibFlags;
}

BundleTask.prototype.flattensSources = function()
{
    return this._flattensSources;
}

BundleTask.prototype.setFlattensSources = function(/*Boolean*/ shouldFlattenSources)
{
    this._flattensSources = shouldFlattenSources;
}

BundleTask.prototype.setLicense = function(aLicense)
{
    this._license = aLicense;
}

BundleTask.prototype.license = function()
{
    return this._license;
}

BundleTask.prototype.setBuildPath = function(aBuildPath)
{
    this._buildPath = aBuildPath;
}

BundleTask.prototype.buildPath = function()
{
    return this._buildPath;
}

BundleTask.prototype.setBuildIntermediatesPath = function(aBuildPath)
{
    this._buildIntermediatesPath = aBuildPath;
}

BundleTask.prototype.buildIntermediatesPath = function()
{
    return this._buildIntermediatesPath || this.buildPath();
}

BundleTask.prototype.buildProductPath = function()
{
    return FILE.join(this.buildPath(), this.productName());
}

BundleTask.prototype.buildIntermediatesProductPath = function()
{
    return this.buildIntermediatesPath() || FILE.join(this.buildPath(), this.productName() + ".build");
}

BundleTask.prototype.buildProductStaticPathForPlatform = function(aPlatform)
{
    return FILE.join(this.buildProductPath(), aPlatform + ".platform", this.productName() + ".sj");
}

BundleTask.prototype.defineTasks = function()
{
    this.defineResourceTasks();
    this.defineSourceTasks();
    this.defineInfoPlistTask();
    this.defineLicenseTask();
    this.defineStaticTask();

    CLEAN.include(this.buildIntermediatesProductPath());
    CLOBBER.include(this.buildProductPath());
}

BundleTask.prototype.packageType = function()
{
    return 1;
}

BundleTask.prototype.infoPlist = function()
{
    var infoPlistPath = this.infoPlistPath(),
        objj_dictionary = require("objective-j").objj_dictionary;

    if (infoPlistPath)
        var infoPlist = require("objective-j/plist").readPlist(infoPlistPath);
    else
        var infoPlist = new objj_dictionary();

    // FIXME: Should all of these unconditionally overwrite?
    infoPlist.setValue("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValue("CPBundleName", this.productName());
    infoPlist.setValue("CPBundleIdentifier", this.identifier());
    infoPlist.setValue("CPBundleVersion", this.version());
    infoPlist.setValue("CPBundlePackageType", this.packageType());
    infoPlist.setValue("CPBundlePlatforms", this.platforms());
    infoPlist.setValue("CPBundleExecutable", this.productName() + ".sj");

    var principalClass = this.principalClass();

    if (principalClass)
        infoPlist.setValue("CPPrincipalClass", principalClass);

    var replacedFiles = this._replacedFiles,
        replacedFilesDictionary = new objj_dictionary();

    for (var engine in replacedFiles)
        if (replacedFiles.hasOwnProperty(engine))
            replacedFilesDictionary.setValue(engine, replacedFiles[engine]);

    infoPlist.setValue("CPBundleReplacedFiles", replacedFilesDictionary);

    return infoPlist;
}

BundleTask.prototype.defineInfoPlistTask = function()
{
    var infoPlistProductPath = FILE.join(this.buildProductPath(), "Info.plist"),
        bundleTask = this;

    filedir (infoPlistProductPath, function()
    {
        require("objective-j/plist").writePlist(infoPlistProductPath, bundleTask.infoPlist());
    });

    this.enhance([infoPlistProductPath]);
}

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
}

BundleTask.prototype.resourcesPath = function()
{
    return FILE.join(this.buildProductPath(), "Resources", "");
}

var IMAGE_EXTENSIONS =  [ ".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"];

var MIME_TYPES =    {
                        ".png"  : "image/png",
                        ".jpg"  : "image/jpeg",
                        ".jpeg" : "image/jpeg",
                        ".gif"  : "image/gif",
                        ".tif"  : "image/tiff",
                        ".tiff" : "image/tiff"
                    };

BundleTask.prototype.defineResourceTask = function(aResourcePath, aDestinationPath)
{
    var extension = FILE.extension(aResourcePath).toLowerCase(),
        extensionless = aResourcePath.substr(0, aResourcePath.length - extension.length);

    // Don't sprite images larger than 32KB, IE 8 doesn't like it.
    if (this.spritesResources() && IMAGE_EXTENSIONS.indexOf(extension) !== -1 && FILE.size(aResourcePath) < 32768)
    {
        var spritedDestinationPath = FILE.join(this.buildIntermediatesProductPath(), "Browser" + ".platform", "Resources", FILE.relative(this.resourcesPath(), aDestinationPath));

        filedir (spritedDestinationPath, function()
        {
            var dataURI = "data:" + MIME_TYPES[extension] + ";base64," + base64.encode(FILE.read(aResourcePath, { mode : 'b'}));
            FILE.write(spritedDestinationPath, dataURI.length + ";" + dataURI, { charset:"UTF-8" });
        });

        filedir (this.buildProductStaticPathForPlatform("Browser"), [spritedDestinationPath]);
    }

    // NOT:
    // (extname === ".cib" && (FILE.exists(extensionless + '.xib') || FILE.exists(extensionless + '.nib')) ||
    // (extname === ".xib" || extname === ".nib") && !this.shouldIncludeNibsAndXibs())
    if ((extension !== ".cib" || !FILE.exists(extensionless + ".xib") && FILE.exists(extensionless + ".nib")) &&
        ((extension !== ".xib" && extension !== ".nib") || this.includesNibsAndXibs()))
    {
        filedir (aDestinationPath, [aResourcePath], function()
        {
            if (FILE.exists(aDestinationPath))
                rm_rf(aDestinationPath);

            if (FILE.isDirectory(aResourcePath))
                FILE.copyTree(aResourcePath, aDestinationPath);
            else
                FILE.copy(aResourcePath, aDestinationPath);
        });

        this.enhance([aDestinationPath]);
    }

    if (extension === ".xib" || extension === ".nib")
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
}

function directoryInCommon(filenames)
{
    var aCommonDirectory = null;

    filenames.forEach(function(aFilename)
    {
        var directory = FILE.dirname(aFilename);

        if (!aCommonDirectory)
            aCommonDirectory = directory;
        
        else
        {
            var index = 0,
                count = Math.min(directory.length, aFilename.length);
    
            for (; index < count && aCommonDirectory.charAt(index) === directory.charAt(index); ++index) ;
    
            aCommonDirectory = directory.substr(0, index);
        }
    });
print("DIRECTORY IN COMMON IS " + aCommonDirectory);
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
}

BundleTask.prototype.defineStaticTask = function()
{
    this.platforms().forEach(function(/*String*/ aPlatform)
    {
        var sourcesPath = FILE.join(this.buildIntermediatesProductPath(), aPlatform + ".platform", "Sources", ""),
            resourcesPath = FILE.join(this.buildIntermediatesProductPath(), aPlatform + ".platform", "Resources", ""),
            staticPath = this.buildProductStaticPathForPlatform(aPlatform),
            flattensSources = this.flattensSources();

        filedir (staticPath, function(aTask)
        {
            print("Creating static file... " + staticPath);

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

                    fileStream.write("p;" + relativePath.length + ";" + relativePath);
                }

                else if (aFilename.indexOf(resourcesPath) === 0)
                {
                    var resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename);

                    if (IMAGE_EXTENSIONS.indexOf(FILE.extension(aFilename)) !== -1)
                        fileStream.write("u;");
                    else
                        fileStream.write("p;");

                    fileStream.write(resourcePath.length + ";" + resourcePath);
                }

                // FIXME: We need to do this for now due to file.read adding newlines. Revert when fixed.
                //fileStream.write(FILE.read(aFilename, { charset:"UTF-8" }));
                fileStream.write(FILE.read(aFilename, { mode:"b" }).decodeToString("UTF-8"));
            }, this);

            fileStream.close();
        });

        this.enhance([staticPath]);
    }, this);
}

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

    this.platforms().forEach(function(/*String*/ aPlatform)
    {
        var platformSources = sources,
            sourcesPath = FILE.join(this.buildIntermediatesProductPath(), aPlatform + ".platform", "Sources", ""),
            staticPath = this.buildProductStaticPathForPlatform(aPlatform),
            flags = BundleTask.PLATFORM_DEFAULT_FLAGS[aPlatform].join(" ");

        if (!Array.isArray(platformSources) && platformSources.constructor !== Jake.FileList)
            platformSources = platformSources[aPlatform];

        var replacedFiles = [];

        platformSources.forEach(function(/*String*/ aFilename)
        {
            // if this file doesn't exist or isn't a .j file, don't preprocess it.
            if (!FILE.exists(aFilename) || FILE.extension(aFilename) !== '.j')
                return;

            var compiledPlatformSource = FILE.join(sourcesPath, FILE.basename(aFilename));

            filedir (compiledPlatformSource, [aFilename], function()
            {
                print("Compiling " + aFilename + "...");
                FILE.write(compiledPlatformSource, require("objective-j/compiler").compile(aFilename, flags + " " + compilerFlags), { charset:"UTF-8" });
            });

            filedir (staticPath, [compiledPlatformSource]);

            // FIXME: how do we non flatten?
            // dir in common
            replacedFiles.push(flattensSources ? FILE.basename(aFilename) : FILE.relative(sourcesPath, aFilename));
        }, this);

        this._replacedFiles[aPlatform] = replacedFiles;
    }, this);
}

exports.BundleTask = BundleTask;

exports.bundle = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BundleTask.defineTask(aName, aFunction);
}
