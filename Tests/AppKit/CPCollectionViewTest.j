// Just doing @import <AppKit/CPCollectionView.j> failed on CPWindow not being defined somewhere.
@import <AppKit/AppKit.j>

@implementation CPCollectionViewTest : OJTestCase
{
    CPCollectionView _collectionView;
    id _globalResults;
}

- (void)setUp
{
    _collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
    _globalResults = nil;
}

// delegate method
- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
    _globalResults = "selection changed: " + [[aCollectionView selectionIndexes] count];
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
    var collectionView = [[_CPCollectionViewWithHooks alloc] initWithFrame:CGRectMakeZero()],
        content = [1, 2, 3],
        reloadContentCount;

    reloadContentCount = [collectionView reloadContentCallCount];
    [collectionView setContent:content];
    [self assert:reloadContentCount + 1 equals:[collectionView reloadContentCallCount] message:@"first call to setContent should have called reloadContent once"];

    [content removeObjectAtIndex:0];
    [self assertTrue:[collectionView content] === content message:@"collection view content should be as assigned"];

    // make sure we call reloadContent even when the content hasn't changed for key-value binding compatibility
    reloadContentCount = [collectionView reloadContentCallCount];
    [collectionView setContent:content];
    [self assert:[collectionView reloadContentCallCount] equals:reloadContentCount + 1 message:@"subsequent calls to setContent should have called reloadContent once"];
}

- (void)testCallCollectionViewDidChangeSelectionDelegateMethod
{
    var content1 = ["a", "b", "c"],
        content2 = ["d", "e", "f"];

    [_collectionView setSelectable:YES];
    [_collectionView setDelegate:self];
    [_collectionView setContent:content1];
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    // the first time the delegate does get called
    [self assert:"selection changed: 1" equals:_globalResults];
    _globalResults = nil;

    // setContent: by itself should not affect the selection.
    [_collectionView setContent:content1];
    [self assert:nil equals:_globalResults];
    // Manually clear the selection.
    [_collectionView setSelectionIndexes:[CPIndexSet indexSet]];
    _globalResults = nil;


    // now lets change the contents
    [_collectionView setContent:content2];
    // we set the selection to 0 again, but on the NEW content
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:"selection changed: 1" equals:_globalResults];

    _globalResults = nil;
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:"selection changed: 1" equals:_globalResults];
}

- (void)testSelectionIndexes
{
    [_collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[_collectionView selectionIndexes]];
    [_collectionView setSelectionIndexes:nil];
    [self assert:[CPIndexSet indexSet] equals:[_collectionView selectionIndexes]];
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
