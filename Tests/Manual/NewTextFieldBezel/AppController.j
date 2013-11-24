/*
 * AppController.j
 * NewTextField
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2011, Intalio, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow        theWindow;
    CPMutableArray  fields;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    fields = [CPMutableArray array];

    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"Text field" width:200];
    [fields addObject:field];
    [self configureField:field at:50];

    field = [CPTextField roundedTextFieldWithStringValue:@"" placeholder:@"Text field" width:200];
    [fields addObject:field];
    [self configureField:field at:100];

    field = [CPTextField textFieldWithStringValue:@"" placeholder:@"Big text field" width:200];
    [field setFont:[CPFont systemFontOfSize:16]];
    [fields addObject:field];
    [self configureField:field at:150];

    field = [[CPSearchField alloc] initWithFrame:CPMakeRect(0, 0, 200, 30)];
    [fields addObject:field];
    [self configureField:field at:200];

    field = [[CPTokenField alloc] initWithFrame:CPMakeRect(0, 0, 200, 30)];
    [field setEditable:YES];
    [field setPlaceholderString:"Type in a token!"];
    [field setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString:@" "]];
    [fields addObject:field];
    [self configureField:field at:250];

    [self makeTableAt:300];
    [theWindow orderFront:self];
}

- (void)configureField:(CPTextField)aField at:(int)yCoord
{
    var contentView = [theWindow contentView];

    [aField setFrameOrigin:CGPointMake(50, yCoord)];
    [aField sizeToFit];
    [contentView addSubview:aField];

    var enabler = [CPCheckBox checkBoxWithTitle:@"Enabled"];

    [enabler setFrameOrigin:CGPointMake(50 + 200 + 10, yCoord + 7)];
    [enabler setTarget:self];
    [enabler setAction:@selector(enableField:)];
    [enabler setState:CPOnState];
    [enabler setTag:[fields count] - 1];
    [contentView addSubview:enabler];
}

- (void)makeTableAt:(int)yCoord
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(50, yCoord, 200, 200)],
        table = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)],
        column = [[CPTableColumn alloc] initWithIdentifier:@"1"];

    [scrollView setBorderType:CPBezelBorder];
    [table setDataSource:self];
    [table setVerticalMotionCanBeginDrag:NO];
    [column setResizingMask:CPTableColumnAutoresizingMask];
    [column setEditable:YES];
    [table setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [table addTableColumn:column];
    [[theWindow contentView] addSubview:scrollView];
    [scrollView setDocumentView:table];
}

- (void)enableField:(id)sender
{
    var field = [fields objectAtIndex:[sender tag]];
    [field setEnabled:[sender state] === CPOnState];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 7;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)column row:(CPInteger)row
{
    return "Double-click to edit";
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)rowIndex
{

}

@end
