
var OS = require("os");

exports.fontinfo = function(name, size)
{
    var p = OS.popen(["fontinfo", "-n", name, size || 12]);

    if (p.wait() === 0)
        return JSON.parse(p.stdout.read());
    else
        return null;
};
