
@implementation CPURLConnectionTest : OJTestCase
{
}

- (void)testParseHTTPHeaders
{
    var testHeader = "Server: gunicorn/0.17.1\r\nDate: Fri, 11 Jan 2013 10:32:43 GMT\r\nConnection: close\r\nTransfer-Encoding: chunked\r\nVary: Accept, Cookie\r\nContent-Type: application/json; charset=utf-8\r\nCache-Control: no-cache\r\n",
        parsed = [CPHTTPURLResponse parseHTTPHeaders:testHeader];

    [self assert:@"gunicorn/0.17.1" equals:[parsed valueForKey:@"Server"]];
    [self assert:@"Fri, 11 Jan 2013 10:32:43 GMT" equals:[parsed valueForKey:@"Date"]];
    [self assert:@"close" equals:[parsed valueForKey:@"Connection"]];
    [self assert:@"chunked" equals:[parsed valueForKey:@"Transfer-Encoding"]];
    [self assert:@"Accept, Cookie" equals:[parsed valueForKey:@"Vary"]];
    [self assert:@"application/json; charset=utf-8" equals:[parsed valueForKey:@"Content-Type"]];
    [self assert:@"no-cache" equals:[parsed valueForKey:@"Cache-Control"]];
    [self assert:7 equals:[[parsed allKeys] count]];
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