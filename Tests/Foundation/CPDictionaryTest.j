@import <Foundation/CPDictionary.j>

@import <OJUnit/OJTestCase.j>

@implementation CPDictionaryTest : OJTestCase
{
    CPDictionary    string_dict;
    CPDictionary    json_dict;
    JSObject        json;
}

- (void)setUp
{
    json = {
        "key1": ['1', '2', '3'],
        "key2": "This is a string",
        "key3": {
            "another": "object"
        }
    };

    string_dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2", @"This is a String", @"This is a String"] forKeys:[@"key1", @"key2", @"key3", @"key4"]];
    json_dict = [CPDictionary dictionaryWithJSObject:json recursively:YES];
}

- (void)testInitWithDictionary
{
    var dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key1", @"key2"]],
        new_dict = [[CPDictionary alloc] initWithDictionary:dict];

    [self assert:[new_dict objectForKey:@"key1"] equals:[dict objectForKey:@"key1"]];
    [self assert:[new_dict objectForKey:@"key2"] equals:[dict objectForKey:@"key2"]];

    var new_dict_cm = [CPDictionary dictionaryWithDictionary:dict];
    [self assert:[new_dict_cm objectForKey:@"key1"] equals:[dict objectForKey:@"key1"]];
    [self assert:[new_dict_cm objectForKey:@"key2"] equals:[dict objectForKey:@"key2"]];
}

- (void)testInitWithObjects
{
    var dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key1", @"key2"]];
    [self assert:[dict objectForKey:@"key1"] equals:@"1"];
    [self assert:[dict objectForKey:@"key2"] equals:@"2"];
    [self assert:[dict count] equals:2];

    var dict_cm = [CPDictionary dictionaryWithObjects:[@"1", @"2"] forKeys:[@"key1", @"key2"]];
    [self assert:[dict_cm objectForKey:@"key1"] equals:@"1"];
    [self assert:[dict_cm objectForKey:@"key2"] equals:@"2"];
    [self assert:[dict_cm count] equals:2];
}

- (void)testDictionaryWithObject
{
    var dict = [CPDictionary dictionaryWithObject:@"1" forKey:@"key1"];
    [self assert:[dict objectForKey:@"key1"] equals:@"1"];
    [self assert:[dict count] equals:1];
}

- (void)testDictionaryWithJSObjectRecursive
{
    var dict = [CPDictionary dictionaryWithJSObject:json recursively:YES];
    [self assert:[json_dict count] equals:3];
    [self assert:[[dict objectForKey:@"key3"] count] equals:1];
}

- (void)testDictionaryWithJSObjectRecursiveWithNull
{
    var json_with_nulls =     {
            "key1": ['1', '2', '3'],
            "key2": "This is a string",
            "key3": null
        },
        dict = [CPDictionary dictionaryWithJSObject:json_with_nulls recursively:YES];

    [self assert:3 equals:[dict count]];
    [self assert:[@"key1", @"key2", @"key3"] equals:[dict allKeys]];
    [self assert:[CPNull null] equals:[dict objectForKey:@"key3"]];
}

- (void)testDictionaryWithJSObjectNonRecursive
{
    var non_recursive_dict = [CPDictionary dictionaryWithJSObject:json recursively:NO];
}

- (void)testCopy
{
    var copy = [string_dict copy];
    [self assert:copy notSame:string_dict];
    [self assert:[copy objectForKey:@"key1"] equals:[string_dict objectForKey:@"key1"]];
}

- (void)testCount
{
    [self assert:[string_dict count] equals:4];
    [self assert:[json_dict count] equals:3];
}

- (void)testAllKeys
{
    [self assert:[string_dict allKeys] equals:[@"key4", @"key3", @"key2", @"key1"]];
    [self assert:[json_dict allKeys] equals:[@"key1", @"key2", @"key3"]];
}

- (void)testAllValues
{
    [self assert:[string_dict allValues] equals:[@"1", @"2", @"This is a String",  @"This is a String"]];
    // Had to get object from key to get test passing
    [self assert:[json_dict allValues] equals:[[json_dict objectForKey:@"key3"], @"This is a string", ['1', '2', '3']]];
}

