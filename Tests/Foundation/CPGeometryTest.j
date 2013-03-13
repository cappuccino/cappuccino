@import <Foundation/CPGeometry.j>

@implementation CPGeometryTest : OJTestCase
{
}

- (void)testCPRectContainsRect
{
    [self assertTrue:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(0, 0, 50, 50))];
    [self assertTrue:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(50, 50, 50, 50))];
    [self assertTrue:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(450, 450, 50, 50))];
    [self assertTrue:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(500, 500, 0, 0))];
    [self assertFalse:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(50, 50, 500, 500))];
    [self assertFalse:CPRectContainsRect(CGRectMake(0, 0, 500, 500), CGRectMake(500, 500, 1, 1))];
}

- (void)testCPPointEqualToPoint
{
    [self assertTrue:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(10, 10))];
    [self assertFalse:CPPointEqualToPoint(CGPointMake(0, 10), CGPointMake(10, 10))];
    [self assertFalse:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(0, 10))];
    [self assertFalse:CPPointEqualToPoint(CGPointMake(10, 0), CGPointMake(10, 10))];
    [self assertFalse:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(10, 0))];
}

- (void)testCPRectEqualToRect
{
    [self assertTrue:CPRectEqualToRect(CGRectMake(0, 0, 100, 100), CGRectMake(0, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(50, 0, 100, 100), CGRectMake(0, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 100, 100), CGRectMake(50, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 50, 100, 100), CGRectMake(0, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 100, 100), CGRectMake(0, 50, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 50, 100), CGRectMake(0, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 100, 100), CGRectMake(0, 0, 50, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 100, 50), CGRectMake(0, 0, 100, 100))];
    [self assertFalse:CPRectEqualToRect(CGRectMake(0, 0, 100, 100), CGRectMake(0, 0, 100, 50))];
}

- (void)textCPRectIsEmpty
{
    [self assertTrue:CPRectIsEmpty(CGRectMake(Infinity, 0, 10, 10))];
    [self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 0, 10))];
    [self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 10, 0))];
    [self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, -10, 10))];
    [self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 10, -10))];
    [self assertFalse:CPRectIsEmpty(CGRectMake(0, 0, 10, 10))];
}

- (void)testCPRectIntersection
{
    var lhsRect = CGRectMake(0, 0, 20, 20),
        rhsRect = CGRectMake(10, 10, 20, 20),
        intersectionResultRect = CGRectMake(10, 10, 10, 10);

    [self assertTrue:CPRectEqualToRect(CPRectIntersection(lhsRect, rhsRect), intersectionResultRect)];
    intersectionResultRect.origin.x = 30;
    intersectionResultRect.origin.y = 30;
    [self assertFalse:CPRectEqualToRect(CPRectIntersection(lhsRect, rhsRect), intersectionResultRect)];
}

- (void)testCPPointCreateCopy
{
    var point = CGPointMake(1, 1),
        copiedPoint = CPPointCreateCopy(point);
    [self assertTrue:CPPointEqualToPoint(point, copiedPoint)];
    point.x = 10;
    [self assertFalse:CPPointEqualToPoint(point, copiedPoint)];
}

- (void)testCPPointMake
{
    var testPoint = CPPointMake(1, 2);
    [self assert:1 equals:testPoint.x message:"point x coordinate failed"];
    [self assert:2 equals:testPoint.y message:"point y coordinate failed"];
}

- (void)testCPRectInset
{
    var testRect = CGRectMake(0, 0, 100, 100);
    [self assertTrue:CGRectEqualToRect(CGRectMake(10, 10, 80, 80), CPRectInset(testRect, 10, 10))];
}

- (void)testCPRectIntegral
{
    var rect = CGRectMake(0.1, 0.2, 10.3, 10.4);
    [self assertTrue:CGRectEqualToRect(CGRectMake(0, 0, 11, 11), CPRectIntegral(rect))];
}

- (void)testCPRectCreateCopy
{
    var rect = CGRectMake(0, 0, 100, 100),
        copiedRect = CPRectCreateCopy(rect);
    [self assertTrue:CGRectEqualToRect(rect, copiedRect)];
    rect.origin.x = 10;
    [self assertFalse:CGRectEqualToRect(rect, copiedRect)];
}

