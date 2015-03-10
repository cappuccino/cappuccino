/*
 * AppController.j
 * CPPlatformWindow
 *
 * Created by You on October 30, 2014.
 * Copyright 2014, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPWindow    windowPlatformWindow;

    CPPlatformWindow    platformWindow;

}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [[CPPlatformWindow alloc] initWithWindow:windowPlatformWindow];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)showWindow:(id)sender
{
    [windowPlatformWindow orderFront:sender];
}

- (IBAction)closeWindow:(id)sender
{
    [windowPlatformWindow orderOut:sender];
}

- (IBAction)changeFrame:(id)sender
{
    [windowPlatformWindow setFrame:CGRectMake(250, 250, 200, 200)];
}

- (IBAction)showAlert:(id)sender
{
    var alert = [CPAlert alertWithMessageText:@"rer" defaultButton:"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:"Multiple login failures may result in blocked access to the system."];
    [alert beginSheetModalForWindow:windowPlatformWindow];
}

@end
