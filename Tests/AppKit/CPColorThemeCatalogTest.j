/*
 *  CPColorThemeCatalogTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-11.
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
    A theme's own colours are in the theme catalog "Theme". The theme gives their values in
    the attribute "theme-colors" of CPColor: for each appearance state, a dictionary from colour
    name to colour. A theme colour resolves at use against the default theme, as a System colour
    does.
*/
@implementation CPColorThemeCatalogTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[self themeWithFillColors]];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
}

/*
    A theme that gives fillColor a value for every appearance, one for DarkAqua and one for
    high-contrast DarkAqua, and strokeColor a value for every appearance only.
*/
- (CPTheme)themeWithFillColors
{
    var theme = [[CPTheme alloc] initWithName:@"CPColorThemeCatalogTestFillColors"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:@{ @"fillColor": [CPColor redColor], @"strokeColor": [CPColor greenColor] } forThemeAttribute:@"theme-colors"];
    [template setValue:@{ @"fillColor": [CPColor blueColor] } forThemeAttribute:@"theme-colors" inState:CPThemeStateAppearanceDarkAqua];
    [template setValue:@{ @"fillColor": [CPColor yellowColor] } forThemeAttribute:@"theme-colors" inState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPColor)themeColorNamed:(CPString)aName
{
    return [CPColor colorWithCatalogName:@"Theme" colorName:aName];
}

/*
    Returns aColor resolved in the appearance named anAppearanceName.
*/
- (CPColor)resolve:(CPColor)aColor in:(CPString)anAppearanceName
{
    var resolvedColor = nil;

    [[CPAppearance appearanceNamed:anAppearanceName] performAsCurrentDrawingAppearance:function()
    {
        resolvedColor = [aColor colorUsingColorSpaceName:nil];
    }];

    return resolvedColor;
}

// MARK: Names

- (void)testTheThemeCatalogGivesAColorForAnyName
{
    var color = [self themeColorNamed:@"fillColor"];

    [self assertNotNull:color];
    [self assert:@"Theme" equals:[color catalogNameComponent]];
    [self assert:@"fillColor" equals:[color colorNameComponent]];
    [self assertNotNull:[self themeColorNamed:@"aNameThatNoThemeGives"]];
}

- (void)testTheThemeCatalogGivesOneObjectPerName
{
    [self assert:[self themeColorNamed:@"fillColor"] same:[self themeColorNamed:@"fillColor"]];
}

- (void)testTwoColorsOfOneNameAreEqual
{
    var color = [self themeColorNamed:@"fillColor"],
        firstColor = [color colorWithAlphaComponent:0.5],
        secondColor = [color colorWithAlphaComponent:0.5];

    [self assertFalse:firstColor === secondColor];
    [self assertTrue:[firstColor isEqual:secondColor]];
}

- (void)testAThemeColorAndASystemColorOfTheSameNameAreNotEqual
{
    [self assertFalse:[[self themeColorNamed:@"labelColor"] isEqual:[CPColor labelColor]]];
    [self assertFalse:[[CPColor labelColor] isEqual:[self themeColorNamed:@"labelColor"]]];
}

// MARK: Resolution

- (void)testResolutionPerAppearanceWithTheFallbackOrder
{
    var color = [self themeColorNamed:@"fillColor"];

    [self assertTrue:[[self resolve:color in:CPAppearanceNameAqua] isEqual:[CPColor redColor]]];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameDarkAqua] isEqual:[CPColor blueColor]]];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameAccessibilityHighContrastDarkAqua] isEqual:[CPColor yellowColor]]];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameVibrantDark] isEqual:[CPColor blueColor]] message:@"VibrantDark falls back to DarkAqua"];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameAccessibilityHighContrastVibrantDark] isEqual:[CPColor yellowColor]] message:@"high-contrast VibrantDark falls back to high-contrast DarkAqua"];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameVibrantLight] isEqual:[CPColor redColor]] message:@"VibrantLight falls back to the value for every appearance"];
}

- (void)testANameMissingFromTheDarkDictionaryTakesTheValueForEveryAppearance
{
    var color = [self themeColorNamed:@"strokeColor"];

    [self assertTrue:[[self resolve:color in:CPAppearanceNameDarkAqua] isEqual:[CPColor greenColor]]];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameAccessibilityHighContrastDarkAqua] isEqual:[CPColor greenColor]]];
}

/*
    The warning is logged once per name for the whole run, so the name is used by this test
    only.
*/
- (void)testAMissingNameGivesTheClearColorAndOneWarning
{
    var warnings = [],
        logger = function(aMessage) { warnings.push(aMessage); },
        color = [self themeColorNamed:@"CPColorThemeCatalogTestMissingColor"];

    CPLogRegisterSingle(logger, "warn");

    try
    {
        [self assertTrue:[[self resolve:color in:CPAppearanceNameAqua] isEqual:[CPColor clearColor]]];
        [self assertTrue:[[self resolve:color in:CPAppearanceNameDarkAqua] isEqual:[CPColor clearColor]]];
    }
    finally
    {
        CPLogUnregister(logger);
    }

    [self assert:1 equals:warnings.length message:warnings.join("\n")];
    [self assertTrue:warnings[0].indexOf("CPColorThemeCatalogTestMissingColor") !== -1];
}

- (void)testAThemeWithoutTheAttributeGivesTheClearColor
{
    [CPTheme setDefaultTheme:[[CPTheme alloc] initWithName:@"CPColorThemeCatalogTestEmpty"]];

    [self assertTrue:[[self resolve:[self themeColorNamed:@"fillColor"] in:CPAppearanceNameAqua] isEqual:[CPColor clearColor]]];
}

- (void)testAnAlphaOnAThemeColor
{
    var color = [[self themeColorNamed:@"fillColor"] colorWithAlphaComponent:0.5];

    [self assertTrue:[[self resolve:color in:CPAppearanceNameAqua] isEqual:[[CPColor redColor] colorWithAlphaComponent:0.5]]];
    [self assertTrue:[[self resolve:color in:CPAppearanceNameDarkAqua] isEqual:[[CPColor blueColor] colorWithAlphaComponent:0.5]]];
}

- (void)testAThemeSwitchChangesTheValueOfOneName
{
    var color = [self themeColorNamed:@"fillColor"],
        otherTheme = [[CPTheme alloc] initWithName:@"CPColorThemeCatalogTestOtherColors"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:@{ @"fillColor": [CPColor purpleColor] } forThemeAttribute:@"theme-colors"];
    [otherTheme takeThemeFromObject:template];

    [self assertTrue:[[self resolve:color in:CPAppearanceNameAqua] isEqual:[CPColor redColor]]];

    [CPTheme setDefaultTheme:otherTheme];

    [self assertTrue:[[self resolve:color in:CPAppearanceNameAqua] isEqual:[CPColor purpleColor]]];
}

// MARK: Archiving

- (void)testArchiveByCatalogAndName
{
    var color = [self themeColorNamed:@"fillColor"],
        decodedColor = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:color]];

    [self assert:color same:decodedColor];
}

- (void)testArchiveOfAThemeColorWithAnAlpha
{
    var color = [[self themeColorNamed:@"fillColor"] colorWithAlphaComponent:0.25],
        decodedColor = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:color]];

    [self assert:@"Theme" equals:[decodedColor catalogNameComponent]];
    [self assert:@"fillColor" equals:[decodedColor colorNameComponent]];
    [self assertTrue:[[self resolve:decodedColor in:CPAppearanceNameDarkAqua] isEqual:[[CPColor blueColor] colorWithAlphaComponent:0.25]]];
}

@end
