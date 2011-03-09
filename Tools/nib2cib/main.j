/*
 * main.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "NSFoundation.j"
@import "NSAppKit.j"

@import "Nib2CibKeyedUnarchiver.j"
@import "Converter.j"

var FILE = require("file"),
    OS = require("os"),
    SYS = require("system"),

    DefaultTheme = "Aristo",
    BuildTypes = ["Debug", "Release"];

var parser = new (require("narwhal/args").Parser)();

parser.usage("INPUT_FILE [OUTPUT_FILE]");

parser.option("-F", "framework", "frameworks")
    .push()
    .help("Add a framework to load");

parser.option("-R", "resources")
    .set()
    .help("Set the Resources directory");

parser.option("--mac", "format")
    .set(NibFormatMac)
    .def(NibFormatUndetermined)
    .help("Set format to Mac");

parser.option("--legacy", "conversionMode")
    .set(ConverterModeLegacy)
    .def(ConverterModeNew)
    .help("Use legacy code that does not preserve view positioning/sizing");

parser.option("-t", "--theme-dir", "themeDir")
    .set()
    .help("A <theme>.build directory to use for theme attribute values");

parser.option("--config", "configFile")
    .set()
    .help("A path to an Info.plist file from which the system font and/or size can be retrieved");

// parser.option("--iphone", "format")
//     .set(NibFormatIPhone)
//     .help("Set format to iPhone");

parser.option("-v", "--verbose", "verbose")
    .inc()
    .help("Increase verbosity level");

parser.option("-q", "--quiet", "quiet")
    .set(true)
    .help("No output");

parser.option("--version", "showVersion")
    .set(true)
    .help("Show the version of nib2cib and quit");

parser.helpful();

function loadFrameworks(frameworkPaths, aCallback)
{
    if (!frameworkPaths || frameworkPaths.length === 0)
        return aCallback();

    frameworkPaths.forEach(function(aFrameworkPath)
    {
        print("Loading " + aFrameworkPath);

        var frameworkBundle = [[CPBundle alloc] initWithPath:aFrameworkPath];

        [frameworkBundle loadWithDelegate:nil];

        require("browser/timeout").serviceTimeouts();
    });

    aCallback();
}

function logFormatter(aString, aLevel, aTitle)
{
    return CPLogColorize(aString, aLevel);
}

function main(args)
{
    var options = parser.parse(args, null, null, true);

    if (options.args.length > 2)
    {
        parser.printUsage(options);
        OS.exit(0);
    }

    if (options.quiet) {}
    else if (options.verbose === 0)
        CPLogRegister(CPLogPrint, "warn", logFormatter);
    else if (options.verbose === 1)
        CPLogRegister(CPLogPrint, "info", logFormatter);
    else
        CPLogRegister(CPLogPrint, null, logFormatter);

    if (!options.quiet && options.verbose > 0)
        printVersion(options.showVersion);

    var inputFile = options.args[0];

    if (!FILE.exists(inputFile))
        fail("No such file: " + FILE.canonical(inputFile));

    if (options.layoutMode === ConverterModeNew && !haveFontInfo())
        fail("The fontinfo package is not installed, please install it.");

    var configPath = setSystemFontAndSize(options.configFile || "", inputFile),
        themeName = "",
        themeDir = options.themeDir || "";

    if (themeDir)
        themeName = FILE.basename(themeDir, FILE.extension(themeDir));

    themeName = themeName || getDefaultThemeName();

    if (!themeName)
        fail("Could not determine the theme name.");

    var theme = loadTheme(themeName, themeDir);

    CPLog.info("\n-------------------------------------------------------------");
    CPLog.info("Input       : " + FILE.canonical(inputFile));
    CPLog.info("Output      : " + (options.args[1] || ""));
    CPLog.info("Format      : " + ["Auto", "Mac", "iPhone"][options.format]);
    CPLog.info("Resources   : " + (options.resources || ""));
    CPLog.info("Frameworks  : " + options.frameworks);
    CPLog.info("Layout Mode : " + (options.layoutMode === ConverterModeLegacy ? "legacy" : "new"));
    CPLog.info("Theme       : " + themeName);
    CPLog.info("Config file : " + (configPath || ""));
    CPLog.info("System Font : " + [CPFont systemFontSize] + "px " + [CPFont systemFontFace]);
    CPLog.info("-------------------------------------------------------------\n");

    var converter = [[Converter alloc] initWithInputPath:inputFile
                                                  format:options.format
                                              layoutMode:options.layoutMode
                                                   theme:theme];

    if (options.resources)
        [converter setResourcesPath:options.resources];

    if (options.args.length > 1)
        [converter setOutputPath:options.args[1]];

    loadFrameworks(options.frameworks, function()
    {
        [converter convert];
    });
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
        fail("No such theme directory: " + themeDir);

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

    themePath = FILE.canonical(themePath);
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

    CPLog.debug("Loaded theme: " + themePath);
    return theme;
}

function haveFontInfo()
{
    try
    {
        var fontinfo = require("fontinfo").fontinfo;
    }
    catch (e)
    {
        return false;
    }

    return true;
}

function setSystemFontAndSize(configFile, inputFile)
{
    var configPath = null;

    // First see if the user passed a config file path
    if (configFile)
    {
        var path = FILE.canonical(configFile);

        if (!FILE.exists(path))
            fail("Cannot find the config file: " + path);

        configPath = path;
    }
    else
    {
        // See if we can find an Info.plist in the parent directory of the input file,
        // if the input file's directory is "Resources".
        var path = FILE.canonical(FILE.dirname(inputFile));

        if (FILE.basename(path) === "Resources")
        {
            path = FILE.join(FILE.dirname(path), "Info.plist");

            if (FILE.exists(path))
                configPath = path;
        }
    }

    if (configPath)
    {
        var plist = FILE.read(configPath);

        if (!plist)
            fail("Could not read the Info.plist at: " + configPath);

        plist = CFPropertyList.propertyListFromString(plist);

        if (!plist)
            fail("Could not parse the Info.plist at: " + configPath);

        var systemFontFace = plist.valueForKey("CPSystemFontFace");

        if (systemFontFace)
            [CPFont setSystemFontFace:systemFontFace];

        var systemFontSize = plist.valueForKey("CPSystemFontSize");

        if (systemFontSize)
            [CPFont setSystemFontSize:parseFloat(systemFontSize, 10)];
    }

    return configPath;
}

function printVersion(exitAfter)
{
    // SYS.args[0] has the path to the nib2cib binary, from that we can get
    // to the lib/nib2cib directory which the Info.plist for nib2cib.
    var path = FILE.dirname(FILE.dirname(SYS.args[0]));

    if (FILE.basename(path) === "narwhal")
        path = FILE.join(path, "packages", "cappuccino");

    path = FILE.join(path, "lib", "nib2cib", "Info.plist");

    if (FILE.exists(path))
    {
        var plist = FILE.read(path);

        if (!plist)
            return;

        plist = CFPropertyList.propertyListFromString(plist);

        if (!plist)
            return;

        var version = plist.valueForKey("CPBundleVersion");

        if (version)
            print("nib2cib v" + version);
    }

    if (exitAfter)
        OS.exit(0);
}

function fail(message)
{
    CPLog.error(message);
    OS.exit(1);
}
