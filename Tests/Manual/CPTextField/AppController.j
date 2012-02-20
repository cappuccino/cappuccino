/*
 * AppController.j
 * CPTextField
 *
 * Created by Alexander Ljungberg on August 2, 2010.
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

    var textField = [CPTextField textFieldWithStringValue:"" placeholder:"Edit me!" width:200],
        label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 400, 24)];

    [label setStringValue:"Edit and hit enter: editing should end."];
    [contentView addSubview:label];

    [textField setFrameOrigin:CGPointMake(15, 35)];

    [textField setEditable:YES];
    [textField setPlaceholderString:"Edit me!"];

    [textField setTarget:self];
    [textField setAction:@selector(textAction:)];

    [contentView addSubview:textField];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)textAction:(id)sender
{
    [sender setEditable:NO];
}

@end
