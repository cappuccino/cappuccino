@import <AppKit/CGAffineTransform.j>
@import "CGTestCase.j"

@implementation CGAffineTransformTest : CGTestCase

- (void)testAffineTransformMake
{
    [self compareTransform:CGAffineTransformMake(1, 2, 3, 4, 3.2, 5.4)
                      with:{ a: 1, b: 2, c: 3, d: 4, tx: 3.2, ty: 5.4 }
                   message:"transform make"];
}

- (void)testCGAffineTransformMakeIdentity
{
    [self compareTransform:CGAffineTransformMakeIdentity()
                      with:{ a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 }
                   message:"transform make identity"];
}

- (void)testAffineTransformMakeCopy
{
    var transform = CGAffineTransformMake(1, 2, 3, 4, 3.2, 5.4),
        t2 = CGAffineTransformMakeCopy(transform);

    transform.a = transform.b = transform.c = transform.d =
        transform.tx = transform.ty = 0;

    [self compareTransform:t2
                      with:CGAffineTransformMake(1, 2, 3, 4, 3.2, 5.4)
                   message:"copy correctly made"];

    [self compareTransform:transform
                      with:CGAffineTransformMake(0, 0, 0, 0, 0, 0)
                   message:"original transform was changed"];
}

- (void)testAffineTransformCreateCopy
{
    // FIXME: CGAffineTransformCreateCopy seems to be working but code has a Fixme?
    var transform = CGAffineTransformMake(1, 2, 3, 4, 3.2, 5.4),
        t2 = CGAffineTransformCreateCopy(transform);

    transform.a = transform.b = transform.c = transform.d =
        transform.tx = transform.ty = 0;

    [self compareTransform:t2
                      with:CGAffineTransformMake(1, 2, 3, 4, 3.2, 5.4)
                   message:"copy correctly made"];

    [self compareTransform:transform
                      with:CGAffineTransformMake(0, 0, 0, 0, 0, 0)
                   message:"original transform was changed"] ;
}

- (void)testAffineTransformMakeScale
{
    [self compareTransform:CGAffineTransformMakeScale(3, 4)
                      with:CGAffineTransformMake(3, 0, 0, 4, 0, 0)
                   message:"make scale"];
}

- (void)testAffineTransformMakeTranslation
{
    [self compareTransform:CGAffineTransformMakeTranslation(3, 4)
                      with:CGAffineTransformMake(1, 0, 0, 1, 3, 4)
                   message:"make translation"];
}

- (void)testAffineTransformTranslate
{
    var transform = CGAffineTransformMakeTranslation(3, 4);

    [self compareTransform:CGAffineTransformTranslate(transform, -3, -4)
                      with:CGAffineTransformMakeIdentity()
                   message:"translate to identity"];

    [self compareTransform:CGAffineTransformTranslate(transform, 0, 0)
                      with:transform
                   message:"zero translate"];
}

- (void)testAffineTransformScale
{
    var transform = CGAffineTransformMakeScale(3, 4);

    [self compareTransform:CGAffineTransformScale(transform, 1 / 3, 1 / 4)
                      with:CGAffineTransformMakeIdentity()
                   message:"scale to identity"];

    transform = CGAffineTransformMake(2, -2, -3, 3, 3.2, 5.4);
    [self compareTransform:CGAffineTransformScale(transform, 1, 1)
                      with:transform
                   message:"scale by 1"];

    [self compareTransform:CGAffineTransformScale(transform, 2, 5)
                      with:CGAffineTransformMake(4,-4,-15,15, 3.2,5.4)
                   message:"random scale to somewhere"];
}

- (void)testAffineTransformConcat
{
    var testcases = {
            "identity concat" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeIdentity(),
                                                CGAffineTransformMakeIdentity()),
              expdata: CGAffineTransformMakeIdentity()
            },

            "translation" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeTranslation(3, 4),
                                                CGAffineTransformMakeTranslation(-3, -4)),
              expdata: CGAffineTransformMakeIdentity()
            },

            "translation (reversed)" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeTranslation(-3, -4),
                                                CGAffineTransformMakeTranslation(3, 4)),
              expdata: CGAffineTransformMakeIdentity()
            },

            "scale" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeScale(3, 4),
                                                CGAffineTransformMakeScale(1 / 3, 1 / 4)),
              expdata: CGAffineTransformMakeIdentity()
            },

            "scale (reversed)" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeScale(1 / 3, 1 / 4),
                                                CGAffineTransformMakeScale(3, 4)),
              expdata: CGAffineTransformMakeIdentity()
            },

            "rotation" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeRotation(PI),
                                                CGAffineTransformMakeRotation(-PI)),
              expdata: CGAffineTransformMakeIdentity()
            },
        };

    for (var key in testcases)
        [self compareTransform:testcases[key].testdata with:testcases[key].expdata message:key];
}

