@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

@implementation CPTableViewTableColumnTest : OJTestCase
{
    CPWindow        theWindow;
    CPTableView     tableView;
}

- (void)setUp
{
    // setup a reasonable table
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                            styleMask:CPWindowNotSizable];

    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [tableView setDataSource:self];

    var itemIndex = 0,
        items = [@"Colonne1", @"Colonne2", @"Colonne3", @"Colonne4"];

    for (itemIndex ; itemIndex < [items count]; itemIndex++)
    {
        var item = [items objectAtIndex:itemIndex],
            column = [[CPTableColumn alloc] initWithIdentifier:item];
        [column setEditable:YES];
        [column setMinWidth:50];
        [[column headerView] setStringValue:item];
        [tableView addTableColumn:column];
    }

    [[theWindow contentView] addSubview:tableView];

    [tableView reloadData];
}

- (void)testRemoveTableColumn
{
    [self assertTrue:([[tableView tableColumns] count] == 4)];

    [tableView removeTableColumn:[[tableView tableColumns] firstObject]];
    [self assertTrue:([[tableView tableColumns] count] == 3)];

    [tableView removeTableColumn:[[tableView tableColumns] firstObject]];
    [self assertTrue:([[tableView tableColumns] count] == 2)];

    var enumerateViewsInRowsCall = 0;

    [tableView enumerateAvailableViewsUsingBlock:function(view, row, column, stop)
    {
        var tableColumn = [[tableView tableColumns] objectAtIndex:column];
        [self assert:("COLUMN_" + [tableColumn identifier] + "ROW_" + row) equals:[view objectValue]];
        enumerateViewsInRowsCall++;
    }];

    [self assert:enumerateViewsInRowsCall equals:30];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 15;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRowIndex
{
    return "COLUMN_" + [aColumn identifier] + "ROW_" + aRowIndex;
}

@end