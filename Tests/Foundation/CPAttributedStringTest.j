
@import <Foundation/CPAttributedString.j>

var sharedObject = [CPObject new];

@implementation CPAttributedStringTest : OJTestCase

- (CPAttributedString)stringForTesting
{
    var string = [[CPAttributedString alloc] initWithString:"The quick brown fox jumped over the lazy dog."];

    string._rangeEntries = [];

    string._rangeEntries.push({
        range:CPMakeRange(0, 9),
        attributes:[CPDictionary dictionaryWithObjects:[1, "bar", sharedObject, 20] forKeys:["a", "b", "c", "d"]]
    });
    string._rangeEntries.push({
        range:CPMakeRange(9, 11),
        attributes:[CPDictionary dictionaryWithObjects:[2, "baz", sharedObject] forKeys:["a", "b", "c"]]
    });
    string._rangeEntries.push({
        range:CPMakeRange(20, 12),
        attributes:[CPDictionary dictionaryWithObjects:[2, "baz", "astring", [CPNull null]] forKeys:["a", "b", "c", "d"]]
    });
    string._rangeEntries.push({
        range:CPMakeRange(32, 13),
        attributes:[CPDictionary dictionaryWithObjects:[37, "baz", 1, 20, 55, 43] forKeys:["a", "b", "c", "d", "e", "f"]]
    });

    return string;
}

- (void)testInitWithString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string string] === @"hi there")
             message:"testInitWithString: expected:" + @"hi there" + " actual:" + [string string]];
}
- (void)testInitWithAttributedString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"],
        attributedString = [[CPAttributedString alloc] initWithAttributedString:string];

    [self assertTrue:([string isEqualToAttributedString:attributedString])
             message:"testInitWithAttributedString: expected:" + string + " actual:" + attributedString];

    //TODO add a case where we init with a string that actually adds attributes
    string = [[CPAttributedString alloc] initWithAttributedString:[self stringForTesting]];

    [self assertTrue:([string isEqualToAttributedString:[self stringForTesting]])
             message:"testInitWithAttributedString: expected:" + [self stringForTesting] + " actual:" + string];
}

- (void)testIinitWithString_attributes
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there" attributes:@{}];

    [self assertTrue:([string string] === @"hi there")
             message:"testIinitWithString_attributes: expected:" + @"hi there" + " actual:" + [string string]];

    var string = [[CPAttributedString alloc] initWithString:@"hi there" attributes:[CPDictionary dictionaryWithObjects:[1, "bar"] forKeys:["number", "foo"]]];

    [self assertTrue:([[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"number"] === 1)
             message:"testIinitWithString_attributes: value for key 'number' expected:" + 1 + " actual:" + [[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"number"]];

    [self assertTrue:([[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"foo"] === "bar")
             message:"testIinitWithString_attributes: value for key 'foo' expected:" + "bar" + " actual:" + [[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"foo"]];
}

//Retrieving Character Information
- (void)testString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string string] === string._string)
             message:"testString: expected:" + @"hi there" + " actual:" + [string string]];
}

- (void)testLength
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string length] === 8)
             message:"testLength: expected:" + 8 + " actual:" + [string length]];

    [self assertTrue:([[self stringForTesting] length] === 45)
             message:"testLength: expected:" + 45 + " actual:" + [[self stringForTesting] length]];
}

- (void)test_indexOfEntryWithIndex
{
    var string = [self stringForTesting];

    [self assertTrue:[string _indexOfEntryWithIndex:0] === 0 message:@"expecting index 0, was:" + [string _indexOfEntryWithIndex:0]];
    [self assertTrue:[string _indexOfEntryWithIndex:10] === 1 message:@"expecting index 1, was:" + [string _indexOfEntryWithIndex:10]];
    [self assertTrue:[string _indexOfEntryWithIndex:30] === 2 message:@"expecting index 2, was:" + [string _indexOfEntryWithIndex:30]];
    [self assertTrue:[string _indexOfEntryWithIndex:35] === 3 message:@"expecting index 3, was:" + [string _indexOfEntryWithIndex:35]];
    [self assertTrue:[string _indexOfEntryWithIndex:8] === 0 message:@"expecting index 0, was:" + [string _indexOfEntryWithIndex:8]];
    [self assertTrue:[string _indexOfEntryWithIndex:9] === 1 message:@"expecting index 1, was:" + [string _indexOfEntryWithIndex:9]];
    [self assertTrue:[string _indexOfEntryWithIndex:20] === 2 message:@"expecting index 2, was:" + [string _indexOfEntryWithIndex:20]];
    [self assertTrue:[string _indexOfEntryWithIndex:32] === 3 message:@"expecting index 3, was:" + [string _indexOfEntryWithIndex:32]];
}

