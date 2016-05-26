// Just doing @import <AppKit/CPCollectionView.j> failed on CPWindow not being defined somewhere.
@import <AppKit/AppKit.j>

@implementation CPCollectionViewTest : OJTestCase
{
    CPCollectionView _collectionView;
    id _globalResults;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
    var itemPrototype = [[CPCollectionViewItem alloc] init];
    [_collectionView setItemPrototype:itemPrototype];

    _globalResults = nil;
}

- (void)testItemPrototypeActuallyReturnsTheItemPrototype
{
    var itemPrototype = [[CPCollectionViewItem alloc] init];
    [_collectionView setItemPrototype:itemPrototype];

    [self assert:itemPrototype same:[_collectionView itemPrototype]];
}

- (void)testIsSelectableGetter
{
    var collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];

    [collectionView setSelectable:YES];
    [self assertTrue:[collectionView isSelectable]];

    [collectionView setSelectable:NO];
    [self assertFalse:[collectionView isSelectable]];
}

- (void)testSetContent
{
    var content = [1, 2, 3];

    [_collectionView setContent:content];
    [self assert:content equals:[_collectionView content] message:@"collection view content should be equal to the content assigned"];
}

- (void)testSetContentStressTest
{
    [self assertNoThrow:function()
    {
        [_collectionView setContent:@["A","B"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@["A"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@["A", "C"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@["C","D"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@["B","E","C"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@["C","E"]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
        [_collectionView setContent:@[]];
        [self assert:[[_collectionView items] valueForKey:@"representedObject"] equals:[_collectionView content]];
    }];
}

- (void)testCollectionViewSetContentPerfTest
{
    var c = 1000,
        content = @[];

    while (c--)
        [content addObject:(@"Item " + c)];

    [_collectionView setContent:content];

    [content insertObject:"NEW ITEM" atIndex:0];

    var d = new Date();
    [_collectionView setContent:[content copy]];

    CPLog.warn("CPCollectionView : Inserted 1 item to 1000 items in " + (new Date() - d) + " ms");
}

- (void)testSelectionIndexes
{
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[_collectionView selectionIndexes]];
    [_collectionView setSelectionIndexes:nil];
    [self assert:[CPIndexSet indexSet] equals:[_collectionView selectionIndexes]];
}

- (void)_testCollectionViewItemIsSelected
{
    [_collectionView setContent:[1, 2, 3]];

    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assertTrue:[[_collectionView itemAtIndex:1] isSelected]];

    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assertTrue:[[_collectionView itemAtIndex:0] isSelected]];
    // The item is correctly deselected when the selection indexes changes.
    [self assertFalse:[[_collectionView itemAtIndex:1] isSelected]];
}

- (void)testBindingSupport
{
    var content = [1,2,3];
    var ac = [[CPArrayController alloc] initWithContent:content];
    [ac setSelectsInsertedObjects:YES];
    [_collectionView bind:CPContentBinding toObject:ac withKeyPath:@"arrangedObjects" options:nil];
    [_collectionView bind:CPSelectionIndexesBinding toObject:ac withKeyPath:@"selectionIndexes" options:nil];

    [self assert:[1,2,3] equals:[_collectionView content]];

    [ac setContent:[6,7]];
    [self assert:[6,7] equals:[_collectionView content]];

    [ac setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:[CPIndexSet indexSetWithIndex:1] equals:[_collectionView selectionIndexes]];

    [ac insertObject:4 atArrangedObjectIndex:2];
    [self assert:[CPIndexSet indexSetWithIndex:2] equals:[_collectionView selectionIndexes]];

    // collection view selection is reflected on the array controller selection
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[ac selectionIndexes]];

    // collection view content is reflected on the array controller content
    //[_collectionView setContent:[8,9]];
    //[self assert:[8,9] equals:[ac content]];
}

- (void)testSetContentAndSelectionIndexes
{
    // Changing the content does not automatically clear the selection indexes. The previous
    // selection indexes are preserved, even if now invalid or out of range. This is what
    // Cocoa does and necessary to prevent a new empty selection from overwriting
    // CPArrayController's selectsInsertedObjects selections.

    [_collectionView setContent:[1, 2, 3]];
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [_collectionView setContent:[3, 1, 2]];
    [self assert:[CPIndexSet indexSetWithIndex:1] equals:[_collectionView selectionIndexes]];
}

@end

@implementation _CPCollectionViewWithHooks : CPCollectionView
{
    CPInteger _reloadContentCallCount @accessors(property=reloadContentCallCount);
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _reloadContentCallCount = 0;
    }

    return self;
}

- (void)reloadContent
{
  [super reloadContent];
  _reloadContentCallCount++;
}

@end
