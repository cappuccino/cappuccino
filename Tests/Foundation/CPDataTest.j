@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPNumber.j>

@implementation CPDataTest : OJTestCase
{
}

-(void)setUp
{
    string_data = [[CPData alloc] initWithEncodedString:@"CPData Test"];

    // Plist helpers
    keys = [@"key1", @"key2", @"key3", @"key4"];
    objects = [@"Some random characters", NO, 9.9, 8.8];
    dict = [CPDictionary dictionaryWithObjects:objects forKeys:keys];

    plist_data = [[CPData alloc] initWithSerializedPlistObject:dict];
}

-(void)testStringLength
{
    var data = [[CPData alloc] initWithEncodedString:@"CPData Test"];
    [self assert:[data length] equals:11];

    var data_cm = [CPData dataWithEncodedString:@"CPData Test"];
    [self assert:[data_cm length] equals:11];
}

-(void)testPlistLength
{
    var data = [[CPData alloc] initWithSerializedPlistObject:dict];
    [self assert:[data length] equals:93];

    var data_cm = [CPData serializedDataWithPlistObject:dict];
    [self assert:[data length] equals:93];
}

-(void)testDescription
{
    [self assert:[string_data description] equals:[string_data encodedString]];
}

-(void)testString
{
    [self assert:[string_data encodedString] equals:@"CPData Test"];
}

-(void)testStringFromPlist
{
    [self assert:[plist_data encodedString] equals:"280NPLIST;1.0;D;K;4;key4f;3;8.8K;4;key3f;3;9.9K;4;key2F;K;4;key1S;22;Some random charactersE;"];
}

-(void)testPlistObject
{
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key1"] equals:@"Some random characters"];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key2"] equals:[CPNumber numberWithBool:NO]];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key3"] equals:[CPNumber numberWithDouble:9.9]];
    [self assert:[[plist_data serializedPlistObject] objectForKey:@"key4"] equals:[CPNumber numberWithDouble:8.8]];
    
    [self assert:[plist_data serializedPlistObject] equals:dict];
}

-(void)testSetPlistObject
{
    var data = [[CPData alloc] init];
    [data setSerializedPlistObject:dict];

    [self assert:[data serializedPlistObject] equals:dict];
}

-(void)testSetString
{
    var data = [[CPData alloc] init];
    [data setString:@"CPData Test"];

    [self assert:[data encodedString] equals:@"CPData Test"];
}

@end
