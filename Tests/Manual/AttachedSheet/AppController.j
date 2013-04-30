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
    CPWindow    secondSheet;
    CPTextField textField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    wind = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 300) styleMask:CPTitledWindowMask | CPResizableWindowMask];
    [wind setMinSize:CGSizeMake(300, 200)];
    [wind setTitle:@"Untitled"];

    sheet = [[CPWindow alloc] initWithContentRect:CGRectMake(50, 50, 300, 100) styleMask:CPTitledWindowMask | CPResizableWindowMask];
    [sheet setMinSize:CGSizeMake(300, 100)];
    [sheet setMaxSize:CGSizeMake(600, 300)];

    secondSheet = [[CPWindow alloc] initWithContentRect:CGRectMake(50, 50, 300, 50) styleMask:CPTitledWindowMask | CPResizableWindowMask];
    [secondSheet setMinSize:CGSizeMake(300, 100)];
    [secondSheet setMaxSize:CGSizeMake(600, 300)];

    toolbar = [CPToolbar new];
    [toolbar setDisplayMode:CPToolbarDisplayModeIconAndLabel]
    [toolbar setDelegate:self];
    [secondSheet setToolbar:toolbar];

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

    var secondSheetContent = [secondSheet contentView];

    var okButton2 = [[CPButton alloc] initWithFrame:CGRectMake(180, 25, 50, buttonHeight)];
    [okButton2 setTitle:"OK"];
    [okButton2 setTarget:self];
    [okButton2 setTag:1];
    [okButton2 setAction:@selector(closeSecondSheet:)];
    [okButton2 setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

    var cancelButton2 = [[CPButton alloc] initWithFrame:CGRectMake(70, 25, 100, buttonHeight)];
    [cancelButton2 setTitle:"Cancel"];
    [cancelButton2 setTarget:self];
    [cancelButton2 setTag:0];
    [cancelButton2 setAction:@selector(closeSecondSheet:)];
    [cancelButton2 setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

    [secondSheetContent addSubview:okButton2];
    [secondSheetContent addSubview:cancelButton2];

    var displayButton = [[CPButton alloc] initWithFrame:CGRectMake(200, 150, 100, buttonHeight)];
    [displayButton setTitle:"Display Sheet"];
    [displayButton setTarget:self];
    [displayButton setAction:@selector(displaySheet:)];
    [[wind contentView] addSubview:displayButton];

    var displayButton = [[CPButton alloc] initWithFrame:CGRectMake(160, 180, 180, buttonHeight)];
    [displayButton setTitle:"Display Sheet with toolbar"];
    [displayButton setTarget:self];
    [displayButton setAction:@selector(displaySheetWithToolBar:)];
    [[wind contentView] addSubview:displayButton];

    [wind orderFront:self]
}

- (void)displaySheetWithToolBar:(id)sender
{
    [CPApp beginSheet:secondSheet modalForWindow:wind modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)displaySheet:(id)sender
{
    [textField setStringValue:""];
    [sheet makeFirstResponder:textField];
    [sheet setToolbar:nil];

    [CPApp beginSheet:sheet modalForWindow:wind modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)closeSheet:(id)sender
{
    [CPApp endSheet:sheet returnCode:[sender tag]];
}

- (void)closeSecondSheet:(id)sender
{
    [CPApp endSheet:secondSheet returnCode:0];
}

- (void)didEndSheet:(CPWindow)aSheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
    var str = [textField stringValue];

    [aSheet orderOut:self];

    if (returnCode == CPOKButton && [str length] > 0)
        [wind setTitle:str];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return ["item1", "item2"];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return ["item1", "item2"];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if (itemIdentifier == "item1")
    {
        [toolbarItem setLabel:@"Color"];
        [toolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"CPImageNameColorPanel.png"] size:CGSizeMake(26, 29)]];
        return toolbarItem;
    }
    else if (itemIdentifier == "item2")
    {
        [toolbarItem setLabel:@"Small New"];
        [toolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"New.png"] size:CGSizeMake(16, 16)]];
        return toolbarItem;
    }
}

@end
