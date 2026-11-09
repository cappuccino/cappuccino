/*
 *  CPAssetCatalogTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-09.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPAppearance.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPImage.j>
@import <AppKit/_CPAssetCatalog.j>

var CPAssetCatalogTestDark = [{ appearance: "luminosity", value: "dark" }],
    CPAssetCatalogTestHighContrast = [{ appearance: "contrast", value: "high" }];

function CPAssetCatalogTestSRGB(red, green, blue, alpha)
{
    return { "color-space": "srgb", components: { red: red, green: green, blue: blue, alpha: alpha } };
}

/*
    A compiled asset catalog table, as the build writes it.
*/
function CPAssetCatalogTestContents()
{
    return {
        version: 1,
        colors: {
            "Background": [
                { idiom: "universal", color: CPAssetCatalogTestSRGB("1.000", "1.000", "1.000", "1.000") },
                { idiom: "universal", appearances: CPAssetCatalogTestDark, color: CPAssetCatalogTestSRGB("0.000", "0.000", "0.000", "1.000") },
                { idiom: "universal", appearances: CPAssetCatalogTestHighContrast, color: CPAssetCatalogTestSRGB("0.500", "0.500", "0.500", "1.000") }
            ],
            "FloatingPoint": [{ idiom: "universal", color: CPAssetCatalogTestSRGB("0.502", "0.000", "0.000", "0.500") }],
            "EightBit": [{ idiom: "universal", color: CPAssetCatalogTestSRGB("128", "0", "255", "1.000") }],
            "Hexadecimal": [{ idiom: "universal", color: CPAssetCatalogTestSRGB("0x80", "0x00", "0xFF", "1.000") }],
            "Gray": [{ idiom: "universal", color: { "color-space": "gray-gamma-22", components: { white: "0.500", alpha: "1.000" } } }],
            "LinearGray": [{ idiom: "universal", color: { "color-space": "extended-linear-srgb", components: { red: "0.214041", green: "0.214041", blue: "0.214041", alpha: "1.000" } } }],
            "DisplayP3Gray": [{ idiom: "universal", color: { "color-space": "display-p3", components: { red: "0.500", green: "0.500", blue: "0.500", alpha: "1.000" } } }],
            "DisplayP3Green": [{ idiom: "universal", color: { "color-space": "display-p3", components: { red: "0.000", green: "0.500", blue: "0.000", alpha: "1.000" } } }],
            "Accent": [{ idiom: "universal", color: { platform: "osx", reference: "systemBlueColor" } }],
            "MacIdiom": [
                { idiom: "universal", color: CPAssetCatalogTestSRGB("1.000", "0.000", "0.000", "1.000") },
                { idiom: "mac", color: CPAssetCatalogTestSRGB("0.000", "1.000", "0.000", "1.000") }
            ]
        },
        images: {
            "Logo": {
                properties: { "template-rendering-intent": "template" },
                images: [
                    { idiom: "universal", filename: "Assets.xcassets/Logo.imageset/logo.png", scale: "1x" },
                    { idiom: "universal", filename: "Assets.xcassets/Logo.imageset/logo@2x.png", scale: "2x" },
                    { idiom: "universal", scale: "3x" },
                    { idiom: "universal", appearances: CPAssetCatalogTestDark, filename: "Assets.xcassets/Logo.imageset/logo-dark.png", scale: "1x" }
                ]
            },
            "CPAddTemplate": {
                images: [{ idiom: "universal", filename: "Assets.xcassets/Add.imageset/add.png" }]
            },
            "CPAssetCatalogTestRegistered": {
                images: [{ idiom: "universal", filename: "Assets.xcassets/Registered.imageset/registered.png" }]
            }
        }
    };
}

@implementation CPAssetCatalogTest : OJTestCase

/*
    Each test gives the main bundle a fresh catalog, so that no test sees values that another
    test resolved.
*/
- (void)setUp
{
    var mainBundle = [CPBundle mainBundle];

    [_CPAssetCatalog _setCatalog:[[_CPAssetCatalog alloc] _initWithContents:CPAssetCatalogTestContents() bundle:mainBundle] forBundle:mainBundle];
}

- (void)tearDown
{
    [_CPAssetCatalog _setCatalog:nil forBundle:[CPBundle mainBundle]];
    [CPAppearance setCurrentAppearance:nil];
}

- (void)setDrawingAppearanceNamed:(CPString)aName
{
    [CPAppearance setCurrentAppearance:[CPAppearance appearanceNamed:aName]];
}

