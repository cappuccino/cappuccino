/*
 * BKThemeDescriptor.j
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
@import <Foundation/CPArray.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPView.j>
@import <AppKit/_CPCibCustomResource.j>


PatternIsHorizontal = CPColorPatternIsHorizontal;
PatternIsVertical   = CPColorPatternIsVertical;

var ItemSizes               = { },
    ThemedObjects           = { },
    ThemedShowcaseObjects   = { },
    BackgroundColors        = { },

    LightCheckersColor      = nil,
    DarkCheckersColor       = nil,
    WindowBackgroundColor   = nil;

@implementation BKThemeDescriptor : CPObject
{
}

+ (CPArray)allThemeDescriptorClasses
{
    // Grab Theme Descriptor Classes.
    var themeDescriptorClasses = [];

    for (candidate in global)
    {
        var theClass = objj_getClass(candidate),
            theClassName = class_getName(theClass);

        if (theClassName === "BKThemeDescriptor")
            continue;

        var index = theClassName.indexOf("ThemeDescriptor");

        if ((index >= 0) && (index === theClassName.length - "ThemeDescriptor".length))
            themeDescriptorClasses.push(theClass);
    }

    [themeDescriptorClasses sortUsingSelector:@selector(compare:)];

    return themeDescriptorClasses;
}

+ (CPColor)lightCheckersColor
{
    if (!LightCheckersColor)
        LightCheckersColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[BKThemeDescriptor class]] pathForResource:@"light-checkers.png"] size:CGSizeMake(12.0, 12.0)]];

    return LightCheckersColor;
}

+ (CPColor)darkCheckersColor
{
    if (!DarkCheckersColor)
        DarkCheckersColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[BKThemeDescriptor class]] pathForResource:@"dark-checkers.png"] size:CGSizeMake(12.0, 12.0)]];

    return DarkCheckersColor;
}

+ (CPColor)windowBackgroundColor
{
    return [CPColor colorWithCalibratedWhite:0.95 alpha:1.0];
}

+ (CPColor)defaultShowcaseBackgroundColor
{
    return [CPColor colorWithCalibratedWhite:0.95 alpha:1.0];
}

+ (CPColor)showcaseBackgroundColor
{
    var className = [self className];

    if (!BackgroundColors[className])
        BackgroundColors[className] = [self defaultShowcaseBackgroundColor];

    return BackgroundColors[className];
}

+ (void)setShowcaseBackgroundColor:(CPColor)aColor
{
    BackgroundColors[[self className]] = aColor;
}

+ (CGSize)itemSize
{
    var className = [self className];

    if (!ItemSizes[className])
        [self calculateThemedObjectTemplates];

    return CGSizeMakeCopy(ItemSizes[className]);
}

+ (CPArray)themedObjectTemplates
{
    var className = [self className];

    if (!ThemedObjects[className])
        [self calculateThemedObjectTemplates];

    return ThemedObjects[className];
}

+ (CPArray)themedShowcaseObjectTemplates
{
    var className = [self className];

    if (!ThemedShowcaseObjects[className])
        [self calculateThemedObjectTemplates];

    return ThemedShowcaseObjects[className];
}

+ (void)calculateThemedObjectTemplates
{
    var templates = [],
        showcaseTemplates = [],
        itemSize = CGSizeMake(0.0, 0.0),
        methods = class_copyMethodList([self class].isa),
        index = 0,
        count = [methods count],
        excludes = [];

    if ([self respondsToSelector:@selector(themeShowcaseExcludes)])
        excludes = [self themeShowcaseExcludes];

    for (; index < excludes.length; ++index)
    {
        var name = excludes[index].toLowerCase();

        if (name && name.indexOf("themed") !== 0)
            excludes[index] = "themed" + name;
        else
            excludes[index] = name;
    }

    for (index = 0; index < count; ++index)
    {
        var method = methods[index],
            selector = method_getName(method);

        if (selector.indexOf("themed") !== 0)
            continue;

        var impl = method_getImplementation(method),
            object = impl(self, selector);

        if (!object)
            continue;

        var template = [[BKThemedObjectTemplate alloc] init],
            excluded = [excludes containsObject:selector.toLowerCase()];

        [template setValue:object forKey:@"themedObject"];
        [template setValue:BKLabelFromIdentifier(selector) forKey:@"label"];

        [templates addObject:template];

        if (!excluded)
        {
            if ([object isKindOfClass:[CPView class]])
            {
                var size = [object frame].size,
                    labelWidth = [[template valueForKey:@"label"] sizeWithFont:[CPFont boldSystemFontOfSize:0]].width + 20.0;

                if (size.width > itemSize.width)
                    itemSize.width = size.width;

                if (labelWidth > itemSize.width)
                    itemSize.width = labelWidth;

                if (size.height > itemSize.height)
                    itemSize.height = size.height;
            }

            [showcaseTemplates addObject:template];
        }
    }

    var className = [self className];

    ItemSizes[className] = itemSize;
    ThemedObjects[className] = templates;
    ThemedShowcaseObjects[className] = showcaseTemplates;
}

+ (int)compare:(BKThemeDescriptor)aThemeDescriptor
{
    return [[self themeName] compare:[aThemeDescriptor themeName]];
}

+ (void)registerThemeValues:(CPArray)themeValues forView:(CPView)aView
{
    for (var i = 0; i < themeValues.length; ++i)
    {
        var attributeValueState = themeValues[i],
            attribute = attributeValueState[0],
            value = attributeValueState[1],
            state = attributeValueState[2];

        if (state)
            [aView setValue:value forThemeAttribute:attribute inState:state];
        else
            [aView setValue:value forThemeAttribute:attribute];
    }
}

+ (void)registerThemeValues:(CPArray)themeValues forView:(CPView)aView inherit:(CPArray)inheritedValues
{
    // Register inherited values first, then override those with the subtheme values.
    if (inheritedValues)
    {
        // Check the class name to see if it is a subtheme of another theme. If so,
        // use the subtheme name as a relative path to image patterns.
        var themeName = [self themeName],
            index = themeName.indexOf("-");

        if (index < 0)
        {
            // This theme is a subtheme, register the inherited values directly
            [self registerThemeValues:inheritedValues forView:aView];
        }
        else
        {
            var themePath = themeName.substr(index + 1) + "/";

            for (var i = 0; i < inheritedValues.length; ++i)
            {
                var attributeValueState = inheritedValues[i],
                    attribute = attributeValueState[0],
                    value = attributeValueState[1],
                    state = attributeValueState[2],
                    pattern = nil;

                if (typeof(value) === "object" &&
                    value.hasOwnProperty("isa") &&
                    [value isKindOfClass:CPColor] &&
                    (pattern = [value patternImage]))
                {
                    if ([pattern isThreePartImage] || [pattern isNinePartImage])
                    {
                        var slices = [pattern imageSlices],
                            newSlices = [];

                        for (var sliceIndex = 0; sliceIndex < slices.length; ++sliceIndex)
                        {
                            var slice = slices[sliceIndex],
                                filename = themePath + [[slice filename] lastPathComponent],
                                size = [slice size];

                            newSlices.push([filename, size.width, size.height]);
                        }

                        if ([pattern isThreePartImage])
                            value = PatternColor(newSlices, [pattern isVertical]);
                        else
                            value = PatternColor(newSlices);
                    }
                    else
                    {
                        var filename = themePath + [[pattern filename] lastPathComponent],
                            size = [pattern size];

                        value = PatternColor(filename, size.width, size.height);
                    }
                }

                if (state)
                    [aView setValue:value forThemeAttribute:attribute inState:state];
                else
                    [aView setValue:value forThemeAttribute:attribute];
            }
        }
    }

    if (themeValues)
        [self registerThemeValues:themeValues forView:aView];
}

@end

function BKLabelFromIdentifier(anIdentifier)
{
    var string = anIdentifier.substr("themed".length),
        index = 0,
        count = string.length,
        label = "",
        lastCapital = null,
        isLeadingCapital = YES;

    for (; index < count; ++index)
    {
        var character = string.charAt(index),
            isCapital = /^[A-Z]/.test(character);

        if (isCapital)
        {
            if (!isLeadingCapital)
            {
                if (lastCapital === null)
                    label += ' ' + character.toLowerCase();
                else
                    label += character;
            }

            lastCapital = character;
        }
        else
        {
            if (isLeadingCapital && lastCapital !== null)
                label += lastCapital;

            label += character;

            lastCapital = null;
            isLeadingCapital = NO;
        }
    }

    return label;
}

function PatternImage(name, width, height)
{
    return [_CPCibCustomResource imageResourceWithName:name size:CGSizeMake(width, height)];
}

/*
    PatternColor is just a wrapper around CPColorWithImages
    that uses an image factory that uses _CPCibCustomResource.
*/
function PatternColor()
{
    var args = Array.prototype.slice.apply(arguments);
    args.push(PatternImage);

    return CPColorWithImages.apply(this, args);
}
