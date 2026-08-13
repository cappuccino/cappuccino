@import <Foundation/Foundation.j>

@implementation CopyAccessorTestClass : CPObject
{
    CPMutableArray ivar @accessors(copy);
}

@end

@implementation CopyAccessorTest : OJTestCase
{
    CopyAccessorTestClass testClass;
}

- (void)setUp
{
    testClass = [[CopyAccessorTestClass alloc] init];
}

- (void)testCopyAccessorStoresDistinctObject
{
    var original = [@"a", @"b"];

    [testClass setIvar:original];

    [self assertFalse:[testClass ivar] === original];
}

- (void)testCopyAccessorIsUnaffectedByLaterMutation
{
    var original = [@"a", @"b"];

    [testClass setIvar:original];
    [original addObject:@"c"];

    [self assert:2 equals:[[testClass ivar] count]];
}

- (void)testCopyAccessorPreservesContentAtAssignment
{
    var original = [@"a", @"b"];

    [testClass setIvar:original];

    [self assert:original equals:[testClass ivar]];
}

@end
