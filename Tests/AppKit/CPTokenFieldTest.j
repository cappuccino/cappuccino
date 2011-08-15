@import <AppKit/CPTokenField.j>

@implementation CPTokenFieldTest : OJTestCase
{
}

- (void)testArchiving
{
    var tokenField = [CPTokenField new];
    [tokenField setCompletionDelay:5.0];
    [tokenField setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString:@","]];

    var archived = [CPKeyedArchiver archivedDataWithRootObject:tokenField],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assert:[unarchived completionDelay] equals:5.0];
    [self assert:[unarchived tokenizingCharacterSet] equals:[CPCharacterSet characterSetWithCharactersInString:@","]];
}

@end