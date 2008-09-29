import <Foundation/Foundation.j>
importPackage(Packages.java.io);

var options = {
    base            : "trunk",
    clean           : false,
    deploy          : false,
    deployHost      : null,
    deployPath      : null,
    skipUpdate      : false,
    tag             : false,
    archive         : false,
    message         : null,
    templatePath    : OBJJ_HOME + "/lib/bake_template.html"
}

var targetPath,
    checkoutsPath,
    buildsPath,
    productsPath,
    version = Math.round(new Date().getTime() / 1000);

CPLogRegister(CPLogPrint);

function readConfig(configFile)
{
    var fileData = String(readFile(configFile));
    if (!fileData)
        throw new Error("Couldn't read file: " + configFile);
        
    var configs = CPJSObjectCreateWithJSON(fileData);
    
    return configs;
}

function update()
{
    for (var i = 0; i < options.sources.length; i++)
    {
        var source = options.sources[i];
        
        source.localSourcePath = checkoutsPath + "/" + source.path.replace(/\W+/g, "_");
        
        switch (source.type)
        {
            case "git":
                if (new File(source.localSourcePath).isDirectory())
                {
                    CPLog.debug("git pull (" + source.localSourcePath + ")");
                    exec("git pull", null, new File(source.localSourcePath));
                }
                else
                {
                    CPLog.debug("git clone (" + source.path + ")");
                    exec(["git", "clone", source.path, source.localSourcePath]);
                }
                break;
            case "svn":
                if (new File(source.localSourcePath).isDirectory())
                {
                    CPLog.debug("svn up (" + source.localSourcePath + ")");
                    exec("svn up", null, new File(source.localSourcePath));
                }
                else
                {
                    CPLog.debug("svn co (" + source.path + ")");
                    exec(["svn", "co", source.path, source.localSourcePath]);
                }
                break;
            case "rsync":
                CPLog.debug("rsync (" + source.localSourcePath + ")");
                exec(["rsync", "-avz", source.path + "/", source.localSourcePath]);
                break;
            default : 
                CPLog.error("Unimplemented: " + source.type);
        }
        
    }
    
}

function build()
{
    var versionedPath = productsPath + "/" + version + "/" + version;
    
    for (var i = 0; i < options.sources.length; i++)
    {
        var source = options.sources[i];
        
        for (var j = 0; j < source.parts.length; j++)
        {
            var part = source.parts[j];
            var fromPath = source.localSourcePath + "/" + part.src;
            var toPath = versionedPath + "/" + part.dst;
            
            if (part.build)
            {
                var buildCommand = part.build.replace("BUILD_PATH", buildsPath);
                CPLog.debug("Building: " + buildCommand);
                
                exec(buildCommand, null, new File(fromPath));
                
                fromPath = buildsPath + "/" + part.copyFrom;
            }
            
            mkdirs(toPath);
            
            var rsyncCommand = "rsync -aC " + fromPath + "/. " + toPath;
            CPLog.debug("Rsyncing: " + rsyncCommand);
            exec(rsyncCommand);
        }
    }
    
    var results = exec(["bash", "-c", "find "+versionedPath+" \\( -name \"*.sj\" -or -name \"*.j\" \\) -exec cat {} \\; | wc -c | tr -d \" \""]);
    
    var filesTotal = parseInt(results.stdout);
    if (isNaN(filesTotal))
        filesTotal = 0;
    
    CPLog.debug("FILES_TOTAL=["+filesTotal+"]");
    
    var substitutions = options.templateVars;
    substitutions.VERSION = version;
    substitutions.FILES_TOTAL = filesTotal;
    
    var template = readFile(options.templatePath);
    if (!template)
        throw new Error("Couldn't get template");
        
    for (var variable in substitutions)
        template = template.replace(new RegExp("\\$" + variable, "g"), substitutions[variable]);
    
    templateBytes = new java.lang.String(template).getBytes();
    templateOutput = new FileOutputStream(productsPath + "/" + version + "/index.html");
    templateOutput.write(templateBytes, 0, templateBytes.length);
    templateOutput.close();
    
    exec(["tar", "czf", version+".tar.gz", version], null, new File(productsPath));    
}

function deploy()
{
    for (var i = 0; i < options.deployments.length; i++)
    {
        var dep = options.deployments[i];
        
        exec(["scp", productsPath + "/" + version + ".tar.gz", dep.host + ":~/" + version + ".tar.gz"]);
        exec(["ssh", dep.host, 
            "tar xzf " + version + ".tar.gz; " +
            "mkdir -p " + dep.path + "; " +
            "mv " + version + "/" + version + "/ " + dep.path + "/" + version + "; " +
            "mv " + version + "/index.html " + dep.path + "/index.html; " +
            "rm " + version + ".tar.gz; " +
            "rmdir " + version + "; " +
            "cd " + dep.path + "; " +
            "ln -nsf " + version + " Current"]);
    }
}

function main()
{
    var bakefile = "bakefile",
        commandOpts = {};
    
    for (var i = 0; i < args.length; i++)
    {
        switch (args[i])
        {
            case "--base":
                commandOpts.base = args[++i];
                break;
            case "--tag":
                commandOpts.tag = true;
                break;
            case "--archive":
                commandOpts.archive = true;
                break;
            case "--clean":
                commandOpts.clean = true;
                break;
            case "--deploy":
                commandOpts.deploy = true;
                break;
            case "--host":
                commandOpts.deployHost = args[++i];
                break;
            case "--path":
                commandOpts.deployPath = args[++i];
                break;
            case "--skip-update":
                commandOpts.skipUpdate = true
                break;
            case "--message":
                commandOpts.message = args[++i];
                break;
            default:
                bakefile = args[i];
        }
    }
    
    try
    {
        var configOpts = readConfig(bakefile);
        
        for (var i in configOpts)  options[i] = configOpts[i];
        for (var i in commandOpts) options[i] = commandOpts[i];
    
        targetPath = pwd() + "/" + bakefile.match(/^[^\.]+/)[0] + ".oven";
        mkdirs(targetPath);

        checkoutsPath = targetPath + "/Checkouts"
        mkdirs(checkoutsPath);

        buildsPath = targetPath + "/Build"
        mkdirs(buildsPath);

        productsPath = targetPath + "/Products"
        mkdirs(productsPath);
    
        if (!options.skipUpdate)
        {
            CPLog.info("Updating");
            update();
        }
            
        CPLog.info("Building");
        build();
        
        if (options.deploy)
        {
            CPLog.info("Deploying");
            deploy();
        }
        
    }
    catch (e)
    {
        CPLog.error(e);
    }
}

function exec()
{
    var runtime = Packages.java.lang.Runtime.getRuntime()
	var p = runtime.exec.apply(runtime, arguments);
	
	var stdout = "";
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream()));
	while (s = reader.readLine())
	{
	    stdout += s;
		CPLog.info("exec: " + s);
	}
    
    var stderr = "";
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream()));
	while (s = reader.readLine())
	{
	    stdout += s;
		CPLog.warn("exec: " + s);
	}

	var code = p.waitFor();
		
	return { code : code, stdout : stdout, stderr : stderr };
}

function pwd()
{
    return String(new File("").getAbsolutePath());
}

function mkdirs(path)
{
    return new File(path).mkdirs();
}

main();