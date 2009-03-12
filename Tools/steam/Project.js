
importClass(java.io.FileOutputStream);
importClass(java.io.BufferedWriter);
importClass(java.io.OutputStreamWriter);

function Target(dictionary)
{
    this._name = dictionary_getValue(dictionary, "Name");
    
    var flagsString = dictionary_getValue(dictionary, "Flags");
    
    this._flags = flagsString ? flagsString.split(/\s+/) : [];
    
    this._type = dictionary_getValue(dictionary, "Type");
    
    if (!this._type)
        this._type = "280N.application";
    
    this._exclusions = [];
    
    var exclusions = dictionary_getValue(dictionary, "Excluded");

    if (exclusions)
    {
        var index = 0,
            count = exclusions.length;
    
        for (; index < count; ++index)
            this._exclusions.push(new File((exclusions[index])).getCanonicalFile());
    }
    
    return this;
}

Target.prototype.name = function()
{
    return this._name;
}

Target.prototype.exclusions = function()
{
    return this._exclusions;
}

Target.prototype.flags = function()
{
    return this._flags;
}

Target.prototype.type = function()
{
    return this._type;
}

function Configuration(dictionary)
{
    this._name = dictionary_getValue(dictionary, "Name");
    
    var flagsString = dictionary_getValue(dictionary, "Flags");
    
    this._flags = flagsString ? flagsString.split(/\s+/) : [];
    
    return this;
}

Configuration.prototype.name = function()
{
    return this._name;
}

Configuration.prototype.flags = function()
{
    return this._flags;
}

function Project(/*String*/ aFilePath, /*String*/ aBuildPath)
{
    this._file = new File(aFilePath).getCanonicalFile();
    this._root = this._file.getParentFile();

    // Read the project file (its just a plist).
    this._properties = readPlist(this._file);
    
    this._name = dictionary_getValue(this._properties, "Name");
    
    // Read existing Info.plist if it exists.
    var infoPlist = new File(this._root.getAbsolutePath() + "/Info.plist");
    
    if (infoPlist.exists())
        this._infoDictionary = readPlist(new File(this._root.getAbsolutePath() + "/Info.plist"));
    else
        this._infoDictionary = new objj_dictionary();

    this.buildPath = aBuildPath;

    // Covert target dictionaries to target objects.
    var targetDictionaries = dictionary_getValue(this._properties, "Targets");

    this._targets = [];

    for (var index = 0, count = targetDictionaries.length; index < count; ++index)
        this._targets.push(new Target(targetDictionaries[index]));

    this.setActiveTarget(this._targets[0]);

    // Covert target dictionaries to target objects.
    var configurationDictionaries = dictionary_getValue(this._properties, "Configurations");
    
    this._configurations = [];
    
    for (index = 0, count = configurationDictionaries.length; index < count; ++index)
        this._configurations.push(new Configuration(configurationDictionaries[index]));
        
    this.setActiveConfiguration(this._configurations[0]);

    // Grab the Resources Directory (if it exists)
    this._resources = new File(this._root.getAbsolutePath() + "/Resources/").getCanonicalFile();
    
    return this;
}

Project.prototype.name = function()
{
    return this._name;
}

Project.prototype.targetWithName = function(/*String*/ aName)
{
    var targets = this._targets,
        index = 0,
        count = targets.length;
    
    for (; index < count; ++index)
    {
        var target = targets[index];
        
        if (target.name() == aName)
            return target;
    }
    
    return null;
}

Project.prototype.configurationWithName = function(/*String*/ aName)
{
    var configurations = this._configurations,
        index = 0,
        count = configurations.length;
    
    for (; index < count; ++index)
    {
        var configuration = configurations[index];
        
        if (configuration.name() == aName)
            return configuration;
    }
    
    return null;
}

Project.prototype.setActiveTarget = function(/*Target*/ aTarget)
{
    this._activeTarget = aTarget;
 
    this._buildProducts = null;
    this._buildIntermediates = null;
    this._buildObjects = null;
}

Project.prototype.activeTarget = function()
{
    return this._activeTarget;
}

Project.prototype.setActiveConfiguration = function(/*Configuration*/ aConfiguration)
{
    this._activeConfiguration = aConfiguration;
    
    this._buildProducts = null;
    this._buildIntermediates = null;
    this._buildObjects = null;
}

Project.prototype.activeConfiguration = function()
{
    return this._activeConfiguration;
}

Project.prototype.buildProducts = function()
{
    if (!this._buildProducts)
    {
        this._buildProducts = new File(this.buildPath + '/' + this._activeConfiguration.name() + '/' + this._activeTarget.name()).getCanonicalFile();
        this._buildProducts.mkdirs();
    }
    
    return this._buildProducts;
}

