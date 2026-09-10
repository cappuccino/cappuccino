/*
 * AppController.j
 * CPProgressIndicator
 *
 * Created by Alexander Ljungberg on May 3, 2012.
 * Copyright 2012, SlevenBits Ltd. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPWindow.j>

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPProgressIndicator fiftyPercentBar @accessors;
    @outlet CPProgressIndicator hundredPercentBar @accessors;

    @outlet CPProgressIndicator twentyPercentCircular @accessors;
    @outlet CPProgressIndicator fiftyPercentCircular @accessors;
    @outlet CPProgressIndicator hundredPercentCircular @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // Interface Builder does not encode the current progress.
    [fiftyPercentBar setDoubleValue:50];
    [hundredPercentBar setDoubleValue:100];

    [twentyPercentCircular setMaxValue:200];
    [twentyPercentCircular setMinValue:50];
    [twentyPercentCircular setDoubleValue:80];

    [fiftyPercentCircular setDoubleValue:50];
    [hundredPercentCircular setDoubleValue:100];

    [theWindow center];
}

@end
