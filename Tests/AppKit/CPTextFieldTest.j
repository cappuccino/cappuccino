@import <AppKit/CPTextField.j>

[CPApplication sharedApplication]

@implementation CPTextFieldTest : OJTestCase
{
}

/*!
    Detect regressions with JS object theme attribute encoding in subclasses.

    This test is not actually CPTextField specific at all. This just happens
    to be the first place the keyed archiving bug was discovered, and there is
    an additional, more specific, test in CPKeyedArchiverTest.
*/
- (void)testArchiveThemeAttributes
{
    var view = [[CPTextFieldSubclass alloc] initWithFrame:CGRectMakeZero()],
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]];

    [self assert:[view valueForThemeAttribute:@"content-inset"].top equals:2 message:@"content-inset should initialise correctly"];
    [self assert:[view valueForThemeAttribute:@"content-inset"].top equals:[decoded valueForThemeAttribute:@"content-inset"].top message:@"content-inset should unarchive correctly"];
}

@end

@implementation CPTextFieldSubclass : CPTextField
{

}

- (id)initWithFrame:aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CGInsetMake(2.0, 2.0, 2.0, 2.0) forThemeAttribute:"content-inset"];
    }
    return self;
}

@end