- (void)testPointApplyAffineTransform
{
    var testcases = {
            "translate to zero" : {
              testdata: CGPointApplyAffineTransform(CGPointMake(3, 4),
                                                    CGAffineTransformMakeTranslation(-3, -4)),
              expdata: CGPointMakeZero()
            },

            "scale to 1,1" : {
              testdata: CGPointApplyAffineTransform(CGPointMake(3, 4),
                                                    CGAffineTransformMakeScale(1 / 3, 1 / 4)),
              expdata: CGPointMake(1, 1)
            },

            "scale and translate to zero" : {
              testdata: CGPointApplyAffineTransform(CGPointMake(3, 4),
                                                    CGAffineTransformConcat(
                                                          CGAffineTransformMakeScale(1 / 3, 1 / 4),
                                                          CGAffineTransformMakeTranslation(-1, -1))),
              expdata: CGPointMakeZero()
            },
        };

    for (var key in testcases)
        [self comparePoint:testcases[key].testdata with:testcases[key].expdata message:key];
}

- (void)testSizeApplyAffineTransform
{
    var testcases = {
            "translation on size should do nothing" : {
              testdata: CGSizeApplyAffineTransform(CGSizeMake(3, 12),
                                                   CGAffineTransformMakeTranslation(-3, -4)),
              expdata: CGSizeMake(3, 12)
            },

            "scale to 1,1" : {
              testdata: CGSizeApplyAffineTransform(CGSizeMake(3, 4),
                                                   CGAffineTransformMakeScale(1 / 3, 1 / 4) ),
              expdata: CGSizeMake(1, 1)
            },

            "scale and translate combined" : {
              testdata: CGSizeApplyAffineTransform(CGSizeMake(3, 4),
                                                   CGAffineTransformConcat(
                                                           CGAffineTransformMakeScale(1 / 3, 1 / 4),
                                                           CGAffineTransformMakeTranslation(-1, -1))),
              expdata: CGSizeMake(1, 1)

            },
        };

    for (var key in testcases)
        [self compareSize:testcases[key].testdata with:testcases[key].expdata message:key];
}

- (void)testAffineTransformIsIdentityPositive
{
  var testcases = {
            "identity is identity" : {
              testdata: CGAffineTransformMakeIdentity()
            },

            "zero rotation is identity" : {
              testdata: CGAffineTransformMakeRotation(0),
            },

            "zero translation is identity" : {
              testdata: CGAffineTransformMakeTranslation(0,0)
            },

            "one scale is identity" : {
              testdata: CGAffineTransformMakeScale(1, 1)
            },

            "identity concat'ed" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeIdentity(),
                                                 CGAffineTransformMakeIdentity()),
            },

            "translation" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeTranslation(3, 4),
                                                 CGAffineTransformMakeTranslation(-3, -4)),
            },

            "scale" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeScale(3, 4),
                                                CGAffineTransformMakeScale(1 / 3, 1 / 4)),
            },

            "rotation" : {
              testdata: CGAffineTransformConcat(CGAffineTransformMakeRotation(-PI),
                                                CGAffineTransformMakeRotation(PI)),
            },
        };

    for (var key in testcases)
        [self assert:YES
              equals:CGAffineTransformIsIdentity(testcases[key].testdata)
             message:key];
}

