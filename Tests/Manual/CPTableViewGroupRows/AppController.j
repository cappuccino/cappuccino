/*
 * AppController.j
 * CPTableViewGroupRows
 *
 * Created by You on November 5, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPArray dataSource;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        tableView = [[CPTableView alloc] initWithFrame:CGRectMakeZero()],
        col = [[CPTableColumn alloc] initWithIdentifier:'test'],
        scrollView = [[CPScrollView alloc] initWithFrame:[contentView bounds]];

    [tableView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tableView setUsesAlternatingRowBackgroundColors:YES];

    [tableView addTableColumn:col];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [scrollView setDocumentView:tableView];

    dataSource = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    [tableView reloadData];

    [CPTimer scheduledTimerWithTimeInterval:5 callback:function() {
        dataSource = [1, 2, 3];
        [tableView reloadData];
    } repeats:nil];

    [contentView addSubview:scrollView];
    [theWindow orderFront:self];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [dataSource count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)rowIndex
{
    return dataSource[rowIndex];
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(CPInteger)rowIndex
{
    return rowIndex == 5;
}

@end
