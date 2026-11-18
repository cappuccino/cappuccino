/*
 *  CPSystemColorDarkAquaTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-18.
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

@import <AppKit/AppKit.j>

/*
    A system colour has a built-in value for Aqua and for DarkAqua, with AppKit's values. The
    built-in value applies when the default theme gives none, and it takes the supported form
    of the appearance: under a theme that supports Aqua only, a dark view gets the Aqua value.

    The names of the System catalog: the 66 public names and the private source list name.
*/
var CPSystemColorDarkAquaTestNames = [
    "_sourceListBackgroundColor",
    "alternateSelectedControlColor", "alternateSelectedControlTextColor", "alternatingContentBackgroundColor",
    "controlAccentColor", "controlBackgroundColor", "controlColor", "controlDarkShadowColor", "controlHighlightColor",
    "controlLightHighlightColor", "controlShadowColor", "controlTextColor", "disabledControlTextColor", "findHighlightColor",
    "gridColor", "headerColor", "headerTextColor", "highlightColor", "keyboardFocusIndicatorColor", "knobColor", "labelColor",
    "linkColor", "placeholderTextColor", "quaternaryLabelColor", "quaternarySystemFillColor", "quinaryLabelColor",
    "quinarySystemFillColor", "scrollBarColor", "secondaryLabelColor", "secondarySelectedControlColor",
    "secondarySystemFillColor", "selectedContentBackgroundColor", "selectedControlColor", "selectedControlTextColor",
    "selectedKnobColor", "selectedMenuItemColor", "selectedMenuItemTextColor", "selectedTextBackgroundColor",
    "selectedTextColor", "separatorColor", "shadowColor", "systemBlueColor", "systemBrownColor", "systemCyanColor",
    "systemFillColor", "systemGrayColor", "systemGreenColor", "systemIndigoColor", "systemMintColor", "systemOrangeColor",
    "systemPinkColor", "systemPurpleColor", "systemRedColor", "systemTealColor", "systemYellowColor", "tertiaryLabelColor",
    "tertiarySystemFillColor", "textBackgroundColor", "textColor", "textInsertionPointColor", "underPageBackgroundColor",
    "unemphasizedSelectedContentBackgroundColor", "unemphasizedSelectedTextBackgroundColor", "unemphasizedSelectedTextColor",
    "windowBackgroundColor", "windowFrameColor", "windowFrameTextColor"
];

@implementation CPSystemColorDarkAquaTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua] labelColors:nil]];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
}

// MARK: Helpers

