@import <OJUnit/OJTestCase.j>

@implementation CFHTTPRequestTest : OJTestCase
{
}

- (void)testSetWithCredentials
{
    var cfHTTPRequest = new CFHTTPRequest();
    [self assertFalse:cfHTTPRequest.withCredentials()];

    cfHTTPRequest.setWithCredentials(YES);
    [self assertTrue:cfHTTPRequest.withCredentials()];
}

@end
