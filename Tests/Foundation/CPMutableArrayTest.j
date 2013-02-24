
@import <Foundation/Foundation.j>
@import "CPArrayTest.j"

@implementation CPMutableArrayTest : CPArrayTest

+ (Class)arrayClass
{
    return ConcreteMutableArray;
}

- (void)test_addObject_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array addObject:0];
    [self assert:array equals:[arrayClass arrayWithObjects:0]];

    [array addObject:0];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 0]];

    [array addObject:1];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 0, 1]];

    [array addObject:[arrayClass arrayWithObjects:0, 1, 2]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 0, 1, [arrayClass arrayWithObjects:0, 1, 2]]];

    [array addObject:[0, 1, 2]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 0, 1, [arrayClass arrayWithObjects:0, 1, 2], [0, 1, 2]]];

    var object = { };

    [array addObject:object];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 0, 1, [arrayClass arrayWithObjects:0, 1, 2], [0, 1, 2], object]];
}

- (void)test_addObjectsFromArray_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array addObjectsFromArray:[arrayClass arrayWithObjects:0, 1, 2]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2]];

    [array addObjectsFromArray:[0, 1, 2]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2, 0, 1, 2]];

    [array addObjectsFromArray:[arrayClass array]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2, 0, 1, 2]];

    [array addObjectsFromArray:[]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2, 0, 1, 2]];
}

- (void)test_insertObjects_atIndexes_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array insertObjects:[arrayClass arrayWithObjects:2, 4] atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    [self assert:array equals:[arrayClass arrayWithObjects:2, 4]];

    [array insertObjects:[arrayClass arrayWithObjects:0] atIndexes:[CPIndexSet indexSetWithIndex:0]];

    [self assert:array equals:[arrayClass arrayWithObjects:0, 2, 4]];

    [array insertObjects:[arrayClass arrayWithObjects:5] atIndexes:[CPIndexSet indexSetWithIndex:3]];

    [self assert:array equals:[arrayClass arrayWithObjects:0, 2, 4, 5]];

    [array insertObjects:[arrayClass arrayWithObjects:6, 7] atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(4, 2)]];

    [self assert:array equals:[arrayClass arrayWithObjects:0, 2, 4, 5, 6, 7]];

    [array insertObjects:[arrayClass arrayWithObjects:-2, -1] atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    [self assert:array equals:[arrayClass arrayWithObjects:-2, -1, 0, 2, 4, 5, 6, 7]];

    var indexSet = [CPMutableIndexSet indexSetWithIndex:3];

    [indexSet addIndex:5];

    [array insertObjects:[arrayClass arrayWithObjects:1, 3] atIndexes:indexSet];

    [self assert:array equals:[arrayClass arrayWithObjects:-2, -1, 0, 1, 2, 3, 4, 5, 6, 7]];

    [self assertThrows:function()
    {
        [array insertObjects:[arrayClass array] atIndexes:[CPIndexSet indexSetWithIndex:13]];
    }];
}

- (void)test_removeObject_
{
    var arrayClass = [[self class] arrayClass],
        a = [CPDate distantFuture],
        b = [a copy],
        c = [CPDate distantPast],
        array = [arrayClass arrayWithObjects:a, b, a, c, b];

    [array removeObject:a];
    [self assert:array equals:[arrayClass arrayWithObjects:c]];
}

- (void)test_removeObjectIdenticalTo_
{
    var arrayClass = [[self class] arrayClass],
        a = [CPDate distantFuture],
        b = [a copy],
        array = [arrayClass arrayWithObjects:a, b, a, b, b];

    [array removeObjectIdenticalTo:b];
    [self assert:array equals:[arrayClass arrayWithObjects:a, a]];
}

- (void)test_removeObjectsAtIndexes_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6];

    [array removeObjectsAtIndexes:[CPIndexSet indexSet]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6]];

    [array removeObjectsAtIndexes:[CPIndexSet indexSetWithIndex:2]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 3, 4, 5, 6]];

    [array removeObjectsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(3, 2)]];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 3, 6]];

    [array removeObjectsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 4)]];
    [self assert:array equals:[arrayClass array]];
}

- (void)test_removeAllObjects
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];

    array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];

    array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6, [arrayClass arrayWithObjects:0, 1, 2]];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];
}

