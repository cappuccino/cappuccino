

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <BlendKit/BlendKit.j>


var FILE = require("file"),
    TERM = require("narwhal/term"),
    task = require("jake").task,
    filedir = require("jake").filedir,
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
};

BlendTask.prototype.infoPlist = function()
{
    var infoPlist = BundleTask.prototype.infoPlist.apply(this, arguments);

    infoPlist.setValueForKey("CPKeyedThemes", require("narwhal/util").unique(this._keyedThemes));

    return infoPlist;
};

BlendTask.prototype.themeDescriptors = function()
{
    return this._themeDescriptors;
};

BlendTask.prototype.setThemeDescriptors = function(/*Array | FileList*/ themeDescriptors)
{
    this._themeDescriptors = themeDescriptors;
};

BlendTask.prototype.defineTasks = function()
{
    this.defineThemeDescriptorTasks();

    BundleTask.prototype.defineTasks.apply(this, arguments);
};

BlendTask.prototype.defineSourceTasks = function()
{
};

BlendTask.prototype.defineThemeDescriptorTasks = function()
{
    this.environments().forEach(function(anEnvironment)
    {
        var folder = anEnvironment.name() + ".environment",
            themeDescriptors = this.themeDescriptors(),
            resourcesPath = this.resourcesPath(),
            intermediatesPath = FILE.join(this.buildIntermediatesProductPath(), folder, "Resources"),
            staticPath = this.buildProductStaticPathForEnvironment(anEnvironment),
            keyedThemes = this._keyedThemes,
            themesTaskName = this.name() + ":themes";

        this.enhance(themesTaskName);

        themeDescriptors.forEach(function(/*CPString*/ themeDescriptorPath)
        {
            objj_importFile(FILE.absolute(themeDescriptorPath), YES);
        });

        [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
        {
            var keyedThemePath = FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme");

            filedir (keyedThemePath, themesTaskName);
            filedir (staticPath, [keyedThemePath]);

            keyedThemes.push([aClass themeName] + ".keyedtheme");
        });

        task (themesTaskName, function()
        {
            [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
            {
                var themeTemplate = [[BKThemeTemplate alloc] init];

                [themeTemplate setValue:[aClass themeName] forKey:@"name"];

                var objectTemplates = [aClass themedObjectTemplates],
                    data = cibDataFromTopLevelObjects(objectTemplates.concat([themeTemplate])),
                    fileContents = themeFromCibData(data);

                // No filedir in this case, so we have to make it ourselves.
                FILE.mkdirs(intermediatesPath);
                // FIXME: MARKER_TEXT isn't global, so we use "t;".
                FILE.write(FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme"), "t;" + fileContents.length + ";" + fileContents, { charset:"UTF-8" });
            });
        });
    }, this);
};

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

    TERM.stream.print("Building \0green(" + [theme name] + "\0) theme");

    [templates makeObjectsPerformSelector:@selector(blendAddThemedObjectAttributesToTheme:) withObject:theme];

    return [[CPKeyedArchiver archivedDataWithRootObject:theme] rawString];
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
        TERM.stream.print(" Recording themed properties for \0purple(" + [themedObject className] + "\0).");

        [aTheme takeThemeFromObject:themedObject];
    }
}

@end

exports.BlendTask = BlendTask;

exports.blend = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return BlendTask.defineTask(aName, aFunction);
};
