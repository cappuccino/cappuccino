@import <AppKit/CGGeometry.j>


@implementation CGGeometryTest : OJTestCase

- (void)testCGStringFromPoint
{
    [self assert:@"{0, 0}" equals:CGStringFromPoint(CGPointMakeZero())];
    [self assert:@"{123, 234}" equals:CGStringFromPoint(CGPointMake(123, 234))];
    [self assert:@"{-123.45, -234}" equals:CGStringFromPoint(CGPointMake(-123.45, -234.))];
}

- (void)testCGStringFromSize
{
    [self assert:@"{0, 0}" equals:CGStringFromSize(CGSizeMakeZero())];
    [self assert:@"{123, 234}" equals:CGStringFromSize(CGSizeMake(123, 234))];
    [self assert:@"{-123.45, -234}" equals:CGStringFromSize(CGSizeMake(-123.45, -234.))];
}

- (void)testCGStringFromRect
{
    [self assert:@"{{0, 0}, {0, 0}}" equals:CGStringFromRect(CGRectMakeZero())];
    [self assert:@"{{123, 234}, {345, 456}}" equals:CGStringFromRect(CGRectMake(123, 234, 345, 456))];
    [self assert:@"{{-123.45, -234}, {345.5, 456}}" equals:CGStringFromRect(CGRectMake(-123.45, -234, 345.5, 456.))];
}

- (void)testCGRectFromString
{
    [self assertTrue:CGRectEqualToRect(CGRectMakeZero(), CGRectFromString(@"{{0, 0}, {0, 0}}"))];
    [self assertTrue:CGRectEqualToRect(CGRectMake(123, 234, 345, 456), CGRectFromString(@"{{123, 234}, {345, 456}}"))];
    [self assertTrue:CGRectEqualToRect(CGRectMake(-123.45, -234, 345.5, 456), CGRectFromString(@"{{-123.45, -234}, {345.5, 456}}"))];
}

@end
