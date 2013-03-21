@import <Foundation/CPString.j>
@import <Foundation/CPCharacterSet.j>

@implementation CPStringTest : OJTestCase


- (void)testStringByReplacingOccurrencesOfStringWithString
{
    var expectedString = @"hello world. A new world!",
        dummyString = @"hello woold. A new woold!",
        actualString = [dummyString stringByReplacingOccurrencesOfString:@"woold" withString:@"world"];

    [self assertTrue:(expectedString === actualString)
             message:"stringByAppendingFormat: expected:" + expectedString + " actual:" + actualString];
}

- (void)testStringByReplacingWithRegexCharacters
{
    var stringToTest = "${foo} {foo}",
        result = [stringToTest stringByReplacingOccurrencesOfString:"${foo}" withString:"BAR"];

    [self assert:result equals:"BAR {foo}"];
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

- (void)testInitWithFormat
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

    var sawException = false;
    try
    {
        [@"abcd" substringToIndex:5];
    }
    catch (anException)
    {
        sawException = true;
        [self assert:CPRangeException equals:[anException name]];
    }
    [self assertTrue:sawException message:"expected CPRangeException"];
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
            ["  -00",   NO],
            ["  -+001", NO],
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] boolValue] equals:testStrings[i][1]];
}

- (void)testCommonPrefixWithString
{
    var testStringsCase = [
            ["Hello", "Helicopter", "Hel"],
            ["Tester", "Taser", "T"],
            ["Abcd", "Abcd", "Abcd"],
            ["A long string", "A longer string", "A long"]
        ];

    var testStringsCaseless = [
            ["hElLo", "HeLiCoPtEr", "hEl"],
            ["tEsTeR", "TaSeR", "t"],
            ["aBcD", "AbCd", "aBcD"],
            ["a LoNg StRiNg", "A lOnGeR sTrInG", "a LoNg"]
        ];

    for (var i = 0; i < testStringsCase.length; i++)
        [self assert: [testStringsCase[i][0] commonPrefixWithString:testStringsCase[i][1]]
              equals: testStringsCase[i][2]];

    for (var i = 0; i < testStringsCaseless.length; i++)
        [self assert: [testStringsCaseless[i][0] commonPrefixWithString: testStringsCaseless[i][1]
                                                 options: CPCaseInsensitiveSearch]
              equals: testStringsCaseless[i][2]];
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

- (void)testStringByAppendingPathComponent
{
    var testStrings = [
            ["/tmp/", "scratch.tiff", "/tmp/scratch.tiff"],
            ["/tmp///", "scratch.tiff", "/tmp/scratch.tiff"],
            ["/tmp///", "///scratch.tiff", "/tmp/scratch.tiff"],
            ["/tmp", "scratch.tiff", "/tmp/scratch.tiff"],
            ["/tmp///", "scratch.tiff", "/tmp/scratch.tiff"],
            ["/tmp///", "///scratch.tiff", "/tmp/scratch.tiff"],
            ["/", "scratch.tiff", "/scratch.tiff"],
            ["", "scratch.tiff", "scratch.tiff"],
            ["", "", ""],
            ["", "/", ""],
            ["/", "/", "/"],
            ["/tmp", nil, "/tmp"],
            ["/tmp", "/", "/tmp"],
            ["/tmp/", "", "/tmp"]
        ];

    for (var i = 0; i < testStrings.length; i++)
    {
        var result = [testStrings[i][0] stringByAppendingPathComponent:testStrings[i][1]];

        [self assertTrue:result === testStrings[i][2] message:"Value <" + testStrings[i][0] + "> Adding <" + testStrings[i][1] + "> Expected <" + testStrings[i][2] + "> was <" + result + ">"];
    }
}

- (void)testStringByAppendingPathExtension
{
    var testStrings = [
            ["/tmp/scratch.old", "tiff", "/tmp/scratch.old.tiff"],
            ["/tmp/scratch.", "tiff", "/tmp/scratch..tiff"],
            ["/tmp///", "tiff", "/tmp.tiff"],
            ["scratch", "tiff", "scratch.tiff"],
            ["/", "tiff", "/"],
            ["", "tiff", ""]
        ];

    for (var i = 0; i < testStrings.length; i++)
    {
        var result = [testStrings[i][0] stringByAppendingPathExtension:testStrings[i][1]];

        [self assertTrue:result === testStrings[i][2] message:"Value <" + testStrings[i][0] + "> Adding <" + testStrings[i][1] + "> Expected <" + testStrings[i][2] + "> was <" + result + ">"];
    }
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
            ["a/b/////////c/d//////",  "a/b/c"],
            ["a/b/././././c/d/./././", "a/b/././././c/d/./."],
            [@"a/b/././././d////", "a/b/./././."],
            [@"~/a", "~"],
            [@"~/a/", "~"],
            [@"../../", ".."],
            [@"", ""]
        ];

    for (var i = 0; i < testStrings.length; i++)
    {
        var result = [testStrings[i][0] stringByDeletingLastPathComponent];

        [self assertTrue:result === testStrings[i][1] message:"Value <" + testStrings[i][0] + "> Expected <" + testStrings[i][1] + "> was <" + result + ">"];
    }
}

