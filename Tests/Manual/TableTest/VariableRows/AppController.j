/*
 * AppController.j
 * TestTemplate
 *
 * Created by You on August 10, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

var tableTestDragType = "tableTestDragType";

@implementation AppController : CPObject
{
    CPTableView table;
    CPTableColumn columnA;
    CPTableColumn columnB;
    CPTableColumn columnC;
    CPTableColumn columnD;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        button = [[CPButton alloc] initWithFrame:CGRectMake(10,10,100,24)];

    [button setTitle:"toggle selection style"];
    [button sizeToFit];
    [button setTarget:self];
    [button setAction:@selector(toggleStyle:)];

    [contentView addSubview:button];

    var scroll = [[CPScrollView alloc] initWithFrame:CGRectMake(100,100,700,400)];

    table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setUsesAlternatingRowBackgroundColors:YES];

    [table setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table setAllowsMultipleSelection:YES];
    [table registerForDraggedTypes:[tableTestDragType]];

    [table setIntercellSpacing:CGSizeMake(0,0)];

    columnA = [[CPTableColumn alloc] initWithIdentifier:"A"];
    [table addTableColumn:columnA];
    [[columnA headerView] setStringValue:"A"];
    [columnA setWidth:175];

    columnB = [[CPTableColumn alloc] initWithIdentifier:"B"];
    [table addTableColumn:columnB];
    [[columnB headerView] setStringValue:"B"];
    [columnB setWidth:175]

    columnC = [[CPTableColumn alloc] initWithIdentifier:"C"];
    [table addTableColumn:columnC];
    [[columnC headerView] setStringValue:"C"];
    [columnC setWidth:175];

    columnD = [[CPTableColumn alloc] initWithIdentifier:"D"];
    [table addTableColumn:columnD];
    [[columnD headerView] setStringValue:"D"];
    [columnD setWidth:175];

    columnE = [[CPTableColumn alloc] initWithIdentifier:"E"];
    [table addTableColumn:columnE];
    [[columnE headerView] setStringValue:"E"];
    [columnE setWidth:175];

    [scroll setDocumentView:table];

    [contentView addSubview:scroll];

    [theWindow orderFront:self];

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

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(CPInteger)aRow
{
    return !(aRow % 5);
}

- (void)toggleStyle:(id)sender
{
    var style = [table selectionHighlightStyle];

    if (style === CPTableViewSelectionHighlightStyleSourceList)
        [table setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleRegular];
    else
        [table setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList]
}


- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    var data = [rowIndexes, [aTableView UID]];

    var encodedData = [CPKeyedArchiver archivedDataWithRootObject:data];
    [pboard declareTypes:[CPArray arrayWithObject:tableTestDragType] owner:self];
    [pboard setData:encodedData forType:tableTestDragType];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                   validateDrop:(id)info
                   proposedRow:(CPInteger)row
                   proposedDropOperation:(CPTableViewDropOperation)operation
{
    [aTableView setDropRow:(row) dropOperation:CPTableViewDropOn];

    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation
{
    return YES;
}

@end
