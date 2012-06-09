var FILE = require("file");

@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

var ELEMENTS = 100,
    REPEATS = 10;

@implementation CPArrayPerformanceTest : OJTestCase
{
    CPArray descriptors;
    CPString the_big_sort;
}

- (void)setUp
{
    var descriptors = [
            [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
            [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
        ];

    the_big_sort = FILE.read(FILE.join(FILE.dirname(module.path), "the_big_sort.txt"), { charset:"UTF-8" });
}

- (void)testAlmostSortedNumericUsingMergeSort
{
    CPLog.warn("\nNUMERIC ALMOST SORTED");
    var a = [self makeUnsorted],
        sorted = [self sortUsingMergeSort:a];
    [self checkAlmostSorted:sorted];
}

- (void)testAlmostSortedNumericUsingNativeSort
{
    var a = [self makeUnsorted],
        sorted = [self sortUsingNativeSort:a];
    [self checkAlmostSorted:sorted];
}

- (void)testRandomNumericUsingMergeSort
{
    CPLog.warn("\nNUMERIC RANDOM");
    var a = [self makeRandomNumeric],
        sorted = [self sortUsingMergeSort:a];
    [self checkRandomSorted:sorted];
}

- (void)testRandomNumericUsingNativeSort
{
    var a = [self makeRandomNumeric],
        sorted = [self sortUsingNativeSort:a];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingMergeSort
{
    CPLog.warn("\nTEXT RANDOM");
    var a = [self makeRandomText],
        sorted = [self sortUsingMergeSort:a];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingNativeSort
{
    var a = [self makeRandomText],
        sorted = [self sortUsingNativeSort:a];
    [self checkRandomSorted:sorted];
}

- (CPArray)sortUsingMergeSort:(CPArray)anArray
{
    var sorted,
        start = (new Date).getTime();

    for (var i = 0; i < REPEATS; ++i)
        sorted = [anArray sortedArrayUsingDescriptors:descriptors];

    var end = (new Date).getTime();

    CPLog.warn(_cmd + ": " + (end - start) + "ms");

    return sorted;
}

- (void)sortUsingNativeSort:(CPArray)anArray
{
    var sorted,
        start = (new Date).getTime();

    for (var i = 0; i < REPEATS; ++i)
        sorted = [anArray _native_sortedArrayUsingDescriptors:descriptors];

    var end = (new Date).getTime();

    CPLog.warn(_cmd + ": " + (end - start) + "ms");

    return sorted;
}

- (CPArray)makeUnsorted
{
    var array = [];

    for (var i = 0; i < ELEMENTS; ++i)
    {
        var s = [Sortable new];

        [s setA:(i % 5)];
        [s setB:(ELEMENTS - i)];

        array.push(s);
    }

    return array;
}

- (CPArray)makeRandomNumeric
{
    var array = [];

    for (var i = 0; i < ELEMENTS; i++)
    {
        var s = [Sortable new],
            n1 = ROUND(RAND() * ELEMENTS),
            n2 = ROUND(RAND() * ELEMENTS);

        [s setA:n1];
        [s setB:n2];
        array.push(s);
    }

    return array;
}

- (CPArray)makeRandomText
{
    var words = the_big_sort.split(" ", ELEMENTS),
        wordcount = words.length,
        array = [];

    for (var i = 0; i < wordcount - 1; i++)
    {
        var s = [Sortable new];

        [s setA:words[i]];
        [s setB:words[i + 1]];
        array.push(s);
    }

    return array;
}

- (void)checkAlmostSorted:(CPArray)sorted
{
    // Verify it really got sorted.
    for (var j = 0; j < sorted.length; ++j)
    {
        var expectedA = 4 - FLOOR(j * 5 / ELEMENTS);

        if (sorted[j].a != expectedA)
            [self fail:"a out of order: " + expectedA + " != " + sorted[j].a];

        var expectedB = (5 - expectedA) + 5 * (j % (ELEMENTS / 5));

        if (sorted[j].b != expectedB)
            [self fail:"b out of order: " + expectedB + " != " + sorted[j].b];
    }
}

- (void)checkRandomSorted:(CPArray)sorted
{
    // Verify that it really got sorted.
    for (var j = 0; j < sorted.length - 1; ++j)
    {
        if ([sorted[j].a compare:sorted[j + 1].a] == CPOrderedAscending)
            [self fail:"a out of order: " + sorted[j].a + " > " + sorted[j + 1].a];

        if ([sorted[j].a  compare:sorted[j + 1].a] == CPOrderedSame && [sorted[j].b compare: sorted[j + 1].b] == CPOrderedDescending)
            [self fail:"b out of order: " + sorted[j].b + " < " + sorted[j + 1].b];
    }
}

@end

@implementation CPArray (NativeSort)

- (CPArray)_native_sortedArrayUsingDescriptors:(CPArray)descriptors
{
    var sorted = [self copy];

    [sorted _native_sortUsingDescriptors:descriptors];

    return sorted;
}

- (CPArray)_native_sortUsingDescriptors:(CPArray)descriptors
{
    var count = [descriptors count];

    sort(function(lhs, rhs)
    {
        var i = 0,
            result = CPOrderedSame;

        while (i < count)
            if ((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;

        return result;
    });
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end
