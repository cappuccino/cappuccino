@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPLog.j>
@import <Foundation/CPNumber.j>

@implementation CPDataTest : OJTestCase
{
    
}

-(void)setUp
{
    string_data = [[CPData alloc] initWithString:@"CPData Test"];
    
    // Plist helpers
    keys = [CPArray arrayWithObjects:@"key1", @"key2", @"key3", @"key4", nil];
    objects = [CPArray arrayWithObjects:@"Some random characters", [CPNumber numberWithBool:NO], [CPNumber numberWithDouble:9.9], [CPNumber numberWithDouble:8.8], nil];
    dict = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
}

-(void)testStringLength
{
    var data = [[CPData alloc] initWithString:@"CPData Test"];
    [self assert:[data length] equals:[CPNumber numberWithInt:11]];
    
    var data_cm = [CPData dataWithString:@"CPData Test"];
    [self assert:[data_cm length] equals:[CPNumber numberWithInt:11]];
}

-(void)testPlistLength
{
    var data = [[CPData alloc] initWithPlistObject:dict];
    [self assert:[data length] equals:[CPNumber numberWithInt:93]];

    var data_cm = [CPData dataWithPlistObject:dict];
    [self assert:[data length] equals:[CPNumber numberWithInt:93]];
}

-(void)testDescription
{
    [self assert:[string_data description] equals:[string_data string]];
}

-(void)testString
{
    [self assert:[string_data string] equals:@"CPData Test"];
}

-(void)testStringFromPlist
{
    var plist_data = [[CPData alloc] initWithPlistObject:dict];
    [self assert:[plist_data string] equals:"280NPLIST;1.0;D;K;4;key4f;3;8.8K;4;key3f;3;9.9K;4;key2F;K;4;key1S;22;Some random charactersE;"];
}

-(void)testPlistObject
{
    var plist_data = [[CPData alloc] initWithPlistObject:dict];
    [self assert:[[plist_data plistObject] objectForKey:@"key1"] equals:@"Some random characters"];
    [self assert:[[plist_data plistObject] objectForKey:@"key2"] equals:[CPNumber numberWithBool:NO]];
    [self assert:[[plist_data plistObject] objectForKey:@"key3"] equals:[CPNumber numberWithDouble:9.9]];
    [self assert:[[plist_data plistObject] objectForKey:@"key4"] equals:[CPNumber numberWithDouble:8.8]];
    
    [self assert:[plist_data plistObject] equals:dict];
}

-(void)testSetPlistObject
{
    var data = [[CPData alloc] init];
    [data setPlistObject:dict];
    
    [self assert:[data plistObject] equals:dict];
}

-(void)testSetString
{
    var data = [[CPData alloc] init];
    [data setString:@"CPData Test"];
    
    [self assert:[data string] equals:@"CPData Test"];
}
@end