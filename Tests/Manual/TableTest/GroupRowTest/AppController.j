/*
 * AppController.j
 * GroupRowTest
 *
 * Created by You on August 27, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPImage iconImage;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],

        tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    [tableView setAllowsMultipleSelection:YES];
    [tableView setAllowsColumnSelection:YES];
    [tableView setUsesAlternatingRowBackgroundColors:YES];

    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [tableView setDelegate:self];
    [tableView setDataSource:self];

    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 0, 0)];
    [iconView setImageScaling:CPImageScaleNone];
    var iconColumn = [[CPTableColumn alloc] initWithIdentifier:"icons"];
    [iconColumn setWidth:32.0];
    [iconColumn setMinWidth:32.0];
    [iconColumn setDataView:iconView];
    [tableView addTableColumn:iconColumn];

    iconImage = [[CPImage alloc] initWithContentsOfFile:"http://www.cappuccino-project.org/img/favicon.ico" size:CGSizeMake(16, 16)];


    for (var i = 1; i <= 5; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];

        [[column headerView] setStringValue:"Number " + i];

        [column setMaxWidth:500.0];
        [column setWidth:200.0];

        [tableView addTableColumn:column];
    }

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([contentView bounds]), CGRectGetHeight([contentView bounds]) / 2)];

    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:scrollView];

    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    [tableView setAllowsMultipleSelection:YES];
    [tableView setAllowsColumnSelection:YES];

    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [tableView setDelegate:self];
    [tableView setDataSource:self];

    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 0, 0)];
    [iconView setImageScaling:CPImageScaleNone];
    var iconColumn = [[CPTableColumn alloc] initWithIdentifier:"icons"];
    [iconColumn setWidth:32.0];
    [iconColumn setMinWidth:32.0];
    [iconColumn setDataView:iconView];
    [tableView addTableColumn:iconColumn];

    for (var i = 1; i <= 5; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];

        [[column headerView] setStringValue:"Number " + i];

        [column setMaxWidth:500.0];
        [column setWidth:200.0];

        [tableView addTableColumn:column];
    }

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([contentView bounds]) / 2, CGRectGetWidth([contentView bounds]), CGRectGetHeight([contentView bounds]) / 2)];

    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:scrollView];

    [theWindow orderFront:self];

}

- (int)numberOfRowsInTableView:(CPTableView)atableView
{
    return 500;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if ([aColumn identifier] === "icons")
        return iconImage;

    return aRow;
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(int)aRow
{
    var groups = [];

    for (var i = 0; i < 100; i += 5)
        groups.push(i);

    return [groups containsObject:aRow];
}

@end
