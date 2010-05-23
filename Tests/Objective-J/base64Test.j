@import <Foundation/CPData.j>

var base64TestStrings = [
    ["leasure.", "bGVhc3VyZS4="],
    ["easure.", "ZWFzdXJlLg=="],
    ["asure.", "YXN1cmUu"],
    ["sure.", "c3VyZS4="]
];

@implementation base64Test : OJTestCase

- (void)test_CFData_encodeBase64String
{
    for (var i = 0; i < base64TestStrings.length; i++)
        [self assert:CFData.encodeBase64String(base64TestStrings[i][0]) equals:base64TestStrings[i][1]];
}

- (void)test_CFData_encodeBase64Array
{
    for (var i = 0; i < base64TestStrings.length; i++)
    {
        var input = [];
        for (var j = 0; j < base64TestStrings[i][0].length; j++)
            input.push(base64TestStrings[i][0].charCodeAt(j));
        [self assert:CFData.encodeBase64Array(input) equals:base64TestStrings[i][1]];
    }
}

- (void)test_CFData_decodeBase64ToString
{
    for (var i = 0; i < base64TestStrings.length; i++)
    {
        var result = CFData.decodeBase64ToString(base64TestStrings[i][1]),
            expected = base64TestStrings[i][0];
        [self assert:result equals:expected];
    }
}

- (void)test_CFData_decodeBase64ToArray
{
    for (var i = 0; i < base64TestStrings.length; i++)
    {
        var result = CFData.decodeBase64ToArray(base64TestStrings[i][1]),
            expected = base64TestStrings[i][0];
            
        for (var j = 0; j < expected.length || j < result.length; j++)
            [self assert:result[j] equals:expected.charCodeAt(j)];
    }
}

@end