- (void)test_removeObjectsInRange_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6];

    [array removeObjectsInRange:CPMakeRange(0, 0)];
    [self assert:array equals:[arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6]];

    [array removeObjectsInRange:CPMakeRange(0, 1)];
    [self assert:array equals:[arrayClass arrayWithObjects:1, 2, 3, 4, 5, 6]];

    [array removeObjectsInRange:CPMakeRange(2, 3)];
    [self assert:array equals:[arrayClass arrayWithObjects:1, 2, 6]];

    [array removeObjectsInRange:CPMakeRange(2, 1)];
    [self assert:array equals:[arrayClass arrayWithObjects:1, 2]];

    [array removeObjectsInRange:CPMakeRange(0, 2)];
    [self assert:array equals:[arrayClass array]];
}

- (void)test_removeAllObjects
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];

    array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];

    array = [arrayClass arrayWithObjects:0, 1, 2, 3, 4, 5, 6, [arrayClass arrayWithObjects:0, 1, 2]];

    [array removeAllObjects];
    [self assert:0 same:[array count]];
    [self assert:[arrayClass array] equals:array];
}

- (void)test_setArray_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [array setArray:[arrayClass array]];
    [self assert:[arrayClass array] equals:array];

    [array setArray:[arrayClass arrayWithObjects:0, 1, 2, 3]];
    [self assert:[arrayClass arrayWithObjects:0, 1, 2, 3] equals:array];

    [array setArray:[arrayClass array]];
    [self assert:[arrayClass array] equals:array];

    [array setArray:[-1, 0, 1]];
    [self assert:[arrayClass arrayWithObjects:-1, 0, 1] equals:array];
}

- (void)test_insertObject_inArraySortedByDescriptors_
{
    var arrayClass = [[self class] arrayClass],
        descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:YES]],
        array = [arrayClass arrayWithObjects:1, 3, 5];

    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[0, 1, 3, 5] equals:array];

    array = [arrayClass arrayWithObjects:1, 3, 5];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 2, 3, 5] equals:array];

    array = [arrayClass arrayWithObjects:1, 3, 5];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 1, 3, 5] equals:array];

    array = [arrayClass arrayWithObjects:1, 3, 5];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 5, 6] equals:array];

    array = [arrayClass arrayWithObjects:1, 3, 5];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[1, 3, 3, 5] equals:array];

    array = [arrayClass array];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [arrayClass array];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];

    descriptors = [[[CPSortDescriptor alloc] initWithKey:@"intValue" ascending:NO]];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:0 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 0] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:2 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 2, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:1 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 1, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:6 inArraySortedByDescriptors:descriptors];
    [self assert:[6, 5, 3, 1] equals:array];

    array = [arrayClass arrayWithObjects:5, 3, 1];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[5, 3, 3, 1] equals:array];

    array = [arrayClass array];
    [array insertObject:3 inArraySortedByDescriptors:descriptors];
    [self assert:[3] equals:array];
}

- (void)test_replaceObjectsInRange_withObjectFromArray_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:1, 2, 3, 4, 5];

    [array replaceObjectsInRange:CPMakeRange(0, 0) withObjectsFromArray:[arrayClass array]];
    [self assert:[1, 2, 3, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 1) withObjectsFromArray:[arrayClass array]];
    [self assert:[2, 3, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(3, 1) withObjectsFromArray:[arrayClass array]];
    [self assert:[2, 3, 4] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 3) withObjectsFromArray:[5, 4, 3, 2, 1]];
    [self assert:[5, 4, 3, 2, 1] equals:array];

    [array replaceObjectsInRange:CPMakeRange(2, 0) withObjectsFromArray:[5, 4, 3, 2, 1]];
    [self assert:[5, 4, 5, 4, 3, 2, 1, 3, 2, 1] equals:array];

    [array replaceObjectsInRange:CPMakeRange(2, 5) withObjectsFromArray:[1]];
    [self assert:[5, 4, 1, 3, 2, 1] equals:array];

    [array replaceObjectsInRange:CPMakeRange(3, 3) withObjectsFromArray:[1, 4, 5]];
    [self assert:[5, 4, 1, 1, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 3) withObjectsFromArray:[1, 4, 5]];
    [self assert:[1, 4, 5, 1, 4, 5] equals:array];
}

