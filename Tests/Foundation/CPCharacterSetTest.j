@import <Foundation/CPCharacterSet.j>

@implementation CPCharacterSetTest : OJTestCase

- (void)testEquals
{
    var charSetA = [CPCharacterSet characterSetWithCharactersInString:"abc"],
        charSetB = [CPCharacterSet characterSetWithCharactersInString:"abc"],
        charSetC = [CPCharacterSet characterSetWithCharactersInString:""];

    [self assertFalse:[charSetA isEqual:[CPNull null]]];
    [self assertFalse:[charSetA isEqual:charSetC]];
    [self assertTrue:[charSetA isEqual:charSetA]];
    [self assertTrue:[charSetA isEqual:charSetB]];
}

- (void)testArchiving
{
    var charSet = [CPCharacterSet characterSetWithCharactersInString:"abc"],
        archived = [CPKeyedArchiver archivedDataWithRootObject:charSet],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assertTrue:[unarchived characterIsMember:'a']];
    [self assertTrue:[unarchived characterIsMember:'b']];
    [self assertTrue:[unarchived characterIsMember:'c']];
    [self assertFalse:[unarchived characterIsMember:'d']];

    var invertedSet = [charSet invertedSet];

    archived = [CPKeyedArchiver archivedDataWithRootObject:invertedSet];
    unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assertFalse:[unarchived characterIsMember:'a'] message:"in unarchived inverted set 'a' is not a member"];
    [self assertFalse:[unarchived characterIsMember:'b'] message:"in unarchived inverted set 'b' is not a member"];
    [self assertFalse:[unarchived characterIsMember:'c'] message:"in unarchived inverted set 'c' is not a member"];
    [self assertTrue:[unarchived characterIsMember:'d'] message:"in unarchived inverted set 'd' is a member"];
}

@end