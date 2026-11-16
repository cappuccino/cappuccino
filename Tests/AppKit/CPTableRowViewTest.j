/*
 *  CPTableRowViewTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-16.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/AppKit.j>

var RowViewTestDragType = @"RowViewTestDragType";

/*
    A row view class that a delegate gives to the table view.
*/
@implementation _RowViewTestRowView : CPTableRowView
@end

/*
    A table view subclass that records the calls of the two subclass hooks.
*/
@implementation _RowViewTestTableView : CPTableView
{
    CPArray     hookAddedRows   @accessors;
    CPArray     hookRemovedRows @accessors;
}

- (void)didAddRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRow
{
    [hookAddedRows addObject:aRow];
    [super didAddRowView:aRowView forRow:aRow];
}

- (void)didRemoveRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRow
{
    [hookRemovedRows addObject:aRow];
    [super didRemoveRowView:aRowView forRow:aRow];
}

@end

/*
    The data source of the table view, and a delegate that can give row views.
*/
@implementation _RowViewTestDataSource : CPObject
{
    CPInteger   numberOfRows        @accessors;
}

- (CPInteger)numberOfRowsInTableView:(CPTableView)aTableView
{
    return numberOfRows;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return @"Value " + aRow;
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id)anInfo proposedRow:(CPInteger)aRow proposedDropOperation:(CPTableViewDropOperation)anOperation
{
    return CPDragOperationMove;
}

@end

@implementation _RowViewTestDelegate : CPObject
{
    CPArray     rowViewRequests     @accessors;
    CPArray     addedRows           @accessors;
    CPArray     removedRows         @accessors;
    CPArray     selectionAtAdd      @accessors;
    CPIndexSet  groupRows           @accessors;
    CPString    rowViewIdentifier   @accessors;
    CPInteger   rowViewsMade        @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        rowViewRequests = [];
        addedRows = [];
        removedRows = [];
        selectionAtAdd = [];
        groupRows = [CPIndexSet indexSet];
        rowViewsMade = 0;
    }

    return self;
}

- (CPTableRowView)tableView:(CPTableView)aTableView rowViewForRow:(CPInteger)aRow
{
    [rowViewRequests addObject:aRow];

    var rowView = rowViewIdentifier ? [aTableView makeViewWithIdentifier:rowViewIdentifier owner:self] : nil;

    if (!rowView)
    {
        rowView = [[_RowViewTestRowView alloc] initWithFrame:CGRectMakeZero()];
        [rowView setIdentifier:rowViewIdentifier];
        rowViewsMade++;
    }

    return rowView;
}

- (void)tableView:(CPTableView)aTableView didAddRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRow
{
    [addedRows addObject:aRow];
    [selectionAtAdd addObject:[aRowView isSelected]];
}

- (void)tableView:(CPTableView)aTableView didRemoveRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRow
{
    [removedRows addObject:aRow];
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(CPInteger)aRow
{
    return [groupRows containsIndex:aRow];
}

@end

@implementation _RowViewTestDraggingInfo : CPObject
{
    CPPasteboard    draggingPasteboard  @accessors;
    CGPoint         draggingLocation    @accessors;
}

@end

/*
    An outline view's data source and delegate: two root items, A with the children A1 and
    A2, and B.
*/
@implementation _RowViewTestOutlineDataSource : CPObject
{
    CPArray     requestedItems  @accessors;
    CPArray     addedRows       @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        requestedItems = [];
        addedRows = [];
    }

    return self;
}

- (CPArray)_childrenOfItem:(id)anItem
{
    if (anItem === nil)
        return [@"A", @"B"];

    if (anItem === @"A")
        return [@"A1", @"A2"];

    return [];
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(CPInteger)anIndex ofItem:(id)anItem
{
    return [self _childrenOfItem:anItem][anIndex];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)anItem
{
    return [[self _childrenOfItem:anItem] count] > 0;
}

- (CPInteger)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)anItem
{
    return [[self _childrenOfItem:anItem] count];
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    return anItem;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id)anInfo proposedItem:(id)anItem proposedChildIndex:(CPInteger)anIndex
{
    return CPDragOperationMove;
}

- (CPTableRowView)outlineView:(CPOutlineView)anOutlineView rowViewForItem:(id)anItem
{
    [requestedItems addObject:anItem];

    return [[_RowViewTestRowView alloc] initWithFrame:CGRectMakeZero()];
}

