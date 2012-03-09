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
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 200, 150)
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
                row = startingRow + Math.floor(i / 2); // Two columns per row.
            //CPLog.error([view stringValue] + " frame: " + CPStringFromRect([tableView convertRect:[view frame] toView:nil]));
            [self assert:("R" + row + "C" + column) equals:[view stringValue] message:"(" + row + ", " + column + ") string value"];
            [self assert:"CustomTextView" + column equals:[[view class] description] message:"(" + row + ", " + column + ") data view"];
        }

        return allViews;
    }

    var allViews = AssertCorrectCellsVisible(0),
        visibleHeight = [tableView visibleRect].size.height,
        fullRowHeight = [tableView rowHeight] + [tableView intercellSpacing].height,
        visibleRows = Math.ceil(visibleHeight / fullRowHeight);
    [self assert:2 * visibleRows equals:[allViews count] message:"only as many data views as necessary should be present"];

    // Now if we scroll down, new views should come in and others should go out.
    var rowTwentyFiveAndAHalfY = Math.floor(25.5 * fullRowHeight);
    [tableView scrollPoint:CGPointMake(0, rowTwentyFiveAndAHalfY)];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    AssertCorrectCellsVisible(25);
    [self assert:2 * visibleRows  equals:[allViews count] message:"only as many data views as necessary should be present (2)"];
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