/*
    Returns a theme whose attribute "supported-appearances" holds someNames, or a theme with no
    list when someNames is nil. someLabelColors maps a theme state, or nil for no state, to a
    value of labelColor; with nil the theme gives no system colour a value.
*/
- (CPTheme)themeSupporting:(CPArray)someNames labelColors:(CPArray)someLabelColors
{
    var theme = [[CPTheme alloc] initWithName:@"CPSystemColorDarkAquaTest"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    if (someNames)
        [template setValue:someNames forThemeAttribute:@"supported-appearances"];

    for (var i = 0; someLabelColors && i < someLabelColors.length; i += 2)
    {
        if (someLabelColors[i])
            [template setValue:someLabelColors[i + 1] forThemeAttribute:@"label-color" inState:someLabelColors[i]];
        else
            [template setValue:someLabelColors[i + 1] forThemeAttribute:@"label-color"];
    }

    [theme takeThemeFromObject:template];

    return theme;
}

/*
    Returns the value of the system colour aName while the appearance named anAppearanceName
    is the drawing appearance.
*/
- (CPColor)systemColor:(CPString)aName in:(CPString)anAppearanceName
{
    var color = [CPColor colorWithCatalogName:@"System" colorName:aName],
        resolvedColor = nil;

    [[CPAppearance appearanceNamed:anAppearanceName] performAsCurrentDrawingAppearance:function()
    {
        resolvedColor = [color colorUsingColorSpaceName:nil];
    }];

    return resolvedColor;
}

- (void)assertComponents:(CPArray)expected of:(CPColor)aColor
{
    var components = [aColor components];

    for (var i = 0; i < 4; i++)
        [self assert:ROUND(expected[i] * 10000) equals:ROUND(components[i] * 10000) message:[aColor description] + ", component " + i];
}

// MARK: The built-in sets

- (void)testEveryNameHasAnAquaAndADarkAquaValue
{
    var missing = [];

    CPSystemColorDarkAquaTestNames.forEach(function(aName)
    {
        [CPAppearanceNameAqua, CPAppearanceNameDarkAqua].forEach(function(anAppearanceName)
        {
            if (![self systemColor:aName in:anAppearanceName])
                missing.push(aName + " in " + anAppearanceName);
        });
    });

    [self assert:67 equals:CPSystemColorDarkAquaTestNames.length];
    [self assertTrue:missing.length === 0 message:missing.join("\n")];
}

- (void)testADarkAppearanceTakesAppKitsDarkAquaValues
{
    [self assertComponents:[1.0, 1.0, 1.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[0.1176, 0.1176, 0.1176, 1.0] of:[self systemColor:@"windowBackgroundColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[1.0, 1.0, 1.0, 0.12] of:[self systemColor:@"separatorColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[0.0, 0.5686, 1.0, 1.0] of:[self systemColor:@"systemBlueColor" in:CPAppearanceNameDarkAqua]];
}

- (void)testAnAquaAppearanceKeepsTheAquaValues
{
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameAqua]];
    [self assertComponents:[1.0, 1.0, 1.0, 1.0] of:[self systemColor:@"windowBackgroundColor" in:CPAppearanceNameAqua]];
}

/*
    A name whose AppKit value is the same in both appearances keeps its Aqua entry, Cappuccino's
    own shadowColor among them.
*/
- (void)testANameWithoutADarkValueKeepsItsAquaEntry
{
    [self assertComponents:[0.0, 0.0, 0.0, 1.0 / 3.0] of:[self systemColor:@"shadowColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[1.0, 1.0, 1.0, 1.0] of:[self systemColor:@"selectedMenuItemTextColor" in:CPAppearanceNameDarkAqua]];
}

/*
    Two dark values are Cappuccino's own: the insertion point is white, so that it shows on the
    dark text background, and the selected text background is a dark blue.
*/
- (void)testTheDarkValuesThatAreCappuccinosOwn
{
    [self assertComponents:[1.0, 1.0, 1.0, 1.0] of:[self systemColor:@"textInsertionPointColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[0.2471, 0.3882, 0.5451, 1.0] of:[self systemColor:@"selectedTextBackgroundColor" in:CPAppearanceNameDarkAqua]];
}

/*
    There is no vibrant set, and the high-contrast sets are empty: each of these appearances
    takes the value of the plain appearance of its lightness.
*/
- (void)testHighContrastAndVibrantAppearancesTakeThePlainValueOfTheirLightness
{
    var dark = [1.0, 1.0, 1.0, 0.8471],
        light = [0.0, 0.0, 0.0, 0.8471];

    [self assertComponents:dark of:[self systemColor:@"labelColor" in:CPAppearanceNameVibrantDark]];
    [self assertComponents:dark of:[self systemColor:@"labelColor" in:CPAppearanceNameAccessibilityHighContrastDarkAqua]];
    [self assertComponents:dark of:[self systemColor:@"labelColor" in:CPAppearanceNameAccessibilityHighContrastVibrantDark]];
    [self assertComponents:light of:[self systemColor:@"labelColor" in:CPAppearanceNameVibrantLight]];
    [self assertComponents:light of:[self systemColor:@"labelColor" in:CPAppearanceNameAccessibilityHighContrastAqua]];
    [self assertComponents:light of:[self systemColor:@"labelColor" in:CPAppearanceNameAccessibilityHighContrastVibrantLight]];
}

// MARK: The order of the lookup

- (void)testAThemeValueKeyedByTheAppearanceComesFirst
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]
                                       labelColors:[CPThemeStateAppearanceDarkAqua, [CPColor blueColor]]]];

    [self assert:[CPColor blueColor] equals:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameAqua]];
}

/*
    A theme value without a state is a value for every appearance, so it comes before the
    built-in dark value.
*/
- (void)testAThemeValueWithoutAStateComesBeforeTheBuiltInValue
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]
                                       labelColors:[nil, [CPColor redColor]]]];

    [self assert:[CPColor redColor] equals:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
    [self assert:[CPColor redColor] equals:[self systemColor:@"labelColor" in:CPAppearanceNameAqua]];
}

// MARK: The supported form

/*
    Under a theme that supports Aqua only, a view with the DarkAqua appearance keeps that
    appearance, but the built-in values take their Aqua form, so they agree with the light
    controls around them.
*/
- (void)testUnderAnAquaOnlyThemeADarkViewTakesTheAquaValues
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua] labelColors:nil]];

    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];

    [self assert:CPAppearanceNameDarkAqua equals:[[view effectiveAppearance] name]];
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameVibrantDark]];
}

- (void)testAThemeWithoutAListTakesTheAquaValues
{
    [CPTheme setDefaultTheme:[self themeSupporting:nil labelColors:nil]];

    [self assertComponents:[1.0, 1.0, 1.0, 1.0] of:[self systemColor:@"windowBackgroundColor" in:CPAppearanceNameDarkAqua]];
}

/*
    The supported form limits only the built-in values. A value that the theme keys by DarkAqua
    applies under a theme that supports Aqua only.
*/
- (void)testUnderAnAquaOnlyThemeAThemeValueForDarkAquaStillApplies
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua]
                                       labelColors:[CPThemeStateAppearanceDarkAqua, [CPColor blueColor]]]];

    [self assert:[CPColor blueColor] equals:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
}

/*
    Under a theme that supports DarkAqua only, a light view takes the dark values.
*/
- (void)testUnderADarkOnlyThemeALightViewTakesTheDarkValues
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameDarkAqua] labelColors:nil]];

    [self assertComponents:[1.0, 1.0, 1.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameAqua]];
}

- (void)testACatalogColorFollowsAThemeSwitch
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua] labelColors:nil]];
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];

    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua] labelColors:nil]];
    [self assertComponents:[1.0, 1.0, 1.0, 0.8471] of:[self systemColor:@"labelColor" in:CPAppearanceNameDarkAqua]];
}

@end
