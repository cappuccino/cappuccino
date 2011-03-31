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
    FileList = require("jake").FileList,
    stream = require("narwhal/term").stream,

    DefaultTheme = "Aristo",
    BuildTypes = ["Debug", "Release"],
    DefaultXibFile = "MainMenu.xib";

var parser = new (require("narwhal/args").Parser)(),
    nibInfo = {};


function main(args)
{
    try
    {
        var options = parseOptions(args);

        if (options.watch)
            watch(options);
        else
            convert(options);
    }
    catch (anException)
    {
        CPLog.fatal([anException reason]);
        OS.exit(1);
    }
}

function convert(options, inputFile)
{
    try
    {
        inputFile = inputFile || getInputFile(options.args);

        var outputFile = getOutputFile(inputFile, options.args),
            resourcesPath = "";

        if (options.resources)
        {
            resourcesPath = FILE.canonical(options.resources);

            if (!FILE.isDirectory(resourcesPath) || !FILE.isReadable(resourcesPath))
                fail("Cannot read resources at: " + resourcesPath);
        }

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
        CPLog.info("Input       : " + inputFile);
        CPLog.info("Output      : " + outputFile);
        CPLog.info("Format      : " + ["Auto", "Mac", "iPhone"][options.format]);
        CPLog.info("Resources   : " + resourcesPath);
        CPLog.info("Frameworks  : " + (options.frameworks || ""));
        CPLog.info("Theme       : " + themeName);
        CPLog.info("Config file : " + (configPath || ""));
        CPLog.info("System Font : " + [CPFont systemFontSize] + "px " + [CPFont systemFontFace]);
        CPLog.info("-------------------------------------------------------------\n");

        var converter = [[Converter alloc] initWithInputPath:inputFile
                                                      format:options.format
                                                       theme:theme];

        [converter setOutputPath:outputFile];
        [converter setResourcesPath:resourcesPath];

        loadFrameworks(options.frameworks, function()
        {
            [converter convert];
        });

        return true;
    }
    catch (anException)
    {
        CPLog.fatal([anException reason]);
        return false;
    }
}

function watch(options)
{
    var verbosity = options.quiet ? -1 : options.verbosity;

    // Turn on info messages
    setLogLevel(1);

    directory = FILE.canonical(options.args[0] || "Resources");

    if (!FILE.isDirectory(directory))
        fail("Cannot find the directory: " + directory);

    CPLog.info("Watching: " + CPLogColorize(directory, "debug"));
    CPLog.info("Press Control-C to stop...");

    while (true)
    {
        var modifiedNibs = getModifiedNibs(directory);

        for (var i = 0; i < modifiedNibs.length; ++i)
        {
            var action = modifiedNibs[i][0],
                path = modifiedNibs[i][1],
                label = action === "add" ? "Added:" : "Modified:",
                level = action === "add" ? "info" : "debug";

            CPLog.info(">> %s %s", CPLogColorize(label, level), path);

            // Let the converter log however the user configured it
            setLogLevel(verbosity);

            var success = convert(options, path);

            setLogLevel(1);

            if (success)
            {
                if (verbosity > 0)
                    stream.print();
                else
                    CPLog.warn("Conversion successful");
            }
        }

        OS.sleep(1);
    }
}

function parseOptions(args)
{
    parser.usage("[--watch DIRECTORY] [INPUT_FILE [OUTPUT_FILE]]");

    parser.option("--watch", "watch")
        .set(true)
        .help("Ask nib2cib to watch a directory for changes");

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

    parser.option("-t", "--theme-dir", "themeDir")
        .set()
        .help("A <theme>.build directory to use for theme attribute values");

    parser.option("--config", "configFile")
        .set()
        .help("A path to an Info.plist file from which the system font and/or size can be retrieved");

    // parser.option("--iphone", "format")
    //     .set(NibFormatIPhone)
    //     .help("Set format to iPhone");

    parser.option("-v", "--verbose", "verbosity")
        .inc()
        .help("Increase verbosity level");

    parser.option("-q", "--quiet", "quiet")
        .set(true)
        .help("No output");

    parser.option("--version", "showVersion")
        .action(printVersionAndExit)
        .help("Show the version of nib2cib and quit");

    parser.helpful();

    var options = parser.parse(args, null, null, true);

    if (options.args.length > 2)
    {
        parser.printUsage(options);
        OS.exit(0);
    }

    setLogLevel(options.quiet ? -1 : options.verbosity);

    if (!options.quiet && options.verbosity > 0)
        printVersion();

    return options;
}

function setLogLevel(level)
{
    CPLogUnregister(CPLogPrint);

    if (level === 0)
        CPLogRegister(CPLogPrint, "warn", logFormatter);
    else if (level === 1)
        CPLogRegister(CPLogPrint, "info", logFormatter);
    else if (level > 1)
        CPLogRegister(CPLogPrint, null, logFormatter);
}

