@import <AppKit/CGColor.j>

@implementation CGColorTest : OJTestCase

- (void)testColorCreate
{
    var colorspace = CGColorSpaceCreateDeviceRGB(), 
        components = [2,3,4,5],
        clruid = CFHashCode(colorspace) + components.join("");

    // Can't access the colormap cache, but it would be nice to 
    // [self assert:NULL equals:_CGColorMap[clruid]];

    var clr = CGColorCreate( colorspace, components );
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
    [self assert:"banana" equals:CGColorCreateCopy( "banana" )];

    var colorspace = CGColorSpaceCreateDeviceRGB(), 
        components = [2,3,4,5],
        clr = CGColorCreate( colorspace, components );
    [self assert:clr equals:CGColorCreateCopy(clr)];
}

- (void)testColorCreateGenericGray
{
    var clr = CGColorCreateGenericGray(0.3, 0.5);
    [self assert:CGColorSpaceCreateDeviceRGB() 
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.3*255)/255,ROUND(0.3*255)/255,ROUND(0.3*255)/255,0.5]  
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

- (void)testColorCreateGenericRGB
{
    var clr = CGColorCreateGenericRGB(0.4,0.3,0.2,0.1);
    [self assert:CGColorSpaceCreateDeviceRGB() 
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.4*255)/255,ROUND(0.3*255)/255,ROUND(0.2*255)/255,0.1]
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

- (void)testColorCreateGenericCMYK
{
    var clr = CGColorCreateGenericCMYK(0.2, 0.3, 0.4, 0.5, 0.6)
    [self assert:CGColorSpaceCreateDeviceCMYK()
          equals:clr.colorspace message:"colorspace failed"];
    [self assert:[ROUND(0.2*255)/255,ROUND(0.3*255)/255,ROUND(0.4*255)/255,
                       ROUND(0.5*255)/255, 0.6]
          equals:clr.components message:"components failed"];
    [self assert:NULL equals:clr.pattern message:"pattern failed"];
}

@end

