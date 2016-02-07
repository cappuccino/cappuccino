/*
 * AppController.j
 * CPViewController
 *
 * Created by You on November 11, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation Button : CPButton
{
}

- (void)mouseDown:(CPEvent)anEvent
{
    [[CPApp delegate] load];
    [super mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [[CPApp delegate] removeSubviews];
    [super mouseUp:anEvent];
}

@end

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPView holderView;

    BOOL async @accessors;
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

- (void)load
{
    if (async)
        [self loadAsync];
    else
        [self loadSync];
}

- (void)loadAsync
{
    var vc = [[CPViewController alloc] initWithCibName:@"ViewController" bundle:nil];
    var vc2 = [[CPViewController alloc] initWithCibName:@"ViewController2" bundle:nil];

    [vc loadViewWithCompletionHandler:function(view1, error)
    {
        [view1 setBackgroundColor:[CPColor redColor]];
        [holderView addSubview:view1];

        [vc2 loadViewWithCompletionHandler:function(view2, error)
        {
            [view2 setBackgroundColor:[CPColor greenColor]];
            [view1 addSubview:view2];
        }];
    }];
}

- (void)loadSync
{
    var vc = [[CPViewController alloc] initWithCibName:@"ViewController" bundle:nil];
    var vc2 = [[CPViewController alloc] initWithCibName:@"ViewController2" bundle:nil];

    var view1 = [vc view];
    [view1 setBackgroundColor:[CPColor redColor]];
    [holderView addSubview:view1];

    var view2 = [vc2 view];
    [view2 setBackgroundColor:[CPColor greenColor]];
    [view1 addSubview:view2];
}

- (@action)removeSubviews:(id)sender
{
    [[holderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
