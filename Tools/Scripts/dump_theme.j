#!/usr/bin/env objj

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <BlendKit/BlendKit.j>

var FILE = require("file"),
    OS = require("os"),

    DefaultTheme = "Aristo",
    BuildTypes = ["Debug", "Release"],

    FILE = require("file"),
    OS = require("os"),
    SYS = require("system"),
    FileList = require("jake").FileList,
    stream = require("term").stream,

    ImageDescriptionFormat = "<%s> {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}";


function main(args)
{
    var themeName = args[1] || "",
        themeDir = "";

    if (themeName && themeName.indexOf("/") >= 0)
    {
        themeDir = themeName;
        themeName = FILE.basename(themeName, FILE.extension(themeName));
    }

    themeName = themeName || getDefaultThemeName();

    if (!themeName)
        fail("Could not determine the theme name.");

    colorPrint("purple", "Theme name: " + themeName);

    var theme = loadTheme(themeName, themeDir);

    if (!theme)
        fail("Could not load the theme \"" + themeName + "\"");

    var classNames = [theme classNames];

    classNames.sort();

    for (var i = 0; i < classNames.length; ++i)
    {
        var className = classNames[i],
            attributes = [theme attributeNamesForClass:className];

        colorPrint("green", "---------------------------\n" + className + "\n---------------------------");
        attributes.sort();

        for (var attributeIndex = 0; attributeIndex < attributes.length; ++attributeIndex)
        {
            var attributeName = attributes[attributeIndex],
                values = [[theme attributeWithName:attributeName forClass:className] values],
                states = [values allKeys];

            colorPrint("violet", attributeName);
            states.sort();

            for (var stateIndex = 0; stateIndex < states.length; ++stateIndex)
            {
                var state = states[stateIndex],
                    value = [theme valueForAttributeWithName:attributeName inState:state forClass:className],
                    description = valueDescription(value).replace(/^/mg, "      ");

                colorPrint("cyan", "   " + CPThemeStateName(state));
                print(description + "\n");
            }
        }

        print("");
    }
}

function valueDescription(aValue)
{
    var description = "";

    if (!aValue)
        return "<null>";

    if (!aValue.isa)
    {
        if (typeof(aValue) === "object")
        {
            if (aValue.hasOwnProperty("width") && aValue.hasOwnProperty("height"))
                description = [CPString stringWithFormat:@"CGSize: { width:%f, height:%f }", aValue.width, aValue.height];
            else if (aValue.hasOwnProperty("x") && aValue.hasOwnProperty("y"))
                description = [CPString stringWithFormat:@"CGPoint: { x:%f, y:%f }", aValue.x, aValue.y];
            else if (aValue.hasOwnProperty("origin") && aValue.hasOwnProperty("size"))
                description = [CPString stringWithFormat:@"CGRect: { x:%f, y:%f }, { width:%f, height:%f }", aValue.origin.x, aValue.origin.y, aValue.size.width, aValue.size.height];
            else if (aValue.hasOwnProperty("top") && aValue.hasOwnProperty("right") && aValue.hasOwnProperty("bottom") && aValue.hasOwnProperty("left"))
                description = [CPString stringWithFormat:@"CGInset: { top:%f, right:%f, bottom:%f, left:%f }", aValue.top, aValue.right, aValue.bottom, aValue.left];
            else
            {
                description = "Object\n{\n";

                for (var property in aValue)
                {
                    if (aValue.hasOwnProperty(property))
                        description += "   " + property + ":" + aValue[property] + "\n";
                }

                description += "}";
            }
        }
        else
            description = "Unknown object";
    }
    else if ([aValue isKindOfClass:[CPImage class]] || [aValue isKindOfClass:[_CPCibCustomResource class]])
        description = imageDescription(aValue);
    else if ([aValue isKindOfClass:[CPColor class]])
        description = colorDescription(aValue);
    else
        description = [aValue description];

    return description;
}

