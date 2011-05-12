@import <AppKit/CGContext.j>
@import "CGTestCase.j"

// This is required for CGBitmapGraphicsContextCreate() but shouldn't be
// defined since it's global and likely to ruin other tests.
if (SET_GLOBAL_DOCUMENT = NO) {
    document = {
      createElement : function(elemname) { return elemname; }
    };
}

@implementation CGContextTest : CGTestCase

- (void)testEnsureNotTestingCanvasOrVml
{
    /*
      Ensure that we have no canvas nor vml support.
    */
    [self assert:YES equals:!CPFeatureIsCompatible(CPHTMLCanvasFeature)];
    [self assert:YES equals:!CPFeatureIsCompatible(CPVMLFeature)];
}

- (void)testCGGStateCreate
{
    [self checkInitialGState:CGGStateCreate() message:"Empty GState"];
}

- (void)testCGGStateCreateCopy
{
    var gstate = CGGStateCreate(),
        gstatecopy = CGGStateCreateCopy(gstate);

    [self checkInitialGState:gstatecopy message:"gstate copy"];

    // ensure that the size is copied
    var sizecopy = CGSizeMakeCopy( gstate.shadowOffset );
    gstate.shadowOffset.width += 1000;
    gstate.shadowOffset.height += 2000;
    [self compareSize:sizecopy
                 with:gstatecopy.shadowOffset
              message:"Failed for shadowOffset"];

    // ensure that the transform is copied
    var transformcopy = CGAffineTransformMakeCopy( gstate.CTM );
    gstate.CTM.a += 1000;
    gstate.CTM.b += 1000;
    gstate.CTM.c += 1000;
    gstate.CTM.d += 1000;
    gstate.CTM.tx += 1000;
    gstate.CTM.ty += 1000;
    [self compareTransform:transformcopy
                      with:gstatecopy.CTM
                   message:"Failed with CTM"];
}

- (void)testCGBitmapGraphicsContextCreate
{
    if (SET_GLOBAL_DOCUMENT) { // only test if document is defined
        var context = CGBitmapGraphicsContextCreate();
        [self assert:NULL  equals:context.path        message:"Failed for path"];
        [self assert:"div" equals:context.DOMElement  message:"Failed for domelement"];
        [self assert:[]    equals:context.gStateStack message:"failed for statestack"];
        [self checkInitialGState:context.gState       message:"bitmap graphic context"];
    }
}

- (void)testCGContextSaveGState
{
    var mockContext = [self createMockContext];
    [self assert:0 equals:mockContext.gStateStack.length];

    CGContextSaveGState(mockContext);
    [self assert:1 equals:mockContext.gStateStack.length];
    [self checkInitialGState:mockContext.gStateStack[0] message:"save gstate"];
}

- (void)testCGContextRestoreGState
{
    var mockContext = [self createMockContext];
    [self assert:0 equals:mockContext.gStateStack.length message:"state stack size (0)"];

    CGContextSaveGState(mockContext);
    [self assert:1 equals:mockContext.gStateStack.length message:"state stack size (1)"];

    CGContextSetLineCap(mockContext, kCGLineCapRound);

    CGContextSaveGState(mockContext);
    CGContextSetLineJoin(mockContext,kCGLineJoinRound);

    [self assert:2 equals:mockContext.gStateStack.length message:"state stack size (2)"];
    [self compareGState:mockContext.gStateStack[0]
                   with:{}
                message:"after save gstate, first state"];
    [self compareGState:mockContext.gStateStack[1]
                   with:{ lineCap:  kCGLineCapRound }
                message:"after save gstate, 2nd state"];
    [self compareGState:mockContext.gState
                   with:{ lineCap:  kCGLineCapRound, lineJoin: kCGLineJoinRound }
                message:"after save gstate, current state"];

    CGContextRestoreGState(mockContext);
    [self compareGState:mockContext.gState
                   with:{ lineCap:  kCGLineCapRound }
                message:"restore gstate"];
    [self assert:1 equals:mockContext.gStateStack.length message:"state stack size (3)"];

    CGContextRestoreGState(mockContext);
    [self compareGState:mockContext.gState
                   with:{ }
                message:"restore gstate"];
    [self assert:0 equals:mockContext.gStateStack.length message:"state stack size (4)"];
}

- (void)testCGContextSetLineCap
{
    var mockContext = [self createMockContext],
        testcases = {
      "nil line cap" : { value: nil },
      "round line join" : { value: kCGLineCapRound  },
      "square line " : { value: kCGLineCapSquare   }
    };

    for ( var key in testcases ) {
        CGContextSetLineCap(mockContext, testcases[key].value);
        [self compareGState:mockContext.gState
                       with:{ lineCap: testcases[key].value }
                    message:key];
    }
}

- (void)testCGContextSetLineJoin
{
    var mockContext = [self createMockContext],
        testcases = {
      "nil line join" : { value: nil },
      "round line join" : { value: kCGLineJoinRound  },
      "bevel line join" : { value: kCGLineJoinBevel   }
    };

    for ( var key in testcases ) {
        CGContextSetLineJoin(mockContext, testcases[key].value);
        [self compareGState:mockContext.gState
                       with:{ lineJoin: testcases[key].value }
                    message:key];
    }
}

