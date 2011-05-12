@import <AppKit/CGPath.j>
@import "CGTestCase.j"

var MockPathMake = function(count, start, current, elements ) {
  return { count: count, start: start, current: current, elements: elements };
};
var PathDefaultValues = MockPathMake(0,NULL,NULL,[]);

@implementation CGPathTest : CGTestCase

- (void)testCGPathCreateMutable
{
    [self comparePath:CGPathCreateMutable()
                 with:PathDefaultValues
              message:"path create mutable"];
}

- (void)testCGPathCreateMutableCopy
{
    var p1 = CGPathCreateMutable(),
        p2 = CGPathCreateMutableCopy(p1);

    CGPathMoveToPoint(p1, nil, 1,1 );

    [self comparePath:p2 with:PathDefaultValues message:"copy should be empty"];

    var p1WithCompare = MockPathMake(1, CGPointMake(1,1), CGPointMake(1,1), [{
              type:kCGPathElementMoveToPoint, x:1, y:1
            }]);

    [self comparePath:p1
                 with:p1WithCompare
              message:"original should contain one point"];
}

- (void)testCGPathCreateCopy
{
    var p1 = CGPathCreateMutable(),
        p2 = CGPathCreateCopy(p1);

    CGPathMoveToPoint(p1, nil, 1,1 );

    [self comparePath:p2 with:PathDefaultValues message:"copy should be empty"];

    var p1WithCompare = MockPathMake(1, CGPointMake(1,1), CGPointMake(1,1), [{
              type:kCGPathElementMoveToPoint, x:1, y:1
            }]);

    [self comparePath:p1
                 with:p1WithCompare
              message:"original should contain one point"];
}

- (void)testCGPathRelease
{
    var path = CGPathCreateMutable();
    [self assert:undefined equals:CGPathRelease(path)];
}

- (void)testCGPathRetain
{
    var path = CGPathCreateMutable();
    [self assert:true equals:path == CGPathRetain(path)];
}

- (void)testCGPathCloseSubpath
{
    var path = CGPathCreateMutable();

    // closing an empty path does nothing
    for ( var idx = 0; idx < 5; idx++ )
        CGPathCloseSubpath(path);

    [self comparePath:path
                 with:PathDefaultValues
              message:"closing an empty path does nothing"];

    // closing a path that has a move to results in closesubpath
    CGPathMoveToPoint(path, nil, 10, 10);
    CGPathCloseSubpath(path);

    var comparePath = MockPathMake(2, CGPointMake(10,10), CGPointMake(10,10), [
      { type:kCGPathElementMoveToPoint, x:10, y:10 },
      { type:kCGPathElementCloseSubpath, points:[CGPointMake(10,10)] }
    ]);

    [self comparePath:path with:comparePath message:"simple closesubpath"];

    // reclosing a closed path results in nothing.
    for ( var idx = 0; idx < 5; idx++ )
        CGPathCloseSubpath(path);

    [self comparePath:path with:comparePath message:"reclosesubpath"];

    // another move to and then close.
    CGPathMoveToPoint(path, nil, 20, 20);
    CGPathCloseSubpath(path);

    comparePath = MockPathMake(4, CGPointMake(20,20), CGPointMake(20,20), [
      { type:kCGPathElementMoveToPoint, x:10, y:10 },
      { type:kCGPathElementCloseSubpath, points:[CGPointMake(10,10)] },
      { type:kCGPathElementMoveToPoint, x:20, y:20 },
      { type:kCGPathElementCloseSubpath, points:[CGPointMake(20,20)] },
    ]);

    [self comparePath:path with:comparePath message:"second closesubpath"];
}

