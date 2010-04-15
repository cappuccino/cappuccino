@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

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
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:3];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"two", @"b", @"three", @"four"]];

    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:5];
    
    [indexes addIndex:4];
    
    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"two", @"three", @"four", @"a", @"b"]];
    
    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:4];
    
    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"b", @"two", @"c", @"three", @"four"]];


    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:6];

    [array insertObjects:newAdditions atIndexes:indexes];
    
    [self assert:array equals:[@"one", @"a", @"b", @"two", @"three", @"four", @"c"]];

    //
    
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
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
	
	[self assert:array equals:[@"one", @"two", @"four"]];
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
}

- (void)testInitWithArrayCopyItems
{
    var a = [[CopyableObject new], 2, 3];
    var b = [[CPArray alloc] initWithArray:a copyItems:YES];

    [self assert:a notEqual:b];
}

- (void)testIsEqualToArray
{
    var a = [1, 2, 3],
        b = [5];

    [self assertTrue:[a isEqualToArray:a]];
    [self assertFalse:[a isEqualToArray:b]];
    [self assertFalse:[a isEqualToArray:nil]];
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