function getInputFile(args)
{
    var inputFile = args[0] || DefaultXibFile;

    if (!/^.+\.xib$/.test(inputFile))
        inputFile += ".xib";

    inputFile = FILE.canonical(inputFile);

    if (!FILE.exists(inputFile) && FILE.basename(FILE.dirname(inputFile)) !== "Resources")
        if (FILE.isDirectory("Resources"))
            inputFile = FILE.resolve(inputFile, FILE.join("Resources", FILE.basename(inputFile)));

    if (!FILE.isReadable(inputFile))
        fail("Cannot read the input file: " + inputFile);

    return inputFile;
}

function getOutputFile(inputFile, args)
{
    var outputFile = null;

    if (args.length > 1)
        outputFile = args[1];
    else
        outputFile = FILE.basename(inputFile, FILE.extension(inputFile));

    if (!/^.+\.cib$/.test(outputFile))
        outputFile += ".cib";

    outputFile = FILE.resolve(inputFile, outputFile);

    if (!FILE.isWritable(FILE.dirname(outputFile)))
        fail("Cannot write the output file at: " + outputFile);

    return outputFile;
}

function loadFrameworks(frameworkPaths, aCallback)
{
    if (!frameworkPaths || frameworkPaths.length === 0)
        return aCallback();

    frameworkPaths.forEach(function(aFrameworkPath)
    {
        CPLog.info("Loading " + aFrameworkPath);

        var frameworkBundle = [[CPBundle alloc] initWithPath:aFrameworkPath];

        [frameworkBundle loadWithDelegate:nil];

        require("browser/timeout").serviceTimeouts();
    });

    aCallback();
}

function logFormatter(aString, aLevel, aTitle)
{
    if (aLevel === "info")
        return aString;
    else
        return CPLogColorize(aString, aLevel);
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
    if (!themeDir)
    {
        cappBuild = SYS.env["CAPP_BUILD"];

        if (!cappBuild)
            fail("$CAPP_BUILD is not set, exiting.");

        if (!FILE.isDirectory(cappBuild))
            fail("$CAPP_BUILD does not exist: " + cappBuild)

        var baseThemeName = themeName,
            pos = themeName.indexOf("-");

        if (pos > 0)
            baseThemeName = themeName.substr(0, pos);

        themeDir = FILE.join(cappBuild, baseThemeName + ".build");
    }

    themeDir = FILE.canonical(themeDir);

    if (!FILE.isDirectory(themeDir))
        fail("Cannot find the theme directory: " + themeDir);

    var themePath = null;

    for (var i = 0; i < BuildTypes.length; ++i)
    {
        var path = FILE.join(themeDir, BuildTypes[i], "Browser.environment/Resources", themeName + ".keyedtheme");

        if (FILE.isReadable(path))
        {
            themePath = path;
            break;
        }
    }

    if (!themePath)
        fail("Could not find the keyed theme data for \"" + themeName + "\" in the directory: " + themeDir);

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

function setSystemFontAndSize(configFile, inputFile)
{
    var configPath = null;

    // First see if the user passed a config file path
    if (configFile)
    {
        var path = FILE.canonical(configFile);

        if (!FILE.isReadable(path))
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

            if (FILE.isReadable(path))
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

function getModifiedNibs(path)
{
    var nibs = new FileList(FILE.join(path, "*.xib")).items(),
        count = nibs.length,
        newNibInfo = {},
        modifiedNibs = [];

    while (count--)
    {
        var nib = nibs[count];

        newNibInfo[nib] = FILE.mtime(nib);

        if (!nibInfo.hasOwnProperty(nib))
            modifiedNibs.push(["add", nib]);
        else
        {
            if (newNibInfo[nib] - nibInfo[nib] !== 0)
                modifiedNibs.push(["mod", nib]);

            // Remove matching nibs so that we leave
            // deleted nibs in nibInfo.
            delete nibInfo[nib];
        }
    }

    for (var nib in nibInfo)
    {
        if (nibInfo.hasOwnProperty(nib))
            CPLog.info(">> %s %s", CPLogColorize("Deleted:", "warn"), nib);
    }

    nibInfo = newNibInfo;

    return modifiedNibs;
}

function printVersionAndExit()
{
    printVersion();
    OS.exit(0);
}

function printVersion()
{
    /*
        There are two usual possibilities for the location of the nib2cib binary.
        If we are executing the installed narwhal binary, the location is:
            <narwhal>/packages/cappuccino/bin/nib2cib
        If we are executing the built binary, the location is:
            <CAPP_BUILD>/Debug|Release/CommonJS/cappuccino/bin/nib2cib

        Base on these paths we can locate nib2cib's Info.plist.
    */
    var path = FILE.dirname(FILE.dirname(FILE.canonical(SYS.args[0]))),
        version = null;

    if (FILE.basename(path) === "narwhal")
        path = FILE.join(path, "packages", "cappuccino");

    path = FILE.join(path, "lib", "nib2cib", "Info.plist");

    if (FILE.isReadable(path))
    {
        var plist = FILE.read(path);

        if (!plist)
            return;

        plist = CFPropertyList.propertyListFromString(plist);

        if (!plist)
            return;

        version = plist.valueForKey("CPBundleVersion");

        if (version)
            stream.print("nib2cib v" + version);
    }

    if (!version)
        stream.print("<No version info available>");
}

function fail(message)
{
    [CPException raise:ConverterConversionException reason:message];
}