- (void)testPathWithComponents
{
    var testStrings = [
            [["tmp", "scratch"], "tmp/scratch"],
            [["/", "tmp", "scratch"], "/tmp/scratch"],
            [["/", "tmp", "/", "scratch"], "/tmp/scratch"],
            [["/", "tmp", "scratch", "/"], "/tmp/scratch"],
            [["/", "tmp", "scratch", ""], "/tmp/scratch"],
            [["", "/tmp", "scratch", ""], "/tmp/scratch"],
            [["", "tmp", "scratch", ""], "tmp/scratch"],
            [["/"], "/"],
            [["/", "/", "/"], "/"],
            [["", "", ""], ""],
            [[""], ""]
        ];

    for (var i = 0; i < testStrings.length; i++)
    {
        var result = [CPString pathWithComponents:testStrings[i][0]];

        [self assertTrue:result === testStrings[i][1] message:"Value <" + testStrings[i][0] + "> Expected [" + testStrings[i][1] + "] was [" + result + "]"];
    }
}

- (void)testPathComponents
{
    var testStrings = [
            ["tmp/scratch", ["tmp", "scratch"]],
            ["/tmp/scratch", ["/", "tmp", "scratch"]],
            ["/tmp/scratch/", ["/", "tmp", "scratch", "/"]],
            ["/tmp/", ["/", "tmp", "/"]],
            ["/////tmp/////scratch///", ["/", "tmp", "scratch", "/"]],
            ["scratch.tiff", ["scratch.tiff"]],
            ["/", ["/"]],
            ["", [""]]
        ];

    for (var i = 0; i < testStrings.length; i++)
    {
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
            ["/", "/"],
            ["", ""]
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:testStrings[i][1] equals:[testStrings[i][0] lastPathComponent]];
}

- (void)testPathExtension
{
    var testStrings = [
            ["/tmp/scratch.tiff", "tiff"],
            ["scratch.png", "png"],
            ["/tmp/scratch..tiff", "tiff"],
            ["/tmp", ""],
            ["scratch", ""],
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:testStrings[i][1] equals:[testStrings[i][0] pathExtension]];
}

- (void)testStringByDeletingPathExtension
{
    var testStrings = [
            ["/tmp/scratch.tiff", "/tmp/scratch"],
            ["scratch.png", "scratch"],
            ["/tmp/scratch..tiff", "/tmp/scratch."],
            ["/tmp", "/tmp"],
            [".tiff", ".tiff"],
            ["/", "/"],
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:testStrings[i][1] equals:[testStrings[i][0] stringByDeletingPathExtension]];
}

