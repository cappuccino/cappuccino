@import <Foundation/CPIndexSet.j>

function descriptionWithoutEntity(aString)
{
    var descriptionWithEntity = [aString description];
    return descriptionWithEntity.substr(descriptionWithEntity.indexOf('>') + 1);
}

@implementation CPIndexSetTest : OJTestCase
{
    CPIndexSet _set;
}

- (void)setUp
{
    _set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 10)];
}

- (void)testAddIndexes
{
    var indexSet = [CPIndexSet indexSet];

    // Test no indexes
    [self assert:descriptionWithoutEntity(indexSet) equals:@"(no indexes)"];

    // Test adding initial range
    [indexSet addIndexesInRange:CPMakeRange(30, 10)];

    [self assert:@"[number of indexes: 10 (in 1 range), indexes: (30-39)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range after existing ranges.
    [indexSet addIndexesInRange:CPMakeRange(50, 10)];

    [self assert:@"[number of indexes: 20 (in 2 ranges), indexes: (30-39 50-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range before existing ranges.
    [indexSet addIndexesInRange:CPMakeRange(10, 10)];

    [self assert:@"[number of indexes: 30 (in 3 ranges), indexes: (10-19 30-39 50-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range inbetween existing ranges.
    [indexSet addIndexesInRange:CPMakeRange(45, 2)];

    [self assert:@"[number of indexes: 32 (in 4 ranges), indexes: (10-19 30-39 45-46 50-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding single index inbetween existing ranges.
    [indexSet addIndexesInRange:CPMakeRange(23, 1)];

    [self assert:@"[number of indexes: 33 (in 5 ranges), indexes: (10-19 23 30-39 45-46 50-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range inbetween existing ranges that forces a combination
    [indexSet addIndexesInRange:CPMakeRange(47, 3)];

    [self assert:@"[number of indexes: 36 (in 4 ranges), indexes: (10-19 23 30-39 45-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range across ranges forcing a combination
    [indexSet addIndexesInRange:CPMakeRange(35, 15)];

    [self assert:@"[number of indexes: 41 (in 3 ranges), indexes: (10-19 23 30-59)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding range across two empty slots forcing a combination
    [indexSet addIndexesInRange:CPMakeRange(5, 70)];

    [self assert:@"[number of indexes: 70 (in 1 range), indexes: (5-74)]" equals:descriptionWithoutEntity(indexSet)];

    // Test adding to extend the beginning of the first range
    [indexSet addIndex:4];

    [self assert:@"[number of indexes: 71 (in 1 range), indexes: (4-74)]" equals:descriptionWithoutEntity(indexSet)];

    [self assertThrows:function() { [indexSet addIndex:CPNotFound]; }];
}

- (void)testRemoveIndexes
{
    var indexSet = [CPIndexSet indexSet];

    // Test no indexes
    [self assert:descriptionWithoutEntity(indexSet) equals:@"(no indexes)"];

    // Test adding initial range
    [indexSet addIndexesInRange:CPMakeRange(0, 70)];

    [self assert:@"[number of indexes: 70 (in 1 range), indexes: (0-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is subset of existing range, causing a split.
    [indexSet removeIndexesInRange:CPMakeRange(30, 10)];

    [self assert:@"[number of indexes: 60 (in 2 ranges), indexes: (0-29 40-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is subset of existing range, causing a split.
    [indexSet removeIndexesInRange:CPMakeRange(50, 5)];

    [self assert:@"[number of indexes: 55 (in 3 ranges), indexes: (0-29 40-49 55-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove index that is subset of existing range, causing a split.
    [indexSet removeIndex:57];

    [self assert:@"[number of indexes: 54 (in 4 ranges), indexes: (0-29 40-49 55-56 58-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is an exactly represented in the set.
    [indexSet removeIndexesInRange:CPMakeRange(40, 10)];

    [self assert:@"[number of indexes: 44 (in 3 ranges), indexes: (0-29 55-56 58-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that isn't in the set.
    [indexSet removeIndexesInRange:CPMakeRange(35, 3)];

    [self assert:@"[number of indexes: 44 (in 3 ranges), indexes: (0-29 55-56 58-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is partially in a left range.
    [indexSet removeIndexesInRange:CPMakeRange(25, 7)];

    [self assert:@"[number of indexes: 39 (in 3 ranges), indexes: (0-24 55-56 58-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is partially in a left range.
    [indexSet removeIndexesInRange:CPMakeRange(57, 3)];

    [self assert:@"[number of indexes: 37 (in 3 ranges), indexes: (0-24 55-56 60-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Test remove range that is partially in a left and right range.
    [indexSet removeIndexesInRange:CPMakeRange(20, 36)];

    [self assert:@"[number of indexes: 31 (in 3 ranges), indexes: (0-19 56 60-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Remove single index that represents an entire range.
    [indexSet removeIndex:56];

    [self assert:@"[number of indexes: 30 (in 2 ranges), indexes: (0-19 60-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Remove index set that is subset of existing range, causing a split.
    [indexSet removeIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(5, 10)]];

    [self assert:@"[number of indexes: 20 (in 3 ranges), indexes: (0-4 15-19 60-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Remove indexes that are partially in 2 ranges and contains intermediate range.
    [indexSet removeIndexesInRange:CPMakeRange(2, 62)];

    [self assert:@"[number of indexes: 8 (in 2 ranges), indexes: (0-1 64-69)]" equals:descriptionWithoutEntity(indexSet)];

    // Remove indexes that fit exactly in 2 ranges.
    [indexSet removeIndexesInRange:CPMakeRange(0, 70)];

    [self assert:@"(no indexes)" equals:descriptionWithoutEntity(indexSet)];

    indexSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 30)];

    // Remove indexes from left hand of single range
    [indexSet removeIndexesInRange:CPMakeRange(0, 29)];

    [self assert:@"[number of indexes: 1 (in 1 range), indexes: (29)]" equals:descriptionWithoutEntity(indexSet)];

    indexSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 30)];

    // Remove indexes from right hand of single range
    [indexSet removeIndexesInRange:CPMakeRange(1, 29)];

    [self assert:@"[number of indexes: 1 (in 1 range), indexes: (0)]" equals:descriptionWithoutEntity(indexSet)];
}

- (void)testGetIndexes
{
    var indexSet = [CPIndexSet indexSet];

    // Test no indexes
    [self assert:descriptionWithoutEntity(indexSet) equals:@"(no indexes)"];

    // Test adding initial range
    [indexSet addIndexesInRange:CPMakeRange(0, 10)];

    [indexSet addIndexesInRange:CPMakeRange(15, 1)];

    [indexSet addIndexesInRange:CPMakeRange(20, 10)];

    [indexSet addIndexesInRange:CPMakeRange(50, 10)];

    [self assert:@"[number of indexes: 31 (in 4 ranges), indexes: (0-9 15 20-29 50-59)]" equals:descriptionWithoutEntity(indexSet)];

    var array = [];

    [indexSet getIndexes:array maxCount:1000 inIndexRange:nil];

    [self assert:[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] equals:array];
}

- (void)testIndexSet:(CPIndexSet)set containsRange:(CPRange)range
{
    [self assertFalse:[set containsIndex:range.location -1]];

    for (var i = range.location, max = CPMaxRange(range); i < max; i++)
        [self assertTrue:[set containsIndex:i]];

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
    [self assertThrows:function() { [CPIndexSet indexSetWithIndex:NaN] }];
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
    var set1 = [[CPIndexSet alloc] initWithIndexesInRange:CPMakeRange(0, 7)],
        set = [[CPIndexSet alloc] initWithIndexSet:set1];
    [self assertNotNull:set];
    [self testIndexSet:set containsRange:CPMakeRange(0, 7)];
}

- (void)testIsEqualToIndexSet
{
    var set1 = [CPIndexSet indexSetWithIndex:7],
        set2 = [CPIndexSet indexSetWithIndex:7],
        set3 = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(7, 2)];

    [self assertFalse:[set1 isEqualToIndexSet:nil]];
    [self assertTrue:[set1 isEqualToIndexSet:set2]];
    [self assertTrue:[set1 isEqualToIndexSet:set1]];
    [self assertFalse:[set1 isEqualToIndexSet:set3]];
}

- (void)testIsEqual
{
    var set1 = [CPIndexSet indexSetWithIndex:7],
        set2 = [CPIndexSet indexSetWithIndex:7],
        set3 = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(7, 2)];

    [self assertFalse:[set1 isEqual:nil]];
    [self assertFalse:[set1 isEqual:7]];
    [self assertTrue:[set1 isEqual:set2]];
    [self assertTrue:[set1 isEqual:set1]];
    [self assertFalse:[set1 isEqual:set3]];
}

- (void)testCount
{
    var set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(7, 2)],
        set2 = [CPIndexSet indexSetWithIndex:7];

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

    var singleIndexSet = [CPIndexSet indexSetWithIndex:3];
    [self assert:3 equals:[singleIndexSet lastIndex]];
}
/*
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
*/
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

- (void)testShiftIndexesStartingAtIndex
{
    var startRange = CPMakeRange(1, 5),
        shiftRange = CPMakeRange(2, 5);
    _set = [CPIndexSet indexSetWithIndexesInRange:startRange];

    // positive delta for downward shift
    [_set shiftIndexesStartingAtIndex:1 by:1];
    [self assertTrue:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:shiftRange]]];

    // negative delta for downward shift
    [_set shiftIndexesStartingAtIndex:1 by:-1];
    [self assertTrue:[_set containsIndexes:[CPIndexSet indexSetWithIndexesInRange:startRange]]];

    // test for fix to issue #746 (last item is mistakenly shifted)
    _set = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 1)];
    [self assertTrue:[_set lastIndex] === 0];

    [_set shiftIndexesStartingAtIndex:[_set lastIndex] + 1 by:1];
    [self assertTrue:[_set lastIndex] === 0];

    // make sure shifting past the lower bound works
    _set = [CPIndexSet indexSetWithIndex:0];
    [_set shiftIndexesStartingAtIndex:0 by:-1];
    [self assert:[_set lastIndex] equals:CPNotFound];
    [self assert:[_set count] equals:0];
}

- (void)testIsEqual
{
    var differentSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 11)],
        equalSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 10)];

    [self assertFalse:[_set isEqual:nil]];
    [self assertFalse:[_set isEqual:differentSet]];
    [self assertTrue:[_set isEqual:equalSet]];
    [self assertTrue:[_set isEqual:_set]];
}

- (void)testIsEqualToIndexSet
{
    var differentSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 11)],
        equalSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 10)];

    [self assertFalse:[_set isEqualToIndexSet:differentSet]];
    [self assertTrue:[_set isEqualToIndexSet:equalSet]];
    [self assertTrue:[_set isEqualToIndexSet:_set]];
}

