/*
 *  CPThemeDataTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-03.
 *  Copyright David Richardson 2026.
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

@import <AppKit/AppKit.j>

/*
    A theme holds values: colours, images, metrics, fonts and flags. It holds no
    code. Behaviour, such as animation, event handling and layout logic, stays in
    the class, where an application can override it, so that a change of theme
    changes appearance and never behaviour.

    These tests read every theme in the built blends and fail on any value that is
    a function, or a string holding a function's source. They read the build, so
    they need the themes built first, as `npx jake build` does.
*/
var fs = require("fs"),
    path = require("path");

var CPThemeDataTestCodePattern = /^\s*\(?\s*(async\s+)?function\b|^\s*\(?[\w\s,]*\)?\s*=>/;

@implementation CPThemeDataTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

/*
    Returns the directory of the built blends: Debug if it exists, otherwise Release.
*/
- (CPString)buildDirectory
{
    var buildPath = process.env.CAPP_BUILD || process.env.BUILD_PATH || "Build",
        configurations = ["Debug", "Release"];

    for (var i = 0; i < configurations.length; i++)
    {
        var directory = path.resolve(buildPath, configurations[i]);

        if (fs.existsSync(directory) && fs.readdirSync(directory).some(function(aName) { return /\.blend$/.test(aName); }))
            return directory;
    }

    return nil;
}

/*
    Returns the keyed theme archives in a blend's static file, as an array of
    { path, text } objects. A static file is a sequence of records, each a type
    letter, a length and that many characters: a "p" record names a file, and the
    "t" record after it holds the file's text.
*/
- (CPArray)keyedThemesInStaticFile:(CPString)aStaticFile
{
    var contents = fs.readFileSync(aStaticFile, { encoding: "utf8" }),
        themes = [],
        index = contents.indexOf(";", contents.indexOf(";") + 1) + 1,
        currentPath = nil;

    while (index < contents.length)
    {
        var type = contents.charAt(index),
            lengthEnd = contents.indexOf(";", index + 2),
            length = parseInt(contents.substring(index + 2, lengthEnd), 10),
            text = contents.substr(lengthEnd + 1, length);

        if (type === "p")
            currentPath = text;
        else if (type === "t" && currentPath && /\.keyedtheme$/.test(currentPath))
            themes.push({ path: currentPath, text: text });

        index = lengthEnd + 1 + length;
    }

    return themes;
}

/*
    Adds a description of every code value inside aValue to someViolations. Arrays
    and dictionaries, such as CSS dictionaries, are searched.
*/
- (void)collectCodeIn:(id)aValue at:(CPString)aLocation into:(CPArray)someViolations
{
    if (aValue === nil || aValue === undefined)
        return;

    if (typeof aValue === "function")
    {
        someViolations.push(aLocation + " is a function");
        return;
    }

    if (typeof aValue === "string")
    {
        if (CPThemeDataTestCodePattern.test(aValue))
            someViolations.push(aLocation + " is a string holding a function's source");

        return;
    }

    if (!aValue.isa)
        return;

    if ([aValue isKindOfClass:[CPArray class]])
    {
        for (var i = 0; i < aValue.length; i++)
            [self collectCodeIn:aValue[i] at:aLocation + "[" + i + "]" into:someViolations];
    }
    else if ([aValue isKindOfClass:[CPDictionary class]])
    {
        var keys = [aValue allKeys];

        for (var i = 0; i < keys.length; i++)
            [self collectCodeIn:[aValue objectForKey:keys[i]] at:aLocation + "." + keys[i] into:someViolations];
    }
}

- (void)testThemeValuesAreData
{
    var buildDirectory = [self buildDirectory];

    [self assertTrue:buildDirectory !== nil message:@"No built blends were found. Build the themes first."];

    var blends = fs.readdirSync(buildDirectory).filter(function(aName) { return /\.blend$/.test(aName); }).sort(),
        themeCount = 0,
        violations = [];

    for (var i = 0; i < blends.length; i++)
    {
        var blendPath = path.join(buildDirectory, blends[i]),
            staticFile = path.join(blendPath, "CommonJS.environment", blends[i] + ".sj");

        if (!fs.existsSync(staticFile))
            continue;

        var bundle = [CPBundle bundleWithPath:blendPath],
            keyedThemes = [self keyedThemesInStaticFile:staticFile];

        for (var j = 0; j < keyedThemes.length; j++)
        {
            var unarchiver = [[_CPThemeKeyedUnarchiver alloc] initForReadingWithData:[CPData dataWithRawString:keyedThemes[j].text] bundle:bundle],
                theme = [unarchiver decodeObjectForKey:@"root"];

            [unarchiver finishDecoding];
            themeCount++;

            var classNames = [[theme classNames] sortedArrayUsingSelector:@selector(compare:)];

            for (var k = 0; k < classNames.length; k++)
            {
                var attributes = [theme attributesForClass:classNames[k]],
                    names = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];

                for (var m = 0; m < names.length; m++)
                {
                    var attribute = [attributes objectForKey:names[m]],
                        location = [theme name] + " " + classNames[k] + " " + names[m],
                        values = [attribute values],
                        states = [values allKeys];

                    [self collectCodeIn:[attribute defaultValue] at:location + " (default)" into:violations];

                    for (var n = 0; n < states.length; n++)
                        [self collectCodeIn:[values objectForKey:states[n]] at:location + " (" + states[n] + ")" into:violations];
                }
            }
        }
    }

    [self assertTrue:themeCount > 0 message:@"No themes were found in the built blends."];
    [self assertTrue:violations.length === 0 message:@"Theme values must be data, not code:\n" + violations.join("\n")];
}

@end
