/*
 * Nib2Cib.j
 * nib2cib
 *
 * Created by Francisco Tolmasky and Aparajita Fishman.
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
    DefaultFile = "MainMenu",
    AllowedStoredOptionsRe = new RegExp("^(defaultTheme|auxThemes|verbosity|quiet|frameworks|format)$"),
    ArgsRe = /"[^\"]+"|'[^\']+'|\S+/g;


@implementation Nib2Cib : CPObject
{
    CPArray         commandLineArgs;
    JSObject        parser;
    JSObject        nibInfo;
    CPString        appDirectory;
    CPString        resourcesDirectory;
    CPDictionary    infoPlist;
    CPArray         userNSClasses;
}

- (id)initWithArgs:(CPArray)theArgs
{
    self = [super init];

    if (self)
    {
        commandLineArgs = theArgs;
        parser = new (require("narwhal/args").Parser)();
        nibInfo = {};
        appDirectory = @"";
        resourcesDirectory = @"";
        infoPlist = [CPDictionary dictionary];
        userNSClasses = [];
    }

    return self;
}

- (void)run
{
    try
    {
        var options = [self parseOptionsFromArgs:commandLineArgs];

        [self setLogLevel:options.quiet ? -1 : options.verbosity];
        [self checkPrerequisites];

        if (options.watch)
            [self watchWithOptions:options];
        else
            [self convertWithOptions:options inputFile:nil];
    }
    catch (anException)
    {
        CPLog.fatal([self exceptionReason:anException]);
        OS.exit(1);
    }
}

- (void)checkPrerequisites
{
    var fontinfo = require("cappuccino/fontinfo").fontinfo,
        info = fontinfo("LucidaGrande", 13);

    if (!info)
        [self failWithMessage:@"fontinfo does not appear to be installed"];
}

- (BOOL)convertWithOptions:(JSObject)options inputFile:(CPString)inputFile
{
    try
    {
        inputFile = inputFile || [self getInputFile:options.args];

        [self getAppAndResourceDirectoriesFromInputFile:inputFile options:options];

        if (options.readStoredOptions)
        {
            options = [self mergeOptionsWithStoredOptions:options inputFile:inputFile];
            [self setLogLevel:options.quiet ? -1 : options.verbosity];
        }

        if (!options.quiet && options.verbosity > 0)
            [self printVersion];

        var outputFile = [self getOutputFileFromInputFile:inputFile args:options.args],
            configInfo = [self readConfigFile:options.configFile || @"" inputFile:inputFile];

        infoPlist = configInfo.plist;

        if (infoPlist)
        {
            var systemFontFace = [infoPlist valueForKey:@"CPSystemFontFace"];

            if (systemFontFace)
                [CPFont setSystemFontFace:systemFontFace];

            var systemFontSize = [infoPlist valueForKey:@"CPSystemFontSize"];

            if (systemFontSize)
                [CPFont setSystemFontSize:parseFloat(systemFontSize, 10)];
        }
        else
            infoPlist = [CPDictionary dictionary];

        var themeList = [self getThemeList:options],
            themes = [self loadThemesFromList:themeList];

        CPLog.info("\n-------------------------------------------------------------");
        CPLog.info("Input         : " + inputFile);
        CPLog.info("Output        : " + outputFile);
        CPLog.info("Format        : " + ["Auto", "Mac", "iPhone"][options.format]);
        CPLog.info("Application   : " + appDirectory);
        CPLog.info("Resources     : " + resourcesDirectory);
        CPLog.info("Frameworks    : " + (options.frameworks || ""));
        CPLog.info("Default theme : " + themeList[0]);
        CPLog.info("Aux themes    : " + themeList.slice(1).join(", "));
        CPLog.info("Config file   : " + (configInfo.path || ""));
        CPLog.info("System Font   : " + [CPFont systemFontSize] + "px " + [CPFont systemFontFace]);
        CPLog.info("-------------------------------------------------------------\n");

        var converter = [[Converter alloc] initWithInputPath:inputFile
                                                      format:options.format
                                                      themes:themes];

        [converter setOutputPath:outputFile];
        [converter setResourcesPath:resourcesDirectory];

        var loadFrameworksCallback = function()
        {
            [self loadNSClassesFromBundle:[CPBundle mainBundle]];
            [converter setUserNSClasses:userNSClasses];
            [converter convert];
        };

        [self loadFrameworks:options.frameworks verbosity:options.verbosity callback:loadFrameworksCallback];

        return YES;
    }
    catch (anException)
    {
        CPLog.fatal([self exceptionReason:anException]);
        return NO;
    }
}

- (void)watchWithOptions:(JSObject)options
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
        [self failWithMessage:@"Cannot find the directory: " + watchDir];

    // Turn on info messages
    [self setLogLevel:1];

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
        var modifiedNibs = [self getModifiedNibsInDirectory:watchDir];

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
            [self setLogLevel:verbosity];

            var success = [self convertWithOptions:options inputFile:nib];

            [self setLogLevel:1];

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

- (JSObject)parseOptionsFromArgs:(CPArray)theArgs
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

    parser.option("-t", "--theme", "auxThemes")
        .push()
        .displayName("name")
        .help("An additional theme loaded dynamically by your application");

    parser.option("--config", "configFile")
        .set()
        .displayName("path")
        .help("A path to an Info.plist file from which the system font and/or size can be retrieved");

    parser.option("-v", "--verbose", "verbosity")
        .inc()
        .help("Increase verbosity level");

    parser.option("-q", "--quiet", "quiet")
        .set(true)
        .help("No output");

    parser.option("-F", "--framework", "frameworks")
        .push()
        .help("Add a framework to load");

    parser.option("--no-stored-options", "readStoredOptions")
        .set(false)
        .def(true)
        .help("Do not read stored options");

    parser.option("--mac", "format")
        .set(NibFormatMac)
        .def(NibFormatUndetermined)
        .help("Set format to Mac");

    parser.option("--version", "showVersion")
        .action(function() { [self printVersionAndExit]; })
        .help("Show the version of nib2cib and quit");

    parser.helpful();

    var options = parser.parse(theArgs, null, null, true);

    if (options.args.length > 2)
    {
        parser.printUsage(options);
        OS.exit(0);
    }

    return options;
}

- (JSObject)mergeOptionsWithStoredOptions:(JSObject)options inputFile:(CPString)inputFile
{
    // We have to clone options
    var userOptions = [self readStoredOptionsAtPath:FILE.join(SYS.env["HOME"], ".nib2cibconfig")],
        appOptions = [self readStoredOptionsAtPath:FILE.join(appDirectory, "nib2cib.conf")],
        filename = FILE.basename(inputFile, FILE.extension(inputFile)) + ".conf",
        fileOptions = [self readStoredOptionsAtPath:FILE.join(FILE.dirname(inputFile), filename)];

    // At this point we have an array of args without the initial command in args[0],
    // add the command and parse the options.
    userOptions = [self parseOptionsFromArgs:[options.command].concat(userOptions)];
    appOptions = [self parseOptionsFromArgs:[options.command].concat(appOptions)];
    fileOptions = [self parseOptionsFromArgs:[options.command].concat(fileOptions)];

    // The increasing order of precedence is: user -> app -> file -> command line
    var mergedOptions = userOptions;

    [self mergeOptions:appOptions with:mergedOptions];
    [self mergeOptions:fileOptions with:mergedOptions];
    [self mergeOptions:options with:mergedOptions];
    mergedOptions.args = options.args;

    return mergedOptions;
}

- (CPArray)readStoredOptionsAtPath:(CPString)path
{
    path = FILE.canonical(path);

    if (!FILE.isReadable(path))
        return [];

    var file = FILE.open(path, "r"),
        line = file.readLine(),
        matches = line.match(ArgsRe) || [];

    file.close();
    CPLog.debug("Reading stored options: " + path);

    if (matches)
    {
        for (var i = 0; i < matches.length; ++i)
        {
            var str = matches[i];

            if ((str.charAt(0) === '"' && str.substr(-1) === '"') || (str.charAt(0) === "'" && str.substr(-1) === "'"))
                matches[i] = str.substr(1, str.length - 2);
        }

        return matches;
    }
    else
        return [];
}

- (void)printOptions:options
{
    for (option in options)
    {
        var value = options[option];

        if (value)
        {
            var show = value.length !== undefined ? value.length > 0 : !!value;

            if (show)
                print(option + ": " + value);
        }
    }
}

// Merges properties in sourceOptions into targetOptions, overriding properties in targetOptions
- (void)mergeOptions:(JSObject)sourceOptions with:(JSObject)targetOptions
{
    for (option in sourceOptions)
    {
        // Make sure only a supported option is given
        if (!AllowedStoredOptionsRe.test(option))
            continue;

        if (sourceOptions.hasOwnProperty(option))
        {
            var value = sourceOptions[option];

            if (value)
            {
                var copy = value.length !== undefined ? value.length > 0 : !!value;

                if (copy)
                    targetOptions[option] = value;
            }
        }
    }
}

- (void)setLogLevel:(int)level
{
    CPLogUnregister(CPLogPrint);

    if (level === 0)
        CPLogRegister(CPLogPrint, "warn", logFormatter);
    else if (level === 1)
        CPLogRegister(CPLogPrint, "info", logFormatter);
    else if (level > 1)
        CPLogRegister(CPLogPrint, null, logFormatter);
}

- (CPString)getInputFile:(CPArray)theArgs
{
    var inputFile = theArgs[0] || DefaultFile,
        path = "";

    if (!/^.+\.[nx]ib$/.test(inputFile))
    {
        if (path = [self findInputFile:inputFile extension:@".xib"])
            inputFile = path;
        else if (path = [self findInputFile:inputFile extension:@".nib"])
            inputFile = path;
        else
            [self failWithMessage:@"Cannot find the input file (.xib or .nib): " + FILE.canonical(inputFile)];
    }
    else if (path = [self findInputFile:inputFile extension:nil])
        inputFile = path;
    else
        [self failWithMessage:@"Could not read the input file: " + FILE.canonical(inputFile)];

    return FILE.canonical(inputFile);
}

- (void)findInputFile:(CPString)inputFile extension:(CPString)extension
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

- (void)getAppAndResourceDirectoriesFromInputFile:(CPString)inputFile options:(JSObject)options
{
    appDirectory = resourcesDirectory = "";

    if (options.resourcesDir)
    {
        var path = FILE.canonical(options.resourcesDir);

        if (!FILE.isDirectory(path))
            [self failWithMessage:@"Cannot read resources at: " + path];

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

- (CPString)getOutputFileFromInputFile:(CPString)inputFile args:(CPArray)theArgs
{
    var outputFile = null;

    if (theArgs.length > 1)
    {
        outputFile = theArgs[1];

        if (!/^.+\.cib$/.test(outputFile))
            outputFile += ".cib";
    }
    else
        outputFile = FILE.join(FILE.dirname(inputFile), FILE.basename(inputFile, FILE.extension(inputFile))) + ".cib";

    outputFile = FILE.canonical(outputFile);

    if (!FILE.isWritable(FILE.dirname(outputFile)))
        [self failWithMessage:@"Cannot write the output file at: " + outputFile];

    return outputFile;
}

- (void)loadFrameworks:(CPArray)frameworks verbosity:(int)verbosity callback:(JSObject)aCallback
{
    if (!frameworks || frameworks.length === 0)
        return aCallback();

    var returnPath = function(path) { return path; };

    frameworks.forEach(function(aFramework)
    {
        [self setLogLevel:verbosity];

        var frameworkPath = nil;

        // If it is just a name with no path components, try to locate it
        if (aFramework.indexOf("/") === -1)
        {
            frameworkPath = [self findInCappBuild:aFramework isDirectory:YES callback:returnPath];

            if (!frameworkPath)
                frameworkPath = [self findInFrameworks:FILE.join(appDirectory, "Frameworks")
                                                  path:aFramework
                                           isDirectory:YES
                                              callback:returnPath];

            if (!frameworkPath)
                frameworkPath = [self findInInstalledFrameworks:aFramework isDirectory:YES callback:returnPath];
        }
        else
            frameworkPath = FILE.canonical(aFramework);

        if (!frameworkPath)
            [self failWithMessage:@"Cannot find the framework \"" + aFramework + "\""];

        CPLog.debug("Loading framework: " + frameworkPath);

        try
        {
            // CPBundle is a bit loquacious with logging, we will defer
            // logging its exceptions till later.
            [self setLogLevel:-1];

            var frameworkBundle = [[CPBundle alloc] initWithPath:frameworkPath];

            [frameworkBundle loadWithDelegate:nil];
            [self setLogLevel:verbosity];

            [self loadNSClassesFromBundle:frameworkBundle];
        }
        finally
        {
            [self setLogLevel:verbosity];
        }

        require("browser/timeout").serviceTimeouts();
    });

    aCallback();
}

- (void)loadNSClassesFromBundle:(CPBundle)aBundle
{
    // See if the framework defines NS classes
    var nsClasses = [aBundle objectForInfoDictionaryKey:@"NSClasses"] || [],
        bundlePath = [aBundle bundlePath];

    for (var i = 0; i < nsClasses.length; ++i)
    {
        if (userNSClasses.indexOf(nsClasses[i]) >= 0)
            continue;

        var path = FILE.join(bundlePath, "NS_" + nsClasses[i] + ".j");

        objj_importFile(path, YES);
        CPLog.debug("Imported NS class: %s", path);

        userNSClasses.push(nsClasses[i]);
    }
}

- (CPArray)getThemeList:(JSObject)options
{
    var defaultTheme = options.defaultTheme;

    if (!defaultTheme)
        defaultTheme = [infoPlist valueForKey:@"CPDefaultTheme"];

    if (!defaultTheme)
        defaultTheme = [self getAppKitDefaultThemeName];

    var themes = [CPSet setWithObject:defaultTheme];

    if (options.auxThemes)
        [themes addObjectsFromArray:options.auxThemes];

    var auxThemes = infoPlist.valueForKey("CPAuxiliaryThemes");

    if (auxThemes)
        [themes addObjectsFromArray:auxThemes];

    // Now remove the default theme, get the list as an array, and insert the default at the beginning
    [themes removeObject:defaultTheme];

    var allThemes = [themes allObjects];

    [allThemes insertObject:defaultTheme atIndex:0];

    return allThemes;
}

// Returns undefined if $CAPP_BUILD is not defined, false if path cannot be found in $CAPP_BUILD
- (id)findInCappBuild:(CPString)path isDirectory:(BOOL)isDirectory callback:(JSObject)callback
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

- (id)findInInstalledFrameworks:(CPString)path isDirectory:(BOOL)isDirectory callback:(JSObject)callback
{
    // NOTE: It's safe to use '/' directly in the path, we're guaranteed to be on a Mac
    return [self findInFrameworks:FILE.canonical(FILE.join(SYS.prefix, "packages/cappuccino/Frameworks"))
                             path:path
                      isDirectory:isDirectory
                         callback:callback];
}

- (id)findInFrameworks:(CPString)frameworksPath path:(CPString)path isDirectory:(BOOL)isDirectory callback:(JSObject)callback
{
    var result = null,
        findPath = FILE.join(frameworksPath, "Debug", path);

    if ((isDirectory && FILE.isDirectory(findPath)) || (!isDirectory && FILE.exists(findPath)))
        result = callback(findPath);

    if (!result)
    {
        findPath = FILE.join(frameworksPath, path);

        if ((isDirectory && FILE.isDirectory(findPath)) || (!isDirectory && FILE.exists(findPath)))
            result = callback(findPath);
    }

    return result;
}

- (CPString)getAppKitDefaultThemeName
{
    var callback = function(path) { return [self themeNameFromPropertyList:path]; },
        themeName = [self findInCappBuild:@"AppKit/Info.plist" isDirectory:NO callback:callback];

    if (!themeName)
        themeName = [self findInInstalledFrameworks:@"AppKit/Info.plist" isDirectory:NO callback:callback];

    return themeName || DefaultTheme;
}

- (CPString)themeNameFromPropertyList:(CPString)path
{
    if (!FILE.isReadable(path))
        return nil;

    var themeName = nil,
        plist = CFPropertyList.readPropertyListFromFile(path);

    if (plist)
        themeName = plist.valueForKey("CPDefaultTheme");

    return themeName;
}

- (CPArray)loadThemesFromList:(CPArray)themeList
{
    var themes = [];

    for (var i = 0; i < themeList.length; ++i)
        themes.push([self loadThemeNamed:themeList[i] directory:resourcesDirectory]);

    return themes;
}

- (CPTheme)loadThemeNamed:(CPString)themeName directory:(CPString)themeDir
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

        themePath = [self findInCappBuild:blendName isDirectory:YES callback:returnPath];

        if (!themePath)
            themePath = [self findInInstalledFrameworks:@"AppKit/Resources/" + blendName isDirectory:YES callback:returnPath];

        // Last resort, try the cwd
        if (!themePath)
        {
            var path = FILE.canonical(blendName);

            if (FILE.isDirectory(path))
                themePath = path;
        }
    }

    if (!themePath)
        [self failWithMessage:@"Cannot find the theme \"" + themeName + "\""];

    return [self readThemeWithName:themeName atPath:themePath];
}

- (CPTheme)readThemeWithName:(CPString)name atPath:(CPString)path
{
    var themeBundle = new CFBundle(path);

    // By default when we try to load the bundle it will use the CommonJS environment,
    // but we want the Browser environment. So we override mostEligibleEnvironment().
    themeBundle.mostEligibleEnvironment = function() { return "Browser"; }
    themeBundle.load();

    var keyedThemes = themeBundle.valueForInfoDictionaryKey("CPKeyedThemes");

    if (!keyedThemes)
        [self failWithMessage:@"Could not find the keyed themes in the theme: " + path];

    var index = keyedThemes.indexOf(name + ".keyedtheme");

    if (index < 0)
        [self failWithMessage:@"Could not find the main theme data (" + name + ".keyedtheme" + ") in the theme: " + path];

    // Load the keyed theme data, making sure to resolve it
    var resourcePath = themeBundle.pathForResource(keyedThemes[index]),
        themeData = new CFMutableData();

    themeData.setRawString(StaticResource.resourceAtURL(new CFURL(resourcePath), true).contents());

    var theme = [CPKeyedUnarchiver unarchiveObjectWithData:themeData];

    if (!theme)
        [self failWithMessage:@"Could not unarchive the theme at: " + path];

    CPLog.debug("Loaded theme: " + path);
    return theme;
}

- (JSObject)readConfigFile:(CPString)configFile inputFile:(CPString)inputFile
{
    var configPath = null,
        path;

    // First see if the user passed a config file path
    if (configFile)
    {
        path = FILE.canonical(configFile);

        if (!FILE.isReadable(path))
            [self failWithMessage:@"Cannot find the config file: " + path];

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
            [self failWithMessage:@"Could not read the Info.plist at: " + configPath];

        plist = CFPropertyList.propertyListFromString(plist);

        if (!plist)
            [self failWithMessage:@"Could not parse the Info.plist at: " + configPath];
    }

    return {path: configPath, plist: plist};
}

- (CPArray)getModifiedNibsInDirectory:(CPString)path
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

- (void)printVersionAndExit
{
    [self printVersion];
    OS.exit(0);
}

- (void)printVersion
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

- (CPString)exceptionReason:(JSObject)exception
{
    if (typeof(exception) === "string")
        return exception;
    else if (exception.isa && [exception respondsToSelector:@selector(reason)])
        return [exception reason];
    else
        return @"An unknown error occurred";
}

- (void)failWithMessage:(CPString)message
{
    [CPException raise:ConverterConversionException reason:message];
}

@end

function logFormatter(aString, aLevel, aTitle)
{
    if (aLevel === "info")
        return aString;
    else
        return CPLogColorize(aString, aLevel);
}
