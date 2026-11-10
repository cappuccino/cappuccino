/*
 *  CPThemeAttributeAppearanceTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-10.
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
@import <AppKit/CPTheme.j>

var CPThemeAttributeAppearanceTestStates = [
        CPThemeStateAppearanceAqua,
        CPThemeStateAppearanceDarkAqua,
        CPThemeStateAppearanceLightContent,
        CPThemeStateAppearanceVibrantLight,
        CPThemeStateAppearanceVibrantDark,
        CPThemeStateAppearanceAccessibilityHighContrastAqua,
        CPThemeStateAppearanceAccessibilityHighContrastDarkAqua,
        CPThemeStateAppearanceAccessibilityHighContrastVibrantLight,
        CPThemeStateAppearanceAccessibilityHighContrastVibrantDark
    ];

@implementation CPThemeAttributeAppearanceTest : OJTestCase

/*
    Returns an attribute that holds the values of someValues, an array of state and value
    pairs, and whose default value is "default".
*/
- (_CPThemeAttribute)attributeWithValues:(CPArray)someValues
{
    return [self attributeWithValues:someValues defaultAttribute:nil];
}

- (_CPThemeAttribute)attributeWithValues:(CPArray)someValues defaultAttribute:(_CPThemeAttribute)aDefaultAttribute
{
    var attribute = [[_CPThemeAttribute alloc] initWithName:@"test-attribute" defaultValue:@"default" defaultAttribute:aDefaultAttribute];

    for (var i = 0; i < someValues.length; i += 2)
        attribute = [attribute attributeBySettingValue:someValues[i + 1] forState:someValues[i]];

    return attribute;
}

- (void)testADarkAquaValueServesHighContrastDarkAqua
{
    var attribute = [self attributeWithValues:[CPThemeStateNormal, @"light", CPThemeStateAppearanceDarkAqua, @"dark"]];

    [self assert:@"dark" equals:[attribute valueForState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua]];
    [self assert:@"dark" equals:[attribute valueForState:CPThemeState(CPThemeStateAppearanceAccessibilityHighContrastDarkAqua, CPThemeStateHighlighted)]];
}

- (void)testAnAquaValueServesVibrantLightAndLightContent
{
    var attribute = [self attributeWithValues:[CPThemeStateNormal, @"normal", CPThemeStateAppearanceAqua, @"aqua"]];

    [self assert:@"aqua" equals:[attribute valueForState:CPThemeStateAppearanceVibrantLight]];
    [self assert:@"aqua" equals:[attribute valueForState:CPThemeStateAppearanceLightContent]];
    [self assert:@"aqua" equals:[attribute valueForState:CPThemeStateAppearanceAccessibilityHighContrastAqua]];
}

- (void)testHighContrastVibrantDarkFallsBackInTheMatchingOrder
{
    var state = CPThemeStateAppearanceAccessibilityHighContrastVibrantDark,
        values = [CPThemeStateNormal, @"normal", CPThemeStateAppearanceDarkAqua, @"dark-aqua"];

    [self assert:@"dark-aqua" equals:[[self attributeWithValues:values] valueForState:state]];

    values = values.concat([CPThemeStateAppearanceVibrantDark, @"vibrant-dark"]);
    [self assert:@"vibrant-dark" equals:[[self attributeWithValues:values] valueForState:state]];

    values = values.concat([CPThemeStateAppearanceAccessibilityHighContrastDarkAqua, @"high-contrast-dark-aqua"]);
    [self assert:@"high-contrast-dark-aqua" equals:[[self attributeWithValues:values] valueForState:state]];

    values = values.concat([state, @"own"]);
    [self assert:@"own" equals:[[self attributeWithValues:values] valueForState:state]];
}

