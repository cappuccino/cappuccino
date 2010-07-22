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

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"Press Cmd-X on the keyboard for each button and verify that it reacts."];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
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

    for (var i=0; i<keysToTest.length; i++)
    {
        var button = [[TestButton alloc] initWithFrame:CGRectMake(10 + i * 50, 100, 40, 24)];
        [button setTitle:keysToTest[i]];
        [button setKeyEquivalent:keysToTest[i]];
        [button setKeyEquivalentModifierMask:CPCommandKeyMask];

        [contentView addSubview:button];
    }

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

@end

@implementation TestButton :CPButton
{

}

- (void)performKeyEquivalent:(CPEvent)anEvent
{
    console.log("anEvent: "+[anEvent charactersIgnoringModifiers]);
    console.log(anEvent);
    [super performKeyEquivalent:anEvent];
}

@end