- (void)outlineView:(CPOutlineView)anOutlineView didAddRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRow
{
    [addedRows addObject:aRow];
}

@end


/*
    Each visible row of a table view has a row view, a CPTableRowView, with AppKit's API. The
    table view sets every property of a row view; a row view only shows its state. A delegate
    can give the row views, and hears of each row view that the table view adds or removes.
*/
@implementation CPTableRowViewTest : OJTestCase
{
    CPWindow                    theWindow;
    CPScrollView                scrollView;
    _RowViewTestTableView       tableView;
    _RowViewTestDataSource      dataSource;
    _RowViewTestDelegate        delegate;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];

    /*
        The table view is the document view of a scroll view, so the area below the last row
        is part of the exposed rect.
    */
    scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];
    tableView = [[_RowViewTestTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];
    [tableView setHookAddedRows:[]];
    [tableView setHookRemovedRows:[]];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [column setWidth:150.0];
    [tableView addTableColumn:column];

    dataSource = [[_RowViewTestDataSource alloc] init];
    [dataSource setNumberOfRows:5];
    [tableView setDataSource:dataSource];

    [scrollView setDocumentView:tableView];
    [[theWindow contentView] addSubview:scrollView];

    [self reload];
}

/*
    Reloads the table view and lays it out, as the display cycle does.
*/
- (void)reload
{
    [tableView reloadData];
    [tableView load];
}

/*
    Gives the table view a delegate that gives row views, and reloads it. The records start
    after the reload.
*/
- (void)useDelegate
{
    delegate = [[_RowViewTestDelegate alloc] init];
    [tableView setDelegate:delegate];
    [self reload];

    [delegate setRemovedRows:[]];
    [tableView setHookRemovedRows:[]];
}

- (CPTableRowView)rowViewAtRow:(CPInteger)aRow
{
    return [tableView rowViewAtRow:aRow makeIfNecessary:NO];
}

/*
    Returns every row view among the subviews of the table view, the private ones below the
    last row included.
*/
- (CPArray)allRowViews
{
    var subviews = [tableView subviews],
        rowViews = [];

    for (var i = 0, count = [subviews count]; i < count; i++)
    {
        if ([subviews[i] isKindOfClass:[CPTableRowView class]])
            rowViews.push(subviews[i]);
    }

    return rowViews;
}

- (CPArray)rowsOfAvailableRowViews
{
    var rows = [];

    [tableView enumerateAvailableRowViewsUsingBlock:function(aRowView, aRow)
    {
        rows.push(aRow);
    }];

    return rows;
}

- (CPArray)sorted:(CPArray)anArray
{
    return [anArray copy].sort(function(lhs, rhs) { return lhs - rhs; });
}

- (void)testEachRowOnScreenHasARowView
{
    for (var row = 0; row < 5; row++)
        [self assertTrue:[[self rowViewAtRow:row] isKindOfClass:[CPTableRowView class]] message:@"row " + row];
}

- (void)testARowViewSpansTheFullWidthOfItsRow
{
    var rowView = [self rowViewAtRow:2],
        rowRect = [tableView rectOfRow:2];

    [self assert:0.0 equals:CGRectGetMinX([rowView frame])];
    [self assert:CGRectGetWidth([tableView bounds]) equals:CGRectGetWidth([rowView frame])];
    [self assert:CGRectGetMinY(rowRect) equals:CGRectGetMinY([rowView frame])];
    [self assert:CGRectGetHeight(rowRect) equals:CGRectGetHeight([rowView frame])];
}

- (void)testARowViewLiesBehindTheViewsOfItsRow
{
    var subviews = [tableView subviews],
        rowView = [self rowViewAtRow:1],
        dataView = [tableView viewAtColumn:0 row:1 makeIfNecessary:NO];

    [self assertTrue:[subviews indexOfObjectIdenticalTo:rowView] < [subviews indexOfObjectIdenticalTo:dataView]];
}

- (void)testARowViewTakesNoMouseEvents
{
    [self assertFalse:[[self rowViewAtRow:0] hitTests]];
    [self assertFalse:[[[CPTableRowView alloc] initWithFrame:CGRectMakeZero()] hitTests]];
}

