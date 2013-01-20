@import <AppKit/CGColor.j>

@implementation CGColorTest : OJTestCase

- (void)testColorCreateReturnNullIfNull
{
    [self assert:NULL equals:CGColorCreate(NULL, [1, 2, 3]) message:"colorspace null failed"];
    [self assert:NULL
          equals:CGColorCreate(CGColorSpaceCreateDeviceRGB(), NULL)
          message:"components null failed"];
}

- (void)testColorCreateEnsureComponentsAreCopied
{
    var colorspace = CGColorSpaceCreateDeviceRGB(),
        components = [2,3,4,5],
        clr = CGColorCreate(colorspace, components);

    components[0] = components[1] = components[2] = components[3] = 0;
    [self assert:[1,1,1,1] equals:clr.components];
    [self assert:[0,0,0,0] equals:components];
}

- (void)testColorCreateCachesColorsAlphaChangeIsPropagated
{
    var clr = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [0.4, 0.3, 0.2, 0.2]),
        newclr = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [0.4, 0.3, 0.2, 0.2]);
    newclr.components[newclr.components.length - 1] = 0.6;
    [self assert:0.6 equals:clr.components[clr.components.length - 1]];
}

- (void)testColorCreate
{
    var colorspace = CGColorSpaceCreateDeviceRGB(),
        components = [2,3,4,5],
        clruid = CFHashCode(colorspace) + components.join("");

    // Can't access the colormap cache, but it would be nice to
    // [self assert:NULL equals:_CGColorMap[clruid]];

    var clr = CGColorCreate(colorspace, components);
    [self assert:colorspace equals:clr.colorspace message:"colorspace failed"];
    [self assert:[1,1,1,1]  equals:clr.components message:"components failed"];
    [self assert:NULL       equals:clr.pattern message:"pattern failed"];

    // Can't access the colormap cache, but it would be nice to
    // [self assert:clr equals:_CGColorMap[clruid]];
}

- (void)testColorCopy
{
    // it returns it's argument, a little artifical but will fail if something
    // changes with the function.
    [self assert:"banana" equals:CGColorCreateCopy("banana")];

    var colorspace = CGColorSpaceCreateDeviceRGB(),
        components = [2, 3, 4, 5],
        clr = CGColorCreate( colorspace, components );
    [self assert:clr equals:CGColorCreateCopy(clr)];
}

- (void)testColorCreateGenericGray
{
    var clr = CGColorCreateGenericGray(0.3, 0.5);
    [self assert:CGColorSpaceCreateDeviceRGB()
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.3 * 255) / 255, ROUND(0.3 * 255) / 255, ROUND(0.3 * 255) / 255, 0.5]
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

- (void)testColorCreateGenericRGB
{
    var clr = CGColorCreateGenericRGB(0.4,0.3,0.2,0.1);
    [self assert:CGColorSpaceCreateDeviceRGB()
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.4 * 255) / 255, ROUND(0.3 * 255) / 255,ROUND(0.2 * 255) / 255, 0.1]
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

- (void)testColorCreateGenericCMYK
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6)
    [self assert:CGColorSpaceCreateDeviceCMYK()
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.2 * 255) / 255,ROUND(0.3 * 255) / 255,ROUND(0.4 * 255) / 255, ROUND(0.5 * 255) / 255, 0.6]
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

- (void)testColorCreateWithPattern
{
    var clrspc = CGColorSpaceCreateDeviceRGB(),
        pattern = "a new pattern",
        components = [0.2, 0.4, 0.6, 0.8],
        clr = CGColorCreateWithPattern(clrspc, pattern, components);

    [self assert:clrspc equals:clr.colorspace];
    [self assert:pattern equals:clr.pattern];
    [self assert:components equals:clr.components];

    // ensure that there was a copy made of the components
    components[0] = components[1] = components[2] = components[3] = 0.0;
    [self assert:[0.2, 0.4, 0.6, 0.8] equals:clr.components];

    // ensure that null is returned
    [self assert:NULL equals:CGColorCreateWithPattern(NULL, "a new pattern", [])];
    [self assert:NULL equals:CGColorCreateWithPattern(CGColorSpaceCreateDeviceRGB(),
                                                      NULL, [])];
    [self assert:NULL equals:CGColorCreateWithPattern(CGColorSpaceCreateDeviceRGB(),
                                                      "a new pattern", NULL)];
    [self assert:NULL equals:CGColorCreateWithPattern(NULL, NULL, NULL)];
}