- (void)testEnumerateIndexesUsingBlock_
{
    var set0 = [CPIndexSet indexSet],
        set1 = [CPMutableIndexSet indexSet],
        set2 = [CPMutableIndexSet indexSet];

    [set1 addIndexesInRange:CPMakeRange(3, 2)];

    [set2 addIndexesInRange:CPMakeRange(3, 2)];
    [set2 addIndexesInRange:CPMakeRange(0, 1)];

    var visitedIndexes = [],
        aBlock;

    aBlock = function(idx)
    {
        visitedIndexes.push(idx);
    };

    [set0 enumerateIndexesUsingBlock:aBlock];
    [self assert:[] equals:visitedIndexes message:"enumerate empty set"];

    [set1 enumerateIndexesUsingBlock:aBlock];
    [self assert:[3, 4] equals:visitedIndexes message:"enumerate " + [set1 description]];

    visitedIndexes = [];
    [set2 enumerateIndexesUsingBlock:aBlock];
    [self assert:[0, 3, 4] equals:visitedIndexes message:"enumerate " + [set2 description]];
}

- (void)testEnumerateIndexesWithOptions_usingBlock_
{
    var set0 = [CPIndexSet indexSet],
        set1 = [CPMutableIndexSet indexSet],
        set2 = [CPMutableIndexSet indexSet];

    [set1 addIndexesInRange:CPMakeRange(3, 2)];

    [set2 addIndexesInRange:CPMakeRange(3, 2)];
    [set2 addIndexesInRange:CPMakeRange(0, 1)];

    var visitedIndexes = [],
        aBlock;

    aBlock = function(idx)
    {
        visitedIndexes.push(idx);
    };

    [set0 enumerateIndexesWithOptions:CPEnumerationNormal usingBlock:aBlock];
    [self assert:[] equals:visitedIndexes message:"enumerate empty set"];

    [set1 enumerateIndexesWithOptions:CPEnumerationNormal usingBlock:aBlock];
    [self assert:[3, 4] equals:visitedIndexes message:"enumerate " + [set1 description]];

    visitedIndexes = [];
    [set2 enumerateIndexesWithOptions:CPEnumerationNormal usingBlock:aBlock];
    [self assert:[0, 3, 4] equals:visitedIndexes message:"enumerate " + [set2 description]];

    visitedIndexes = [];
    [set0 enumerateIndexesWithOptions:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[] equals:visitedIndexes message:"reverse enumerate empty set"];

    visitedIndexes = [];
    [set1 enumerateIndexesWithOptions:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[4, 3] equals:visitedIndexes message:"reverse enumerate " + [set1 description]];

    visitedIndexes = [];
    [set2 enumerateIndexesWithOptions:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[4, 3, 0] equals:visitedIndexes message:"reverse enumerate " + [set2 description]];
}

