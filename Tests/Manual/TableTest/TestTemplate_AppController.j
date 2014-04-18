/*
 * AppController.j
 * TestTemplate
 *
 * Created by You on August 10, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


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
        contentView = [theWindow contentView];

    var scroll = [[CPScrollView alloc] initWithFrame:CGRectMake(100,100,700,400)];

    table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table setDataSource:self];

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
    return 10000;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    return "Column " + [aColumn identifier] + " Row " + aRow;
}

@end
