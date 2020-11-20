
require("../../common.jake");

var OS = require("os"),
    task = require("jake").task,
    stream = require("narwhal/term").stream,
    applicationName = "XcodeCapp.app";

task ("build", function()
{
    // If sw_vers does not exist, we aren't on Mac OS X
    if (!executableExists("sw_vers"))
        OS.exit(0);

    // No building on 10.6
    try
    {
        var p = OS.popen(["sw_vers", "-productVersion"]);

        if (p.wait() === 0)
        {
            var versions = p.stdout.read().split("."),
                majorVersion = parseInt(versions[0], 10),
                minorVersion = parseInt(versions[1], 10),
                buildVersion = parseInt(versions[2], 10);

        if (!((majorVersion == 11) || (majorVersion == 10 && minorVersion >= 12)))
            {
                colorPrint("XcodeCapp requires at least macOS Sierra.", "red");

                p.stdin.close();
                p.stdout.close();
                p.stderr.close();
                OS.exit(0);
            }
        }
    }
    finally
    {
        p.stdin.close();
        p.stdout.close();
        p.stderr.close();
    }

    if (executableExists("xcodebuild"))
    {
        var args = installPath = FILE.join("/", "Applications", applicationName);

        // Remove old symlink, if present.
		//The application is now built directly into /Applications
        if (FILE.isLink(installPath))
            FILE.remove(installPath);

		if (OS.system("xcodebuild install"))
            colorPrint("Unable to build XcodeCapp. Skipping", "orange");
    }
    else
    {
        print("Building " + applicationName + " requires Xcode.");
    }
});

task ("clean", function()
{
    if (OS.system("xcodebuild clean"))
        colorPrint("Unable to clean XcodeCapp. Skipping", "orange");
});

task ("clobber", function()
{
    if (OS.system("xcodebuild clean"))
        colorPrint("Unable to clean XcodeCapp. Skipping", "orange");
});

task ("default", ["build"]);