- (void)testEnumerateIndexesInRange_options_usingBlock_
{
    var set0 = [CPIndexSet indexSet],
        set1 = [CPMutableIndexSet indexSet],
        set2 = [CPMutableIndexSet indexSet];

    [set1 addIndexesInRange:CPMakeRange(3, 2)];

    [set2 addIndexesInRange:CPMakeRange(3, 2)];
    [set2 addIndexesInRange:CPMakeRange(0, 1)];

    var visitedIndexes = [],
        aBlock;

    aBlock = function(idx)
    {
        visitedIndexes.push(idx);
    };

    visitedIndexes = [];
    [set0 enumerateIndexesInRange:CPMakeRange(0, 4) options:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[] equals:visitedIndexes message:"reverse enumerate in range empty set"];

    visitedIndexes = [];
    [set1 enumerateIndexesInRange:CPMakeRange(0, 5) options:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[4, 3] equals:visitedIndexes message:"reverse enumerate in range " + [set1 description]];

    visitedIndexes = [];
    [set1 enumerateIndexesInRange:CPMakeRange(0, 4) options:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[3] equals:visitedIndexes message:"reverse enumerate in range " + [set1 description]];

    visitedIndexes = [];
    [set2 addIndexesInRange:CPMakeRange(7, 2)];
    [set2 enumerateIndexesInRange:CPMakeRange(2, 4) options:CPEnumerationReverse usingBlock:aBlock];
    [self assert:[4, 3] equals:visitedIndexes message:"reverse enumerate " + [set2 description]];
}

