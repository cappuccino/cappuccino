@import <AppKit/AppKit.j>

@implementation CPColorTest : OJTestCase
{
}

- (void)testHexStringConversion
{
    var colors = ['000000', '0099CC', '7E8EAB', 'FFFFFF'];
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

- (void)testIsEqual_
{
    // Based on https://gist.github.com/e06f749362cb1166439f by spakanati.
    var color1 = [CPColor colorWithCSSString:"rgba(127,127,127,1.0)"],
        color2 = [CPColor colorWithCSSString:"rgba(127, 127, 127, 1.0)"],
        color3 = [CPColor colorWithRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:1.0],
        color4 = [CPColor whiteColor];

    [self assertTrue:[color1 isEqual:color2] message:"[color1 isEqual:color2]"];
    [self assertTrue:[color1 isEqual:color3] message:"[color1 isEqual:color3]"];
    [self assertTrue:[color2 isEqual:color3] message:"[color2 isEqual:color3]"];

    [self assertTrue:[color1 isEqual:color1] message:"[color1 isEqual:color1]"];
    [self assertFalse:[color1 isEqual:color4] message:"[color1 isEqual:color4]"];
    [self assertFalse:[color4 isEqual:color1] message:"[color4 isEqual:color1]"];
}

@end
