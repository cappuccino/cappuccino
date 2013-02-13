var COUNTER;

@implementation CPKVCArrayTest : OJTestCase
{
    TestObject              _object @accessors(property=object);
    ImplementedTestObject   _implementedObject @accessors(property=implementedObject);
    CPArray                 _kvcArray @accessors(property=kvcArray);
}

- (void)setUp
{
    _object = [[TestObject alloc] init];
    _implementedObject = [[ImplementedTestObject alloc] init];

    COUNTER = 0;
}

- (void)_patchSelector:(SEL)selectors, ...
{
    var method_dtable = [[self object] class].method_dtable,
        method_list = [[self object] class].method_list,
        selectorsToRemove = [@selector(countOfValues), @selector(objectInValuesAtIndex),
                                @selector(objectInValuesAtIndex:), @selector(valuesAtIndexes:),
                                @selector(insertObject:inValuesAtIndex:), @selector(insertValues:atIndexes:),
                                @selector(removeObjectFromValuesAtIndex:), @selector(removeValuesAtIndexes:),
                                @selector(removeObjectFromValuesAtIndex:),
                                @selector(replaceObjectInValuesAtIndex:withObject:),
                                @selector(replaceValuesAtIndexes:withValues:)],
        selectorIndex = [selectorsToRemove count];

    while (selectorIndex--)
    {
        var selector = [selectorsToRemove objectAtIndex:selectorIndex],
            implementation = method_dtable[selector];

        if (!implementation)
            continue;

        delete method_dtable[selector]
        [method_list removeObject:implementation];
    }

    for (var i = 2; i < arguments.length; i++)
    {
        var theSelector = arguments[i],
            method = class_getInstanceMethod([[self implementedObject] class], theSelector),
            implementation = method_getImplementation(method);

        class_addMethod([[self object] class], theSelector, implementation);
    }
}

- (void)testUsesCountOfKey
{
    [self _patchSelector:@selector(countOfValues)];

    var count = [[[self object] mutableArrayValueForKey:@"values"] count];

    [self assert:10 equals:count message:@"countOfValues should return 10"];
    [self assert:1 equals:COUNTER message:@"countOfValues should have been called once"]
}

- (void)testObjectAtIndexUsesObjectInKeyAtIndex
{
    [self _patchSelector:@selector(objectInValuesAtIndex:)];

    var values = [[self object] mutableArrayValueForKey:@"values"],
        object = [values objectAtIndex:0];

    [self assert:0 equals:object]
    [self assert:1 equals:COUNTER message:@"objectInValuesAtIndex: should have been called once"];
}