- (void)testALightStateNeverTakesADarkValue
{
    var attribute = [self attributeWithValues:[CPThemeStateNormal, @"normal",
                                               CPThemeStateAppearanceDarkAqua, @"dark-aqua",
                                               CPThemeStateAppearanceVibrantDark, @"vibrant-dark",
                                               CPThemeStateAppearanceAccessibilityHighContrastDarkAqua, @"high-contrast-dark-aqua"]],
        lightStates = [CPThemeStateAppearanceAqua,
                       CPThemeStateAppearanceLightContent,
                       CPThemeStateAppearanceVibrantLight,
                       CPThemeStateAppearanceAccessibilityHighContrastAqua,
                       CPThemeStateAppearanceAccessibilityHighContrastVibrantLight];

    for (var i = 0; i < lightStates.length; i++)
        [self assert:@"normal" equals:[attribute valueForState:lightStates[i]] message:String(lightStates[i])];
}

- (void)testAValueForTheOwnAppearanceWinsOverAFallbackValue
{
    var attribute = [self attributeWithValues:[CPThemeStateAppearanceDarkAqua, @"dark-aqua",
                                               CPThemeState(CPThemeStateAppearanceDarkAqua, CPThemeStateHighlighted), @"dark-aqua-highlighted",
                                               CPThemeStateAppearanceAccessibilityHighContrastDarkAqua, @"high-contrast-dark-aqua"]];

    [self assert:@"high-contrast-dark-aqua" equals:[attribute valueForState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua]];
    [self assert:@"high-contrast-dark-aqua" equals:[attribute valueForState:CPThemeState(CPThemeStateAppearanceAccessibilityHighContrastDarkAqua, CPThemeStateHighlighted)]];
}

- (void)testAFallbackValueComesAlsoFromTheDefaultAttribute
{
    var defaultAttribute = [self attributeWithValues:[CPThemeStateAppearanceDarkAqua, @"default-dark-aqua"]],
        attribute = [self attributeWithValues:[CPThemeStateHighlighted, @"highlighted"] defaultAttribute:defaultAttribute];

    [self assert:@"default-dark-aqua" equals:[attribute valueForState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua]];
}

/*
    The expected values are the results of the search at commit 925878881, which had no
    fallback: the exact key, the largest subset, the normal value, the default attribute and
    the default value.
*/
- (void)testAnAttributeWithoutAnAppearanceKeyGivesTheResultsOfTheSearchWithoutFallback
{
    var defaultAttribute = [self attributeWithValues:[CPThemeStateSelected, @"default-selected"]],
        attribute = [self attributeWithValues:[CPThemeStateNormal, @"normal",
                                               CPThemeStateHighlighted, @"highlighted",
                                               CPThemeState(CPThemeStateHighlighted, CPThemeStateDisabled), @"highlighted-disabled"]
                             defaultAttribute:defaultAttribute],
        noNormalAttribute = [self attributeWithValues:[CPThemeStateHighlighted, @"highlighted"] defaultAttribute:defaultAttribute];

    for (var i = 0; i < CPThemeAttributeAppearanceTestStates.length; i++)
    {
        var appearanceState = CPThemeAttributeAppearanceTestStates[i],
            message = String(appearanceState);

        [self assert:@"normal" equals:[attribute valueForState:appearanceState] message:message];
        [self assert:@"highlighted" equals:[attribute valueForState:CPThemeState(appearanceState, CPThemeStateHighlighted)] message:message];
        [self assert:@"highlighted-disabled" equals:[attribute valueForState:CPThemeState(appearanceState, CPThemeStateHighlighted, CPThemeStateDisabled)] message:message];
        [self assert:@"default-selected" equals:[attribute valueForState:CPThemeState(appearanceState, CPThemeStateSelected)] message:message];

        [self assert:@"default" equals:[noNormalAttribute valueForState:appearanceState] message:message];
        [self assert:@"default-selected" equals:[noNormalAttribute valueForState:CPThemeState(appearanceState, CPThemeStateSelected)] message:message];
    }
}

@end
