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

- (void)testSetGroupingSeparator_
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];

    [self assert:@"1" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1]]];
    [self assert:@"12" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:12]]];
    [self assert:@"123" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:123]]];
    [self assert:@"1,234" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1234]]];
    [self assert:@"12,345" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:12345]]];
    [self assert:@"123,456" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:123456]]];
    [self assert:@"1,234,567" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1234567]]];

    [numberFormatter setGroupingSeparator:@" "];
    [self assert:@"1" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1]]];
    [self assert:@"12" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:12]]];
    [self assert:@"123" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:123]]];
    [self assert:@"1 234" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1234]]];
    [self assert:@"12 345" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:12345]]];
    [self assert:@"123 456" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:123456]]];
    [self assert:@"1 234 567" equals:[numberFormatter stringFromNumber:[CPNumber numberWithInt:1234567]]];
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
