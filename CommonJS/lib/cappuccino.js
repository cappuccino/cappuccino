var FILE = require("file");
var sprintf = require("printf").sprintf;

var pkg = null;
function getPackage() {
    if (!pkg)
        pkg = JSON.parse(FILE.path(module.path).dirname().dirname().join("package.json").read({ charset : "UTF-8" }));
    return pkg;
}

exports.version = function() { return getPackage()["version"]; }
exports.revision = function() { return getPackage()["cappuccino-revision"]; }
exports.timestamp = function() { return new Date(getPackage()["cappuccino-timestamp"]); }

exports.fullVersionString = function() {
    return sprintf("cappuccino %s (%04d-%02d-%02d %s)",
        exports.version(),
        exports.timestamp().getUTCFullYear(),
        exports.timestamp().getUTCMonth()+1,
        exports.timestamp().getUTCDate(),
        exports.revision().slice(0,6)
    );
}
