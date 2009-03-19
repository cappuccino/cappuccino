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
    var format = @"%d X %d = %d",
        expectedString = "2 X 3 = 6",
        dummyString = @"",
        actualString = [dummyString stringByAppendingFormat:format, 2, 3, 6];
        
    [self assertTrue:(expectedString === actualString) 
             message:"stringByAppendingFormat: expected:" + expectedString + " actual:" + actualString];
}

- (void)testStringWithString
{
    var original = [[CPString alloc] initWithString:"str"],
        copy = [CPString stringWithString:original];

    [self assertTrue:(original == copy) message:"Contents should be equal"];
}

- (void)testInitWithString
{
    var str = [[CPString alloc] initWithString:"str"];
    [self assert:"str" equals:str];
}

- (void) testInitWithFormat
{
    // this could be really big
    var str = [[CPString alloc] initWithFormat:"%s", "str"];
    [self assert:"str" equals:str];

    str = [[CPString alloc] initWithFormat:"%d", 42];
    [self assert:"42" equals:str];

    str = [[CPString alloc] initWithFormat:"%f", 42.2];
    [self assert:"42.2" equals:str];    
}

- (void)testStringWithFormat
{
    // this could be equally big
    var str = [CPString stringWithFormat:"%s", "str"];
    [self assert:"str" equals:str];

    str = [CPString stringWithFormat:"%d", 42];
    [self assert:"42" equals:str];

    str = [CPString stringWithFormat:"%f", 42.2];
    [self assert:"42.2" equals:str];    
}

- (void)testLength
{
    [self assert:0 equals:["" length]];
    [self assert:1 equals:["a" length]];
    [self assert:5 equals:["abcde" length]];
    [self assert:3 equals:["日本語" length]];
}

- (void)testCharacterAtIndex
{
    [self assert:"a" equals:["abcd" characterAtIndex:0]];
    [self assert:"b" equals:["abcd" characterAtIndex:1]];
    [self assert:"d" equals:["abcd" characterAtIndex:3]];
    [self assert:"語" equals:["日本語" characterAtIndex:2]];
}

- (void)testStringByAppendingSting
{
    [self assert:"onetwo" equals:["one" stringByAppendingString:"two"]];
}


- (void)testStringByPaddingToLength
{
    [self assert:"onebcd" 
	      equals:["one" stringByPaddingToLength:6 
			                         withString:"abcdefg"
	                            startingAtIndex:1]];
}

- (void)testComponentsSeparatedByString
{
    [self assert:["arash", "francisco", "ross", "tom"]
	  equals:["arash.francisco.ross.tom" componentsSeparatedByString:"."]];
}

- (void)testSubstringFromIndex
{
    [self assert:"abcd" equals:["abcd" substringFromIndex:0]];
    [self assert:"bcd"  equals:["abcd" substringFromIndex:1]];
    [self assert:""     equals:["abcd" substringFromIndex:4]];
}

- (void)testSubstringWithRange
{
    [self assert:"bcd"   equals:["abcde" substringWithRange:CPMakeRange(1,3)]];
    [self assert:"abcde" equals:["abcde" substringWithRange:CPMakeRange(0,5)]];
    [self assert:""      equals:["abcde" substringWithRange:CPMakeRange(1,0)]];
}

- (void)testSubstringToIndex
{
    [self assert:"abcd" equals:["abcd" substringToIndex:4]];
    [self assert:"abc"  equals:["abcd" substringToIndex:3]];
    [self assert:""     equals:["abcd" substringToIndex:0]];
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

- (void)testUppercaseString
{
    var str = "This is a test";
    [self assert:[str uppercaseString] equals:"THIS IS A TEST"];
}
 
- (void)testLowercaseString
{
    var str = "This Is A TEST";
    [self assert:"this is a test" equals:[str lowercaseString]];
}

- (void)testStringWithHash
{
    [self assert:"000000" equals:[CPString stringWithHash:0]];
    [self assert:"000001" equals:[CPString stringWithHash:1]];
    [self assert:"00000a" equals:[CPString stringWithHash:10]];
    [self assert:"000010" equals:[CPString stringWithHash:16]];
    [self assert:"ffffff" equals:[CPString stringWithHash:16777215]];
}

- (void)testStringByDeletingLastPathComponent
{
    var testStrings = [
        ["/tmp/scratch.tiff", "/tmp"],
        ["/tmp/lock/", "/tmp"],
        ["/tmp/", "/"],
        ["/tmp", "/"],
        ["/", "/"],
        ["scratch.tiff", ""],
        ["a/b/c/d//////",  "a/b/c"],
        ["a/b/././././c/d/./././", "a/b/././././c/d/./."],
        [@"a/b/././././d////", "a/b/./././."],
        [@"~/a", "~"],
        [@"~/a/", "~"],
        [@"../../", ".."]
    ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] stringByDeletingLastPathComponent] equals:testStrings[i][1]];
}

- (void)testPathComponents
{
    var testStrings = [
        ["tmp/scratch", ["tmp", "scratch"]],
        ["/tmp/scratch", ["/", "tmp", "scratch"]]
    ]
    
    for (var i = 0; i < testStrings.length; i++) {
        var result = [testStrings[i][0] pathComponents];
        [self assertTrue:[result isEqualToArray:testStrings[i][1]] message:"Expected [" + testStrings[i][1] + "] was [" + result + "]"];
    }
}

- (void)testLastPathComponent
{
    var testStrings = [
        ["/tmp/scratch.tiff", "scratch.tiff"],
        ["/tmp/scratch", "scratch"],
        ["/tmp/", "tmp"],
        ["scratch", "scratch"],
        ["/", "/"]
    ];
        
    for (var i = 0; i < testStrings.length; i++)
        [self assert:testStrings[i][1] equals:[testStrings[i][0] lastPathComponent]];
}

@end
