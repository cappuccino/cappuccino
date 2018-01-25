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
    BOOL        useBlocks;
}

- (void)_init
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
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [self _init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500) styleMask:CPTitledWindowMask];
    [theWindow setTitle:@"CPAlert Test"];

    var contentView = [theWindow contentView];

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 400, 24)];

    [label setStringValue:"1. Click button: respond to the alert dialog with the mouse or the keyboard."];
    [contentView addSubview:label];

    var button = [CPButton buttonWithTitle:@"Run using delegate method"];
    [button setTarget:self];
    [button setAction:@selector(testWithDelegate:)];
    [button sizeToFit];
    var frame = [button frame];
    frame.origin = CPPointMake(35, CGRectGetMaxY([label frame]) + 20);
    [button setFrame:frame];
    [contentView addSubview:button];

    var button1 = [CPButton buttonWithTitle:@"Run using didEnd blocks"];
    [button1 setTarget:self];
    [button1 setAction:@selector(testWithBlocks:)];
    [button1 sizeToFit];
    var frame1 = [button1 frame];
    frame1.origin = CPPointMake(CGRectGetMaxX(frame) + 20, frame.origin.y);
    [button1 setFrame:frame1];
    [contentView addSubview:button1];

    var label2 = [[CPTextField alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(frame1) + 40, 400, 30)];
    [label2 setStringValue:"2. Click button to start 10 second delay. Put the browser to the background to test. Sheet should attach to window while browser is in the background."];
    [label2 setLineBreakMode:CPLineBreakByWordWrapping];
    [contentView addSubview:label2];

    var button2 = [CPButton buttonWithTitle:@"Start Timer"];
    [button2 setTarget:self];
    [button2 setAction:@selector(startAlertTimer:)];
    [button2 setCenter:[contentView center]];
    frame = [button2 frame];
    frame.origin.y = CGRectGetMaxY([label2 frame]) + 20;
    [button2 setFrame:frame];
    [contentView addSubview:button2];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (@action)testWithDelegate:(id)sender
{
    useBlocks = NO;
    [self _init];
    [self showNextAlertVariation];
}

- (@action)testWithBlocks:(id)sender
{
    useBlocks = YES;
    [self _init];
    [self showNextAlertVariation];
}

- (@action)startAlertTimer:(id)sender
{
    [sender setEnabled:NO];
    [self performSelector:@selector(showAlert:) withObject:sender afterDelay:10.0];
}

- (void)showAlert:(id)sender
{
    var alert = [CPAlert alertWithMessageText:"This sheet should attach to the main window when the browser is in background..." defaultButton:"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
    [alert beginSheetModalForWindow:[CPApp mainWindow] didEndBlock:function(alert, returnCode) {[sender setEnabled:YES];}]
}

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(CPInteger)returnCode
{
    CPLog.info("%s alert = %s, code = %d", _cmd, [anAlert description], returnCode);

    if (returnCode === 0)
        [label setStringValue:"You chose the default action."];
    else
        [label setStringValue:"You cancelled the dialog."];

    [self showNextAlertVariation];
}

- (void)customDidEnd:(CPAlert)anAlert code:(id)code context:(id)context
{
    CPLog.info("%s alert = %s, code = %d, context = %s", _cmd, [anAlert description], code, context);
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
    [alert setMessageText:message[0] || @""];
    [alert setInformativeText:message[1] || @""];

    if (message.length > 2)
        [alert addButtonWithTitle:message[2]];

    if (message.length > 3)
        [alert addButtonWithTitle:message[3]];

    [alert setTheme:(windowStyle === CPHUDBackgroundWindowMask) ? [CPTheme defaultHudTheme] : [CPTheme defaultTheme]];
    [alert setAlertStyle:variation[1]];

    if (windowStyle & CPDocModalWindowMask)
    {
        if (useBlocks)
            [alert beginSheetModalForWindow:theWindow didEndBlock:function(alert, returnCode)
                {
                    CPLog.info("didEndBlock: alert = %s, code = %d", [alert description], returnCode);

                    [self showNextAlertVariation];
                }];
        else
            [alert beginSheetModalForWindow:theWindow modalDelegate:self didEndSelector:@selector(customDidEnd:code:context:) contextInfo:@"here is some context"];
    }
    else if (useBlocks)
        [alert runModalWithDidEndBlock:function(alert, returnCode)
            {
                CPLog.info("didEndBlock: alert = %s, code = %d", [alert description], returnCode);

                [self showNextAlertVariation];
            }];
    else
        [alert runModal];
}

@end
