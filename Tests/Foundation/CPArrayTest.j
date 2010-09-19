@import <Foundation/Foundation.j>

@implementation CPArrayTest : OJTestCase

- (void)testComponentsJoinedByString
{
    var testStrings = [
        [[], "", ""],
        [[], "-", ""],
        [[1,2], "-", "1-2"],
        [[1,2,3], "-", "1-2-3"],
        [["123", 456], "-", "123-456"]
    ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] componentsJoinedByString:testStrings[i][1]] equals:testStrings[i][2]];
}

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

    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c"],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:4];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"b", @"two", @"c", @"three", @"four"]];


    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four"],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c"],
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
            indexes = [CPMutableIndexSet indexSetWithIndex: 2];

    [array removeObjectsAtIndexes: indexes];

    [self assert:array equals:[@"one", @"two", @"four", nil]];
}

- (void)testIndexOfObjectPassingTest
{
    var array = [CPArray arrayWithObjects:{name:@"Tom", age:7}, {name:@"Dick", age:13}, {name:@"Harry", age:27}, {name:@"Zelda", age:7}],
        namePredicate = function(object, index) { return [object.name isEqual:@"Harry"]; },
        agePredicate = function(object, index) { return object.age === 13; },
        failPredicate = function(object, index) { return [object.name isEqual:@"Horton"]; },
        noPredicate = function(object, index) { return NO; },
        stopPredicate = function(object, index) { return nil; };

    [self assert:[array indexOfObjectPassingTest:namePredicate] equals:2];
    [self assert:[array indexOfObjectPassingTest:agePredicate] equals:1];
    [self assert:[array indexOfObjectPassingTest:failPredicate] equals:CPNotFound];
    [self assert:[array indexOfObjectPassingTest:noPredicate] equals:CPNotFound];
    [self assert:[array indexOfObjectPassingTest:stopPredicate] equals:CPNotFound];
}

- (void)testIndexOfObjectPassingTestContext
{
    var array = [CPArray arrayWithObjects:{name:@"Tom", age:7}, {name:@"Dick", age:13}, {name:@"Harry", age:27}, {name:@"Zelda", age:7}],
        namePredicate = function(object, index, context) { return [object.name isEqual:context]; },
        agePredicate = function(object, index, context) { return object.age === context; };

    [self assert:[array indexOfObjectPassingTest:namePredicate context:@"Harry"] equals:2];
    [self assert:[array indexOfObjectPassingTest:agePredicate context:13] equals:1];
}

- (void)testIndexOfObjectWithOptionsPassingTest
{
    var array = [CPArray arrayWithObjects:{name:@"Tom", age:7}, {name:@"Dick", age:13}, {name:@"Harry", age:27}, {name:@"Zelda", age:7}],
        namePredicate = function(object, index) { return [object.name isEqual:@"Harry"]; },
        agePredicate = function(object, index) { return object.age === 7; };

    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:namePredicate] equals:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:namePredicate] equals:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:agePredicate] equals:0];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:agePredicate] equals:3];
}

- (void)testIndexOfObjectWithOptionsPassingTestContext
{
    var array = [CPArray arrayWithObjects:{name:@"Tom", age:7}, {name:@"Dick", age:13}, {name:@"Harry", age:27}, {name:@"Zelda", age:7}],
        namePredicate = function(object, index, context) { return [object.name isEqual:context]; },
        agePredicate = function(object, index, context) { return object.age === context; };

    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:namePredicate context:@"Harry"] equals:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:namePredicate context:@"Harry"] equals:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:agePredicate context:7] equals:0];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:agePredicate context:7] equals:3];
}

- (void)testIndexOfObjectSortedByFunction
{
    var array = [0, 1, 2, 3, 4, 7];

    [self assert:[array indexOfObject:3 sortedByFunction:function(a, b){ return a - b; }] equals:3];
    [self assert:[[array arrayByReversingArray] indexOfObject:3 sortedByFunction:function(a, b){ return b - a; }] equals:2];
}

- (void)testIndexOfObjectSortedByDescriptors
{
    var array = [0, 1, 2, 3, 4, 7];

    [self assert:[array indexOfObject:3
                  sortedByDescriptors:[[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:YES]]]
          equals:3];

    [self assert:[[array arrayByReversingArray] indexOfObject:3
                  sortedByDescriptors:[[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]]]
          equals:2];
}

- (void)testIndexOutOfBounds
{
    try
    {
        [[] objectAtIndex:0];
        [self assert:false];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPRangeException];
        [self assert:[anException reason] equals:@"index (0) beyond bounds (0)"];
    }

    [[0, 1, 2] objectAtIndex:0];
    [[0, 1, 2] objectAtIndex:1];
    [[0, 1, 2] objectAtIndex:2];

    try
    {
        [[0, 1, 2] objectAtIndex:3];
        [self assert:false];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPRangeException];
        [self assert:[anException reason] equals:@"index (3) beyond bounds (3)"];
    }

    try
    {
        [[0, 1, 2] objectAtIndex:4];
        [self assert:false];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPRangeException];
        [self assert:[anException reason] equals:@"index (4) beyond bounds (3)"];
    }
}

- (void)testInsertObjectInArraySortedByDescriptors
{
    var descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:YES]];
    var array = [1, 3, 5];

    [array insertObject: 0 inArraySortedByDescriptors:descriptors];
    [self assert:[0, 1, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject: 2 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 2, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject: 1 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 1, 3, 5] equals:array];

    array = [1, 3, 5];
    [array insertObject: 6 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 5, 6] equals:array];

    array = [1, 3, 5];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 3, 5] equals:array];

    array = [];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [5, 3, 1];
    [array insertObject: 0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [5, 3, 1];
    [array insertObject: 2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [5, 3, 1];
    [array insertObject: 0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [5, 3, 1];
    [array insertObject: 2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [5, 3, 1];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [];
    [array insertObject: 3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

}

- (void)testInitWithArrayCopyItems
{
    var a = [[CopyableObject new], 2, 3, {empty:true}];
    var b = [[CPArray alloc] initWithArray:a copyItems:YES];

    [self assert:a notEqual:b];

    [self assert:a[0] notEqual:b[0]];
    [self assert:a[1] equals:b[1]];
    [self assert:a[2] equals:b[2]];
    [self assertTrue:a[3] === b[3]];
}

- (void)testIsEqualToArray
{
    var a = [1, 2, 3],
        b = [5];

    [self assertTrue:[a isEqualToArray:a]];
    [self assertFalse:[a isEqualToArray:b]];
    [self assertFalse:[a isEqualToArray:nil]];
}

- (void)testIsEqualToArray
{
    var a = [1, 2, 3],
        b = [5];

    [self assertTrue:[a isEqualToArray:a]];
    [self assertFalse:[a isEqualToArray:b]];
    [self assertFalse:[a isEqualToArray:nil]];
}

- (void)testThatCPArrayDoesSortUsingDescriptorsForStrings
{
    var target = ["a", "b", "c", "d"],
        pretty = [];

    for(var i = 0; i < target.length; i++)
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


@implementation CPArray (reverse)

- (CPArray)arrayByReversingArray
{
    var a = [];
    for (i = length - 1; i>0; --i)
        a.push(self[i]);

    return a;
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
