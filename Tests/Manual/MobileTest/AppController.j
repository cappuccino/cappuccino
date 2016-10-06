/*
 * AppController.j
 * MobileTest
 *
 * Created by You on August 18, 2016.
 * Copyright 2016, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import "Test1Controller.j"
@import "Test2Controller.j"


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPButton    nextButton;
    @outlet CPView      testView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (@action)next:(id)sender
{
    [self activateTest:[Test2Controller new]];
    [sender setEnabled:NO];
}

- (void)activateTest:aController
{
    var viewFrame = [testView frame],
        resizingMask = [testView autoresizingMask];

    [aController loadViewWithCompletionHandler:function(aView, error)
    {
        [aView setFrame:viewFrame];
        [aView setAutoresizingMask:resizingMask];
        [[theWindow contentView] replaceSubview:testView with:aView];
        testView = aView;
        [theWindow makeFirstResponder:[aView nextValidKeyView]];
    }];

}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

    [self activateTest:[Test1Controller new]];
}

@end
