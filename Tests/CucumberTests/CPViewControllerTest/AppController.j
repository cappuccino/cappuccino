/*
 * AppController.j
 * CPViewControllerTest
 *
 * Created by You on May 9, 2016.
 * Copyright 2016, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow         theWindow;
    @outlet CPViewController viewController;
            BOOL             isViewLoaded;
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

    isViewLoaded = NO;
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)load:(id)sender
{
    [viewController loadViewWithCompletionHandler:function(view, error)
    {
        [view setBackgroundColor:[CPColor redColor]];
        [view setFrameOrigin:CGPointMake(100,100)];
        [[theWindow contentView] addSubview:view];
    }];
}

@end
