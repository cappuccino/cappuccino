
var FILE = require("file"),
    OS = require("os"),
    Jake = require("jake"),
    objj = require("objj/objj"),
    objjc = require("objj/objjc"),
    plist = require("objj/plist");

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

    this._productName = this.name();
    
    this._buildIntermediatesPath = null;
    this._buildPath = FILE.cwd();

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
                            "Rhino"     : "Rhino",
                            "Browser"   : "Browser"
                        };

BundleTask.PLATFORM_DIRECTORIES =   {
                                        "ObjJ"      : "objj.platform",
                                        "Rhino"     : "rhino.platform",
                                        "Browser"   : "browser.platform"
                                    };

BundleTask.PLATFORM_DEFAULT_FLAGS = {
                                        "ObjJ"      : [],
                                        "Rhino"     : ['-DPLATFORM_RHINO'],
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
    return FILE.join(this.buildProductPath(), BundleTask.PLATFORM_DIRECTORIES[aPlatform], this.productName() + ".sj");
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
    var infoPlist = new objj.objj_dictionary();
    //util = require("util"),
    infoPlist.setValue("CPBundleInfoDictionaryVersion", 6.0);
    infoPlist.setValue("CPBundleName", this.productName());
    infoPlist.setValue("CPBundleIdentifier", this.identifier());
    infoPlist.setValue("CPBundleVersion", this.version());
    infoPlist.setValue("CPBundlePackageType", this.packageType());

    return infoPlist;
/*
    info_plist_path = File.join(build_path, 'Info.plist')
    new_info_plist = { 'CPBundleName' => name, 'CPBundleIdentifier' => identifier, 'CPBundleInfoDictionaryVersion' => 6.0, 'CPBundleVersion' => version, 'CPBundlePackageType' => Bundle::Type.code_string(type) }
    
    new_info_plist['CPBundlePlatforms'] = platforms;

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
print(LICENSE_PATHS.LGPL_v2_1);
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
    var extname = FILE.extname(aResourcePath);

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
            FILE.glob(aPath + "/**/*").forEach(function(aSubresourcePath)
            {
                this.defineResourceTask(resourcePath, FILE.join(resourcesPath, aSubresourcePath.substring(aSubresourcePath.length - baselength)));
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
        var staticPath = this.buildProductStaticPathForPlatform(aPlatform);

        filedir (staticPath, function(aTask)
        {
            print("Creating static file...");

            // No newline!
            OS.system("echo -n \"@STATIC;1.0;\" > " + staticPath);

            aTask.prerequisites().forEach(function(aFilename)
            {
                // Our prerequisites will contain directories due to filedir.
                if (FILE.isFile(aFilename))
                    OS.system("cat " + aFilename + " >> " + staticPath);
            }, this);
        });

        this.enhance([staticPath]);
    }, this);
}

BundleTask.prototype.defineSourceTasks = function()
{
    var sources = this.sources();

    if (!sources)
        return;

    this.platforms().forEach(function(/*String*/ aPlatform)
    {
        var platformSources = sources,
            platformBuildIntermediatesPath = FILE.join(this.buildIntermediatesProductPath(), BundleTask.PLATFORM_DIRECTORIES[aPlatform]),
            staticPath = this.buildProductStaticPathForPlatform(aPlatform);

        if (!Array.isArray(platformSources))
            platformSources = platformSources[aPlatform];

        platformSources.forEach(function(/*String*/ aFilename)
        {
            // if this file doesn't exist or isn't a .j file, don't preprocess it.
            if (!FILE.exists(aFilename) || FILE.extname(aFilename) !== '.j')
                return;

            var compiledPlatformSource = FILE.join(platformBuildIntermediatesPath, FILE.basename(aFilename));

            filedir (compiledPlatformSource, [aFilename], function()
            {
                objjc.preprocess(aFilename, compiledPlatformSource);
            });

            filedir (staticPath, [compiledPlatformSource]);

        }, this);
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
