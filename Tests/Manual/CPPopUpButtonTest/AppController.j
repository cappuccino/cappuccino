/*
 * AppController.j
 * CPPopUpButtonTest
 *
 * Created by Klaas Pieter Annema on December 8, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPPopUpButton popUpButton;
    CPPopUpButton popUpButton2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];
    popUpButton2 = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    for (var i = 0; i < 5; i++)
    {
        var menuItem1 = [[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"Left %i", i] action:nil keyEquivalent:nil];
        [menuItem1 setTag:i];
        [popUpButton addItem:menuItem1];

        var menuItem2 = [[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"Right %i", i] action:nil keyEquivalent:nil];
        [menuItem2 setTag:i];
        [popUpButton2 addItem:menuItem2];
    }

    [popUpButton sizeToFit];
    [popUpButton2 sizeToFit];

    var width = CGRectGetWidth([popUpButton frame]),
        width2 = CGRectGetWidth([popUpButton2 frame]);

    [popUpButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popUpButton setCenter:CGPointMake([contentView center].x - width / 2.0 - 10, [contentView center].y)];
    [contentView addSubview:popUpButton];

    [popUpButton2 setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popUpButton2 setCenter:CGPointMake([contentView center].x + width / 2.0 + 10, [contentView center].y)];
    [contentView addSubview:popUpButton2];

    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 29.0)],
        frameOrigin = [popUpButton frameOrigin];

    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setCenter:CGPointMake([contentView center].x, [contentView center].y + 40.0)];
    [textField setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
    [textField bind:CPValueBinding toObject:popUpButton withKeyPath:@"selectedItem.tag" options:nil];
    [contentView addSubview:textField];

    var button = [CPButton buttonWithTitle:@"Remove Items"],
        frame = [textField frame];

    [button setCenter:CGPointMake([contentView center].x, 0)];
    [button setFrameOrigin:CGPointMake(CGRectGetMinX([button frame]), CGRectGetMaxY(frame) + 15)];
    [button setTarget:self];
    [button setAction:@selector(removeItems:)];
    [contentView addSubview:button];

    [popUpButton bind:CPSelectedTagBinding toObject:textField withKeyPath:@"value" options:nil]
    [popUpButton2 bind:CPSelectedTagBinding toObject:popUpButton withKeyPath:@"selectedItem.tag" options:nil];

    // Change the selected tag of the second popup doesn't reverse set it,
    // see the discussion for pull request 1018 for more details about the problem.
    // https://github.com/280north/cappuccino/pull/1018
    [popUpButton2 selectItemWithTag:2];

    [theWindow orderFront:self];
}

- (@action)removeItems:(id)sender
{
    [popUpButton2 removeAllItems];
    [popUpButton removeAllItems];
    CPLog("objectValue = %d", [popUpButton objectValue]);
}

@end
