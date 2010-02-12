@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPNumber.j>

var expectedString = "280NPLIST;1.0;D;K;4;key4f;3;8.8K;4;key3f;3;9.9K;4;key2F;K;4;key1S;22;Some random charactersE;"

@implementation CPDataTest : OJTestCase
{
    CPData plist_data;
}

-(void)setUp
{
    // Plist helpers
    var keys = [@"key1", @"key2", @"key3", @"key4"];
    var objects = [@"Some random characters", NO, 9.9, 8.8];
    var dict = [CPDictionary dictionaryWithObjects:objects forKeys:keys];

    plist_data = [[CPData alloc] initWithSerializedPlistObject:dict];
}

-(void)testLength
{
    [plist_data length] === expectedString.length
}

-(void)testStringFromPlist
{
    [self assert:[plist_data encodedString] equals:expectedString];
}

-(void)testPlistObject
{
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key1"] equals:@"Some random characters"];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key2"] equals:[CPNumber numberWithBool:NO]];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key3"] equals:[CPNumber numberWithDouble:9.9]];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key4"] equals:[CPNumber numberWithDouble:8.8]];
}

@end
