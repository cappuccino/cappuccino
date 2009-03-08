
importPackage(java.lang);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);


function printUsage()
{
    print("this is where you say the usage");
}

function main()
{
    if (arguments.length < 1)
        return printUsage();
    
    var allFiles = NO,
        format = nil,
        filePaths = [],
        outPath = nil,
        outExtension = nil;
    
        index = 0,
        count = arguments.length;
    
    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        if (argument.charAt(0) === '-' && !allFiles)
        {
            if (filePaths.length > 0)
                return printUsage();
            
            else if (argument === "-convert")
                format = arguments[++index];
            
            else if (argument === "-o")
                outPath = arguments[++index];
            
            else if (argument === "-e")
                outExtension = arguments[++index];
            
            else if (argument === "--")
                allFiles = YES;
                
            else if (argument === "-help")
                return printUsage();
        }
        else
            filePaths.push(arguments[index]);
    }
    
    index = 0;
    count = filePaths.length;
    
    for (; index < count; ++index)
    {
        // Read the plist file
        var file = new File(filePaths[index]),
            reader = new BufferedReader(new FileReader(file)),
            fileContents = "";
        
        // Get contents of the file
        while (reader.ready())
            fileContents += reader.readLine() + '\n';
            
        reader.close();
    
        var data = new objj_data();
        
        data.string = fileContents;
    
        var plistObject = new CPPropertyListCreateFromData(data);
    
        if (format === "280north1")
            data = CPPropertyListCreate280NorthData(plistObject);
    
        else if (format === "xml1")
            data = CPPropertyListCreateXMLData(plistObject);
    
        var outFile = file;
        
        if (outPath)
            outFile = new File(outPath);
        
//        else if (outExtension)
            
        
        // Write out file
        var writer = new BufferedWriter(new FileWriter(outFile));
        
        writer.write(data.string);
        
        writer.close();
    }
}

main.apply(main, args);