- (void)assertColor:(CPColor)aColor red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha message:(CPString)aMessage
{
    var actual = [[aColor redComponent], [aColor greenComponent], [aColor blueComponent], [aColor alphaComponent]],
        expected = [red, green, blue, alpha];

    for (var i = 0; i < 4; i++)
        [self assertTrue:Math.abs(actual[i] - expected[i]) < 0.001 message:aMessage + ": expected " + expected + " but was " + actual];
}

// MARK: Colours

- (void)testColorNamedGivesTheSharedAssetColor
{
    var color = [CPColor colorNamed:@"Background"];

    [self assertNotNull:color];
    [self assert:color same:[CPColor colorNamed:@"Background"]];
    [self assert:color same:[CPColor colorNamed:@"Background" bundle:[CPBundle mainBundle]]];
}

- (void)testAnUnknownColorNameGivesNil
{
    [self assertNull:[CPColor colorNamed:@"NoSuchColor"]];
}

- (void)testABundleWithoutCatalogGivesNoColor
{
    [self assertNull:[CPColor colorNamed:@"Background" bundle:[CPBundle bundleWithPath:@"CPAssetCatalogTestMissing.bundle"]]];
}

- (void)testAnAssetColorTakesTheEntryForTheDrawingAppearance
{
    var color = [CPColor colorNamed:@"Background"];

    [self assertColor:color red:1.0 green:1.0 blue:1.0 alpha:1.0 message:@"Aqua"];

    [self setDrawingAppearanceNamed:CPAppearanceNameDarkAqua];
    [self assertColor:color red:0.0 green:0.0 blue:0.0 alpha:1.0 message:@"DarkAqua"];
}

- (void)testVibrantAppearancesTakeTheLuminosityOfTheirLightness
{
    var color = [CPColor colorNamed:@"Background"];

    [self setDrawingAppearanceNamed:CPAppearanceNameVibrantDark];
    [self assertColor:color red:0.0 green:0.0 blue:0.0 alpha:1.0 message:@"VibrantDark"];

    [self setDrawingAppearanceNamed:CPAppearanceNameVibrantLight];
    [self assertColor:color red:1.0 green:1.0 blue:1.0 alpha:1.0 message:@"VibrantLight"];
}

/*
    High contrast looks for the same luminosity at normal contrast before any luminosity at
    high contrast.
*/
- (void)testHighContrastPrefersTheSameLuminosityBeforeAnyLuminosity
{
    var color = [CPColor colorNamed:@"Background"];

    [self setDrawingAppearanceNamed:CPAppearanceNameAccessibilityHighContrastDarkAqua];
    [self assertColor:color red:0.0 green:0.0 blue:0.0 alpha:1.0 message:@"high-contrast DarkAqua"];

    [self setDrawingAppearanceNamed:CPAppearanceNameAccessibilityHighContrastAqua];
    [self assertColor:color red:0.5 green:0.5 blue:0.5 alpha:1.0 message:@"high-contrast Aqua"];
}

- (void)testComponentsReadEveryXcodeNotation
{
    [self assertColor:[CPColor colorNamed:@"FloatingPoint"] red:0.502 green:0.0 blue:0.0 alpha:0.5 message:@"floating point"];
    [self assertColor:[CPColor colorNamed:@"EightBit"] red:128 / 255 green:0.0 blue:1.0 alpha:1.0 message:@"8-bit integer"];
    [self assertColor:[CPColor colorNamed:@"Hexadecimal"] red:128 / 255 green:0.0 blue:1.0 alpha:1.0 message:@"8-bit hexadecimal"];
}

- (void)testGrayLinearAndDisplayP3ComponentsConvertToSRGB
{
    [self assertColor:[CPColor colorNamed:@"Gray"] red:0.5039 green:0.5039 blue:0.5039 alpha:1.0 message:@"gray gamma 2.2"];
    [self assertColor:[CPColor colorNamed:@"LinearGray"] red:0.5 green:0.5 blue:0.5 alpha:1.0 message:@"linear sRGB"];
    [self assertColor:[CPColor colorNamed:@"DisplayP3Gray"] red:0.5 green:0.5 blue:0.5 alpha:1.0 message:@"Display P3 gray"];
    [self assertColor:[CPColor colorNamed:@"DisplayP3Green"] red:0.0 green:0.5096 blue:0.0 alpha:1.0 message:@"Display P3 green"];
}

