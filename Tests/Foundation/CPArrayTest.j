@import <Foundation/Foundation.j>

@import <OJUnit/OJTestCase.j>

@implementation CPArrayTest : OJTestCase
{
}

+ (Class)arrayClass
{
    return ConcreteArray;
}

- (void)test_containsObject_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:0, @"hello", [AlwaysEqual new], [arrayClass arrayWithObjects:0]];

    [self assertTrue:[array containsObject:0]];
    [self assertTrue:[array containsObject:@"hello"]];
    [self assertTrue:[array containsObject:[AlwaysEqual new]]]; // test isEqual:
    [self assertTrue:[array containsObject:[arrayClass arrayWithObjects:0]]];

    [self assertFalse:[array containsObject:1]];
    [self assertFalse:[array containsObject:@"bye"]];
    [self assertFalse:[array containsObject:[arrayClass arrayWithObjects:1]]];
}

- (void)test_containsObjectIdenticalTo_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:0, @"hello", [AlwaysEqual new], [arrayClass arrayWithObjects:0]];

    [self assertTrue:[array containsObjectIdenticalTo:0]];
    [self assertTrue:[array containsObjectIdenticalTo:@"hello"]];

    [self assertFalse:[array containsObjectIdenticalTo:1]];
    [self assertFalse:[array containsObjectIdenticalTo:@"bye"]];
    [self assertFalse:[array containsObjectIdenticalTo:[AlwaysEqual new]]];
    [self assertFalse:[array containsObjectIdenticalTo:[arrayClass arrayWithObjects:0]]];
    [self assertFalse:[array containsObjectIdenticalTo:[arrayClass arrayWithObjects:1]]];
}

- (void)test_count
{
    var arrayClass = [[self class] arrayClass];

    [self assert:[[arrayClass array] count] same:0];
    [self assert:[[arrayClass arrayWithObjects:0, 1, 2] count] same:3];
    [self assert:[[arrayClass arrayWithObjects:0, 1, 2, nil] count] same:3];
    [self assert:[[arrayClass arrayWithObjects:0, 1, nil, 2, nil] count] same:2];
}

- (void)test_firstObject
{
    var arrayClass = [[self class] arrayClass];

    [self assert:[[arrayClass array] firstObject] same:nil];
    [self assert:[[arrayClass arrayWithObjects:0, 1, 2] firstObject] same:0];
}

- (void)test_lastObject
{
    var arrayClass = [[self class] arrayClass];

    [self assert:[[arrayClass array] lastObject] same:nil];
    [self assert:[[arrayClass arrayWithObjects:0, 1, 2] lastObject] same:2];
    [self assert:[[arrayClass arrayWithObjects:0, 1, 2, nil] lastObject] same:2];
    [self assert:[[arrayClass arrayWithObjects:0, 1, nil, 2, nil] lastObject] same:1];
}

- (void)test_objectAtIndex_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [self assertThrows:function () { [array objectAtIndex:-1] }];
    [self assertThrows:function () { [array objectAtIndex:0] }];

    var array = [arrayClass arrayWithObjects:0, 1, 2];

    [self assertThrows:function () { [array objectAtIndex:-1] }];
    [self assert:[array objectAtIndex:0] same:0];
    [self assert:[array objectAtIndex:1] same:1];
    [self assert:[array objectAtIndex:2] same:2];
    [self assertThrows:function () { [array objectAtIndex:3] }];
}

- (void)test_objectsAtIndexes_
{
    function rangeIndexes(location, length)
    {
        return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(location, length)];
    }

    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [self assertThrows:function () { [array objectsAtIndexes:rangeIndexes(0, 1)] }];

    var array = [arrayClass arrayWithObjects:0, 1, 2];

    [self assert:[array objectsAtIndexes:rangeIndexes(0, 1)] equals:[0]];
    [self assert:[array objectsAtIndexes:rangeIndexes(0, 2)] equals:[0, 1]];
    [self assert:[array objectsAtIndexes:rangeIndexes(0, 3)] equals:[0, 1, 2]];
    [self assertThrows:function () { [array objectsAtIndexes:rangeIndexes(0, 4)] }];
    [self assert:[array objectsAtIndexes:rangeIndexes(1, 1)] equals:[1]];
    [self assert:[array objectsAtIndexes:rangeIndexes(1, 2)] equals:[1, 2]];
    [self assertThrows:function () { [array objectsAtIndexes:rangeIndexes(1, 3)] }];
    [self assertThrows:function () { [array objectsAtIndexes:rangeIndexes(3, 1)] }];
}