//Retrieving Attribute Information
- (void)testAttributesAtIndexEffectiveRange
{
    var string = [self stringForTesting],
        expectedValues = {a:1, b:"bar", c:sharedObject, d:20};

    testAttributesAtIndexWithValues(string, 1, expectedValues, self);

    expectedValues = {a:37, b:"baz", f:43}

    testAttributesAtIndexWithValues(string, 33, expectedValues, self);
}

//- (CPDictionary)attributesAtIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
- (void)testAttributesAtIndexLongestEffectiveRangeInRange
{
    var string = [self stringForTesting];

    string._rangeEntries[3].range.length = 10;
    string._rangeEntries.push({range:CPMakeRange(42, 3), attributes:[string._rangeEntries[3].attributes copy]});

    var range = CPMakeRange(0, 0),
        attributes = [string attributesAtIndex:35 longestEffectiveRange:range inRange:CPMakeRange(0, 43)];

    [self assertTrue:CPMaxRange(range) == 43 message:@"expecting attributes to be valuable at range 43, was: " + CPMaxRange(range)];
    [self assertTrue:range.location == 32 message:@"expecting attributes to be valuable at range 32, was: " + range.location];

    [self assertTrue:[attributes objectForKey:"a"] === 37 message:@"expecting 'a' to be '1', was: " + [attributes objectForKey:"a"]];
    [self assertTrue:[attributes objectForKey:"b"] === "baz" message:@"expecting 'b' to be 'baz', was: " + [attributes objectForKey:"b"]];
    [self assertTrue:[attributes objectForKey:"f"] === 43 message:@"expecting 'f' to be 43, was: " + [attributes objectForKey:"f"]];
}

//- (id)attribute:(CPString)attribute atIndex:(unsigned)index effectiveRange:(CPRangePointer)aRange
- (void)testAttributeAtIndexEffectiveRange
{
    var string = [self stringForTesting];

    testAttributeAtIndexWithValue(string, 1, "a", 1, self);
    testAttributeAtIndexWithValue(string, 20, "d", [CPNull null], self);
}

//- (id)attribute:(CPString)attribute atIndex:(unsigned)index longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
- (void)testAttributeAtIndexLongestEffectiveRangeInRange
{
    var string = [self stringForTesting];

    var range = CPMakeRange(0, 0),
        attribute = [string attribute:"b" atIndex:35 longestEffectiveRange:range inRange:CPMakeRange(0, 43)];

    [self assertTrue:CPMaxRange(range) == 43 message:@"expecting attributes to be valuable at range 43, was: " + CPMaxRange(range)];
    [self assertTrue:range.location == 9 message:@"expecting attributes to be valuable at range 9, was: " + range.location];

    [self assertTrue:attribute === "baz" message:@"expecting 'b' to be 'baz', was: " + attribute];
}

//Comparing Attributed Strings
- (void)testIsEqualToAttributedString
{
    [self assertTrue:[[self stringForTesting] isEqualToAttributedString:[self stringForTesting]] message:"expected stringForTesting to equal itself, but it didn't"];

    [self assertFalse:[[self stringForTesting] isEqualToAttributedString:[[CPAttributedString alloc] initWithString:@"HELLO!"]] message:"Expected stringForTesting to not equal 'HELLO!', but it did"];
}

