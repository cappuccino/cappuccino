@import <AppKit/AppKit.j>

@implementation CPTableViewTest : OJTestCase
{
    CPTableView     tableView;
    CPTableColumn   tableColumn;

    CPArray         tableEntries;

    BOOL            doubleActionReceived;
    int             selectionDidChangeNotificationsReceived;
}

- (void)setUp
{
    // setup a reasonable table
    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    [tableView addTableColumn:tableColumn];
}

- (void)testDoubleAction
{
    doubleActionReceived = NO;

    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleAction:)];

    // CPEvent with 2 clickCount
    var dblClk = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMake(50, 50) modifierFlags:0
                          timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:2 pressure:0];

    [[CPApplication sharedApplication] sendEvent:dblClk];
    [tableView trackMouse:dblClk];

    [self assertTrue:doubleActionReceived];
}

- (void)doubleAction:(id)sender
{
    doubleActionReceived = YES;
}

/*!
    Test that proper notifications are sent - or not sent - during the course of a table data
    change which might affect the selection.
*/
- (void)testNumberOfRowsChangedSelectionNotification
{
    tableEntries = ["A", "B", "C"];
    [tableView setDataSource:self];

    selectionDidChangeNotificationsReceived = 0;
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:CPTableViewSelectionDidChangeNotification
                                               object:tableView];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self assert:selectionDidChangeNotificationsReceived equals:1 message:"CPTableViewSelectionDidChangeNotification expected when selecting rows"];

    // If we remove the last row, the selection should change and we should be notified.
    [tableEntries removeObjectAtIndex:2];
    [tableView reloadData];

    [self assert:selectionDidChangeNotificationsReceived equals:2  message:"CPTableViewSelectionDidChangeNotification when selected rows go away"];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"CPTableViewSelectionDidChangeNotification expected when selecting rows"];
    [tableEntries removeObjectAtIndex:1];
    [tableView reloadData];

    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"no CPTableViewSelectionDidChangeNotification expected when removing a row which does not change the selection"];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [tableEntries count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return tableEntries[aRow];
}

- (void)selectionDidChange:(CPNotification)aNotification
{
    selectionDidChangeNotificationsReceived++;
}

@end
