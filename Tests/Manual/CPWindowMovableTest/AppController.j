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
    CPCheckBox backgroundMovableCB;
    CPCheckBox movableCB;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];


    backgroundMovableCB = [CPCheckBox checkBoxWithTitle:@"Movable by background"];

    [backgroundMovableCB setFrameOrigin:CGPointMake(10, 10)];
    [backgroundMovableCB setTarget:self];
    [backgroundMovableCB setAction:@selector(setMovableByBackground:)]
    [contentView addSubview:backgroundMovableCB];

    movableCB = [CPCheckBox checkBoxWithTitle:@"Movable"];

    [movableCB setFrameOrigin:CGPointMake(200, 10)];
    [movableCB setTarget:self];
    [movableCB setAction:@selector(setMovable:)]
    [contentView addSubview:movableCB];

    [theWindow orderFront:self];

    aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 200, 200) styleMask:CPTitledWindowMask];
    [aWindow setTitle:@"Move me!"];
    [aWindow center];
    [aWindow makeKeyAndOrderFront:self];

    [backgroundMovableCB setState:[aWindow isMovableByWindowBackground]];
    [movableCB setState:[aWindow isMovable]];
    [backgroundMovableCB setEnabled:[aWindow isMovable]];
}

- (IBAction)setMovableByBackground:(id)aSender
{
    [aWindow setMovableByWindowBackground:[aSender state] === CPOnState];
}

- (IBAction)setMovable:(id)aSender
{
    [aWindow setMovable:[aSender state] === CPOnState];
    [backgroundMovableCB setEnabled:[aWindow isMovable]];
}


@end