- (void)testIsEqual
{
    [self assertTrue:[[self stringForTesting] isEqual:[self stringForTesting]] message:"expected stringForTesting to equal itself, but it didn't"];

    [self assertFalse:[[self stringForTesting] isEqual:[[CPAttributedString alloc] initWithString:@"HELLO!"]] message:"Expected stringForTesting to not equal 'HELLO!', but it did"];

    var a = [self stringForTesting];

    [self assertTrue:[a isEqual:a] message:"expected a to equal itself, but it didn't"];

    [self assertFalse:[a isEqual:@"HELLO!"] message:"Expected a to not equal 'HELLO!', but it did"];
}

//Extracting a Substring
//- (CPAttributedString)attributedSubstringFromRange:(CPRange)aRange
- (void)testAttributedSubstringFromRange
{
    var a = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(0, 9)],
        expectedValues = {a:1, b:"bar", c:sharedObject, d:20};

    testAttributesAtIndexWithValues(a, 0, expectedValues, self);

    var b = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(0, 10)],
        expectedValues = {a:1, b:"bar", c:sharedObject, d:20};

    testAttributesAtIndexWithValues(b, 0, expectedValues, self);

    var c = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(0, 45)];
    [self assertTrue:[c isEqual:[self stringForTesting]] message:"expected c to equal itself, but it didn't"];

    var d = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(9, 11)],
        expectedValues = {a:2, b:"baz", c:sharedObject};

    testAttributesAtIndexWithValues(d, 0, expectedValues, self);

    var e = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(8, 30)],
        expectedValues = {a:2, b:"baz", c:"astring", d:[CPNull null]};

    testAttributesAtIndexWithValues(e, 13, expectedValues, self);

    [self assertTrue:CPEqualRanges(e._rangeEntries[0].range, CPMakeRange(0, 1)) message:"expected range to be {0, 1}, was " + CPStringFromRange(e._rangeEntries[0].range)];
}

//Changing Characters
//- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
- (void)testReplaceCharactersInRangeWithString
{
    var string = [self stringForTesting];

    [string replaceCharactersInRange:CPMakeRange(10, 5) withString:"firetruck red"];

    [self assertTrue:[string string] === "The quick firetruck red fox jumped over the lazy dog." message:"replacing 'brown' with 'firetruck red' produced: " + [string string].substr(10, 5)];

    testAttributesAtIndexWithValues(string, 21, {a:2, b:"baz", c:sharedObject}, self);
    testAttributesAtIndexWithValues(string, 40, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);
    testAttributesAtIndexWithValues(string, [string length] - 1, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);
}

//- (void)deleteCharactersInRange:(CPRange)aRange
- (void)testDeleteCharactersInRange
{
    var string = [self stringForTesting];

    [string deleteCharactersInRange:CPMakeRange(10, 5)];

    [self assertTrue:[string string] === "The quick  fox jumped over the lazy dog." message:"replacing 'brown' with '' produced: " + [string string]];

    testAttributesAtIndexWithValues(string, 10, {a:2, b:"baz", c:sharedObject}, self);
    testAttributesAtIndexWithValues(string, 27, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);
    testAttributesAtIndexWithValues(string, [string length] - 1, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);

    [string deleteCharactersInRange:CPMakeRange(0, [string length])];

    [self assertTrue:[string isEqual:[[CPAttributedString alloc] initWithString:""]] message:"emptry string was not equal: " + [string string]];

    var string = [self stringForTesting];

    //this deletes an exact rangeEntry
    [string deleteCharactersInRange:CPMakeRange(9, 11)];

    testAttributesAtIndexWithValues(string, 9, {a:2, b:"baz", c:"astring", d:[CPNull null]}, self);
}

