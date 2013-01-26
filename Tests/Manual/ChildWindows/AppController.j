/*
 * AppController.j
 * ChildWindows
 *
 * Created by You on January 17, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow parent;
    @outlet CPWindow child;
    @outlet CPWindow grandchild;
    @outlet CPWindow other;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [parent addChildWindow:child ordered:CPWindowAbove];
    [child addChildWindow:grandchild ordered:CPWindowBelow];

    [other orderFront:self];
    [parent orderFront:self];
}

- (@action)move:(id)sender
{
    var origin = [[sender window] frame].origin,
        newOrigin = CGPointMake(origin.x + 20, origin.y + 20);

    [[sender window] setFrameOrigin:newOrigin];
}

@end
