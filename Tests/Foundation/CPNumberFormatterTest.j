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

- (void)testRoundingMode
{
    var numberFormatter = [[CPNumberFormatter alloc] init],
        formattedNumberString;
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];

    [numberFormatter setRoundingMode:CPNumberFormatterRoundUp];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5672]];
    [self assert:@"123.568" equals:formattedNumberString];

    [numberFormatter setRoundingMode:CPNumberFormatterRoundDown];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5679]];
    [self assert:@"123.567" equals:formattedNumberString];

    [numberFormatter setRoundingMode:CPNumberFormatterRoundHalfEven];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5675]];
    [self assert:@"123.568" equals:formattedNumberString];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5665]];
    [self assert:@"123.566" equals:formattedNumberString];

    [numberFormatter setRoundingMode:CPNumberFormatterRoundHalfDown];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5675]];
    [self assert:@"123.567" equals:formattedNumberString];

    [numberFormatter setRoundingMode:CPNumberFormatterRoundHalfUp];
    formattedNumberString = [numberFormatter stringFromNumber:[CPNumber numberWithFloat:123.5675]];
    [self assert:@"123.568" equals:formattedNumberString];
}

@end