- (void)testAffineTransformIsIdentityNegative
{
    var testcases = {
            "some random transform" : {
              testdata: CGAffineTransformMake(1, 1, 1, 1, 1, 1)
            },

            "non-zero translation is not identity" : {
              testdata: CGAffineTransformMakeTranslation(1, 1)
            },

            "non-one scale is not identity" : {
              testdata: CGAffineTransformMakeScale(2,2)
            },

            "rotation" : {
              testdata: CGAffineTransformMakeRotation(PI),
            },

            // TODO a two-pi rotation is actually identity
            "2PI rotation is NOT identity?" : {
              testdata: CGAffineTransformMakeRotation(PI * 2),
            },
        };

    for (var key in testcases)
        [self assert:NO
              equals:CGAffineTransformIsIdentity(testcases[key].testdata)
             message:key];
}

- (void)testAffineTransformEqualToTransform
{
    var testcases = {
            "identity" : {
              lhs: CGAffineTransformMakeIdentity(),
              rhs: CGAffineTransformMakeIdentity(),
              expdata: YES
            },

            "translate" : {
              lhs: CGAffineTransformMakeTranslation(1, 1),
              rhs: CGAffineTransformMakeTranslation(1, 1),
              expdata: YES
            },

            "scale" : {
              lhs: CGAffineTransformMakeScale(1, 1),
              rhs: CGAffineTransformMakeScale(1, 1),
              expdata: YES
            },

            "rotation" : {
              lhs: CGAffineTransformMakeRotation(PI),
              rhs: CGAffineTransformMakeRotation(PI),
              expdata: YES
            },

            "translate and scale" : {
              lhs: CGAffineTransformMakeScale(1, 1),
              rhs: CGAffineTransformMakeTranslation(1, 1),
              expdata: NO
            },
        };

    for (var key in testcases)
        [self assert:testcases[key].expdata
              equals:CGAffineTransformEqualToTransform(testcases[key].lhs, testcases[key].rhs)
             message:key];
}

- (void)testStringCreateWithCGAffineTransform
{
    // FIXME?: should there be a leading space on these strings
    var testcases = {
            "identity" : {
              testdata: CGAffineTransformMakeIdentity(),
              expdata: " [[ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1]]"
            },

            "scale" : {
              testdata: CGAffineTransformMakeScale(3, 4),
              expdata: " [[ 3, 0, 0 ], [ 0, 4, 0 ], [ 0, 0, 1]]"
            },

            "translation" : {
              testdata: CGAffineTransformMakeTranslation(3, 4),
              expdata: " [[ 1, 0, 0 ], [ 0, 1, 0 ], [ 3, 4, 1]]"
            },

            "scale and translation" : {
              testdata: CGAffineTransformTranslate(CGAffineTransformMakeScale(3, 4), 5, 6),
              expdata: " [[ 3, 0, 0 ], [ 0, 4, 0 ], [ 15, 24, 1]]"
            },
        };

    for (var key in testcases)
        [self assert:testcases[key].expdata
              equals:CGStringCreateWithCGAffineTransform(testcases[key].testdata)
             message:key];
}

- (void)testStringFromCGAffineTransform
{
    var testcases = {
            "identity" : {
              testdata: CGAffineTransformMakeIdentity(),
              expdata: "{1, 0, 0, 1, 0, 0}"
            },

            "scale" : {
              testdata: CGAffineTransformMakeScale(3, 4),
              expdata: "{3, 0, 0, 4, 0, 0}"
            },

            "translation" : {
              testdata: CGAffineTransformMakeTranslation(3, 4),
              expdata: "{1, 0, 0, 1, 3, 4}"
            },

            "rotation - zero" : {
              testdata: CGAffineTransformMakeRotation(0),
              expdata: "{1, 0, 0, 1, 0, 0}"
            },

            "rotation - pi" : {
              testdata: CGAffineTransformMakeRotation(PI),
              expdata: "{-1, 1.2246467991473532e-16, -1.2246467991473532e-16, -1, 0, 0}"
            },

            "rotation - 2pi" : {
              testdata: CGAffineTransformMakeRotation(2 * PI),
              expdata: "{1, -2.4492935982947064e-16, 2.4492935982947064e-16, 1, 0, 0}"
            },

            "rotation - 3pi" : {
              testdata: CGAffineTransformMakeRotation(3 * PI),
              expdata: "{-1, 3.6739403974420594e-16, -3.6739403974420594e-16, -1, 0, 0}"
            },

            "scale and translation and rotate" : {
              testdata: CGAffineTransformRotate(CGAffineTransformTranslate(CGAffineTransformMakeScale(3, 4), 5, 6), PI),
              expdata: "{-3, 4.898587196589413e-16, -3.6739403974420594e-16, -4, 15, 24}"
            },
        };

    for (var key in testcases)
        [self assert:testcases[key].expdata
              equals:CPStringFromCGAffineTransform(testcases[key].testdata)
             message:key];
}

