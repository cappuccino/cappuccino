@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

@implementation CPFontManagerTest : OJTestCase
{
    CPFont fontA;
    CPFont fontB;
    CPFont convertedFontA;
    CPFont convertedFontB;

    int tag @accessors;
}

- (void)setUp
{
    fontA = [CPFont systemFontOfSize:8.0];
}

- (void)testAvailableFonts
{
    var fonts = [[CPFontManager sharedFontManager] availableFonts];

    [self assertTrue:[fonts isKindOfClass:[CPArray class]] message:@"font list returned by availableFonts"];
}

- (void)testSetSelectedFont_isMultiple_
{
    var fontManager = [CPFontManager sharedFontManager];

    [fontManager setSelectedFont:fontA isMultiple:NO];
    [self assert:[fontManager selectedFont] equals:fontA];
    [self assertFalse:[fontManager isMultiple]];

    [fontManager setSelectedFont:fontA isMultiple:YES];
    [self assert:[fontManager selectedFont] equals:fontA];
    [self assertTrue:[fontManager isMultiple]];
}

- (void)testAddFontTrait_
{
    var fontManager = [CPFontManager sharedFontManager];

    [fontManager setSelectedFont:fontA isMultiple:NO];
    [fontManager setTarget:self];

    fontB = [CPFont boldFontWithName:@"Helvetica" size:12.0 italic:YES];
    // Do nothing conversion.
    [fontManager addFontTrait:self];

    [self assert:fontA equals:convertedFontA message:@"fontA changed"];
    [self assert:fontB equals:convertedFontB message:@"fontB changed"];

    // Add bold
    tag = CPBoldFontMask;
    [fontManager addFontTrait:self];

    [self assertTrue:[convertedFontA isBold] message:@"add bold to fontA"];
    [self assertFalse:[convertedFontA isItalic] message:@"maintain no italics fontA"];
    [self assert:8.0 equals:[convertedFontA size]];

    [self assertTrue:[convertedFontB isBold]];
    [self assertTrue:[convertedFontB isItalic]];
    [self assert:12.0 equals:[convertedFontB size]];

    // Remove bold, add italic
    tag = CPUnboldFontMask || CPItalicFontMask;
    [fontManager addFontTrait:self];

    [self assertFalse:[convertedFontA isBold] message:@"maintain no bold fontA with CPUnboldFontMask || CPItalicFontMask"];
    [self assertFalse:[convertedFontA isItalic] message:@"add italics fontA with CPUnboldFontMask || CPItalicFontMask"];
    [self assert:8.0 equals:[convertedFontA size] message:@"maintain size fontA with CPUnboldFontMask || CPItalicFontMask"];

    [self assertFalse:[convertedFontB isBold] message:@"remove bold fontB with CPUnboldFontMask || CPItalicFontMask"];
    [self assertTrue:[convertedFontB isItalic] message:@"maintain italics fontB with CPUnboldFontMask || CPItalicFontMask"];
    [self assert:12.0 equals:[convertedFontB size] message:@"maintain size fontB with CPUnboldFontMask || CPItalicFontMask"];

    // Remove italic
    tag = CPUnitalicFontMask;
    [fontManager addFontTrait:self];

    [self assertFalse:[convertedFontA isBold] message:@"maintain no bold fontA with CPUnitalicFontMask"];
    [self assertFalse:[convertedFontA isItalic] message:@"maintain no italics fontA with CPUnitalicFontMask"];
    [self assert:8.0 equals:[convertedFontA size] message:@"maintain size fontA with CPUnitalicFontMask"];

    [self assertTrue:[convertedFontB isBold] message:@"maintain bold fontB with CPUnitalicFontMask"];
    [self assertFalse:[convertedFontB isItalic] message:@"remove italics from fontB with CPUnitalicFontMask"];
    [self assert:12.0 equals:[convertedFontB size] message:@"maintain size fontB with CPUnitalicFontMask"];
}

- (@action)changeFont:(id)sender
{
    convertedFontA = [sender convertFont:fontA];
    convertedFontB = [sender convertFont:fontB];
}

@end