- (void)test_replaceObjectsInRange_withObjectFromArray_range_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:1, 2, 3, 4, 5];

    [array replaceObjectsInRange:CPMakeRange(0, 0) withObjectsFromArray:[arrayClass array] range:CPMakeRange(0, 0)];
    [self assert:[1, 2, 3, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 1) withObjectsFromArray:[arrayClass array] range:CPMakeRange(0, 0)];
    [self assert:[2, 3, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(3, 1) withObjectsFromArray:[arrayClass array] range:CPMakeRange(0, 0)];
    [self assert:[2, 3, 4] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 3) withObjectsFromArray:[5, 4, 3, 2, 1] range:CPMakeRange(1, 3)];
    [self assert:[4, 3, 2] equals:array];

    [array replaceObjectsInRange:CPMakeRange(2, 0) withObjectsFromArray:[5, 4, 3, 2, 1] range:CPMakeRange(4, 1)];
    [self assert:[4, 3, 1, 2] equals:array];

    [array replaceObjectsInRange:CPMakeRange(1, 2) withObjectsFromArray:[5] range:CPMakeRange(0, 0)];
    [self assert:[4, 2] equals:array];

    [array replaceObjectsInRange:CPMakeRange(1, 1) withObjectsFromArray:[1, 4, 5] range:CPMakeRange(0, 3)];
    [self assert:[4, 1, 4, 5] equals:array];

    [array replaceObjectsInRange:CPMakeRange(0, 3) withObjectsFromArray:[1, 4, 5] range:CPMakeRange(1, 1)];
    [self assert:[4, 5] equals:array];
}

- (void)test_exchangeObjectAtIndex_withObjectAtIndex_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:1, 2, 3, 4, 5];

    [array exchangeObjectAtIndex:0 withObjectAtIndex:0];
    [self assert:[1, 2, 3, 4, 5] equals:array];

    [array exchangeObjectAtIndex:0 withObjectAtIndex:1];
    [self assert:[2, 1, 3, 4, 5] equals:array];

    [array exchangeObjectAtIndex:1 withObjectAtIndex:3];
    [self assert:[2, 4, 3, 1, 5] equals:array];

    [array exchangeObjectAtIndex:1 withObjectAtIndex:3];
    [self assert:[2, 1, 3, 4, 5] equals:array];

    [array exchangeObjectAtIndex:4 withObjectAtIndex:2];
    [self assert:[2, 1, 5, 4, 3] equals:array];
}

// Old Tests
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

    [self assert:"@[\n    3:d,\n    2:c,\n    1:b,\n    0:a\n]" equals:[pretty description]];

    [pretty sortUsingDescriptors:[[[CPSortDescriptor alloc] initWithKey:@"value" ascending:YES]]];

    [self assert:"@[\n    0:a,\n    1:b,\n    2:c,\n    3:d\n]" equals:[pretty description]];
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

- (void)testMutableCopy
{
    var normalArray = [],
        mutableArray = [normalArray mutableCopy];

    [mutableArray addObject:[CPNull null]];

    [self assert:1 equals:[mutableArray count] message:"mutable copy should have content"];
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

@implementation ConcreteMutableArray : CPMutableArray
{
    Array   array;
}

- (id)initWithObjects:(id)anObject, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    array = Array.prototype.slice.call(arguments, 2, index);

    return self;
}

- (id)init
{
    self = [super init];

    if (self)
        array = [];

    return self;
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];

    if (self)
        array = [anArray copy];

    return self;
}

- (CPUInteger)count
{
    return array.length;
}

- (id)objectAtIndex:(CPUInteger)anIndex
{
    if (anIndex < 0 || anIndex >= [self count])
        throw "range error";

    return array[anIndex];
}

- (void)insertObject:(id)anObject atIndex:(CPUInteger)anIndex
{
    array.splice(anIndex, 0, anObject);
}

- (void)removeObjectAtIndex:(CPUInteger)anIndex
{
    array.splice(anIndex, 1);
}

- (void)addObject:(id)anObject
{
    array.push(anObject);
}

- (void)removeLastObject
{
    array.pop();
}

- (void)replaceObjectAtIndex:(CPUInteger)anIndex withObject:(id)anObject
{
    array[anIndex] = anObject;
}

@end
