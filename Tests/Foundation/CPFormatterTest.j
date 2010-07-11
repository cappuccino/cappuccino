@import <Foundation/CPFormatter.j>

@implementation CPFormatterTest : OJTestCase

- (void)testThatCPFormatterIsConstructed 
{
    [self assertNotNull:[[CPFormatter alloc] init]];
}

- (void)testStringForObjectValue
{
    var formatter = [[CPFormatter alloc] init];

    [self assertThrows:function(){ [formatter stringForObjectValue:@"Hello World"]; }];
}

- (void)testEditingStringForObjectValue
{
    var formatter = [[CPFormatter alloc] init];

    [self assertThrows:function(){ [formatter editingStringForObjectValue:@"Hello Wolrd"]; }];
}

- (void)testGetObjectValueForString
{
    var formatter = [[CPFormatter alloc] init];

    [self assertThrows:function(){ [formatter getObjectValue:@"Hello World" forString:@"Hello World" errorDescription:nil]; }];
}

- (void)testIsPartialStringValidNewEditingString
{
    var formatter = [[CPFormatter alloc] init];

    [self assertThrows:function(){ [formatter isPartialStringValid:@"Hello Wolrd" newEditingString:@"Hello World" errorDescription:nil]; }];
}

- (void)testIsPartialStringValueProposedSelectedRange
{
    var formatter = [[CPFormatter alloc] init];

    [self assertThrows:function(){ [formatter isPartialStringValue:@"Hello Wolrd" proposedSelectedRange:CPRangeMake(3,5) originalString:@"Hello World" originalSelectedRange:nil errorDescription:nil]; }];
}
@end