- (void)testObjectForKey
{
    [self assert:[string_dict objectForKey:@"key1"] equals:"1"];
    [self assert:[json_dict objectForKey:@"key1"] equals:['1', '2', '3']];
}

- (void)testAllKeysForObject
{
    [self assert:[string_dict allKeysForObject:@"This is a String"] equals:[@"key4", @"key3"]];
}

- (void)testKeyEnumerator
{
    var dict = [[CPDictionary alloc] init];
    [self assertNull:[[dict keyEnumerator] nextObject]];
    [self assertNotNull:[[dict keyEnumerator] allObjects]];

    [self assertNotNull:[[string_dict keyEnumerator] nextObject]];
    [self assertNotNull:[[json_dict keyEnumerator] nextObject]];
    [self assertNotNull:[[string_dict keyEnumerator] allObjects]];
    [self assertNotNull:[[json_dict keyEnumerator] allObjects]];
}

- (void)testObjectEnumerator
{
    var dict = [[CPDictionary alloc] init];
    [self assertNull:[[dict objectEnumerator] nextObject]];
    [self assertNotNull:[[dict objectEnumerator] allObjects]];

    [self assertNotNull:[[string_dict objectEnumerator] nextObject]];
    [self assertNotNull:[[json_dict objectEnumerator] nextObject]];
    [self assertNotNull:[[string_dict objectEnumerator] allObjects]];
    [self assertNotNull:[[json_dict objectEnumerator] allObjects]];
}

- (void)testIsEqualToDictionary
{
    [self assertTrue:[string_dict isEqualToDictionary:[string_dict copy]]];
    [self assertTrue:[json_dict isEqualToDictionary:[json_dict copy]]];
    [self assertFalse:[json_dict isEqualToDictionary:[string_dict copy]]];
}

- (void)testRemoveAllObjects
{
    [string_dict removeAllObjects];
    [json_dict removeAllObjects];
    [self assert:[string_dict count] equals:0];
    [self assert:[json_dict count] equals:0];
}

- (void)testRemoveObjectForKey
{
    [string_dict removeObjectForKey:@"key1"];
    [json_dict removeObjectForKey:@"key1"];
    [self assert:[string_dict count] equals:3];
    [self assert:[json_dict count] equals:2];
}

- (void)testRemoveObjectsForKeys
{
    [string_dict removeObjectsForKeys:[@"key1"]];
    [json_dict removeObjectsForKeys:[@"key1", @"key2"]];
    [self assert:[string_dict count] equals:3];
    [self assert:[json_dict count] equals:1];
}

- (void)testSetObjectForKey
{
    var dict = [[CPDictionary alloc] init];
    [dict setObject:@"setObjectForKey test" forKey:@"key1"];
    [self assert:[dict objectForKey:@"key1"] equals:@"setObjectForKey test"];
    [self assert:[dict count] equals:1];
}

- (void)testAddEntriesFromDictionary
{
    var dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key5", @"key6"]];
    [string_dict addEntriesFromDictionary:dict]
    [json_dict addEntriesFromDictionary:dict]
    [self assert:[string_dict count] equals:6];
    [self assert:[json_dict count] equals:5];
}

- (void)testDictionaryWithFalsyValues
{
    var dict = [[CPDictionary alloc] initWithObjects:["", 0, [CPNull null]] forKeys:["1", "2", "3"]];
    [self assertTrue:[dict containsKey:"1"]];
    [self assertTrue:[dict containsKey:"2"]];
    [self assertTrue:[dict containsKey:"3"]];
    [self assertFalse:[dict containsKey:"4"]];
}

// FIXME: When CPDictionary will throw exception on nil value the following test case can be turn on again
/*
- (void)testThrowsOnNilValue
{
    [self assertThrows:function(){
        var dict = [[CPDictionary alloc] initWithObjects:[1, nil] forKeys:["1", "2"]];
    }];
}*/

