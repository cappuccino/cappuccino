
@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPCib.j>
@import <AppKit/CPTheme.j>
@import <BlendKit/BlendKit.j>

importClass(java.io.File);
importClass(java.io.FileOutputStream);
importClass(java.io.BufferedWriter);
importClass(java.io.OutputStreamWriter);


function main()
{
    var index = 0,
        count = arguments.length,
        
        outputFilePath = "",
        descriptorFiles = [],
        resourcesPath = nil,
        cibFiles = [];
    
    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (argument)
        {
            case "-c":      
            case "--cib":       cibFiles.push(arguments[++index]);
                                break;
            
            case "-d":      
            case "-descriptor": descriptorFiles.push(arguments[++index]);
                                break;

            case "-o":          outputFilePath = arguments[++index];
                                break;

            case "-R":          resourcesPath = arguments[++index];
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
        var themeDescriptorClasses = BKThemeDescriptorClasses(),
            count = [themeDescriptorClasses count];
    
        while (count--)
        {
            var theClass = themeDescriptorClasses[count],
                themeTemplate = [[AKThemeTemplate alloc] init];
                
            [themeTemplate setValue:[theClass themeName] forKey:@"name"];
            
            var objectTemplates = BKThemeObjectTemplatesForClass(theClass);
                data = cibDataFromTopLevelObjects(objectTemplates.concat([themeTemplate])),
                temporaryCibFile = File.createTempFile("temp", ".cib"),
                temporaryCibFilePath = temporaryCibFile.getAbsolutePath(),
                writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(temporaryCibFilePath), "UTF-8"));
    
            writer.write([data string]);
            writer.close();
            
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
        resourcesFile = new File(resourcesPath);
    
    var count = cibFiles.length,
        replacedFiles = [],
        staticContent = @"";
    
    while (count--)
    {
        var theme = themeFromCibFile(new File(cibFiles[count])),
        
            // Archive our theme.
            filePath = [theme name] + ".keyedtheme",
            fileContents = [[CPKeyedArchiver archivedDataWithRootObject:theme] string];
        
        replacedFiles.push(filePath);
        
        staticContent += MARKER_PATH + ';' + filePath.length + ';' + filePath + MARKER_TEXT + ';' + fileContents.length + ';' + fileContents;
    }
    
    staticContent = "@STATIC;1.0;" + staticContent;
    
    var infoDictionary = [CPDictionary dictionary];
        staticContentName = "Aristo";//getFileNameWithoutExtension(project.activeTarget().name());

    [infoDictionary setObject:@"Yikes." forKey:@"CPBundleName"];    
    [infoDictionary setObject:@"Yikes." forKey:@"CPBundleIdentifier"];
    [infoDictionary setObject:replacedFiles forKey:@"CPBundleReplacedFiles"];
    [infoDictionary setObject:staticContentName forKey:@"CPBundleExecutable"];
    
    var outputFile = new File(outputFilePath).getCanonicalFile();

    outputFile.mkdirs();
    
    var writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFilePath + "/Info.plist"), "UTF-8"));
    
    writer.write(CPPropertyListCreate280NorthData(infoDictionary).string);
    
    writer.close();
    
    writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFilePath + '/' + staticContentName), "UTF-8"));
    
    writer.write(staticContent);
    
    writer.close();
    
    if (resourcesPath)
        rsync(new File(resourcesPath), new File(outputFilePath));
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
        
        if ([object isKindOfClass:[AKThemeTemplate class]])
            theme = [[CPTheme alloc] initWithName:[object valueForKey:@"name"]];
    }

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
    
    if ([theClass isKindOfClass:[AKThemeObjectTemplate class]])
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

@implementation AKThemeObjectTemplate (BlendAdditions)

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
        print(" Recording theme for " + [themedObject className] + ".");
        
        [aTheme takeThemeFromObject:themedObject];
    }
}

@end
