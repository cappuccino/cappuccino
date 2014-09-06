/*
 * AppController.j
 * CPPanelTest
 *
 * Created by You on June 18, 2014.
 * Copyright 2014, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPPanel     panel;
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

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)showPanel:(id)sender
{
    [panel makeKeyAndOrderFront:sender];
}

- (IBAction)closePanel:(id)sender
{
    [panel close];
}

@end
