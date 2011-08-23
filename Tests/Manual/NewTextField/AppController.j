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

@import "OldTextField.j"


@implementation AppController : CPObject
{
    CPWindow        theWindow;
    CPTextField     newField;
    OldTextField    oldField;
    CPCheckBox      newFieldEnabler;
    CPCheckBox      oldFieldEnabler;
    CPArray         themeValues;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

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

        placeholderColor = [CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0];

    themeValues =
        [
            [@"vertical-alignment", CPTopVerticalTextAlignment,         CPThemeStateBezeled],
            [@"bezel-color",        bezelColor,                         CPThemeStateBezeled],
            [@"bezel-color",        bezelFocusedColor,                  CPThemeStateBezeled | CPThemeStateEditing],
            [@"bezel-color",        bezelDisabledColor,                 CPThemeStateBezeled | CPThemeStateDisabled],
            [@"font",               [CPFont systemFontOfSize:12.0],     CPThemeStateBezeled],

            [@"content-inset",      CGInsetMake(8.0, 7.0, 5.0, 8.0),    CPThemeStateBezeled],
            [@"content-inset",      CGInsetMake(7.0, 7.0, 5.0, 8.0),    CPThemeStateBezeled | CPThemeStateEditing],
            [@"bezel-inset",        CGInsetMake(3.0, 4.0, 3.0, 4.0),    CPThemeStateBezeled],
            [@"bezel-inset",        CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled | CPThemeStateEditing],

            [@"text-color",         placeholderColor,                   OldTextFieldStatePlaceholder],

            [@"line-break-mode",    CPLineBreakByTruncatingTail,        CPThemeStateTableDataView],
            [@"vertical-alignment", CPCenterVerticalTextAlignment,      CPThemeStateTableDataView],
            [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),    CPThemeStateTableDataView],

            [@"text-color",         [CPColor colorWithCalibratedWhite:51.0 / 255.0 alpha:1.0], CPThemeStateTableDataView],
            [@"text-color",         [CPColor whiteColor],                CPThemeStateTableDataView | CPThemeStateSelectedTableDataView],
            [@"font",               [CPFont boldSystemFontOfSize:12.0],  CPThemeStateTableDataView | CPThemeStateSelectedTableDataView],
            [@"text-color",         [CPColor blackColor],                CPThemeStateTableDataView | CPThemeStateEditing],
            [@"content-inset",      CGInsetMake(7.0, 7.0, 5.0, 8.0),     CPThemeStateTableDataView | CPThemeStateEditing],
            [@"font",               [CPFont systemFontOfSize:12.0],      CPThemeStateTableDataView | CPThemeStateEditing],
            [@"bezel-inset",        CGInsetMake(-2.0, -2.0, -2.0, -2.0), CPThemeStateTableDataView | CPThemeStateEditing],

            [@"text-color",         [CPColor colorWithCalibratedWhite:125.0 / 255.0 alpha:1.0], CPThemeStateTableDataView | CPThemeStateGroupRow],
            [@"text-color",         [CPColor colorWithCalibratedWhite:1.0 alpha:1.0], CPThemeStateTableDataView | CPThemeStateGroupRow | CPThemeStateSelectedTableDataView],
            [@"text-shadow-color",  [CPColor whiteColor],                CPThemeStateTableDataView | CPThemeStateGroupRow],
            [@"text-shadow-offset",  CGSizeMake(0,1),                    CPThemeStateTableDataView | CPThemeStateGroupRow],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.6],                CPThemeStateTableDataView | CPThemeStateGroupRow | CPThemeStateSelectedTableDataView],
            [@"font",               [CPFont boldSystemFontOfSize:12.0],  CPThemeStateTableDataView | CPThemeStateGroupRow]
        ];

    [self makeFields:[CPTextField class] atPosition:50];
    [self makeFields:[OldTextField class] atPosition:350];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(50, 150, 200, 200)],
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

    [theWindow orderFront:self];
}

- (void)makeFields:(Class)fieldClass atPosition:(int)position
{
    var contentView = [theWindow contentView],
        label = [CPTextField labelWithTitle:fieldClass === CPTextField ? @"New" : @"Old"],
        field = [fieldClass textFieldWithStringValue:@"" placeholder:@"Text field" width:200];

    [label setFont:[CPFont boldSystemFontOfSize:12]];
    [label setFrameOrigin:CGPointMake(position, 20)];
    [contentView addSubview:label];

    if (fieldClass === [CPTextField class])
        newField = field;
    else
    {
        oldField = field;
        [field registerThemeValues:themeValues];
    }

    [field setFrameOrigin:CGPointMake(position, 50)];
    [field sizeToFit];
    [contentView addSubview:field];

    var fieldEnabler = [CPCheckBox checkBoxWithTitle:@"Enabled"];

    [fieldEnabler setFrameOrigin:CGPointMake(position + 210, 57)];
    [fieldEnabler setTarget:self];
    [fieldEnabler setAction:@selector(enableField:)];
    [fieldEnabler setState:CPOnState];
    [contentView addSubview:fieldEnabler];

    var bigField = [fieldClass textFieldWithStringValue:@"" placeholder:@"Big text field" width:200];

    if (fieldClass === [CPTextField class])
        newFieldEnabler = fieldEnabler;
    else
    {
        oldFieldEnabler = fieldEnabler;
        [bigField registerThemeValues:themeValues];
    }

    [bigField setFrameOrigin:CGPointMake(position, 100)];
    [bigField setFont:[CPFont systemFontOfSize:18]];
    [bigField sizeToFit];
    [contentView addSubview:bigField];

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