- (void)test_indexOfObject_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [self assert:[array indexOfObject:0] same:CPNotFound];

    var innerArray = [arrayClass arrayWithObjects:0];

    array = [arrayClass arrayWithObjects:0, @"hello", [AlwaysEqual new], innerArray];

    [self assert:[array indexOfObject:0] same:0];
    [self assert:[array indexOfObject:@"hello"] same:1];
    [self assert:[array indexOfObject:[AlwaysEqual new]] same:2];
    [self assert:[array indexOfObject:innerArray] same:3];
    [self assert:[array indexOfObject:[arrayClass arrayWithObjects:0]] same:3];

    [self assert:[array indexOfObject:1] same:CPNotFound];
    [self assert:[array indexOfObject:@"bye"] same:CPNotFound];
}

- (void)test_indexOfObjectIdenticalTo_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array];

    [self assert:[array indexOfObject:0] same:CPNotFound];

    var innerArray = [arrayClass arrayWithObjects:0];

    array = [arrayClass arrayWithObjects:0, @"hello", [AlwaysEqual new], innerArray];

    [self assert:[array indexOfObjectIdenticalTo:0] same:0];
    [self assert:[array indexOfObjectIdenticalTo:@"hello"] same:1];
    [self assert:[array indexOfObjectIdenticalTo:[AlwaysEqual new]] same:CPNotFound];
    [self assert:[array indexOfObjectIdenticalTo:innerArray] same:3];
    [self assert:[array indexOfObjectIdenticalTo:[arrayClass arrayWithObjects:0]] same:CPNotFound];

    [self assert:[array indexOfObjectIdenticalTo:1] same:CPNotFound];
    [self assert:[array indexOfObjectIdenticalTo:@"bye"] same:CPNotFound];
}

- (void)test_indexOfObjectPassingTest_
{
    var array = [[[self class] arrayClass] arrayWithObjects:
            { name:@"Tom", age:7 },
            { name:@"Dick", age:13 },
            { name:@"Harry", age:27 },
            { name:@"Zelda", age:7 }];

    [self assert:[array indexOfObjectPassingTest:function() { return YES; }] same:0];
    [self assert:[array indexOfObjectPassingTest:function() { return NO; }] same:CPNotFound];
    [self assert:[array indexOfObjectPassingTest:function() { return nil; }] same:CPNotFound];

    [self assert:[array indexOfObjectPassingTest:function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Harry"];
                        }] same:2];

    [self assert:[array indexOfObjectPassingTest:function(anObject, anIndex)
                        {
                            return anObject.age === 13;
                        }] equals:1];

    [self assert:[array indexOfObjectPassingTest:function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Horton"];
                        }] equals:CPNotFound];
}

- (void)test_indexOfObjectPassingTest_context_
{
    var array = [[[self class] arrayClass] arrayWithObjects:
            { name:@"Tom", age:7 },
            { name:@"Dick", age:13 },
            { name:@"Harry", age:27 },
            { name:@"Zelda", age:7 }];

    [self assert:[array indexOfObjectPassingTest:function(anObject, anIndex, aContext)
                        {
                            return [anObject.name isEqual:aContext];
                        } context:@"Harry"] same:2];

    [self assert:[array indexOfObjectPassingTest:function(anObject, anIndex, aContext)
                        {
                            return anObject.age === aContext;
                        } context:13] same:1];
}

- (void)test_indexOfObjectWithOptions_passingTest
{
    var array = [[[self class] arrayClass] arrayWithObjects:
        { name:@"Tom", age:7 },
        { name:@"Dick", age:13 },
        { name:@"Harry", age:27 },
        { name:@"Zelda", age:7 }],
        namePredicate = function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Harry"];
                        },
        agePredicate =  function(anObject, anIndex)
                        {
                            return anObject.age === 7;
                        };

    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:namePredicate] same:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:namePredicate] same:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:agePredicate] same:0];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:agePredicate] same:3];
}

