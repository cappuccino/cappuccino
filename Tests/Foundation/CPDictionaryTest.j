@import <Foundation/CPDictionary.j>

@implementation CPDictionaryTest : OJTestCase
{
}

- (void)setUp
{
    json = {
        "key1": ['1', '2', '3'],
        "key2": "This is a string",
        "key3": {
            "another": "object"
        }
    }

    string_dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key1", @"key2"]];
    json_dict = [CPDictionary dictionaryWithJSObject:json recursively:YES];
    
    json_with_nulls = {
        "key1": ['1', '2', '3'],
        "key2": "This is a string",
        "key3": null
    }
}

- (void)testInitWithDictionary
{
    var dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key1", @"key2"]];

    var new_dict = [[CPDictionary alloc] initWithDictionary:dict];
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
    [self assert:[dict count] equals:3];
    [self assert:[[dict objectForKey:@"key3"] count] equals:1];
}

- (void)testDictionaryWithJSObjectRecursiveWithNull
{
    var dict = [CPDictionary dictionaryWithJSObject:json_with_nulls recursively:YES];
    [self assert:3 equals:[dict count]];
    [self assert:[@"key1", @"key2", @"key3"] equals:[dict allKeys]];
    [self assert:[CPNull null] equals:[dict objectForKey:@"key3"]];
}

- (void)testDictionaryWithJSObjectNonRecursive
{
    var non_recursive_dict = [CPDictionary dictionaryWithJSObject:json recursively:NO];
    [self assertThrows:[non_recursive_dict objectForKey:@"key3"]];
}

- (void)testCopy
{
    var copy = [string_dict copy];
    [self assert:copy notSame:string_dict];
    [self assert:[copy objectForKey:@"key1"] equals:[string_dict objectForKey:@"key1"]];
}

- (void)testCount
{
    [self assert:[string_dict count] equals:2];
    [self assert:[json_dict count] equals:3];
}

- (void)testAllKeys
{
    [self assert:[string_dict allKeys] equals:[@"key2", @"key1"]];
    [self assert:[json_dict allKeys] equals:[@"key1", @"key2", @"key3"]];
}

- (void)testAllValues
{
    [self assert:[string_dict allValues] equals:[@"1", @"2"]];
    // Had to get object from key to get test passing
    [self assert:[json_dict allValues] equals:[[json_dict objectForKey:@"key3"], @"This is a string", ['1', '2', '3']]];
}

- (void)testObjectForKey
{
    [self assert:[string_dict objectForKey:@"key1"] equals:"1"];
    [self assert:[json_dict objectForKey:@"key1"] equals:['1', '2', '3']];
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
    [self assert:[string_dict count] equals:1];
    [self assert:[json_dict count] equals:2];
    [self assertThrows:[string_dict objectForKey:@"key1"]];
    [self assertThrows:[json_dict objectForKey:@"key1"]];
}

- (void)testRemoveObjectsForKeys
{
    [string_dict removeObjectsForKeys:[@"key1"]];
    [json_dict removeObjectsForKeys:[@"key1", @"key2"]];
    [self assert:[string_dict count] equals:1];
    [self assert:[json_dict count] equals:1];
    [self assertThrows:[string_dict objectForKey:@"key1"]];
    [self assertThrows:[json_dict objectForKey:@"key1"]];
    [self assertThrows:[json_dict objectForKey:@"key2"]];
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
    var dict = [[CPDictionary alloc] initWithObjects:[@"1", @"2"] forKeys:[@"key4", @"key5"]];
    [string_dict addEntriesFromDictionary:dict]
    [json_dict addEntriesFromDictionary:dict]
    [self assert:[string_dict count] equals:4];
    [self assert:[json_dict count] equals:5];
}

@end