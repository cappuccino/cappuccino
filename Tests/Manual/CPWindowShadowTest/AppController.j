/*
 * AppController.j
 * CPWindowShadowTest
 *
 * Created by You on February 24, 2017.
 * Copyright 2017, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

// TO DISABLE THE NATIVE SHADOW FEATURE, UNCOMMENT THE FOLLOWING LINE.
//CPSetPlatformFeature(CPNativeShadowFeature, NO);

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPWindow    modalWindow;
    @outlet CPPanel     floatingPanel;
    @outlet CPWindow    sheet;
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
    [theWindow setFullPlatformWindow:NO];
}

- (IBAction)displaySheet:(id)sender
{
    [CPApp beginSheet:sheet modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:) contextInfo:nil];
}

- (IBAction)runModalWindow:(id)sender
{
    [CPApp runModalForWindow:modalWindow];
}

- (IBAction)endSheet:(id)sender
{
    [CPApp endSheet:sheet returnCode:1];
}

- (IBAction)stopModal:(id)sender
{
    [CPApp stopModal];
    [modalWindow orderOut:nil];
}

- (IBAction)hasShadow:(id)sender
{
    [[sender window] setHasShadow:[sender state]];
}

- (IBAction)setFloating:(id)sender
{
    [[sender window] setFloatingPanel:[sender state]];
}

- (void)sheetDidEnd:(CPWindow)aSheet
{
    [aSheet close];
}

@end
