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
    CPWindow    aWindow;
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

    aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(150, 300, 400, 150) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPDocModalWindowMask];
    [aWindow setTitle:@"Text Field in a Window"]

    contentView = [aWindow contentView];

    textField = [CPTextField textFieldWithStringValue:"Select me!" placeholder:"" width:0];
    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 360, 30)];
    [label setLineBreakMode:CPLineBreakByWordWrapping];

    [label setStringValue:"Select the field and double click it to select text. The text should become selected. Then hit enter to continue."];
    [contentView addSubview:label];

    [textField setFrame:CGRectMake(15, CGRectGetMaxY([label frame]) + 10, 300, 30)];

    [textField setEditable:YES];

    [textField setTarget:self];
    [textField setAction:@selector(modalAction:)];

    [contentView addSubview:textField];

    [CPApp beginSheet:aWindow modalForWindow:theWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)modalAction:(id)sender
{
    [CPApp endSheet:aWindow returnCode:0];
}

- (void)textAction:(id)sender
{
    [sender setEditable:NO];
}

@end
