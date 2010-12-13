/*
 * AppController.j
 * CPPopUpButtonTest
 *
 * Created by You on December 8, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()],
        popUpButton2 = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    for (var i = 0; i < 5; i++)
    {
        var menuItem1 = [[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"%i", i] action:nil keyEquivalent:nil];
        [menuItem1 setTag:i];
        [popUpButton addItem:menuItem1];

        var menuItem2 = [[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"%i", i] action:nil keyEquivalent:nil];
        [menuItem2 setTag:i];
        [popUpButton2 addItem:menuItem2];
    }

    [popUpButton sizeToFit];
    [popUpButton2 sizeToFit];

    [popUpButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popUpButton setCenter:CGPointMake([contentView center].x - 25.0, [contentView center].y)];
    [contentView addSubview:popUpButton];

    [popUpButton2 setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popUpButton2 setCenter:CGPointMake([contentView center].x + 25.0, [contentView center].y)];
    [contentView addSubview:popUpButton2];

    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 29.0)];
        frameOrigin = [popUpButton frameOrigin];

    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setCenter:CGPointMake([contentView center].x, [contentView center].y + 40.0)];
    [textField setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
    [textField bind:@"value" toObject:popUpButton withKeyPath:@"selectedTag" options:0];
    [contentView addSubview:textField];

    [popUpButton bind:@"selectedTag" toObject:textField withKeyPath:@"value" options:0]
    [popUpButton2 bind:@"selectedTag" toObject:popUpButton withKeyPath:@"selectedTag" options:0];

    // Change the selected tag of the second popup doesn't reverse set it,
    // see the discussion for pull request 1018 for more details about the problem.
    // https://github.com/280north/cappuccino/pull/1018
    [popUpButton2 _setSelectedTag:2];

    [theWindow orderFront:self];
}

@end
