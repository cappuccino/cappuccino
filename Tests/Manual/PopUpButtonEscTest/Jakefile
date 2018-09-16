/*
 * Jakefile
 * PopUpButtonTest
 *
 * Created by Glenn L. Austin on June 26, 2013.
 * Copyright 2013, Austin-Soft.com All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("PopUpButtonTest", function(task)
{
    ENV["OBJJ_INCLUDE_PATHS"] = "Frameworks";

    if (configuration === "Debug")
        ENV["OBJJ_INCLUDE_PATHS"] = FILE.join(ENV["OBJJ_INCLUDE_PATHS"], configuration);

    task.setBuildIntermediatesPath(FILE.join("Build", "PopUpButtonTest.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("PopUpButtonTest");
    task.setIdentifier("com.austin-soft.PopUpButtonTest");
    task.setVersion("1.0");
    task.setAuthor("Austin-Soft.com");
    task.setEmail("support@austin-soft.com");
    task.setSummary("PopUpButtonTest");
    task.setSources(new FileList("**/*.j").exclude(FILE.join("Build", "**")).exclude(FILE.join("Frameworks", "Source", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["PopUpButtonTest"], function()
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
    OS.system(["open", FILE.join("Build", "Debug", "PopUpButtonTest", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "PopUpButtonTest", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "PopUpButtonTest"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "PopUpButtonTest"), FILE.join("Build", "Deployment", "PopUpButtonTest")]);
    printResults("Deployment")
});

task ("desktop", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Desktop", "PopUpButtonTest"));
    require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", "PopUpButtonTest"), FILE.join("Build", "Desktop", "PopUpButtonTest", "PopUpButtonTest.app"));
    printResults("Desktop")
});

task ("run-desktop", ["desktop"], function()
{
    OS.system([FILE.join("Build", "Desktop", "PopUpButtonTest", "PopUpButtonTest.app", "Contents", "MacOS", "NativeHost"), "-i"]);
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "PopUpButtonTest"));
    print("----------------------------");
}
