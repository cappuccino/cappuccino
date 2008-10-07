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
- (void)testBoolValue
{
    var testStrings = [
        ["  090",  YES],
        ["  YES",  YES],
        ["  true", YES],
        ["  True", YES],
        ["  tTR",  YES],
        ["  +98",  YES],
        ["  -98",  YES],
        ["  +08",  YES],
        ["  -98",  YES],
        ["  NO",    NO],
        ["  -N00",  NO],
        ["  00",    NO],
        ["  -00",   NO]
    ];
    
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] boolValue] equals:testStrings[i][1]];
}

- (void)testCapitalizedString
{
    var testStrings = [
        ["", ""],
        ["hElLo wOrLd", "Hello World"],
        [" monkey-Cow", " Monkey-cow"],
        ["tHe QuicK bRowN-Fox JumPed_Over +the LaZy%dog", "The Quick Brown-fox Jumped_over +the Lazy%dog"]
    ];
    
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] capitalizedString] equals:testStrings[i][1]];
}



@end
