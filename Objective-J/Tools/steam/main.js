
importPackage(java.lang);
importPackage(java.util);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);
importClass(java.io.SequenceInputStream);

#include "../Utilities/bundle.js"

#include "Project.js"

OBJJ_STEAM = OBJJ_HOME + "/lib/steam/";

function main()
{
    if (arguments.length < 1)
        printUsage();
    
    var command = Array.prototype.shift.apply(arguments);

    switch (command)
    {
        case "create":              create.apply(create, arguments);
                                    break;
                            
        case "create-frameworks":   createFrameworks.apply(createFrameworks, arguments);
                                    break;
                                    
                                    
        case "inline-bundle":       inlineBundle.apply(inlineBundle, arguments);
                                    break;
                                    
        case "build":               build.apply(build, arguments);
                                    break;
                        
        case "help":                printUsage(arguments[1]);
                                    break;
        
        case "version":
        case "--version":           printVersion();
                                    break;
                        
        default :                   printUsage(command);
    }
    
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

function getFiles(/*File*/ sourceDirectory, /*nil|String|Array<String>*/ extensions, /*Array*/ exclusions)
{
    var matches = [],
        files = sourceDirectory.listFiles(),
        hasMultipleExtensions = typeof extensions !== "string";

    if (files)
    {
        var index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index].getCanonicalFile(),
                name = String(file.getName()),
                isValidExtension = !extensions;
            
            if (exclusions && fileArrayContainsFile(exclusions, file))
                continue;
            
            if (!isValidExtension)
                if (hasMultipleExtensions)
                {
                    var extensionCount = extensions.length;
                    
                    while (extensionCount-- && !isValidExtension)
                    {
                        var extension = extensions[extensionCount];
                        
                        if (name.substring(name.length - extension.length - 1) === ("." + extension))
                            isValidExtension = true;
                    }
                }
                else if (name.substring(name.length - extensions.length - 1) === ("." + extensions))
                    isValidExtension = true;
                
            if (isValidExtension)
                matches.push(file);
            
            if (file.isDirectory())
                matches = matches.concat(getFiles(file, extensions, exclusions));
        }
    }
    
    return matches;
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

function rsync(srcFile, dstFile)
{
    var src, dst;

    if (String(java.lang.System.getenv("OS")).indexOf("Windows") < 0)
    {
        src = srcFile.getAbsolutePath();
        dst = dstFile.getAbsolutePath();
    }
    else
    {
        src = exec(["cygpath", "-u", srcFile.getAbsolutePath() + '/']);
        dst = exec(["cygpath", "-u", dstFile.getAbsolutePath() + "/Resources"]);
    }

    if (srcFile.exists())
        exec(["rsync", "-avz", src, dst]);
}

function getFileName(aPath)
{
    var index = aPath.lastIndexOf('/');
    
    if (index == -1)
        return aPath;
    
    return aPath.substr(index + 1); 
}

function getFileNameWithoutExtension(aFileOrFileName)
{
    var name = typeof aFileOrFileName === "string" ? aFileOrFileName : aFileOrFileName.getName(),
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

#include "build.js"
#include "create.js"
#include "create-frameworks.js"
#include "inline-bundle.js"
#include "usage.js"
#include "version.js"
