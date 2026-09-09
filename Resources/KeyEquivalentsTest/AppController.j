/*
 * AppController.j
 * cappuccino-keyequivalents
 *
 * Created by Alexander Ljungberg on July 20, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    function plainFormatter(aString, aLevel, aTitle)
    {
        return aString;
    }

    CPLogRegisterRange(CPLogDefault, "debug", "debug", plainFormatter);
    CPLogRegisterRange(CPLogDefault, "warn", "warn", plainFormatter);

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [label setStringValue:@"Press Cmd-X on Mac, or Ctrl-X on Windows, on the keyboard for each button and verify that it reacts."];
    [label setFont:[CPFont boldSystemFontOfSize:14.0]];
    [label sizeToFit];
    [label setFrameOrigin:CGPointMake(10, 10)];

    [contentView addSubview:label];

    var keysToTest = [
            "a",
            ";",
            "-",
            "=",
            ",",
            ".",
            "/",
            "`",
            "'",
            "[",
            "\\",
            "]"
        ];

    for (var i = 0; i < keysToTest.length; i++)
    {
        var button = [[TestButton alloc] initWithFrame:CGRectMake(10 + i * 50, 50, 40, 24)];
        [button setTitle:keysToTest[i]];
        [button setKeyEquivalent:keysToTest[i]];
        [button setKeyEquivalentModifierMask:CPCommandKeyMask];     // Cmd on Mac === Ctrl on other O/Ss

        [button setAction:@selector(reportButtonAction:)];

        [contentView addSubview:button];
    }

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [label setStringValue:@"Press the appropriate key on the keyboard for each button and verify that it reacts."];
    [label setFont:[CPFont boldSystemFontOfSize:14.0]];
    [label sizeToFit];
    [label setFrameOrigin:CGPointMake(10, 110)];

    [contentView addSubview:label];

    var functionKeysToTest = [
            ["backspace", CPBackspaceCharacter],
            ["delete char", CPDeleteCharacter],
            ["delete key", CPDeleteFunctionKey],
            ["tab", CPTabCharacter],
            ["carriage return", CPCarriageReturnCharacter],
            ["newline", CPNewlineCharacter],
            ["space", CPSpaceFunctionKey],
            ["esc", CPEscapeFunctionKey],
            ["pgup", CPPageUpFunctionKey],
            ["pgdn", CPPageDownFunctionKey],
            ["left arrow", CPLeftArrowFunctionKey],
            ["up arrow", CPUpArrowFunctionKey],
            ["right arrow", CPRightArrowFunctionKey],
            ["down arrow", CPDownArrowFunctionKey],
            ["home", CPHomeFunctionKey],
            ["end", CPEndFunctionKey]
        ];

    for (var i = 0, buttonsWide = 6, yOffset = 0; i < functionKeysToTest.length; i++)
    {
        if (i % buttonsWide  === 0)
            yOffset += 30;

        var button = [[TestButton alloc] initWithFrame:CGRectMake(10 + (i % buttonsWide) * 110,
                                                                            120 + yOffset, 100, 24)];
        [button setTitle:functionKeysToTest[i][0]];
        [button setKeyEquivalent:functionKeysToTest[i][1]];
        [button setAction:@selector(reportButtonAction:)];

        [contentView addSubview:button];
    }

    var label2 = [[CPTextField alloc] initWithFrame:CGRectMake(10, 140 + yOffset + 24, 100, 24)];
    [label2 setStringValue:@"If a text field is the first responder, some key equivalents are ignored."];
    [label2 sizeToFit];
    [contentView addSubview:label2];

    var textField = [CPTextField textFieldWithStringValue:"" placeholder:"" width:100];
    [textField setFrameOrigin:CGPointMake(10, CGRectGetMaxY([label2 frame]) + 10)];
    [contentView addSubview:textField];

    [theWindow orderFront:self];
}

- (void)reportButtonAction:(id)sender
{
    CPLog.warn(" * Action selector called by button: " + [sender title] + " *");
}

@end

@implementation TestButton : CPButton
{
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    var eventKey = [anEvent charactersIgnoringModifiers],
        keyMessage = (eventKey.charCodeAt(0) > 32 && eventKey.charCodeAt(0) < 127 ? "Key: " + eventKey + ", " : "");

    CPLog.debug("TestButton \"" + [self title] + "\", " + keyMessage + "anEvent: " + anEvent);

    return [super performKeyEquivalent:anEvent];
}

@end