- (void)testHasPrefix
{
    [self assertTrue: ["abc" hasPrefix:"a"]];
    [self assertTrue: ["abc" hasPrefix:"ab"]];
    [self assertTrue: ["abc" hasPrefix:"abc"]];
    [self assertFalse:["abc" hasPrefix:"abcd"]];
    [self assertFalse:["abc" hasPrefix:"dbc"]];
    [self assertFalse:["abc" hasPrefix:"bc"]];
    [self assertFalse:["abc" hasPrefix:"c"]];
    [self assertFalse:["abc" hasPrefix:""]];
}

- (void)testHasSuffix
{
    [self assertTrue: ["abc" hasSuffix:"c"]];
    [self assertTrue: ["abc" hasSuffix:"bc"]];
    [self assertTrue: ["abc" hasSuffix:"abc"]];
    [self assertFalse:["abc" hasSuffix:"abcd"]];
    [self assertFalse:["abc" hasSuffix:"ab"]];
    [self assertFalse:["abc" hasSuffix:"b"]];
    [self assertFalse:["abc" hasSuffix:"cat"]];
    [self assertFalse:["abc" hasSuffix:""]];
}

- (void)testComponentsSeparatedByCharactersInSetEmptyString
{
    [self assert:[""]
          equals:["" componentsSeparatedByCharactersInSet:[CPCharacterSet whitespaceCharacterSet]]];
}

- (void)testComponentsSeparatedByCharactersInSetStringWithoutCharactersFromSet
{
    [self assert:["Abradab"]
          equals:["Abradab" componentsSeparatedByCharactersInSet:[CPCharacterSet whitespaceCharacterSet]]];
}

- (void)testComponentsSeparatedByCharactersInSet
{
    [self assert:["Baku", "baku", "to", "jest", "", "skład."]
          equals:["Baku baku to jest  skład." componentsSeparatedByCharactersInSet:[CPCharacterSet whitespaceCharacterSet]]];
}

- (void)testComponentsSeparatedByCharactersInSetLeadingAndTrailingCharacterFromSet
{
    [self assert:["", "Test", ""]
          equals:[" Test " componentsSeparatedByCharactersInSet:[CPCharacterSet whitespaceCharacterSet]]];
}

- (void)testComponentsSeparatedByCharactersExceptionRaiseOnNilSeparator
{
    try
    {
        [[CPString string] componentsSeparatedByCharactersInSet:nil];
        [self assert:false];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPInvalidArgumentException];
        [self assert:[anException reason] equals:@"componentsSeparatedByCharactersInSet: the separator can't be 'nil'"];
    }
}

- (void)testIsEqual
{
    var str = "s";
    [self assert:str equals:[CPString stringWithString:str]];
    [self assert:str equals:[str copy]];
    [self assert:[str copy] equals:str];
    [self assert:[str copy] equals:[str copy]];
}

- (void)testRangeOfString
{
    // Based on the Cocoa "String Programming Guide" example.
    var searchString = @"age",
        beginsTest = @"Agencies",
        prefixRange = [beginsTest rangeOfString:searchString options:(CPCaseInsensitiveSearch)];

    [self assert:0 equals:prefixRange.location message:@"forward search for age (location)"];
    [self assert:3 equals:prefixRange.length message:@"forward search for age (length)"];

    var endsTest = @"BRICOLAGE",
        suffixRange = [endsTest rangeOfString:searchString options:(CPCaseInsensitiveSearch | CPBackwardsSearch)];

    [self assert:6 equals:suffixRange.location message:@"backwards search for age (location)"];
    [self assert:3 equals:suffixRange.length message:@"backwards search for age (length)"];
}