- (void)testCGPathEqualToPath
{
    [self ensurePathsAreEqual:CGPathCreateMutable()
                         with:CGPathCreateMutable()
                         message:"empty paths"];

    var p1 = CGPathCreateMutable(),
        p2 = CGPathCreateMutable(),
        pt1 = CGPointMake(1,1),
        pt2 = CGPointMake(2,2);

    // contrived test but still important since a newly created test has start
    // and current points set to NULL. Testcases are name/value pairs where the value
    // is an array containing [exp_result, p1.start, p1.current, p2.start, p2.current]
    var testcases = {
      "t00" : [YES, NULL, NULL, NULL, NULL],
      "t01" : [ NO, NULL, NULL,  pt1, NULL],
      "t02" : [YES,  pt1, NULL,  pt1, NULL],
      "t03" : [ NO,  pt2, NULL,  pt1, NULL],
      "t04" : [ NO,  pt1,  pt2,  pt1, NULL],
      "t05" : [YES,  pt1,  pt2,  pt1,  pt2],
      "t06" : [ NO,  pt2,  pt2,  pt1,  pt2],
      "t07" : [ NO,  pt1,  pt2, NULL,  pt2],
      "t08" : [YES, NULL,  pt2, NULL,  pt2],
      "t09" : [ NO, NULL,  pt1, NULL,  pt2],
    };

    for ( var key in testcases ) {
        var ary = testcases[key];

        p1.start   = ary[1];
        p1.current = ary[2];
        p2.start   = ary[3];
        p2.current = ary[4];

        [self assert:ary[0] equals:CGPathEqualToPath(p1, p2) message:key];
        [self assert:ary[0] equals:CGPathEqualToPath(p2, p1) message:key+"(reverse)"];
    }

    // build up the paths and compare each time. Apply the path function first to p1
    // and ensure that it does not match p2. Then apply to p2 and ensure that the
    // paths are equal.
    //
    // To make sure things are working, replace the 'path' variable in one of the
    // CGPathXXXXX functions (in the 'funct' member) with 'p1' (or 'p2'), i.e. apply
    // function to only one of the paths. This should cause an assert error.
    var testcases = {
      "MoveToPoint" : {
        funct : function(path) {
            CGPathMoveToPoint(path, nil, 20, 20);
        },
      },

      "AddLineToPoint" : {
        funct : function(path) {
            CGPathAddLineToPoint(path, nil, 100, 100);
        }
      },

      "AddLines" : {
        funct : function(path) {
            var points = [ CGPointMake(3,4),CGPointMake(7,4),CGPointMake(3,5)];
            CGPathAddLines(path, nil, points, 3);
        }
      },

      "AddCurveToPoint" : {
        funct : function(path) {
            CGPathAddCurveToPoint(path, nil, 10, 20, 30, 40, 50, 60 );
        }
      },

      "AddArc" : {
        funct : function(path) {
            CGPathAddArc(path, nil, 43, 82, 12, Math.PI, Math.PI*3/2, YES);
        }
      },

      "AddQuadCurveToPoint" : {
        funct : function(path) {
            CGPathAddQuadCurveToPoint(path, nil, 231, 231, 45,67);
        }
      },

      "AddRects" : {
        funct : function(path) {
            CGPathAddRects(path, nil, [CGRectMake( 12,24,100,231)], 1);
            // avoid an issue expecting the paths to be different when one is
            // closed -- won't happen because AddRects close the current path
            CGPathMoveToPoint(path, nil, 20, 20);
        }
      },
    };

    p1 = CGPathCreateMutable();
    p2 = CGPathCreateMutable();
    var msg = "";
    for ( var key in testcases ) {
        msg += " (" + key + ")";
        testcases[key].funct(p1);
        [self assert:NO equals:CGPathEqualToPath(p1, p2) message:msg+"[p1]"];
        [self assert:NO equals:CGPathEqualToPath(p2, p1) message:msg+"[p1] - reverse"];

        testcases[key].funct(p2);
        [self ensurePathsAreEqual:p1 with:p2 message:msg+"[both]"];
        [self closeAndCompare:p1 with:p2 message:msg+"[close]"];
    }
}

