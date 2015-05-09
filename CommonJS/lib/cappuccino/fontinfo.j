
var OS = require("os");

exports.fontinfo = function(name, size)
{
    var result;

    try
    {
        var p = OS.popen(["fontinfo", "-n", name, size || 12]);
        if (p.wait() === 0)
            result = p.stdout.read();
    }
    finally
    {
        p.stdin.close();
        p.stdout.close();
        p.stderr.close();
    }

    return result ? JSON.parse(result) : null;
};
