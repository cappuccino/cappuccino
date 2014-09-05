
@implementation CFURLTest : OJTestCase
{
}

- (void)testRelativeURLs
{
    var URLStrings =
    {
        "g:h"           : "g:h",
        "g"             : "http://a/b/c/g",
        "./g"           : "http://a/b/c/g",
        "g/"            : "http://a/b/c/g/",
        "/g"            : "http://a/g",
        //"//g"           : "http://g",
        "?y"            : "http://a/b/c/?y",
        "g?y"           : "http://a/b/c/g?y",
        //"#s"            : "(current document)#s",
        "g#s"           : "http://a/b/c/g#s",
        "g?y#s"         : "http://a/b/c/g?y#s",
        ";x"            : "http://a/b/c/;x",
        "g;x"           : "http://a/b/c/g;x",
        "g;x?y#s"       : "http://a/b/c/g;x?y#s",
        "."             : "http://a/b/c/",
        "./"            : "http://a/b/c/",
        ".."            : "http://a/b/",
        "../"           : "http://a/b/",
        "../g"          : "http://a/b/g",
        "../.."         : "http://a/",
        "../../"        : "http://a/",
        "../../g"       : "http://a/g",
        "../../../g"    : "http://a/g",//"http://a/../g",
        "../../../../g" : "http://a/g",//"http://a/../../g",
        "/./g"          : "http://a/g",//"http://a/./g",
        "/../g"         : "http://a/g",//"http://a/../g",
        "g."            : "http://a/b/c/g.",
        ".g"            : "http://a/b/c/.g",
        "g.."           : "http://a/b/c/g..",
        "..g"           : "http://a/b/c/..g",
        "./../g"        :  "http://a/b/g",
        "./g/."         :  "http://a/b/c/g/",
        "g/./h"         :  "http://a/b/c/g/h",
        "g/../h"        :  "http://a/b/c/h",
        "g;x=1/./y"     :  "http://a/b/c/g;x=1/y",
        "g;x=1/../y"    :  "http://a/b/c/y",
        "g?y/./x"       :  "http://a/b/c/g?y/./x",
        "g?y/../x"      :  "http://a/b/c/g?y/../x",
        "g#s/./x"       :  "http://a/b/c/g#s/./x",
        "g#s/../x"      :  "http://a/b/c/g#s/../x"
    };

    var URLString,
        baseURL = new CFURL("http://a/b/c/d;p?q");

    for (URLString in URLStrings)
        if (URLStrings.hasOwnProperty(URLString))
        {
//            print(URLStrings[URLString] + " " + new CFURL(URLString, baseURL).absoluteString());
            [self assert:URLStrings[URLString] equals:new CFURL(URLString, baseURL).absoluteString()];
        }
}

- (void)testPeriods
{
    var URLStrings =
    {
        "."             : "./",
        "./"            : "./",
        ".//"           : "./",
        "/."            : "/",
        "/./"           : "/",
        "/.//"          : "/",
        "./a/"          : "a/",
        "./a"           : "a",
        ".."            : "../",
        "../"           : "../",
        "..//"          : "../",
        "/.."           : "/",
        "/../"          : "/",
        "/..//"         : "/",
        "../a/"         : "../a/",
        "../a"          : "../a"
    };

    var URLString;

    for (URLString in URLStrings)
        if (URLStrings.hasOwnProperty(URLString))
            [self assert:new CFURL(URLString).absoluteString() equals:URLStrings[URLString]];
}

- (void)testDoubleSlash
{
    [self assert:"//a" equals:new CFURL("//a").absoluteString()];
    [self assert:"ftp://a" equals:new CFURL("//a", new CFURL("ftp://example.com/b")).absoluteString()];
    [self assert:"ftp://example.com/a" equals:new CFURL("/a", new CFURL("ftp://example.com/b")).absoluteString()];
}

@end
