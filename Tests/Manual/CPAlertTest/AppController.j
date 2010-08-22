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
    CPArray     messages;
    int         messageIndex;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    messages = [
        [@"Are you sure you want to theorise before you have data?",
         @"Invariably, you end up twisting facts to suit theories, instead of theories to suit facts.",
         "Theorise", "Cancel"],
        [@"Snakes. Why did it have to be snakes?",
         nil,
         "Torch", "Cancel"],
         [@"Sometimes a message can be really long and just appear to go on and on. It could be a speech. It could be the television.",
          nil,
          "Off", "Cancel"]
    ];
    messageIndex = 0;

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
        [label setStringValue:"You chose the default action."];
    else
        [label setStringValue:"You cancelled the dialog."];

    [self showNextAlertVariation];
}

- (void)showNextAlertVariation
{
    if (![variations count])
        return;

    var variation = variations[0],
        message = messages[messageIndex],
        alert = [[CPAlert alloc] init];

    messageIndex = (messageIndex + 1) % messages.length;
    [variations removeObjectAtIndex:0];

    [alert setDelegate:self];
    [alert setMessageText:message[0]];
    [alert setInformativeText:message[1]];
    [alert addButtonWithTitle:message[2]];
    [alert addButtonWithTitle:message[3]];
    [alert setWindowStyle:variation[0]];
    [alert setAlertStyle:variation[1]];

    [alert runModal];
}

@end
