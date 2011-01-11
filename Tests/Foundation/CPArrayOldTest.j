@import <Foundation/Foundation.j>

@implementation CPArrayOldTest : OJTestCase

- (void)testsInsertObjectsAtIndexes
{
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b"],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:3];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"two", @"b", @"three", @"four"]];

    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b"],
        indexes = [CPMutableIndexSet indexSetWithIndex:5];

    [indexes addIndex:4];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"two", @"three", @"four", @"a", @"b"]];

    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", @"c"],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:4];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"b", @"two", @"c", @"three", @"four"]];


    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", @"c"],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:6];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"b", @"two", @"three", @"four", @"c"]];


    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b"],
        indexes = [CPMutableIndexSet indexSetWithIndex:5];

    [indexes addIndex:6];

    try
    {
        [array insertObjects:newAdditions atIndexes:indexes];
        [self fail];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
}

- (void)testRemoveObjectsAtIndexes
{
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:2];

    [array removeObjectsAtIndexes:indexes];

    [self assert:array equals:[@"one", @"two", @"four"]];
}

- (void)testInsertObjectInArraySortedByDescriptors
{
    var descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:YES]],
        array = [1, 3, 5];

    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[0, 1, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 2, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 1, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 5, 6] equals:array];

    array = [1, 3, 5];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 3, 5] equals:array];

    array = [];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [5, 3, 1];
    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [5, 3, 1];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [5, 3, 1];
    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [5, 3, 1];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

}

- (void)testInitWithArrayCopyItems
{
    var a = [[CopyableObject new], 2, 3, {empty:true}],
        b = [[CPArray alloc] initWithArray:a copyItems:YES];

    [self assert:a notEqual:b];

    [self assert:a[0] notEqual:b[0]];
    [self assert:a[1] equals:b[1]];
    [self assert:a[2] equals:b[2]];
    [self assertTrue:a[3] === b[3]];
}

- (void)testThatCPArrayDoesSortUsingDescriptorsForStrings
{
    var target = ["a", "b", "c", "d"],
        pretty = [];

    for (var i = 0; i < target.length; i++)
        pretty.push([[CPPrettyObject alloc] initWithValue:target[i] number:i]);

    [pretty sortUsingDescriptors:[[[CPSortDescriptor alloc] initWithKey:@"value" ascending:NO]]];

    [self assert:"(\n\t3:d, \n\t2:c, \n\t1:b, \n\t0:a\n)" equals:[pretty description]];

    [pretty sortUsingDescriptors:[[[CPSortDescriptor alloc] initWithKey:@"value" ascending:YES]]];

    [self assert:"(\n\t0:a, \n\t1:b, \n\t2:c, \n\t3:d\n)" equals:[pretty description]]
}

- (void)testThatCPArrayDoesSortUsingTwoDescriptors
{
    var descriptors = [
                        [[CPSortDescriptor alloc] initWithKey:@"value" ascending:NO],
                        [[CPSortDescriptor alloc] initWithKey:@"number" ascending:NO]
                      ],
        target = [
                    [[CPPrettyObject alloc] initWithValue:@"a" number:1],
                    [[CPPrettyObject alloc] initWithValue:@"a" number:2],
                    [[CPPrettyObject alloc] initWithValue:@"a" number:3],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:1],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:2],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:3],
                 ];

    [target sortUsingDescriptors:descriptors];

    [self assert:@"3:b" equals:[target[0] description]];
    [self assert:@"2:b" equals:[target[1] description]];
    [self assert:@"1:b" equals:[target[2] description]];
    [self assert:@"3:a" equals:[target[3] description]];
    [self assert:@"2:a" equals:[target[4] description]];
    [self assert:@"1:a" equals:[target[5] description]];
}

- (void)testThatCPArrayDoesSortUsingTwoDescriptorsOpposite
{
    var descriptors = [
                          [[CPSortDescriptor alloc] initWithKey:@"number" ascending:NO],
                          [[CPSortDescriptor alloc] initWithKey:@"value" ascending:NO]
                      ],
        target = [
                    [[CPPrettyObject alloc] initWithValue:@"a" number:1],
                    [[CPPrettyObject alloc] initWithValue:@"a" number:2],
                    [[CPPrettyObject alloc] initWithValue:@"a" number:3],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:1],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:2],
                    [[CPPrettyObject alloc] initWithValue:@"b" number:3],
                 ];

    [target sortUsingDescriptors:descriptors];

    [self assert:@"3:b" equals:[target[0] description]];
    [self assert:@"3:a" equals:[target[1] description]];
    [self assert:@"2:b" equals:[target[2] description]];
    [self assert:@"2:a" equals:[target[3] description]];
    [self assert:@"1:b" equals:[target[4] description]];
    [self assert:@"1:a" equals:[target[5] description]];
}

- (void)testThatCPArrayDoesSortUsingDescriptorWithMultipleSameValues
{
    var descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]],
        target = [1, 1, 2, 4, 3, 1, 2, 4, 5, 1];

    [target sortUsingDescriptors:descriptors];

    [self assert:[5, 4, 4, 3, 2, 2, 1, 1, 1, 1] equals:target];
}

@end

@implementation CPPrettyObject : CPObject
{
    CPString        value       @accessors;
    CPNumber        number      @accessors;
}

- (id)initWithValue:(CPString)aValue number:(CPNumber)aNumber
{
    self = [super init];
    if (self)
    {
        number = aNumber;
        value = aValue;
    }
    return self;
}

- (CPString)description
{
    return number + ":" + value;
}

@end

@implementation CopyableObject : CPObject
{
}

- (id)copy
{
    return [[[self class] alloc] init];
}

@end
