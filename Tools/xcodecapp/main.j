
@import "XCProject.j"

var FILE = require("file"),
    OS = require("os");

var project = [[XCProject alloc] initWithPath:FILE.cwd()];

while (YES)
{
    [project update];

    OS.sleep(1);
}

