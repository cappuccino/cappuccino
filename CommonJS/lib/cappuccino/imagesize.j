
var OS = require("os");

exports.imagesize = function(path)
{
    var p = OS.popen(["imagesize", "-n", path]);

    if (p.wait() === 0)
        return JSON.parse(p.stdout.read());
    else
        return null;
};
