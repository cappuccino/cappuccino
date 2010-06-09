
@implementation CFDictionaryTest : OJTestCase

- (void)testContainsValue
{
    var dict = new CFMutableDictionary();
    [self assert:NO equals:dict.containsValue(@"123")];
    [self assert:NO equals:dict.containsValue(@"abc")];

    dict.setValueForKey(@"abc", @"123");
    [self assert:YES equals:dict.containsValue(@"123")];
    [self assert:NO equals:dict.containsValue(@"abc")];

    dict.setValueForKey(@"def", @"123");
    [self assert:YES equals:dict.containsValue(@"123")];
    [self assert:NO equals:dict.containsValue(@"abc")];
}

- (void)testCountOfValue
{
    var dict = new CFMutableDictionary();
    [self assert:0 equals:dict.countOfValue(@"123")];
    
    dict.setValueForKey(@"abc", @"123");
    [self assert:1 equals:dict.countOfValue(@"123")];

    dict.setValueForKey(@"def", @"123");
    [self assert:2 equals:dict.countOfValue(@"123")];
}

@end
