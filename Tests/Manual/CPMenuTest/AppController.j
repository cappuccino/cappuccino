/*
 * AppController.j
 * CPMenuTest
 *
 * Created by Alexander Ljungberg on August 31, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>

@import "MyView.j"

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [[MyView alloc] initWithFrame:CGRectMakeZero()];

    [contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [theWindow setContentView:contentView];

    var popupButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    [popupButton addItemWithTitle:@"Item 1"];
    [popupButton addItemWithTitle:@"Item 2"];
    [popupButton addItemWithTitle:@"Item 3"];
    [popupButton sizeToFit];

    [popupButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popupButton setCenter:[contentView center]];

    [contentView addSubview:popupButton];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    [CPMenu setMenuBarVisible:YES];
}

@end
