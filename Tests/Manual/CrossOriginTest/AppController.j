/*
 * AppController.j
 * CrossOriginTest
 *
 * Created by You on December 5, 2014.
 * Copyright 2014, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

var corsServer = "http://localhost:8001";

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPButton    theButton;
    @outlet CPButton    setsWithCredentials;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response
{
    console.log("Response received");
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var wc = ([[connection originalRequest] withCredentials]) ? "YES" : "NO"
    console.log("CPURLConnection was sent with credentials? " + wc + " Response: " + data);
}

- (@action)stateOfWithCredentials:(id)aSender
{
    console.log([setsWithCredentials state]);
}

- (@action)testCappuccinoRequest:(id)aSender
{
    var req = [CPURLRequest requestWithURL:[CPURL URLWithString:corsServer + @"/resp.json"]];
    [req setValue:@"no-cache" forHTTPHeaderField:@"Pragma"];
    [req setValue:@"no-store, no-cache, must-revalidate, post-check=0, pre-check=0" forHTTPHeaderField:@"Cache-Control"];
    [req setWithCredentials:[setsWithCredentials state]];
    [[CPURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
}

- (@action)testNativeRequest:(id)aSender
{
    var wc = ([setsWithCredentials state]) ? true : false;
    var req = new XMLHttpRequest();
    function reqListener ()
    {
        console.log("Native XHR was sent with credentials? " + wc + " Response: " + this.responseText);
    }

    req.onload = reqListener;
    req.withCredentials = wc;
    req.open("GET", corsServer + "/resp.json", true);
    req.setRequestHeader("Pragma", "no-cache");
    req.setRequestHeader("Cache-Control", "no-store, no-cache, must-revalidate, post-check=0, pre-check=0");

    req.send();
}

@end
