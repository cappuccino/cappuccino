@import <Foundation/CPMapTable.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPEnumerator.j>
@import <OJUnit/OJTestCase.j>

@implementation CPMapTableTest : OJTestCase
{
    CPMapTable map_table;
    id objectKey;
}

- (void)setUp
{
    map_table = [[CPMapTable alloc] init];
    objectKey = [[CPObject alloc] init];
}

- (void)testInit
{
    [self assert:[map_table count] equals:0];
}

- (void)testSetObjectForKey
{
    [map_table setObject:@"value1" forKey:@"key1"];
    [self assert:[map_table count] equals:1];
    [self assert:[map_table objectForKey:@"key1"] equals:@"value1"];

    [map_table setObject:@"value2" forKey:123];
    [self assert:[map_table count] equals:2];
    [self assert:[map_table objectForKey:123] equals:@"value2"];

    [map_table setObject:@"value3" forKey:objectKey];
    [self assert:[map_table count] equals:3];
    [self assert:[map_table objectForKey:objectKey] equals:@"value3"];

    // Test overriding a value
    [map_table setObject:@"newValue" forKey:@"key1"];
    [self assert:[map_table count] equals:3];
    [self assert:[map_table objectForKey:@"key1"] equals:@"newValue"];
}

- (void)testObjectForKey
{
    [self assertNull:[map_table objectForKey:@"nonExistentKey"]];

    [map_table setObject:@"value1" forKey:@"key1"];
    [self assert:[map_table objectForKey:@"key1"] equals:@"value1"];
}

- (void)testCount
{
    [self assert:[map_table count] equals:0];

    [map_table setObject:@"value1" forKey:@"key1"];
    [self assert:[map_table count] equals:1];

    [map_table setObject:@"value2" forKey:@"key2"];
    [self assert:[map_table count] equals:2];

    [map_table removeObjectForKey:@"key1"];
    [self assert:[map_table count] equals:1];
}

- (void)testRemoveObjectForKey
{
    [map_table setObject:@"value1" forKey:@"key1"];
    [map_table setObject:@"value2" forKey:123];

    [map_table removeObjectForKey:@"key1"];
    [self assert:[map_table count] equals:1];
    [self assertNull:[map_table objectForKey:@"key1"]];
    [self assert:[map_table objectForKey:123] equals:@"value2"];

    [map_table removeObjectForKey:123];
    [self assert:[map_table count] equals:0];
    [self assertNull:[map_table objectForKey:123]];
}

- (void)testRemoveAllObjects
{
    [map_table setObject:@"value1" forKey:@"key1"];
    [map_table setObject:@"value2" forKey:@"key2"];

    [map_table removeAllObjects];
    [self assert:[map_table count] equals:0];
    [self assertNull:[map_table objectForKey:@"key1"]];
    [self assertNull:[map_table objectForKey:@"key2"]];
}

- (void)testKeyEnumerator
{
    // Test empty case by creating a new enumerator for each assertion
    [self assertNull:[[map_table keyEnumerator] nextObject]];
    [self assert:[[[map_table keyEnumerator] allObjects] count] equals:0];

    // Add objects and test populated case
    [map_table setObject:@"value1" forKey:@"key1"];
    [map_table setObject:@"value2" forKey:123];
    [map_table setObject:@"value3" forKey:objectKey];

    var allKeys = [[map_table keyEnumerator] allObjects];

    [self assert:[allKeys count] equals:3];
    [self assertTrue:[allKeys containsObject:@"key1"]];
    [self assertTrue:[allKeys containsObject:123]];
    [self assertTrue:[allKeys containsObject:objectKey]];
}

- (void)testObjectEnumerator
{
    // Test empty case by creating a new enumerator for each assertion
    [self assertNull:[[map_table objectEnumerator] nextObject]];
    [self assert:[[[map_table objectEnumerator] allObjects] count] equals:0];

    // Add objects and test populated case
    [map_table setObject:@"value1" forKey:@"key1"];
    [map_table setObject:@"value2" forKey:123];
    [map_table setObject:@"value3" forKey:objectKey];

    var allValues = [[map_table objectEnumerator] allObjects];

    [self assert:[allValues count] equals:3];
    [self assertTrue:[allValues containsObject:@"value1"]];
    [self assertTrue:[allValues containsObject:@"value2"]];
    [self assertTrue:[allValues containsObject:@"value3"]];
}

- (void)testDictionaryRepresentation
{
    [map_table setObject:@"value1" forKey:@"key1"];
    [map_table setObject:@"value2" forKey:@"key2"];

    var dictionary = [map_table dictionaryRepresentation];
    [self assert:[dictionary count] equals:2];
    [self assert:[dictionary objectForKey:@"key1"] equals:@"value1"];
    [self assert:[dictionary objectForKey:@"key2"] equals:@"value2"];
}

@end
