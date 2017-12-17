/*
 * AppController.j
 * CPWindowLiveResizeTest
 *
 * Created by You on June 2, 2017.
 * Copyright 2017, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet MyWindow    theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(viewWillStartLiveResize:)
                   name:CPWindowWillStartLiveResizeNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(viewDidEndLiveResize:)
                   name:CPWindowDidEndLiveResizeNotification
                 object:nil];
}

- (void)viewWillStartLiveResize:(CPNotification)note
{
    [[theWindow contentView] setBackgroundColor:[CPColor redColor]];
}

- (void)viewDidEndLiveResize:(CPNotification)note
{
    [[theWindow contentView] setBackgroundColor:[CPColor clearColor]];
}

- (IBAction)animate:(id)sender
{
    var n = ROUND(RAND() * 500);
    [theWindow setFrame:CGRectMake(100, 100, 200 + n, 200 + n) display:YES animate:YES];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:NO];
}

@end

@implementation MyWindow : CPWindow
{
}

- (CPTimeInterval)animationResizeTime:(CGRect)aRect
{
    return 2;
}

@end
