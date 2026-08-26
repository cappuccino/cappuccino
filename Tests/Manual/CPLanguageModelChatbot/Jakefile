/*
 * Jakefile
 * CPLevelIndicator
 *
 * Created by Alexander Ljungberg on May 28, 2011.
 * Copyright 2011, WireLoad All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("CPLevelIndicator", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "CPLevelIndicator.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("CPLevelIndicator");
    task.setIdentifier("com.yourcompany.CPLevelIndicator");
    task.setVersion("1.0");
    task.setAuthor("WireLoad");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("CPLevelIndicator");
    task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");
    task.setNib2CibFlags("-R Resources/");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["CPLevelIndicator"], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", "CPLevelIndicator", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "CPLevelIndicator", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "CPLevelIndicator"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "CPLevelIndicator"), FILE.join("Build", "Deployment", "CPLevelIndicator")]);
    printResults("Deployment")
});

task ("desktop", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Desktop", "CPLevelIndicator"));
    require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", "CPLevelIndicator"), FILE.join("Build", "Desktop", "CPLevelIndicator", "CPLevelIndicator.app"));
    printResults("Desktop")
});

task ("run-desktop", ["desktop"], function()
{
    OS.system([FILE.join("Build", "Desktop", "CPLevelIndicator", "CPLevelIndicator.app", "Contents", "MacOS", "NativeHost"), "-i"]);
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "CPLevelIndicator"));
    print("----------------------------");
}
