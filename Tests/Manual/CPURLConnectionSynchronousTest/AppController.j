/*
 * AppController.j
 * CPURLConnectionSynchronousTest
 *
 * Created by You on July 28, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    BOOL _success;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    _success = YES;

    [self testSynchronousRequestSuccess];
    [self testSynchronousRequestNotFound];
    
    if (_success)
        write("</br>All Tests Passed In Test Suite", "green");
    else
        write("</br>One Or More Test Failed", "red");
}

- (void)testSynchronousRequestSuccess
{
    write(_cmd , "black");

    var req = [CPURLRequest requestWithURL:@"Info.plist"],    
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assertTrue:(CPData == [data class])];
    [self assertTrue:([data rawString] != @"")];
}

- (void)testSynchronousRequestNotFound
{
    write(_cmd , "black");

    var req = [CPURLRequest requestWithURL:@"NotFound"],    
        data = [CPURLConnection sendSynchronousRequest:req returningResponse:nil];

    [self assertTrue:(data === nil)];
}

- (void)assertTrue:(BOOL)result
{
    if (!result)
    {
        write("Test Failed", "red");
        _success = NO;
    }
}

@end

function write(text, color)
{
    document.write("<span style=\"color:"+color+"\">"+text+"</span></br>");
}