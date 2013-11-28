/*
 * AppController.j
 * TableTest/Editing
 *
 * Created by Mike Fellows on July 15, 2011.
 * Copyright 2010, All rights reserved.
 */

@import <AppKit/CPScrollView.j>
@import <AppKit/CPTableColumn.j>
@import <AppKit/CPTableView.j>

@implementation AppController : CPObject
{
    CPArray rowData;
    CPArray rowEdits;
    Int numberOfRows;
    Int numberOfEditsKept;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        scroll = [[CPScrollView alloc] initWithFrame:[contentView bounds]];

    // Initialize data structures.

    numberOfRows = 10;
    numberOfEditsKept = 6;

    var i = numberOfRows;
    rowData = [];
    rowEdits = [];
    while (i--)
    {
        rowData[i] = "Initial Value, Row " + i;

        var j = numberOfEditsKept;
        rowEdits[i] = [];
        while (j--)
            rowEdits[i][j] = "";
    }

    // Build the table.

    [scroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:YES];
    [table setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table setAllowsMultipleSelection:NO];
    [table setIntercellSpacing:CGSizeMake(0,0)];

    var columnIndex = [[CPTableColumn alloc] initWithIdentifier:"Row"];
    [table addTableColumn:columnIndex];
    [[columnIndex headerView] setStringValue:"Row"];
    [columnIndex setWidth:50];

    var dataColumn = [[CPTableColumn alloc] initWithIdentifier:"Current"];
    [table addTableColumn:dataColumn];
    [[dataColumn headerView] setStringValue:"Current (Editable)"];
    [dataColumn setEditable:YES];
    [dataColumn setWidth:140];

    for (i = 0; i < numberOfEditsKept; i++)
    {
        var editColumn = [[CPTableColumn alloc] initWithIdentifier:"Edit" + i];
        [table addTableColumn:editColumn];
        [[editColumn headerView] setStringValue:i + 1 + " Edit" + (i > 0 ? "s" : "") + " Ago"];
        [editColumn setWidth:140];
    }

    // Add the table to the scroll view and window.

    [scroll setDocumentView:table];
    [contentView addSubview:scroll];
    [theWindow orderFront:self];
}

- (int)numberOfRowsInTableView:(id)tableView
{
    return numberOfRows;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    if ([aColumn identifier] == "Row")
        return aRow;
    else if ([aColumn identifier] == "Current")
        return rowData[aRow];
    else
    {
        var result = [aColumn identifier].match(/Edit(\d+)/);
        if (result)
            return rowEdits[aRow][parseInt(result[1])];
        else
            return "error";
    }
}

- (void)tableView:(CPTableView)tableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)tableColumn row:(CPInteger)aRow
{
    var name = [tableColumn identifier];

    switch (name)
    {
        case "Current":
        {
            rowEdits[aRow].unshift(rowData[aRow]);
            rowEdits[aRow].pop;
            rowData[aRow] = aValue;
            break;
        }
    }
}

@end
