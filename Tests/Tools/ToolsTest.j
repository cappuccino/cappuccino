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

    status = OS.system(["capp", "gen", "ToolsTestApp"]);
    [self assert:status equals:0 message:"capp gen failed"];

    status = OS.system(["press", "-f", "ToolsTestApp", "PressTestApp"]);
    [self assert:status equals:0 message:"press failed"];

    status = OS.system(["flatten", "-f", "ToolsTestApp", "FlattenTestApp"]);
    [self assert:status equals:0 message:"flatten failed"];
}

- (void)tearDown
{
    cleanup();
}

@end