- (void)testRangeOfString_Anchored_Backwards
{
    var endsTest = @"AGEBRICOLAGE",
        unAnchoredSuffixRange = [endsTest rangeOfString:@"LAG" options:(CPCaseInsensitiveSearch | CPBackwardsSearch)],
        anchoredSuffixRange = [endsTest rangeOfString:@"LAG" options:(CPAnchoredSearch | CPCaseInsensitiveSearch | CPBackwardsSearch)];

    [self assert:8 equals:unAnchoredSuffixRange.location message:"backwards search for LAG"];
    [self assert:CPNotFound equals:anchoredSuffixRange.location message:"anchored backwards search for LAG"];

    anchoredSuffixRange = [endsTest rangeOfString:@"AGE" options:(CPAnchoredSearch | CPCaseInsensitiveSearch | CPBackwardsSearch)];
    [self assert:9 equals:anchoredSuffixRange.location message:"anchored backwards search for AGE"];

    anchoredSuffixRange = [endsTest rangeOfString:endsTest options:(CPAnchoredSearch | CPCaseInsensitiveSearch | CPBackwardsSearch)];
    [self assert:0 equals:anchoredSuffixRange.location message:"anchored backwards search for whole string (location)"];
    [self assert:endsTest.length equals:anchoredSuffixRange.length message:"anchored backwards search for whole string (length)"];

    anchoredSuffixRange = [endsTest rangeOfString:@"" options:(CPAnchoredSearch | CPCaseInsensitiveSearch | CPBackwardsSearch)];
    [self assert:CPNotFound equals:anchoredSuffixRange.location message:"anchored backwards search for nothing (location)"];
    [self assert:0 equals:anchoredSuffixRange.length message:"anchored backwards search for nothing (length)"];
}

- (void)testRangeOfString_options_range
{
    var testString = @"In another life you would have made a excellent criminal.",
        hitRange;

    hitRange = [testString rangeOfString:@"life" options:0 range:CPMakeRange(0, testString.length)];
    [self assert:11 equals:hitRange.location message:@"search for 'life' in full range (location)"];
    [self assert:4 equals:hitRange.length message:@"search for 'life' in full range (position)"];

    hitRange = [testString rangeOfString:@"i" options:0 range:CPMakeRange(0, testString.length)];
    [self assert:12 equals:hitRange.location message:@"search for 'i' in full range (location)"];
    [self assert:1 equals:hitRange.length message:@"search for 'i' in full range (position)"];

    hitRange = [testString rangeOfString:@"i" options:0 range:CPMakeRange(10, 20)];
    [self assert:12 equals:hitRange.location message:@"search for 'i' in partial range (location)"];
    [self assert:1 equals:hitRange.length message:@"search for 'i' in partial range (position)"];

    var sawException = false;
    try
    {
        hitRange = [testString rangeOfString:@"i" options:0 range:CPMakeRange(50, 60)];
    }
    catch (anException)
    {
        sawException = true;
        [self assert:CPRangeException equals:[anException name]];
    }
    [self assertTrue:sawException message:"expected CPRangeException"];
}

- (void)testStringByTrimmingCharactersInSet
{
    var startOneString = @".This is a test startOne",
        startManyString = @".,.This is a test startMany",
        endOneString = @"This is a test endOne.",
        endManyString = @"This is a test endMany.,.",
        bothOneString = @".This is a test bothOne,",
        bothManyString = @".,,This is a test bothMany..,",
        noneString = @"This is a test none",
        set = [CPCharacterSet characterSetWithCharactersInString:@".,"];

    [self assert:"This is a test startOne" equals:[startOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test startMany" equals:[startManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test endOne" equals:[endOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test endMany" equals:[endManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test bothOne" equals:[bothOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test bothMany" equals:[bothManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test none" equals:[noneString stringByTrimmingCharactersInSet:set]];
}

- (void)testStringByTrimmingWhitespace
{
    var startOneString = @" This is a test startOne",
        startManyString = @"   This is a test startMany",
        endOneString = @"This is a test endOne ",
        endManyString = @"This is a test endMany   ",
        bothOneString = @" This is a test bothOne ",
        bothManyString = @"   This is a test bothMany   ",
        noneString = @"This is a test none",
        set = [CPCharacterSet characterSetWithCharactersInString:@" "];

    [self assert:"This is a test startOne" equals:[startOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test startMany" equals:[startManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test endOne" equals:[endOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test endMany" equals:[endManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test bothOne" equals:[bothOneString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test bothMany" equals:[bothManyString stringByTrimmingCharactersInSet:set]];
    [self assert:"This is a test none" equals:[noneString stringByTrimmingCharactersInSet:set]];
}

@end