- (void)testCPRectMake
{
    var rect = CPRectMake(10, 20, 30, 40);
    [self assert:10 equals:rect.origin.x message:"Rect x coordinate failed"];
    [self assert:20 equals:rect.origin.y message:"Rect x coordinate failed"];
    [self assert:30 equals:rect.size.width message:"Rect width failed"];
    [self assert:40 equals:rect.size.height message:"Rect height failed"];
}

- (void)testCPRectOffset
{
    var initialRect = CGRectMake(10, 10, 100, 100),
        offsetRect = CGRectMake(20, 20, 100, 100);
    [self assertTrue:CGRectEqualToRect(offsetRect, CPRectOffset(initialRect, 10, 10))];
    [self assertFalse:CGRectEqualToRect(initialRect, CPRectOffset(initialRect, 10, 10))];
}

- (void)testCPRectStandardize
{
    var initialRect = CGRectMake(10, 10, -10, -10),
        standardizedRect = CGRectMake(0, 0, 10, 10);
    [self assertTrue:CGRectEqualToRect(standardizedRect,CPRectStandardize(initialRect))];
    [self assertFalse:CGRectEqualToRect(initialRect,CPRectStandardize(initialRect))];
}

- (void)testCPRectUnion
{
    var firstRect = CGRectMake(0, 0, 10, 10),
        secondRect = CGRectMake(20, 20, 10, 10),
        unitedRect = CGRectMake(0, 0, 30, 30);
    [self assertTrue:CGRectEqualToRect(unitedRect, CPRectUnion(firstRect, secondRect))];
    [self assertFalse:CGRectEqualToRect(firstRect, CPRectUnion(firstRect, secondRect))];
}

- (void)testCPSizeCreateCopy
{
    var initialSize = CGSizeMake(100, 200),
        copiedSize = CPSizeCreateCopy(initialSize);
    [self assertTrue:CGSizeEqualToSize(initialSize, copiedSize)];
    initialSize.width = 10;
    [self assertFalse:CGSizeEqualToSize(initialSize, copiedSize)];
}

- (void)testCPSizeMake
{
    var size = CPSizeMake(10, 20);
    [self assert:10 equals:size.width message:"Size width failed"];
    [self assert:20 equals:size.height message:"Size height failed"];
}

- (void)testCPRectContainsPoint
{
    var rect = CGRectMake(10, 10, 10, 10);
    [self assertTrue:CPRectContainsPoint(rect, CGPointMake(15, 15))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(5, 5))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(15, 5))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(25, 5))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(5, 15))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(5, 25))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(15, 25))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(25, 15))];
    [self assertFalse:CPRectContainsPoint(rect, CGPointMake(25, 25))];
}

- (void)testCPRectGetHeight
{
    var rect = CGRectMake(10, 20, 30, 40);
    [self assert:40 equals:CPRectGetHeight(rect)];
}

- (void)testCPRectGetMaxX
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:50 equals:CPRectGetMaxX(rect)];
}

- (void)testCPRectGetMaxY
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:100 equals:CPRectGetMaxY(rect)];
}

- (void)testCPRectGetMidX
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:30 equals:CPRectGetMidX(rect)];
}

- (void)testCPRectGetMidY
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:60 equals:CPRectGetMidY(rect)];
}

- (void)testCPRectGetMinX
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:10 equals:CPRectGetMinX(rect)];
}

- (void)testCPRectGetMinY
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:20 equals:CPRectGetMinY(rect)];
}

- (void)testCPRectGetWidth
{
    var rect = CGRectMake(10, 20, 40, 80);
    [self assert:40 equals:CPRectGetWidth(rect)];
}

- (void)testCPRectIntersectsRect
{
    var firstRect = CGRectMake(10, 10, 10, 10),
        secondRect = CGRectMake(15, 15, 10, 10);
    [self assertTrue:CPRectIntersectsRect(firstRect, secondRect)];
    secondRect.origin = CGPointMake(25, 25);
    [self assertFalse:CPRectIntersectsRect(firstRect, secondRect)];
}

- (void)testCPRectIsNull
{
    [self assertFalse:CPRectIsNull(CGRectMake(0, 0, 0, 10))];
    [self assertTrue:CPRectIsNull(CGRectMake(Infinity, 0, 0, 0))];
    [self assertTrue:CPRectIsNull(CGRectMake(0, Infinity, -10, 10))];
    [self assertFalse:CPRectIsNull(CGRectMake(0, 0, 10, -10))];
    [self assertFalse:CPRectIsNull(CGRectMake(0, 0, 10, 10))];
}

