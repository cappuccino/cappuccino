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

- (void)testColorWithCSSString
{
    var rgbaColour = [CPColor colorWithCSSString:@"rgba(32, 64, 128, 0.5)"];

    [self assert:32 equals:Math.round([rgbaColour redComponent] * 255) message:"red component"];
    [self assert:64 equals:Math.round([rgbaColour greenComponent] * 255) message:"green component"];
    [self assert:128 equals:Math.round([rgbaColour blueComponent] * 255) message:"blue component"];
    [self assert:128 equals:Math.round([rgbaColour alphaComponent] * 255) message:"alpha component"];
}

@end