Project.prototype.buildIntermediates = function()
{
    if (!this._buildIntermediates)
    {
        this._buildIntermediates = new File(this.buildPath + '/' + this._activeTarget.name() + ".build/" + this._activeConfiguration.name()).getCanonicalFile();
        this._buildIntermediates.mkdirs();    
    }
    
    return this._buildIntermediates;
}

Project.prototype.buildObjects = function()
{
    if (!this._buildObjects)
    {
        this._buildObjects = new File(this.buildIntermediates().getAbsolutePath() + '/' + this._activeTarget.name()).getCanonicalFile();
        this._buildObjects.mkdirs();
    }
    
    return this._buildObjects;
}

Project.prototype.activeFlags = function()
{
    return this.activeTarget().flags().concat(this.activeConfiguration().flags());
}

Project.prototype.build = function()
{
    java.lang.System.out.println("Building Target \"" + this.activeTarget().name() + 
        "\" of Project \"" + this.name() + 
        "\" with Configuration \"" + this.activeConfiguration().name() + "\".");

    var jFiles = getFiles(this._root, "j", this._activeTarget.exclusions()),
        replacedFiles = [];
        hasModifiedJFiles = false;
        shouldObjjPreprocess = true,
        shouldGzip = this._gzip,
        objjcComponents = ["sh", OBJJ_HOME + "/bin/objjc"];
    
    objjcComponents = objjcComponents.concat(this.activeFlags());
    
    if (!shouldObjjPreprocess)
        objjcComponents.push("-E");
        
    var buildObjects = this.buildObjects(),
        buildProducts = this.buildProducts();
    
    for (index = 0, count = jFiles.length; index < count; ++index)
    {
        var file = jFiles[index],
            builtFile = new File(buildObjects.getAbsolutePath() + '/' + getFileNameWithoutExtension(file) + '.o');
        
        replacedFiles.push(file.getName() + "");
        
        if (builtFile.exists() && file.lastModified() < builtFile.lastModified())
            continue;
        else
            hasModifiedJFiles = true;
        
        objjcComponents.push(file.getAbsolutePath());
        
        objjcComponents.push("-o");
        objjcComponents.push(buildObjects.getAbsolutePath() + '/' + getFileNameWithoutExtension(file) + '.o');
    }
    
    exec(objjcComponents, true);
    
    var oFiles = getFiles(buildObjects, 'o'),
        sjFile = new File(buildProducts.getCanonicalPath() + '/' + this._activeTarget.name() + ".sj");
            
    if (hasModifiedJFiles)
    {
        // concatenate sjheader.txt and individual .o
        exec(["sh", "-c", "cat '" + OBJJ_STEAM + "/sjheader.txt' '" + oFiles.join("' '") + "' > '" + sjFile.getCanonicalPath() + "'"], true);
    }
    
    if (shouldGzip)
    {
        // gzip and copy .htaccess file
        exec(["sh", "-c", "gzip -c '" + sjFile.getCanonicalPath() + "' > '" + sjFile.getCanonicalPath() + ".gz'"], true);
        exec(["cp", OBJJ_HOME + "/lib/htaccess", sjFile.getParentFile().getCanonicalPath() + "/.htaccess"], true);
    }
    else
    {
        // remove gzip and .htaccess file if present
        exec(["rm", "-f", sjFile.getParentFile().getCanonicalPath() + "/.htaccess", sjFile.getCanonicalPath() + ".gz"], true);
    }
    
    dictionary_setValue(this._infoDictionary, "CPBundleExecutable", this._activeTarget.name() + ".sj");
    dictionary_setValue(this._infoDictionary, "CPBundleReplacedFiles", replacedFiles);
    
    this.writeInfoPlist();
    
    this.copyResources();
    
    // FIXME: This should be, if this is an app...
    if (dictionary_getValue(this._infoDictionary, "CPBundlePackageType") == "280N")
        this.copyIndexFile();
        
}

Project.prototype.clean = function()
{
    java.lang.System.out.println("Cleaning Target \"" + this.activeTarget().name() + 
        "\" of Project \"" + this.name() + 
        "\" with Configuration \"" + this.activeConfiguration().name() + "\".");
        
    exec(["rm", "-rf", this.buildIntermediates().getAbsolutePath()], true);
    exec(["rm", "-rf", this.buildProducts().getAbsolutePath()], true);
}

Project.prototype.copyIndexFile = function()
{
    var indexFile = new File(this._root.getAbsolutePath() + "/index.html").getCanonicalFile();
    
    rsync(indexFile, this.buildProducts());
}

Project.prototype.writeInfoPlist = function()
{
    var writer = new BufferedWriter(new FileWriter(this.buildProducts().getAbsolutePath() + '/' + "Info.plist"));

    writer.write(CPPropertyListCreateXMLData(this._infoDictionary).string);

    writer.close();
}

Project.prototype.copyResources = function()
{
    rsync(this._resources, this.buildProducts());
}
