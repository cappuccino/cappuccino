import <Foundation/CPString.j>

@implementation CPStringTest : OJTestCase


- (void)testStringByReplacingOccurrencesOfStringWithString
{
    var expectedString = @"hello world. A new world!";
    var dummyString = @"hello woold. A new woold!";
    var actualString = [dummyString stringByReplacingOccurrencesOfString:@"woold" withString:@"world"];
    [self assertTrue:(expectedString === actualString) 
             message:"stringByAppendingFormat: expected:" + expectedString + " actual:" + actualString];
    
    
    
}
- (void)testStringByAppendingFormat
{
    var format = @"%d X %d = %d";
    var expectedString = "2 X 3 = 6";
    var dummyString = @"";
    var actualString = [dummyString stringByAppendingFormat:format ,2 ,3 ,6];
    [self assertTrue:(expectedString === actualString) 
             message:"stringByAppendingFormat: expected:" + expectedString + " actual:" + actualString];
    
}
- (void) testBoolValue
{
    var testString = @"  090";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
    
    testString = @"  YES";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
    
    testString = @"  true";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
    
    testString = @"  True";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  tTR";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  +98";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  -98";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  +08";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  -98";
    [self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

    testString = @"  NO";
    [self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return false"];
    
    testString = @"  -N00";
    [self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return false"];
    
    testString = @"  00";
    [self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return false"];
    
    testString = @"  -00";
    [self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return false"];
    
}



@end
