
importPackage(java.lang);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);


function exec(command)
{
	var p = Packages.java.lang.Runtime.getRuntime().exec(command);//jsArrayToJavaArray(command));
	
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream()));
	while (s = reader.readLine())
		System.out.println(s);
    
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream()));
	while (s = reader.readLine())
		System.out.println(s);

	var result = p.waitFor();
		
	return result;
}

function preprocess(aFilePath, outFilePath, gccArgs, shouldObjjPreprocess, shouldCheckSyntax)
{
    print("Statically Preprocessing " + aFilePath);
    
    // FIXME: figure out why this doesn't work on Windows/Cygwin
    //var tmpFile = java.io.File.createTempFile("OBJJC", "");
    var tmpFile = new java.io.File(outFilePath+".tmp");
    tmpFile.deleteOnExit();
    
    // -E JUST preprocess.
    // -x c Interpret language as C -- closest thing to JavaScript.
    // -P Don't generate #line directives
    var gccComponents = ["gcc", "-E", "-x", "c", "-P", aFilePath, "-o", shouldObjjPreprocess ? tmpFile.getAbsolutePath() : outFilePath],
        index = gccArgs.length;
    
    // Add custom gcc arguments.
    while (index--)
        gccComponents.splice(5, 0, gccArgs[index]);
    
    exec(gccComponents);
    
    if (!shouldObjjPreprocess)
        return;
    
    // Read file and preprocess it.
    var reader = new BufferedReader(new FileReader(tmpFile)),
        fileContents = "";
    
    // Get contents of the file
    while (reader.ready())
        fileContents += reader.readLine() + '\n';
        
    reader.close();
    
    var results;
    
    try
    {
        results = objj_preprocess_file(new File(aFilePath).getName(), fileContents, shouldCheckSyntax);
    }
    catch (e)
    {
        if (e.fragment)
        {
            var lines = e.fragment.info.split("\n"),
                PAD = 3;
		    System.out.println(
		        "Syntax error in "+e.fragment.file.path+
		        " on preprocessed line number "+e.lineNumber+"\n"+
		        "\t"+lines.slice(e.lineNumber-1-PAD<0 ? 0 : e.lineNumber-1-PAD, e.lineNumber+PAD).join("\n\t"));
        }
		else
		    System.out.println("Unknown error: " + e);
		    
    	System.exit(1);
    }

    // Write file.
    var writer = new BufferedWriter(new FileWriter(outFilePath));
    writer.write(results);
    writer.close();
}

function main()
{
    var filePaths = [],
        outFilePaths = [],
        
        index = 0,
        count = args.length,
        
        gccArgs = [],
        
        shouldObjjPreprocess = true,
        shouldCheckSyntax = true;
    
    for (; index < count; ++index)
    {
        if (args[index] == "-o")
        {
            if (++index < count)
                outFilePaths.push(args[index]);
        }
        
        else if (args[index].indexOf("-D") == 0)
            gccArgs.push(args[index])
            
        else if (args[index].indexOf("-U") == 0)
            gccArgs.push(args[index]);
            
        else if (args[index].indexOf("-E") == 0)
            shouldObjjPreprocess = false;
            
        else if (args[index].indexOf("-S") == 0)
            shouldCheckSyntax = false;
    
        else
            filePaths.push(args[index]);
    }
    
    for (index = 0, count = filePaths.length; index < count; ++index)
        preprocess(filePaths[index], outFilePaths[index], gccArgs, shouldObjjPreprocess, shouldCheckSyntax);
}

args = arguments;
main();
