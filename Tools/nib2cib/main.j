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
    StaticResource = require("objective-j").StaticResource,

    DefaultTheme = "Aristo",
    BuildTypes = ["Debug", "Release"],
    DefaultFile = "MainMenu";

var parser = new (require("narwhal/args").Parser)(),
    nibInfo = {},
    appDirectory = "",
    resourcesDirectory = "";


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
        CPLog.fatal(exceptionReason(anException));
        OS.exit(1);
    }
}

function convert(options, inputFile)
{
    try
    {
        inputFile = inputFile || getInputFile(options.args);

        getAppAndResourceDirectoriesFromInputFile(inputFile, options);

        var outputFile = getOutputFile(inputFile, options.args),
            configInfo = readConfigFile(options.configFile || "", inputFile),
            defaultTheme = null;

        if (configInfo.plist)
        {
            var systemFontFace = configInfo.plist.valueForKey("CPSystemFontFace");

            if (systemFontFace)
                [CPFont setSystemFontFace:systemFontFace];

            var systemFontSize = configInfo.plist.valueForKey("CPSystemFontSize");

            if (systemFontSize)
                [CPFont setSystemFontSize:parseFloat(systemFontSize, 10)];

            if (!options.defaultTheme)
                defaultTheme = configInfo.plist.valueForKey("CPDefaultTheme");
        }

        var themeList = getThemeList(defaultTheme || options.defaultTheme, options),
            themes = loadThemes(themeList);

        CPLog.info("\n-------------------------------------------------------------");
        CPLog.info("Input         : " + inputFile);
        CPLog.info("Output        : " + outputFile);
        CPLog.info("Format        : " + ["Auto", "Mac", "iPhone"][options.format]);
        CPLog.info("Application   : " + appDirectory);
        CPLog.info("Resources     : " + resourcesDirectory);
        CPLog.info("Frameworks    : " + (options.frameworks || ""));
        CPLog.info("Default theme : " + themeList[0]);
        CPLog.info("Extra themes  : " + themeList.slice(1).join(", "));
        CPLog.info("Config file   : " + (configInfo.path || ""));
        CPLog.info("System Font   : " + [CPFont systemFontSize] + "px " + [CPFont systemFontFace]);
        CPLog.info("-------------------------------------------------------------\n");

        var converter = [[Converter alloc] initWithInputPath:inputFile
                                                      format:options.format
                                                      themes:themes];

        [converter setOutputPath:outputFile];
        [converter setResourcesPath:resourcesDirectory];

        loadFrameworks(options.frameworks, options.verbosity, function()
        {
            [converter convert];
        });

        return true;
    }
    catch (anException)
    {
        CPLog.fatal(exceptionReason(anException));
        return false;
    }
}

