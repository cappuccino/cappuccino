@import <Foundation/CPNumber.j>

@implementation CPNumberTest : OJTestCase

- (void)testCompareWithNil
{
    [self assertThrows:function () { [34 compare:nil] }];
}

- (void)testCompareWithCPNull
{
    [self assertThrows:function () { [34 compare:[CPNull null]] }];
}

- (void)testIntValue
{
    /*
    For reference:

        [[NSNumber numberWithDouble:3.1] intValue]: 3
        [[NSNumber numberWithDouble:3.9] intValue]: 3
        [[NSNumber numberWithDouble:-3.1] intValue]: -3
        [[NSNumber numberWithDouble:-3.9] intValue]: -3
        [[NSNumber numberWithDouble:3.1] integerValue]: 3
        [[NSNumber numberWithDouble:3.9] integerValue]: 3
        [[NSNumber numberWithDouble:-3.1] integerValue]: -3
        [[NSNumber numberWithDouble:-3.9] integerValue]: -3
    */

    var testStrings = [
//            [090,   90],   // Removed cause Rhino does not support numbers starting with '0'
            [-1,      -1],
            [3.1415,   3],
            [3.5415,   3],
            [-3.1415, -3],
            [-3.5415, -3],
            [2.7183,   2],
            [-0,       0],
            [00,       0],
            [-00,      0],
            [+001,     1],
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] shortValue] equals:testStrings[i][1]];
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] intValue] equals:testStrings[i][1]];
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] longValue] equals:testStrings[i][1]];
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] longLongValue] equals:testStrings[i][1]];
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] integerValue] equals:testStrings[i][1]];
}

@end
