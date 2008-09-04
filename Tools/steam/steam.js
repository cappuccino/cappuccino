
importPackage(java.lang);
importPackage(java.util);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);
importClass(java.io.SequenceInputStream);


function Target(dictionary)
{
    this._name = dictionary_getValue(dictionary, "name");
    
    this._exclusions = [];
    
    var exclusions = dictionary_getValue(dictionary, "Excluded");

    if (exclusions)
    {
        var index = 0,
            count = exclusions.length;
    
        for (; index < count; ++index)
        {
            var file = new File(exclusions[index]).getCanonicalFile();
            
            if (file.isDirectory())
            {
                var files = getFiles(file);
                
                if (files.length)
                   this._exclusions = this._exclusions.concat(files);
            }
            else
                this._exclusions.push(file);
        }
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

function Configuration(dictionary)
{
    this._name = dictionary_getValue(dictionary, "name");
    
    return this;
}

Configuration.prototype.name = function()
{
    return this._name;
}

function Project(/*String*/ aFilePath, /*String*/ aBuildPath)
{
    this._file = new File(aFilePath).getCanonicalFile();
    this._root = this._file.getParentFile();

    // Read the project file (its just a plist).
    this._properties = readPlist(this._file);
    
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
    
    for (index = 0, count = targetDictionaries.length; index < count; ++index)
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

Project.prototype.setActiveConfiguration = function(/*Configuration*/ aConfiguration)
{
    this._activeConfiguration = aConfiguration;
    
    this._buildProducts = null;
    this._buildIntermediates = null;
    this._buildObjects = null;
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

Project.prototype.build = function()
{
    var jFiles = getFiles(this._root, "j", this._activeTarget.exclusions()),
        replacedFiles = [];
        hasModifiedJFiles = false;
        shouldObjjPreprocess = true,
        objjcComponents = ["objjc"];
    
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
    
    if (hasModifiedJFiles)
    {
        var oFiles = getFiles(buildObjects, 'o'),
            sjFile = new File(buildProducts.getCanonicalPath() + '/' + this._activeTarget.name() + ".sj"),
            
            catComponents = [OBJJ_HOME + "/lib/cat", OBJJ_HOME + "/lib/sjheader.txt"];
    
        for (index = 0, count = oFiles.length; index < count; ++index)
            catComponents.push(oFiles[index].getCanonicalPath());
            
        catComponents.push("-o");
        catComponents.push(sjFile.getCanonicalPath());
    
        exec(catComponents);
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
    exec(["rm", "-rf", this.buildIntermediates().getAbsolutePath()], true);
    exec(["rm", "-rf", this.buildProducts().getAbsolutePath()], true);
}

Project.prototype.copyIndexFile = function()
{
    var indexFile = new File(this._root.getAbsolutePath() + "/index.html").getCanonicalFile();
    
    if (indexFile.exists())
        exec(["rsync", "-avz", indexFile.getAbsolutePath(), this.buildProducts().getAbsolutePath()]);
}

Project.prototype.writeInfoPlist = function()
{
    var writer = new BufferedWriter(new FileWriter(this.buildProducts().getAbsolutePath() + '/' + "Info.plist"));

    writer.write(CPPropertyListCreateXMLData(this._infoDictionary).string);

    writer.close();
}

Project.prototype.copyResources = function()
{
    if (this._resources.exists())
        exec(["rsync", "-avz", this._resources.getAbsolutePath() + '/', this.buildProducts().getAbsolutePath() + "/Resources"]);
}

function main()
{
    var index = 0,
        count = arguments.length,
        
        actions             = [],
        
        targetName          = null,
        configurationName   = null,
        
        buildPath           = null,
        projectFilePath     = null;
    
    for (; index < count; ++index)
    {   
        switch (arguments[index])
        {
            case "-f":      if (index + 1 == count)
                                throw "-f needs project file.";
                            
                            projectFilePath = arguments[++index];
                            break;
            
            case "-t":      if (index + 1 == count)
                                throw "-t needs a target";
                            
                            targetName = arguments[++index];
                            break;
                        
            case "-c":      if (index + 1 == count)
                                throw "-c needs configuration";
                        
                            configurationName = arguments[++index];
                            break;
                        
            case "-b":      if (index + 1 == count)
                                throw "-b needs a build location";
                            
                            buildPath = arguments[++index];
                            break;
                        
            case "clean":   
            case "build":   actions.push(arguments[index]);
                            break;
        }
    }
    
    // If no project file was specified, look for one.
    if (!projectFilePath)
    {
        var candidates = getFiles(new File('.'), "steam");
        
        if (candidates.length < 1)
            throw "No project file specified or found.";
        
        projectFilePath = candidates[0];
    }

    // Construct the Build Directory
    if (!buildPath)
    {
        buildPath = System.getenv("STEAM_BUILD");
        
        if (!buildPath)
            buildPath = "Build";
    }
    
    var project = new Project(projectFilePath, buildPath);
    
    if (targetName)
    {
        var target = project.targetWithName(targetName);
        
        if (!target)
            throw "Target \"" + targetName + "\" not found in project.";
    
        project.setActiveTarget(target);
    }
    
    if (configurationName)
    {
        var configuration = project.configurationWithName(configurationName);
        
        if (!configuration)
            throw "Configuration \"" + configurationName + "\" not found in project.";
            
        project.setActiveConfiguration(configuration);
    }
    
    if (!actions.length)
        actions.push("build");
    
    for (index = 0, count = actions.length; index < count; ++index)
        project[actions[index]]();
}

function fileArrayContainsFile(/*Array*/ files, /*File*/ aFile)
{
    var index = 0,
        count = files.length;
        
    for (; index < count; ++index)
        if (files[index].equals(aFile))
            return true;
    
    return false;
}

function getFiles(/*File*/ sourceDirectory, /*String*/ extension, /*Array*/ exclusions)
{
    var matches = [],
        files = sourceDirectory.listFiles();
    
    if (files)
    {
        var index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index].getCanonicalFile(),
                name = String(file.getName());
            
            if ((!extension || name.substring(name.length - extension.length - 1) == ("." + extension)) && (!exclusions || !fileArrayContainsFile(exclusions, file)))
                matches.push(file);
            
            if (file.isDirectory())
                matches = matches.concat(getFiles(file, extension, exclusions));
        }
    }
    
    return matches;
}

function readPlist(/*File*/ aFile)
{
    var reader = new BufferedReader(new FileReader(aFile)),
        fileContents = "";
    
    // Get contents of the file
    while (reader.ready())
        fileContents += reader.readLine() + '\n';
        
    reader.close();

    var data = new objj_data();
    data.string = fileContents;

    return new CPPropertyListCreateFromData(data);
}

function exec(/*Array*/ command, /*Boolean*/ showOutput)
{
    var line = "",
        output = "",
        
        process = Packages.java.lang.Runtime.getRuntime().exec(command),//jsArrayToJavaArray(command));
        reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getInputStream()));
    
    while (line = reader.readLine())
    {
        if (showOutput)
            System.out.println(line);
        
        output += line + '\n';
    }
    
    reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getErrorStream()));
    
    while (line = reader.readLine())
        System.out.println(line);

    try
    {
        if (process.waitFor() != 0)
            System.err.println("exit value = " + process.exitValue());
    }
    catch (anException)
    {
        System.err.println(anException);
    }
    
    return output;
}

function getFileName(aPath)
{
    var index = aPath.lastIndexOf('/');
    
    if (index == -1)
        return aPath;
    
    return aPath.substr(index + 1); 
}

function getFileNameWithoutExtension(aFile)
{
    var name = aFile.getName(),
        index = name.lastIndexOf('.');
    
    if (index == -1 || index == 0)
        return name;
    
    return name.substr(0, index); 
}

function getFileExtension(aPath)
{
    var slash = aPath.lastIndexOf('/'),
        period = aPath.lastIndexOf('.');
    
    if (period < slash || (period == slash + 1))
        return "";
    
    return aPath.substr(period + 1);
}

main.apply(main, arguments);
