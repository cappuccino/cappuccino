/*
 * AppController.j
 * WindowSheetOrderTest
 *
 * Created by You on March 23, 2018.
 * Copyright 2018, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
    @outlet CPWindow window;
    @outlet CPWindow window2;
    @outlet CPWindow sheetWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [window makeKeyAndOrderFront:self];
    [CPApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    [window2 performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.4];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)closeSheet:(idf)sender
{
	[CPApp endSheet:sheetWindow];
}

@end
