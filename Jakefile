#!/usr/bin/env narwhal
print("top");
var FILE = require("file"),
    ENV = require("system").env,
    OS = require("os"),
    jake = require("jake");

require(FILE.absolute("common.jake"));

var subprojects = [/*"External", */"Objective-J", "Foundation", "AppKit", "Tools", "External/ojunit"];

["build", "clean", "clobber"].forEach(function(/*String*/ aTaskName)
{
    task (aTaskName, function()
    {
        subjake(subprojects, aTaskName);
    });
});

global.$DEBUG_ENV                       = FILE.join($BUILD_DIR, 'Debug', 'env');
global.$RELEASE_ENV                     = FILE.join($BUILD_DIR, 'Release', 'env');

global.$DOXYGEN_CONFIG                  = FILE.join('Tools', 'Documentation', 'Cappuccino.doxygen');
global.$DOCUMENTATION_BUILD             = FILE.join($BUILD_DIR, 'Documentation');

global.$TOOLS_README                    = FILE.join('Tools', 'READMEs', 'TOOLS-README');
global.$TOOLS_EDITORS                   = FILE.join('Tools', 'Editors');
global.$TOOLS_INSTALLER                 = FILE.join('Tools', 'Install', 'install-tools');
global.$TOOLS_DOWNLOAD                  = FILE.join($BUILD_DIR, 'Cappuccino', 'Tools');
global.$TOOLS_DOWNLOAD_ENV              = FILE.join($TOOLS_DOWNLOAD, 'objj');
global.$TOOLS_DOWNLOAD_EDITORS          = FILE.join($TOOLS_DOWNLOAD, 'Editors');
global.$TOOLS_DOWNLOAD_README           = FILE.join($TOOLS_DOWNLOAD, 'README');
global.$TOOLS_DOWNLOAD_INSTALLER        = FILE.join($TOOLS_DOWNLOAD, 'install-tools');

global.$STARTER_README                  = FILE.join('Tools', 'READMEs', 'STARTER-README');
global.$STARTER_DOWNLOAD                = FILE.join($BUILD_DIR, 'Cappuccino', 'Starter');
global.$STARTER_DOWNLOAD_APPLICATION    = FILE.join($STARTER_DOWNLOAD, 'NewApplication');
global.$STARTER_DOWNLOAD_README         = FILE.join($STARTER_DOWNLOAD, 'README');

global.$TOOLS_COMMONJS                  = FILE.join($BUILD_DIR, "Cappuccino", "Tools", "CommonJS", "objective-j");

task ("downloads", ["starter_download", "tools_download"]);

filedir ($TOOLS_DOWNLOAD_EDITORS, [$TOOLS_EDITORS], function()
{
    cp_r(FILE.join($TOOLS_EDITORS, '.'), $TOOLS_DOWNLOAD_EDITORS);
});

filedir ($TOOLS_DOWNLOAD_README, [$TOOLS_README], function()
{
    cp($TOOLS_README, $TOOLS_DOWNLOAD_README);
});

filedir ($TOOLS_DOWNLOAD_INSTALLER, [$TOOLS_INSTALLER], function()
{
    cp($TOOLS_INSTALLER, $TOOLS_DOWNLOAD_INSTALLER);
});

task ("tools_download", [$TOOLS_DOWNLOAD_EDITORS, $TOOLS_DOWNLOAD_README, $TOOLS_DOWNLOAD_INSTALLER, $TOOLS_COMMONJS]);

task ("starter_download", [$STARTER_DOWNLOAD_APPLICATION, $STARTER_DOWNLOAD_README]);

filedir ($TOOLS_COMMONJS, ["build"], function()
{
    rm_rf($TOOLS_COMMONJS);
    cp_r($COMMONJS_PRODUCT, $TOOLS_COMMONJS);
});

task ("deploy", ["downloads", "docs"], function()
{
    // copy the docs into the starter pack
    cp_r(FILE.join($DOCUMENTATION_BUILD, 'html', '.'), FILE.join($STARTER_DOWNLOAD, 'Documentation'));

    var cappuccino_output_path = FILE.join($BUILD_DIR, 'Cappuccino');

    // zip the starter pack
    var starter_zip_output = FILE.join($BUILD_DIR, 'Cappuccino', 'Starter.zip');
    rm_rf(starter_zip_output);

    OS.system("cd " + cappuccino_output_path + " && zip -ry -8 Starter.zip Starter");

    // zip the tools pack
    var tools_zip_output = FILE.join($BUILD_DIR, 'Cappuccino', 'Tools.zip')
    rm_rf(tools_zip_output);

    OS.system("cd " + cappuccino_output_path + " && zip -ry -8 Tools.zip Tools");
});

filedir ($STARTER_DOWNLOAD_APPLICATION, ["build"], function()
{
    //ENV["PATH"] = FILE.join($TOOLS_DOWNLOAD_ENV, "bin") + ':' + ENV["PATH"];

    rm_rf($STARTER_DOWNLOAD_APPLICATION);
    FILE.mkdirs($STARTER_DOWNLOAD);

    if (OS.system("capp gen " + $STARTER_DOWNLOAD_APPLICATION + " -t Application --noconfig"))
        OS.exit(1); // rake abort if ($? != 0)

    // No tools means no objective-j gem
    // FILE.rm(FILE.join($STARTER_DOWNLOAD_APPLICATION, 'Rakefile'))
});

filedir ($STARTER_DOWNLOAD_README, [$STARTER_README], function()
{
    cp($STARTER_README, $STARTER_DOWNLOAD_README);
});

task ("install", ["tools_download"], function()
{
    var prefix = ENV["prefix"] ? ("--prefix " + ENV["prefix"]) : "";

    if (OS.system("cd " + $TOOLS_DOWNLOAD + " && sudo sh ./install-tools " + prefix))
        OS.exist(1); // rake abort if ($? != 0)
});

task ("test", ["build"], function()
{
    var tests = "'" + FILEList('Tests/**/*.j').join("' '") + "'",
        build_result = OS.system("ojtest " + tests);

    if (build_result.match(/Test suite failed/i))
    {
        print("tests failed, aborting the build");
        print (build_result);

        OS.exit(1);
    }
    else
        print(build_result);
});

task ("docs", function()
{
    if (executableExists("doxygen"))
    {
        if (OS.system("doxygen " + $DOXYGEN_CONFIG))
            OS.exit(1); //rake abort if ($? != 0)

        rm_rf($DOCUMENTATION_BUILD);
        mv("debug.txt", FILE.join("Documentation", "debug.txt"));
        mv("Documentation", $DOCUMENTATION_BUILD);
    }
    else
        print("doxygen not installed. skipping documentation generation.");
});

task ("submodules", function()
{
/*
    if executable_exists? "git"
        system %{git submodule init && git submodule update}
        rake abort if ($? != 0)
    else
        puts "Git not installed"
        rake abort
    end
*/
});

/*
TODO: zip/tar.        
*/
