@import <Foundation/CPCharacterSet.j>

@implementation CPCharacterSetTest : OJTestCase

- (void)testArchiving
{
    var charSet = [CPCharacterSet characterSetWithCharactersInString:"abc"],
        archived = [CPKeyedArchiver archivedDataWithRootObject:charSet],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assertTrue:[unarchived characterIsMember:'a']];
    [self assertTrue:[unarchived characterIsMember:'b']];
    [self assertTrue:[unarchived characterIsMember:'c']];
    [self assertFalse:[unarchived characterIsMember:'d']];
}

@end