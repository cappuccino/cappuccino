@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

@implementation CPTableViewTest : OJTestCase
{
    CPWindow        theWindow;
    CPTableView     tableView;
    CPTableColumn   tableColumn;

    BOOL            doubleActionReceived;
    int             selectionIsChangingNotificationsReceived;
    int             selectionDidChangeNotificationsReceived;
}

- (void)setUp
{
    // setup a reasonable table
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                            styleMask:CPWindowNotSizable];

    tableView = [[FirstResponderConfigurableTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    tableView.acceptsFirstResponder = YES;
    [tableView addTableColumn:tableColumn];

    [[theWindow contentView] addSubview:tableView];
}

- (void)testDoubleAction
{
    doubleActionReceived = NO;

    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleAction:)];

    // CPEvent with 2 clickCount
    var dblClkDown = [CPEvent mouseEventWithType:CPLeftMouseDown location:CGPointMake(50, 50) modifierFlags:0
                          timestamp:0 windowNumber:[theWindow windowNumber] context:nil eventNumber:0 clickCount:2 pressure:0],
        dblClkUp = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMake(50, 50) modifierFlags:0
                          timestamp:0 windowNumber:[theWindow windowNumber] context:nil eventNumber:0 clickCount:2 pressure:0];

    [[CPApplication sharedApplication] sendEvent:dblClkDown];
    [tableView trackMouse:dblClkDown];

    [[CPApplication sharedApplication] sendEvent:dblClkUp];
    [tableView trackMouse:dblClkUp];

    [self assertTrue:doubleActionReceived];

    // The event should also work even if the table is not the first responder.
    tableView.acceptsFirstResponder = NO;
    [theWindow makeFirstResponder:nil];

    doubleActionReceived = NO;

    [[CPApplication sharedApplication] sendEvent:dblClkDown];
    [tableView trackMouse:dblClkDown];

    [[CPApplication sharedApplication] sendEvent:dblClkUp];
    [tableView trackMouse:dblClkUp];

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


    selectionIsChangingNotificationsReceived = 0;
    selectionDidChangeNotificationsReceived = 0;
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionIsChanging:)
                                                 name:CPTableViewSelectionIsChangingNotification
                                               object:tableView];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:CPTableViewSelectionDidChangeNotification
                                               object:tableView];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self assert:0 equals:selectionIsChangingNotificationsReceived message:"no isChanging notifications when programmatically selecting rows"];
    [self assert:1 equals:selectionDidChangeNotificationsReceived message:"didChange notifications when selecting rows"];

    // If we remove the last row, the selection should change and we should be notified.
    [[dataSource tableEntries] removeObjectAtIndex:2];
    [tableView reloadData];

    [self assert:0 equals:selectionIsChangingNotificationsReceived message:"no isChanging notifications when selected rows disappear"];
    [self assert:2 equals:selectionDidChangeNotificationsReceived message:"didChange notifications when selected rows disappear"];

    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"CPTableViewSelectionDidChangeNotification expected when selecting rows"];
    [[dataSource tableEntries] removeObjectAtIndex:1];
    [tableView reloadData];

    [self assert:selectionDidChangeNotificationsReceived equals:3 message:"no CPTableViewSelectionDidChangeNotification expected when removing a row which does not change the selection"];

    // Reset everything.
    [dataSource setTableEntries:["A", "B", "C"]];
    [tableView reloadData];
    [tableView deselectAll];
    selectionIsChangingNotificationsReceived = 0;
    selectionDidChangeNotificationsReceived = 0;
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self assert:2 equals:selectionDidChangeNotificationsReceived message:"notification for select row 0, 2"];

    selectionIsChangingNotificationsReceived = 0;
    selectionDidChangeNotificationsReceived = 0;
    [tableView deselectAll];
    [self assert:selectionDidChangeNotificationsReceived equals:2 message:"notification for deselect all"];
}

- (void)selectionIsChanging:(CPNotification)aNotification
{
    selectionIsChangingNotificationsReceived++;
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

/*!
    Verify that all data appears as expected, using the right data views etc. This is a bit of a kitchen
    sink test, verifying multiple behaviours of the table view.
*/
- (void)testLayout
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, 100.0, 100.0)],
        tableColumn1 = [[CPTableColumn alloc] initWithIdentifier:@"Bar"];
    [tableView addTableColumn:tableColumn1];
    [scrollView setDocumentView:tableView];

    [tableColumn setWidth:50.0];
    [tableColumn1 setWidth:50.0];

    var arrayController = [CPArrayController new],
        contentArray = [];

    for (var row = 0; row < 50; row++)
    {
        var column = row * 2;
        contentArray.push([CPDictionary dictionaryWithObjects:["R" + row + "C0", "R" + row + "C1"] forKeys:["c1", "c2"]]);
    }
    [arrayController setContent:contentArray];

    [tableColumn bind:CPValueBinding toObject:arrayController withKeyPath:@"arrangedObjects.c1" options:nil];
    [tableColumn1 bind:CPValueBinding toObject:arrayController withKeyPath:@"arrangedObjects.c2" options:nil];

    [tableColumn setDataView:[CustomTextView0 new]];
    [tableColumn1 setDataView:[CustomTextView1 new]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:50 equals:[tableView numberOfRows] message:"tableView numberOfRows should reflect content array length"];

    function AssertCorrectCellsVisible(startingRow)
    {
        var allViews = getAllViews(tableView);

        // Sort views from left to right, top to bottom.
        [allViews sortUsingFunction:keyViewComparator context:nil];

        // We only care about the placement of data views - what else the table puts in there is up to it.
        [allViews filterUsingPredicate:[CPPredicate predicateWithFormat:@"self.class.description beginswith %@", "CustomTextView"]];

        for (var i = 0; i < [allViews count]; i++)
        {
            var view = allViews[i],
                column = i % 2,
                row = startingRow + FLOOR(i / 2); // Two columns per row.
            //CPLog.error([view stringValue] + " frame: " + CPStringFromRect([tableView convertRect:[view frame] toView:nil]));
            [self assert:("R" + row + "C" + column) equals:[view stringValue] message:"(" + row + ", " + column + ") string value"];
            [self assert:"CustomTextView" + column equals:[[view class] description] message:"(" + row + ", " + column + ") data view"];
        }

        return allViews;
    }

    var allViews = AssertCorrectCellsVisible(0),
        visibleHeight = [tableView visibleRect].size.height,
        fullRowHeight = [tableView rowHeight] + [tableView intercellSpacing].height,
        visibleRows = CEIL(visibleHeight / fullRowHeight);
    [self assert:2 * visibleRows equals:[allViews count] message:"only as many data views as necessary should be present"];

    // Now if we scroll down, new views should come in and others should go out.
    var rowTwentyFiveAndAHalfY = FLOOR(25.5 * fullRowHeight);
    [tableView scrollPoint:CGPointMake(0, rowTwentyFiveAndAHalfY)];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    AssertCorrectCellsVisible(25);
    [self assert:2 * visibleRows  equals:[allViews count] message:"only as many data views as necessary should be present (2)"];
}

