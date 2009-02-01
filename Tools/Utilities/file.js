

function readFile(/*File*/ aFile)
{
    var reader = new BufferedReader(new FileReader(aFile)),
        fileContents = "";
    
    // Get contents of the file
    while (reader.ready())
        fileContents += reader.readLine() + '\n';
    
    reader.close();
        
    return fileContents;
}

function writeContentsToFile(/*String*/ contents, /*File*/ aFile)
{
    
}

function readPlist(/*File*/ aFile)
{
    var fileContents = readFile(aFile);

    var data = new objj_data();
    data.string = fileContents;

    return new CPPropertyListCreateFromData(data);
}

function importFiles(files, aCallback)
{

    if (files.length === 0)
        aCallback();
    else
    {
        var file = files.shift();
        
        if (typeof file === "string")
            file = new File(file);
        
        objj_import(file.getCanonicalPath(), YES, function() { importFiles(files, aCallback) });
    }
        return;

    var context = new objj_context();

    if (aCallback)
        context.didCompleteCallback = aCallback;

    var count = files.length;
        
    while (count--)
    {
        var file = files[count];
        
        if (typeof file === "string")
            file = new File(file);
        
        context.pushFragment(fragment_create_file(file, new objj_bundle(""), YES, NULL));
    }
    
    context.evaluate();
}

function loadFrameworks(frameworkPaths, aCallback)
{
    if (frameworkPaths.length === 0)
        return aCallback();
    
    var frameworkPath = frameworkPaths.shift(),
        
        infoPlist = new File(frameworkPath + "/Info.plist");
        
    if (!infoPlist.exists())
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework or could not be found.");
        java.lang.System.exit(1);
    }
    
    var infoDictionary = readPlist(new File(frameworkPath + "/Info.plist"));
    
    if (dictionary_getValue(infoDictionary, "CPBundlePackageType") !== "FMWK")
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework .");
        java.lang.System.exit(1);
    }
    
    var files = dictionary_getValue(infoDictionary, "CPBundleReplacedFiles"),
        index = 0,
        count = files.length;
        
    for (; index < count; ++index)
        files[index] = String(frameworkPath + '/' + files[index]);
    
    importFiles(files, function() { loadFrameworks(frameworkPaths, aCallback) });
}