- (void)testCGPathGetCurrentPoint
{
    [self assert:NULL
          equals:CGPathGetCurrentPoint(CGPathCreateMutable())
         message:"Newly created path"];

    [self assert:NULL
          equals:CGPathGetCurrentPoint(NULL)
         message:"null path"];

    var point = CGPointMake( 10, 10 );

    [self comparePoint:point
                  with:CGPathGetCurrentPoint(MockPathMake(0,NULL,point,NULL))
               message:"mock path with point"];

    var path = CGPathCreateMutable();

    CGPathMoveToPoint(path, nil, 10, 10);

    [self comparePoint:point
                  with:CGPathGetCurrentPoint(path)
               message:"move to path"];
}

- (void)testCGPathIsEmpty
{
    var testcases = {
      "nil" : {
        testdata : nil,
        expdata: YES
      },

      "default path values" : {
        testdata: PathDefaultValues,
        expdata: YES
      },

      "newly created path" : {
        testdata: CGPathCreateMutable(),
        expdata: YES
      },

      "copy from new path" : {
        testdata: CGPathCreateMutableCopy(CGPathCreateMutable()),
        expdata: YES
      },

      "something with count > 0" : {
        testdata: { count: 1 },
        expdata: NO
      },

      "a path with count > 0" : {
        testdata: MockPathMake( 10, NULL, NULL, NULL ),
        expdata: NO
      }
    };

    for ( var key in testcases )
        [self assert:testcases[key].expdata
              equals:CGPathIsEmpty(testcases[key].testdata)
             message:key];
}

/*
  List of still to be tested functions.

- (void)testCGPathAddArc
- (void)testCGPathAddArcToPoint
- (void)testCGPathAddCurveToPoint
- (void)testCGPathAddLines
- (void)testCGPathAddLineToPoint
- (void)testCGPathAddPath
- (void)testCGPathAddQuadCurveToPoint
- (void)testCGPathAddRect
- (void)testCGPathAddRects
- (void)testCGPathMoveToPoint
- (void)testCGPathWithEllipseInRect
- (void)testCGPathWithRoundedRectangleInRect

*/

@end

@implementation CGPathTest (Helpers)

- (void)closeAndCompare:(CGPath)firstPath
                   with:(CGPath)secondPath
                message:(CPString)aMsg
{
    CGPathCloseSubpath(firstPath);
    [self assert:NO
          equals:CGPathEqualToPath(firstPath,secondPath)
         message:aMsg+" (closeandcompare) (first close)"];

    CGPathCloseSubpath(secondPath);
    [self ensurePathsAreEqual:firstPath
                         with:secondPath
                      message:aMsg+" (closeandcompare)"];
}

- (void)ensurePathsAreEqual:(CGPath)firstPath
                       with:(CGPath)secondPath
                    message:(CPString)aMsg
{
    // if paths don't match but compare correctly, or vice versa, then know about it.
    // Hence we compare and then do the equals. We also ensure that equals works
    // with either ordering.
    [self comparePath:firstPath
                 with:secondPath
              message:aMsg + " (comparePath)"];

    [self assert:YES
          equals:CGPathEqualToPath(firstPath, secondPath)
         message:aMsg + " (equalPath)"];

    [self comparePath:secondPath
                 with:firstPath
              message:aMsg + " (comparePath) (reverse)"];

    [self assert:YES
          equals:CGPathEqualToPath(secondPath, firstPath)
         message:aMsg + " (equalPath) (reverse)"];
}


