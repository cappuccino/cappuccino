/*
 * main.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */


@import <Foundation/Foundation.j>

@import <AppKit/CPCib.j>

@import "NSFoundation.j"
@import "NSAppKit.j"
@import "Nib2CibKeyedUnarchiver.j"

importPackage(java.io);

CPLogRegister(CPLogPrint);

function exec(command)
{
	var p = Packages.java.lang.Runtime.getRuntime().exec(command);
	var result = p.waitFor();
	
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream()));
	while (s = reader.readLine())
		print(s);

	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream()));
	while (s = reader.readLine())
		print(s);
		
	return result;
}

function printUsage()
{
    java.lang.System.out.println("usage: steam INPUT_FILE [OUTPUT_FILE]");    
    java.lang.System.exit(1);
}

function cibExtension(aPath)
{
    var start = aPath.length - 1;
    
    while (aPath.charAt(start) === '/')
        start--;

    aPath = aPath.substr(0, start + 1);

    var dotIndex = aPath.lastIndexOf('.');
    
    if (dotIndex == -1)
        return aPath + ".cib";
    
    var slashIndex = aPath.lastIndexOf('/');
    
    if (slashIndex > dotIndex)
        return aPath + ".cib";
    
    return aPath.substr(0, dotIndex) + ".cib";
}

function convert(inputFileName, outputFileName, resourcesPath)
{
    var resourcesFile = nil;
    
    if (resourcesPath)
    {
        resourcesFile = new java.io.File(resourcesPath).getCanonicalFile();
     
        if (!resourcesFile.canRead())
        {
            print("Could not find Resources at " + resourcesFile);
            return;
        }
    }
    
    // Make sure we can read the file
    if (!(new Packages.java.io.File(inputFileName)).canRead())
    {
        print("Could not read file at " + inputFileName);
        return;
    }

    // Compile xib or nib to make sure we have a non-new format nib.
    var temporaryNibFile = java.io.File.createTempFile("temp", ".nib"),
        temporaryNibFilePath = temporaryNibFile.getAbsolutePath();
    
    temporaryNibFile.deleteOnExit();
    
    if (exec(["/usr/bin/ibtool", inputFileName, "--compile", temporaryNibFilePath]))
    {
        print("Could not compile file at " + inputFileName);
        return;
    }

    // Convert from binary plist to XML plist
    var temporaryPlistFile = java.io.File.createTempFile("temp", ".plist"),
        temporaryPlistFilePath = temporaryPlistFile.getAbsolutePath();
    
    temporaryPlistFile.deleteOnExit();
    
    if (exec(["/usr/bin/plutil", "-convert", "xml1", temporaryNibFilePath, "-o", temporaryPlistFilePath]))
    {
        print("Could not convert to xml plist for file at " + inputFileName);
        return;
    }

    var data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:temporaryPlistFilePath] returningResponse:nil error:nil];
    
    // Minor NSKeyedArchive to CPKeyedArchive conversion.
    [data setString:[data string].replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>")];
    
    // Unarchive the NS data
    var unarchiver = [[Nib2CibKeyedUnarchiver alloc] initForReadingWithData:data resourcesFile:resourcesFile],
        objectData = [unarchiver decodeObjectForKey:@"IB.objectdata"],
        
        data = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:data];

    // Re-archive the CP data.
    [archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];
    [archiver finishEncoding];
    
    var writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFileName), "UTF-8"));
    
    writer.write([data string]);
    
    writer.close();
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

function loadFrameworks(frameworkPaths, aCallback)
{
    if (frameworkPaths.length === 0)
        return aCallback();
    
    var frameworkPath = frameworkPaths.shift(),
        
        infoPlist = new java.io.File(frameworkPath + "/Info.plist");
        
    if (!infoPlist.exists())
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework or could not be found.");
        java.lang.System.exit(1);
    }
    
    var infoDictionary = readPlist(new java.io.File(frameworkPath + "/Info.plist"));
    
    if ([infoDictionary objectForKey:@"CPBundlePackageType"] !== "FMWK")
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework.");
        java.lang.System.exit(1);
    }
    
    var files = [infoDictionary objectForKey:@"CPBundleReplacedFiles"],
        count = files.length;
    
    if (count)
    {
        var context = new objj_context();

        context.didCompleteCallback = function() { loadFrameworks(frameworkPaths, aCallback) };

        while (count--)
            context.pushFragment(fragment_create_file(frameworkPath + '/' + files[count], new objj_bundle(""), YES, NULL));

        context.evaluate();
    }
    else
        loadFrameworks(frameworkPaths, aCallback);
}

function main()
{
    var count = arguments.length;
    
    if (count < 1)
        printUsage();
    
    var index = 0,
    
        inputFileName = nil,
        outputFileName = nil,
        resourcesPath = nil,
        frameworkPaths = [];
    
    for (; index < count; ++index)
    {
        switch(arguments[index])
        {
            case "-help":
            case "--help":  printUsage();
            
            case "-F":      frameworkPaths.push(arguments[++index]);
                            break;
                            
            case "-R":      resourcesPath = arguments[++index];
                            break;
            
            default:        if (inputFileName && inputFileName.length > 0)
                                outputFileName = arguments[index];
                            else
                                inputFileName = arguments[index];
        }
    }

    if (!outputFileName || outputFileName.length < 1)
        outputFileName = cibExtension(inputFileName);

    if (frameworkPaths.length)
        loadFrameworks(frameworkPaths, function() { convert(inputFileName, outputFileName, resourcesPath); });
    
    else
        convert(inputFileName, outputFileName, resourcesPath);
}