- (void)testContentBinding
{
    var contentBindingTable = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        delegate = [ContentBindingTableDelegate new];

    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"A"];

    [contentBindingTable addTableColumn:tableColumn];
    [delegate setTester:self];
    [contentBindingTable setDelegate:delegate];

    [delegate setTableEntries:[[@"A1", @"B1"], [@"A2", @"B2"], [@"A3", @"B3"]]];
    [contentBindingTable bind:@"content" toObject:delegate withKeyPath:@"tableEntries" options:nil];

    // The following should also work:
    //var ac = [[CPArrayController alloc] initWithContent:[delegate tableEntries]];
    //[contentBindingTable bind:@"content" toObject:ac withKeyPath:@"arrangedObjects" options:nil];

    [[theWindow contentView] addSubview:contentBindingTable];
    [theWindow makeFirstResponder:contentBindingTable];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    // Set the model again with different values
    [delegate setTableEntries:[[@"C1", @"D1"], [@"C2", @"D2"], [@"C3", @"D3"]]];
    [contentBindingTable reloadData];
}

- (void)testInitiallyHiddenColumns
{
    var table = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)],
        tableColumn1 = [[CPTableColumn alloc] initWithIdentifier:@"A"],
        tableColumn2 = [[CPTableColumn alloc] initWithIdentifier:@"B"],
        delegate = [ContentBindingTableDelegate new];

    [delegate setTester:self];
    [table setDelegate:delegate];

    [delegate setTableEntries:[[@"A1", @"B1"], [@"A2", @"B2"], [@"A3", @"B3"]]];
    [table bind:@"content" toObject:delegate withKeyPath:@"tableEntries" options:nil];

    [[theWindow contentView] addSubview:table];

    [tableColumn1 setHidden:YES];

    [tableColumn1 setWidth:50.0];
    [tableColumn2 setWidth:100.0];

    [table addTableColumn:tableColumn1];
    [table addTableColumn:tableColumn2];

    [table reloadData];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assertTrue:[table bounds].size.width > 100 && [table bounds].size.width < 200];

    [tableColumn1 setHidden:NO];
    [tableColumn1 setWidth:100.0];

    [self assertTrue:[table bounds].size.width >= 200];
}

@end

@implementation FirstResponderConfigurableTableView : CPTableView
{
    BOOL acceptsFirstResponder;
}

- (BOOL)acceptsFirstResponder
{
    return acceptsFirstResponder;
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

@implementation ContentBindingTableDelegate : CPObject
{
    // For the purpose of this test, the delegate contains the model (!).
    CPArray tableEntries @accessors;
    CPTableViewTest tester @accessors;
}

- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    // Make sure each view contains the full row in its objectValue
    [tester assert:tableEntries[row] equals:[aView objectValue]];
}

@end

@implementation CustomTextView0 : CPTextField
@end

@implementation CustomTextView1 : CPTextField
@end

var getAllViews = function(aView)
{
    var views = [aView],
        subviews = [aView subviews];

    for (var i = 0, count = [subviews count]; i < count; i++)
        views = views.concat(getAllViews(subviews[i]));

    return views;
};

var keyViewComparator = function(lhs, rhs, context)
{
    var lhsBounds = [lhs convertRect:[lhs bounds] toView:nil],
        rhsBounds = [rhs convertRect:[rhs bounds] toView:nil],
        lhsY = CGRectGetMinY(lhsBounds),
        rhsY = CGRectGetMinY(rhsBounds),
        lhsX = CGRectGetMinX(lhsBounds),
        rhsX = CGRectGetMinX(rhsBounds),
        intersectsVertically = MIN(CGRectGetMaxY(lhsBounds), CGRectGetMaxY(rhsBounds)) - MAX(lhsY, rhsY);

    // If two views are "on the same line" (intersect vertically), then rely on the x comparison.
    if (intersectsVertically > 0)
    {
        if (lhsX < rhsX)
            return CPOrderedAscending;

        if (lhsX === rhsX)
            return CPOrderedSame;

        return CPOrderedDescending;
    }

    if (lhsY < rhsY)
        return CPOrderedAscending;

    if (lhsY === rhsY)
        return CPOrderedSame;

    return CPOrderedDescending;
};
