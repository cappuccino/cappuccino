function build()
{
    var index = 0,
        count = arguments.length,
        
        actions             = [],
        
        targetName          = null,
        configurationName   = null,
        
        buildPath           = null,
        projectFilePath     = null,
        
        gzip                = false;

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
                            
            case "--gzip":  gzip = true;
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

    project._gzip = gzip;
    
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
