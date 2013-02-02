@import <AppKit/AppKit.j>

@implementation CPOutlineViewTest : OJTestCase
{
    CPOutlineView   outlineView;
    CPTableColumn   tableColumn;
    TestOutlineDataSource  dataSource;
}

- (void)setUp
{
    outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    [outlineView addTableColumn:tableColumn];
    [outlineView setOutlineTableColumn:tableColumn];

    [outlineView setAllowsMultipleSelection:YES];

    dataSource = [TestOutlineDataSource new];
    [dataSource setEntries:[".1", ".1.1", ".1.2", ".1.2.1", ".1.2.2", ".2", ".3", ".3.1"]];

    [outlineView setDataSource:dataSource];
    [outlineView expandItem:nil expandChildren:YES];
}

/*!
    Test that entries load and hide correctly.
*/
- (void)testCollapse
{
    // By default all rows should be visible.
    var entries = [dataSource entries];
    for (var i = 0; i < entries.length; i++)
    {
        var item = [outlineView itemAtRow:i];
        [self assert:entries[i] equals:item message:"item " + i + " visible, in correct order"];
    }

    // Now collapse the .1 group.
    [outlineView collapseItem:".1"];
    var expected = [".1", ".2", ".3", ".3.1"];
    for (var i = 0; i < expected.length; i++)
    {
        var item = [outlineView itemAtRow:i];
        [self assert:expected[i] equals:item message:"item " + i + " visible after collapse, in correct order"];
    }
}

