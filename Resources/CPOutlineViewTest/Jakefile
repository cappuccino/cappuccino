/*
 * Jakefile
 * outlineview
 *
 * Created by You on January 22, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    task = require("jake").task,
    FileList = require("jake").FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";

app ("outlineview", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "outlineview.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("outlineview");
    task.setIdentifier("com.yourcompany.outlineview");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("outlineview");
    task.setSources(new FileList("**/*.j"));
    task.setResources(new FileList("Resources/*"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["outlineview"]);
