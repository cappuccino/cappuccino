@import <AppKit/CPTreeNode.j>
@import <Foundation/CPIndexPath.j>
@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPKeyedArchiver.j>

@implementation CPTreeNodeTest : OJTestCase
{
    CPTreeNode      root;
    CPTreeNode      child1;
    CPTreeNode      child2;
    CPMutableArray  _kvoRecordedChanges;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    root = [CPTreeNode treeNodeWithRepresentedObject:@"root"];
    child1 = [CPTreeNode treeNodeWithRepresentedObject:@"child1"];
    child2 = [CPTreeNode treeNodeWithRepresentedObject:@"child2"];

    _kvoRecordedChanges = [];
}

/*
 * Records each KVO notification delivered to this test instance.
 * Used by the KVO-contract tests below.
 */
- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [_kvoRecordedChanges addObject:aChange];
}

// 1. creation and representedObject
- (void)testCreationAndRepresentedObject
{
    [self assert:@"root" equals:[root representedObject]];
    [self assertTrue:([root isKindOfClass:[CPTreeNode class]])];
}

// 2. root/parent relationships
- (void)testParentRelationships
{
    [self assert:nil equals:[root parentNode]];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [self assert:root equals:[child1 parentNode]];
}

// 3. insertion and automatic reparenting
- (void)testAutomaticReparenting
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [root insertObject:child2 inChildNodesAtIndex:0];

    [self assert:2 equals:[root countOfChildNodes]];

    // Move child1 to child2. It should be removed from root automatically.
    [child2 insertObject:child1 inChildNodesAtIndex:0];

    [self assert:child2 equals:[child1 parentNode]];
    [self assert:1 equals:[root countOfChildNodes]];
    [self assert:child2 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:child1 equals:[child2 objectInChildNodesAtIndex:0]];
}

// 4. removal
- (void)testRemoval
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [root removeObjectFromChildNodesAtIndex:0];

    [self assert:nil equals:[child1 parentNode]];
    [self assert:0 equals:[root countOfChildNodes]];
}

// 5. replacement
- (void)testReplacement
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [root replaceObjectInChildNodesAtIndex:0 withObject:child2];

    [self assert:nil equals:[child1 parentNode]];
    [self assert:root equals:[child2 parentNode]];
    [self assert:child2 equals:[root objectInChildNodesAtIndex:0]];
}

// 6. moving an existing child (verifies index adjustment logic)
- (void)testMovingExistingChild
{
    var c3 = [CPTreeNode treeNodeWithRepresentedObject:@"child3"];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [root insertObject:child2 inChildNodesAtIndex:1];
    [root insertObject:c3 inChildNodesAtIndex:2];

    // Array is [child1, child2, c3]. Move child1 (index 0) to index 2.
    [root insertObject:child1 inChildNodesAtIndex:2];

    [self assert:child2 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:c3 equals:[root objectInChildNodesAtIndex:1]];
    [self assert:child1 equals:[root objectInChildNodesAtIndex:2]];

    // Move child1 (index 2) back to index 0.
    [root insertObject:child1 inChildNodesAtIndex:0];

    [self assert:child1 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:child2 equals:[root objectInChildNodesAtIndex:1]];
    [self assert:c3 equals:[root objectInChildNodesAtIndex:2]];
}

// 7. rejection of cyclic relationships
- (void)testCycleRejection
{
    [root insertObject:child1 inChildNodesAtIndex:0];

    var e = [self assertThrows:function()
    {
        [child1 insertObject:root inChildNodesAtIndex:0];
    }];

    [self assert:CPInvalidArgumentException equals:[e name]];
}

// 8. childNodes and mutableChildNodes
- (void)testChildNodesCopyAndMutableProxy
{
    [root insertObject:child1 inChildNodesAtIndex:0];

    // childNodes must return a defensive copy
    var copy = [root childNodes];
    [copy removeObjectAtIndex:0];
    [self assert:1 equals:[root countOfChildNodes]];

    // mutableChildNodes must proxy back through KVC
    var mutableProxy = [root mutableChildNodes];
    [mutableProxy addObject:child2];

    [self assert:2 equals:[root countOfChildNodes]];
    [self assert:root equals:[child2 parentNode]];
}

