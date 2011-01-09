@import <AppKit/AppKit.j>

@implementation CPOutlineViewTest : OJTestCase
{
    CPOutlineView   outlineView;
    CPTableColumn   tableColumn;
    TestDataSource  dataSource;
}

- (void)setUp
{
    outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    [outlineView addTableColumn:tableColumn];
    [outlineView setOutlineTableColumn:tableColumn];

    [outlineView setAllowsMultipleSelection:YES];

    dataSource = [TestDataSource new];
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

    [outlineView collapseItem:".1"];

    afterSelection = [outlineView selectedRowIndexes];

    [self assert:1 equals:[afterSelection count] message:"1 selection should disappear"];

    [self assert:".3" equals:[outlineView itemAtRow:[afterSelection firstIndex]] message:".3 selection should remain"];
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
    [preSelection addIndex:[outlineView rowForItem:".2"]];

    [outlineView selectRowIndexes:preSelection byExtendingSelection:NO];

    [outlineView expandItem:".1.2"];
    afterSelection = [outlineView selectedRowIndexes];

    [self assert:2 equals:[afterSelection count] message:"selections should remain"];

    [self assert:".1.1" equals:[outlineView itemAtRow:[afterSelection firstIndex]] message:".1.1 selection should remain"];
    [self assert:".2" equals:[outlineView itemAtRow:[afterSelection lastIndex]] message:".2 selection should remain"];
}

@end

@implementation TestDataSource : CPObject
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

@end
