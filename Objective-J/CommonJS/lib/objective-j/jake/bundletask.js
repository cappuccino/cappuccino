
var FILE = require("file"),
    OS = require("os"),
    UTIL = require("util"),
    TERM = require("term"),
    Jake = require("jake"),
    CLEAN = require("jake/clean").CLEAN,
    CLOBBER = require("jake/clean").CLOBBER,
    base64 = require("base64"),
    environment = require("objective-j/jake/environment");

var Task = Jake.Task,
    filedir = Jake.filedir;

function isImage(/*String*/ aFilename)
{
    return  FILE.isFile(aFilename) &&
            UTIL.has([".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff"], FILE.extension(aFilename).toLowerCase());
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

    this.setEnvironments([environment.Browsers, environment.CommonJS]);

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
}

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

    this._flattenedEnvironments = environment.Environment.flattenedEnvironments(this._environments);
}

BundleTask.prototype.environments = function()
{
    return this._environments;
}

BundleTask.prototype.flattenedEnvironments = function()
{
    return this._flattenedEnvironments;
}

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

BundleTask.prototype.setSources = function(sources, environments)
{
    if (!environments)
        this._sources = sources;
    else
    {
        if (Array.isArray(environments))
            environments = environment.Environment.flattenedEnvironments(environments);
        else
            environments = environments.flattenedEnvironments();

        if (!this._sources)
            this._sources = { };

        environments.forEach(function(anEnvironment)
        {
            this._sources[anEnvironment] = sources;
        }, this);
    }
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

BundleTask.prototype.buildProductStaticPathForEnvironment = function(anEnvironment)
{
    return FILE.join(this.buildProductPath(), anEnvironment.name() + ".environment", this.productName() + ".sj");
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

    if (infoPlistPath && FILE.exists(infoPlistPath))
        var infoPlist = require("objective-j/plist").readPlist(infoPlistPath);
    else
        var infoPlist = new objj_dictionary();

    // FIXME: Should all of these unconditionally overwrite?
    infoPlist.setValue("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValue("CPBundleName", this.productName());
    infoPlist.setValue("CPBundleIdentifier", this.identifier());
    infoPlist.setValue("CPBundleVersion", this.version());
    infoPlist.setValue("CPBundlePackageType", this.packageType());
    infoPlist.setValue("CPBundleEnvironments", this.flattenedEnvironments().map(function(anEnvironment)
    {
        return anEnvironment.name();
    }));
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

    var infoPlistPath = this.infoPlistPath();

    if (infoPlistPath && FILE.exists(infoPlistPath))
        filedir (infoPlistProductPath, [infoPlistPath]);

    // FIXME: ? We do this because adding a .j file should cause Info.plist to be updated.
    // Any better way to handle this? Perhaps this should happen unconditionally.
    this.flattenedEnvironments().forEach(function(/*Environment*/ anEnvironment)
    {
        if (!anEnvironment.spritesImages())
            return;

        filedir (infoPlistProductPath, this.buildProductStaticPathForEnvironment(anEnvironment));
    }, this);

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

BundleTask.prototype.defineResourceTask = function(aResourcePath, aDestinationPath)
{
    // Don't sprite images larger than 32KB, IE 8 doesn't like it.
    if (this.spritesResources() && isImage(aResourcePath) && FILE.size(aResourcePath) < 32768)
    {
        this.flattenedEnvironments().forEach(function(/*Environment*/ anEnvironment)
        {
            if (!anEnvironment.spritesImages())
                return;

            var folder = anEnvironment.name() + ".environment",
                spritedDestinationPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Resources", FILE.relative(this.resourcesPath(), aDestinationPath));

            filedir (spritedDestinationPath, function()
            {
                FILE.write(spritedDestinationPath, base64.encode(FILE.read(aResourcePath, { mode : 'b'})), { charset:"UTF-8" });
            });

            // Add this as a dependency unconditionally because we need to set up the URL map either way.
            filedir (this.buildProductStaticPathForEnvironment(anEnvironment), [spritedDestinationPath]);
        }, this);
    }

    var extension = FILE.extension(aResourcePath),
        extensionless = aResourcePath.substr(0, aResourcePath.length - extension.length);
    // NOT:
    // (extname === ".cib" && (FILE.exists(extensionless + '.xib') || FILE.exists(extensionless + '.nib')) ||
    // (extname === ".xib" || extname === ".nib") && !this.shouldIncludeNibsAndXibs())
    if ((extension !== ".cib" || !FILE.exists(extensionless + ".xib") && !FILE.exists(extensionless + ".nib")) &&
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
}

BundleTask.prototype.defineStaticTask = function()
{
    this.flattenedEnvironments().forEach(function(/*Environment*/ anEnvironment)
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

            var fileStream = FILE.open(staticPath, "w+", { charset:"UTF-8" }),
                MHTMLContents = "";

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

                    // FIXME: We need to do this for now due to file.read adding newlines. Revert when fixed.
                    //fileStream.write(FILE.read(aFilename, { charset:"UTF-8" }));
                    fileStream.write(FILE.read(aFilename, { mode:"b" }).decodeToString("UTF-8"));
                }

                else if (aFilename.indexOf(resourcesPath) === 0)
                {
                    var contents = "",
                        resourcePath = "Resources/" + FILE.relative(resourcesPath, aFilename);

                    if (isImage(aFilename))
                    {
                        fileStream.write("u;");

                        if (anEnvironment.spritesImagesAsDataURLs())
                            contents = "data:" + mimeType(aFilename) + ";base64," + FILE.read(aFilename, { charset:"UTF-8" });

                        else if (anEnvironment.spritesImagesAsMHTML())
                        {
                            contents = "mhtml:" + FILE.join(folder, productName + ".sj!") + resourcePath;

                            if (!MHTMLContents.length)
                                MHTMLContents = "/*\r\nContent-Type: multipart/related; boundary=\"_ANY_STRING_WILL_DO_AS_A_SEPARATOR\"\r\n\r\n";

                            MHTMLContents += "--_ANY_STRING_WILL_DO_AS_A_SEPARATOR\r\n";
                            MHTMLContents += "Content-Location:" + resourcePath + "\r\nContent-Transfer-Encoding:base64\r\n\r\n";
                            MHTMLContents += FILE.read(aFilename, { charset:"UTF-8" });
                            MHTMLContents += "\r\n";
                        }

                        contents = contents.length + ";" + contents;
                    }
                    else
                    {
                        fileStream.write("p;");

                        contents = FILE.read(aFilename, { charset:"UTF-8" });
                    }

                    fileStream.write(resourcePath.length + ";" + resourcePath + contents);
                }
            }, this);

            fileStream.write("e;");

            if (MHTMLContents.length > 0)
                fileStream.write(MHTMLContents + "*/");

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

    var environments = this.flattenedEnvironments(),
        flattensSources = this.flattensSources();

    environments.forEach(function(/*Environment*/ anEnvironment)
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
            basePathLength = basePath.length;

        environmentSources.forEach(function(/*String*/ aFilename)
        {
            // if this file doesn't exist or isn't a .j file, don't preprocess it.
            if (!FILE.exists(aFilename) || FILE.extension(aFilename) !== '.j')
                return;

            var relativePath = aFilename.substring(basePathLength ? basePathLength + 1 : basePathLength),
                compiledEnvironmentSource = FILE.join(sourcesPath, relativePath);

            filedir (compiledEnvironmentSource, [aFilename], function()
            {
                TERM.stream.write("Compiling [\0blue(" + anEnvironment + "\0)] \0purple(" + aFilename + "\0)").flush();
                var compiled = require("objective-j/compiler").compile(aFilename, environmentCompilerFlags);
                TERM.stream.print(Array(Math.round(compiled.length / 1024) + 3).join("."));
                FILE.write(compiledEnvironmentSource, compiled, { charset:"UTF-8" });
            });

            filedir (staticPath, [compiledEnvironmentSource]);

            replacedFiles.push(flattensSources ? FILE.basename(aFilename) : relativePath);
        }, this);

        this._replacedFiles[anEnvironment] = replacedFiles;
    }, this);
}

exports.BundleTask = BundleTask;

exports.bundle = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BundleTask.defineTask(aName, aFunction);
}
