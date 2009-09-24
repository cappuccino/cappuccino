
var FILE = require("file"),
    OS = require("os"),
    Jake = require("jake"),
    objj_dictionary = require("objective-j").objj_dictionary,
    compiler = require("objective-j/compiler"),
    plist = require("objective-j/plist");

var Task = Jake.Task,
    filedir = Jake.filedir;

exports.bundle = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BundleTask.defineTask(aName, aFunction);
}

function BundleTask(aName, anApplication)
{
    Task.apply(this, arguments);

    this._license = null;
    this._platforms = [BundleTask.Platform.ObjJ];
    this._sources = null;
    this._resources = null;
    this._identifier = null;
    this._version = 0.1;

    this._compilerFlags = null;
    this._flattensSources = false;

    this._productName = this.name();
    
    this._buildIntermediatesPath = null;
    this._buildPath = FILE.cwd();

    this._replacedFiles = new objj_dictionary();

//    this._nib2cibFlags = [];
//   this.shouldnib
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

/*
        required_attribute :name
        required_attribute :version

        required_attribute :summary
        required_attribute :identifier
        required_attribute :include_nibs, false
        required_attribute :nib2cib_flags, []
        required_attribute :platforms, [Platform::ObjJ]
        required_attribute :type, Bundle::Type::Application
        
        # ------------------------- OPTIONAL gemspec attributes.
        
        attributes :email, :homepage, :github_project, :description, :license_file, :license
        attributes :build_path, :intermediates_path
        attribute :principal_class
        attribute :index_file
        attribute :info_plist
        #    attributes :autorequire, :default_executable
        #    attribute :platform,               Gem::Platform::RUBY
        
        array_attribute :authors
        attributes :sources
        array_attribute :resources
        array_attribute :flags
        #    array_attribute :test_files
        #    array_attribute :executables
        #    array_attribute :extensions
        #    array_attribute :requirements
        #    array_attribute :dependencies
        
        #read_only :dependencies
        
        # ------------------------- ALIASED gemspec attributes.
        
        #    attribute_alias_singular :executable,   :executables
        attribute_alias_singular :author, :authors
        attribute_alias_singular :flag, :flags
        attribute_alias_singular :nib2cib_flag, :nib2cib_flags
        attribute_alias_singular :platform, :platforms
        #    attribute_alias_singular :require_path, :require_paths
        #    attribute_alias_singular :test_file,    :test_files
        
        # ------------------------- RUNTIME attributes (not persisted).
        
        attr_writer :loaded
        attr_accessor :loaded_from
        

    this._sources = 
}
*/

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
        
/*
if type == Bundle::Type::Application and index_file

                index_file_path = File.join(build_path, File.basename(index_file))

                file_d index_file_path => [index_file] do |t|
                    cp(index_file, t.name)
                end

                enhance([index_file_path])

                frameworks_path = File.join(build_path, 'Frameworks')

                file_d frameworks_path do
                    IO.popen("capp gen -f " + build_path) do |capp|
                        capp.sync = true

                        while str = capp.gets
                            puts str
                        end
                    end
                    rake abort if ($? != 0)
                end

                enhance([frameworks_path])
            end

*/

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

BundleTask.prototype.setProductName = function(aProductName)
{
    this._productName = aName;
}

BundleTask.prototype.productName = function()
{
    return this._productName;
}

BundleTask.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
}

BundleTask.prototype.compilerFlags = function()
{
    return this._compilerFlags;
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
//    CLOBBER.include(build_path)
}

BundleTask.prototype.packageType = function()
{
    return 1;
}