- (void)test_indexOfObjectWithOptions_passingTest_context
{
    var array = [[[self class] arrayClass] arrayWithObjects:
        { name:@"Tom", age:7 },
        { name:@"Dick", age:13 },
        { name:@"Harry", age:27 },
        { name:@"Zelda", age:7 }],
        namePredicate = function(anObject, anIndex, aContext)
                        {
                            return [anObject.name isEqual:aContext];
                        },
        agePredicate =  function(anObject, anIndex, aContext)
                        {
                            return anObject.age === aContext;
                        };

    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:namePredicate context:@"Harry"] same:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:namePredicate context:@"Harry"] same:2];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationNormal passingTest:agePredicate context:7] same:0];
    [self assert:[array indexOfObjectWithOptions:CPEnumerationReverse passingTest:agePredicate context:7] same:3];
}

- (void)test_indexOfObject_inSortedRange_options_usingComparator_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass arrayWithObjects:0, 1, 1, 1, 2, 2, 3, 3, 4, 4, 7],
        arraySimple = [arrayClass arrayWithObjects:4, 5, 7, 8, 9, 10],
        numComparator = function(lhs, rhs) { return lhs - rhs; },
        index;

    index = [arraySimple indexOfObject:7
                         inSortedRange:nil
                               options:0
                       usingComparator:numComparator];
    [self assert:2 equals:index message:"simple index of 7"];

    index = [[arraySimple arrayByReversingArray] indexOfObject:7
                                                 inSortedRange:nil
                                                       options:0
                                               usingComparator: function(a, b) { return b - a; }];
    [self assert:3 equals:index message:"simple index of 7 reversed"];

    index = [arraySimple indexOfObject:6
                         inSortedRange:nil
                               options:0
                       usingComparator:numComparator];
    [self assert:CPNotFound equals:index message:"simple index of non existent value"];

    index = [arraySimple indexOfObject:6
                         inSortedRange:nil
                               options:CPBinarySearchingInsertionIndex
                       usingComparator:numComparator];
    [self assert:2 equals:index message:"simple insertion index of non existent value"];

    index = [arraySimple indexOfObject:6
                         inSortedRange:CPMakeRange(3, 2) // [ -, -, -, 7, 8]
                               options:CPBinarySearchingInsertionIndex
                       usingComparator:numComparator];
    [self assert:3 equals:index message:"simple insertion index with range"];

    index = [array indexOfObject:1
                       inSortedRange:nil
                             options:0
                     usingComparator:numComparator];
    [self assertTrue:[[1, 2, 3] containsObject:index]];
    [self assert:[array indexOfObject:1
                        inSortedRange:nil
                              options:CPBinarySearchingFirstEqual
                      usingComparator:numComparator]
          equals:1 message:"binary search first equal to 1"];
    [self assert:[array indexOfObject:1
                        inSortedRange:nil
                              options:CPBinarySearchingLastEqual
                      usingComparator:numComparator]
          equals:3];
    index = [array indexOfObject:1
                   inSortedRange:nil
                         options:CPBinarySearchingInsertionIndex
                 usingComparator:numComparator];
    [self assertTrue:[[1, 2, 3, 4] containsObject:index]];
    [self assert:[array indexOfObject:1
                        inSortedRange:nil
                              options:CPBinarySearchingFirstEqual | CPBinarySearchingInsertionIndex
                      usingComparator:numComparator]
          equals:1];
    [self assert:[array indexOfObject:1
                        inSortedRange:nil
                              options:CPBinarySearchingLastEqual | CPBinarySearchingInsertionIndex
                      usingComparator:numComparator]
          equals:4 message:"last equal insertion index"];

    index = [array indexOfObject:2
                   inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                         options:0
                 usingComparator:numComparator];
    [self assertTrue:[[4, 5] containsObject:index]];
    [self assert:[array indexOfObject:2
                        inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                              options:CPBinarySearchingFirstEqual
                      usingComparator:numComparator]
          equals:4 message:"first equal in range 2-7"];
    [self assert:[array indexOfObject:2
                        inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                              options:CPBinarySearchingLastEqual
                      usingComparator:numComparator]
          equals:5];
    index = [array indexOfObject:2
                   inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                         options:CPBinarySearchingInsertionIndex
                 usingComparator:numComparator];
    [self assertTrue:[[4, 5, 6] containsObject:index]];
    [self assert:[array indexOfObject:2
                        inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                              options:CPBinarySearchingFirstEqual | CPBinarySearchingInsertionIndex
                      usingComparator:numComparator]
          equals:4 message:"first equal insertion index in range 2-7"];
    [self assert:[array indexOfObject:2
                        inSortedRange:CPMakeRange(2, 5) // [ -, -, 1, 1, 2, 2, 3, -, -, -, -]
                              options:CPBinarySearchingLastEqual | CPBinarySearchingInsertionIndex
                      usingComparator:numComparator]
          equals:6];

    [self assert:[array indexOfObject:3
                      inSortedRange:CPMakeRange(2, 6) // [ -, -, 1, 1, 2, 2, 3, 3, -, -, -]
                            options:CPBinarySearchingLastEqual | CPBinarySearchingInsertionIndex
                    usingComparator:numComparator]
        equals:8 message:"inserting index at end of range"];

    [self assert:[[1, 2, 2] indexOfObject:2
                            inSortedRange:CPMakeRange(0, 2) // [1, 2]
                                  options:CPBinarySearchingLastEqual | CPBinarySearchingInsertionIndex
                          usingComparator:numComparator]
          equals:2 message:"insertion index should not be off by one when applying a range"];

}

