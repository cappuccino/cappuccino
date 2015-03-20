@import <OJUnit/OJTestCase.j>


var exampleURL = "http://www.cappuccino-project.org";

@implementation CPURLRequestTest : OJTestCase
{
}

- (void)testClassMethods
{
    var url = [CPURL URLWithString:exampleURL],
        req = [CPURLRequest requestWithURL:url];

    [self assert:[req HTTPMethod] equals:@"GET"];
    [self assert:[req URL] equals:url];
}

- (void)testWithCredentials
{
    var url = [CPURL URLWithString:exampleURL],
        req = [CPURLRequest requestWithURL:url];

    [self assertFalse:[req withCredentials]];

    [req setWithCredentials:YES];
    [self assertTrue:[req withCredentials]];
}

@end