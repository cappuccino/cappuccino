

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <BlendKit/BlendKit.j>


var Jake = require("jake"),
    BundleTask = require("objective-j/jake/bundletask").BundleTask;


function BlendTask(aName)
{
    BundleTask.apply(this, arguments);
    
    this._themeDescriptors = [];
    this._keyedThemes = [];
}

BlendTask.__proto__ = BundleTask;
BlendTask.prototype.__proto__ = BundleTask.prototype;

BlendTask.prototype.packageType = function()
{
    return "BLND";
}

BlendTask.prototype.infoPlist = function()
{
    var infoPlist = BundleTask.prototype.infoPlist.apply(this, arguments);

    infoPlist.setValue("CPKeyedThemes", this._keyedThemes);

    return infoPlist;
}

BlendTask.prototype.themeDescriptors = function()
{
    return this._themeDescriptors;
}

BlendTask.prototype.setThemeDescriptors = function(/*Array | FileList*/ themeDescriptors)
{
    this._themeDescriptors = themeDescriptors;
}

BlendTask.prototype.defineTasks = function()
{
    this.defineThemeDescriptorTasks();

    BundleTask.prototype.defineTasks.apply(this, arguments);
}

BlendTask.prototype.defineSourceTasks = function()
{ 
}

BlendTask.prototype.defineThemeDescriptorTasks = function()
{print("in");
    var themeDescriptors = this.themeDescriptors(),
        resourcesPath = this.resourcesPath(),
        intermediatesPath = FILE.join(this.buildIntermediatesProductPath(), "Browser" + ".platform", "Resources"),
        staticPath = this.buildProductStaticPathForPlatform("Browser"),
        keyedThemes = this._keyedThemes,
        themesTaskName = this.name() + ":themes";
print("out");
    this.enhance(themesTaskName);
print("uuuuhmmm");
    objj_import(themeDescriptors.toArray(), YES, function()
    {
        [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
        {
            var keyedThemePath = FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme");

            filedir (keyedThemePath, themesTaskName);
            filedir (staticPath, [keyedThemePath]);

            keyedThemes.push([aClass themeName] + ".keyedtheme");
        });
    });
print("WHAT");
    require("browser/timeout").serviceTimeouts();
print("IS WRONG");
    task (themesTaskName, function()
    {print("wtf");
        [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
        {
            var themeTemplate = [[BKThemeTemplate alloc] init];

            [themeTemplate setValue:[aClass themeName] forKey:@"name"];

            var objectTemplates = [aClass themedObjectTemplates],
                data = cibDataFromTopLevelObjects(objectTemplates.concat([themeTemplate])),
                fileContents = themeFromCibData(data);
print("will write to" + FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme"));
            // No filedir in this case, so we have to make it ourselves.
            FILE.mkdirs(intermediatesPath);
            FILE.write(FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme"), MARKER_TEXT + ";" + fileContents.length + ";" + fileContents, { charset:"UTF-8" });
        });
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

function themeFromCibData(data)
{
    var cib = [[CPCib alloc] initWithData:data],
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

    return [[CPKeyedArchiver archivedDataWithRootObject:theme] string];
}

@implementation CPCib (BlendAdditions)

- (id)initWithData:(CPData)aData
{
    self = [super init];

    if (self)
        _data = aData;

    return self;
}

@end

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

exports.BlendTask = BlendTask;

exports.blend = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BlendTask.defineTask(aName, aFunction);
}