- (void)test_indexesOfObjectsPassingTest_
{
    var array = [[[self class] arrayClass] arrayWithObjects:
            { name:@"Tom", age:7 },
            { name:@"Dick", age:13 },
            { name:@"Harry", age:27 },
            { name:@"Zelda", age:7 }];

    [self assert:[array indexesOfObjectsPassingTest:function() { return YES; }] equals:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 4)]];
    [self assert:[array indexesOfObjectsPassingTest:function() { return NO; }] equals:[CPIndexSet indexSet]];
    [self assert:[array indexesOfObjectsPassingTest:function() { return nil; }] equals:[CPIndexSet indexSet]];

    [self assert:[array indexesOfObjectsPassingTest:function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Harry"];
                        }] equals:[CPIndexSet indexSetWithIndex:2]];

    var indexSet = [CPIndexSet indexSetWithIndex:0];
    [indexSet addIndex:3];

    [self assert:[array indexesOfObjectsPassingTest:function(anObject, anIndex)
                        {
                            return anObject.age === 7;
                        }] equals:indexSet];

    [self assert:[array indexesOfObjectsPassingTest:function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Horton"];
                        }] equals:[CPIndexSet indexSet]];
}

- (void)test_indexesOfObjectsPassingTest_context_
{
    var array = [[[self class] arrayClass] arrayWithObjects:
            { name:@"Tom", age:7 },
            { name:@"Dick", age:13 },
            { name:@"Harry", age:27 },
            { name:@"Zelda", age:7 }];

    [self assert:[array indexesOfObjectsPassingTest:function(anObject, anIndex, aContext)
                        {
                            return [anObject.name isEqual:aContext];
                        } context:@"Harry"] equals:[CPIndexSet indexSetWithIndex:2]];

    var indexSet = [CPIndexSet indexSetWithIndex:0];
    [indexSet addIndex:3];

    [self assert:[array indexesOfObjectsPassingTest:function(anObject, anIndex, aContext)
                        {
                            return anObject.age === aContext;
                        } context:7] equals:indexSet];
}

