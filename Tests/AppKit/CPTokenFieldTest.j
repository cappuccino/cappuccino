@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

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

- (void)testCreate
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable],
        tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(10, 10, 100, 28)];

    // This shouldn't crash.
    [[aWindow contentView] addSubview:tokenField];
}

@end
