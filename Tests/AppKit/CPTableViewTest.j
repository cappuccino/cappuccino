@import <AppKit/AppKit.j>

@implementation CPTableViewTest : OJTestCase
{
    CPTableView     tableView;
    CPTableColumn   tableColumn;

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
    var dataSource = [TestDataSource new];

    [dataSource setTableEntries:["A", "B", "C"]];
    [tableView setDataSource:dataSource];


    selectionDidChangeNotificationsReceived = 0;
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:CPTableViewSelectionDidChangeNotification
                                               object:tableView];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self assert:selectionDidChangeNotificationsReceived equals:1 message:"CPTableViewSelectionDidChangeNotification expected when selecting rows"];

    // If we remove the last row, the selection should change and we should be notified.
    [[dataSource tableEntries] removeObjectAtIndex:2];
    [tableView reloadData];

    [self assert:selectionDidChangeNotificationsReceived equals:2  message:"CPTableViewSelectionDidChangeNotification when selected rows go away"];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"CPTableViewSelectionDidChangeNotification expected when selecting rows"];
    [[dataSource tableEntries] removeObjectAtIndex:1];
    [tableView reloadData];

    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"no CPTableViewSelectionDidChangeNotification expected when removing a row which does not change the selection"];
}

- (void)selectionDidChange:(CPNotification)aNotification
{
    selectionDidChangeNotificationsReceived++;
}

/*!
    Test inline table editing.
*/
- (void)testEditCell
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,200,150)
                                                styleMask:CPWindowNotSizable];

    [[theWindow contentView] addSubview:tableView];

    var dataSource = [TestDataSource new];

    [dataSource setTableEntries:["A", "B", "C"]];
    [tableView setDataSource:dataSource];
    [tableView setDelegate:[EditableTableDelegate new]];

    [theWindow makeFirstResponder:tableView];
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [tableView editColumn:0 row:1 withEvent:nil select:YES];

    // Process all events immediately to make sure table data views are reloaded.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    // Now some text field should be the first responder.
    var fieldEditor = [theWindow firstResponder];
    [self assert:[fieldEditor class] equals:CPTextField message:"table cell editor should be a text field"];

    [fieldEditor setStringValue:"edited text"];
    [fieldEditor performClick:nil];

    [self assert:"edited text" equals:[dataSource tableEntries][1] message:"table cell edit should propagate to model"]

    // The first responder status should revert to the table view so that, for example, the user may continue
    // keyboard navigation to edit the next row.
    [self assert:[theWindow firstResponder] equals:tableView message:"table view should be first responder after cell edit"];
}

@end

@implementation TestDataSource : CPObject
{
    CPArray tableEntries @accessors;
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [tableEntries count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return tableEntries[aRow];
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    tableEntries[aRow] = anObject;
}

@end

@implementation EditableTableDelegate : CPObject
{
}

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aTableColumn row:(int)anRow
{
    return YES;
}

@end