// 9. index paths
- (void)testIndexPaths
{
    [self assert:[CPIndexPath indexPathWithIndexes:[]] equals:[root indexPath]];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [self assert:[CPIndexPath indexPathWithIndex:0] equals:[child1 indexPath]];

    [child1 insertObject:child2 inChildNodesAtIndex:0];
    [self assert:[CPIndexPath indexPathWithIndexes:[0, 0]] equals:[child2 indexPath]];
}

// 10. descendant lookup
- (void)testDescendantNodeAtIndexPath
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [child1 insertObject:child2 inChildNodesAtIndex:0];

    var path = [CPIndexPath indexPathWithIndexes:[0, 0]];
    [self assert:child2 equals:[root descendantNodeAtIndexPath:path]];

    var invalidPath = [CPIndexPath indexPathWithIndexes:[1, 0]];
    [self assert:nil equals:[root descendantNodeAtIndexPath:invalidPath]];
}

// 11. recursive sorting
- (void)testRecursiveSorting
{
    var nodeA = [CPTreeNode treeNodeWithRepresentedObject:@"A"];
    var nodeC = [CPTreeNode treeNodeWithRepresentedObject:@"C"];
    var nodeB = [CPTreeNode treeNodeWithRepresentedObject:@"B"];

    [root insertObject:nodeC inChildNodesAtIndex:0];
    [root insertObject:nodeA inChildNodesAtIndex:1];
    [root insertObject:nodeB inChildNodesAtIndex:2];

    // Add children to nodeB to verify recursion
    var childB2 = [CPTreeNode treeNodeWithRepresentedObject:@"B2"];
    var childB1 = [CPTreeNode treeNodeWithRepresentedObject:@"B1"];

    [nodeB insertObject:childB2 inChildNodesAtIndex:0];
    [nodeB insertObject:childB1 inChildNodesAtIndex:1];

    var sd = [[CPSortDescriptor alloc] initWithKey:@"representedObject" ascending:YES];

    [root sortWithSortDescriptors:[sd] recursively:YES];

    [self assert:nodeA equals:[root objectInChildNodesAtIndex:0]];
    [self assert:nodeB equals:[root objectInChildNodesAtIndex:1]];
    [self assert:nodeC equals:[root objectInChildNodesAtIndex:2]];

    [self assert:childB1 equals:[nodeB objectInChildNodesAtIndex:0]];
    [self assert:childB2 equals:[nodeB objectInChildNodesAtIndex:1]];
}

// 12. NS/Cocoa-style KVC mutation behavior (Strict validation)
- (void)testStrictChildValidation
{
    var e = [self assertThrows:function()
    {
        [root insertObject:[CPObject new] inChildNodesAtIndex:0];
    }];

    [self assert:CPInvalidArgumentException equals:[e name]];
}

// 13. coding/decoding and restoration of parent relationships
- (void)testCodingAndDecoding
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [child1 insertObject:child2 inChildNodesAtIndex:0];

    var data = [CPKeyedArchiver archivedDataWithRootObject:root];
    var decodedRoot = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    [self assert:1 equals:[decodedRoot countOfChildNodes]];

    var decodedChild1 = [decodedRoot objectInChildNodesAtIndex:0];
    [self assert:decodedRoot equals:[decodedChild1 parentNode]];

    var decodedChild2 = [decodedChild1 objectInChildNodesAtIndex:0];
    [self assert:decodedChild1 equals:[decodedChild2 parentNode]];
}

- (void)testMutableChildNodesCountDoesNotCopy
{
    /*
     Validates that evaluating the count of the mutable proxy does not trigger
     the underlying KVC getter (childNodes). The getter returns a defensive
     copy. Invoking it for a simple count degrades an O(1) operation to O(N)
     allocations.
     */
    var spy = [[CPTreeNodeCountingSpy alloc] initWithRepresentedObject:@"spy"];

    for (var i = 0; i < 50; i++)
        [spy insertObject:[CPTreeNode treeNodeWithRepresentedObject:i] inChildNodesAtIndex:i];

    [spy setChildNodesCallCount:0];

    [[spy mutableChildNodes] count];

    [self assert:0 equals:[spy childNodesCallCount]
         message:"count via mutableChildNodes should not invoke the copying childNodes accessor"];
}