- (void)test_indexesOfObjectsWithOptions_passingTest
{
    var array = [[[self class] arrayClass] arrayWithObjects:
        { name:@"Tom", age:7 },
        { name:@"Dick", age:13 },
        { name:@"Harry", age:27 },
        { name:@"Zelda", age:7 }],
        namePredicate = function(anObject, anIndex)
                        {
                            return [anObject.name isEqual:@"Harry"];
                        },
        agePredicate =  function(anObject, anIndex)
                        {
                            return anObject.age === 7;
                        };

    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:namePredicate] equals:[CPIndexSet indexSetWithIndex:2]];
    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationReverse passingTest:namePredicate] equals:[CPIndexSet indexSetWithIndex:2]];

    var indexSet = [CPIndexSet indexSetWithIndex:0];
    [indexSet addIndex:3];

    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:agePredicate] equals:indexSet];
    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationReverse passingTest:agePredicate] equals:indexSet];
}

- (void)test_indexesOfObjectsWithOptions_passingTest_context
{
    var array = [[[self class] arrayClass] arrayWithObjects:
        { name:@"Tom", age:7 },
        { name:@"Dick", age:13 },
        { name:@"Harry", age:27 },
        { name:@"Zelda", age:7 }],
        namePredicate = function(anObject, anIndex, aContext)
                        {
                            return [anObject.name isEqual:aContext];
                        },
        agePredicate =  function(anObject, anIndex, aContext)
                        {
                            return anObject.age === aContext;
                        };

    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:namePredicate context:@"Harry"] equals:[CPIndexSet indexSetWithIndex:2]];
    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationReverse passingTest:namePredicate context:@"Harry"] equals:[CPIndexSet indexSetWithIndex:2]];

    var indexSet = [CPIndexSet indexSetWithIndex:0];
    [indexSet addIndex:3];

    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:agePredicate context:7] equals:indexSet];
    [self assert:[array indexesOfObjectsWithOptions:CPEnumerationReverse passingTest:agePredicate context:7] equals:indexSet];
}

- (void)test_isEqualToArray_
{
    var arrayClass = [[self class] arrayClass],
        lhs = [arrayClass arrayWithObjects:1, @"hello", [AlwaysEqual new], [arrayClass arrayWithObjects:1]],
        rhs = [arrayClass arrayWithObjects:1, @"hello", [AlwaysEqual new], [arrayClass arrayWithObjects:1]];

    [self assertTrue:[lhs isEqualToArray:lhs]];
    [self assertTrue:[rhs isEqualToArray:rhs]];
    [self assertFalse:[lhs isEqualToArray:nil]];
    [self assertFalse:[rhs isEqualToArray:nil]];
    [self assertTrue:[lhs isEqualToArray:rhs]];
    [self assertTrue:[rhs isEqualToArray:lhs]];

    lhs = [arrayClass arrayWithObjects:1];
    rhs = [arrayClass array];

    [self assertTrue:[lhs isEqualToArray:lhs]];
    [self assertTrue:[rhs isEqualToArray:rhs]];
    [self assertFalse:[lhs isEqualToArray:nil]];
    [self assertFalse:[rhs isEqualToArray:nil]];
    [self assertFalse:[lhs isEqualToArray:rhs]];
    [self assertFalse:[rhs isEqualToArray:lhs]];

    lhs = [arrayClass arrayWithObjects:1, 2, 3];
    rhs = [arrayClass arrayWithObjects:3, 2, 1];

    [self assertTrue:[lhs isEqualToArray:lhs]];
    [self assertTrue:[rhs isEqualToArray:rhs]];
    [self assertFalse:[lhs isEqualToArray:nil]];
    [self assertFalse:[rhs isEqualToArray:nil]];
    [self assertFalse:[lhs isEqualToArray:rhs]];
    [self assertFalse:[rhs isEqualToArray:lhs]];

    lhs = [arrayClass arrayWithObjects:1, 2, 3];
    rhs = [arrayClass arrayWithObjects:5];

    [self assertTrue:[lhs isEqualToArray:lhs]];
    [self assertTrue:[rhs isEqualToArray:rhs]];
    [self assertFalse:[lhs isEqualToArray:nil]];
    [self assertFalse:[rhs isEqualToArray:nil]];
    [self assertFalse:[lhs isEqualToArray:rhs]];
    [self assertFalse:[rhs isEqualToArray:lhs]];
}

