@import <Foundation/CPNull.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@implementation CPNullTest : OJTestCase

- (void)testArchiving
{
    [self assert:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:[CPNull null]]] equals:[CPNull null]];
}

@end