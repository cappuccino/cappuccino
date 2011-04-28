@import <AppKit/CGColorSpace.j>

@implementation CGColorSpaceTest : OJTestCase 

- (void)testColorSpaceCreateWithName
{
    var testdata = { 
      "CGColorSpaceGenericGray" : {
          model: kCGColorSpaceModelMonochrome,
          count: 1,
          base: NULL
      },
      "CGColorSpaceGenericRGB" : {
          model: kCGColorSpaceModelRGB,
          count: 3,
          base: NULL
      },
      "CGColorSpaceGenericCMYK" : {
          model: kCGColorSpaceModelCMYK,
          count: 4,
          base: NULL
      },
      "CGColorSpaceGenericRGBLinear" : {
          model: kCGColorSpaceModelRGB,
          count: 3,
          base: NULL
      },
      "CGColorSpaceGenericRGBHDR" : {
          model: kCGColorSpaceModelRGB,
          count: 3,
          base: NULL
      },
      "CGColorSpaceAdobeRGB1998" : {
          model: kCGColorSpaceModelRGB,
          count: 3,
          base: NULL
      },
      "CGColorSpaceSRGB" : {
          model: kCGColorSpaceModelRGB,
          count: 3,
          base: NULL
      },
    }
    
    for ( var key in testdata ) {
        var clrsp = CGColorSpaceCreateWithName(key),
            expdata = testdata[key];
        [self assert:expdata.model equals:clrsp.model message:"model for "+key];
        [self assert:expdata.count equals:clrsp.count message:"count for "+key];
        [self assert:expdata.base equals:clrsp.base message:"base for "+key];
    }

    [self assert:NULL 
          equals:CGColorSpaceCreateWithName("doesnotexist") 
          message:"should be missing"];
}

- (void)testColorSpaceStandardizeComponents
{
    var testcases = {
        "notsupported1" : {
          testdata : {
              model: kCGColorSpaceModelIndexed, 
              count: 5
          },
          expected: [5,4,3,2,1,NaN] // alpha value normalisation adds value at index 5
        },
        "notsupported2" : {
          testdata : {
              model: kCGColorSpaceModelLab,
              count: 5
          },
          expected: [5,4,3,2,1,NaN]
        },
        "notsupported3" : {
          testdata : {
              model: kCGColorSpaceModelPattern,
              count: 4
          },
          expected: [5,4,3,2,1]
        },
        "base override with count value" : {
          testdata : {
              model: kCGColorSpaceModelPattern,
              base: { model: kCGColorSpaceModelMonochrome },
              count: 4
          },
          expected: [1,1,1,1,1],
        },
        "base override no count value" : {
          testdata : {
              model: kCGColorSpaceModelPattern,
              base: { model: kCGColorSpaceModelMonochrome, count: 4 },
              count: 0
          },
          expected: [1,4,3,2,1], // alpha value is assumed to be at index 0
        },
        "monochrome color space model" : {
          testdata : {
              model: kCGColorSpaceModelMonochrome,
              count: 2
          },
          expected: [1,1,1,2,1],
        },
        "rgb color space model" : {
          testdata : {
              model: kCGColorSpaceModelRGB,
              count: 2
          },
          expected: [1,1,1,2,1],
        },
        "cmyk color space model" : {
          testdata : {
              model: kCGColorSpaceModelCMYK,
              count: 2
          },
          expected: [1,1,1,2,1],
        },
        "devicen color space model" : {
          testdata : {
              model: kCGColorSpaceModelDeviceN,
              count: 2
          },
          expected: [1,1,1,2,1],
        },
    }

    for ( var key in testcases ) {
        var components = [5,4,3,2,1];
        CGColorSpaceStandardizeComponents( testcases[key].testdata, components);
        [self assert:testcases[key].expected equals:components message:"Failed for "+key];
    }
}

- (void)testRgbStandardize
{
    var clrspc = CGColorSpaceCreateDeviceRGB(),
        testcases = {
        "negative values" : {
          components: [-5,-4,-3,-2,-1,-1,-1,-1],
          expected: [0,0,0,0,-1,-1,-1,-1],
        },
        // TODO: this happens because first the alpha value is normalised,
        // TODO: so the components array does not have length 0, rather 4.
        "missing values become undefined" : {
          components: [],
          expected: [undefined,undefined,undefined,1],
        },
        "values standarized if between 0 and 1" : {
          components: [0.3, 0.4, 0.5, 0.6],
          expected: [ROUND(0.3*255)/255, ROUND(0.4*255)/255, 
                          ROUND(0.5*255)/255, ROUND(0.6*255)/255],
        },
        "values 0 or 1 if zero or one" : {
          components: [0, 1, 0, 1],
          expected: [0,1,0,1],
        }
    };

    for ( var key in testcases ) {
        CGColorSpaceStandardizeComponents( clrspc, testcases[key].components);
        [self assert:testcases[key].expected 
              equals:testcases[key].components 
              message:"Failed for "+key];
    }
}

@end