- (void)testRowViewAtRowRaisesForARowOutsideTheTable
{
    [self assertThrows:function() { [tableView rowViewAtRow:5 makeIfNecessary:NO]; }];
    [self assertThrows:function() { [tableView rowViewAtRow:-1 makeIfNecessary:YES]; }];
}

/*
    Rows below the last row have row views too, so that the row look fills the empty area.
    These row views are private.
*/
- (void)testRowsBelowTheLastRowHavePrivateRowViews
{
    [self useDelegate];

    [self assertTrue:[[self allRowViews] count] > 5 message:@"the area below the last row has row views"];
    [self assert:[0, 1, 2, 3, 4] equals:[self rowsOfAvailableRowViews]];
    [self assert:[0, 1, 2, 3, 4] equals:[self sorted:[delegate rowViewRequests]]];
    [self assert:[0, 1, 2, 3, 4] equals:[self sorted:[delegate addedRows]]];

    var rowViews = [self allRowViews];

    for (var i = 0, count = [rowViews count]; i < count; i++)
    {
        if ([tableView rowForView:rowViews[i]] === -1)
            [self assert:[CPTableRowView class] equals:[rowViews[i] class] message:@"a row view below the last row"];
    }
}

- (void)testEnumerationVisitsEachRowViewInAscendingOrder
{
    var rowViews = [];

    [tableView enumerateAvailableRowViewsUsingBlock:function(aRowView, aRow)
    {
        [self assert:[self rowViewAtRow:aRow] same:aRowView];
        rowViews.push(aRow);
    }];

    [self assert:[0, 1, 2, 3, 4] equals:rowViews];
}

- (void)testTheSelectionReachesTheRowViews
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)] byExtendingSelection:NO];

    [self assertFalse:[[self rowViewAtRow:0] isSelected]];
    [self assertTrue:[[self rowViewAtRow:1] isSelected]];
    [self assertTrue:[[self rowViewAtRow:2] isSelected]];
    [self assertFalse:[[self rowViewAtRow:3] isSelected]];

    [self assertTrue:[[self rowViewAtRow:0] isNextRowSelected]];
    [self assertFalse:[[self rowViewAtRow:1] isPreviousRowSelected]];
    [self assertTrue:[[self rowViewAtRow:1] isNextRowSelected]];
    [self assertTrue:[[self rowViewAtRow:2] isPreviousRowSelected]];
    [self assertFalse:[[self rowViewAtRow:2] isNextRowSelected]];
    [self assertTrue:[[self rowViewAtRow:3] isPreviousRowSelected]];

    [tableView deselectAll:nil];

    for (var row = 0; row < 5; row++)
    {
        var rowView = [self rowViewAtRow:row];

        [self assertFalse:[rowView isSelected] message:@"row " + row];
        [self assertFalse:[rowView isPreviousRowSelected] message:@"row " + row];
        [self assertFalse:[rowView isNextRowSelected] message:@"row " + row];
    }
}

/*
    A row view of a selected row lays out when the table view has no selection colour, as
    under no theme. The table view derived the unfocused colour from no colour and raised,
    and the exception stopped the display server for every later layout.
*/
- (void)testASelectedRowViewLaysOutWithoutASelectionColor
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];

    var rowView = [self rowViewAtRow:1];

    [self assertNull:[tableView selectionHighlightColor] message:@"the test needs a table view without a selection colour"];
    [self assertTrue:[rowView needsLayout]];

    [rowView layoutIfNeeded];

    [self assertFalse:[rowView needsLayout]];
}

- (void)testSelectingARowViewDoesNotSelectTheRow
{
    [[self rowViewAtRow:1] setSelected:YES];

    [self assert:0 equals:[[tableView selectedRowIndexes] count]];
}

- (void)testRowViewsAreNotEmphasizedWithoutTheFocus
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];

    [self assertFalse:[[self rowViewAtRow:1] isEmphasized]];
}

- (void)testTheHighlightStyleReachesTheRowViews
{
    [self assert:CPTableViewSelectionHighlightStyleRegular equals:[[self rowViewAtRow:0] selectionHighlightStyle]];
    [self assert:CPTableViewDraggingDestinationFeedbackStyleRegular equals:[[self rowViewAtRow:0] draggingDestinationFeedbackStyle]];

    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];

    for (var row = 0; row < 5; row++)
    {
        [self assert:CPTableViewSelectionHighlightStyleSourceList equals:[[self rowViewAtRow:row] selectionHighlightStyle] message:@"row " + row];
        [self assert:CPTableViewDraggingDestinationFeedbackStyleSourceList equals:[[self rowViewAtRow:row] draggingDestinationFeedbackStyle] message:@"row " + row];
    }
}

