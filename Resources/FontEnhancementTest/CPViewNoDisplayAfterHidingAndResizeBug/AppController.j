/*
 * AppController.j
 * CPViewNoDisplayAfterHidingAndResizeBug
 *
 * Created by You on February 24, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPView view;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100,100,700,400) styleMask:CPResizableWindowMask],
        contentView = [theWindow contentView];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10, 10, 200, 28)];
    [button setTitle:@"Hide"];
    [button setAlternateTitle:@"Unhide"];
    [button setButtonType:CPToggleButton];
    [button setTarget:self];
    [button setAction:@selector(hide:)];

    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(230, 10, 500, 50)];
    [textField setStringValue:@"Test: 1/ Hide the red view, 2/ resize the window (and the red view), 3/ unhide the view.\n Expected: the red view should be visible and resized."];

    view = [[CustomView alloc] initWithFrame:CGRectMake(100,100, 200,200)];
    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:button];
    [contentView addSubview:textField];
    [contentView addSubview:view];

    [theWindow orderFront:self];
}

- (void)hide:(id)sender
{
    var state = [sender state];
    [view setHidden:(state == CPOnState)];
}

@end

@implementation CustomView : CPView
{
}

- (void)drawRect:(CGRect)aRect
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    [[CPColor redColor] set];

    CGContextFillRect(ctx, [self bounds]);
}

@end