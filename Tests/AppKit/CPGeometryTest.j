@import <AppKit/CPGeometry.j>

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

@end