function watch(options)
{
    var verbosity = options.quiet ? -1 : options.verbosity,
        watchDir = options.args[0];

    if (!watchDir)
        watchDir = FILE.canonical(FILE.isDirectory("Resources") ? "Resources" : ".");
    else
    {
        watchDir = FILE.canonical(watchDir);

        if (FILE.basename(watchDir) !== "Resources")
        {
            var path = FILE.join(watchDir, "Resources");

            if (FILE.isDirectory(path))
                watchDir = path;
        }
    }

    if (!FILE.isDirectory(watchDir))
        fail("Cannot find the directory: " + watchDir);

    // Turn on info messages
    setLogLevel(1);

    var nibs = new FileList(FILE.join(watchDir, "*.[nx]ib")).items(),
        count = nibs.length;

    // First time through only IB files with no corresponding cib
    // or a cib with an earlier or equal mtime are converted.
    while (count--)
    {
        var nib = nibs[count],
            cib = nib.substr(0, nib.length - 4) + ".cib";

        if (FILE.exists(cib) && (FILE.mtime(nib) - FILE.mtime(cib)) <= 0)
            nibInfo[nib] = FILE.mtime(nib);
    }

    CPLog.info("Watching: " + CPLogColorize(watchDir, "debug"));
    CPLog.info("Press Control-C to stop...");

    while (true)
    {
        var modifiedNibs = getModifiedNibs(watchDir);

        for (var i = 0; i < modifiedNibs.length; ++i)
        {
            var action = modifiedNibs[i][0],
                nib = modifiedNibs[i][1],
                label = action === "add" ? "Added" : "Modified",
                level = action === "add" ? "info" : "debug";

            CPLog.info(">> %s: %s", CPLogColorize(label, level), nib);

            // Don't convert an add if there is an existing cib with a later mtime
            if (action === "add")
            {
                var cib = nib.substr(0, nib.length - 4) + ".cib";

                if (FILE.exists(cib) && (FILE.mtime(nib) - FILE.mtime(cib)) < 0)
                    continue;
            }

            // Let the converter log however the user configured it
            setLogLevel(verbosity);

            var success = convert(options, nib);

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

    parser.option("-R", "resourcesDir")
        .set()
        .displayName("directory")
        .help("Set the Resources directory, usually unnecessary as it is inferred from the input path");

    parser.option("--default-theme", "defaultTheme")
        .set()
        .displayName("name")
        .help("Specify a custom default theme which is not set in your Info.plist");

    parser.option("-t", "--theme", "extraThemes")
        .push()
        .displayName("name")
        .help("An additional theme loaded dynamically by your application");

    parser.option("--config", "configFile")
        .set()
        .displayName("path")
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

    parser.option("-F", "framework", "frameworks")
        .push()
        .help("Add a framework to load");

    parser.option("--mac", "format")
        .set(NibFormatMac)
        .def(NibFormatUndetermined)
        .help("Set format to Mac");

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
    var inputFile = args[0] || DefaultFile,
        path = "";

    if (!/^.+\.[nx]ib$/.test(inputFile))
    {
        if (path = findInputFile(inputFile, ".xib"))
            inputFile = path;
        else if (path = findInputFile(inputFile, ".nib"))
            inputFile = path;
        else
            fail("Cannot find the input file (.xib or .nib): " + FILE.canonical(inputFile));
    }
    else if (path = findInputFile(inputFile))
        inputFile = path;
    else
        fail("Could not read the input file: " + FILE.canonical(inputFile));

    return FILE.canonical(inputFile);
}

function findInputFile(inputFile, extension)
{
    var path = inputFile;

    if (extension)
        path += extension;

    if (FILE.isReadable(path))
        return path;

    if (FILE.basename(FILE.dirname(inputFile)) !== "Resources" && FILE.isDirectory("Resources"))
    {
        path = FILE.resolve(path, FILE.join("Resources", FILE.basename(path)));

        if (FILE.isReadable(path))
            return path;
    }

    return null;
}

function getAppAndResourceDirectoriesFromInputFile(inputFile, options)
{
    appDirectory = resourcesDirectory = "";

    if (options.resourcesDir)
    {
        var path = FILE.canonical(options.resourcesDir);

        if (!FILE.isDirectory(path))
            fail("Cannot read resources at: " + path);

        resourcesDirectory = path;
    }

    var parentDir = FILE.dirname(inputFile);

    if (FILE.basename(parentDir) === "Resources")
    {
        appDirectory = FILE.dirname(parentDir);
        resourcesDirectory = resourcesDirectory || parentDir;
    }
    else
    {
        appDirectory = parentDir;

        if (!resourcesDirectory)
        {
            var path = FILE.join(appDirectory, "Resources");

            if (FILE.isDirectory(path))
                resourcesDirectory = path;
        }
    }
}

function getOutputFile(inputFile, args)
{
    var outputFile = null;

    if (args.length > 1)
    {
        outputFile = args[1];

        if (!/^.+\.cib$/.test(outputFile))
            outputFile += ".cib";
    }
    else
        outputFile = FILE.join(FILE.dirname(inputFile), FILE.basename(inputFile, FILE.extension(inputFile))) + ".cib";

    outputFile = FILE.canonical(outputFile);

    if (!FILE.isWritable(FILE.dirname(outputFile)))
        fail("Cannot write the output file at: " + outputFile);

    return outputFile;
}

function loadFrameworks(frameworkPaths, verbosity, aCallback)
{
    if (!frameworkPaths || frameworkPaths.length === 0)
        return aCallback();

    frameworkPaths.forEach(function(aFrameworkPath)
    {
        setLogLevel(verbosity);
        CPLog.info("Loading " + aFrameworkPath);

        try
        {
            // CPBundle is a bit loquacious with logging, we will defer
            // logging its exceptions till later.
            setLogLevel(-1);

            var frameworkBundle = [[CPBundle alloc] initWithPath:aFrameworkPath];

            [frameworkBundle loadWithDelegate:nil];
        }
        finally
        {
            setLogLevel(verbosity);
        }

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

function getThemeList(defaultTheme, options)
{
    var themes = [defaultTheme || getAppKitDefaultThemeName()];

    if (options.extraThemes)
        for (var i = 0; i < options.extraThemes.length; ++i)
            if (themes.indexOf(options.extraThemes[i]) < 0)
                themes.push(options.extraThemes[i]);

    return themes;
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

function loadThemes(themeList)
{
    var themes = [];

    for (var i = 0; i < themeList.length; ++i)
        themes.push(loadTheme(themeList[i], resourcesDirectory));

    return themes;
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

function readTheme(name, path)
{
    var themeBundle = new CFBundle(path);

    // By default when we try to load the bundle it will use the CommonJS environment,
    // but we want the Browser environment. So we override mostEligibleEnvironment().
    themeBundle.mostEligibleEnvironment = function() { return "Browser"; }
    themeBundle.load();

    var keyedThemes = themeBundle.valueForInfoDictionaryKey("CPKeyedThemes");

    if (!keyedThemes)
        fail("Could not find the keyed themes in the theme: " + path);

    var index = keyedThemes.indexOf(name + ".keyedtheme");

    if (index < 0)
        fail("Could not find the main theme data (" + name + ".keyedtheme" + ") in the theme: " + path);

    // Load the keyed theme data, making sure to resolve it
    var resourcePath = themeBundle.pathForResource(keyedThemes[index]),
        themeData = new CFMutableData();

    themeData.setRawString(StaticResource.resourceAtURL(new CFURL(resourcePath), true).contents());

    var theme = [CPKeyedUnarchiver unarchiveObjectWithData:themeData];

    if (!theme)
        fail("Could not unarchive the theme at: " + path);

    CPLog.debug("Loaded theme: " + path);
    return theme;
}

function readConfigFile(configFile, inputFile)
{
    var configPath = null,
        path;

    // First see if the user passed a config file path
    if (configFile)
    {
        path = FILE.canonical(configFile);

        if (!FILE.isReadable(path))
            fail("Cannot find the config file: " + path);

        configPath = path;
    }
    else
    {
        path = FILE.join(appDirectory, "Info.plist");

        if (FILE.isReadable(path))
            configPath = path;
    }

    var plist = null;

    if (configPath)
    {
        var plist = FILE.read(configPath);

        if (!plist)
            fail("Could not read the Info.plist at: " + configPath);

        plist = CFPropertyList.propertyListFromString(plist);

        if (!plist)
            fail("Could not parse the Info.plist at: " + configPath);
    }

    return {path: configPath, plist: plist};
}

function getModifiedNibs(path)
{
    var nibs = new FileList(FILE.join(path, "*.[nx]ib")).items(),
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
        if (nibInfo.hasOwnProperty(nib))
            CPLog.info(">> %s: %s", CPLogColorize("Deleted", "warn"), nib);

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

function exceptionReason(exception)
{
    if (typeof(exception) === "string")
        return exception;
    else if (exception.isa && [exception respondsToSelector:@selector(reason)])
        return [exception reason];
    else
        return "An unknown error occurred";
}

function fail(message)
{
    [CPException raise:ConverterConversionException reason:message];
}
