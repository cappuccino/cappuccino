/*
 * main.j
 * blend
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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
@import <AppKit/AppKit.j>
@import <BlendKit/BlendKit.j>

var File = require("file");


function main()
{
    var index = 0,
        count = system.args.length,
        
        outputFilePath = "",
        descriptorFiles = [],
        resourcesPath = nil,
        cibFiles = [],
        blendName = "Untitled";
    
    for (; index < count; ++index)
    {
        var argument = system.args[index];
        
        switch (argument)
        {
            case "-c":      
            case "--cib":       cibFiles.push(system.args[++index]);
                                break;
            
            case "-d":      
            case "-descriptor": descriptorFiles.push(system.args[++index]);
                                break;

            case "-o":          outputFilePath = system.args[++index];
                                break;

            case "-R":          resourcesPath = system.args[++index];
                                break;

            default:            jExtensionIndex = argument.indexOf(".j");
                                
                                if ((jExtensionIndex > 0) && (jExtensionIndex === argument.length - ".j".length))
                                    descriptorFiles.push(argument);
                                else
                                    cibFiles.push(argument);
        }
    }

    if (descriptorFiles.length === 0)
        return buildBlendFromCibFiles(cibFiles);

    objj_import(descriptorFiles, YES, function()
    {
        var themeDescriptorClasses = [BKThemeDescriptor allThemeDescriptorClasses],
            count = [themeDescriptorClasses count];

        while (count--)
        {
            var theClass = themeDescriptorClasses[count],
                themeTemplate = [[BKThemeTemplate alloc] init];

            [themeTemplate setValue:[theClass themeName] forKey:@"name"];

            var objectTemplates = [theClass themedObjectTemplates],
                data = cibDataFromTopLevelObjects(objectTemplates.concat([themeTemplate])),
                temporaryCibFile = Packages.java.io.File.createTempFile("temp", ".cib"),
                temporaryCibFilePath = String(temporaryCibFile.getAbsolutePath());

            File.write(temporaryCibFilePath, [data string], { charset:"UTF-8" });
            
            cibFiles.push(temporaryCibFilePath);
        }

        buildBlendFromCibFiles(cibFiles, outputFilePath, resourcesPath);
    });
}

function cibDataFromTopLevelObjects(objects)
{
    var data = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:data],
        objectData = [[_CPCibObjectData alloc] init];

    objectData._fileOwner = [_CPCibCustomObject new];
    objectData._fileOwner._className = @"CPObject";

    var index = 0,
        count = objects.length;
        
    for (; index < count; ++index)
    {
        objectData._objectsValues[index] = objectData._fileOwner;
        objectData._objectsKeys[index] = objects[index];
    }

    [archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];

    [archiver finishEncoding];

    return data;
}

function getDirectory(aPath)
{
    return (aPath).substr(0, (aPath).lastIndexOf('/') + 1)
}

function buildBlendFromCibFiles(cibFiles, outputFilePath, resourcesPath)
{
    var resourcesFile = nil;

    if (resourcesPath)
        resourcesFile = new Packages.java.io.File(resourcesPath);

    var count = cibFiles.length,
        replacedFiles = [],
        staticContent = @"";

    while (count--)
    {
        var theme = themeFromCibFile(new Packages.java.io.File(cibFiles[count])),

            // Archive our theme.
            filePath = [theme name] + ".keyedtheme",
            fileContents = [[CPKeyedArchiver archivedDataWithRootObject:theme] string];

        replacedFiles.push(filePath);

        staticContent += MARKER_PATH + ';' + filePath.length + ';' + filePath + MARKER_TEXT + ';' + fileContents.length + ';' + fileContents;
    }

    staticContent = "@STATIC;1.0;" + staticContent;

    var blendName = File.basename(outputFilePath),
        extension = File.extname(outputFilePath);

    if (extension.length)
        blendName = blendName.substr(0, blendName.length - extension.length);

    var infoDictionary = [CPDictionary dictionary],
        staticContentName = blendName + ".sj";

    [infoDictionary setObject:blendName forKey:@"CPBundleName"];
    [infoDictionary setObject:blendName forKey:@"CPBundleIdentifier"];
    [infoDictionary setObject:replacedFiles forKey:@"CPBundleReplacedFiles"];
    [infoDictionary setObject:staticContentName forKey:@"CPBundleExecutable"];
    
    var outputFile = new Packages.java.io.File(outputFilePath).getCanonicalFile();

    outputFile.mkdirs();

    File.write(outputFilePath + "/Info.plist", [CPPropertyListCreate280NorthData(infoDictionary) string], { charset:"UTF-8" });
    File.write(outputFilePath + '/' + staticContentName, staticContent, { charset:"UTF-8" });
    
    if (resourcesPath)
        rsync(new Packages.java.io.File(resourcesPath), new Packages.java.io.File(outputFilePath));
}

function themeFromCibFile(aFile)
{
    var cib = [[CPCib alloc] initWithContentsOfURL:aFile.getCanonicalPath()],
        topLevelObjects = [];
    
    [cib _setAwakenCustomResources:NO];
    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:topLevelObjects forKey:CPCibTopLevelObjects]];

    var count = topLevelObjects.length,
        theme = nil,
        templates = [];

    while (count--)
    {
        var object = topLevelObjects[count];
        
        templates = templates.concat([object blendThemeObjectTemplates]);

        if ([object isKindOfClass:[BKThemeTemplate class]])
            theme = [[CPTheme alloc] initWithName:[object valueForKey:@"name"]];
    }

    print("Building " + [theme name] + " theme");

    [templates makeObjectsPerformSelector:@selector(blendAddThemedObjectAttributesToTheme:) withObject:theme];

    return theme;
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

@implementation CPObject (BlendAdditions)

- (CPArray)blendThemeObjectTemplates
{
    var theClass = [self class];
    
    if ([theClass isKindOfClass:[BKThemedObjectTemplate class]])
        return [self];
        
    if ([theClass isKindOfClass:[CPView class]])
    {
        var templates = [],
            subviews = [self subviews],
            count = [subviews count];
        
        while (count--)
            templates = templates.concat([subviews[count] blendThemeObjectTemplates]);
        
        return templates;
    }
    
    return [];
}

@end

@implementation BKThemedObjectTemplate (BlendAdditions)

- (void)blendAddThemedObjectAttributesToTheme:(CPTheme)aTheme
{
    var themedObject = [self valueForKey:@"themedObject"];
    
    if (!themedObject)
    {
        var subviews = [self subviews];
        
        if ([subviews count] > 0)
            themedObject = subviews[0];
    }
    
    if (themedObject)
    {
        print(" Recording themed properties for " + [themedObject className] + ".");
        
        [aTheme takeThemeFromObject:themedObject];
    }
}

@end
