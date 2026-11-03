/*
 *  BuiltThemes.j
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
    Loads the themes in the built blends, so that tests can check the real themes
    rather than themes made in code. The themes are read from the build, so they need
    the themes built first, as `npx jake build` does.

    A decoded theme registers itself by name, so +[CPTheme themeNamed:] finds it
    afterwards. The themes are decoded once and shared by every test, so that one name
    never refers to two different theme objects.
*/
var fs = require("fs"),
    path = require("path");

var BuiltThemesLoaded = nil;

/*
    Returns the directory of the built blends: Debug if it exists, otherwise Release.
*/
function BuiltThemesBuildDirectory()
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
function BuiltThemesKeyedThemesInStaticFile(aStaticFile)
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
    Returns every theme in the built blends, sorted by blend. Returns an empty array
    when no blends are built.
*/
function BuiltThemes()
{
    if (BuiltThemesLoaded)
        return BuiltThemesLoaded;

    var buildDirectory = BuiltThemesBuildDirectory();

    BuiltThemesLoaded = [];

    if (!buildDirectory)
        return BuiltThemesLoaded;

    var blends = fs.readdirSync(buildDirectory).filter(function(aName) { return /\.blend$/.test(aName); }).sort();

    for (var i = 0; i < blends.length; i++)
    {
        var blendPath = path.join(buildDirectory, blends[i]),
            staticFile = path.join(blendPath, "CommonJS.environment", blends[i] + ".sj");

        if (!fs.existsSync(staticFile))
            continue;

        var bundle = [CPBundle bundleWithPath:blendPath],
            keyedThemes = BuiltThemesKeyedThemesInStaticFile(staticFile);

        for (var j = 0; j < keyedThemes.length; j++)
        {
            var unarchiver = [[_CPThemeKeyedUnarchiver alloc] initForReadingWithData:[CPData dataWithRawString:keyedThemes[j].text] bundle:bundle],
                theme = [unarchiver decodeObjectForKey:@"root"];

            [unarchiver finishDecoding];
            BuiltThemesLoaded.push(theme);
        }
    }

    return BuiltThemesLoaded;
}

/*
    Returns the built theme with a name, or nil.
*/
function BuiltThemeNamed(aName)
{
    var themes = BuiltThemes();

    for (var i = 0; i < themes.length; i++)
        if ([themes[i] name] === aName)
            return themes[i];

    return nil;
}