- (void)testKeysOfEntriesPassingTest
{
    var numberDictionary = [CPDictionary dictionaryWithJSObject:{
            key1: 5,
            key2: 1,
            key3: 4,
            key4: 2,
            key5: 3
        }];

    var expected = [@"key1", @"key3"],
        result = [numberDictionary keysOfEntriesPassingTest:function(key, value, stop)
        {
            return value >= 4;
        }];

    [self assert:expected equals:result];

    expected = [@"key3", @"key1"],
    result = [numberDictionary keysOfEntriesWithOptions:CPEnumerationReverse passingTest:function(key, value, stop)
        {
            return value >= 4;
        }];

    [self assert:expected equals:result];

    expected = [@"key3"],
    result = [numberDictionary keysOfEntriesWithOptions:CPEnumerationReverse passingTest:function(key, value, stop)
        {
            if (value === 4)
                stop(YES);

            return value >= 4;
        }];

    [self assert:expected equals:result];

    var stringDictionary = [CPDictionary dictionaryWithJSObject:{
            a: @"Z", b: @"y", c: @"X", d: @"W",
            e: @"V", f: @"u", g: @"T", h: @"s",
            i: @"R", j: @"q", k: @"P", l: @"o"
        }];

    expected = [@"j", @"k", @"l"];
    result = [stringDictionary keysOfEntriesPassingTest:function(key, value, stop)
        {
            return value.toLowerCase() <= @"q";
        }];

    [self assert:expected equals:result];

    expected = [@"l", @"k", @"j"];
    result = [stringDictionary keysOfEntriesWithOptions:CPEnumerationReverse passingTest:function(key, value, stop)
        {
            return value.toLowerCase() <= @"q";
        }];

    [self assert:expected equals:result];

    expected = [@"j", @"k"];
    result = [stringDictionary keysOfEntriesPassingTest:function(key, value, stop)
        {
            if (value === @"P")
                stop(YES);

            return value.toLowerCase() <= "q";
        }];

    [self assert:expected equals:result];
}

- (void)testKeysSortedByValueUsingSelector
{
    var numberDictionary = [CPDictionary dictionaryWithJSObject:{
            key1: 5,
            key2: 1,
            key3: 4,
            key4: 2,
            key5: 3
        }];

    var expected = [@"key2", @"key4", @"key5", @"key3", @"key1"],
        result = [numberDictionary keysSortedByValueUsingSelector:@selector(compare:)];

    [self assert:expected equals:result];

    var stringDictionary = [CPDictionary dictionaryWithJSObject:{
            a: @"Z", b: @"y", c: @"X", d: @"W",
            e: @"V", f: @"u", g: @"T", h: @"s",
            i: @"R", j: @"q", k: @"P", l: @"o"
        }];

    expected = [@"l", @"k", @"j", @"i", @"h", @"g", @"f", @"e", @"d", @"c", @"b", @"a"];
    result = [stringDictionary keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];

    [self assert:expected equals:result];

    expected = [@"k", @"i", @"g", @"e", @"d", @"c", @"a", @"l", @"j", @"h", @"f", @"b"];
    result = [stringDictionary keysSortedByValueUsingSelector:@selector(compare:)];
    [self assert:expected equals:result];
}

- (void)testKeysSortedByValueUsingComparator
{
    var numberDictionary = [CPDictionary dictionaryWithJSObject:{
            key1: 5,
            key2: 1,
            key3: 4,
            key4: 2,
            key5: 3
        }];

    var expected = [@"key2", @"key4", @"key5", @"key3", @"key1"],
        result = [numberDictionary keysSortedByValueUsingComparator:function(obj1, obj2)
        {
            return obj1 < obj2 ? CPOrderedAscending : CPOrderedDescending;
        }];

    [self assert:expected equals:result];

    var stringDictionary = [CPDictionary dictionaryWithJSObject:{
            a: @"Z", b: @"y", c: @"X", d: @"W",
            e: @"V", f: @"u", g: @"T", h: @"s",
            i: @"R", j: @"q", k: @"P", l: @"o"
        }];

    expected = [@"l", @"k", @"j", @"i", @"h", @"g", @"f", @"e", @"d", @"c", @"b", @"a"];
    result = [stringDictionary keysSortedByValueUsingComparator:function(obj1, obj2)
        {
            return obj1.toLowerCase() < obj2.toLowerCase() ? CPOrderedAscending : CPOrderedDescending;
        }];

    [self assert:expected equals:result];

    expected = [@"k", @"i", @"g", @"e", @"d", @"c", @"a", @"l", @"j", @"h", @"f", @"b"];
    result = [stringDictionary keysSortedByValueUsingComparator:function(obj1, obj2)
        {
            return obj1 < obj2 ? CPOrderedAscending : CPOrderedDescending;
        }];
    [self assert:expected equals:result];
}

