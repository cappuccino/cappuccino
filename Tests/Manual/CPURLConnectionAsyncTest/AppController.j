/*
 * AppController.j
 * CPURLConnectionAsyncTest
 *
 * Created by You on February 1, 2012.
 * Copyright 2012, Your Company All rights reserved.

 This test needs to be at the root of your Web Server (http://localhost/CPURLConnectionAsyncTest/) and with php enabled.
 For each test, we start 3 async connections and we setup the resulting operations to be dependant one from each other. The connection received after the smallest delay is dependant on a connection received with a longer delay.
    We test that dedendant operations are perfomed before their dependencies.
    We also test that in the completionHandler(response, data, error), the data and error params are mututally exclusive.*/

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    @outlet CPTextField testField;
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPOperationQueue queue;
    CPArray results;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (CPURLConnection)startAsyncConnection:(CPInteger)idx responseStatus:(CPInteger)aStatus delay:(CPInteger)aDelay isLast:(BOOL)isLast
{
    var resourcePath = [[CPBundle mainBundle] resourcePath],
        url = [CPURL URLWithString:[CPString stringWithFormat:@"%@delayed.php?sleep=%@&status=%@", resourcePath, aDelay, aStatus]],
        request = [CPURLRequest requestWithURL:url];

    return [self startAsyncConnection:idx request:request isLast:isLast];
}

- (CPURLConnection)startAsyncConnection:(CPInteger)idx request:(CPURLRequest)request isLast:(BOOL)isLast
{
    var connection = [CPURLConnection sendAsynchronousRequest:request queue:queue completionHandler:function (response, data, error)
    {
        var status;

        if (error == nil)
            error = [CPNull null];

        if (data == nil)
            data = [CPNull null];

        if (response == nil)
            status = -1;
        else
            status = [response statusCode];

        CPLog.debug([request URL] + "\nRESPONSE:" + response + "\nDATA:" + data + "\nERROR:" + [error description]);

        [results addObject:@{"conn_id":idx, "data":data, "status":status, "error":error}];

        // We received all the responses to the connections we launched (3).
        if ([results count] == 3)
        {
            var test = [self testResults];
            [testField setStringValue:((test) ? "Test passed" : @"Test failed")];
        }
    }];

    return connection;
}

- (BOOL)testResults
{
    if ([results count] !== 3)
        return NO;

    // In theses tests, we send connections 1,2,3 and we expect the operations to be performed in reverse order: 3,2,1 because of the dependencies we set up.
    if (![[results valueForKey:@"conn_id"] isEqualToArray:@[3,2,1]])
        return NO;

    var nul = [CPNull null];

    for (var i = 0; i < [results count]; i++)
    {
        var res = [results objectAtIndex:i],
            noData = [res objectForKey:@"data"] == nul,
            noError = [res objectForKey:@"error"] == nul;

        if (noData == noError)
            return NO;
    }

    return YES;
}

- (IBAction)test1:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 responseStatus:200 delay:2 isLast:NO],
        connection3 = [self startAsyncConnection:3 responseStatus:200 delay:3 isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test2:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 responseStatus:404 delay:2 isLast:NO],
        connection3 = [self startAsyncConnection:3 responseStatus:200 delay:3 isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test3:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 responseStatus:200 delay:2 isLast:NO],
        connection3 = [self startAsyncConnection:3 responseStatus:404 delay:3 isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test4:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 responseStatus:403 delay:2 isLast:NO],
        connection3 = [self startAsyncConnection:3 responseStatus:404 delay:3 isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test5:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:404 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 responseStatus:1000 delay:2 isLast:NO],
        connection3 = [self startAsyncConnection:3 responseStatus:404 delay:3 isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test6:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];
    [testField setStringValue:@"Waiting for response ..."];

    var request = [CPURLRequest requestWithURL:"dummy"],
        connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 request:request isLast:NO],
        connection3 = [self startAsyncConnection:3 request:request isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (IBAction)test7:(id)sender
{
    results = @[];
    queue = [[CPOperationQueue alloc] init];

    var resourcePath = [[CPBundle mainBundle] resourcePath],
        url = [CPURL URLWithString:[CPString stringWithFormat:@"%@delayed.php?sleep=%@&status=%@", resourcePath, 10, 200]],
        timeoutrequest = [CPURLRequest requestWithURL:url cachePolicy:CPURLRequestUseProtocolCachePolicy timeoutInterval:3],
        nourl = [CPURLRequest requestWithURL:@"nourl"];

    [testField setStringValue:@"Waiting for response ..."];

    var connection1 = [self startAsyncConnection:1 responseStatus:200 delay:1 isLast:YES],
        connection2 = [self startAsyncConnection:2 request:nourl isLast:NO],
        connection3 = [self startAsyncConnection:3 request:timeoutrequest isLast:NO];

    [[connection1 operation] addDependency:[connection2 operation]];
    [[connection2 operation] addDependency:[connection3 operation]];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

@end