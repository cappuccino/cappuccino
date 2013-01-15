var OS = require("os");
var FILE = require("file");

function cleanup() {
    ["ToolsTestApp", "PressTestApp", "FlattenTestApp"].forEach(function(dir) {
        if (FILE.isDirectory(dir))
            FILE.rmtree(dir);
    });
}

@implementation ToolsTest : OJTestCase
{
}

- (void)setUp
{
    cleanup();
}

- (void)testTools
{
    var status;

    status = OS.system(["capp", "gen", "ToolsTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"capp gen failed"];

    status = OS.system(["press", "-f", "ToolsTestApp", "PressTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"press failed"];

    status = OS.system(["flatten", "-f", "ToolsTestApp", "FlattenTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"flatten failed"];
}

- (void)tearDown
{
    cleanup();
}

@end
