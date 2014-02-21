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

@end
