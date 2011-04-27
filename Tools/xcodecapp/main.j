
@import "XCProject.j"

var FILE = require("file"),
    OS = require("os"),
    parser = new (require("narwhal/args").Parser)()


function main(args)
{
    CPLogRegister(CPLogPrint, null);

    try
    {
        var options = parseOptions(args),
            ignoreFilePath,
            loopDelay = 1,
            openProject = YES;

        if (options.ignorepath)
            ignoreFilePath = options.ignorepath;

        if (options.loopdelay)
            loopDelay = parseInt(options.loopdelay);

        if (options.noproject)
            openProject = NO;

        run(ignoreFilePath, loopDelay, openProject);
    }
    catch (anException)
    {
        CPLog.fatal(exceptionReason(anException));
        OS.exit(1);
    }
}

function parseOptions(args)
{
    parser.usage("[--loop-delay SECONDS] [--ignorepath PATH] [--noproject]");

    parser.option("--loop-delay", "loopdelay")
        .set()
        .displayName("time")
        .help("Define the delay between two watch loops");

    parser.option("--ignorepath", "ignorepath")
        .set()
        .displayName("path")
        .help("The path to the ignore list. By default it is ./.xcodecapp-ignore");

    parser.option("--noproject", "noproject")
        .set(true)
        .help("If this option is set, the XCode project will not be opened");

    parser.helpful();

    return parser.parse(args, null, null, true);
}

function exceptionReason(exception)
{
    if (typeof(exception) === "string")
        return exception;
    else if (exception.isa && [exception respondsToSelector:@selector(reason)])
        return [exception reason];
    else
        return "An unknown error occurred";
}

function run(anIgnoreFilePath, loopDelay, shouldOpenProject)
{
    var project = [[XCProject alloc] initWithPath:FILE.cwd() ignoreFilePath:anIgnoreFilePath shouldOpenProject:shouldOpenProject];

    while (YES)
    {
        [project update];

        OS.sleep(loopDelay);
    }
}