- (void)test_arrayByAddingObject_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array],
        nextArray = [array arrayByAddingObject:0];

    [self assert:[array count] same:0];
    [self assert:[nextArray count] same:1];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:0]];

    array = nextArray;
    nextArray = [array arrayByAddingObject:1];

    [self assert:[array count] same:1];
    [self assert:[nextArray count] same:2];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:0, 1]];

    array = nextArray;
    nextArray = [array arrayByAddingObject:[arrayClass arrayWithObjects:1, 3]];

    [self assert:[array count] same:2];
    [self assert:[nextArray count] same:3];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:0, 1, [arrayClass arrayWithObjects:1, 3]]];

    return array;
}

- (void)test_arrayByAddingObjectFromArray_
{
    var arrayClass = [[self class] arrayClass],
        array = [arrayClass array],
        otherArray = [arrayClass array],
        nextArray = [array arrayByAddingObjectsFromArray:otherArray];

    [self assert:[array count] same:0];
    [self assert:[nextArray count] same:0];
    [self assert:array equals:[arrayClass array]];
    [self assert:otherArray equals:[arrayClass array]];
    [self assert:array equals:nextArray];

    otherArray = [arrayClass arrayWithObjects:1, 2, 3];
    nextArray = [array arrayByAddingObjectsFromArray:otherArray];

    [self assert:[array count] same:0];
    [self assert:[otherArray count] same:3];
    [self assert:[nextArray count] same:3];
    [self assert:array equals:[arrayClass array]];
    [self assert:otherArray equals:[arrayClass arrayWithObjects:1, 2, 3]];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:1, 2, 3]];

    array = nextArray;
    otherArray = [arrayClass arrayWithObjects:5];
    nextArray = [array arrayByAddingObjectsFromArray:otherArray];

    [self assert:[array count] same:3];
    [self assert:[otherArray count] same:1];
    [self assert:[nextArray count] same:4];
    [self assert:array equals:[arrayClass arrayWithObjects:1, 2, 3]];
    [self assert:otherArray equals:[arrayClass arrayWithObjects:5]];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:1, 2, 3, 5]];

    array = nextArray;
    otherArray = [1, 2, 3];
    nextArray = [array arrayByAddingObjectsFromArray:otherArray];

    [self assert:[array count] same:4];
    [self assert:[otherArray count] same:3];
    [self assert:[nextArray count] same:7];
    [self assert:array equals:[arrayClass arrayWithObjects:1, 2, 3, 5]];
    [self assert:otherArray equals:[arrayClass arrayWithObjects:1, 2, 3]];
    [self assert:nextArray equals:[arrayClass arrayWithObjects:1, 2, 3, 5, 1, 2, 3]];

    return array;
}

- (void)test_componentsJoinedByString_
{
    var arrayClass = [[self class] arrayClass],
        tests = [
                    [[arrayClass array], "", ""],
                    [[arrayClass array], "-", ""],
                    [[arrayClass arrayWithObjects:1, 2], "-", "1-2"],
                    [[arrayClass arrayWithObjects:1, 2, 3], "-", "1-2-3"],
                    [[arrayClass arrayWithObjects:"123", 456], "-", "123-456"]
                ],
        index = 0,
        count = tests.length;

    for (; index < count; ++index)
        [self assert:[tests[index][0] componentsJoinedByString:tests[index][1]] equals:tests[index][2]];
}

- (void)testEnumateObjectsUsingBlock_
{
    var input0 = [],
        input1 = [1, 3, "b"],
        output = [CPMutableDictionary dictionary],
        outputFunction = function(anObject, idx)
        {
            [output setValue:anObject forKey:"" + idx];
        };

    [input0 enumerateObjectsUsingBlock:outputFunction];
    [self assert:0 equals:[output count] message:@"output when enumerating empty array"];

    [input1 enumerateObjectsUsingBlock:outputFunction];
    [self assert:3 equals:[output count] message:@"output when enumerating input1"];
    [self assert:input1[0] equals:[output valueForKey:"0"] message:@"output[0]"];
    [self assert:input1[1] equals:[output valueForKey:"1"] message:@"output[0]"];
    [self assert:input1[2] equals:[output valueForKey:"2"] message:@"output[0]"];

    var stoppingFunction = function(anObject, idx, stop)
    {
        [output setValue:anObject forKey:"" + idx];
        if ([output count] > 1)
            @deref(stop) = YES;
    }
    output = [CPMutableDictionary dictionary];

    [input1 enumerateObjectsUsingBlock:stoppingFunction];
    [self assert:2 equals:[output count] message:@"output when enumerating input1 and stopping after 2"];
    [self assert:input1[0] equals:[output valueForKey:"0"] message:@"output[0]"];
    [self assert:input1[1] equals:[output valueForKey:"1"] message:@"output[0]"];
}

