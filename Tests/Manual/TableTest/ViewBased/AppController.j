/*
 * AppController.j
 * CPTableViewViewBased
 *
 * Created by cacaodev.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "../CPTrace.j"

@implementation AppController : CPObject
{
    CPTableView tableView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [self buildModel];

    tableView = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [tableView setDataSource:self];
    [tableView setDelegate:self];

    var columnA = [[CPTableColumn alloc] initWithIdentifier:"A"];
    [tableView addTableColumn:columnA];
    [[columnA headerView] setStringValue:"A"];
    [columnA setWidth:175];

    var columnB = [[CPTableColumn alloc] initWithIdentifier:"B"];
    [tableView addTableColumn:columnB];
    [[columnB headerView] setStringValue:"B"];
    [columnB setWidth:175]

    var columnC = [[CPTableColumn alloc] initWithIdentifier:"C"];
    [tableView addTableColumn:columnC];
    [[columnC headerView] setStringValue:"C"];
    [columnC setWidth:175];

    var columnD = [[CPTableColumn alloc] initWithIdentifier:"D"];
    [tableView addTableColumn:columnD];
    [[columnD headerView] setStringValue:"D"];
    [columnD setWidth:175];

    var columnE = [[CPTableColumn alloc] initWithIdentifier:"E"];
    [tableView addTableColumn:columnE];
    [[columnE headerView] setStringValue:"E"];
    [columnE setWidth:175];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(100,100,700,400)];
    [scrollView setDocumentView:tableView];
    [contentView addSubview:scrollView];

    var tlr = 0;
    var f = function(a,b,c,d,e,f,g)
    {
        var lr = [c[0] count];
        if (d > 0)
            tlr += lr;
    
        var avg = (ROUND(100 * e/tlr) / 100);
        console.log(b + " " + lr + " rows in " + d + " ms ; avg/row = " + avg + " ms");
    }

    CPTrace(@"CPTableView", @"_loadDataViewsInRows:columns:", f);

    [theWindow orderFront:self];
}

- (void)buildModel // For the editable view aka the slider
{
    content = [];

    var count = 10000;
    while (count--)
        content.push({A:10,B:10,C:10,D:10,E:10});
}

- (IBAction)sliderAction:(id)sender
{
    var row = [tableView rowForView:sender],
        column = [tableView columnForView:sender],
        identifier = [[[tableView tableColumns] objectAtIndex:column] identifier];

    //CPLogConsole(_cmd + sender + " row = " + row + " column = " + column);
    content[row][identifier] = [sender value];
}

- (int)numberOfRowsInTableView:(id)aTableView
{
    return content.length;
}

- (void)tableView:(CPTableView)aTableView dataViewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var n = (aRow % 3),
        viewKind = "view_kind_" + n,
        tableColumnId = [aTableColumn identifier],

        view = [aTableView makeViewWithIdentifier:viewKind owner:self];

    if (view == nil)
    {
        if (n == 0)
            view = [[CPTableCellView alloc] initWithFrame:CGRectMakeZero()];
        else if (n == 1)
        {
            view = [[CPSlider alloc] initWithFrame:CGRectMakeZero()];
            [view setMinValue:0];
            [view setMaxValue:20];
            [view setTarget:self];
            [view setAction:@selector(sliderAction:)];
        }
        else
            view = [[CPLevelIndicator alloc] initWithFrame:CGRectMakeZero()];

        [view setIdentifier:viewKind];
    }

    if (n == 0)
        [view setObjectValue:("Column " + tableColumnId + " Row " + aRow)];
    else if (n == 1)
        [view setValue:content[aRow][tableColumnId]];

    return view;
}

@end

