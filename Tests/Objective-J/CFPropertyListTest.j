@global module

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

- (void)testDateDeserialization
{
    var path = FILE.join(FILE.dirname(module.path), "PropertyLists/XMLDate.plist"),
        object = CFPropertyList.readPropertyListFromFile(path),
        date = [object objectForKey:@"date"];

    [self assert:[CPDate class] equals:[date class]];
    [self assert:[[CPDate alloc] initWithString:"2012-01-01 10:00:00 +0100"] equals:date];
}

@end
