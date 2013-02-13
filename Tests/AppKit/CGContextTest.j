@import <AppKit/CGContext.j>

@import "CGTestCase.j"

// These are left undefined in CGContext.j if CPFeatureIsCompatible(CPHTMLCanvasFeature)
@global CGGStateCreate
@global CGGStateCreateCopy

@implementation CGContextTest : CGTestCase

- (void)testEnsureTestingCanvas
{
    /*
      Ensure that we have no canvas nor vml support.
    */
    if (system.engine !== "jsc")
    {
        [self assert:YES equals:!CPFeatureIsCompatible(CPHTMLCanvasFeature)];
    }
    [self assert:YES equals:!CPFeatureIsCompatible(CPVMLFeature)];
}

- (void)testGStateCreate
{
    if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
        return;

    var gstate = CGGStateCreate(),
        testdata = { alpha:       1.0,
                     strokeStyle: "#000",
                     fillStyle:   "#ccc",
                     lineWidth:   1.0,
                     lineJoin:    kCGLineJoinMiter,
                     lineCap:     kCGLineCapButt,
                     miterLimit:  10.0,
                     globalAlpha: 1.0,
                     blendMode:   kCGBlendModeNormal,
                     shadowBlur:  0.0,
                     shadowColor: NULL };

    for (var key in testdata)
        [self assert:testdata[key] equals:gstate[key] message:"Failed for " + key];

    [self compareSize:CGSizeMakeZero()
                 with:gstate.shadowOffset
              message:"Failed for shadowOffset"];

    [self compareTransform:CGAffineTransformMakeIdentity()
                      with:gstate.CTM
                   message:"Failed for CTM"];
}

- (void)testGStateCreateCopy
{
    if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
        return;

    var gstate = CGGStateCreate(),
        gstatecopy = CGGStateCreateCopy(gstate),
        testdata = { alpha:       1.0,
                     strokeStyle: "#000",
                     fillStyle:   "#ccc",
                     lineWidth:   1.0,
                     lineJoin:    kCGLineJoinMiter,
                     lineCap:     kCGLineCapButt,
                     miterLimit:  10.0,
                     globalAlpha: 1.0,
                     blendMode:   kCGBlendModeNormal,
                     shadowBlur:  0.0,
                     shadowColor: NULL };

    for (var key in testdata)
        [self assert:testdata[key] equals:gstatecopy[key] message:"Failed for " + key];

    // ensure that the size is copied
    var sizecopy = CGSizeMakeCopy(gstate.shadowOffset);
    gstate.shadowOffset.width += 1000;
    gstate.shadowOffset.height += 2000;
    [self compareSize:sizecopy with:gstatecopy.shadowOffset message:"Failed for shadowOffset"];

    // ensure that the transform is copied
    var transformcopy = CGAffineTransformMakeCopy(gstate.CTM);
    gstate.CTM.a += 1000;
    gstate.CTM.b += 1000;
    gstate.CTM.c += 1000;
    gstate.CTM.d += 1000;
    gstate.CTM.tx += 1000;
    gstate.CTM.ty += 1000;
    [self compareTransform:transformcopy with:gstatecopy.CTM message:"Failed with CTM"];
}

@end
