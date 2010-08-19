/*
 * AppController.j
 * CPAlertTest
 *
 * Created by Alexander Ljungberg on August 19, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPTextField label;
    CPArray     variations;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    variations = [
        [nil, CPWarningAlertStyle],
        [nil, CPInformationalAlertStyle],
        [nil, CPCriticalAlertStyle],
        [CPHUDBackgroundWindowMask, CPWarningAlertStyle],
        [CPHUDBackgroundWindowMask, CPInformationalAlertStyle],
        [CPHUDBackgroundWindowMask, CPCriticalAlertStyle],
    ];

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 400, 24)];

    [label setStringValue:"Respond to the alert dialog with the mouse or the keyboard."];
    [contentView addSubview:label];

    [theWindow orderFront:self];

    [self showNextAlertVariation];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(id)returnCode
{
    if (returnCode === 0)
        [label setStringValue:"You chose 'Theorise'."];
    else
        [label setStringValue:"You cancelled the dialog."];

    [self showNextAlertVariation];
}

- (void)showNextAlertVariation
{
    if (![variations count])
        return;

    var variation = [variations objectAtIndex:0],
        alert = [[CPAlert alloc] init];

    [variations removeObjectAtIndex:0];

    [alert setDelegate:self];
    [alert addButtonWithTitle:@"Theorise"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Do you want to theorise before you have data?"];
    [alert setInformativeText:@"Invariably, you end up twisting facts to suit theories, instead of theories to suit facts."];
    [alert setWindowStyle:variation[0]];
    [alert setAlertStyle:variation[1]];

    [alert runModal];
}

@end
