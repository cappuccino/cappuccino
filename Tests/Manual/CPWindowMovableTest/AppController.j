/*
 * AppController.j
 * CPWindowMovableTest
 *
 * Created by You on October 28, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow aWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];


    var button = [CPButton buttonWithTitle:@"Set movable by background"];

    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [button setFrameOrigin:CPPointMake(10, 10)];
    [button setTarget:self];
    [button setAction:@selector(swicthMovableByBackground:)]
    [contentView addSubview:button];


    var button2 = [CPButton buttonWithTitle:@"Switch movable"];

    [button2 setFrameOrigin:CPPointMake(200, 10)];
    [button2 setTarget:self];
    [button2 setAction:@selector(swicthMovable:)]
    [contentView addSubview:button2];

    [theWindow orderFront:self];

    aWindow = [[CPWindow alloc] initWithContentRect:CPRectMake(0, 0, 200, 200) styleMask:CPTitledWindowMask];
    [aWindow setTitle:@"Move me!"];
    [aWindow center];
    [aWindow makeKeyAndOrderFront:self];
}


- (IBAction)swicthMovableByBackground:(id)aSender
{
    [aWindow setMovableByWindowBackground:![aWindow isMovableByWindowBackground]];
}

- (IBAction)swicthMovable:(id)aSender
{
    [aWindow setMovable:![aWindow isMovable]];
}


@end