//Private methods
//- (void)_indexOfRangeEntryForIndex:(unsigned)characterIndex splitOnMaxIndex:(BOOL)split
- (void)testIndexOfRangeEntryForIndexSplitOnMaxIndex
{
    var string = [self stringForTesting],
        index = [string _indexOfRangeEntryForIndex:4 splitOnMaxIndex:YES];

    [self assertTrue:index == 1 message:"index of character 4 should have been 1, was: " + index];

    [self assertTrue:CPEqualRanges(string._rangeEntries[0].range, CPMakeRange(0, 4)) message:"range 0 should be {0, 4}; was " + CPStringFromRange(string._rangeEntries[0].range)];

    [self assertTrue:CPEqualRanges(string._rangeEntries[1].range, CPMakeRange(4, 5)) message:"range 1 should be {4, 5}; was " + CPStringFromRange(string._rangeEntries[1].range)];

    [self assertTrue:[string isEqual:[self stringForTesting]] message:"should be equal to template attributed string but wasn't"];

    string = [self stringForTesting];

    index = [string _indexOfRangeEntryForIndex:8 splitOnMaxIndex:YES];

    [self assertTrue:index == 1 message:"index of character 8 should have been 1, was: " + index];

    [self assertTrue:CPEqualRanges(string._rangeEntries[0].range, CPMakeRange(0, 8)) message:"range 0 should be {0, 8}; was " + CPStringFromRange(string._rangeEntries[0].range)];

    index = [string _indexOfRangeEntryForIndex:9 splitOnMaxIndex:YES];

    [self assertTrue:index == 2 message:"index of character 9 should have been 2, was: " + index];

    [self assertTrue:CPEqualRanges(string._rangeEntries[0].range, CPMakeRange(0, 8)) message:"range 0 should be {0, 8}; was " + CPStringFromRange(string._rangeEntries[0].range)];

    [self assertTrue:CPEqualRanges(string._rangeEntries[1].range, CPMakeRange(8, 1)) message:"range 1 should be {8, 1}; was " + CPStringFromRange(string._rangeEntries[1].range)];

    [self assertTrue:CPEqualRanges(string._rangeEntries[2].range, CPMakeRange(9, 11)) message:"range 2 should be {9, 11}; was " + CPStringFromRange(string._rangeEntries[2].range)];

    string = [self stringForTesting];

    index = [string _indexOfRangeEntryForIndex:44 splitOnMaxIndex:YES];

    [self assertTrue:index == 4 message:"index of character 44 should have been 4, was: " + index];

    [self assertTrue:CPEqualRanges(string._rangeEntries[index].range, CPMakeRange(44, 1)) message:"range 3 should be {44, 1}; was " + CPStringFromRange(string._rangeEntries[index].range)];

    index = [string _indexOfRangeEntryForIndex:43 splitOnMaxIndex:YES];

    [self assertTrue:index == 4 message:"index of character 43 should have been 4, was: " + index];

    [self assertTrue:CPEqualRanges(string._rangeEntries[index - 1].range, CPMakeRange(32, 11)) message:"range 3 should be {32, 11}; was " + CPStringFromRange(string._rangeEntries[index - 1].range)];

    [self assertTrue:CPEqualRanges(string._rangeEntries[index].range, CPMakeRange(43, 1)) message:"range 4 should be {43, 1}; was " + CPStringFromRange(string._rangeEntries[index].range)];
}

