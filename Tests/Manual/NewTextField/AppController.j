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
    CPTextField newField;
    CPTextField oldField;
    CPCheckBox newFieldEnabler;
    CPCheckBox oldFieldEnabler;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    newField = [CPTextField textFieldWithStringValue:@"" placeholder:@"New text field" width:200];

    [newField setFrameOrigin:CGPointMake(50, 50)];
    [contentView addSubview:newField];

    newFieldEnabler = [CPCheckBox checkBoxWithTitle:@"Enabled"];

    [newFieldEnabler setFrameOrigin:CGPointMake(270, 54)];
    [newFieldEnabler setTarget:self];
    [newFieldEnabler setAction:@selector(enableField:)];
    [newFieldEnabler setState:CPOnState];
    [contentView addSubview:newFieldEnabler];

    var bezelColor = CPColorWithImages(
            [
                ["textfield-bezel-square-0.png", 3.0, 4.0],
                ["textfield-bezel-square-1.png", 1.0, 4.0],
                ["textfield-bezel-square-2.png", 3.0, 4.0],
                ["textfield-bezel-square-3.png", 3.0, 1.0],
                ["textfield-bezel-square-4.png", 1.0, 1.0],
                ["textfield-bezel-square-5.png", 3.0, 1.0],
                ["textfield-bezel-square-6.png", 3.0, 4.0],
                ["textfield-bezel-square-7.png", 1.0, 4.0],
                ["textfield-bezel-square-8.png", 3.0, 4.0]
            ]),

        bezelFocusedColor = CPColorWithImages(
            [
                ["textfield-bezel-square-focused-0.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-1.png", 1.0, 7.0],
                ["textfield-bezel-square-focused-2.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-3.png", 7.0, 1.0],
                ["textfield-bezel-square-focused-4.png", 1.0, 1.0],
                ["textfield-bezel-square-focused-5.png", 7.0, 1.0],
                ["textfield-bezel-square-focused-6.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-7.png", 1.0, 7.0],
                ["textfield-bezel-square-focused-8.png", 7.0, 7.0]
            ]),

        bezelDisabledColor = CPColorWithImages(
            [
                ["textfield-bezel-square-disabled-0.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-1.png", 1.0, 4.0],
                ["textfield-bezel-square-disabled-2.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-3.png", 3.0, 1.0],
                ["textfield-bezel-square-disabled-4.png", 1.0, 1.0],
                ["textfield-bezel-square-disabled-5.png", 3.0, 1.0],
                ["textfield-bezel-square-disabled-6.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-7.png", 1.0, 4.0],
                ["textfield-bezel-square-disabled-8.png", 3.0, 4.0]
            ]),

        themeValues =
        [
            [@"bezel-color",        bezelColor,                         CPThemeStateBezeled],
            [@"bezel-color",        bezelFocusedColor,                  CPThemeStateBezeled | CPThemeStateEditing],
            [@"bezel-color",        bezelDisabledColor,                 CPThemeStateBezeled | CPThemeStateDisabled],

            [@"content-inset",      CGInsetMake(7.0, 7.0, 6.0, 8.0),    CPThemeStateBezeled],
            [@"content-inset",      CGInsetMake(6.0, 7.0, 6.0, 8.0),    CPThemeStateBezeled | CPThemeStateEditing],
            [@"bezel-inset",        CGInsetMake(3.0, 4.0, 3.0, 4.0),    CPThemeStateBezeled],
            [@"bezel-inset",        CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled | CPThemeStateEditing]
        ];

    oldField = [CPTextField textFieldWithStringValue:@"" placeholder:@"Old text field" width:200];

    [oldField registerThemeValues:themeValues];
    [oldField setFrameOrigin:CGPointMake(50, 100)];
    [contentView addSubview:oldField];

    oldFieldEnabler = [CPCheckBox checkBoxWithTitle:@"Enabled"];

    [oldFieldEnabler setFrameOrigin:CGPointMake(270, 104)];
    [oldFieldEnabler setTarget:self];
    [oldFieldEnabler setAction:@selector(enableField:)];
    [oldFieldEnabler setState:CPOnState];
    [contentView addSubview:oldFieldEnabler];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(50, 150, 200, 200)],
        table = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)],
        column = [[CPTableColumn alloc] initWithIdentifier:@"1"];

    [scrollView setBorderType:CPBezelBorder];
    [table setDataSource:self];
    [table setVerticalMotionCanBeginDrag:NO];
    //[table setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [column setResizingMask:CPTableColumnAutoresizingMask];
    [column setEditable:YES];
    [table setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [table addTableColumn:column];
    [contentView addSubview:scrollView];
    [scrollView setDocumentView:table];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)enableField:(id)sender
{
    var field = sender === newFieldEnabler ? newField : oldField;
    [field setEnabled:[sender state] === CPOnState];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 7;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)column row:(int)row
{
    return "Row " + row;
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{

}

@end
