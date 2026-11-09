/*
 *  CPColorCatalogTest.j
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

@import <AppKit/CPColor.j>
@import <AppKit/CPAppearance.j>
@import <AppKit/CPTheme.j>

/*
    The system colours, as AppKit names them. Each has a class method of the same name, except
    the private _sourceListBackgroundColor, which Interface Builder writes for a source list.
*/
var CPColorCatalogTestSystemColorNames = [
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

@implementation CPColorCatalogTest : OJTestCase
{
    CPTheme     _previousTheme;
}

/*
    Each test starts with a theme that gives no colour values, so that a system colour takes
    its default unless the test sets another theme.
*/
- (void)setUp
{
    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[[CPTheme alloc] initWithName:@"CPColorCatalogTestEmpty"]];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
}

/*
    A theme that gives labelColor a value for every appearance, one for DarkAqua and one for
    high-contrast DarkAqua.
*/
- (CPTheme)themeWithLabelColors
{
    var theme = [[CPTheme alloc] initWithName:@"CPColorCatalogTestLabelColors"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:[CPColor redColor] forThemeAttribute:@"label-color"];
    [template setValue:[CPColor blueColor] forThemeAttribute:@"label-color" inState:CPThemeStateAppearanceDarkAqua];
    [template setValue:[CPColor greenColor] forThemeAttribute:@"label-color" inState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPColor)labelColorIn:(CPString)anAppearanceName
{
    var resolvedColor = nil;

    [[CPAppearance appearanceNamed:anAppearanceName] performAsCurrentDrawingAppearance:function()
    {
        resolvedColor = [[CPColor labelColor] colorUsingColorSpaceName:nil];
    }];

    return resolvedColor;
}

- (void)assertComponents:(CPArray)expected of:(CPColor)aColor
{
    var components = [aColor components];

    for (var i = 0; i < 4; i++)
        [self assert:ROUND(expected[i] * 10000) equals:ROUND(components[i] * 10000) message:[aColor description] + ", component " + i];
}

// MARK: Names

- (void)testEachSystemColorMethodReturnsItsCatalogColor
{
    CPColorCatalogTestSystemColorNames.forEach(function(aName)
    {
        var color = [CPColor performSelector:CPSelectorFromString(aName)];

        [self assert:@"System" equals:[color catalogNameComponent] message:aName];
        [self assert:aName equals:[color colorNameComponent]];
        [self assert:color same:[CPColor colorWithCatalogName:@"System" colorName:aName]];
    });
}

- (void)testThePrivateSourceListColorResolvesByName
{
    var color = [CPColor colorWithCatalogName:@"System" colorName:@"_sourceListBackgroundColor"];

    [self assert:@"_sourceListBackgroundColor" equals:[color colorNameComponent]];
}

- (void)testAnUnknownCatalogOrNameGivesNil
{
    [self assertNull:[CPColor colorWithCatalogName:@"System" colorName:@"noSuchColor"]];
    [self assertNull:[CPColor colorWithCatalogName:@"Crayons" colorName:@"labelColor"]];
}

- (void)testAColorThatIsNotACatalogColorHasNoCatalogName
{
    [self assertThrows:function() { [[CPColor redColor] catalogNameComponent]; }];
    [self assertThrows:function() { [[CPColor redColor] colorNameComponent]; }];
}

// MARK: Defaults

- (void)testWithoutAThemeValueASystemColorTakesAppKitsAquaValue
{
    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:[CPColor labelColor]];
    [self assertComponents:[0.0, 0.4784, 1.0, 1.0] of:[CPColor controlAccentColor]];
}

/*
    nib2cib maps these three names to fixed values, which a cib already holds.
*/
- (void)testTheColorsThatNib2cibMapsKeepItsValues
{
    [self assertComponents:[175.0 / 255.0, 175.0 / 255.0, 175.0 / 255.0, 1.0] of:[CPColor controlColor]];
    [self assertComponents:[1.0, 1.0, 1.0, 1.0] of:[CPColor controlBackgroundColor]];
    [self assertComponents:[204.0 / 255.0, 204.0 / 255.0, 204.0 / 255.0, 1.0] of:[CPColor gridColor]];
}

