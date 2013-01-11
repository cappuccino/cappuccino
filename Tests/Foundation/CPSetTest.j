
@import <Foundation/CPSet.j>


@implementation CPSetTest : OJTestCase
{
}

- (void)assertSet:(CPSet)aSet onlyHasObjects:(CPArray)objects
{
    [self assert:[objects count] equals:[aSet count]];

    var allObjects = [aSet allObjects],
        index = 0,
        count = [objects count];

    [self assert:[objects count] equals:[allObjects count]];

    for (; index < count; ++index)
    {
        var object = objects[index];

        if ([allObjects indexOfObjectIdenticalTo:object] === CPNotFound)
            return [self fail:@"Set does not contain " + object];
    }
}

- (void)testEmptySet
{
    var set = [CPSet set];

    [self assert:@"{(\n)}" equals:[set description]];
    [self assert:0 equals:[set count]];
    [self assert:[] equals:[set allObjects]];
    [self assert:nil equals:[set anyObject]];
    [self assert:NO equals:[set containsObject:RAND()]];
    [self assert:nil equals:[set member:RAND()]];

    var object,
        objectEnumerator = [set objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self fail:@"Empty set had non-empty enumerator"];

    [self assertTrue:[set isSubsetOfSet:set]];
    [self assertTrue:[set isSubsetOfSet:[CPSet set]]];

    // Empty set intersects nothing!
    [self assertFalse:[set intersectsSet:set]];
    [self assertFalse:[set intersectsSet:[CPSet set]]];

    [self assertTrue:[set isEqualToSet:set]];
    [self assertTrue:[set isEqualToSet:[CPSet set]]];

    var copy = [set copy];

    [self assert:@"{(\n)}" equals:[copy description]];
    [self assertTrue:[set isEqualToSet:copy]];
}

- (void)testSetWithArray_
{
    [self assertSet:[CPSet setWithArray:[]] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithArray:[@"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithArray:[@"a", @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithArray:[@"a", @"a", @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithArray:[@"a", @"b"]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithArray:[@"a", @"b", @"a"]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithArray:[@"a", @"b", @"a", 0]] onlyHasObjects:[@"a", @"b", 0]];
}

- (void)testSetWithObject
{
    [self assertSet:[CPSet setWithObject:nil] onlyHasObjects:[]];
    [self assertThrows:function() { [CPSet setWithObject:undefined] }];
    [self assertSet:[CPSet setWithObject:0] onlyHasObjects:[0]];
    [self assertSet:[CPSet setWithObject:@"a"] onlyHasObjects:[@"a"]];
}

- (void)testSetWithObjects_count_
{
    [self assertSet:[CPSet setWithObjects:[] count:0] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithObjects:[@"a"] count:1] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"a"] count:2] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"a", @"a"] count:3] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b"] count:2] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b", @"a"] count:3] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b", @"a", 0] count:4] onlyHasObjects:[@"a", @"b", 0]];
    [self assertThrows:function() {
        [CPSet setWithObjects:[@"a", nil, undefined, 0] count:4];
    }];

    [self assertSet:[CPSet setWithObjects:[] count:4] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithObjects:[@"a"] count:2] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"a"] count:0] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"a", @"a"] count:1] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b"] count:1] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b", @"a"] count:2] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:[@"a", @"b", @"a", 0] count:10] onlyHasObjects:[@"a", @"b", 0]];
    [self assertThrows:function() {
        [CPSet setWithObjects:[@"a", nil, undefined, 0] count:3];
    }];
}

- (void)testSetWithObjects_
{
    [self assertSet:[CPSet setWithObjects:nil] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithObjects:@"a"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", nil] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"a"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", nil, @"a"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"a", @"a"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"a", @"a"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b"] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b", nil] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:@"a", nil, @"b"] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b", @"a"] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b", @"a", 0] onlyHasObjects:[@"a", @"b", 0]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b", @"a", 0, nil] onlyHasObjects:[@"a", @"b", 0]];
    [self assertSet:[CPSet setWithObjects:@"a", @"b", @"a", nil, 0] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithObjects:@"a", nil, undefined, 0] onlyHasObjects:[@"a"]];

    [self assertThrows:function() {
        [CPSet setWithObjects:@"a", undefined, 0, nil];
    }];
}

