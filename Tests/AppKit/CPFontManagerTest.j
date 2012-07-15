@import <AppKit/AppKit.j>

@implementation CPFontManagerTest : OJTestCase
{
}

- (void)testAvailableFonts
{
    var fonts = [[CPFontManager sharedFontManager] availableFonts];

    [self assertTrue:[fonts isKindOfClass:[CPArray class]] message:@"font list returned by availableFonts"];
}

- (void)testSetSelectedFont_isMultiple_
{
    var fontManager = [CPFontManager sharedFontManager],
        fontA = [CPFont systemFontOfSize:5.0];

    [fontManager setSelectedFont:fontA isMultiple:NO];
    [self assert:[fontManager selectedFont] equals:fontA];
    [self assertFalse:[fontManager isMultiple]];

    [fontManager setSelectedFont:fontA isMultiple:YES];
    [self assert:[fontManager selectedFont] equals:fontA];
    [self assertTrue:[fontManager isMultiple]];
}

@end
