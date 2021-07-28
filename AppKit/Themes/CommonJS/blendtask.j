/*
 * blendtask.j
 * BlendKit
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

@import <Foundation/CPObject.j>
@import <Foundation/CPData.j>
@import <Foundation/CPKeyedArchiver.j>
@import <AppKit/CPCib.j>
@import <AppKit/_CPCibObjectData.j>
@import <BlendKit/BlendKit.j>

debugger;
console.log("require: " + require);
var /* FILE = require("file"), */
    TERM = require("objj-runtime").term,
    task = require("objj-jake").task,
    filedir = require("objj-jake").filedir,
    BundleTask = require("../../../Jake/bundletask.js").BundleTask;

var fs = require("fs");
var path = require("path");

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

    function onlyUnique(value, index, self) {
        return self.indexOf(value) === index;
    }

    this._keyedThemes.filter(onlyUnique)

    infoPlist.setValueForKey("CPKeyedThemes", this._keyedThemes.filter(onlyUnique));
    //infoPlist.setValueForKey("CPKeyedThemes", require("narwhal/util").unique(this._keyedThemes));

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
    var self = this;
    return self.defineThemeDescriptorTasks().then(function() {
        BundleTask.prototype.defineTasks.apply(self, arguments);
    });
};

BlendTask.prototype.defineSourceTasks = function()
{
};

BlendTask.prototype.defineThemeDescriptorTasks = function()
{
    var self = this;
    return new Promise(function(resolve, reject) {
        var envsLeft = self.environments().length;
        self.environments().forEach(function(anEnvironment)
        {
            var folder = anEnvironment.name() + ".environment",
                themeDescriptors = this.themeDescriptors(),
                resourcesPath = this.resourcesPath(),
                intermediatesPath = path.join(this.buildIntermediatesProductPath(), folder, "Resources"),
                staticPath = this.buildProductStaticPathForEnvironment(anEnvironment),
                keyedThemes = this._keyedThemes,
                themesTaskName = this.name() + ":themes";
            var tdLeft = themeDescriptors.length;

            this.enhance(themesTaskName);

            themeDescriptors.forEach(function(/*CPString*/ themeDescriptorPath)
            {
                var localIntermediatesPath = intermediatesPath;
                var localStaticPath = staticPath;
                var localKeyedThemes = keyedThemes;
                var localThemesTaskName = themesTaskName;
                
                console.log("starting themedescriptors: " + themeDescriptorPath);
                objj_importFile(path.resolve(themeDescriptorPath), YES, function() {
                    if (--tdLeft === 0) {
                        [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
                        {
                            var keyedThemePath = path.join(localIntermediatesPath, [aClass themeName] + ".keyedtheme");

                            filedir (keyedThemePath, themesTaskName);
                            filedir (localStaticPath, [keyedThemePath]);

                            localKeyedThemes.push([aClass themeName] + ".keyedtheme");
                        });
                        console.log("themesTaskName: " + localThemesTaskName);
                        task (localThemesTaskName, function()
                        {
                            [BKThemeDescriptor allThemeDescriptorClasses].forEach(function(aClass)
                            {
                                var themeTemplate = [[BKThemeTemplate alloc] init];

                                [themeTemplate setValue:[aClass themeName] forKey:@"name"];

                                var objectTemplates = [aClass themedObjectTemplates],
                                    data = cibDataFromTopLevelObjects(objectTemplates.concat([themeTemplate])),
                                    fileContents = themeFromCibData(data);

                                // No filedir in this case, so we have to make it ourselves.
                                fs.mkdirSync(localIntermediatesPath, { recursive: true });
                                //FILE.mkdirs(intermediatesPath);
                                // FIXME: MARKER_TEXT isn't global, so we use "t;".
                                fs.writeFileSync(path.join(localIntermediatesPath, [aClass themeName] + ".keyedtheme"), "t;" + fileContents.length + ";" + fileContents, { encoding: "utf8" });
                                //FILE.write(FILE.join(intermediatesPath, [aClass themeName] + ".keyedtheme"), "t;" + fileContents.length + ";" + fileContents, { charset:"UTF-8" });
                            });
                        });
                        if (--envsLeft === 0) {
                            resolve();
                        }
                    }
                });
            });
        }, self);
    });
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
    [cib instantiateCibWithExternalNameTable:@{ CPCibTopLevelObjects: topLevelObjects }];

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
    return BlendTask.defineTask(aName, aFunction).then(function(task) {
        return task;
    });
};