- (void)testEnumerateIndexesAndStop
{
    var set0 = [CPMutableIndexSet indexSet];

    [set0 addIndexesInRange:CPMakeRange(3, 2)];
    [set0 addIndexesInRange:CPMakeRange(0, 1)];

    var visitedIndexes = [],
        aBlock;

    aBlock = function(idx, /* ref */ stop)
    {
        visitedIndexes.push(idx);
        if (visitedIndexes.length >= 2)
            @deref(stop) = YES;
    }

    [set0 enumerateIndexesUsingBlock:aBlock];
    [self assert:[0, 3] equals:visitedIndexes message:"enumeration should stop after 2 results"];
}

- (void)testIndexPassingTest
{
    var set0 = [CPMutableIndexSet indexSet],
        index = [set0 indexPassingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:index === CPNotFound message:"must be equal to CPNotFound, was " + index];

    [set0 addIndexesInRange:CPMakeRange(1, 10)];
    index = [set0 indexPassingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:index === 2 message:"index must be equal to 2"];

    index = [set0 indexPassingTest:function(anIndex)
        {
            return anIndex === 1000;
        }];

    [self assertTrue:index === CPNotFound message:"must be equal to CPNotFound, was " + index];
}

- (void)testIndexesPassingTest
{
    var set0 = [CPMutableIndexSet indexSet],
        set1 = [CPMutableIndexSet indexSet],
        indexes = [set0 indexesPassingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:[indexes isEqualToIndexSet:set1] message:"must be equal to " + [set1 description] + ", was " + [indexes description]];

    [set0 addIndexesInRange:CPMakeRange(1, 10)];
    [set1 addIndex:2];
    [set1 addIndex:4];
    [set1 addIndex:6];
    [set1 addIndex:8];
    [set1 addIndex:10];
    indexes = [set0 indexesPassingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:[indexes isEqualToIndexSet:set1] message:"must be equal to " + [set1 description] + ", was " + [indexes description]];
}