- (void)testSetWithSet_
{
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:nil]] onlyHasObjects:[]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", nil]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", nil, @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"a", @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"a", @"a"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b"]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b", nil]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", nil, @"b"]] onlyHasObjects:[@"a"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b", @"a"]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b", @"a", 0]] onlyHasObjects:[@"a", @"b", 0]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b", @"a", 0, nil]] onlyHasObjects:[@"a", @"b", 0]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", @"b", @"a", nil, 0]] onlyHasObjects:[@"a", @"b"]];
    [self assertSet:[CPSet setWithSet:[CPSet setWithObjects:@"a", nil, undefined, 0]] onlyHasObjects:[@"a"]];
    [self assertThrows:function() {
        [CPSet setWithSet:[CPSet setWithObjects:@"a", undefined, 0, nil]];
    }];
}

- (void)testAddObject
{
    var set = [CPSet new];

    [self assertFalse:[set containsObject:"foo"]];
    [set addObject:"foo"];
    [self assertTrue:[set containsObject:"foo"]];
}

- (void)testAddZeroObject
{
    var set = [CPSet new];

    [self assertFalse:[set containsObject:0]];
    [set addObject:0];
    [self assertTrue:[set containsObject:0]];
}

- (void)testRemoveObject
{
    var set = [CPSet new];

    [set addObject:"foo"];
    [self assertTrue:[set containsObject:"foo"]];
    [set removeObject:"foo"];
    [self assertFalse:[set containsObject:"foo"]];

    var dict1 = [CPDictionary dictionaryWithObject:self forKey:@"key"],
        dict2 = [CPDictionary dictionaryWithObject:self forKey:@"key"],
        set2 = [CPMutableSet new];

    [set2 addObject:dict1];
    [set2 removeObject:dict2];
    [self assertTrue:[set2 count] === 0];

    // Removing an object not in the set is not an error.
    [set2 removeObject:dict2];
}

- (void)testRemoveZeroObject
{
    var set = [CPSet new];

    // In Objective-J this is equivalent to [set addObject:[CPNumber numberWithInt:0]];
    [set addObject:0];
    [self assertTrue:[set containsObject:0] message:@"adding 0 to a set should work"];
    [set removeObject:0];
    [self assertFalse:[set containsObject:0] message:@"removing 0 from a set should work"];
}

- (void)testAddNilObject
{
    var set = [CPSet new];

    [self assertFalse:[set containsObject:nil]];

    // Should throw an exception. In Cocoa this is NSException.
    var sawException = NO;
    try {
        [set addObject:nil];
    }
    catch (ex)
    {
        sawException = YES;
        [self assert:"attempt to insert nil or undefined" equals:[ex reason]];
    }
    [self assertTrue:sawException message:"expected exception for set addObject:nil"];
    [self assertFalse:[set containsObject:nil]];
}

- (void)testRemoveNilObject
{
    var set = [CPSet new];

    [self assertThrows:function() { [set addObject:nil] }];
    [self assertFalse:[set containsObject:nil]];
    [self assertThrows:function() { [set removeObject:nil] }];
    [self assertFalse:[set containsObject:nil]];
}

- (void)testIsSubsetOfSet
{
    var set = [CPSet setWithArray:[1, 2, 3, 4, 5]];
    [self assertTrue:[[CPSet setWithArray:[1, 2, 3]] isSubsetOfSet:set]];
    [self assertFalse:[[CPSet setWithArray:[1, 2, 3, 100]] isSubsetOfSet:set]];
    [self assertTrue:[[CPSet new] isSubsetOfSet:set]];
}

- (void)testDescription
{
    var set = [CPSet new];

    [self assert:@"{(\n)}" equals:[set description]];
    [set addObject:"horizon"];
    [set addObject:"surfer"];
    [set addObject:"7"];
    [self assertSet:set onlyHasObjects:["horizon", "surfer", "7"]];
}

- (void)testKVCSetOperators
{
    var one = [CPSet setWithArray:[@"one", @"two", @"three"]],
        two = [CPSet setWithArray:[1, 2, 3, 4, 8, 0]];

    [self assert:[one valueForKey:"@count"] equals:3];
    [self assert:[two valueForKey:"@count"] equals:6];
    [self assert:[two valueForKeyPath:"@sum.intValue"] equals:18];
    [self assert:[two valueForKeyPath:"@avg.doubleValue"] equals:3.0];
    [self assert:[one valueForKeyPath:"@max.description"] equals:@"two"];
    [self assert:[two valueForKeyPath:"@max.intValue"] equals:8];
    [self assert:[one valueForKeyPath:"@min.description"] equals:@"one"];
    [self assert:[two valueForKeyPath:"@min.intValue"] equals:0];

    var b = [CPSet set];
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

- (void)testMember
{
    var dict1 = [CPDictionary dictionaryWithObject:self forKey:@"key"],
        dict2 = [CPDictionary dictionaryWithObject:self forKey:@"key"],
        set2 = [CPMutableSet new];

    [set2 addObject:dict1];
    [self assertTrue:[set2 member:dict2] === dict1];
}

@end
