@global module

var fs = require("fs"),
    path = require("path"),
    FileList = ObjectiveJ.utils.filelist.FileList;

@implementation CFPropertyListTest : OJTestCase

- (void)testFormatSniffing
{
    debugger;
    var XMLPropertyLists = new FileList(path.join(path.dirname(__filename), "PropertyLists", "XML-*.plist"));

    XMLPropertyLists.forEach(function(/*String*/ aPath)
    {
        [self assert:CFPropertyList.FormatXML_v1_0 equals:CFPropertyList.sniffedFormatOfString(fs.readFileSync(aPath).toString())];
    });
}

- (void)testDateDeserialization
{
    var p = path.join(path.dirname(__filename), "PropertyLists/XMLDate.plist"),
        object = CFPropertyList.readPropertyListFromFile(p),
        date = [object objectForKey:@"date"];

    [self assert:[CPDate class] equals:[date class]];
    [self assert:[[CPDate alloc] initWithString:"2012-01-01 10:00:00 +0100"] equals:date];
}

- (void)testPropertyListFromXMLShouldHandleEmptyXMLGracefully {
    // rhino can't parse empty XML documents
    if (system.engine !== "rhino") {
        var XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
            object = CFPropertyList.propertyListFromXML(XML);
    
        [self assert:object equals:null];
    }
}

- (void)testPropertyListFromXMLShouldHandleEmptierXMLGracefully {
    // rhino can't parse empty XML documents
    if (system.engine !== "rhino") {
        var XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            object = CFPropertyList.propertyListFromXML(XML);
    
        [self assert:object equals:null];
    }
}

// This is removed as the Node module xmldom/xmldom will print out an error (will not fail) when the xml string is empty
/*- (void)testPropertyListFromXMLShouldHandleEmptiestXMLGracefully {
    // rhino can't parse empty XML documents
    if (system.engine !== "rhino") {
        var XML = "",
            object = CFPropertyList.propertyListFromXML(XML);
    
        [self assert:object equals:null];
    }
}*/

- (void)testPropertyListFromXMLShouldParseNiceAndCleanXML {
    var XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>Main cib file base name</key><string>MainMenu.cib</string><key>CPBundleName</key><string>CopyAndPaste</string><key>CPBundleVersion</key><string>1.0</string><key>CPHumanReadableCopyright</key><string>Copyright \u00a9 2013, SlevenBits, Ltd. All rights reserved.</string></dict></plist>",
        object = CFPropertyList.propertyListFromXML(XML);
    
    [self assert:[object valueForKey:"Main cib file base name"] equals:"MainMenu.cib"];
    [self assert:[object valueForKey:"CPBundleName"] equals:"CopyAndPaste"];
    [self assert:[object valueForKey:"CPBundleVersion"] equals:"1.0"];
    [self assert:[object valueForKey:"CPHumanReadableCopyright"] equals:"Copyright \u00a9 2013, SlevenBits, Ltd. All rights reserved."];
    [self assert:[object count] equals:4];
}

- (void)testPropertyListFromXMLShouldIgnoreWhiteSpace{
    var XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!--Some really fab XML coming here--> <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> <!--Get ready, this will be great--> \n<plist version=\"1.0\"> \n<dict>\n\t<key>Main cib file base name</key>\n\t<string>MainMenu.cib</string>\n\t <key>CPBundleName</key>\n\t<string>CopyAndPaste</string>\n    <key>CPBundleVersion</key>\n    <string>1.0</string>\n    <key>CPHumanReadableCopyright</key>\n    <string>Copyright \u00a9 2013, SlevenBits, Ltd. All rights reserved.</string>\n</dict>\n</plist>\n",
        // feed in preparsed XML to ensure we preserve whitespace for purposes of this test
        object = CFPropertyList.propertyListFromXML(new window.DOMParser().parseFromString(XML, "text/xml"));
    
    [self assert:[object valueForKey:"Main cib file base name"] equals:"MainMenu.cib"];
    [self assert:[object valueForKey:"CPBundleName"] equals:"CopyAndPaste"];
    [self assert:[object valueForKey:"CPBundleVersion"] equals:"1.0"];
    [self assert:[object valueForKey:"CPHumanReadableCopyright"] equals:"Copyright \u00a9 2013, SlevenBits, Ltd. All rights reserved."];
    [self assert:[object count] equals:4];
}

@end
