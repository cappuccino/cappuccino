@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>


var ELEMENTS = 100,
    REPEATS = 10;

@implementation CPArrayPerformanceTest : OJTestCase

- (void)testSortUsingDescriptorsSpeed
{
    var array = [self makeUnsorted];

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];

    var start = (new Date).getTime();

    for (var i = 0; i < REPEATS; ++i)
    {
        var sorted = [array sortedArrayUsingDescriptors:descriptors];

        [self checkSorted:sorted];
    }

    var end = (new Date).getTime();

    CPLog.warn(_cmd + ": " + (end - start) + "ms");
}

- (void)testSortUsingNativeSort
{
    var array = [self makeUnsorted];

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];

    function sortFunction(lhs, rhs)
    {
        return ([lhs a] === [rhs a]) ? ([lhs b] - [rhs b]) : ([rhs a] - [lhs a]);
    }

    var start = (new Date).getTime();

    for (var i = 0; i < REPEATS; ++i)
    {
        var sorted = [array copy];

        sorted.sort(sortFunction)

        [self checkSorted:sorted];
    }

    var end = (new Date).getTime();

    CPLog.warn(_cmd+": " + (end - start) + "ms");
}

- (CPArray)makeUnsorted
{
    var array = [];

    for (var i=0; i < ELEMENTS; ++i)
    {
        var s = [Sortable new];

        [s setA:(i % 5)];
        [s setB:(ELEMENTS - i)];

        array.push(s);
    }

    return array;
}

- (void)checkSorted:(CPArray)sorted
{
    // Verify it really got sorted.
    for (var j=0; j < ELEMENTS; ++j)
    {
        var expectedA = 4-FLOOR(j * 5 / ELEMENTS);

        if (sorted[j].a != expectedA)
            [self fail:"a out of order: " + expectedA + " != " + sorted[j].a];

        var expectedB = (5 - expectedA) + 5 * (j % (ELEMENTS / 5));

        if (sorted[j].b != expectedB)
            [self fail:"b out of order: " + expectedB + " != " + sorted[j].b];
    }
}

- (void)testObjectsAtIndexesPerformance
{
    var array = [CPArray array],
        indexes = [CPIndexSet indexSet],
        i = count = 1000,
        repeats1 = repeats2 = 1000,
        rcount = 10,
        rsize = 10;

    // Create array
    while (i--)
        [array addObject:(count - 1 - i)];

    // create indexes in 10 ranges of size 10
    while (rcount--)
    {
        var randomLocation = ROUND(RAND()*(count - rsize)), // 0-990
            randomLength = ROUND(RAND()*rsize); // 0-9

        [indexes addIndexesInRange:CPMakeRange(randomLocation, randomLength)];
    }

    var start = (new Date).getTime();
    while (repeats1--)
        var objects = [array objectsAtIndexes:indexes];
    var end = (new Date).getTime();

    while (repeats2--)
        var prevObjects = [array _prev_objectsAtIndexes:indexes];
    var prevEnd = (new Date).getTime();

    [self assert:[objects count] equals:[indexes count]];
    [self assert:[prevObjects count] equals:[indexes count]];

    CPLog.warn("-objectsAtIndexes: with "+ count + " elements and random indexes in 10 ranges of size 10 - old: " + (prevEnd - end) + "ms new: " + (end - start)+"ms");
}
@end

@implementation CPArray (objectsAtIndexes)

- (CPArray)_prev_objectsAtIndexes:(CPIndexSet)indexes
{
    var index = CPNotFound,
        objects = [];

    while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound)
        objects.push([self objectAtIndex:index]);

    return objects;
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end
