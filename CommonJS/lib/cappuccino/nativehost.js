var FILE = require("file");
var OS = require("os");

var NATIVEHOST_SOURCE = FILE.path(module.path).dirname().dirname().dirname().join("support", "NativeHost.app");

exports.buildNativeHost = function(rootPath, buildNative, options) {

    if (FILE.exists(buildNative))
        FILE.rmtree(buildNative);

    // If not we lose all of our permissions.
    FILE.mkdirs(FILE.dirname(buildNative));
    OS.system(["cp", "-r", NATIVEHOST_SOURCE, buildNative]);

    // Do this again anyways?
    FILE.chmod(FILE.join(buildNative, "Contents", "MacOS", "NativeHost"), 0755);

    var buildClientDirectory = FILE.join(buildNative, "Contents", "Resources", "Application");

    FILE.mkdirs(FILE.dirname(buildClientDirectory));
    OS.system(["cp", "-r", rootPath, buildClientDirectory]);
    // FILE.copyTree(rootPath, buildClientDirectory);

    var defaultBundleName = FILE.basename(buildNative).match(/^(.*)(\.app)?$/)[1];

    CFPropertyList.modifyPlist(FILE.join(buildNative, "Contents", "Info.plist"), function(plist) {
        plist.setValueForKey("CFBundleName", defaultBundleName);
        plist.setValueForKey("NHInitialResource", "Application/index.html");

        // merge Cappuccino plist
        var cappPlist = CFPropertyList.readPropertyListFromFile(FILE.join(rootPath, "Info.plist"));
        cappPlist.keys().forEach(function(key) {
            var value = cappPlist.valueForKey(key);
            plist.setValueForKey(key, value);

            if (key === "CPBundleName")
                plist.setValueForKey("CFBundleName", value);
        });
    });
}