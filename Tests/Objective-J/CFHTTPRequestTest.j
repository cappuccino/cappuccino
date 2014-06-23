@import <OJUnit/OJTestCase.j>

@implementation CFHTTPRequestTest : OJTestCase
{
}

- (void)testSetWithCredentials
{
    var cfHTTPRequest = new CFHTTPRequest();
    [self assertFalse:cfHTTPRequest.getWithCredentials()];

    cfHTTPRequest.setWithCredentials(YES);
    [self assertTrue:cfHTTPRequest.getWithCredentials()];
}

@end
