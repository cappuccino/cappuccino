
var OS = require("os");

exports.imagesize = function(path)
{
    var p = OS.popen(["imagesize", "-n", path]),
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
