// Just doing @import <AppKit/CPCollectionView.j> failed on CPWindow not being defined somewhere.
@import <AppKit/AppKit.j>

@implementation CPCollectionViewTest : OJTestCase
{
    CPCollectionView _collectionView;
}

- (void)setUp
{
    _collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
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
    [self assert:reloadContentCount+1 equals:[collectionView reloadContentCallCount] message:@"first call to setContent should have called reloadContent once"];

    [content removeObjectAtIndex:0];
    [self assertTrue:[collectionView content] === content message:@"collection view content should be as assigned"];

    // make sure we call reloadContent even when the content hasn't changed for key-value binding compatibility
    reloadContentCount = [collectionView reloadContentCallCount];
    [collectionView setContent:content];
    [self assert:[collectionView reloadContentCallCount] equals:reloadContentCount+1 message:@"subsequent calls to setContent should have called reloadContent once"];
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
