@import <AppKit/AppKit.j>

@implementation CPColorTest : OJTestCase
{
}

- (void)testHexStringConversion
{
    var colors = ['000000', '0099CC', '7E8EAB', 'FFFFFF'];
    for (var i = 0; i < colors.length; ++i)
        [self assert:colors[i] equals:[[CPColor colorWithHexString:colors[i]] hexString]];
}

- (void)testColorWithCSSString
{
    var rgbaColour = [CPColor colorWithCSSString:@"rgba(32, 64, 128, 0.5)"];

    [self assert:32 equals:ROUND([rgbaColour redComponent] * 255) message:"red component"];
    [self assert:64 equals:ROUND([rgbaColour greenComponent] * 255) message:"green component"];
    [self assert:128 equals:ROUND([rgbaColour blueComponent] * 255) message:"blue component"];
    [self assert:128 equals:ROUND([rgbaColour alphaComponent] * 255) message:"alpha component"];
}

- (void)testColorWithHue_saturation_brightness_
{
    var tests = [
            [[0, 0, 0], [0, 0, 0]],
            [[0, 0, 1], [1, 1, 1]],
            [[0, 1, 1], [1, 0, 0]],
            [[0.75, 1, 1], [0.5, 0, 1]],
            [[0.5, 0.5, 0.5], [0.25, 0.5, 0.5]],
            [[0.9, 0.8, 0.7], [0.7, 0.14, 0.476]]
        ];

    for (var i = 0; i < tests.length; i++)
    {
        var test = tests[i],
            input = test[0],
            expected = test[1],
            c = [CPColor colorWithCalibratedHue:input[0] saturation:input[1] brightness:input[2] alpha:0.5];
        [self assert:expected equals:[Math.round([c redComponent] * 1000) / 1000, Math.round([c greenComponent] * 1000) / 1000, Math.round([c blueComponent] * 1000) / 1000] message:@"hue: " + input[0] + " saturation: " + input[1] + " brightness: " + input[2]];
    }

    var hsb = [[CPColor colorWithHue:0.9 saturation:0.8 brightness:0.7] hsbComponents];
    [self assert:[0.9, 0.8, 0.7] equals:[Math.round(hsb[0] * 10) / 10, Math.round(hsb[1] * 10) / 10, Math.round(hsb[2] * 10) / 10]];

    hsb = [[CPColor colorWithHue:0.999 saturation:0.8 brightness:0.7] hsbComponents];
    [self assert:[0.999, 0.8, 0.7] equals:[Math.round(hsb[0] * 1000) / 1000, Math.round(hsb[1] * 10) / 10, Math.round(hsb[2] * 10) / 10]];
}

- (void)testIsEqual_
{
    // Based on https://gist.github.com/e06f749362cb1166439f by spakanati.
    var color1 = [CPColor colorWithCSSString:"rgba(127,127,127,1.0)"],
        color2 = [CPColor colorWithCSSString:"rgba(127, 127, 127, 1.0)"],
        color3 = [CPColor colorWithRed:127.0 / 255.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0],
        color4 = [CPColor blackColor];

    [self assertTrue:[color1 isEqual:color2] message:"[color1 isEqual:color2]"];
    [self assertTrue:[color1 isEqual:color3] message:"[color1 isEqual:color3]"];
    [self assertTrue:[color2 isEqual:color3] message:"[color2 isEqual:color3]"];

    [self assertTrue:[color1 isEqual:color1] message:"[color1 isEqual:color1]"];
    [self assertFalse:[color1 isEqual:color4] message:"![color1 isEqual:color4]"];
    [self assertFalse:[color4 isEqual:color1] message:"![color4 isEqual:color1]"];

    var image1 = [CPImage new],
        image2 = [CPImage new],
        color5 = [CPColor colorWithPatternImage:image1],
        color6 = [CPColor colorWithPatternImage:image2],
        color7 = [CPColor colorWithPatternImage:image1];

    image2._filename = "othername";

    [self assertTrue:[color5 isEqual:color5] message:"[color5 isEqual:color5]"];
    [self assertTrue:[color5 isEqual:color7] message:"[color5 isEqual:color7]"];
    [self assertFalse:[color5 isEqual:color6] message:"![color5 isEqual:color6]"];
    [self assertFalse:[color4 isEqual:color5] message:"![color4 isEqual:color5]"];
}

- (void)testOutOfRange
{
    var color1 = [CPColor colorWithCalibratedRed:-1.0 green:-1.0 blue:-1.0 alpha:-.05],
        color2 = [CPColor colorWithCalibratedRed:1.1 green:1.2 blue:1.3 alpha:1.05];

    [self assert:0.0 equals:[color1 redComponent] message:"color1 redComponent"];
    [self assert:0.0 equals:[color1 greenComponent] message:"color1 greenComponent"];
    [self assert:0.0 equals:[color1 blueComponent] message:"color1 blueComponent"];
    [self assert:0.0 equals:[color1 alphaComponent] message:"color1 alphaComponent"];

    [self assert:1.0 equals:[color2 redComponent] message:"color2 redComponent"];
    [self assert:1.0 equals:[color2 greenComponent] message:"color2 greenComponent"];
    [self assert:1.0 equals:[color2 blueComponent] message:"color2 blueComponent"];
    [self assert:1.0 equals:[color2 alphaComponent] message:"color2 alphaComponent"];
}

@end