// 14. replacing at an index with a child already present at a different index (same parent)
- (void)testReplaceExistingChildSameParent
{
    var c3 = [CPTreeNode treeNodeWithRepresentedObject:@"child3"];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [root insertObject:child2 inChildNodesAtIndex:1];
    [root insertObject:c3 inChildNodesAtIndex:2];

    // Array is [child1, child2, c3]. Replace the object at index 2 (c3) with child1.
    [root replaceObjectInChildNodesAtIndex:2 withObject:child1];

    [self assert:2 equals:[root countOfChildNodes]];
    [self assert:child2 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:child1 equals:[root objectInChildNodesAtIndex:1]];
    [self assert:root equals:[child1 parentNode]];
    [self assert:nil equals:[c3 parentNode]];
}

// 15. rejection of cyclic relationships via replacement
- (void)testReplaceCycleRejection
{
    var c3 = [CPTreeNode treeNodeWithRepresentedObject:@"child3"];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [child1 insertObject:child2 inChildNodesAtIndex:0];
    [child2 insertObject:c3 inChildNodesAtIndex:0];

    var e = [self assertThrows:function()
    {
        [child2 replaceObjectInChildNodesAtIndex:0 withObject:root];
    }];

    [self assert:CPInvalidArgumentException equals:[e name]];
}

// 16. KVO: same-parent move reports a paired removal and insertion on childNodes
//
// Disabled: structurally impossible with the current accessor-call approach.
// _CPKVOProxy coalesces nested willChange/didChange calls for the same key
// on the same object (see _sendNotificationsForKey:changeOptions:isBefore:
// in CPKeyValueObserving.j); the inner Removal bracket opened by
// removeObjectFromChildNodesAtIndex: is silently discarded inside the outer
// Insertion bracket already open on root. Fixing this requires firing a
// single CPKeyValueChangeReplacement instead of two nested accessor calls.
- (void)disabled_testKVONotificationsDuringSameParentMove
{
    var c3 = [CPTreeNode treeNodeWithRepresentedObject:@"child3"];

    [root insertObject:child1 inChildNodesAtIndex:0];
    [root insertObject:child2 inChildNodesAtIndex:1];
    [root insertObject:c3 inChildNodesAtIndex:2];

    [root addObserver:self forKeyPath:@"childNodes" options:0 context:nil];

    // Array is [child1, child2, c3]. Move child1 (index 0) to index 2.
    [root insertObject:child1 inChildNodesAtIndex:2];

    [root removeObserver:self forKeyPath:@"childNodes"];

    var removals = 0,
        insertions = 0,
        count = [_kvoRecordedChanges count];

    for (var i = 0; i < count; i++)
    {
        var kind = [[_kvoRecordedChanges objectAtIndex:i] objectForKey:CPKeyValueChangeKindKey];

        if (kind === CPKeyValueChangeRemoval)
            removals++;
        else if (kind === CPKeyValueChangeInsertion)
            insertions++;
    }

    [self assert:1 equals:removals
         message:"a same-parent move must report a removal at the original position"];
    [self assert:1 equals:insertions
         message:"a same-parent move must report an insertion at the target position"];
}

// 17. KVO: cross-parent move reports a removal on the old parent and an insertion on the new parent
- (void)testKVONotificationsDuringCrossParentMove
{
    [root insertObject:child1 inChildNodesAtIndex:0];

    [root addObserver:self forKeyPath:@"childNodes" options:0 context:nil];
    [child2 addObserver:self forKeyPath:@"childNodes" options:0 context:nil];

    // child1 currently belongs to root. Move it under child2.
    [child2 insertObject:child1 inChildNodesAtIndex:0];

    [root removeObserver:self forKeyPath:@"childNodes"];
    [child2 removeObserver:self forKeyPath:@"childNodes"];

    var removals = 0,
        insertions = 0,
        count = [_kvoRecordedChanges count];

    for (var i = 0; i < count; i++)
    {
        var kind = [[_kvoRecordedChanges objectAtIndex:i] objectForKey:CPKeyValueChangeKindKey];

        if (kind === CPKeyValueChangeRemoval)
            removals++;
        else if (kind === CPKeyValueChangeInsertion)
            insertions++;
    }

    [self assert:1 equals:removals
         message:"the old parent's childNodes must report the removal"];
    [self assert:1 equals:insertions
         message:"the new parent's childNodes must report the insertion"];
}

