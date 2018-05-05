/*
 * Jakefile
 * 44-Sorting-CPTableView
 *
 * Created by Argos Oz on May 1, 2018.
 * Copyright 2018, Army of Me, Inc. All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os"),
    projectName = "44SortingCPTableView";

app (projectName, function(task)
{
    ENV["OBJJ_INCLUDE_PATHS"] = "Frameworks";

    if (configuration === "Debug")
        ENV["OBJJ_INCLUDE_PATHS"] = FILE.join(ENV["OBJJ_INCLUDE_PATHS"], configuration);

    task.setBuildIntermediatesPath(FILE.join("Build", "44SortingCPTableView.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("44-Sorting-CPTableView");
    task.setIdentifier("com.yourcompany.44SortingCPTableView");
    task.setVersion("1.0");
    task.setAuthor("Army of Me, Inc.");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("44-Sorting-CPTableView");
    task.setSources(new FileList("**/*.j").exclude(FILE.join("Build", "**")).exclude(FILE.join("Frameworks", "Source", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g -S --inline-msg-send");
    else
        task.setCompilerFlags("-O2");
});

task ("default", [projectName], function()
{
    printResults(configuration);
});

task ("build", ["default"], function()
{
    updateApplicationSize();
});

task ("debug", function()
{
    configuration = ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    configuration = ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", projectName, "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", projectName, "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", projectName));
    OS.system(["press", "-f", FILE.join("Build", "Release", projectName), FILE.join("Build", "Deployment", projectName)]);
    printResults("Deployment")
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, projectName));
    print("----------------------------");
}

function updateApplicationSize()
{
    print("Calculating application file sizes...");

    var contents = FILE.read(FILE.join("Build", configuration, projectName, "Info.plist"), { charset:"UTF-8" }),
        format = CFPropertyList.sniffedFormatOfString(contents),
        plist = CFPropertyList.propertyListFromString(contents),
        totalBytes = {executable:0, data:0, mhtml:0};

    // Get the size of all framework executables and sprite data
    var frameworksDir = "Frameworks";

    if (configuration === "Debug")
        frameworksDir = FILE.join(frameworksDir, "Debug");

    var frameworks = FILE.list(frameworksDir);

    frameworks.forEach(function(framework)
    {
        if (framework !== "Source")
            addBundleFileSizes(FILE.join(frameworksDir, framework), totalBytes);
    });

    // Read in the default theme name, and attempt to get its size
    var themeName = plist.valueForKey("CPDefaultTheme") || "Aristo2",
        themePath = nil;

    if (themeName === "Aristo" || themeName === "Aristo2")
        themePath = FILE.join(frameworksDir, "AppKit", "Resources", themeName + ".blend");
    else
        themePath = FILE.join("Frameworks", "Resources", themeName + ".blend");

    if (FILE.isDirectory(themePath))
        addBundleFileSizes(themePath, totalBytes);

    // Add sizes for the app
    addBundleFileSizes(FILE.join("Build", configuration, projectName), totalBytes);

    print("Executables: " + totalBytes.executable + ", sprite data: " + totalBytes.data + ", total: " + (totalBytes.executable + totalBytes.data));

    var dict = new CFMutableDictionary();

    dict.setValueForKey("executable", totalBytes.executable);
    dict.setValueForKey("data", totalBytes.data);
    dict.setValueForKey("mhtml", totalBytes.mhtml);

    plist.setValueForKey("CPApplicationSize", dict);

    FILE.write(FILE.join("Build", configuration, projectName, "Info.plist"), CFPropertyList.stringFromPropertyList(plist, format), { charset:"UTF-8" });
}

function addBundleFileSizes(bundlePath, totalBytes)
{
    var bundleName = FILE.basename(bundlePath),
        environment = bundleName === "Foundation" ? "Objj" : "Browser",
        bundlePath = FILE.join(bundlePath, environment + ".environment");

    if (FILE.isDirectory(bundlePath))
    {
        var filename = bundleName + ".sj",
            filePath = new FILE.Path(FILE.join(bundlePath, filename));

        if (filePath.exists())
            totalBytes.executable += filePath.size();

        filePath = new FILE.Path(FILE.join(bundlePath, "dataURLs.txt"));

        if (filePath.exists())
            totalBytes.data += filePath.size();

        filePath = new FILE.Path(FILE.join(bundlePath, "MHTMLData.txt"));

        if (filePath.exists())
            totalBytes.mhtml += filePath.size();

        filePath = new FILE.Path(FILE.join(bundlePath, "MHTMLPaths.txt"));

        if (filePath.exists())
            totalBytes.mhtml += filePath.size();
    }
}
