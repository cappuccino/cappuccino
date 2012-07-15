@import <AppKit/AppKit.j>

@implementation CPFontManagerTest : OJTestCase
{
}

- (void)testAvailableFonts
{
    var fonts = [[CPFontManager sharedFontManager] availableFonts];

    [self assertTrue:[fonts isKindOfClass:[CPArray class]] message:@"font list returned by availableFonts"];
}

@end
