var FILE = require("file");
var OS = require("os");

var NATIVEHOST_SOURCE = FILE.path(module.path).dirname().dirname().dirname().join("support", "NativeHost.app");

exports.buildNativeHost = function(rootPath, buildNative, options) {
    options = options || {};
    options.index = options.index || "index.html";

    rootPath = FILE.path(rootPath);
    buildNative = FILE.path(buildNative);

    if (buildNative.exists())
        buildNative.rmtree();

    buildNative.dirname().mkdirs();
    // FIXME: Narwhal doesn't preserve permissions
    // FILE.copyTree(NATIVEHOST_SOURCE, buildNative);
    OS.system(["cp", "-r", NATIVEHOST_SOURCE, buildNative]);
    FILE.chmod(buildNative.join("Contents", "MacOS", "NativeHost"), 0755);

    var rootBaseName = rootPath.basename();
    var buildClientDirectory = buildNative.join("Contents", "Resources", rootBaseName);

    FILE.mkdirs(FILE.dirname(buildClientDirectory));
    // FILE.copyTree(rootPath, buildClientDirectory);
    OS.system(["cp", "-r", rootPath, buildClientDirectory]);

    var defaultBundleName = buildNative.basename().match(/^(.*)(\.app)?$/)[1];

    function mergePlist(plist, path) {
        var otherPlist = CFPropertyList.readPropertyListFromFile(String(path));

        otherPlist.keys().forEach(function(key) {
            var value = otherPlist.valueForKey(key);
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

            if (key === "CFBundleExecutable") {
                buildNative.join("Contents", "MacOS", "NativeHost").rename(value);
                // FIXME:
                FILE.chmod(buildNative.join("Contents", "MacOS", value), 0755);
            }
        });
    }

    CFPropertyList.modifyPlist(buildNative.join("Contents", "Info.plist"), function(plist) {

        plist.setValueForKey("CFBundleName", defaultBundleName);
        plist.setValueForKey("NHInitialResource", FILE.join(rootBaseName, options.index));

        // merge Cappuccino plist
        var cappPlistPath = rootPath.join("Info.plist");
        if (cappPlistPath.isFile())
            mergePlist(plist, cappPlistPath);

        if (options.extraPlistPath)
            mergePlist(plist, options.extraPlistPath);
    });
}
