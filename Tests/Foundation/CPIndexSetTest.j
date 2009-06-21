@import <Foundation/CPIndexSet.j>

@implementation CPIndexSetTest : OJTestCase
{
    CPIndexSet _set;
}

- (void)setUp
{
    _set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 10)];
}

- (void)tearDown
{
    _set = nil;
}

- (void)testIndexSet:(CPIndexSet)set containsRange:(CPRange)range
{
    [self assertFalse:[set containsIndex:range.location -1]];
    
    for (var i=range.location, max=CPMaxRange(range); i<max; i++)
    {
        [self assertTrue:[set containsIndex:i]];
    }
    
    [self assertFalse:[set containsIndex:i]];
}

- (void)testIndexSet
{
    [self assertNotNull:[CPIndexSet indexSet]];
    [self assert:[[CPIndexSet indexSet] class] equals:[CPIndexSet class]];
}

- (void)testIndexSetWithIndex
{
    [self assertTrue:[[CPIndexSet indexSetWithIndex:1] containsIndex:1]];
    [self assertTrue:[[CPIndexSet indexSetWithIndex:0] containsIndex:0]];
    [self assertFalse:[[CPIndexSet indexSetWithIndex:0] containsIndex:1]];
}

- (void)testIndexSetWithIndexesInRange
{
    var set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 7)];
    [self assertNotNull:set];
    [self testIndexSet:set containsRange:CPMakeRange(0, 7)];
}

- (void)testInit
{
    var set = [[CPIndexSet alloc] init];
    [self assertNotNull:set];
    [self assert:[set count] equals:0];
}

- (void)testInitWithIndex
{
    var set = [[CPIndexSet alloc] initWithIndex:234];
    [self assertNotNull:set];
    [self assertTrue:[set containsIndex:234]];
    [self assertFalse:[set containsIndex:5432]];
}

- (void)testInitWithIndexesInRange
{
    var set = [[CPIndexSet alloc] initWithIndexesInRange:CPMakeRange(0, 7)];
    [self assertNotNull:set];
    [self testIndexSet:set containsRange:CPMakeRange(0, 7)];
    [self assertTrue:[set containsIndexesInRange:CPMakeRange(0, 7)]];
    [self assertTrue:[set containsIndexesInRange:CPMakeRange(1, 6)]];
    [self assertFalse:[set containsIndexesInRange:CPMakeRange(2, 6)]];
}

- (void)testInitWithIndexSet
{
    var set1 = [[CPIndexSet alloc] initWithIndexesInRange:CPMakeRange(0, 7)];
    var set = [[CPIndexSet alloc] initWithIndexSet:set1];
    [self assertNotNull:set];
    [self testIndexSet:set containsRange:CPMakeRange(0, 7)];
}

- (void)testIsEqualToIndexSet
{
    var set1 = [CPIndexSet indexSetWithIndex:7];
    var set2 = [CPIndexSet indexSetWithIndex:7];
    var set3 = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(7, 2)];
    
    [self assertTrue:[set1 isEqualToIndexSet:set2]];
    [self assertTrue:[set1 isEqualToIndexSet:set1]];
    [self assertFalse:[set1 isEqualToIndexSet:set3]];
}

- (void)testCount
{
    var set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(7, 2)];
    var set2 = [CPIndexSet indexSetWithIndex:7];

    [self assert:[set2 count] equals:1];
    [self assert:[set count] equals:2];
}

- (void)testFirstIndex
{
    [self assert:[_set firstIndex] equals:10];
    [self assert:[[CPIndexSet indexSet] firstIndex] equals:CPNotFound];
}

- (void)testLastIndex
{
    [self assert:[_set lastIndex] equals:19];
    [self assert:[[CPIndexSet indexSet] lastIndex] equals:CPNotFound];
}

- (void)testAddSpeed
{
    var startTime = [CPDate date];
    
    for (var i = 0; i < 1000; i++)
    {
       [_set addIndex:ROUND(RAND()*100000)];
    }

    print([startTime timeIntervalSinceNow]);
    //[self assertTrue: ABS([startTime timeIntervalSinceNow]) < 2];  
}

- (void)testIndexGreaterThanIndex
{
    [self assert:[_set indexGreaterThanIndex:5] equals:10];
    [self assert:[_set indexGreaterThanIndex:11] equals:12];
    [self assert:[_set indexGreaterThanIndex:19] equals:CPNotFound];
}

- (void)testIndexLessThanIndex
{
    [self assert:[_set indexLessThanIndex:5] equals:CPNotFound];
    [self assert:[_set indexLessThanIndex:11] equals:10];
    [self assert:[_set indexLessThanIndex:20] equals:19];
    [self assert:[_set indexLessThanIndex:222] equals:19];
}

- (void)testIndexGreaterThanOrEqualToIndex
{
    [self assert:[_set indexGreaterThanOrEqualToIndex:5] equals:10];
    [self assert:[_set indexGreaterThanOrEqualToIndex:10] equals:10];
    [self assert:[_set indexGreaterThanOrEqualToIndex:19] equals:19];
    [self assert:[_set indexGreaterThanOrEqualToIndex:20] equals:CPNotFound];
}

- (void)testIndexLessThanOrEqualToIndex
{
    [self assert:[_set indexLessThanOrEqualToIndex:5] equals:CPNotFound];
    [self assert:[_set indexLessThanOrEqualToIndex:10] equals:10];
    [self assert:[_set indexLessThanOrEqualToIndex:19] equals:19];
    [self assert:[_set indexLessThanOrEqualToIndex:20] equals:19];
}

- (void)testContainsIndex
{
    [self assertTrue:[_set containsIndex:10]];
    [self assertTrue:[_set containsIndex:11]];
    [self assertTrue:[_set containsIndex:19]];
    [self assertFalse:[_set containsIndex:9]];
    [self assertFalse:[_set containsIndex:20]];
}

- (void)testContainsIndexesInRange
{
    [self assertTrue:[_set containsIndexesInRange:CPMakeRange(10, 10)]];
    [self assertFalse:[_set containsIndexesInRange:CPMakeRange(10, 0)]];
    [self assertTrue:[_set containsIndexesInRange:CPMakeRange(10, 1)]];
    [self assertTrue:[_set containsIndexesInRange:CPMakeRange(14, 2)]];
    [self assertFalse:[_set containsIndexesInRange:CPMakeRange(10, 11)]];
    [self assertFalse:[_set containsIndexesInRange:CPMakeRange(9, 2)]];
    [self assertFalse:[_set containsIndexesInRange:CPMakeRange(19, 2)]];
}

- (void)testContainsIndexes
{
    [self assertTrue:[_set containsIndexes:_set]];
    [self assertTrue:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 1)]]];
    [self assertTrue:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 10)]]];
    [self assertTrue:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(19, 1)]]];
    [self assertFalse:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 11)]]];
    [self assertFalse:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(9, 2)]]];
}

@end