//- (void)_coalesceRangeEntriesFromIndex:(unsigned)start toIndex:(unsigned)end
- (void)testCoalesceRangeEntriesFromIndexToIndex
{
    var templateString = [[CPAttributedString alloc] initWithString:"The quick brown fox jumped over the lazy dog."];

    templateString._rangeEntries = [];

    templateString._rangeEntries.push({
        range:CPMakeRange(0, 4),
        attributes:[CPDictionary dictionaryWithObjects:[1, "bar", sharedObject, 20] forKeys:["a", "b", "c", "d"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(4, 5),
        attributes:[CPDictionary dictionaryWithObjects:[1, "bar", sharedObject, 20] forKeys:["a", "b", "c", "d"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(9, 10),
        attributes:[CPDictionary dictionaryWithObjects:[2, "baz", sharedObject] forKeys:["a", "b", "c"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(19, 1),
        attributes:[CPDictionary dictionaryWithObjects:[2, "baz", sharedObject] forKeys:["a", "b", "c"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(20, 12),
        attributes:[CPDictionary dictionaryWithObjects:[2, "baz", "astring", [CPNull null]] forKeys:["a", "b", "c", "d"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(32, 1),
        attributes:[CPDictionary dictionaryWithObjects:[37, "baz", 1, 20, 55, 43] forKeys:["a", "b", "c", "d", "e", "f"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(33, 10),
        attributes:[CPDictionary dictionaryWithObjects:[37, "baz", 1, 20, 55, 43] forKeys:["a", "b", "c", "d", "e", "f"]]
    });
    templateString._rangeEntries.push({
        range:CPMakeRange(43, 2),
        attributes:[CPDictionary dictionaryWithObjects:[37, "baz", 1, 20, 55, 43] forKeys:["a", "b", "c", "d", "e", "f"]]
    });

    var string = [[CPAttributedString alloc] initWithAttributedString:templateString];

    [string _coalesceRangeEntriesFromIndex:0 toIndex:string._rangeEntries.length - 1];

    [self assertTrue:[string isEqual:templateString] message:"string should equal template string but does not."];

    [self assertTrue:CPEqualRanges(string._rangeEntries[0].range, CPMakeRange(0, 9)) message:"range 0 should be {0, 9}; was " + CPStringFromRange(string._rangeEntries[0].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[1].range, CPMakeRange(9, 11)) message:"range 1 should be {9, 11}; was " + CPStringFromRange(string._rangeEntries[1].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[2].range, CPMakeRange(20, 12)) message:"range 2 should be {20, 12}; was " + CPStringFromRange(string._rangeEntries[2].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[3].range, CPMakeRange(32, 13)) message:"range 3 should be {32, 13}; was " + CPStringFromRange(string._rangeEntries[3].range)];

    var string = [[CPAttributedString alloc] initWithAttributedString:templateString];

    [string _coalesceRangeEntriesFromIndex:4 toIndex:7];

    [self assertTrue:[string isEqual:templateString] message:"string should equal template string but does not."];

    [self assertTrue:CPEqualRanges(string._rangeEntries[0].range, CPMakeRange(0, 4)) message:"range 0 should be {0, 4}; was " + CPStringFromRange(string._rangeEntries[0].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[1].range, CPMakeRange(4, 5)) message:"range 1 should be {4, 5}; was " + CPStringFromRange(string._rangeEntries[1].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[2].range, CPMakeRange(9, 10)) message:"range 2 should be {9, 10}; was " + CPStringFromRange(string._rangeEntries[2].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[3].range, CPMakeRange(19, 1)) message:"range 3 should be {19, 1}; was " + CPStringFromRange(string._rangeEntries[3].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[4].range, CPMakeRange(20, 12)) message:"range 4 should be {20, 12}; was " + CPStringFromRange(string._rangeEntries[4].range)];
    [self assertTrue:CPEqualRanges(string._rangeEntries[5].range, CPMakeRange(32, 13)) message:"range 5 should be {32, 13}; was " + CPStringFromRange(string._rangeEntries[5].range)];
}

//Changing Attributes
//- (void)setAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
- (void)testSetAttributesRange
{
    var string = [self stringForTesting];

    [string setAttributes:@{} range:CPMakeRange(0, [string length])];

    testAttributesAtIndexWithValues(string, 10, {a:undefined, b:undefined, c:undefined, d:undefined, e:undefined, f:undefined}, self);

    string = [self stringForTesting];

    [string setAttributes:[CPDictionary dictionaryWithObjects:[1, 2, 3, 4, 5] forKeys:["a", "b", "c", "d", "e"]] range:CPMakeRange(0, [string length])];

    testAttributesAtIndexWithValues(string, 10, {a:1, b:2, c:3, d:4, e:5}, self);

    var range = CPMakeRange(0, 0);

    [string setAttributes:[CPDictionary dictionaryWithObject:"FOO" forKey:"BAR"] range:CPMakeRange(15, 20)];

    var value = [string attribute:"BAR" atIndex:16 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === "FOO" message:"expected value to be 'FOO', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(15, 20)) message:"expected key to be valid across {15, 20}, was: " + CPStringFromRange(range)];

    var index = range.location;

    while (index < CPMaxRange(range))
        [self assertTrue:[string attribute:"BAR" atIndex:index++ effectiveRange:nil] == "FOO" message:"incorrect value for key BAR"];

    string = [self stringForTesting];

    [string addAttributes:[CPDictionary dictionaryWithObject:"FOO" forKey:"BAR"] range:CPMakeRange(0, 45)];

    var value = [string attribute:"BAR" atIndex:16 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === "FOO" message:"expected value to be 'FOO', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(0, 45)) message:"expected key to be valid across {0, 45}, was: " + CPStringFromRange(range)];

    var index = range.location;

    while (index < CPMaxRange(range))
        [self assertTrue:[string attribute:"BAR" atIndex:index++ effectiveRange:nil] == "FOO" message:"incorrect value for key BAR"];
}

//- (void)addAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
- (void)testAddAttributesRange
{
    var string = [self stringForTesting],
        range = CPMakeRange(0, 0);

    [string addAttributes:[CPDictionary dictionaryWithObject:"FOO" forKey:"BAR"] range:CPMakeRange(15, 20)];

    var value = [string attribute:"BAR" atIndex:16 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === "FOO" message:"expected value to be 'FOO', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(15, 20)) message:"expected key to be valid across {15, 20}, was: " + CPStringFromRange(range)];

    var index = range.location;

    while (index < CPMaxRange(range))
        [self assertTrue:[string attribute:"BAR" atIndex:index++ effectiveRange:nil] == "FOO" message:"incorrect value for key BAR"];

    string = [self stringForTesting];

    [string addAttributes:[CPDictionary dictionaryWithObjects:[1, 2, 3, 4, 5] forKeys:["a", "b", "c", "d", "e"]] range:CPMakeRange(0, [string length])];

    testAttributesAtIndexWithValues(string, 10, {a:1, b:2, c:3, d:4, e:5}, self);

    string = [self stringForTesting];

    [string addAttributes:[CPDictionary dictionaryWithObject:"FOO" forKey:"BAR"] range:CPMakeRange(0, 45)];

    var value = [string attribute:"BAR" atIndex:16 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === "FOO" message:"expected value to be 'FOO', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(0, 45)) message:"expected key to be valid across {0, 45}, was: " + CPStringFromRange(range)];

    var index = range.location;

    while (index < CPMaxRange(range))
        [self assertTrue:[string attribute:"BAR" atIndex:index++ effectiveRange:nil] == "FOO" message:"incorrect value for key BAR"];
}

//- (void)addAttribute:(CPString)anAttribute value:(id)aValue range:(CPRange)aRange
- (void)testAddAttributeValueRange
{
    var string = [self stringForTesting];

    [string addAttribute:"duck" value:"goose" range:CPMakeRange(10, 30)];

    testAttributeAtIndexWithValue(string, 10, "duck", "goose", self);
    testAttributeAtIndexWithValue(string, 30, "duck", "goose", self);
    testAttributeAtIndexWithValue(string, 40, "duck", undefined, self);

}

//- (void)removeAttribute:(CPString)anAttribute range:(CPRange)aRange
- (void)testRemoveAttributeRange
{
    var string = [self stringForTesting];

    [string removeAttribute:"a" range:CPMakeRange(10, 30)];

    testAttributeAtIndexWithValue(string, 10, "a", null, self);
    testAttributeAtIndexWithValue(string, 30, "a", null, self);
    testAttributeAtIndexWithValue(string, 40, "a", 37, self);
}

//Changing Characters and Attributes
//- (void)appendAttributedString:(CPAttributedString)aString
- (void)testAppendAttributedString
{
    var string = [self stringForTesting],
        addOn = [string attributedSubstringFromRange:CPMakeRange(41, 3)];

    [string appendAttributedString:addOn];
    [string appendAttributedString:addOn];

    [self assertTrue:[string string] === "The quick brown fox jumped over the lazy dog.dogdog" message:"wrong string after appending"];

    var range = CPMakeRange(0, 0),
        value = [string attribute:"c" atIndex:47 longestEffectiveRange:range inRange:CPMakeRange(0, [string length])];

    [self assertTrue:value === 1 message:"expected value to be '1', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(32, 13 + 3 + 3)) message:"expected key to be valid across {32, 19}, was: " + CPStringFromRange(range)];
}

//- insertAttributedString:(CPAttributedString)aString atIndex:(CPString)anIndex
- (void)testInsertAttributedStringAtIndex
{
    var string = [self stringForTesting],
        addOn = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(41, 3)];

    [string insertAttributedString:addOn atIndex:[string length]];

    testAttributesAtIndexWithValues(string, 46, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);

    string = [self stringForTesting];

    addOn = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(41, 3)];

    [string insertAttributedString:addOn atIndex:9];

    testAttributesAtIndexWithValues(string, 9, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);

    addOn = [[self stringForTesting] attributedSubstringFromRange:CPMakeRange(41, 3)];

    [string insertAttributedString:addOn atIndex:8];

    testAttributesAtIndexWithValues(string, 8, {a:37, b:"baz", c:1, d:20, e:55, f:43}, self);

    var range = CPMakeRange(0, 0),
        value = [string attribute:"a" atIndex:9 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === 37 message:"expected value to be '37', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(8, 3)) message:"expected key to be valid across {8, 3}, was: " + CPStringFromRange(range)];

    value = [string attribute:"a" atIndex:11 longestEffectiveRange:range inRange:CPMakeRange(0, 45)];

    [self assertTrue:value === 1 message:"expected value to be '37', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(11, 1)) message:"expected key to be valid across {11, 1}, was: " + CPStringFromRange(range)];
}

//- (void)replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPAttributedString)aString
- (void)testReplaceCharactersInRangeWithAttributedString
{
    var string = [self stringForTesting],
        addOn = [string attributedSubstringFromRange:CPMakeRange(41, 3)];

    [string replaceCharactersInRange:CPMakeRange(41, 3) withAttributedString:addOn];

    [self assertTrue:[string string] === [[self stringForTesting] string] message:"wrong string after replacing."];

    var range = CPMakeRange(0, 0),
        value = [string attribute:"c" atIndex:42 longestEffectiveRange:range inRange:CPMakeRange(0, [string length])];

    [self assertTrue:value === 1 message:"expected value to be '1', was: " + value];
    [self assertTrue:CPEqualRanges(range, CPMakeRange(32, 13)) message:"expected key to be valid across {32, 13}, was: " + CPStringFromRange(range)];
}

//- (void)setAttributedString:(CPAttributedString)aString
- (void)testSetAttributedString
{
    var string = [[CPAttributedString alloc] initWithString:"HELLO THERE"];
    [string setAttributedString:[self stringForTesting]];

    [self assertTrue:[[self stringForTesting] isEqual:string] message:"setAttributedString should have made strings equal, but they were not"];
}

@end

function isEqualAllowingUndefinedCast(a, b)
{
    return a === b || (a === undefined && a == b) || (b === undefined && a == b);
}

function testAttributesAtIndexWithValues(aString, anIndex, values, aSelf)
{
    var range = CPMakeRange(0, 0),
        attributes = [aString attributesAtIndex:anIndex effectiveRange:range];

    for (key in values)
        [aSelf assertTrue:isEqualAllowingUndefinedCast([attributes objectForKey:key], values[key]) message: "expecting '" + key + "' to be '" + values[key] + "', was '" + [attributes objectForKey:key]];

    var index = range.location;

    while (index < CPMaxRange(range))
    {
        attributes = [aString attributesAtIndex:index++ effectiveRange:nil];

        for (key in values)
            [aSelf assertTrue:isEqualAllowingUndefinedCast([attributes objectForKey:key], values[key]) message: "expecting '" + key + "' in loop to be '" + values[key] + "', was '" + [attributes objectForKey:key]];
    }
}

function testAttributeAtIndexWithValue(aString, anIndex, aKey, aValue, aSelf)
{
    var range = CPMakeRange(0, 0),
        attribute = [aString attribute:aKey atIndex:anIndex effectiveRange:range];

    [aSelf assertTrue: isEqualAllowingUndefinedCast(attribute, aValue) message: "expecting '" + aKey + "' to be '" + aValue + "', was '" + attribute];

    var index = range.location;

    while (index < CPMaxRange(range))
    {
        attribute = [aString attribute:aKey atIndex:index++ effectiveRange:nil];

        [aSelf assertTrue: isEqualAllowingUndefinedCast(attribute, aValue) message: "expecting '" + aKey + "' to be '" + aValue + "', was '" + attribute];
    }
}

function printRangeEntry(entry)
{
    print("range: " + CPStringFromRange(entry.range) + " " + [entry.attributes description]);
}