- (void)testJSObjectDescription
{
    var array = [CGRectMake(1, 2, 3, 4), CGPointMake(5, 6)],
        d = [array description];

    [self assertTrue:d.indexOf("(1, 2)") !== -1 message:"Can't find '(1, 2)' in description of array " + d];
    [self assertTrue:d.indexOf("(3, 4)") !== -1 message:"Can't find '(3, 4)' in description of array " + d];
    [self assertTrue:d.indexOf("(5, 6)") !== -1 message:"Can't find '(5, 6)' in description of array " + d];
}

- (void)testSortUsingDescriptorsWithDifferentSelectors
{
    var a = [CPDictionary dictionaryWithJSObject:{"a": "AB", "b": "ba"}],
        b = [CPDictionary dictionaryWithJSObject:{"a": "aa", "b": "BB"}],
        array = [a, b],
        d1 = [[CPSortDescriptor sortDescriptorWithKey:@"a" ascending:YES selector:@selector(compare:)]],
        d2 = [[CPSortDescriptor sortDescriptorWithKey:@"a" ascending:YES selector:@selector(caseInsensitiveCompare:)]],
        s1 = [array sortedArrayUsingDescriptors:d1],
        s2 = [array sortedArrayUsingDescriptors:d2];

    [self assertTrue:s1[0] === a message:s1[0] + " is larger then " + a + " when sorting case sensitive"];
    [self assertTrue:s2[1] === a message:s2[1] + " is larger then " + a + " when sorting case insensitive"];
}

- (void)testSortUsingDescriptorsWithKeyPath
{
    var a = [CPDictionary dictionaryWithJSObject:{"a": "AB", "b": "ba"}],
        b = [CPDictionary dictionaryWithJSObject:{"a": "aa", "b": "BB"}],
        A = [CPDictionary dictionaryWithJSObject:{"x": a}],
        B = [CPDictionary dictionaryWithJSObject:{"x": b}],
        array = [A, B],
        d1 = [[CPSortDescriptor sortDescriptorWithKey:@"x.b" ascending:YES selector:@selector(compare:)]],
        d2 = [[CPSortDescriptor sortDescriptorWithKey:@"x.b" ascending:NO selector:@selector(compare:)]],
        s1 = [array sortedArrayUsingDescriptors:d1],
        s2 = [array sortedArrayUsingDescriptors:d2];

    [self assertTrue:s1[1] === A message:s1[1] + " is larger then " + A + " when sorting ascending"];
    [self assertTrue:s2[0] === A message:s2[0] + " is larger then " + A + " when sorting descending"];
}

- (void)testDisallowObservers
{
    var anArray = [CPArray arrayWithObject:0];

    [self assertThrows:function() { [anArray addObserver:self forKeyPath:@"self" options:0 context:nil]; }];
    [self assertThrows:function() { [anArray removeObserver:self forKeyPath:@"self"]; }];
}

- (void)testArrayLiteral
{
  var anArray = @[1, [CPNull null], @"3"];

  [self assert:[1, [CPNull null], "3"] equals:anArray];
}

@end

@implementation AlwaysEqual : CPObject
{
}

- (BOOL)isEqual:(id)anObject
{
    return [anObject isKindOfClass:AlwaysEqual];
}

@end

@implementation CPArray (TestingAdditions)

- (CPArray)arrayByReversingArray
{
    var args = [[self class], @selector(arrayWithObjects:)],
        index = [self count];

    while (index--)
        args.push([self objectAtIndex:index]);

    return objj_msgSend.apply(this, args);
}

@end

@implementation ConcreteArray : CPArray
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

@end
