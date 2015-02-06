@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

@implementation CPTableViewReloadDataTest : OJTestCase
{
    CPWindow        theWindow;
    CPTableView     tableView;
    CPArray         tableContent;
}

- (void)setUp
{
    tableContent = [];
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
}

- (void)testReloadDataAfterModelCountChangesFromZero
{
    tableContent = ["A", "B", "C"];

    [tableView reloadData];

    [tableView _enumerateViewsInRows:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 3)]  columns:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 4)] usingBlock:function(view, row, column, stop)
    {
        var tableColumn = [[tableView tableColumns] objectAtIndex:column],
            expected = [tableColumn identifier] + "_" + [tableContent objectAtIndex:row];

        [self assertTrue:([view stringValue] == expected)];
    }];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [tableContent count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRowIndex
{
    return [aColumn identifier] + "_" + [tableContent objectAtIndex:aRowIndex];
}

@end