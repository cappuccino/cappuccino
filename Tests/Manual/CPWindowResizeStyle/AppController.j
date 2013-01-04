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
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
}

- (@action)resizeStyleDidChange:(id)sender
{
    [CPWindow setGlobalResizeStyle:[[sender selectedRadio] tag]];
}

@end
