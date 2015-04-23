
var OS = require("os");

exports.fontinfo = function(name, size)
{
    var p = OS.popen(["fontinfo", "-n", name, size || 12]),
        result;

    if (p.wait() === 0)
        result = p.stdout.read();

    p.stdin.close();
    p.stdout.close();
    p.stderr.close();

    if (result)
        return JSON.parse(result);
    else
        return null;
};
