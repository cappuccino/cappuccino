@import <Foundation/CPCache.j>


@implementation CPCacheItemTest : OJTestCase

- (void)testCacheItemWithObjectCostPosition
{
    var cacheItem = [_CPCacheItem cacheItemWithObject:"Hello Cappuccino!" cost:50 position:1];
    [self assert:[cacheItem object] equals:"Hello Cappuccino!"];
    [self assert:[cacheItem cost] equals:50];
    [self assert:[cacheItem position] equals:1];
}

@end
