/*
 * AppController.j
 * resize
 *
 * Created by You on December 24, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
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
    var w = [note object];
    w._previousStyle = [w title];
    [w setTitle:@"In Live Resize …"];
}

- (void)viewDidEndLiveResize:(CPNotification)note
{
    var w = [note object];
    [w setTitle:w._previousStyle];
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (@action)resizeStyleDidChange:(id)sender
{
    [CPWindow setGlobalResizeStyle:[[sender selectedRadio] tag]];
}

@end
