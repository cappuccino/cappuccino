/*
 * AppController.j
 * CPPropertyListSerializationTest
 *
 * Created by You on March 9, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

var originalBase64Data = "YnBsaXN0MDDUAQIDBAUG6utYJHZlcnNpb25YJG9iamVjdHNZJGFyY2hpdmVyVCR0b3ASAAGGoK8QMwcIHyMkKi4yNj5MUF5fYGFzdHx9gIqLjJGUmZqdoqisrbGytr3AwcPK09yI3d7f4OHk51UkbnVsbNsJCgsMDQ4PEBESExQVFhcYGRobHB0dXxAQTlNWaXNpYmxlV2luZG93c11OU09iamVjdHNLZXlzVk5TUm9vdFxOU09pZHNWYWx1ZXNWJGNsYXNzWk5TT2lkc0tleXNdTlNDb25uZWN0aW9uc18QD05TT2JqZWN0c1ZhbHVlc18QGU5TQWNjZXNzaWJpbGl0eUNvbm5lY3RvcnNfEBdOU0FjY2Vzc2liaWxpdHlPaWRzS2V5c18QGU5TQWNjZXNzaWJpbGl0eU9pZHNWYWx1ZXOABYAjgAKAKYAygCiAB4AngDCAMYAx0g0gISJbTlNDbGFzc05hbWWABIADWE5TT2JqZWN00iUmJyhaJGNsYXNzbmFtZVgkY2xhc3Nlc15OU0N1c3RvbU9iamVjdKInKVhOU09iamVjdNINKywtWk5TLm9iamVjdHOABqDSJSYvMFxOU011dGFibGVTZXSjLzEpVU5TU2V00g0rMzSAHqE1gAjUDTc4OTo7PD1XTlNMYWJlbF1OU0Rlc3RpbmF0aW9uWE5TU291cmNlgCKAIYALgAnXPw1AQUJDRDxGR0hJSktdTlNOZXh0S2V5Vmlld1hOU3ZGbGFnc18QD05TTmV4dFJlc3BvbmRlcl8QFE5TUmV1c2VJZGVudGlmaWVyS2V5W05TRnJhbWVTaXplWk5TU3Vidmlld3OAC4AgEQESgACADYAfgArSDSszToAeoTyAC9lRUlNADUFCQ1RVVj1YWT1JXF1ZTlNFbmFibGVkVk5TQ2VsbFtOU1N1cGVydmlld18QGU5TQW50aUNvbXByZXNzaW9uUHJpb3JpdHkJgA+ACREBCoAdgAmADYAMgA5ZezExNiwgMTd9U05pYlp7MjUwLCA3NTB92WJjZGVmZ2gNaWprbEk8b3BxcltOU0NlbGxGbGFnc1xOU0NlbGxGbGFnczJaTlNDb250ZW50c18QEE5TQ2VsbElkZW50aWZpZXJdTlNDb250cm9sVmlld1tOU1RleHRDb2xvcllOU1N1cHBvcnRfEBFOU0JhY2tncm91bmRDb2xvchIEAf5AEhBACACAEIANgAuAGYARgByAFFdNeSBDRUxM1A11dnd4eXp7Vk5TTmFtZVZOU1NpemVYTlNmRmxhZ3OAE4ASI0AqAAAAAAAAEQQUXEx1Y2lkYUdyYW5kZdIlJn5/Vk5TRm9udKJ+KdWBDYKDhIWGh4iJXU5TQ2F0YWxvZ05hbWVbTlNDb2xvck5hbWVcTlNDb2xvclNwYWNlV05TQ29sb3KAFYAYgBYQBoAXVlN5c3RlbVxjb250cm9sQ29sb3LTDYONho+QV05TV2hpdGWAGBADTTAuNjY2NjY2NjY2NwDSJSaSk1dOU0NvbG9yopIp1YENgoOEhYaXiJiAFYAYgBqAG18QEGNvbnRyb2xUZXh0Q29sb3LTDYONho+cgBhCMADSJSaen18QD05TVGV4dEZpZWxkQ2VsbKSeoKEpXE5TQWN0aW9uQ2VsbFZOU0NlbGzSJSajpFtOU1RleHRGaWVsZKWjpaanKVlOU0NvbnRyb2xWTlNWaWV3W05TUmVzcG9uZGVy0iUmqapeTlNNdXRhYmxlQXJyYXmjqaspV05TQXJyYXlZezExNiwgMTd90iUmrq9fEA9OU1RhYmxlQ2VsbFZpZXeksKanKV8QD05TVGFibGVDZWxsVmlld1l0ZXh0RmllbGTSJSaztF8QFE5TTmliT3V0bGV0Q29ubmVjdG9yo7O1KV5OU05pYkNvbm5lY3RvctINK7e4gCakPTxWvIAJgAuAD4Ak0g0gIb+ABIAlXU5TQXBwbGljYXRpb27SJSarwqKrKdINK7fFgCakFj08FoACgAmAC4AC0g0rt8yAJqYWPTxWvDWAAoAJgAuAD4AkgAjSDSu31YAmptbX2Nna24AqgCuALIAtgC6ALxAFEAcQCBAJEArSDSsz44AeoNINK7fmgCag0iUm6OleTlNJQk9iamVjdERhdGGi6ClfEA9OU0tleWVkQXJjaGl2ZXLR7O1dSUIub2JqZWN0ZGF0YYABAAgAEQAaACMALQAyADcAbQBzAIoAnQCrALIAvwDGANEA3wDxAQ0BJwFDAUUBRwFJAUsBTQFPAVEBUwFVAVcBWQFeAWoBbAFuAXcBfAGHAZABnwGiAasBsAG7Ab0BvgHDAdAB1AHaAd8B4QHjAeUB7gH2AgQCDQIPAhECEwIVAiQCMgI7Ak0CZAJwAnsCfQJ/AoIChAKGAogCigKPApECkwKVAqgCsgK5AsUC4QLiAuQC5gLpAusC7QLvAvEC8wL9AwEDDAMfAysDOANDA1YDZANwA3oDjgOTA5gDmgOcA54DoAOiA6QDpgOuA7cDvgPFA84D0APSA9sD3gPrA/AD9wP6BAUEEwQfBCwENAQ2BDgEOgQ8BD4ERQRSBFkEYQRjBGUEcwR4BIAEgwSOBJAEkgSUBJYEqQSwBLIEtQS6BMwE0QTeBOUE6gT2BPwFBgUNBRkFHgUtBTEFOQVDBUgFWgVfBXEFewWABZcFmwWqBa8FsQW2BbgFugW8Bb4FwwXFBccF1QXaBd0F4gXkBekF6wXtBe8F8QX2BfgF/wYBBgMGBQYHBgkGCwYQBhIGGQYbBh0GHwYhBiMGJQYnBikGKwYtBi8GNAY2BjcGPAY+Bj8GRAZTBlYGaAZrBnkAAAAAAAACAQAAAAAAAADuAAAAAAAAAAAAAAAAAAAGew==";

@implementation AppController : CPObject
{
    CPDictionary deserializedData;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [theWindow orderFront:self];

    var path = [[CPBundle mainBundle] pathForResource:@"PropertyList.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var receivedData = [[CPData alloc] initWithRawString:dataString];

    deserializedData = [CPPropertyListSerialization propertyListFromData:receivedData format:CPPropertyListXMLFormat_v1_0];

    document.write("This test checks the class and value of objects deserialized from a CPPropertyListXMLFormat_v1_0 file</br></br>");

    [self testObjectForKey:@"Number" isKindOfClass:[CPNumber class]];
    [self testObjectForKey:@"Number" isEqual:12];

    [self testObjectForKey:@"Bool" isEqual:YES];

    [self testObjectForKey:@"String" isKindOfClass:[CPString class]];
    [self testObjectForKey:@"String" isEqual:@"String"];

    [self testObjectForKey:@"Data" isKindOfClass:[CPData class]];
    [self testObjectForKey:@"Dict" isKindOfClass:[CPDictionary class]];
    [self testObjectForKey:@"Dict.Number" isKindOfClass:[CPNumber class]];
    [self testObjectForKey:@"Dict.Data" isKindOfClass:[CPData class]];
    [self testObjectForKey:@"Dict.Bool" isEqual:YES];

    [self testObjectForKey:@"Array" isKindOfClass:[CPArray class]];

    // CPData -isEqual: is not implemented. Here we convert the CPData we get from CPPropertyListSerialization to base64 (using the CFData API) and compare with the original.

    var dataObject = [deserializedData objectForKey:@"Data"],
        base64 = CFData.encodeBase64Array(dataObject.bytes()),
        isvalue = (base64 == originalBase64Data);

    if (isvalue)
        document.write(@"Key Data base64: TEST PASSED");
    else
        document.write(@"Key Data base64 should be :" + originalBase64Data + " was: " + base64);
}

- (void)testObjectForKey:(CPString)aKey isKindOfClass:(Class)aClass
{
    var value = [deserializedData valueForKeyPath:aKey],
        result;

    if ([[value class] isKindOfClass:aClass])
        result = @"Key " + aKey + " class: TEST PASSED </br>";
    else
        result = @"Key " + aKey + "should be of class:" + aClass + " was: " + [value class] + "</br>";

    document.write(result);
}

- (void)testObjectForKey:(CPString)aKey isEqual:(id)aValue
{
    var value = [deserializedData valueForKeyPath:aKey];

    if (value == aValue || [value isEqual:aValue])
        result = @"Key " + aKey + " value: TEST PASSED </br>";
    else
        result = @"Key " + aKey + "should be :" + aValue + " was: " + value  + "</br>";

    document.write(result);
}

@end
