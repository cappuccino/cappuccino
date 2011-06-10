@import <Foundation/Foundation.j>

@implementation CPNumberFormatterTest : OJTestCase
{
}

- (void)testDecimalStyle
{
    var numberFormatter = [[CPNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    var formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithInt:123]];
    [self assert:@"123" equals:formattedNumberString];

    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:122344.4563]];
    // TODO Locale support. This test is sensitive to float precision.
    [self assert:@"122,344.456" equals:formattedNumberString];
}

@end