- (void)testAGroupRowHasTheGroupRowStyle
{
    delegate = [[_RowViewTestDelegate alloc] init];
    [delegate setGroupRows:[CPIndexSet indexSetWithIndex:1]];
    [tableView setDelegate:delegate];
    [self reload];

    [self assertFalse:[[self rowViewAtRow:0] isGroupRowStyle]];
    [self assertTrue:[[self rowViewAtRow:1] isGroupRowStyle]];
}

- (void)testTheDelegateGivesTheRowViews
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [tableView setHookAddedRows:[]];
    [self useDelegate];

    for (var row = 0; row < 5; row++)
        [self assert:[_RowViewTestRowView class] equals:[[self rowViewAtRow:row] class] message:@"row " + row];

    [self assert:[0, 1, 2, 3, 4] equals:[delegate addedRows]];
    [self assert:[0, 1, 2, 3, 4] equals:[tableView hookAddedRows]];
    [self assert:[NO, YES, NO, NO, NO] equals:[delegate selectionAtAdd] message:@"a row view is configured before the table view announces it"];
}

- (void)testARowViewThatLeavesItsRowIsAnnounced
{
    [self useDelegate];

    [dataSource setNumberOfRows:2];
    [self reload];

    [self assert:[-1, -1, -1, 0, 1] equals:[self sorted:[delegate removedRows]]];
    [self assert:[-1, -1, -1, 0, 1] equals:[self sorted:[tableView hookRemovedRows]]];
}

- (void)testRowViewAtRowCanMakeARowViewForARowOffScreen
{
    [dataSource setNumberOfRows:30];
    [self useDelegate];

    [self assertNull:[self rowViewAtRow:25]];

    var rowView = [tableView rowViewAtRow:25 makeIfNecessary:YES];

    [self assertTrue:[rowView isKindOfClass:[CPTableRowView class]]];
    [self assert:rowView same:[self rowViewAtRow:25]];
    [self assertTrue:[[delegate addedRows] containsObject:25]];

    // The row view is temporary: the next layout removes it.
    [tableView load];

    [self assertNull:[self rowViewAtRow:25]];
    [self assertTrue:[[delegate removedRows] containsObject:25]];
}

- (void)testRowForViewAcceptsARowView
{
    var rowView = [self rowViewAtRow:3],
        subview = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)];

    [rowView addSubview:subview];

    [self assert:3 equals:[tableView rowForView:rowView]];
    [self assert:3 equals:[tableView rowForView:subview]];
    [self assert:-1 equals:[tableView columnForView:rowView]];
    [self assert:-1 equals:[tableView rowForView:[[CPTableRowView alloc] initWithFrame:CGRectMakeZero()]]];
}

- (void)testARowViewGivesTheViewsOfItsRow
{
    var rowView = [self rowViewAtRow:2];

    [self assert:1 equals:[rowView numberOfColumns]];
    [self assert:[tableView viewAtColumn:0 row:2 makeIfNecessary:NO] same:[rowView viewAtColumn:0]];
    [self assert:0 equals:[[[CPTableRowView alloc] initWithFrame:CGRectMakeZero()] numberOfColumns]];
}

/*
    A row view's background colour is the colour that the application set, else the
    alternating colour of the row, else the background colour of the table view.
*/
- (void)testTheBackgroundColorDefaultsToTheTableViewBackground
{
    [tableView setBackgroundColor:[CPColor yellowColor]];

    [self assert:[CPColor yellowColor] equals:[[self rowViewAtRow:1] backgroundColor]];
}

- (void)testTheBackgroundColorIsTheAlternatingColorOfTheRow
{
    var colors = [[CPColor redColor], [CPColor greenColor]];

    [tableView setAlternatingRowBackgroundColors:colors];
    [tableView setUsesAlternatingRowBackgroundColors:YES];

    for (var row = 0; row < 5; row++)
        [self assert:colors[row % 2] equals:[[self rowViewAtRow:row] backgroundColor] message:@"row " + row];
}

