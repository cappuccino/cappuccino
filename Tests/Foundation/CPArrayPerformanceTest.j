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

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end
