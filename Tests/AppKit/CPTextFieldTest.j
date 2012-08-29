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

- (void)testFormatters
{
    var control = [[CPTextField alloc] initWithFrame:CGRectMakeZero()],
        numberFormatter = [[CPNumberFormatter alloc] init];

    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:3];

    [control setFormatter:numberFormatter];
    [control setStringValue:@"12.3456"];
    [self assertTrue:[[control objectValue] isKindOfClass:CPNumber] message:@"object should be a number"];
    // Note that the control stores the value with a different precision than the maximum fraction
    // digits of the number formatter. It's a little surprising but this makes the implementation easier
    // and Cocoa does it too.
    [self assert:[CPNumber numberWithFloat:12.3456] equals:[control objectValue]];
    [self assert:"12.346" equals:[control stringValue]];

    [control setFloatValue:45.3456];
    [self assertTrue:"45.346" === [control stringValue]];

    [control setFormatter:nil];
    [control setStringValue:@"12"];
    [self assert:@"12" equals:[control objectValue]];
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
