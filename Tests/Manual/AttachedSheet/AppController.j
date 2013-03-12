/*
 * AppController.j
 * AttachedSheet
 *
 * Created by Cacaodev on August 1, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    CPWindow    wind;
    CPWindow    sheet;
    CPTextField textField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    wind = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 300) styleMask:CPTitledWindowMask | CPResizableWindowMask];
    [wind setMinSize:CGSizeMake(300, 200)];
    [wind setTitle:@"Untitled"];

    sheet = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 300, 100) styleMask:CPDocModalWindowMask | CPResizableWindowMask];
    [sheet setMinSize:CGSizeMake(300, 100)];
    [sheet setMaxSize:CGSizeMake(600, 300)];

    var sheetContent = [sheet contentView];

    textField = [[CPTextField alloc] initWithFrame:CGRectMake(10, 30, 280, 30)];
    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setAutoresizingMask:CPViewWidthSizable];

    var buttonHeight = [[CPTheme defaultTheme] valueForAttributeWithName:@"min-size" forClass:CPButton].height,
        okButton = [[CPButton alloc] initWithFrame:CGRectMake(230, 70, 50, buttonHeight)];
    [okButton setTitle:"OK"];
    [okButton setTarget:self];
    [okButton setTag:1];
    [okButton setAction:@selector(closeSheet:)];
    [okButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

    var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(120, 70, 100, buttonHeight)];
    [cancelButton setTitle:"Cancel"];
    [cancelButton setTarget:self];
    [cancelButton setTag:0];
    [cancelButton setAction:@selector(closeSheet:)];
    [cancelButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

    [sheetContent addSubview:textField];
    [sheetContent addSubview:okButton];
    [sheetContent addSubview:cancelButton];

    var displayButton = [[CPButton alloc] initWithFrame:CGRectMake(200, 150, 100, buttonHeight)];
    [displayButton setTitle:"Display Sheet"];
    [displayButton setTarget:self];
    [displayButton setAction:@selector(displaySheet:)];
    [[wind contentView] addSubview:displayButton];

    [wind orderFront:self]
}

- (void)displaySheet:(id)sender
{
    [textField setStringValue:""];
    [sheet makeFirstResponder:textField];

    [CPApp beginSheet:sheet modalForWindow:wind modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)closeSheet:(id)sender
{
    [CPApp endSheet:sheet returnCode:[sender tag]];
}

- (void)didEndSheet:(CPWindow)aSheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
    var str = [textField stringValue];

    [sheet orderOut:self];

    if (returnCode == CPOKButton && [str length] > 0)
        [wind setTitle:str];
}

@end
