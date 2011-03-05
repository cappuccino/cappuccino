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
     theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    var aFrame = CGRectMake(0,32,CGRectGetWidth([[theWindow contentView] bounds]), CGRectGetHeight([[theWindow contentView] bounds]) -32);

     view1 = [[CPView alloc] initWithFrame:aFrame];
     view2 = [[CPView alloc] initWithFrame:aFrame];

    var scroll = [[CPScrollView alloc] initWithFrame:aFrame];
    [scroll setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    table1 = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table1 setDataSource:self];
    [table1 setDelegate:self];
    [table1 setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [table1 setUsesAlternatingRowBackgroundColors:YES];

    [table1 setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table1 setAllowsMultipleSelection:YES];

    [table1 setIntercellSpacing:CGSizeMake(0,0)];

    var column = [[CPTableColumn alloc] initWithIdentifier:"A"];
    [table1 addTableColumn:column];
    [[column headerView] setStringValue:"A"];
    [column setWidth:175];
    [column setMinWidth:100];
    [column setMaxWidth:250];
    [scroll setDocumentView:table1];
    [view1 addSubview:scroll];

    var scroll = [[CPScrollView alloc] initWithFrame:aFrame];
    [scroll setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    table2 = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table2 setDataSource:self];
    [table2 setDelegate:self];
    [table2 setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [table2 setUsesAlternatingRowBackgroundColors:YES];

    [table2 setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table2 setAllowsMultipleSelection:YES];

    [table2 setIntercellSpacing:CGSizeMake(0,0)];

    var column = [[CPTableColumn alloc] initWithIdentifier:"B"];
    [table2 addTableColumn:column];
    [[column headerView] setStringValue:"B"];
    [column setWidth:175];
    [column setMinWidth:100];
    [column setMaxWidth:250];
    [scroll setDocumentView:table2];
    [view2 addSubview:scroll];



        var aButton = [[CPButton alloc] initWithFrame:CGRectMake(6,6, 24, 24)];
        [aButton setTitle:@"B"];
        [aButton setTarget:self];
        [aButton setEnabled:YES];
        [aButton setAction:@selector(goToB)];
        [[theWindow contentView] addSubview:aButton];      

        aButton = [[CPButton alloc] initWithFrame:CGRectMake(36,6, 24, 24)];
        [aButton setTitle:@"A"];
        [aButton setTarget:self];
        [aButton setEnabled:YES];
        [aButton setAction:@selector(goToA)];
        [[theWindow contentView] addSubview:aButton];      





    [[theWindow contentView] addSubview:view1];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (int)numberOfRowsInTableView:(id)tableView
{
    return 100;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return "Column " + [aColumn identifier] + " Row " + aRow;
}

- (int)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
{
    return 24;
}

- (void)goToA
{
    [view2 removeFromSuperview];
    [[theWindow contentView] addSubview:view1];
    [table1 _setSelectedRowIndexes:[[table2 selectedRowIndexes] copy]];
}
- (void)goToB
{
    [view1 removeFromSuperview];
    [[theWindow contentView] addSubview:view2];
    [table2 _setSelectedRowIndexes:[[table1 selectedRowIndexes] copy]];
}

@end
