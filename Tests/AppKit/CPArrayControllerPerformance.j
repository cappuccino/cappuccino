@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPPredicate.j>
@import <AppKit/CPArrayController.j>

@implementation CPArrayControllerPerformance : OJTestCase

- (void)testRearrangeObjects
{
    var ELEMENTS = 200,
        REPEATS = 25,
        ac = [CPArrayController new],
        array = [];

    for (var i = 0; i < ELEMENTS; i++)
    {
        var s = [Sortable new];
        [s setA:i];
        [s setB:i % 3];
        array.push(s);
    }

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
    ];

    [ac setContent:array];


    [ac setFilterPredicate:[CPPredicate predicateWithFormat:@"(b != %@)", 0]];

    // Filter alone
    var start = (new Date).getTime();
    for (var i = 0; i < REPEATS; i++)
    {
        [ac rearrangeObjects];

        var sorted = [ac arrangedObjects],
            last = ELEMENTS;

        // Verify that all is well.
        for (var j = 0, count = [sorted count]; j < count; j++)
        {
            if (sorted[j].b == 0)
                [self fail:"b == 0 should be filtered out (position: "+j+")"];
            last = sorted[j];
        }
    }
    var end = (new Date).getTime();

    CPLog.warn("testRearrangeObjects, filter: "+(end-start)+"ms");

    [ac setSortDescriptors:descriptors];

    // Filter and sort.
    start = (new Date).getTime();
    for (var i = 0; i < REPEATS; i++)
    {
        [ac rearrangeObjects];

        var sorted = [ac arrangedObjects],
            last = ELEMENTS;

        // Verify that all is well.
        for (var j = 0, count = [sorted count]; j < count; j++)
        {
            if (sorted[j].b == 0)
                [self fail:"b == 0 should be filtered out (position: "+j+")"];
            if (sorted[j].a >= last)
                [self fail:"array values should be descending (position: "+j+")"];
            last = sorted[j];
        }
    }
    end = (new Date).getTime();

    CPLog.warn("testRearrangeObjects, filter and sort: "+(end-start)+"ms");
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end