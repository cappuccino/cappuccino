var FILE = require("file");
var OS = require("os");

var NATIVEHOST_SOURCE = FILE.path(module.path).dirname().dirname().dirname().join("support", "NativeHost.app");

exports.buildNativeHost = function(rootPath, buildNative, options) {
    rootPath = FILE.path(rootPath);
    buildNative = FILE.path(buildNative);

    if (buildNative.exists())
        buildNative.rmtree();

    // If not we lose all of our permissions.
    buildNative.dirname().mkdirs();
    OS.system(["cp", "-r", NATIVEHOST_SOURCE, buildNative]);

    // Do this again anyways?
    FILE.chmod(buildNative.join("Contents", "MacOS", "NativeHost"), 0755);

    var buildClientDirectory = buildNative.join("Contents", "Resources", "Application");

    FILE.mkdirs(FILE.dirname(buildClientDirectory));
    OS.system(["cp", "-r", rootPath, buildClientDirectory]);
    // FILE.copyTree(rootPath, buildClientDirectory);

    var defaultBundleName = buildNative.basename().match(/^(.*)(\.app)?$/)[1];

    CFPropertyList.modifyPlist(buildNative.join("Contents", "Info.plist"), function(plist) {
        plist.setValueForKey("CFBundleName", defaultBundleName);
        plist.setValueForKey("NHInitialResource", "Application/index.html");

        // merge Cappuccino plist
        var cappPlist = CFPropertyList.readPropertyListFromFile(FILE.join(rootPath, "Info.plist"));
        cappPlist.keys().forEach(function(key) {
            var value = cappPlist.valueForKey(key);
            plist.setValueForKey(key, value);

            if (key === "CPBundleName")
                plist.setValueForKey("CFBundleName", value);

            if (key === "CFBundleIconFile") {
                var iconPath = rootPath.join("Resources", value);
                if (iconPath.isFile())
                    iconPath.copy(buildNative.join("Contents", "Resources", value));
                else
                    print("Warning: CFBundleIconFile references " + value + " but does not exist in the resources directory.");
            }
        });
    });
}