- (void)testAffineTransformRotate
{
    var ang = PI + 0.5 * PI,
        transform = CGAffineTransformMake(1, 2, 3, 4, 5, 6),
        cos = COS(ang),
        sin = SIN(ang);

    var testcases = {
            "affine transform rotate failed" : {
              testdata: CGAffineTransformRotate(transform, ang),
              expdata: CGAffineTransformMake(transform.a * cos + transform.c * sin,
                                                        transform.b * cos + transform.d * sin,
                                                        transform.c * cos - transform.a * sin,
                                                        transform.d * cos - transform.b * sin,
                                                        transform.tx,transform.ty)
            },

            "rotation negation" : {
              testdata: CGAffineTransformRotate(CGAffineTransformRotate(CGAffineTransformMakeScale(3, 4), PI), -PI),
              expdata: CGAffineTransformMakeScale(3, 4)
            }
        };

    for (var key in testcases)
        [self compareTransform:testcases[key].testdata with:testcases[key].expdata message:key];
}

- (void)testAffineTransformInvert
{
    var transform = CGAffineTransformRotate(CGAffineTransformTranslate(CGAffineTransformMakeScale(3, 4), 5, 6), PI),
        determinant = 1 / (transform.a * transform.d - transform.b * transform.c),
        invertedtransform = CGAffineTransformMake(determinant * transform.d,
                                                  -determinant * transform.b,
                                                  -determinant * transform.c,
                                                  determinant * transform.a,
                                                  determinant * (transform.c * transform.ty -
                                                                 transform.d * transform.tx),
                                                  determinant * (transform.b * transform.tx -
                                                                 transform.a * transform.ty));

    var testcases = {
            "test invert algorithm" : {
              testdata: transform,
              expdata: invertedtransform
            },

            "identity should be it self on inversion" : {
              testdata: CGAffineTransformMakeIdentity(),
              expdata: CGAffineTransformMakeIdentity()
            },

            "rotation" : {
              testdata: CGAffineTransformMakeRotation(-PI),
              expdata: CGAffineTransformMakeRotation(PI),
            },

            "translation" : {
              testdata: CGAffineTransformMakeTranslation(4, 5),
              expdata: CGAffineTransformMakeTranslation(-4, -5)
            },

            "scale" : {
              testdata: CGAffineTransformMakeScale(3, 4),
              expdata: CGAffineTransformMakeScale(1 / 3, 1 / 4)
            },
        };

    for (var key in testcases)
        [self compareTransform:CGAffineTransformInvert(testcases[key].testdata)
                          with:testcases[key].expdata
                       message:key];
}

- (void)testRectApplyAffineTransform
{
    var rect = CGRectMake(3, 4, 5, 6),
        testcases = {
            "identity does nothing" : {
              testdata: CGRectApplyAffineTransform(rect, CGAffineTransformMakeIdentity() ),
              expdata: rect
            },

            "rotation 90 degrees" : {
              testdata: CGRectApplyAffineTransform(rect, CGAffineTransformMakeRotation(PI / 2)),
              expdata: CGRectMake(-10, 3.0000000000000004, 6, 5)
            },

            "translation" : {
              testdata: CGRectApplyAffineTransform(rect, CGAffineTransformMakeTranslation(3, 4)),
              expdata: CGRectMake(6, 8, 5, 6)
            },

            "scale" : {
              testdata: CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(1, 4)),
              expdata: CGRectMake(3, 16, 5, 24)
            },

            "rotate, translate and scale" : {
              testdata: CGRectApplyAffineTransform(rect, CGAffineTransformRotate(CGAffineTransformTranslate(CGAffineTransformMakeScale(3, 4),5,6), PI)),
              expdata: CGRectMake(-9.000000000000004, -16,
                                  15.000000000000002, 24.000000000000004)
            },
        };

    for (var key in testcases)
        [self compareRect:testcases[key].testdata with:testcases[key].expdata message:key];
}

@end
