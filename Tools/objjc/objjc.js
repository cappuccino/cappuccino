
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

function preprocess(aFilePath, outFilePath, gccArgs, shouldObjjPreprocess)
{
    print("Statically Preprocessing " + aFilePath);
    
    var tmpFile = java.io.File.createTempFile("OBJJC", "");
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

    // Write file.
    var writer = new BufferedWriter(new FileWriter(outFilePath));
    
    writer.write(objj_preprocess_file(new File(aFilePath).getName(), fileContents));
    
    writer.close();
}

function main()
{
    var filePaths = [],
        outFilePaths = [],
        
        index = 0,
        count = args.length,
        
        gccArgs = [],
        
        shouldObjjPreprocess = true;
    
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
    
        else
            filePaths.push(args[index]);
    }
    
    for (index = 0, count = filePaths.length; index < count; ++index)
        preprocess(filePaths[index], outFilePaths[index], gccArgs, shouldObjjPreprocess);
}

args = arguments;
main();
