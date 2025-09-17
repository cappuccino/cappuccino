/*
 * AppController.j
 * ColumnResize
 *
 * Created by You on December 10, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{

}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var scroll = [[CPScrollView alloc] initWithFrame:[contentView bounds]];

    [scroll setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:YES];

    [table setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table setAllowsMultipleSelection:YES];

    [table setIntercellSpacing:CGSizeMake(0,0)];

    columnA = [[CPTableColumn alloc] initWithIdentifier:"A"];
    [table addTableColumn:columnA];
    [[columnA headerView] setStringValue:"A"];
    [columnA setWidth:175];
    [columnA setMinWidth:100];
    [columnA setMaxWidth:250];

    columnB = [[CPTableColumn alloc] initWithIdentifier:"B"];
    [table addTableColumn:columnB];
    [[columnB headerView] setStringValue:"B"];
    [columnB setWidth:175];
    [columnB setMinWidth:100];

    columnC = [[CPTableColumn alloc] initWithIdentifier:"C"];
    [table addTableColumn:columnC];
    [[columnC headerView] setStringValue:"C"];
    [columnC setWidth:175];
    [columnC setMinWidth:100];

    columnD = [[CPTableColumn alloc] initWithIdentifier:"D"];
    [table addTableColumn:columnD];
    [[columnD headerView] setStringValue:"D"];
    [columnD setWidth:175];
    [columnD setMaxWidth:200];
    [columnD setMinWidth:100];

    columnE = [[CPTableColumn alloc] initWithIdentifier:"E"];
    [table addTableColumn:columnE];
    [[columnE headerView] setStringValue:"E"];
    [columnE setWidth:175];
    [columnE setMaxWidth:200];
    [columnE setMinWidth:100];


    [scroll setDocumentView:table];

    [contentView addSubview:scroll];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (int)numberOfRowsInTableView:(id)tableView
{
    return 2000;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    return "Column " + [aColumn identifier] + " Row " + aRow;
}

- (int)tableView:(CPTableView)aTableView heightOfRow:(CPInteger)aRow
{
    return aRow % 2 ? 200 : 50;
    return aRow % 2 ? 1010 - (aRow * 10) : 10 + (aRow * 10);
}

@end