- (void)testCGContextSetLineWidth
{
    var mockContext = [self createMockContext],
        testcases = {
      "nil line width" : { value: nil },
      "negative line width" : { value: -1  },
      "large line width" : { value: 10   }
    };

    for ( var key in testcases ) {
        CGContextSetLineWidth(mockContext, testcases[key].value);
        [self compareGState:mockContext.gState
                       with:{ lineWidth: testcases[key].value }
                    message:key];
    }
}

- (void)testCGContextSetMiterLimit
{
    var mockContext = [self createMockContext],
        testcases = {
      "nil miter limit" : { value: nil },
      "negative miter limit" : { value: -1  },
      "large miter limit" : { value: 10   }
    };

    for ( var key in testcases ) {
        CGContextSetMiterLimit(mockContext, testcases[key].value);
        [self compareGState:mockContext.gState
                       with:{ miterLimit: testcases[key].value }
                    message:key];
    }
}

- (void)testCGContextSetBlendMode
{
    var mockContext = [self createMockContext],
        testcases = {
      "nil blend mode" : { value: nil },
      "blend mode kCGBlendModeScreen" : { value: kCGBlendModeScreen },
      "blend mode kCGBlendModeLighten" : { value: kCGBlendModeLighten },
      "blend mode kCGBlendModeColorBurn" : { value: kCGBlendModeColorBurn },
      "blend mode kCGBlendModeHardLight" : { value: kCGBlendModeHardLight },
      "blend mode kCGBlendModeExclusion" : { value: kCGBlendModeExclusion },
      "blend mode kCGBlendModeHue" : { value: kCGBlendModeHue },
    };

    for ( var key in testcases ) {
        CGContextSetBlendMode(mockContext, testcases[key].value);
        [self compareGState:mockContext.gState
                       with:{ blendMode: testcases[key].value }
                    message:key];
    }
}

/*
  List of still to be tested functions.

- (void)testCGContextAddArc
- (void)testCGContextAddArcToPoint
- (void)testCGContextAddCurveToPoint
- (void)testCGContextAddEllipseInRect
- (void)testCGContextAddLineToPoint
- (void)testCGContextAddLines
- (void)testCGContextAddPath
- (void)testCGContextAddQuadCurveToPoint
- (void)testCGContextAddRect
- (void)testCGContextAddRects
- (void)testCGContextBeginPath
- (void)testCGContextClosePath
- (void)testCGContextConcatCTM
- (void)testCGContextEOFillPath
- (void)testCGContextFillEllipseInRect
- (void)testCGContextFillPath
- (void)testCGContextFillRect
- (void)testCGContextFillRects
- (void)testCGContextFillRoundedRectangleInRect
- (void)testCGContextGetCTM
- (void)testCGContextMoveToPoint
- (void)testCGContextRelease
- (void)testCGContextRetain
- (void)testCGContextRotateCTM
- (void)testCGContextScaleCTM
- (void)testCGContextSetAlpha
- (void)testCGContextSetFillColor
- (void)testCGContextSetShadow
- (void)testCGContextSetShadowWithColor
- (void)testCGContextSetStrokeColor
- (void)testCGContextStrokeEllipseInRect
- (void)testCGContextStrokeLineSegments
- (void)testCGContextStrokePath
- (void)testCGContextStrokeRect
- (void)testCGContextStrokeRectWithWidth
- (void)testCGContextStrokeRoundedRectangleInRect
- (void)testCGContextTranslateCTM

*/

@end

@implementation CGContextTest (ContextHelpers)

/*
  Compare a graphics state with a hash. Unlike other compare methods, this uses
  a default hash that contains values that are overridden if defined in the override
  hash.
*/
- (void)compareGState:(id)aGState
                 with:(id)overrideHash
              message:(CPString)aMsg
{
    aMsg += " (via. compareGState): ";
    var testdata = { alpha:       1.0,
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

    for ( var key in testdata )
        [self assert:(key in overrideHash ? overrideHash[key] : testdata[key])
              equals:aGState[key]
             message:aMsg + "Failed for " + key];

    [self compareSize:("shadowOffset" in overrideHash ? overrideHash["shadowOffset"] :
                       CGSizeMakeZero())
                 with:aGState.shadowOffset
              message:aMsg + "Failed for shadowOffset"];

    [self compareTransform:("CTM" in overrideHash ? overrideHash["CTM"] :
                            CGAffineTransformMakeIdentity())
                      with:aGState.CTM
                   message:aMsg + "Failed for CTM"];
}

- (void)checkInitialGState:(id)aGState message:(CPString)aMsg
{
    [self compareGState:aGState with:{} message:aMsg];
}

- (id)createMockContext
{
    return { DOMElement:NULL, path:NULL, gState:CGGStateCreate(), gStateStack:[] };
}

@end
