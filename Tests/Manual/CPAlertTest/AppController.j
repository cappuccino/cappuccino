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
    CPWindow    theWindow;
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
         "Torch"],
        [@"Sometimes a message can be really long and just appear to go on and on. It could be a speech. It could be the television.",
         nil]
    ];
    messageIndex = 0;

    variations = [
        [nil, CPWarningAlertStyle],
        [nil, CPInformationalAlertStyle],
        [nil, CPCriticalAlertStyle],
        [CPHUDBackgroundWindowMask, CPWarningAlertStyle],
        [CPHUDBackgroundWindowMask, CPInformationalAlertStyle],
        [CPHUDBackgroundWindowMask, CPCriticalAlertStyle],
        [CPDocModalWindowMask, CPWarningAlertStyle],
        [CPDocModalWindowMask, CPInformationalAlertStyle],
        [CPDocModalWindowMask, CPCriticalAlertStyle]
    ];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500) styleMask:CPTitledWindowMask];
    [theWindow setTitle:@"CPAlert Test"];

    var contentView = [theWindow contentView];

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 400, 24)];

    [label setStringValue:"Respond to the alert dialog with the mouse or the keyboard."];
    [contentView addSubview:label];

    [theWindow orderFront:self];

    [self showNextAlertVariation];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(CPInteger)returnCode
{
    CPLogConsole(_cmd);
    if (returnCode === 0)
        [label setStringValue:"You chose the default action."];
    else
        [label setStringValue:"You cancelled the dialog."];

    [self showNextAlertVariation];
}

- (void)customDidEnd:(CPAlert)anAlert code:(id)code context:(id)context
{
    CPLogConsole(_cmd + anAlert + code + context);
}

- (void)showNextAlertVariation
{
    if (![variations count])
        return;

    var variation = variations[0],
        message = messages[messageIndex],
        alert = [CPAlert new];

    messageIndex = (messageIndex + 1) % messages.length;
    [variations removeObjectAtIndex:0];

    var windowStyle = variation[0];
    [alert setDelegate:self];
    [alert setMessageText:message[0]];
    [alert setInformativeText:message[1]];
    if (message.length > 2)
        [alert addButtonWithTitle:message[2]];
    if (message.length > 3)
        [alert addButtonWithTitle:message[3]];
    [alert setTheme:(windowStyle === CPHUDBackgroundWindowMask) ? [CPTheme defaultHudTheme] : [CPTheme defaultTheme]];
    [alert setAlertStyle:variation[1]];

    if (windowStyle & CPDocModalWindowMask)
        [alert beginSheetModalForWindow:theWindow modalDelegate:self didEndSelector:@selector(customDidEnd:code:context:) contextInfo:@"here is some context"];
    else
        [alert runModal];
}

@end