- (void)testColorGetAlpha
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6);
    [self assert:0.6 equals:CGColorGetAlpha(clr)];
}

- (void)testColorGetColorSpace
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6);
    [self assert:CGColorSpaceCreateDeviceCMYK()
          equals:CGColorGetColorSpace(clr)];
}

- (void)testColorGetComponents
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6);
    [self assert:[ROUND(0.2 * 255) / 255, ROUND(0.3 * 255) / 255, ROUND(0.4 * 255) / 255,
                  ROUND(0.5 * 255) / 255, ROUND(0.6 * 255) / 255]
          equals:CGColorGetComponents(clr)];
}

- (void)testColorGetNumberOfComponents
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6);
    [self assert:5 equals:CGColorGetNumberOfComponents(clr)];
}

- (void)testColorGetPattern
{
    var clr = CGColorCreateWithPattern(CGColorSpaceCreateDeviceRGB(), "a new pattern",
                                       [1,1,1,1]);
    [self assert:"a new pattern" equals:CGColorGetPattern(clr)];
}

- (void)testColorCreateCopyWithAlphaWithPattern
{
    var clr = CGColorCreateWithPattern(CGColorSpaceCreateDeviceRGB(), "a new pattern",
                                       [1,1,1,1]);
    [self assert:1 equals:CGColorGetAlpha(clr) message:"initial alpha"];

    var newclr = CGColorCreateCopyWithAlpha(clr, 0.6);
    [self assert:0.6 equals:CGColorGetAlpha(newclr) message:"new color alpha value"];
    [self assert:1 equals:CGColorGetAlpha(clr) message:"alpha after copy"];

    [self assert:clr.colorspace equals:newclr.colorspace message:"newclr colorspace failed"];
    [self assert:clr.pattern equals:newclr.pattern message:"newclr pattern failed"];
}

- (void)testColorCreateCopyWithAlphaWithComponents
{
    var clr = CGColorCreateGenericRGB(0.4, 0.3, 0.2, 0.3);
    [self assert:0.3 equals:CGColorGetAlpha(clr) message:"initial alpha"];

    var newclr = CGColorCreateCopyWithAlpha(clr, 0.6);
    [self assert:0.6 equals:CGColorGetAlpha(newclr) message:"new color alpha value"];
    [self assert:0.3 equals:CGColorGetAlpha(clr) message:"alpha after copy"];

    [self assert:CGColorSpaceCreateDeviceRGB()
          equals:newclr.colorspace message:"newclr colorspace failed"];
    [self assert:[ROUND(0.4 * 255) / 255, ROUND(0.3 * 255) / 255, ROUND(0.2 * 255) / 255, 0.6]
          equals:newclr.components message:"newclr components failed"];
    [self assert:NULL equals:newclr.pattern message:"newclr pattern failed"];

    [self assert:CGColorSpaceCreateDeviceRGB()
          equals:clr.colorspace message:"orig clr colorspace failed"];
    [self assert:[ROUND(0.4 * 255) / 255, ROUND(0.3 * 255) / 255, ROUND(0.2 * 255) / 255, 0.3]
          equals:clr.components message:"orig clr components failed"];
    [self assert:NULL equals:clr.pattern message:"orig clr pattern failed"];
}

- (void)testColorCreateCopyWithAlphaWithComponentsNullColor
{
    [self assert:NULL
          equals:CGColorCreateCopyWithAlpha(NULL,0.5)
          message:"null color failed"];

    var clr = CGColorCreateGenericRGB(0.4,0.3,0.2,0.1),
        newclr = CGColorCreateCopyWithAlpha(clr, 0.1);
    [self assert:clr equals:newclr];
}

- (void)testColorEqualToColor
{
    [self assert:true equals:CGColorEqualToColor(NULL,NULL)];

    var clr1 = CGColorCreateGenericRGB(0.4, 0.3, 0.2, 0.3);
    [self assert:false equals:CGColorEqualToColor(NULL,clr1)];
    [self assert:true equals:CGColorEqualToColor(clr1,clr1)];
    [self assert:false equals:CGColorEqualToColor(clr1,NULL)];

    var clr2 = CGColorCreateGenericRGB(0.4, 0.3, 0.2, 0.3);
    [self assert:true equals:CGColorEqualToColor(clr1,clr2)];
    [self assert:true equals:CGColorEqualToColor(clr2,clr1)];

    clr2 = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6);
    [self assert:false equals:CGColorEqualToColor(clr1,clr2)];
    [self assert:false equals:CGColorEqualToColor(clr2,clr1)];
}

@end

