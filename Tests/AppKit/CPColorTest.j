@import <AppKit/AppKit.j>

@implementation CPColorTest : OJTestCase
{
}

- (void)testHexStringConversion
{
    var colors = ['000000', '7E8EAB', 'FFFFFF'];
    for (var i = 0; i < colors.length; ++i)
        [self assert: colors[i] equals: [[CPColor colorWithHexString: colors[i]] hexString]];
}

@end
