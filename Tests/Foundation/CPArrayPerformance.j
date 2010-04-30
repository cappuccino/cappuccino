@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

@implementation CPArrayPerformance : OJTestCase

- (void)testSortUsingDescriptorsSpeed
{

    var ELEMENTS = 1000,
        REPEATS = 10,
        array = [];
    for (var i=0; i<ELEMENTS; i++) {
        var s = [Sortable new];
        [s setA:(i % 5)];
        [s setB:(ELEMENTS-i)];
        array.push(s);
    }

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];

    var start = (new Date).getTime();

    for (var i=0; i<REPEATS; i++)
    {
        var sorted = [array sortedArrayUsingDescriptors:descriptors];

        // Verify it really got sorted.
        for (var j=0; j<ELEMENTS; j++) {
            var expectedA = 4-FLOOR(j * 5 / ELEMENTS);
            if (sorted[j].a != expectedA)
                [self fail:"a out of order: "+expectedA+" != "+sorted[j].a];
            var expectedB = (5-expectedA) + 5 * (j % (ELEMENTS / 5))
            if (sorted[j].b != expectedB)
                [self fail:"b out of order: "+expectedB+" != "+sorted[j].b];
        }
    }

    var end = (new Date).getTime();

    CPLog.warn("testSortUsingDescriptorsSpeed: "+(end-start)+"ms");
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end