- (void)testObjectsAtIndexesUsesObjectInKeyAtIndex
{
    [self _patchSelector:@selector(objectInValuesAtIndex:)];

    var values = [[self object] mutableArrayValueForKey:@"values"],
        objects = [values objectsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    [self assert:[0, 1] equals:objects]
    [self assert:2 equals:COUNTER message:@"objectInValuesAtIndex: should have been called once"];
}

- (void)testObjectAtIndexUsesKeyAtIndexes
{
    [self _patchSelector:@selector(valuesAtIndexes:)];

    var values = [[self object] mutableArrayValueForKey:@"values"],
        object = [values objectAtIndex:0];

    [self assert:0 equals:object]
    [self assert:1 equals:COUNTER message:@"valuesAtIndexes: should have been called once"];
}

- (void)testObjectsAtIndexesUsesKeyAtIndexes
{
    [self _patchSelector:@selector(valuesAtIndexes:)];

    var values = [[self object] mutableArrayValueForKey:@"values"],
        objects = [values objectsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    [self assert:[0, 1] equals:objects]
    [self assert:1 equals:COUNTER message:@"valuesAtIndexes: should have been called once"];
}

- (void)testInsertObjectAtIndexUsesInsertKeyAtIndex
{
    [self _patchSelector:@selector(insertObject:inValuesAtIndex:)];

    [[[self object] mutableArrayValueForKey:@"values"] insertObject:11 atIndex:10];

    [self assert:11 equals:[[[self object] values] objectAtIndex:10]];
    [self assert:1 equals:COUNTER message:@"insertObject:inValuesAtIndex: should have been called once"];
}

- (void)testInsertObjectsAtIndexesUsesInsertKeyAtIndex
{
    [self _patchSelector:@selector(insertObject:inValuesAtIndex:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 2)];
    [[[self object] mutableArrayValueForKey:@"values"] insertObjects:[11, 12] atIndexes:indexes];

    [self assert:[11, 12] equals:[[[self object] values] objectsAtIndexes:indexes]];
    [self assert:2
          equals:COUNTER
         message:@"insertValues:atIndexes: should have been called once for each object"];
}

- (void)testInsertObjectAtIndexUsesInsertKeyAtIndexes
{
    [self _patchSelector:@selector(insertValues:atIndexes:)];

    [[[self object] mutableArrayValueForKey:@"values"] insertObject:11 atIndex:10];

    [self assert:11 equals:[[[self object] values] objectAtIndex:10]];
    [self assert:1 equals:COUNTER message:@"insertValues:atIndexes: should have been called once"];
}

- (void)testInsertObjectsAtIndexesUsesInsertKeyAtIndexes
{
    [self _patchSelector:@selector(insertValues:atIndexes:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(10, 2)];
    [[[self object] mutableArrayValueForKey:@"values"] insertObjects:[11, 12] atIndexes:indexes];

    [self assert:[11, 12] equals:[[[self object] values] objectsAtIndexes:indexes]];
    [self assert:1
          equals:COUNTER
         message:@"insertValues:atIndexes: should have been called once for each object"];
}

- (void)testRemoveObjectAtIndexUsesRemoveObjectFromKeyAtIndex
{
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObjectAtIndex:0];

    [self assert:[1, 2, 3, 4, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:@"removeObjectFromValuesAtIndex: should have been called once"];
}

- (void)testRemoveObjectAtIndexesUsesRemoveObjectFromKeyAtIndex
{
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)];
    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsAtIndexes:indexes];

    [self assert:[2, 3, 4, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:2 equals:COUNTER message:@"removeValuesAtIndex: should have been called once for each object"];
}
- (void)testRemoveObjectsAtIndexesUsesRemoveKeyAtIndex
{
    [self _patchSelector:@selector(removeValuesAtIndexes:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObjectAtIndex:0];

    [self assert:[1, 2, 3, 4, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1
          equals:COUNTER
         message:@"removeValuesAtIndexes: should have been once for each object"];
}

- (void)testRemoveObjectsAtIndexesUsesRemoveKeyAtIndexes
{
    [self _patchSelector:@selector(removeValuesAtIndexes:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(3, 2)];
    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsAtIndexes:indexes];

    [self assert:[0, 1, 2, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:@"removeValuesAtIndexes: should have been called once"];
}

- (void)testRemoveObjectUsesRemoveKeyAtIndex
{
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObject:1];

    [self assert:[0, 2, 3, 4, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:"removeObjectFromValuesAtIndex: should have been called once"]
}

- (void)testeRemoveObjectUsesRemoveKeyAtIndexes
{
    [self _patchSelector:@selector(removeValuesAtIndexes:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObject:5];

    [self assert:[0, 1, 2, 3, 4, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:@"removeValuesAtIndexes: should have been called once"];
}

- (void)testRemoveObjectsInArrayUsesRemoveKeyAtIndex
{
    [[self object] setValues:[3, 1, 1, 3, 6]];
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsInArray:[3, 6]];

    // Note that all instances of the specified values are removed, not just the first one.
    [self assert:[1, 1] equals:[[self object] values]];
    [self assert:3 equals:COUNTER message:"removeObjectFromValuesAtIndex: should have been called thrice"]

    // Try to remove something that doesn't exist. Should not crash.
    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsInArray:[3, 6]];
    [self assert:[1, 1] equals:[[self object] values]];
}

- (void)testRemoveObjectsInArrayUsesRemoveKeyAtIndexes
{
    [[self object] setValues:[3, 1, 1, 3, 6]];
    [self _patchSelector:@selector(removeValuesAtIndexes:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsInArray:[3, 6]];

    [self assert:[1, 1] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:@"removeValuesAtIndexes: should have been called once"];

    // Try to remove something that doesn't exist. Should not crash.
    [[[self object] mutableArrayValueForKey:@"values"] removeObjectsInArray:[3, 6]];
    [self assert:[1, 1] equals:[[self object] values]];
}

- (void)testRemoveLastObjectUsesRemoveKeyAtIndex
{
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeLastObject];

    [self assert:[0, 1, 2, 3, 4, 5, 6, 7, 8] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:"removeObjectFromValuesAtIndex: should have been called once"]
}

- (void)testRemoveLastObjectUsesRemoveKeyAtIndexes
{
    [self _patchSelector:@selector(removeValuesAtIndexes:)];

    [[[self object] mutableArrayValueForKey:@"values"] removeLastObject];

    [self assert:[0, 1, 2, 3, 4, 5, 6, 7, 8] equals:[[self object] values]];
    [self assert:1 equals:COUNTER message:@"removeValuesAtIndexes: should have been called once"];
}

- (void)testReplaceObjectAtIndexWithObjectUsesReplaceObjectInKeyAtIndexWithObject
{
    [self _patchSelector:@selector(replaceObjectInValuesAtIndex:withObject:)];

    [[[self object] mutableArrayValueForKey:@"values"] replaceObjectAtIndex:0 withObject:1];

    [self assert:[1, 1, 2, 3, 4, 5, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1
          equals:COUNTER
         message:@"replaceObjectInValuesAtIndex:withObject: should have been called once"];
}

- (void)testReplaceObjectsAtIndexesWithObjectsUsesReplaceObjectInKeyAtIndexWithObject
{
    [self _patchSelector:@selector(replaceObjectInValuesAtIndex:withObject:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(5, 3)];
    [[[self object] mutableArrayValueForKey:@"values"] replaceObjectsAtIndexes:indexes withObjects:[1, 2, 3]];

    [self assert:[0, 1, 2, 3, 4, 1, 2, 3, 8, 9] equals:[[self object] values]];
    [self assert:3
          equals:COUNTER
         message:@"replaceObjectInValuesAtIndex:withObject: should have been called once"];
}

- (void)testReplaceObjectAtIndexWithObjectUsesReplaceKeyAtIndexesWithKeys
{
    [self _patchSelector:@selector(replaceValuesAtIndexes:withValues:)];

    [[[self object] mutableArrayValueForKey:@"values"] replaceObjectAtIndex:5 withObject:6];

    [self assert:[0, 1, 2, 3, 4, 6, 6, 7, 8, 9] equals:[[self object] values]];
    [self assert:1
          equals:COUNTER
         message:@"replaceObjectInValuesAtIndex:withObject: should have been called once"];
}

- (void)testReplaceObjectsAtIndexesWithObjectsUsesReplaceKeyAtIndexesWithKeys
{
    [self _patchSelector:@selector(replaceValuesAtIndexes:withValues:)];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(6, 2)];
    [[[self object] mutableArrayValueForKey:@"values"] replaceObjectsAtIndexes:indexes withObjects:[7, 8]];

    [self assert:[0, 1, 2, 3, 4, 5, 7, 8, 8, 9] equals:[[self object] values]];
    [self assert:1
          equals:COUNTER
         message:@"replaceObjectInValuesAtIndexes:withValues: should have been called once"];
}

- (void)testSetArray
{
    [self _patchSelector:@selector(removeObjectFromValuesAtIndex:), @selector(insertObject:inValuesAtIndex:)];

    // This should result in all 10 objects being removed from the values and the 2 new ones being inserted
    // in a KVO compliant manner.
    [[[self object] mutableArrayValueForKey:@"values"] setArray:[88, 99]];

    [self assert:[88, 99] equals:[[self object] values]];
    [self assert:12
          equals:COUNTER
         message:@"removeObjectFromValuesAtIndex: should have been called 10 times and insertObject:inValuesAtIndex: 2 times"];
}

- (void)testKVCArrayOperators
{
    var one = [1, 1, 1, 1, 1, 1, 1, 1],
        two = [1, 2, 3, 4, 8, 0];

    [self assert:[one valueForKey:"@count"] equals:8];
    [self assert:[one valueForKeyPath:"@sum.intValue"] equals:8];
    [self assert:[two valueForKeyPath:"@avg.intValue"] equals:3];
    [self assert:[two valueForKeyPath:"@max.intValue"] equals:8];
    [self assert:[two valueForKeyPath:"@min.intValue"] equals:0];

    var a = [AA new];
    [a setValue:one forKey:"b"];
    [self assert:[a valueForKeyPath:"b.@count"] equals:8];
    [self assert:[a valueForKeyPath:"b.@sum.intValue"] equals:8];

    var b = [];
    [b addObject:[CPDictionary dictionaryWithObjects:[@"Tom", 27] forKeys:[@"name", @"age"]]];
    [b addObject:[CPDictionary dictionaryWithObjects:[@"Dick", 31] forKeys:[@"name", @"age"]]];
    [b addObject:[CPDictionary dictionaryWithObjects:[@"Harry", 47] forKeys:[@"name", @"age"]]];
    [self assert:[b valueForKeyPath:@"@sum.age"] equals:105];
    [self assert:[b valueForKeyPath:@"@avg.age"] equals:35];
    [self assert:[b valueForKeyPath:@"@min.age"] equals:27];
    [self assert:[b valueForKeyPath:@"@max.age"] equals:47];
    [self assert:[b valueForKeyPath:@"@min.name"] equals:@"Dick"];
    [self assert:[b valueForKeyPath:@"@max.name"] equals:@"Tom"];
}

@end

@implementation AA : CPObject
{
    id  b;
}
@end

@implementation TestObject : CPObject
{
    CPArray _values @accessors(property=values);
}

- (id)init
{
    if (self = [super init])
    {
        _values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    }

    return self;
}

@end

@implementation ImplementedTestObject : TestObject
{
}

- (int)countOfValues
{
    // CPLog.warn(@"countOfValues");

    COUNTER += 1;
    return [[self values] count];
}

- (id)objectInValuesAtIndex:(int)theIndex
{
    // CPLog.warn(@"objectInValuesAtIndex: %@", theIndex);

    COUNTER += 1;
    return [[self values] objectAtIndex:theIndex];
}

- (CPArray)valuesAtIndexes:(CPIndexSet)theIndexes
{
    // CPLog.warn(@"valuesAtIndexes: %@", theIndexes);

    COUNTER += 1;
    return [[self values] objectsAtIndexes:theIndexes];
}

- (void)insertObject:(id)theObject inValuesAtIndex:(int)theIndex
{
    // CPLog.warn(@"insertObject: %@ inValuesAtIndex: %@", theObject, theIndex);

    COUNTER += 1;
    [[self values] insertObject:theObject atIndex:theIndex];
}

- (void)insertValues:(CPArray)theObjects atIndexes:(CPIndexSet)theIndexes
{
    // CPLog.warn(@"insertValues: %@ atIndexes: %@", theObjects, theIndexes);

    COUNTER += 1;
    [[self values] insertObjects:theObjects atIndexes:theIndexes];
}

- (void)removeObjectFromValuesAtIndex:(int)theIndex
{
    // CPLog.warn(@"removeObjectFromValuesAtIndex: %@", theIndex);

    COUNTER += 1;
    [[self values] removeObjectAtIndex:theIndex];
}

- (void)removeValuesAtIndexes:(CPIndexSet)theIndexes
{
    // CPLog.warn(@"removeValuesAtIndexes: %@", theIndexes);

    COUNTER += 1;
    [[self values] removeObjectsAtIndexes:theIndexes];
}

- (void)replaceObjectInValuesAtIndex:(int)theIndex withObject:(id)theObject
{
    // CPLog.warn(@"replaceObjectInValuesAtIndex: %@ withObject: %@", theIndex, theObject);

    COUNTER += 1;
    [[self values] replaceObjectAtIndex:theIndex withObject:theObject];
}

- (void)replaceValuesAtIndexes:(CPIndexSet)theIndexes withValues:(id)theObjects
{
    // CPLog.warn(@"replaceValuesAtIndexes: %@ withValues: %@", theIndexes, theObjects);

    COUNTER += 1;
    [[self values] replaceObjectsAtIndexes:theIndexes withObjects:theObjects];
}

@end