- (void)comparePath:(CGPath)aPath
               with:(id)anotherPath
            message:(CPString)aMsg
{
    // count
    [self assert:anotherPath.count
          equals:aPath.count
         message:aMsg + ": Failed for count"];

    // ensure that the count equals the number of elements
    [self assert:aPath.count
          equals:aPath.elements.length
         message:"Elements array does not match count"];

    [self assert:anotherPath.count
          equals:anotherPath.elements.length
         message:"Elements array does not match count for anotherPath"];

    // start and current points. check for null or a point.
    var pointCompares = {
      "start"   : ("start" in anotherPath ? anotherPath["start"] : NULL),
      "current" : ("current" in anotherPath ? anotherPath["current"] : NULL)
    };

    for ( var key in pointCompares )
        if ( pointCompares[key] )
            [self comparePoint:pointCompares[key]
                          with:aPath[key]
                       message:aMsg + ": Failed for " + key];
        else
            [self assert:NULL equals:aPath[key] message:aMsg + ": Failed for " + key];

    // elements -- can not be empty or null since we compared count and
    // elements.length above.
    for (var idx = 0, count = anotherPath.count; idx < count; ++idx)
    {
        var compareElement = anotherPath.elements[idx],
            withElement = aPath.elements[idx],
            msg = aMsg + ": Failed for element at " + idx;

        // ensure types are equal
        [self assert:compareElement.type
              equals:withElement.type
             message:msg + ": attr: type"];

        switch (compareElement.type)
        {
        case kCGPathElementMoveToPoint:
            [self comparePoint:CGPointMake( compareElement.x, compareElement.y)
                          with:CGPointMake( withElement.x, withElement.y)
                       message:msg + " (kCGPathElementMoveToPoint)"];
            break;

        case kCGPathElementAddLineToPoint:
            [self comparePoint:CGPointMake( compareElement.x, compareElement.y)
                          with:CGPointMake( withElement.x, withElement.y)
                       message:msg + " (kCGPathElementAddLineToPoint)"];
            break;

        case kCGPathElementCloseSubpath:
            msg += " (kCGPathElementCloseSubpath)";

            // ensure that each has 1 point ...
            [self assert:2
                  equals:compareElement.points.length + withElement.points.length
                 message:msg + " (point count)"];

            [self comparePoint:compareElement.points[0]
                          with:withElement.points[0]
                       message:msg];
            break;

        case kCGPathElementAddQuadCurveToPoint:
            msg += " (kCGPathElementAddQuadCurveToPoint)";

            [self comparePoint:CGPointMake( compareElement.cpx, compareElement.cpy)
                          with:CGPointMake( withElement.cpx, withElement.cpy)
                       message:msg + " cp"];

            [self comparePoint:CGPointMake( compareElement.x, compareElement.y)
                          with:CGPointMake( withElement.x, withElement.y)
                       message:msg + " end"];
            break;

        case kCGPathElementAddCurveToPoint:
            msg += " (kCGPathElementAddCurveToPoint)";

            [self comparePoint:CGPointMake( compareElement.cp1x, compareElement.cp1y)
                          with:CGPointMake( withElement.cp1x, withElement.cp1y)
                       message:msg + " cp1"];

            [self comparePoint:CGPointMake( compareElement.cp2x, compareElement.cp2y)
                          with:CGPointMake( withElement.cp2x, withElement.cp2y)
                       message:msg + " cp2"];

            [self comparePoint:CGPointMake( compareElement.x, compareElement.y)
                          with:CGPointMake( withElement.x, withElement.y)
                       message:msg + " end"];
            break;

        case kCGPathElementAddArc:
            msg += " (kCGPathElementAddArc)";

            [self comparePoint:CGPointMake( compareElement.x, compareElement.y)
                          with:CGPointMake( withElement.x, withElement.y)
                       message:msg + " end"];

            var otherAttrs = { "radius"     : compareElement.radius,
                               "startAngle" : compareElement.startAngle,
                               "endAngle"   : compareElement.endAngle };

            for ( var key in otherAttrs )
                [self assert:otherAttrs[key]
                      equals:withElement[key]
                     message:msg+" "+key];
            break;

        default:
            [self assert:false
                  equals:true
                 message:msg + "UNKNOWN Type: " + compareElement.type];
            break;
        }
    }
}

@end