BundleTask.prototype.infoPlist = function()
{
    var infoPlist = new objj_dictionary();
    //util = require("util"),
    infoPlist.setValue("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValue("CPBundleName", this.productName());
    infoPlist.setValue("CPBundleIdentifier", this.identifier());
    infoPlist.setValue("CPBundleVersion", this.version());
    infoPlist.setValue("CPBundlePackageType", this.packageType());
    infoPlist.setValue("CPBundleReplacedFiles", this._replacedFiles);
    infoPlist.setValue("CPBundlePlatforms", this.platforms());
    infoPlist.setValue("CPBundleExecutable", this.productName() + ".sj");

    return infoPlist;
/*

    if info_plist
        existing_info_plist = Plist::parse_xml(info_plist)
        new_info_plist = new_info_plist.merge existing_info_plist
        file_d info_plist_path => [info_plist]
    end

    if principal_class
        new_info_plist['CPPrincipalClass'] = principal_class
    end*/
}

BundleTask.prototype.defineInfoPlistTask = function()
{
    var infoPlistProductPath = FILE.join(this.buildProductPath(), "Info.plist"),
        bundleTask = this;

    filedir (infoPlistProductPath, function()
    {
        plist.writePlist(infoPlistProductPath, bundleTask.infoPlist());
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
/*
BundleTask.prototype.compact = function(path, *patterns)
{
            puts 'Compacting ' + path
            
            info_plist_path = File.join(path, 'Info.plist')
            existing_info_plist = Plist::parse_xml(info_plist_path)
            
            absolute_path = File.expand_path(path) + '/'

            patterns = patterns.map { |pattern| "#{path}/#{pattern}" }
            
            bundle_name = existing_info_plist['CPBundleName']
            replaced_files = []

            FileList.new(File.join(path, '**', '*.platform')).each do |platform|
            
                FileList.new(File.join(platform, '*.j')) do |list|
                    
                    list.include(*patterns)
                    
                    executable_path = File.join(platform, bundle_name) + '.sj'
                    platform_absolute_path = File.expand_path(platform) + '/'
                    
                    File.open(executable_path, 'w+') do |executable|
                    
                        executable.write '@STATIC;1.0;'
                        
                        list.each do |fileName|
                        
                            fileName = File.expand_path(fileName)

                            File.open(fileName) do |file|
                            
                                if fileName.index(platform_absolute_path) == 0
                                    fileName = File.expand_path(fileName)[platform_absolute_path.length..-1]
                                else
                                    fileName = File.expand_path(fileName)[absolute_path.length..-1]
                                end
                                
                                executable.write "p;#{fileName.length};#{fileName}#{file.read}"
                                
                                replaced_files << fileName
                            end
                        end
                    end                    
                end
            end

            existing_info_plist['CPBundleReplacedFiles'] = replaced_files.uniq
            existing_info_plist['CPBundleExecutable'] = bundle_name + '.sj'
            
            File.open(info_plist_path, 'w') do |file|
                file.puts existing_info_plist.to_plist
            end
            
        end
}
*/
BundleTask.prototype.resourcesPath = function()
{
    return FILE.join(this.buildProductPath(), "Resources");
}

BundleTask.prototype.defineResourceTask = function(aResourcePath, aDestinationPath)
{
    var extname = FILE.extension(aResourcePath);

    // NOT:
    // (extname === ".cib" && (FILE.exists(extensionless + '.xib') || FILE.exists(extensionless + '.nib')) ||
    // (extname === ".xib" || extname === ".nib") && !this.shouldIncludeNibsAndXibs())
    if ((extname !== ".cib" || !FILE.exists(extensionsless + ".xib") && FILE.exists(extensionless + ".nib")) &&
        ((extname !== ".xib" && extname !== ".nib") || this.shouldIncludeNibsAndXibs()))
    {
        filedir (aDestinationPath, [aResourcePath], function()
        {
            cp_r(aResourcePath, aDestinationPath);
        });

        this.enhance([aDestinationPath]);
    }

    if (extname === ".xib" || extname === ".nib")
    {
        aDestinationPath = FILE.join(FILE.dirname(aDestinationPath), FILE.basename(aDestinationPath, extname)) + ".cib";

        filedir (aDestinationPath, [aResourcePath], function()
        {
            OS.system("nib2cib " + aResourcePath + " "  + aCopiedResource + " " + (this._nib2cibFlags || ""));
        });

        this.enhance([aDestinationPath]);
    }
}

BundleTask.prototype.defineResourceTasks = function()
{
    if (!this.resources)
        return;

    var resourcesPath = this.resourcesPath();

    this._resources.forEach(function(aResourcePath)
    {
        var baselength = FILE.basename(aResourcePath).length;

        if (FILE.isDirectory(aResourcePath))
        {
            FILE.glob(aResourcePath + "/**").forEach(function(aSubresourcePath)
            {
                this.defineResourceTask(aSubresourcePath, FILE.join(resourcesPath, aSubresourcePath.substring(aResourcePath.length - baselength)));
            }, this);
        }
        else
        {
            this.defineResourceTask(aResourcePath, FILE.join(resourcesPath, FILE.basename(aResourcePath)));
        }
    }, this);
}

BundleTask.prototype.defineStaticTask = function()
{
    this.platforms().forEach(function(/*String*/ aPlatform)
    {
        var sourcesPath = FILE.join(this.buildIntermediatesProductPath(), aPlatform + ".platform", ""),
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
                if (FILE.isFile(aFilename))
                {
                    var relativePath = flattensSources ? FILE.basename(aFilename) : FILE.relative(sourcesPath, aFilename);

                    // FIXME: We need to do this for now due to file.read adding newlines. Revert when fixed.
                    fileStream.write("p;" + relativePath.length + ";" + relativePath);
                    fileStream.write(FILE.read(aFilename, { mode:"b" }).decodeToString("UTF-8"));
                }
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
            sourcesPath = FILE.join(this.buildIntermediatesProductPath(), aPlatform + ".platform", ""),
            staticPath = this.buildProductStaticPathForPlatform(aPlatform),
            flags = BundleTask.PLATFORM_DEFAULT_FLAGS[aPlatform].join(" ");

        if (!Array.isArray(platformSources))
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
                FILE.write(compiledPlatformSource, compiler.compile(aFilename, flags + " " + compilerFlags), { charset:"UTF-8" });
            });

            filedir (staticPath, [compiledPlatformSource]);

            replacedFiles.push(flattensSources ? FILE.basename(aFilename) : FILE.relative(sourcesPath, aFilename));
        }, this);

        this._replacedFiles.setValue(aPlatform, replacedFiles);
    }, this);
/*
                    list.each do |fileName|
                    
                        fileName = File.expand_path(fileName)

                        File.open(fileName) do |file|
                        
                            if fileName.index(platform_absolute_path) == 0
                                fileName = File.expand_path(fileName)[platform_absolute_path.length..-1]
                            else
                                fileName = File.expand_path(fileName)[absolute_path.length..-1]
                            end
                            
                            executable.write "p;#{fileName.length};#{fileName}#{file.read}"
                            
                            replaced_files << fileName
                        end
                    end

        existing_info_plist['CPBundleReplacedFiles'] = replaced_files.uniq
        existing_info_plist['CPBundleExecutable'] = bundle_name + '.sj'

    });
});*/
}

exports.BundleTask = BundleTask;
