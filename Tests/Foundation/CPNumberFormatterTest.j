@import <Foundation/Foundation.j>

@implementation CPNumberFormatterTest : OJTestCase
{
}

- (void)testDecimalStyle
{
    var numberFormatter = [[CPNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:3];
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
    [numberFormatter setMaximumFractionDigits:3];

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

- (void)testStringFromDecimalNumber
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:1];

    [self assert:@"1" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1"]]];
    [self assert:@"0.4" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.4467"]]];
}

- (void)testSetMinimumFractionDigits_
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMinimumFractionDigits:3];
    [numberFormatter setMaximumFractionDigits:4];

    [self assert:@"1.000" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1"]]];
    [self assert:@"1.100" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1.1"]]];
    [self assert:@"0.4467" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.4467"]]];
}

- (void)testArchiving
{
    var numberFormatter = [CPNumberFormatter new],
        archived,
        unarchived;

    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMinimumFractionDigits:2];
    [numberFormatter setMaximumFractionDigits:3];
    [numberFormatter setRoundingMode:CPNumberFormatterRoundHalfDown];
    [numberFormatter setGroupingSeparator:@" "];

    archived = [CPKeyedArchiver archivedDataWithRootObject:numberFormatter],
    unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assert:CPNumberFormatterDecimalStyle equals:[unarchived numberStyle] message:@"numberStyle"];
    [self assert:2 equals:[unarchived minimumFractionDigits] message:@"minimumFractionDigits"];
    [self assert:3 equals:[unarchived maximumFractionDigits] message:@"maximumFractionDigits"];
    [self assert:CPNumberFormatterRoundHalfDown equals:[unarchived roundingMode] message:@"roundingMode"];
    [self assert:@" " equals:[unarchived groupingSeparator] message:@"groupingSeparator"];
}

- (void)testCurrencyStyle
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterCurrencyStyle];
    [numberFormatter setCurrencyCode:@"USD"];

    [self assert:@"$1.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1"]]];
    [self assert:@"$12.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12"]]];
    [self assert:@"$12.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12.1"]]];
    [self assert:@"$12.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12.10"]]];
    [self assert:@"$0.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.1"]]];
    [self assert:@"$0.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.10"]]];
    [self assert:@"$0.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.005"]]];
    [self assert:@"$0.02" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.015"]]];


    [numberFormatter setCurrencyCode:@"SEK"];
    [numberFormatter setCurrencySymbol:@""];

    [self assert:@"SEK1.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1"]]];
    [self assert:@"SEK12.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12"]]];
    [self assert:@"SEK12.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12.1"]]];
    [self assert:@"SEK12.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"12.10"]]];
    [self assert:@"SEK0.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.1"]]];
    [self assert:@"SEK0.10" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.10"]]];
    [self assert:@"SEK0.00" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.005"]]];
    [self assert:@"SEK0.02" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.015"]]];
}

- (void)testPercentStyle
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterPercentStyle];

    [self assert:@"1%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.01"]]];
    [self assert:@"100%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1.0"]]];
    [self assert:@"150%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1.5"]]];

    [numberFormatter setMinimumFractionDigits:1];
    [numberFormatter setMaximumFractionDigits:1];

    [self assert:@"1.0%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"0.01"]]];
    [self assert:@"100.2%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1.002"]]];
    [self assert:@"150.7%" equals:[numberFormatter stringFromNumber:[CPDecimalNumber decimalNumberWithString:@"1.507"]]];
}

- (void)testSetGeneratesDecimalNumbers_
{
    var numberFormatter = [CPNumberFormatter new];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];

    [self assertTrue:[numberFormatter generatesDecimalNumbers]];
    var generated = [numberFormatter numberFromString:@"1.23456"];
    [self assert:CPDecimalNumber equals:[generated class]];
    [self assert:[CPDecimalNumber decimalNumberWithString:@"1.23456"] equals:generated];

    [numberFormatter setGeneratesDecimalNumbers:NO];
    generated = [numberFormatter numberFromString:@"1.23456"];
    [self assertFalse:[generated isKindOfClass:CPDecimalNumber]];
    [self assert:1.23456 equals:generated];
}

@end