function imageDescription(anImage)
{
    var filename = [anImage filename],
        size = [anImage size];

    if (filename.indexOf("data:") === 0)
    {
        var index = filename.indexOf(",");

        if (index > 0)
            filename = [CPString stringWithFormat:@"%s,%s...%s", filename.substr(0, index), filename.substr(index + 1, 10), filename.substr(filename.length - 10)];
        else
            filename = "data:<unknown type>";
    }

    return [CPString stringWithFormat:ImageDescriptionFormat, [anImage className], filename, size.width, size.height];
}

function colorDescription(aColor)
{
    var patternImage = [aColor patternImage];

    if (!patternImage || !([patternImage isThreePartImage] || [patternImage isNinePartImage]))
        return [aColor description];

    var description = "<CPColor> {\n",
        slices = [patternImage imageSlices];

    if ([patternImage isThreePartImage])
        description += "   orientation: " + ([patternImage isVertical] ? "vertical" : "horizontal") + ",\n";

    description += "   patternImage: [\n";

    for (var i = 0; i < slices.length; ++i)
    {
        var imgDescription = imageDescription(slices[i]);

        description += imgDescription.replace(/^/mg, "      ") + ",\n";
    }

    description = description.substr(0, description.length - 2) + "\n   ]\n}";
    return description;
}

function getDefaultThemeName()
{
    var themeName = nil,
        cappBuild = SYS.env["CAPP_BUILD"];

    if (cappBuild)
    {
        for (var i = 0; i < BuildTypes.length; ++i)
        {
            var path = FILE.join(cappBuild, BuildTypes[i], "AppKit", "Info.plist");
            themeName = themeNameFromPropertyList(path);

            if (themeName)
                break;
        }
    }

    return themeName || DefaultTheme;
}

function themeNameFromPropertyList(path)
{
    if (!FILE.exists(path))
        return nil;

    var themeName = nil,
        plist = CFPropertyList.readPropertyListFromFile(path);

    if (plist)
        themeName = plist.valueForKey("CPDefaultTheme");

    return themeName;
}

function loadTheme(themeName, themeDir)
{
    if (!themeDir)
    {
        cappBuild = SYS.env["CAPP_BUILD"];

        if (!cappBuild)
            fail("Could not find $CAPP_BUILD, exiting.");

        var baseThemeName = themeName,
            pos = themeName.indexOf("-");

        if (pos > 0)
            baseThemeName = themeName.substr(0, pos);

        themeDir = FILE.join(cappBuild, baseThemeName + ".build");
    }

    if (!FILE.isDirectory(themeDir))
        fail("No such directory: " + themeDir);

    var themePath = null;

    for (var i = 0; i < BuildTypes.length; ++i)
    {
        var path = FILE.join(themeDir, BuildTypes[i], "Browser.environment/Resources", themeName + ".keyedtheme");

        if (FILE.exists(path))
        {
            themePath = path;
            break;
        }
    }

    if (!themePath)
        fail("Could not find the keyed theme data for: " + themeName);

    var plist = FILE.read(themePath);

    if (!plist)
        fail("Could not read the keyed theme at: " + themePath);

    // The .keyedtheme file has a header that is data I don't need. Strip it off.
    var m = plist.match(/^t;\d+;/);

    if (!m || m.length === 0)
        fail("Invalid keyed theme data at: " + themePath);

    plist = plist.substr(m[0].length);
    plist = CFPropertyList.propertyListFromString(plist);

    var data = [CPData dataWithPlistObject:plist],
        theme = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    if (!theme)
        fail("Could not unarchive the theme at: " + themePath);

    colorPrint("purple", "Loaded theme: " + themePath + "\n");
    return theme;
}

function colorPrint(color, message)
{
    stream.print("\0bold(\0" + color + "(" + message + "\0)\0)");
}

function fail(message)
{
    stream.print("\0red(" + message + "\0)");
    OS.exit(1);
}