- (void)testABackgroundColorThatTheApplicationSetsStaysUntilTheRowViewLeavesItsRow
{
    var rowView = [self rowViewAtRow:1],
        color = [CPColor blueColor];

    [tableView setBackgroundColor:[CPColor yellowColor]];
    [rowView setBackgroundColor:color];
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];

    [self assert:color same:[rowView backgroundColor]];

    [self reload];

    [self assert:[CPColor yellowColor] equals:[rowView backgroundColor]];
}

/*
    The table view keeps a pool for the row views that it makes. A row view from the delegate
    that has an identifier goes to the queue of makeViewWithIdentifier:owner:.
*/
- (void)testTheTableViewReusesItsOwnRowViews
{
    var oldRowViews = [self allRowViews];

    [self reload];

    var newRowViews = [self allRowViews];

    [self assert:[oldRowViews count] equals:[newRowViews count]];

    for (var i = 0; i < [newRowViews count]; i++)
        [self assertTrue:[oldRowViews containsObjectIdenticalTo:newRowViews[i]] message:@"row view " + i];
}

- (void)testADelegateRowViewWithAnIdentifierIsReused
{
    delegate = [[_RowViewTestDelegate alloc] init];
    [delegate setRowViewIdentifier:@"RowView"];
    [tableView setDelegate:delegate];
    [self reload];
    [self reload];

    [self assert:5 equals:[delegate rowViewsMade]];
}

- (void)testADelegateRowViewWithoutAnIdentifierIsNotReused
{
    [self useDelegate];
    [self reload];

    [self assert:10 equals:[delegate rowViewsMade]];
}

- (void)testTheRowOfAProposedDropIsTheTargetForTheDrop
{
    [tableView registerForDraggedTypes:[RowViewTestDragType]];

    var info = [[_RowViewTestDraggingInfo alloc] init],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];

    [pasteboard declareTypes:[RowViewTestDragType] owner:self];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:[tableView convertPoint:CGPointMake(50.0, CGRectGetMidY([tableView rectOfRow:2])) toView:nil]];

    [tableView draggingUpdated:info];

    for (var row = 0; row < 5; row++)
        [self assert:(row === 2) equals:[[self rowViewAtRow:row] isTargetForDropOperation] message:@"row " + row];

    [self assert:0.0 equals:[[self rowViewAtRow:2] indentationForDropOperation]];

    [tableView draggingExited:info];

    [self assertFalse:[[self rowViewAtRow:2] isTargetForDropOperation]];
}

/*
    An outline view gives its delegate the row views of items, and sets the indentation of a
    drop to the indentation of the row's item.
*/
- (void)testAnOutlineViewDelegateGivesTheRowViewsOfItems
{
    var outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        outlineDataSource = [[_RowViewTestOutlineDataSource alloc] init],
        column = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    [outlineView setDataSource:outlineDataSource];
    [outlineView setDelegate:outlineDataSource];
    [[theWindow contentView] addSubview:outlineView];

    [outlineView expandItem:@"A"];

    [outlineDataSource setRequestedItems:[]];
    [outlineDataSource setAddedRows:[]];

    [outlineView reloadData];
    [outlineView load];

    [self assert:[@"A", @"A1", @"A2", @"B"] equals:[outlineDataSource requestedItems]];
    [self assert:[0, 1, 2, 3] equals:[outlineDataSource addedRows]];
    [self assert:[_RowViewTestRowView class] equals:[[outlineView rowViewAtRow:1 makeIfNecessary:NO] class]];

    [outlineView registerForDraggedTypes:[RowViewTestDragType]];

    var info = [[_RowViewTestDraggingInfo alloc] init],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard],
        childRow = [outlineView rowForItem:@"A1"];

    [pasteboard declareTypes:[RowViewTestDragType] owner:self];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:[outlineView convertPoint:CGPointMake(100.0, CGRectGetMidY([outlineView rectOfRow:childRow])) toView:nil]];

    [outlineView draggingUpdated:info];

    var rowView = [outlineView rowViewAtRow:childRow makeIfNecessary:NO];

    [self assertTrue:[rowView isTargetForDropOperation]];
    [self assert:[outlineView indentationPerLevel] equals:[rowView indentationForDropOperation]];
}

@end
