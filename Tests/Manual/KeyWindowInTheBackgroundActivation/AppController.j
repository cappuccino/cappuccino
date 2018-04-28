/*
 * AppController.j
 * WindowFrontTest
 *
 * Created by You on January 15, 2018.
 * Copyright 2018, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPWindow window1;
    @outlet CPWindow window2;
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
    
    [window1 performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.1];
}

- (IBAction)bringWindow2Front:(id)sender
{
	[window2 orderFront:self];
}

@end
