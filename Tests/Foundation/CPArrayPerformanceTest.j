var FILE = require("file");

@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

@global module

//+ Jonas Raoni Soares Silva
//@ http://jsfromhell.com/array/shuffle [v1.0]
function shuffle(o)
{ //v1.0
    for (var j, x, i = o.length; i; j = parseInt(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};

var ELEMENTS = 100,
    REPEATS = 10;

@implementation CPArrayPerformanceTest : OJTestCase
{
    CPArray descriptors;
}

- (void)setUp
{
    descriptors = [
            [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
            [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
        ];
}

- (void)testAlmostSortedNumericUsingMergeSort
{
    CPLog.warn("\nNUMERIC ALMOST SORTED");
    var a = [self makeUnsorted],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkAlmostSorted:sorted];
}

- (void)testAlmostSortedNumericUsingNativeSort
{
    var a = [self makeUnsorted],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkAlmostSorted:sorted];
}

- (void)testRandomNumericUsingMergeSort
{
    CPLog.warn("\nNUMERIC RANDOM");
    var a = [self makeRandomNumeric],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkRandomSorted:sorted];
}

- (void)testRandomNumericUsingNativeSort
{
    var a = [self makeRandomNumeric],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingMergeSort
{
    CPLog.warn("\nTEXT RANDOM");
    var a = [self makeRandomText],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingNativeSort
{
    var a = [self makeRandomText],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingDescriptors:) withObject:descriptors];
    [self checkRandomSorted:sorted];
}

- (void)testAlmostSortedNumericUsingMergeSelectorSort
{
    CPLog.warn("\nNUMERIC ALMOST SORTED (SELECTOR)");
    var a = [self makeUnsorted],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkAlmostSorted:sorted];
}

- (void)testAlmostSortedNumericUsingNativeSelectorSort
{
    var a = [self makeUnsorted],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkAlmostSorted:sorted];
}

- (void)testRandomNumericUsingMergeSelectorSort
{
    CPLog.warn("\nNUMERIC RANDOM (SELECTOR)");
    var a = [self makeRandomNumeric],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkRandomSorted:sorted];
}

- (void)testRandomNumericUsingNativeSelectorSort
{
    var a = [self makeRandomNumeric],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingMergeSelectorSort
{
    CPLog.warn("\nTEXT RANDOM (SELECTOR)");
    var a = [self makeRandomText],
        sorted = [self sort:a usingSortSelector:@selector(sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkRandomSorted:sorted];
}

- (void)testRandomTextUsingNativeSelectorSort
{
    var a = [self makeRandomText],
        sorted = [self sort:a usingSortSelector:@selector(_native_sortedArrayUsingSelector:) withObject:@selector(compareAAscendingThenBDescending:)];
    [self checkRandomSorted:sorted];
}

- (CPArray)sort:(CPArray)anArray usingSortSelector:(SEL)aSelector withObject:(id)anObject
{
    var sorted,
        start = (new Date).getTime();

    for (var i = 0; i < REPEATS; ++i)
        sorted = [anArray performSelector:aSelector withObject:anObject];

    var end = (new Date).getTime();

    CPLog.warn(aSelector + ": " + (end - start) + "ms");

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
    var the_big_sort = FILE.read(FILE.join(FILE.dirname(module.path), "the_big_sort.txt"), { charset:"UTF-8" }),
        words = the_big_sort.split(" ", ELEMENTS),
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

- (void)testObjectsAtIndexesSpeed
{
    REPEATS = 100;

    var SIZE = 1000,
        c = SIZE,
        r = REPEATS,
        rr = r,
        location = 0,
        array = [CPArray array],
        indexes = [CPIndexSet indexSet];

    while (c--)
        array.push("" + c);

    while (location < SIZE - 10)
    {
        var rangeLength = ROUND(10 * RAND());
        [indexes addIndexesInRange:CPMakeRange(location, rangeLength)];

        location += rangeLength + ROUND(10 * RAND());
    }

    var d = new Date(),
        test1,
        test2;
    while (r--)
        test1 = [array _previous_objectsAtIndexes:indexes];
    var dd = new Date();

    while (rr--)
        test2 = [array objectsAtIndexes:indexes];
    var ddd = new Date();

    CPLog.warn("\n_CPJavaScriptArray -objectsAtIndexes:");
    CPLog.warn("           CPArray -objectsAtIndexes: " + (dd - d) + "ms.");
    CPLog.warn("_CPJavaScriptArray -objectsAtIndexes: " + (ddd - dd) + "ms.");

    if (![test1 isEqual:test2])
        [self fail:"_CPJavaScriptArray -objectsAtIndexes: returns an wrong value"];
}

- (void)testRemoveObjectIdenticalTo
{
    REPEATS = 200;

    var SIZE = 33 * 6,
        allThings = [],
        testSources = [];

    for (var c = 0; c < SIZE; c++)
        allThings.push("" + c);

    var someThings = [allThings subarrayWithRange:CPMakeRange(SIZE / 3, SIZE / 3)],
        removeThings = [allThings subarrayWithRange:(CPMakeRange(0, 2 * SIZE / 3))];

    for (var r = 0; r < REPEATS * 2; r++)
        testSources.push(shuffle(someThings));

    var d = new Date(),
        test1;
    for (var r = 0; r < REPEATS; r++)
    {
        test1 = testSources.pop();
        for (var i = 0, count = [removeThings count]; i < count; i++)
            [test1 _previous_removeObjectIdenticalTo:removeThings[i]];
    }

    var dd = new Date(),
        test2;
    for (var r = 0; r < REPEATS; r++)
    {
        test2 = testSources.pop();
        for (var i = 0, count = [removeThings count]; i < count; i++)
            [test2 removeObjectIdenticalTo:removeThings[i]];
    }
    var ddd = new Date();

    CPLog.warn("\n_CPJavaScriptArray -removeObjectIdenticalTo:");
    CPLog.warn("           CPArray -removeObjectIdenticalTo: " + (dd - d) + "ms.");
    CPLog.warn("_CPJavaScriptArray -removeObjectIdenticalTo: " + (ddd - dd) + "ms.");

    if (![test1 isEqual:test2])
        [self fail:"_CPJavaScriptArray -objectsAtIndexes: returns wrong value"];
}

@end

@implementation _CPJavaScriptArray (ObjectsAtIndexes)

- (CPArray)_previous_objectsAtIndexes:(CPIndexSet)indexes
{
    return [super objectsAtIndexes:indexes];
}

- (void)_previous_removeObjectIdenticalTo:(id)anObject
{
    [self _previous_removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, [self count])];
}

- (void)_previous_removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    [super removeObjectIdenticalTo:anObject inRange:aRange];
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

    self.sort(function(lhs, rhs)
    {
        var i = 0,
            result = CPOrderedSame;

        while (i < count)
            if ((result = [descriptors[i++] compareObject:lhs withObject:rhs]) !== CPOrderedSame)
                return result;

        return result;
    });
}

- (CPArray)_native_sortedArrayUsingSelector:(SEL)aSelector
{
    var sorted = [self copy];

    [sorted _native_sortUsingSelector:aSelector];

    return sorted;
}

- (CPArray)_native_sortUsingSelector:(SEL)aSelector
{
    self.sort(function(lhs, rhs)
    {
        return [lhs performSelector:aSelector withObject:rhs];
    });
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

- (int)compareAAscendingThenBDescending:(Sortable)other
{
    var aResult = [a compare:other.a];

    return aResult === CPOrderedSame ? [b compare:other.b] : -aResult;
}

@end

