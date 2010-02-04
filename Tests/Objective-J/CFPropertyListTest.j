
var FILE = require("file"),
    FileList = require("jake").FileList;

@implementation CFPropertyListTest : OJTestCase

- (void)testFormatSniffing
{
    var XMLPropertyLists = new FileList(FILE.join(FILE.dirname(module.path), "PropertyLists", "XML-*.plist"));

    XMLPropertyLists.forEach(function(/*String*/ aPath)
    {
        [self assert:CFPropertyList.FormatXML_v1_0 equals:CFPropertyList.sniffedFormatOfString(FILE.read(aPath))];
    });
}

@end
