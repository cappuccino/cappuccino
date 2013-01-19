@import <Foundation/CPURL.j>

var exampleProtocol = "http",
    exampleUser = "foo",
    examplePassword = "bar",
    exampleHost = "cappuccino-project.org",
    examplePort = 80,
    exampleAuthority = exampleUser + ":" + examplePassword + "@" + exampleHost + ":" + examplePort,
    examplePathBase = "/contribute/",
    examplePathRelative = "coding-style.php",
    exampleFullPath = examplePathBase + examplePathRelative,
    exampleQuery = "foo=bar",
    exampleAnchor = "baz",
    exampleURL = exampleProtocol + "://" + exampleAuthority + exampleFullPath + "?" + exampleQuery + "#" + exampleAnchor;

@implementation CPURLTest : OJTestCase
{
}

- (void)testAbsolute
{
    var pathString = exampleFullPath,
        urlString = exampleURL,
        url = [CPURL URLWithString:urlString];

    [self assert:[url baseURL] equals:nil];

    [self assert:[url relativeString] equals:urlString];
    [self assert:[url absoluteString] equals:urlString];

    [self assert:[url relativePath] equals:pathString];
    [self assert:[url path] equals:pathString];

    [self assert:[url absoluteURL] same:url];

    [self assert:[url scheme] equals:exampleProtocol];
    [self assert:[url user] equals:exampleUser];
    [self assert:[url password] equals:examplePassword];
    [self assert:[url host] equals:exampleHost];
    [self assert:[url port] equals:examplePort];
    [self assert:[url parameterString] equals:exampleQuery];
    [self assert:[url fragment] equals:exampleAnchor];

    [self assert:[url pathExtension] equals:"php"];
    [self assert:[url lastPathComponent] equals:examplePathRelative];
}

- (void)testRelative
{
    var baseString = exampleProtocol + "://" + exampleAuthority + examplePathBase,
        pathString = examplePathRelative,
        urlString = examplePathRelative + "?" + exampleQuery + "#" + exampleAnchor,
        baseURL = [CPURL URLWithString:baseString],
        url = [CPURL URLWithString:urlString relativeToURL:baseURL];

    [self assert:[url baseURL] equals:baseURL];

    [self assert:[url relativeString] equals:urlString];
    [self assert:[url absoluteString] equals:exampleURL];

    [self assert:[url relativePath] equals:pathString];
    [self assert:[url path] equals:exampleFullPath];

    [self assert:[url absoluteURL] notSame:url];

    [self assert:[url scheme] equals:exampleProtocol];
    [self assert:[url user] equals:exampleUser];
    [self assert:[url password] equals:examplePassword];
    [self assert:[url host] equals:exampleHost];
    [self assert:[url port] equals:examplePort];
    [self assert:[url parameterString] equals:exampleQuery];
    [self assert:[url fragment] equals:exampleAnchor];

    [self assert:[url pathExtension] equals:"php"];
    [self assert:[url lastPathComponent] equals:examplePathRelative];
}

- (void)testRelativeNoBase
{
    var pathString = examplePathRelative,
        urlString = examplePathRelative + "?" + exampleQuery + "#" + exampleAnchor,
        url = [CPURL URLWithString:urlString];

    [self assert:[url baseURL] equals:nil];

    [self assert:[url relativeString] equals:urlString];
    [self assert:[url absoluteString] equals:urlString];

    [self assert:[url relativePath] equals:pathString];
    [self assert:[url path] equals:pathString];

    [self assert:[url absoluteURL] same:url];

    [self assert:[url scheme] equals:nil];
    [self assert:[url user] equals:nil];
    [self assert:[url password] equals:nil];
    [self assert:[url host] equals:nil];
    [self assert:[url port] equals:nil];
    [self assert:[url parameterString] equals:exampleQuery];
    [self assert:[url fragment] equals:exampleAnchor];

    [self assert:[url pathExtension] equals:"php"];
    [self assert:[url lastPathComponent] equals:examplePathRelative];
}

- (void)testDeleteComponent
{
    var url = [CPURL URLWithString:exampleFullPath];

    url = [url URLByDeletingLastPathComponent];
    [self assert:[url absoluteString] equals:examplePathBase.substring(0, examplePathBase.length - 1)];

    url = [url URLByDeletingLastPathComponent];
    [self assert:[url absoluteString] equals:@"/"];

    url = [url URLByDeletingLastPathComponent];
    [self assert:[url absoluteString] equals:@"/"];

    url = [CPURL URLWithString:@"foo"];
    url = [url URLByDeletingLastPathComponent];
    [self assert:[url absoluteString] equals:@""];
}

- (void)testURLToString
{
    [self assert:String([CPURL URLWithString:exampleURL]) equals:exampleURL];
}

- (void)testIsEqual
{
    var url = [CPURL URLWithString:@"http://www.cappuccino-project.org"],
        url2 = [CPURL URLWithString:@"http://www.cappuccino-project.org"],
        url3 = [CPURL URLWithString:@"http://www.cappuccino-project.org/index.html"],
        url4 = [CPURL URLWithString:@"http://www.cappuccino-project.org//index.html"];

    [self assert:url equals:url];
    [self assert:url equals:url2];
    [self assert:url notEqual:url3];
    [self assert:url notEqual:[CPNull null]];
    [self assert:url3 equals:url4];
}

- (void)testIsEqualToURL
{
    var url = [CPURL URLWithString:@"http://www.cappuccino-project.org"],
        url2 = [CPURL URLWithString:@"http://www.cappuccino-project.org"],
        url3 = [CPURL URLWithString:@"http://www.cappuccino-project.org/index.html"];

    [self assertTrue:[url isEqualToURL:url]];
    [self assertTrue:[url isEqualToURL:url2]];
    [self assertFalse:[url isEqualToURL:url3]];
}

@end