/*!
    Test that when an ancestor item containing a selected item is collapsed, the item is deselected.
*/
- (void)testCollapseDeselect
{
    var preSelection = [CPIndexSet indexSet];
    [preSelection addIndex:[outlineView rowForItem:".1.2.2"]];
    [preSelection addIndex:[outlineView rowForItem:".1.1"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];

    [outlineView collapseItem:".1.2"];

    var afterSelection = [outlineView selectedRowIndexes];

    [self assert:1 equals:[afterSelection count] message:"1 selection should remain"];
    [self assert:".1.1" equals:[outlineView itemAtRow:[outlineView selectedRow]] message:".1.1 selection should remain"];
}

/*!
    Test that the selection stays on the same item below a collapse.
*/
- (void)testCollapseWithSelectionBelow
{
    // [".1", ".1.1", ".1.2", ".1.2.1", ".1.2.2", ".2", ".3", ".3.1"]
    var preSelection = [CPIndexSet indexSet];
    [preSelection addIndex:[outlineView rowForItem:".1.1"]];
    [preSelection addIndex:[outlineView rowForItem:".3.1"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];

    [outlineView collapseItem:".1.2"];

    var afterSelection = [outlineView selectedRowIndexes];

    [self assert:2 equals:[afterSelection count] message:"selections should remain"];
    [self assert:".1.1" equals:[outlineView itemAtRow:[afterSelection firstIndex]] message:".1.1 selection should remain"];
    [self assert:".3.1" equals:[outlineView itemAtRow:[afterSelection lastIndex]] message:".3.1 selection should remain"];

    // Collapse where one selection disappears and one shifts.
    preSelection = [CPIndexSet indexSet];
    [preSelection addIndex:[outlineView rowForItem:".1.1"]];
    [preSelection addIndex:[outlineView rowForItem:".3"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];

    // Test that by the time the selection notification is sent out, rows have
    // updated so that the selection matches the right items in the outline view.
    var delegate = [TestNotificationsDelegate new];
    [delegate setTester:self];
    [delegate setExpectedSelectedItems:[".3", ]];
    [outlineView setDelegate:delegate];

    [outlineView collapseItem:".1"];

    afterSelection = [outlineView selectedRowIndexes];
    [self assert:1 equals:[afterSelection count] message:"1 selection should disappear"];
    [self assert:".3" equals:[outlineView itemAtRow:[afterSelection firstIndex]] message:".3 selection should remain"];
    [self assert:1 equals:[delegate selectionChangeCount] message:"selection notifications during collapseItem"];
}

/*!
    Test that the selection stays on the same item below an expand.
*/
- (void)testExpandWithSelectionBelow
{
    // [".1", ".1.1", ".1.2", ".1.2.1", ".1.2.2", ".2", ".3", ".3.1"]
    [outlineView collapseItem:".1.2"];

    var preSelection = [CPIndexSet indexSet];
    [preSelection addIndex:[outlineView rowForItem:".1.1"]];
    [preSelection addIndex:[outlineView rowForItem:".3.1"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];

    // Test that by the time the selection notification is sent out, rows have
    // been expanded. E.g. the outline view is made consistent before notifying.
    var delegate = [TestNotificationsDelegate new];
    [delegate setTester:self];
    [outlineView setDelegate:delegate];

    [outlineView expandItem:".1.2"];

    var afterSelection = [outlineView selectedRowIndexes];
    [self assert:2 equals:[afterSelection count] message:"selections should remain"];

    [self assert:".1.1" equals:[outlineView itemAtRow:[afterSelection firstIndex]] message:".1.1 selection should remain"];
    [self assert:".3.1" equals:[outlineView itemAtRow:[afterSelection lastIndex]] message:".3.1 selection should remain"];
    [self assert:1 equals:[delegate selectionChangeCount] message:"selection notifications during expandItem"];
}

/*!
    Test selection updates when an expanded node has pre-expanded children.
*/
- (void)testExpandWithSelectionBelowAndExpandedChildren
{
    // [".1", ".1.1", ".1.2", ".1.2.1", ".1.2.2", ".2", ".3", ".3.1"]
    [outlineView collapseItem:".1"];

    var preSelection = [CPIndexSet indexSet];
    [preSelection addIndex:[outlineView rowForItem:".2"]];
    [preSelection addIndex:[outlineView rowForItem:".3.1"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];
    var delegate = [TestNotificationsDelegate new];
    [delegate setTester:self];
    [delegate setExpectedSelectedItems:[".2", ".3.1"]];
    [outlineView setDelegate:delegate];

    [outlineView expandItem:".1"];
    // The delegate will check the selection update but not the count.
    [self assert:2 equals:[[outlineView selectedRowIndexes] count] message:"selections should remain"];
}


- (void)testExpandCollapseItemVisibility
{
    var delegate = [TestExpandCollapseVisibilityDelegate new];
    [delegate setTester:self];
    [outlineView setDelegate:delegate];

    [outlineView collapseItem:".1"];
    [outlineView expandItem:".1"];
}

/*!
    Test that the outline view archives properly.
*/
- (void)testCoding
{
    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:outlineView]];

    outlineView = decoded;
    // Expansion state does not archive.
    [outlineView expandItem:nil expandChildren:YES];
    // While not exhaustive, if this test works nothing is majorly broken with the unarchived outline view.
    [self testCollapse];
}

@end

@implementation TestOutlineDataSource : CPObject
{
    CPArray entries @accessors;
}

- (CPArray)childrenOfPrefix:(CPString)theItem
{
    if (!theItem)
        theItem = "";

    var matcher = new RegExp("^" + theItem + "\\.\\d$"),
        children = [];
    for (var i = 0; i < entries.length; i++)
        if (matcher.exec(entries[i]))
            children.push(entries[i]);

    return children;
}

- (id)outlineView:(CPOutlineView)theOutlineView child:(int)theIndex ofItem:(id)theItem
{
    return [self childrenOfPrefix:theItem][theIndex];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)theItem
{
    return !![[self childrenOfPrefix:theItem] count];
}

- (int)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)theItem
{
    return [[self childrenOfPrefix:theItem] count];
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)theColumn byItem:(id)theItem
{
    return theItem;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        entries = [aCoder decodeObjectForKey:"entries"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:entries forKey:"entries"];
}

@end

@implementation TestNotificationsDelegate : CPObject
{
    id      tester @accessors;
    CPArray expectedSelectedItems @accessors;
    int     selectionChangeCount @accessors;
}

- (id)init
{
    if (self = [super init])
        selectionChangeCount = 0;
    return self;
}

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    selectionChangeCount++;

    // Verify that the state is consistent - every selected row has been loaded.
    var anOutlineView = [aNotification object],
        selection = [anOutlineView selectedRowIndexes],
        rows = [];

    [selection getIndexes:rows maxCount:-1 inIndexRange:nil];

    for (var i = 0, count = [rows count]; i < count; i++)
    {
        var item = [anOutlineView itemAtRow:rows[i]];
        [tester assertTrue: item !== nil message:"selected row #" + i + " should exist"];
        if (expectedSelectedItems)
            [tester assert:expectedSelectedItems[i] equals:item message:"in notification selected row #" + i];
    }
}

@end

@implementation TestExpandCollapseVisibilityDelegate : CPObject
{
    id      tester @accessors;
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var anOutlineView = [aNotification object],
        visibleRows = [anOutlineView rowsInRect:[anOutlineView visibleRect]];

    [tester assertTrue:[anOutlineView isItemExpanded:".1"]];
    [tester assert:0 equals:visibleRows.location];
    [tester assert:8 equals:visibleRows.length];
}

- (void)outlineViewItemDidCollapse:(CPNotification)aNotification
{
    var anOutlineView = [aNotification object],
        visibleRows = [anOutlineView rowsInRect:[anOutlineView visibleRect]];

    [tester assertFalse:[anOutlineView isItemExpanded:".1"]];
    [tester assert:0 equals:visibleRows.location];
    [tester assert:4 equals:visibleRows.length];
}

- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var anOutlineView = [aNotification object],
        visibleRows = [anOutlineView rowsInRect:[anOutlineView visibleRect]];

    [tester assertFalse:[anOutlineView isItemExpanded:".1"]];
    [tester assert:0 equals:visibleRows.location];
    [tester assert:4 equals:visibleRows.length];
}

- (void)outlineViewItemDidExpand:(CPNotification)aNotification
{
    var anOutlineView = [aNotification object],
        visibleRows = [anOutlineView rowsInRect:[anOutlineView visibleRect]];

    [tester assertTrue:[anOutlineView isItemExpanded:".1"]];
    [tester assert:0 equals:visibleRows.location];
    [tester assert:8 equals:visibleRows.length];
}

@end
