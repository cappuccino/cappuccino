var fs = require('fs');
var path = require('path');
var childProcess = require("child_process");
var utilsFile = ObjectiveJ.utils.file;

function cleanup() {
    ["ToolsTestApp", "PressTestApp", "FlattenTestApp"].forEach(function(dir) {
        if (fs.existsSync(dir) && fs.lstatSync(dir).isDirectory())
            utilsFile.rm_rf(dir);
    });

    ["objj2objcskeletonTestFile.h", "objj2objcskeletonTestFile.m", "objj2objcskeletonTestFile.j", "objjWarningTestFile.j", "objjErrorTestFile.j"].forEach(function(file) {
        if (fs.existsSync(file) && fs.lstatSync(file).isFile())
            fs.rmSync(file);
    });
}

@implementation ToolsTest : OJTestCase
{
}

- (void)setUp
{
    cleanup();
    fs.writeFileSync("objj2objcskeletonTestFile.j", "@import <Foundation/CPObject.j>\n@import <AppKit/AppKit.j>\n\n\n@implementation AppController : CPObject\n{\n    @outlet CPSplitView splitViewA;\n    @outlet CPSplitView splitViewB;\n    @outlet CPSplitView splitViewC;\n}\n\n@end");
    fs.writeFileSync("objjWarningTestFile.j", "@import <Foundation/Foundation.j>@implementation AppController : CPObject{CPWindow theWindow;}@end");
    fs.writeFileSync("objjErrorTestFile.j", "@implementation AppController : CPObject{}@end");
}

- (void)tearDown
{
    cleanup();
}

- (void)testTools
{
    var status,
        rootDirectory = ""//FILE.cwd();

    [self assertNoThrow: function() {
        childProcess.execSync(["capp", "gen", "ToolsTestApp"].map(utilsFile.enquote).join(" ") + " > /dev/null", {stdio: 'inherit'});
    }];

    //status = childProcess.execSync(["press", "-f", "ToolsTestApp", "PressTestApp"].map(OS.enquote).join(" ") + " > /dev/null", {stdio: 'inherit'});
    //[self assert:0 equals:status message:"press failed"];

    //status = childProcess.execSync(["flatten", "-f", "ToolsTestApp", "FlattenTestApp"].map(OS.enquote).join(" ") + " > /dev/null", {stdio: 'inherit'});
    //[self assert:0 equals:status message:"flatten failed"];

    [self assertNoThrow: function() {
        childProcess.execSync(["objj", "ToolsTestApp/AppController.j"].map(utilsFile.enquote).join(" "), {stdio: 'ignore'});
    }];

    [self assertNoThrow: function() {
        childProcess.execSync(["objj", "-x", "ToolsTestApp/AppController.j"].map(utilsFile.enquote).join(" "), {stdio: 'ignore'});
    }];

    status = [self assertThrows: function() {
        debugger;
        return childProcess.execSync(["objj", "--xml", "objjErrorTestFile.j"].map(utilsFile.enquote).join(" "), {stdio: 'pipe'});
    }];
    [self assert:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version = \"1.0\"><array><dict><key>line</key><integer>1</integer><key>sourcePath</key><string>" + rootDirectory + "/objjErrorTestFile.j</string><key>message</key><string>\
\n@implementation AppController : CPObject{}@end\
\n                                ^\
\nERROR line 1 in file:" + rootDirectory + "/objjErrorTestFile.j:1: Can&apos;t find superclass CPObject</string></dict></array></plist>\n" equals:status message:"objj failed"];

    process.exit(0);
    status = [self assertNoThrow: function() {
        childProcess.execSync(["objj", "-x", "objjWarningTestFile.j"].map(utilsFile.enquote).join(" "), {stdio: 'inherit'});
    }];
    [self assert:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version = \"1.0\"><array><dict><key>line</key><integer>1</integer><key>sourcePath</key><string>" + rootDirectory + "/objjWarningTestFile.j</string><key>message</key><string>\n@import &lt;Foundation/Foundation.j&gt;@implementation AppController : CPObject{CPWindow theWindow;}@end\
\n                                                                          ^\
\nWARNING line 1 in file:" + rootDirectory + "/objjWarningTestFile.j:1: Unknown type &apos;CPWindow&apos; for ivar &apos;theWindow&apos;</string></dict></array></plist>\n" equals:status message:"objj failed"];

    [self assertNoThrow: function() {
        childProcess.execSync(["objj", "-m", "ToolsTestApp/AppController.j", "ToolsTestApp/AppController.j"], {stdio: 'inherit'});
    }];

    [self assertNoThrow: function() {
        childProcess.execSync(["objj", "-I", "ToolsTestApp/Frameworks", "ToolsTestApp/AppController.j"], {stdio: 'inherit'});
    }];

    [self assertNoThrow: function() {
        childProcess.execSync(["objj2objcskeleton", "objj2objcskeletonTestFile.j", "."], {stdio: 'inherit'});
    }];

    var contentHeader = fs.readFileSync("objj2objcskeletonTestFile.h"),
        expectedHeaderResult = "#import <Cocoa/Cocoa.h>\n#import \"xcc_general_include.h\"\n\n@interface AppController : NSObject\n\n@property (assign) IBOutlet NSSplitView* splitViewA;\n@property (assign) IBOutlet NSSplitView* splitViewB;\n@property (assign) IBOutlet NSSplitView* splitViewC;\n\n@end\n";

    [self assert:contentHeader equals:expectedHeaderResult message:@"Header generated by objj2objcskeleton is wrong"];

    var contentMFile = fs.readFileSync("objj2objcskeletonTestFile.m"),
        expectedMResult = "#import \"objj2objcskeletonTestFile.h\"\n\n@implementation AppController\n@end\n";

    [self assert:contentMFile equals:expectedMResult message:@"File generated by objj2objcskeleton is wrong"];
}

@end
