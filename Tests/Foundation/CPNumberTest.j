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

- (void)testintValue
{
    var testStrings = [
//            [090,   90],   // Removed cause Rhino does not support numbers starting with '0'
            [-1,    -1],
            [3.1415, 3],
            [2.7183, 2],
            [-0,     0],
            [00,     0],
            [-00,    0],
            [+001,   1],
        ];

    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] intValue] equals:testStrings[i][1]];
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] integerValue] equals:testStrings[i][1]];
}

@end
