
var FILE = require("file");
var MD5 = require("md5");

var FileList = require("jake").FileList;
var BundleTask = require("objective-j/jake/bundletask").BundleTask;

exports.generateManifest = function(productPath, options)
{
    options = options || {};

    indexFilePath = options.index || FILE.join(productPath, "index.html");

    if (!FILE.isFile(indexFilePath)) {
        print("Warning: Skipping cache manifest generation, no index file at "+indexFilePath);
        return;
    }

    var index = FILE.read(indexFilePath, { charset : "UTF-8" });

    var manifestName = "app.manifest";
    var manifestPath = FILE.join(productPath, manifestName);
    var manifestAttribute = 'manifest="'+manifestName+'"';

    print("Generating cache manifest: " + manifestPath);

    var manifestOut = FILE.open(manifestPath, "w", { charset : "UTF-8" });
    manifestOut.print("CACHE MANIFEST");
    manifestOut.print("");
    manifestOut.print("CACHE:");

    var list = new FileList(FILE.join(productPath, "**", "*"));
    list.exclude(manifestPath);
    list.exclude("**/.DS_Store", "**/.htaccess");
    list.exclude("**/LICENSE");
    list.exclude("**/MHTML*");
    list.exclude("**/CommonJS.environment/*");
    list.exclude("**/*.cur"); // FIXME: sprite these?

    // FIXME: bleh. heuristic for whether index file includes debug frameworks
    if (index.indexOf('"Frameworks/Debug"') < 0)
        list.exclude("**/Frameworks/Debug/*");

    if (options.exclude)
        options.exclude.forEach(list.exclude.bind(list));

    list.forEach(function(path) {
        if (FILE.isFile(path)) {
            var relative = FILE.relative(productPath, path);

            // FIXME: check the actual sprited images file
            // check index for references to file (for spinner.gif, etc)
            if (BundleTask.isSpritable(path) && index.indexOf(relative) < 0)
                return;

            // include hash of each file in comments to expire when any file changes
            var hash = MD5.hash(FILE.read(path, "b")).decodeToString("base16");
            manifestOut.print("# " + hash);
            manifestOut.print(relative);
        }
    });

    manifestOut.print("");
    manifestOut.print("NETWORK:");
    manifestOut.print("*");
    manifestOut.close();

    // Insert "manifest" attribute in <html> tag of index file
    var matchTag = index.match(/<html[^>]*>/i);
    if (matchTag) {
        var htmlTag = matchTag[0];
        var newHTMLTag = null;

        var matchAttr = htmlTag.match(/manifest\s*=\s*"([^"]*)"/i);
        if (matchAttr) {
            if (matchAttr[1] !== manifestName) {
                newHTMLTag = htmlTag.replace(matchAttr[0], manifestAttribute);
            }
        } else {
            newHTMLTag = htmlTag.replace(/>$/, " "+manifestAttribute+">");
        }

        if (newHTMLTag) {
            print("Replacing html tag: \n    " + htmlTag + "\nwith:\n    " + newHTMLTag);
            var newIndex = index.replace(htmlTag, newHTMLTag);
            if (newIndex === index) {
                print("Warning: No change!");
            } else {
                FILE.write(indexFilePath, newIndex, { charset : "UTF-8" });
            }
        }
    }
    else {
        print("Warning: Couldn't find <html> tag in "+indexFilePath);
    }

    // Add Content-Type "text/cache-manifest" for manifest file to .htaccess
    // This allows manifests to work out of the box on Apache (if htaccess overrides are allowed)
    var htaccessPath = FILE.join(productPath, ".htaccess");
    var htaccess = FILE.isFile(htaccessPath) ? FILE.read(htaccessPath, { charset : "UTF-8" }) : "";

    var htaccessOut = FILE.open(htaccessPath, "w", { charset : "UTF-8" });
    htaccessOut.print(htaccess);

    var openTag = "<Files "+manifestName+">";
    if (htaccess.indexOf(openTag) < 0) {
        htaccessOut.print("");
        htaccessOut.print(openTag);
        htaccessOut.print("\tHeader set Content-Type text/cache-manifest");
        htaccessOut.print("</Files>");
    }
    htaccessOut.close();
}
