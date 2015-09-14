@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPPredicate.j>
@import <AppKit/CPArrayController.j>

var ELEMENTS = 200,
    REPEATS = 25;

@implementation CPArrayControllerPerformance : OJTestCase
{

}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (CPArrayController)setupWithElements:(int)aCount
{
    var ac = [CPArrayController new],
        array = [];

    for (var i = 0; i < aCount; i++)
    {
        var s = [Sortable new];
        [s setA:i];
        [s setB:i % 3];
        array.push(s);
    }

    [ac setContent:array];

    [ac setFilterPredicate:[CPPredicate predicateWithFormat:@"(b != %@)", 0]];

    return ac;
}

- (void)testRearrangeObjects
{
    var ac = [self setupWithElements:ELEMENTS];

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
                [self fail:"b == 0 should be filtered out (position: " + j + ")"];
            last = sorted[j];
        }
    }
    var end = (new Date).getTime();

    CPLog.warn("testRearrangeObjects, filter: "+(end-start)+"ms");

    [ac setSortDescriptors:[
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
    ]];

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
                [self fail:"b == 0 should be filtered out (position: " + j + ")"];
            if (sorted[j].a >= last)
                [self fail:"array values should be descending (position: " + j + ")"];
            last = sorted[j];
        }
    }
    end = (new Date).getTime();

    CPLog.warn("testRearrangeObjects, filter and sort: "+(end-start)+"ms");
}

- (void)testAddObject_
{
    var ac = [self setupWithElements:ELEMENTS],
        predicate = [ac filterPredicate],
        content = [[ac content] copy];

    // Add object while clearing the predicate.
    [ac setClearsFilterPredicateOnInsertion:YES];

    [ac setSortDescriptors:[
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
    ]];

    var start = (new Date).getTime();
    for (var i = 0; i < REPEATS / 2; i++)
    {
        [ac setFilterPredicate:predicate];
        [ac addObject:[Sortable sortableWithA:i B:i * 2]];

        var sorted = [ac arrangedObjects],
            last = ELEMENTS;

        // Verify that all is well.
        for (var j = 0, count = [sorted count]; j < count; j++)
        {
            if (sorted[j].a >= last)
                [self fail:"array values should be descending (position: " + j + ")"];
            last = sorted[j];
        }
    }
    var end = (new Date).getTime();
    CPLog.warn("testAddObject_, sorted, clear filter on insert: " + (end - start) + "ms");

    [ac setClearsFilterPredicateOnInsertion:NO];
    [ac setFilterPredicate:predicate];

    var start = (new Date).getTime();
    for (var i = 0; i < REPEATS; i++)
    {
        [ac addObject:[Sortable sortableWithA:i B:i % 3]];

        var sorted = [ac arrangedObjects],
            last = ELEMENTS;

        // Verify that all is well.
        for (var j = 0, count = [sorted count]; j < count; j++)
        {
            if (sorted[j].b == 0)
                [self fail:"b == 0 should be filtered out (position: " + j + ")"];
            if (sorted[j].a >= last)
                [self fail:"array values should be descending (position: " + j + ")"];
            last = sorted[j];
        }
    }
    var end = (new Date).getTime();
    CPLog.warn("testAddObject_, sorted, filtered: " + (end - start) + "ms");
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

+ (id)sortableWithA:(int)anA B:(int)aB
{
    var r = [Sortable new];
    r.a = anA;
    r.b = aB;
    return r;
}

@end