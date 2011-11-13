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
    stream = require("narwhal/term").stream,

    parser = new (require("narwhal/args").Parser)(),
    options = null,

    ImageDescriptionFormat = "<%s> {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}";


function main(args)
{
    parseArgs(args);

    var themeName = options.args[0] || "",
        themeDir = "";

    if (themeName && (themeName.lastIndexOf(".blend") === (themeName.length - ".blend".length)))
    {
        themeDir = FILE.canonical(FILE.dirname(themeName));
        themeName = FILE.basename(themeName, FILE.extension(themeName));
    }

    themeName = themeName || getAppKitDefaultThemeName();

    if (!themeName)
        fail("Could not determine the theme name.");

    colorPrint("purple", "Theme name: " + themeName);

    var theme = loadTheme(themeName, themeDir);

    if (!theme)
        fail("Could not load the theme \"" + themeName + "\"");

    dumpTheme(theme);
}

function parseArgs(args)
{
    parser.usage("[--no-color] [NAME_OR_BLEND_PATH]");

    parser.option("--no-color", "colorize")
        .set(false)
        .def(true)
        .help("Colorize the output. Should only be used when dumping to the terminal.");

    parser.helpful();

    options = parser.parse(args, null, null, true);

    if (options.args.length > 1)
    {
        parser.printUsage(options);
        OS.exit(0);
    }
}

function dumpTheme(theme)
{
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
                stream.print(description + "\n");
            }
        }

        stream.print("");
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

// Returns undefined if $CAPP_BUILD is not defined, false if path cannot be found in $CAPP_BUILD
function findInCappBuild(path, isDirectory, callback)
{
    var cappBuild = SYS.env["CAPP_BUILD"];

    if (!cappBuild)
        return undefined;

    cappBuild = FILE.canonical(cappBuild);

    if (FILE.isDirectory(cappBuild))
    {
        var result = null;

        for (var i = 0; i < BuildTypes.length && !result; ++i)
        {
            var findPath = FILE.join(cappBuild, BuildTypes[i], path);

            if ((isDirectory && FILE.isDirectory(findPath)) || (!isDirectory && FILE.exists(findPath)))
                result = callback(findPath);
        }

        return result;
    }
    else
        return false;
}

function findInInstalledFrameworks(path, isDirectory, callback)
{
    // NOTE: It's safe to use '/' directly in the path, we're guaranteed to be on a Mac
    var frameworks = FILE.canonical(FILE.join(SYS.prefix, "packages/cappuccino/Frameworks")),
        result = null,
        findPath = FILE.join(frameworks, "Debug", path);

    if ((isDirectory && FILE.isDirectory(findPath)) || (!isDirectory && FILE.exists(findPath)))
        result = callback(findPath);

    if (!result)
    {
        findPath = FILE.join(frameworks, path);

        if ((isDirectory && FILE.isDirectory(findPath)) || (!isDirectory && FILE.exists(findPath)))
            result = callback(findPath);
    }

    return result;
}

function getAppKitDefaultThemeName()
{
    var callback = function(path) { return themeNameFromPropertyList(path); },
        themeName = findInCappBuild("AppKit/Info.plist", false, callback);

    if (!themeName)
        themeName = findInInstalledFrameworks("AppKit/Info.plist", false, callback);

    return themeName || DefaultTheme;
}

function themeNameFromPropertyList(path)
{
    if (!FILE.isReadable(path))
        return nil;

    var themeName = nil,
        plist = CFPropertyList.readPropertyListFromFile(path);

    if (plist)
        themeName = plist.valueForKey("CPDefaultTheme");

    return themeName;
}

function loadTheme(themeName, themeDir)
{
    if (/^.+\.blend$/.test(themeName))
        themeName = themeName.substr(0, themeName.length - ".blend".length);

    var blendName = themeName + ".blend",
        themePath = "";

    if (themeDir)
    {
        themePath = FILE.join(FILE.canonical(themeDir), blendName);

        if (!FILE.isDirectory(themePath))
            themePath = themeDir = null;
    }

    if (!themeDir)
    {
        var returnPath = function(path) { return path; };

        themePath = findInCappBuild(blendName, true, returnPath);

        if (!themePath)
            themePath = findInInstalledFrameworks("AppKit/Resources/" + blendName, true, returnPath);

        // Last resort, try the cwd
        if (!themePath)
        {
            var path = FILE.canonical(blendName);

            if (FILE.isDirectory(path))
                themePath = path;
        }
    }

    if (!themePath)
        fail('Cannot find the theme "' + themeName + '"');

    return readTheme(themeName, themePath);
}

function readTheme(themeName, themePath)
{
    var keyedTheme = null,
        staticData = FILE.read(FILE.join(themePath, "Browser.Environment", FILE.basename(themePath) + ".sj"));

    if (!staticData)
        fail("Could not find the theme file: " + themePath);

    try
    {
        keyedTheme = readStaticResource(themeName + ".keyedtheme", staticData);

        if (!keyedTheme)
            fail("Could not find the keyed theme data in the theme at: " + themePath);
    }
    catch (ex)
    {
        fail("Could not read the theme at: " + themePath);
    }

    keyedTheme = CFPropertyList.propertyListFromString(keyedTheme);

    var data = [CPData dataWithPlistObject:keyedTheme],
        theme = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    if (!theme)
        fail("Could not unarchive the theme at: " + themePath);

    colorPrint("purple", "Loaded theme: " + themePath + "\n");

    return theme;
}

// Skip the static data header
var mark = "@STATIC;".length;

function readStaticResource(name, staticData)
{
    name = "Resources/" + name;

    // After the header is the version
    var version = readFloatItem(staticData);

    while (true)
    {
        var resourceName = readStringItem(staticData);

        mark += 2;  // skip "t;"

        var resourceLength = readIntItem(staticData);

        if (resourceName == name)
            return readDataItem(staticData, resourceLength);

        mark += resourceLength;

        if (staticData.substr(mark, 2) == "e;")
            return null;
    }
}

function readIntItem(staticData)
{
    var endPos = endOfItem(staticData),
        value = parseInt(staticData.substring(mark, endPos), 10);

    mark = endPos + 1;

    return value;
}

function readFloatItem(staticData)
{
    var endPos = endOfItem(staticData),
        value = parseFloat(staticData.substring(mark, endPos));

    mark = endPos + 1;

    return value;
}

function readStringItem(staticData)
{
    if (staticData.substr(mark, 2) !== "p;")
        throw "Expected string item, found '" + staticData.substr(mark, 2) + "'";

    mark += 2;  // skip "p;"

    var length = readIntItem(staticData),
        value = staticData.substr(mark, length);

    mark += length;

    return value;
}

function endOfItem(staticData)
{
    var endPos = staticData.indexOf(";", mark);

    if (endPos < 0)
        throw "Could not find item terminator";

    return endPos;
}

function readDataItem(staticData, dataLength)
{
    var data = staticData.substr(mark, dataLength);

    mark += dataLength;

    return data;
}

function colorPrint(color, message)
{
    if (options.colorize)
        stream.print("\0bold(\0" + color + "(" + message + "\0)\0)");
    else
        stream.print(message);
}

function fail(message)
{
    colorPrint("red", message);
    OS.exit(1);
}