- (void)testEnumerateKeysAndObjectsUsingBlock_
{
    var input0 = @{},
        input1 = [CPDictionary dictionaryWithJSObject:{a: 1, b: 3, c: "b"}],
        output = [CPMutableDictionary dictionary],
        outputFunction = function(aKey, anObject)
        {
            [output setValue:anObject forKey:aKey];
        };

    [input0 enumerateKeysAndObjectsUsingBlock:outputFunction];
    [self assert:0 equals:[output count] message:@"output when enumerating empty dictionary"];

    [input1 enumerateKeysAndObjectsUsingBlock:outputFunction];
    [self assert:3 equals:[output count] message:@"output when enumerating input1"];
    [self assert:input1 equals:output message:@"output should equal input"];

    // Stop enumerating after two keys.
    output = [CPMutableDictionary dictionary];
    var stoppingFunction = function(aKey, anObject, stop)
    {
        [output setValue:anObject forKey:aKey];
        if ([output count] > 1)
            @deref(stop) = YES;
    }

    [input1 enumerateKeysAndObjectsUsingBlock:stoppingFunction];
    [self assert:2 equals:[output count] message:@"output when enumerating input1 and stopping after 2"];

    // CPEnumerationReverse shouldn't have any particular effect. Just check that it doesn't crash.
    output = [CPMutableDictionary dictionary];
    [input1 enumerateKeysAndObjectsWithOptions:CPEnumerationReverse usingBlock:outputFunction];
    [self assert:3 equals:[output count] message:@"output when enumerating input1"];
    [self assert:input1 equals:output message:@"output should equal input"];
}

- (void)testJSObjectDescription
{
    var dict = [[CPDictionary alloc] initWithObjects:[CGRectMake(1, 2, 3, 4), CGPointMake(5, 6)] forKeys:[@"key1", @"key2"]],
        d = [dict description];

    [self assertTrue:d.indexOf("(1, 2)") !== -1 message:"Can't find '(1, 2)' in description of dictionary " + d];
    [self assertTrue:d.indexOf("(3, 4)") !== -1 message:"Can't find '(3, 4)' in description of dictionary " + d];
    [self assertTrue:d.indexOf("(5, 6)") !== -1 message:"Can't find '(5, 6)' in description of dictionary " + d];

    [self assert:'@{\n    @"key1": @[\n        @"1",\n        @"2",\n        @"3"\n    ],\n    @"key2": @"This is a string",\n    @"key3": @{\n        @"another": @"object"\n    }\n}' equals:[json_dict description]];
}

- (void)testInitWithObjectsAndKeys
{
    var dict = [[CPDictionary alloc] initWithObjectsAndKeys:@"Value1", @"Key1", nil, @"Key2", @"Value3", @"Key3"];

    [self assert:2 equals:[dict count]];
    [self assert:@"Value1" equals:[dict objectForKey:@"Key1"]];
    [self assert:nil equals:[dict objectForKey:@"Key2"]]; // No key/value pair
    [self assert:@"Value3" equals:[dict objectForKey:@"Key3"]];
}

- (void)testDictionaryLiteral
{
    var dict = @{
            @"Key1": @"Value1",
            @"Key2": [CPNull null],
            @"Key3": 2
        };

    [self assert:3 equals:[dict count]];
    [self assert:@"Value1" equals:[dict objectForKey:@"Key1"]];
    [self assert:[CPNull null] same:[dict objectForKey:@"Key2"]];
    [self assert:2 equals:[dict objectForKey:@"Key3"]];
}

- (void)testDictionaryLiteralExpressions
{
    var aKey = @"aKey",
        aValue = 5,
        dict = @{
            @"Key" + 1: @"Value" + 1,
            @"Key2": NO ? 1 : 2,
            aKey: aValue,   // trailing comma is allowed
        };

    [self assert:3 equals:[dict count]];
    [self assert:@"Value1" equals:[dict objectForKey:@"Key1"]];
    [self assert:2 equals:[dict objectForKey:@"Key2"]];
    [self assert:5 equals:[dict objectForKey:@"aKey"]];
}

@end
