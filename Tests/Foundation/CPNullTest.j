@import <Foundation/CPNull.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@implementation CPNullTest : OJTestCase

- (void)testEquals
{
    [self assert:[CPNull null] equals:[CPNull null] message:"CPNull null should equal itself."];
    [self assert:[CPNull null] equals:[CPNull new] message:"CPNull null should equal another CPNull."];
}

- (void)testArchiving
{
    [self assert:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:[CPNull null]]] equals:[CPNull null]];
}

@end