
var OS = require("os");

exports.imagesize = function(path)
{
    var result;

    try
    {
        var p = OS.popen(["imagesize", "-n", path]);
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