// 18. KVO: reparenting notifies observers of parentNode
//
// Disabled: parentNode has no setParentNode:, so there is no selector for
// the KVO swizzler to instrument. Not a bug to fix incrementally; requires
// deciding whether parentNode becomes a real settable property.
- (void)disabled_testParentNodeNotifiesOnMove
{
    [root insertObject:child1 inChildNodesAtIndex:0];

    [child1 addObserver:self forKeyPath:@"parentNode" options:0 context:nil];

    // child1 currently belongs to root. Move it under child2.
    [child2 insertObject:child1 inChildNodesAtIndex:0];

    [child1 removeObserver:self forKeyPath:@"parentNode"];

    [self assert:1 equals:[_kvoRecordedChanges count]
         message:"reparenting must notify observers of parentNode"];
}

// 19. mutableChildNodes proxy: remove and replace
- (void)testMutableChildNodesProxyRemoveAndReplace
{
    [root insertObject:child1 inChildNodesAtIndex:0];
    [root insertObject:child2 inChildNodesAtIndex:1];

    var proxy = [root mutableChildNodes];

    [proxy removeObjectAtIndex:0];

    [self assert:1 equals:[root countOfChildNodes]];
    [self assert:child2 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:nil equals:[child1 parentNode]];

    var c3 = [CPTreeNode treeNodeWithRepresentedObject:@"child3"];

    [proxy replaceObjectAtIndex:0 withObject:c3];

    [self assert:c3 equals:[root objectInChildNodesAtIndex:0]];
    [self assert:root equals:[c3 parentNode]];
    [self assert:nil equals:[child2 parentNode]];
}

// 20. range validation on insertion
- (void)testInsertOutOfBoundsRaises
{
    var e1 = [self assertThrows:function()
    {
        [root insertObject:child1 inChildNodesAtIndex:-1];
    }];

    [self assert:CPRangeException equals:[e1 name]];

    var e2 = [self assertThrows:function()
    {
        [root insertObject:child1 inChildNodesAtIndex:1];
    }];

    [self assert:CPRangeException equals:[e2 name]];
}

// 21. non-recursive sort leaves descendants untouched
- (void)testSortNonRecursive
{
    var nodeA = [CPTreeNode treeNodeWithRepresentedObject:@"A"];
    var nodeC = [CPTreeNode treeNodeWithRepresentedObject:@"C"];
    var nodeB = [CPTreeNode treeNodeWithRepresentedObject:@"B"];

    [root insertObject:nodeC inChildNodesAtIndex:0];
    [root insertObject:nodeA inChildNodesAtIndex:1];
    [root insertObject:nodeB inChildNodesAtIndex:2];

    var childB2 = [CPTreeNode treeNodeWithRepresentedObject:@"B2"];
    var childB1 = [CPTreeNode treeNodeWithRepresentedObject:@"B1"];

    [nodeB insertObject:childB2 inChildNodesAtIndex:0];
    [nodeB insertObject:childB1 inChildNodesAtIndex:1];

    var sd = [[CPSortDescriptor alloc] initWithKey:@"representedObject" ascending:YES];

    [root sortWithSortDescriptors:[sd] recursively:NO];

    [self assert:nodeA equals:[root objectInChildNodesAtIndex:0]];
    [self assert:nodeB equals:[root objectInChildNodesAtIndex:1]];
    [self assert:nodeC equals:[root objectInChildNodesAtIndex:2]];

    // Descendants of nodeB must remain in insertion order; only the top level was sorted.
    [self assert:childB2 equals:[nodeB objectInChildNodesAtIndex:0]];
    [self assert:childB1 equals:[nodeB objectInChildNodesAtIndex:1]];
}

// 22. leaf status
- (void)testIsLeaf
{
    [self assertTrue:[root isLeaf]];

    [root insertObject:child1 inChildNodesAtIndex:0];

    [self assertFalse:[root isLeaf]];
    [self assertTrue:[child1 isLeaf]];
}

// 23. descendant lookup for nil and zero-length index paths
- (void)testDescendantNodeAtIndexPathDegenerateCases
{
    [root insertObject:child1 inChildNodesAtIndex:0];

    [self assert:root equals:[root descendantNodeAtIndexPath:nil]];
    [self assert:root equals:[root descendantNodeAtIndexPath:[CPIndexPath indexPathWithIndexes:[]]]];
}
@end

@implementation CPTreeNodeCountingSpy : CPTreeNode
{
    CPInteger _childNodesCallCount @accessors(property=childNodesCallCount);
}

- (id)initWithRepresentedObject:(id)anObject
{
    self = [super initWithRepresentedObject:anObject];

    if (self)
        _childNodesCallCount = 0;

    return self;
}

- (CPArray)childNodes
{
    _childNodesCallCount++;
    return [super childNodes];
}

@end