- (void)testAReferenceEntryGivesTheSystemColor
{
    [self assert:[CPColor systemBlueColor] same:[[CPColor colorNamed:@"Accent"] _resolvedColor]];
}

- (void)testTheMacIdiomComesBeforeUniversal
{
    [self assertColor:[CPColor colorNamed:@"MacIdiom"] red:0.0 green:1.0 blue:0.0 alpha:1.0 message:@"mac idiom"];
}

- (void)testAnAssetColorWithAlphaStaysAnAssetColor
{
    var color = [[CPColor colorNamed:@"Background"] colorWithAlphaComponent:0.25];

    [self setDrawingAppearanceNamed:CPAppearanceNameDarkAqua];
    [self assertColor:color red:0.0 green:0.0 blue:0.0 alpha:0.25 message:@"DarkAqua with alpha"];
    [self assert:color equals:[[CPColor colorNamed:@"Background"] colorWithAlphaComponent:0.25]];
    [self assert:color notEqual:[CPColor colorNamed:@"Background"]];
}

- (void)testAnAssetColorIsArchivedByName
{
    var color = [CPColor colorNamed:@"Background"],
        withAlpha = [color colorWithAlphaComponent:0.25];

    [self assert:color same:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:color]]];
    [self assert:withAlpha equals:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:withAlpha]]];
}

// MARK: Images

- (void)testImageNamedFindsTheSharedAssetImage
{
    var image = [CPImage imageNamed:@"Logo"];

    [self assertTrue:[image isKindOfClass:[_CPAssetImage class]]];
    [self assert:@"Logo" equals:[image name]];
    [self assert:image same:[CPImage imageNamed:@"Logo"]];
}

- (void)testAnAssetComesBeforeASystemImageOfTheSameName
{
    [self assertTrue:[[CPImage imageNamed:CPImageNameAddTemplate] isKindOfClass:[_CPAssetImage class]]];
}

- (void)testARegisteredImageComesBeforeAnAsset
{
    var registered = [[CPImage alloc] initByReferencingFile:@"registered.png" size:CGSizeMake(4, 4)];

    [registered setName:@"CPAssetCatalogTestRegistered"];

    [self assert:registered same:[CPImage imageNamed:@"CPAssetCatalogTestRegistered"]];
}

- (void)testAnAssetImageTakesTheEntryForTheDrawingAppearance
{
    var image = [CPImage imageNamed:@"Logo"],
        mainBundle = [CPBundle mainBundle];

    [self assert:[mainBundle pathForResource:@"Assets.xcassets/Logo.imageset/logo.png"] equals:[[image _resolvedImage] filename]];

    [self setDrawingAppearanceNamed:CPAppearanceNameDarkAqua];
    [self assert:[mainBundle pathForResource:@"Assets.xcassets/Logo.imageset/logo-dark.png"] equals:[[image _resolvedImage] filename]];
}

- (void)testTheDisplayScaleChoosesTheImageEntry
{
    var entries = [{ scale: "1x", filename: "a" }, { scale: "2x", filename: "b" }, { scale: "3x", filename: "c" }],
        withSingleScale = [{ scale: "2x", filename: "b" }, { filename: "vector" }];

    [self assert:entries[0] same:_CPAssetEntryForDisplayScale(entries, 1)];
    [self assert:entries[1] same:_CPAssetEntryForDisplayScale(entries, 1.5)];
    [self assert:entries[1] same:_CPAssetEntryForDisplayScale(entries, 2)];
    [self assert:entries[2] same:_CPAssetEntryForDisplayScale(entries, 4)];
    [self assert:withSingleScale[1] same:_CPAssetEntryForDisplayScale(withSingleScale, 2)];
}

- (void)testAnImageOfScale2xCoversHalfItsPixelSize
{
    var image = [[_CPScaledImage alloc] _initWithContentsOfFile:@"logo@2x.png" scale:2.0];

    image._image = { width: 40, height: 20 };
    [image _imageDidLoad];

    [self assertTrue:CGSizeEqualToSize(CGSizeMake(20, 10), [image size])];
}

- (void)testTheTemplateRenderingIntentStaysInTheCatalog
{
    var catalog = [_CPAssetCatalog catalogForBundle:nil];

    [self assert:@"template" equals:[catalog _propertiesOfImageNamed:@"Logo"]["template-rendering-intent"]];
}

- (void)testAnAssetImageIsArchivedByName
{
    var image = [CPImage imageNamed:@"Logo"];

    [self assert:image same:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:image]]];
}

@end