- (void)testTheSystemColorsThatCPColorHadKeepTheirValues
{
    [self assertComponents:[0.0, 0.0, 0.0, 1.0 / 3.0] of:[CPColor shadowColor]];
    [self assertComponents:[0.22, 0.46, 0.84, 1.0] of:[CPColor alternateSelectedControlColor]];
    [self assertComponents:[0.83, 0.83, 0.83, 1.0] of:[CPColor secondarySelectedControlColor]];
    [self assertTrue:[[CPColor selectedTextBackgroundColor] isEqual:[CPColor colorWithHexString:"99CCFF"]]];
}

// MARK: Theme values

- (void)testAThemeValueReplacesTheDefault
{
    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assert:[CPColor redColor] equals:[self labelColorIn:CPAppearanceNameAqua]];
    [self assertComponents:[0.0, 0.0, 0.0, 1.0] of:[CPColor textColor]];
}

- (void)testTheThemeValueForTheDrawingAppearanceWins
{
    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assert:[CPColor blueColor] equals:[self labelColorIn:CPAppearanceNameDarkAqua]];
}

- (void)testAVibrantAppearanceTakesTheValueOfThePlainAppearance
{
    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assert:[CPColor blueColor] equals:[self labelColorIn:CPAppearanceNameVibrantDark]];
    [self assert:[CPColor redColor] equals:[self labelColorIn:CPAppearanceNameVibrantLight]];
}

- (void)testAHighContrastValueWinsUnderHighContrast
{
    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assert:[CPColor greenColor] equals:[self labelColorIn:CPAppearanceNameAccessibilityHighContrastDarkAqua]];
    [self assert:[CPColor greenColor] equals:[self labelColorIn:CPAppearanceNameAccessibilityHighContrastVibrantDark]];
}

- (void)testAHighContrastAppearanceWithoutAValueOfItsOwnFallsBack
{
    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assert:[CPColor redColor] equals:[self labelColorIn:CPAppearanceNameAccessibilityHighContrastAqua]];
}

- (void)testACatalogColorFollowsAThemeChange
{
    var labelColor = [CPColor labelColor];

    [self assertComponents:[0.0, 0.0, 0.0, 0.8471] of:labelColor];

    [CPTheme setDefaultTheme:[self themeWithLabelColors]];

    [self assertComponents:[1.0, 0.0, 0.0, 1.0] of:labelColor];
}

// MARK: Behaviour

- (void)testAColorWithAnotherAlphaStaysACatalogColor
{
    var color = [[CPColor labelColor] colorWithAlphaComponent:0.5];

    [self assert:@"labelColor" equals:[color colorNameComponent]];
    [self assertComponents:[0.0, 0.0, 0.0, 0.5] of:color];
}

- (void)testACatalogColorEqualsItsResolvedValue
{
    var fixedShadowColor = [CPColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0 / 3.0];

    [self assertTrue:[[CPColor shadowColor] isEqual:fixedShadowColor]];
    [self assertTrue:[fixedShadowColor isEqual:[CPColor shadowColor]]];
}

- (void)testCatalogColorsAreEqualWhenTheyNameTheSameColor
{
    [self assertTrue:[[CPColor labelColor] isEqual:[CPColor colorWithCatalogName:@"System" colorName:@"labelColor"]]];
    [self assertFalse:[[CPColor labelColor] isEqual:[CPColor controlTextColor]]];
    [self assertFalse:[[CPColor labelColor] isEqual:[[CPColor labelColor] colorWithAlphaComponent:0.5]]];
}

- (void)testACatalogColorIsArchivedByName
{
    var archivedColor = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:[CPColor labelColor]]],
        archivedAlphaColor = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:[[CPColor labelColor] colorWithAlphaComponent:0.5]]];

    [self assert:[CPColor labelColor] same:archivedColor];
    [self assert:@"labelColor" equals:[archivedAlphaColor colorNameComponent]];
    [self assert:0.5 equals:[archivedAlphaColor alphaComponent]];
}

@end
