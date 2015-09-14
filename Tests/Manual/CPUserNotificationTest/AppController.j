/*
 * AppController.j
 * CPUserNotificationTest
 *
 * Created by You on June 25, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

var icon = [[CPImage alloc] initWithContentsOfFile:@"Resources/Icon.png"];

@implementation AppController : CPObject
{
    CPUserNotification _scheduleUserNotification;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"User Notification Test!"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];

    var deliverButton = [CPButton buttonWithTitle:@"Deliver Notification"];
    [deliverButton setTarget:self];
    [deliverButton setAction:@selector(deliverUserNotification:)];
    [deliverButton setFrameOrigin:CGPointMake(10, 50)];
    [contentView addSubview:deliverButton]

    var scheduleButton = [CPButton buttonWithTitle:@"Schedule Notification"];
    [scheduleButton setTarget:self];
    [scheduleButton setAction:@selector(scheduleUserNotification:)];
    [scheduleButton setFrameOrigin:CGPointMake(10, 80)];
    [contentView addSubview:scheduleButton]

    var removeButton = [CPButton buttonWithTitle:@"Remove Scheduled Notifications"];
    [removeButton setTarget:self];
    [removeButton setAction:@selector(removeNotification:)];
    [removeButton setFrameOrigin:CGPointMake(10, 110)];
    [contentView addSubview:removeButton]

    [theWindow orderFront:self];

    [[CPUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

- (void)deliverUserNotification:(id)sender
{
    var note = [CPUserNotification new];
    [note setTitle:@"This is a delivered notification"];
    [note setInformativeText:@"Informative text for the delivered notification"];
    [note setContentImage:icon];

    [[CPUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
}

- (void)scheduleUserNotification:(id)sender
{
    if (_scheduleUserNotification)
        return;

    _scheduleUserNotification = [CPUserNotification new];
    [_scheduleUserNotification setTitle:@"This is a scheduled notification"];
    [_scheduleUserNotification setInformativeText:@"A notifications will pop up every 5 seconds"];
    [_scheduleUserNotification setDeliveryDate:[CPDate dateWithTimeIntervalSinceNow:1]];
    [_scheduleUserNotification setDeliveryRepeatInterval:5];
    [_scheduleUserNotification setContentImage:icon];

    [[CPUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:_scheduleUserNotification];
}

- (void)removeNotification:(id)sender
{
    [[CPUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:_scheduleUserNotification];
    _scheduleUserNotification = nil;
}

- (BOOL)userNotificationCenter:(id)n shouldPresentNotification:(id)aNotification
{
    return YES;
}

- (void)userNotificationCenter:(CPUserNotificationCenter)center didDeliverNotification:(CPUserNotification)notification
{
    CPLog.warn(@"didDeliverNotification");
}

- (void)userNotificationCenter:(CPUserNotificationCenter)center didActivateNotification:(CPUserNotification)notification
{
    CPLog.warn(@"didActivateNotification");
}

@end
