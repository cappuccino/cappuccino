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

-(void)testCPPointEqualToPoint
{
	[self assertTrue:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(10, 10))];
	[self assertFalse:CPPointEqualToPoint(CGPointMake(0, 10), CGPointMake(10, 10))];
	[self assertFalse:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(0, 10))];
	[self assertFalse:CPPointEqualToPoint(CGPointMake(10, 0), CGPointMake(10, 10))];
	[self assertFalse:CPPointEqualToPoint(CGPointMake(10, 10), CGPointMake(10, 0))];
}

-(void)testCPRectEqualToRect
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

-(void)textCPRectIsEmpty
{
	[self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 0, 10))];
	[self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 10, 0))];
	[self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, -10, 10))];
	[self assertTrue:CPRectIsEmpty(CGRectMake(0, 0, 10, -10))];
	[self assertFalse:CPRectIsEmpty(CGRectMake(0, 0, 10, 10))];
}

-(void)testCPRectIntersection
{
	var lhsRect = CGRectMake(0, 0, 20, 20),
		rhsRect = CGRectMake(10, 10, 20, 20),
		intersectionResultRect = CGRectMake(10, 10, 10, 10);

	[self assertTrue:CPRectEqualToRect(CPRectIntersection(lhsRect, rhsRect), intersectionResultRect)];
	intersectionResultRect.origin.x = 30;
	intersectionResultRect.origin.y = 30;
	[self assertFalse:CPRectEqualToRect(CPRectIntersection(lhsRect, rhsRect), intersectionResultRect)];
}

-(void)testCPPointCreateCopy
{
	var point = CGPointMake(1, 1);
	[self assertTrue:CPPointEqualToPoint(CPPointCreateCopy(point),point)];
	[self assertFalse:CPPointEqualToPoint(CPPointCreateCopy(point), CGPointMake(0,1))];
}

@end
