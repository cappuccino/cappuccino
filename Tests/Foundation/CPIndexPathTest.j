
@import <Foundation/CPIndexPath.j>


@implementation CPIndexPathTest : OJTestCase
{
    CPIndexPath indexPath;
}

- (void)setUp
{
    indexPath = [[CPIndexPath alloc] initWithIndexes:[1,5,3,7,3] length:3];
}

- (void)testIndexPathConstructed
{
    [self assertNotNull:indexPath];
}

- (void)testLength
{
    [self assert:3 equals:[indexPath length]];
}

- (void)testIndexAtPosition
{
    [self assert:5 equals:[indexPath indexAtPosition:1]];
}

- (void)testIndexPathByAddingIndex
{
    [self assert:[CPIndexPath indexPathWithIndexes:[[indexPath indexes] arrayByAddingObject:3]]
          equals:[indexPath indexPathByAddingIndex:3]];
}

- (void)testIndexPathByRemovingLastIndex
{
    var ip = [indexPath indexes];
    [ip removeLastObject];

    [self assert:[CPIndexPath indexPathWithIndexes:ip]
          equals:[indexPath indexPathByRemovingLastIndex]];
}

- (void)testCompareThrowsOnNil
{
    [self assertThrows:function() { [indexPath compare:nil] }];
}

- (void)testCompare
{
    var comparisonIndexPath = [CPIndexPath indexPathWithIndexes:[CPArray arrayWithObjects:1,5,2]];

    [self assert:CPOrderedDescending equals:[indexPath compare:comparisonIndexPath]];

    comparisonIndexPath = [CPIndexPath indexPathWithIndexes:[CPArray arrayWithObjects:1,4]];
    [self assert:CPOrderedDescending equals:[indexPath compare:comparisonIndexPath]];

    comparisonIndexPath = [CPIndexPath indexPathWithIndexes:[CPArray arrayWithObjects:1,5,3]];
    [self assert:CPOrderedSame equals:[indexPath compare:comparisonIndexPath]];

    comparisonIndexPath = [CPIndexPath indexPathWithIndexes:[CPArray arrayWithObjects:1,5,4]];
    [self assert:CPOrderedAscending equals:[indexPath compare:comparisonIndexPath]];

    comparisonIndexPath = [CPIndexPath indexPathWithIndexes:[CPArray arrayWithObjects:1,6]];
    [self assert:CPOrderedAscending equals:[indexPath compare:comparisonIndexPath]];
}

@end
