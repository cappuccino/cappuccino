/*
 * AppController.j
 * CPLocalizationTest
 *
 * Created by You on April 20, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    var label = [CPTextField labelWithTitle:CPLocalizedString(@"Label from file", @"")];

    [label setFrameOrigin:CGPointMake(20, 10)];
    [[theWindow contentView] addSubview:label];

    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

@end
