@import <Foundation/CPURL.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

@implementation CPArrayTest : OJTestCase

- (void)testComparingSimpleArrays
{
    [self assertTrue:[["1", 2, [3, 4, 5]] isEqual:["1", 2, [3, 4, 5]]]];
    [self assertFalse:[["1", 2, [3, 4, "5"]] isEqual:["1", 2, [3, 4, 5]]]];
}

- (void)testComparingArraysOfCappuccinoObjects
{
    var obj1 = [CPURL URLWithString:"/test/url"],
        obj2 = [CPURL URLWithString:"/test/url"],
        obj3 = [CPArray arrayWithObjects:["test1", "test2", "test3"]],
        obj4 = [CPArray arrayWithObjects:["test1", "test2", "test3"]],
        obj5 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "c"]],
        obj6 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "c"]],
        obj7 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "e"]];

    [self assertTrue:[[obj1, [obj3, obj5]] isEqual:[obj2, [obj4, obj6]]]];
    [self assertFalse:[[obj1, [obj3, obj5]] isEqual:[obj2, [obj4, obj7]]]];
}

- (void)testComparingArraysOfJSObjects
{
    var obj1 = {'name' : 'test',
                'property' : [1, '2', [3, 4], {'inner_object' : {'a' : 'b'}}],
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 2, 3]},
                                          'prop3' : 'string'}};
    var obj2 = {'name' : 'test',
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 8, 3]},
                                          'prop3' : 'string'}};
    var obj3 = {'name' : 'test',
                'property' : [1, '2', [3, 4], {'inner_object' : {'a' : 'b'}}],
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 2, 3]},
                                          'prop3' : 'string'}};
    var obj4 = {'name' : 'test',
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 8, 3]},
                                          'prop3' : 'string'}};
    [self assertTrue:[[obj1, obj2] isEqual:[obj3, obj4]]];
    [self assertFalse:[[obj1, obj2] isEqual:[obj4, obj3]]];

}

- (void)testComparingArraysOfObjjAndJSObjects
{
    var obj1 = {'name' : 'test',
                'property' : [1, '2', [3, 4], {'inner_object' : {'a' : 'b'}}],
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 2, 3]},
                                          'prop3' : 'string'}};
    var obj2 = {'name' : 'test',
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 8, 3]},
                                          'prop3' : 'string'}};
    var obj3 = {'name' : 'test',
                'property' : [1, '2', [3, 4], {'inner_object' : {'a' : 'b'}}],
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 2, 3]},
                                          'prop3' : 'string'}};
    var obj4 = {'name' : 'test',
                'another_inner_object' : {'prop1' : 8,
                                          'prop2' : {'x' : [1, 8, 3]},
                                          'prop3' : 'string'}};

    var obj6 = [CPURL URLWithString:"/test/url"],
        obj7 = [CPURL URLWithString:"/test/url"],
        obj8 = [CPArray arrayWithObjects:["test1", "test2", "test3"]],
        obj9 = [CPArray arrayWithObjects:["test1", "test2", "test3"]],
        obj10 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "c"]],
        obj11 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "c"]],
        obj12 = [CPDictionary dictionaryWithObjects:[1, 2, 3] forKeys:["a", "b", "e"]];
    [self assertTrue:[[obj1, obj6, obj10, [obj2, obj8]] isEqual:[obj3, obj7, obj11, [obj4, obj9]]]];
    [self assertFalse:[[obj1, obj6, obj10, [obj2, obj8]] isEqual:[obj3, {"json" : "test"}, obj11, [obj4, obj9]]]];
    [self assertFalse:[[obj12, obj6, obj10, [obj2, obj8]] isEqual:[obj3, obj7, obj11, [obj4, obj9]]]];
    [self assertFalse:[[obj1, obj6, obj10, [obj2, obj8]] isEqual:[obj3, obj7, obj11, [obj4, obj12]]]];
}

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

- (void)testInitWithArrayCopyItems
{
    var a = [[CopyableObject new], 2, 3];
    var b = [[CPArray alloc] initWithArray:a copyItems:YES];

    [self assert:a notEqual:b];
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
