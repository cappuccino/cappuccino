@import <OJUnit/OJTestCase.j>

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
    var req = [CPURLRequest requestWithURL:@"file:Tests/Foundation/CPURLConnectionTest.j"],
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assert:CPData equals:[data class]];
    [self assertNotNull:data];
    [self assertFalse:([data rawString] == @"")];
}

- (void)testSynchronousRequestNotFound
{
    var req = [CPURLRequest requestWithURL:@"file:NotFound"],
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assertNull:data];
}

- (void)testClassMethodConnectionWithCredentials
{
    var req = [CPURLRequest requestWithURL:[CPURL URLWithString:@"file:Tests/Foundation/CPURLConnectionTest.j"]];
    [req setWithCredentials:YES];
    var data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assertNotNull:data];
}

- (void)testInstanceMethodConnectionWithCredentials
{
    var req = [CPURLRequest requestWithURL:[CPURL URLWithString:@"file:Tests/Foundation/CPURLConnectionTest.j"]];
    [req setWithCredentials:YES];

    var conn = [[CPURLConnection alloc] initWithRequest:req delegate:nil startImmediately:NO];

    [self assertTrue:conn._HTTPRequest.withCredentials];

    [req setWithCredentials:NO];
    [self assertTrue:conn._HTTPRequest.withCredentials];
}

- (void)testRequestGetters
{
    var req = [CPURLRequest requestWithURL:[CPURL URLWithString:@"file:Tests/Foundation/CPURLConnectionTest.j"]],
        conn = [[CPURLConnection alloc] initWithRequest:req delegate:nil startImmediately:NO];
    
    var originalRequest = [conn originalRequest],
        currentRequest = [conn currentRequest];

    [self assert:originalRequest._UID notEqual:currentRequest._UID];

    [[conn currentRequest] setWithCredentials:YES];
    [self assert:[originalRequest withCredentials] notEqual:[currentRequest withCredentials]];
}

// New modern Async Tests

- (async void)testSendAsynchronousRequestSuccess
{
    var req = [CPURLRequest requestWithURL:@"file:Tests/Foundation/CPURLConnectionTest.j"];
    
    // Await the promise wrapper
    const { response, data, error } = await [CPURLConnection sendAsynchronousRequest:req];

    // Assert structure
    [self assertNull:error];
    [self assertNotNull:response];
    [self assertNotNull:data];
    
    // Validate Content
    [self assert:CPData equals:[data class]];
    [self assertTrue:[[data rawString] containsString:@"@implementation CPURLConnectionTest"]];
}

- (async void)testFetchRequestSuccess
{
    // Fetch API often has stricter security on file:// protocols than XHR, 
    // but this should work in a local test runner environment if configured correctly.
    var req = [CPURLRequest requestWithURL:@"file:Tests/Foundation/CPURLConnectionTest.j"];
    
    const { response, data, error } = await [CPURLConnection fetch:req];

    if (error)
        CPLog(@"Fetch Error (Likely CORS on file://): %@", [error description]);

    [self assertNull:error];
    [self assertNotNull:response];
    [self assertNotNull:data];
    
    // Verify that fetch actually retrieved the data
    [self assertTrue:[[data rawString] length] > 0];
    [self assertTrue:[[data rawString] containsString:@"CPURLConnectionTest"]];
}

- (async void)testFetchRequestNotFound
{
    var req = [CPURLRequest requestWithURL:@"file:Tests/Foundation/FileThatDoesNotExist.j"];
    
    const { response, data, error } = await [CPURLConnection fetch:req];
    
    // Behavior depends on browser/environment implementation of fetch for file://
    // It will either return a 404/0 status code OR an error object.
    
    if (error)
    {
        // If it threw a network error (common for file:// 404s in some browsers)
        [self assertNotNull:error];
        [self assertNull:data];
    }
    else
    {
        // If it returned a response object (common for http:// 404s)
        var status = [response statusCode];
        
        // 0 is often returned for failed local file loads, 404 for HTTP
        var isFailureCode = (status === 0 || status === 404);
        [self assertTrue:isFailureCode]; 
    }
}

- (async void)testFetchAbortTimeout
{
    // Create a request with a very short timeout
    // Using a remote URL (non-existent domain) ensures it doesn't resolve instantly
    var req = [CPURLRequest requestWithURL:@"http://nonexistent.cappuccino.dev"]; 
    [req setTimeoutInterval:0.001]; // 1ms timeout
    
    const { response, data, error } = await [CPURLConnection fetch:req];

    [self assertNotNull:error];
    [self assertNull:data];
    [self assert:@"The request timed out." equals:[[error userInfo] objectForKey:@"LocalizedDescription"]];
}

@end
