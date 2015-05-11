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
    @outlet CPWindow    externalWindow;

    CPPlatformWindow    platformWindow;

}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [[CPPlatformWindow alloc] initWithWindow:externalWindow];
    [externalWindow setDelegate:self];
    [theWindow setDelegate:self];
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
    [externalWindow orderFront:sender];
}

- (IBAction)closeWindow:(id)sender
{
    [externalWindow close];
}

- (IBAction)changeFrame:(id)sender
{
    [externalWindow setFrame:CGRectMake(250, 250, 200, 200)];
}

- (IBAction)showAlert:(id)sender
{
    var alert = [CPAlert alertWithMessageText:@"rer" defaultButton:"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:"Multiple login failures may result in blocked access to the system."];
    [alert beginSheetModalForWindow:externalWindow];
}


#pragma mark -
#pragma mark Delegate

- (void)windowDidBecomeKey:(CPNotification)aNotification
{
    CPLog.debug("windowDidBecomeKey:");
}

- (void)windowDidBecomeMain:(CPNotification)aNotification
{
    CPLog.debug("windowDidBecomeMain:");
}

- (void)windowDidEndSheet:(CPNotification)aNotification
{
    CPLog.debug("windowDidEndSheet:");
}

- (void)windowDidMove:(CPNotification)aNotification
{
    CPLog.debug("windowDidMove:");
}

- (void)windowDidResignKey:(CPNotification)aNotification
{
    CPLog.debug("windowDidResignKey:");
}

- (void)windowDidResignMain:(CPNotification)aNotification
{
    CPLog.debug("windowDidResignMain:");
}

- (void)windowDidResize:(CPNotification)aNotification
{
    CPLog.debug("windowDidResize:");
}

- (CPSize)windowWillResize:(CPWindow)sender toSize:(CPSize)aSize
{
    CPLog.debug("windowWillResize:toSize");
    return aSize;
}

- (void)windowWillClose:(CPWindow)aWindow
{
    CPLog.debug("windowWillClose:");
}

- (void)applicationDidResignActive:(CPNotification)aNotification
{
    CPLog.debug(@"applicationDidResignActive");
}

- (void)applicationDidBecomeActive:(CPNotification)aNotification
{
    CPLog.debug(@"applicationDidBecomeActive");
}

- (void)applicationWillResignActive:(CPNotification)aNotification
{
    CPLog.debug(@"applicationWillResignActive");
}

- (void)applicationWillBecomeActive:(CPNotification)aNotification
{
    CPLog.debug(@"applicationWillBecomeActive");
}


@end