- (void)testIndexPassingTest_options
{
    var set0 = [CPMutableIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 10)],
        index = [set0 indexWithOptions:CPEnumerationReverse
                           passingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:index === 10 message:"index must be equal to 10"];
}

- (void)testIndexesPassingTest_options
{
    var set0 = [CPMutableIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 5)],
        set1 = [CPMutableIndexSet indexSet],
        visitedIndexes = [],
        indexes = [set0 indexesWithOptions:CPEnumerationReverse
                               passingTest:function(anIndex)
        {
            visitedIndexes.push(anIndex);
            return anIndex % 2 === 0;
        }];

    [set1 addIndex:2];
    [set1 addIndex:4];

    [self assertTrue:[indexes isEqualToIndexSet:set1] message:"must be equal to " + [set1 description] + ", was " + [indexes description]];
    [self assert:[5, 4, 3, 2, 1] equals:visitedIndexes message:"enumeration should be done in reverse"];
}

- (void)testIndexPassingTest_options_range
{
    var set0 = [CPMutableIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 10)],
        index = [set0 indexInRange:CPMakeRange(3, 4)
                           options:CPEnumerationReverse
                       passingTest:function(anIndex)
        {
            return anIndex % 2 === 0;
        }];

    [self assertTrue:index === 6 message:"index must be equal to 6"];
}

- (void)testIndexesPassingTest_options_range
{
    var set0 = [CPMutableIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 5)],
        set1 = [CPMutableIndexSet indexSet],
        visitedIndexes = [],
        indexes = [set0 indexesInRange:CPMakeRange(3, 4)
                               options:CPEnumerationReverse
                           passingTest:function(anIndex)
        {
            visitedIndexes.push(anIndex);
            return anIndex % 2 === 0;
        }];

    [set1 addIndex:4];

    [self assertTrue:[indexes isEqualToIndexSet:set1] message:"must be equal to " + [set1 description] + ", was " + [indexes description]];
    [self assert:[5, 4, 3] equals:visitedIndexes message:"enumeration should be done in reverse"];
}

- (void)tearDown
{
    _set = nil;
}

@end