- (void)testCPDivideRect
{
    var initialRect = CGRectMake(0, 0, 10, 10),
        slice = CGRectMake(0, 0, 0, 0),
        rem = CGRectMake(0, 0, 0, 0);

    CPDivideRect(initialRect, slice, rem, 3, CGMinXEdge);
    [self assertTrue:CGRectEqualToRect(slice, CGRectMake(0, 0, 3, 10))];
    [self assertTrue:CGRectEqualToRect(rem, CGRectMake(3, 0, 7, 10))];

    CPDivideRect(initialRect, slice, rem, 3, CGMinYEdge);
    [self assertTrue:CGRectEqualToRect(slice, CGRectMake(0, 0, 10, 3))];
    [self assertTrue:CGRectEqualToRect(rem, CGRectMake(0, 3, 10, 7))];

    CPDivideRect(initialRect, slice, rem, 3, CGMaxXEdge);
    [self assertTrue:CGRectEqualToRect(slice, CGRectMake(7, 0, 3, 10))];
    [self assertTrue:CGRectEqualToRect(rem, CGRectMake(0, 0, 7, 10))];

    CPDivideRect(initialRect, slice, rem, 3, CGMaxYEdge);
    [self assertTrue:CGRectEqualToRect(slice, CGRectMake(0, 7, 10, 3))];
    [self assertTrue:CGRectEqualToRect(rem, CGRectMake(0, 0, 10, 7))];
}

- (void)testCPSizeEqualToSize
{
    [self assertTrue:CPSizeEqualToSize(CGSizeMake(10, 10), CGSizeMake(10, 10))];
    [self assertFalse:CPSizeEqualToSize(CGSizeMake(0, 10), CGSizeMake(10, 10))];
    [self assertFalse:CPSizeEqualToSize(CGSizeMake(10, 10), CGSizeMake(0, 10))];
    [self assertFalse:CPSizeEqualToSize(CGSizeMake(10, 0), CGSizeMake(10, 10))];
    [self assertFalse:CPSizeEqualToSize(CGSizeMake(10, 10), CGSizeMake(10, 0))];
}

- (void)testCPStringFromPoint
{
    var point = CGPointMake(0, 1);
    [self assert:"{0, 1}" equals: CPStringFromPoint(point)];
}

- (void)testCPStringFromSize
{
    var size = CGSizeMake(10, 20);
    [self assert:"{10, 20}" equals: CPStringFromSize(size)];
}

- (void)testCPStringFromRect
{
    var rect = CGRectMake(10, 20, 30, 40);
    [self assert:"{{10, 20}, {30, 40}}" equals:CPStringFromRect(rect)];
}

- (void)testCPPointFromString
{
    var point = CGPointMake(0,1);
    [self assertTrue:CGPointEqualToPoint(point , CPPointFromString("{0, 1}"))];
}

- (void)testCPSizeFromString
{
    var size = CGSizeMake(10, 20);
    [self assertTrue:CGSizeEqualToSize(size, CPSizeFromString("{10, 20}"))];
}

- (void)testCPRectFromString
{
    var rect = CGRectMake(10, 20, 30, 40);
    [self assertTrue:CGRectEqualToRect(rect, CPRectFromString("{{10, 20}, {30, 40}}"))];
}

- (void)testCPSizeMakeZero
{
    var size = CGSizeMake(10, 20);
    [self assertTrue:CGSizeEqualToSize(CGSizeMake(0, 0), CPSizeMakeZero(size))];
}

- (void)testCPRectMakeZero
{
    var rect = CGRectMake(10, 20, 30, 40);
    [self assertTrue:CGRectEqualToRect(CGRectMake(0, 0, 0, 0), CPRectMakeZero(rect))];
}

- (void)testCPPointMakeZero
{
    var point = CGPointMake(10, 20);
    [self assertTrue:CGPointEqualToPoint(CGPointMake(0, 0), CPPointMakeZero(0, 0))];
}

- (void)testCPPointFromEvent
{
    var anEvent = [CPEvent mouseEventWithType:CPLeftMouseDownMask location:CGPointMake(5.0, 5.0) modifierFlags:0
        timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:1];
    anEvent.clientX = 1.0;
    anEvent.clientY = 2.0;
    var point = CPPointFromEvent(anEvent);
    [self assert:1.0 equals:point.x message:"Point x coordinate failed"];
    [self assert:2.0 equals:point.y message:"Point y coordinate failed"];
}

@end
