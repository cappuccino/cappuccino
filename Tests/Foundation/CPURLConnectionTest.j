
@implementation CPURLConnectionTest : OJTestCase
{
}

- (void)testSynchronousRequestSuccess
{
    var req = [CPURLRequest requestWithURL:@"Tests/Foundation/CPURLConnectionTest.j"],    
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assert:CPData equals:[data class]];
    [self assertNotNull:data];
    [self assertFalse:([data rawString] == @"")];
}

- (void)testSynchronousRequestNotFound
{
    var req = [CPURLRequest requestWithURL:@"NotFound"],    
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assertNull:data];
}

@end