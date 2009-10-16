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
    
    [self assert:[CPCollectionViewItem class] equals:[[_collectionView itemPrototype] class]];
}

- (void)testIsSelectableActuallyReturnsSelectableStatus
{
    [_collectionView setSelectable:YES];
    [self assertTrue:[_collectionView isSelectable]];
    
    [_collectionView setSelectable:NO];
    [self assertFalse:[_collectionView isSelectable]];
}

@end
