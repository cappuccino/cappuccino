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

@end
