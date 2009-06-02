// Just doing @import <AppKit/CPCollectionView.j> failed on CPWindow not being defined somewhere.
@import <AppKit/AppKit.j>

@implementation CPCollectionViewTest : OJTestCase

- (void)testItemPrototypeActuallyReturnsTheItemPrototype
{
    var propertiesCollectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()],
        itemPrototype = [[CPCollectionViewItem alloc] init];

    [propertiesCollectionView setItemPrototype:itemPrototype];
    
    [self assert:[CPCollectionViewItem class] equals:[[propertiesCollectionView itemPrototype] class]];
}

@end
