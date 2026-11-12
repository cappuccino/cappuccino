/*
 *  Aristo3ThemeColorsTest.j
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

@import "BuiltThemes.j"

/*
    Aristo3 gives its own colours as names of the theme catalog. Each name takes its value from
    the attribute "theme-colors" of CPColor: a table for every appearance and a table for the
    dark appearance. A value in a CSS dictionary is a string, a colour or an array of these,
    and it is converted when it is written.

    These tests read the built Aristo3 theme, so they need the themes built first, as
    `npx jake build` does.
*/
var Aristo3ThemeColorsTestObjectDescriptions = ["Catalog color", "Asset color", "[object"];

@implementation Aristo3ThemeColorsTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _previousTheme = [CPTheme defaultTheme];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
}

- (CPTheme)aristo3
{
    var theme = BuiltThemeNamed(@"Aristo3");

    [self assertNotNull:theme message:@"The built blends hold no Aristo3 theme. Build the themes first."];

    return theme;
}

/*
    Returns the table of theme colours that aTheme gives for the theme state aState.
*/
- (CPDictionary)themeColorsOf:(CPTheme)aTheme inState:(CPThemeState)aState
{
    return [[[aTheme attributeWithName:@"theme-colors" forClass:@"color"] values] objectForKey:String(aState)];
}

/*
    Calls aFunction(aValue, aLocation) for each value inside aValue: aValue itself, the members
    of an array or a dictionary, and the values of the CSS dictionaries of a CSS colour or
    image. A named colour or a System image is not opened: it resolves to another object.
*/
- (void)visit:(id)aValue at:(CPString)aLocation with:(Function)aFunction
{
    if (aValue === nil || aValue === undefined)
        return;

    aFunction(aValue, aLocation);

    if (typeof aValue === "string" || !aValue.isa)
        return;

    if ([aValue isKindOfClass:[CPArray class]])
    {
        for (var i = 0; i < aValue.length; i++)
            [self visit:aValue[i] at:aLocation + "[" + i + "]" with:aFunction];
    }
    else if ([aValue isKindOfClass:[CPDictionary class]])
    {
        var keys = [aValue allKeys];

        for (var i = 0; i < keys.length; i++)
            [self visit:[aValue objectForKey:keys[i]] at:aLocation + "." + keys[i] with:aFunction];
    }
    else if (([aValue isKindOfClass:[CPColor class]] && ![aValue isKindOfClass:[_CPDynamicColor class]]) ||
             ([aValue isKindOfClass:[CPImage class]] && ![aValue isKindOfClass:[_CPDynamicImage class]]))
    {
        [self visit:[aValue cssDictionary] at:aLocation + " (CSS)" with:aFunction];
        [self visit:[aValue cssBeforeDictionary] at:aLocation + " (::before)" with:aFunction];
        [self visit:[aValue cssAfterDictionary] at:aLocation + " (::after)" with:aFunction];
    }
}

/*
    Calls aFunction(aValue, aLocation) for each value inside every attribute value of aTheme.
*/
- (void)visitTheme:(CPTheme)aTheme with:(Function)aFunction
{
    var classNames = [[aTheme classNames] sortedArrayUsingSelector:@selector(compare:)];

    for (var i = 0; i < classNames.length; i++)
    {
        var attributes = [aTheme attributesForClass:classNames[i]],
            names = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];

        for (var j = 0; j < names.length; j++)
        {
            var values = [[attributes objectForKey:names[j]] values],
                states = [values allKeys];

            for (var k = 0; k < states.length; k++)
                [self visit:[values objectForKey:states[k]] at:classNames[i] + " " + names[j] + " (" + states[k] + ")" with:aFunction];
        }
    }
}

- (BOOL)isThemeColor:(id)aValue
{
    return !!aValue && !!aValue.isa && [aValue isKindOfClass:[_CPCatalogColor class]] && [aValue catalogNameComponent] === @"Theme";
}

- (void)testEveryThemeColorThatAristo3NamesHasALightAndADarkValue
{
    var theme = [self aristo3],
        lightColors = [self themeColorsOf:theme inState:CPThemeStateNormal],
        darkColors = [self themeColorsOf:theme inState:CPThemeStateAppearanceDarkAqua],
        missing = [],
        count = 0;

    [self assertNotNull:lightColors message:@"Aristo3 gives no theme colours for every appearance"];
    [self assertNotNull:darkColors message:@"Aristo3 gives no theme colours for DarkAqua"];

    [self visitTheme:theme with:function(aValue, aLocation)
    {
        if (![self isThemeColor:aValue])
            return;

        var name = [aValue colorNameComponent];

        count++;

        if (![lightColors containsKey:name])
            missing.push(aLocation + ": " + name + " has no value for every appearance");

        if (![darkColors containsKey:name])
            missing.push(aLocation + ": " + name + " has no value for DarkAqua");
    }];

    [self assertTrue:count > 0 message:@"Aristo3 names no theme colour"];
    [self assertTrue:missing.length === 0 message:missing.join("\n")];
}

- (void)testTheLightAndTheDarkTableNameTheSameColors
{
    var theme = [self aristo3],
        lightNames = [[[self themeColorsOf:theme inState:CPThemeStateNormal] allKeys] sortedArrayUsingSelector:@selector(compare:)],
        darkNames = [[[self themeColorsOf:theme inState:CPThemeStateAppearanceDarkAqua] allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [self assert:lightNames.join(", ") equals:darkNames.join(", ")];
}

- (void)testATableValueIsAFixedOrASystemColor
{
    var theme = [self aristo3],
        violations = [];

    [CPThemeStateNormal, CPThemeStateAppearanceDarkAqua].forEach(function(aState)
    {
        var colors = [self themeColorsOf:theme inState:aState],
            names = [colors allKeys];

        for (var i = 0; i < names.length; i++)
        {
            var value = [colors objectForKey:names[i]];

            if (![value isKindOfClass:[CPColor class]] || [self isThemeColor:value] || [value isCSSBased] || [value patternImage])
                violations.push(String(aState) + " " + names[i] + ": " + [value description]);
        }
    });

    [self assertTrue:violations.length === 0 message:violations.join("\n")];
}

/*
    Each System colour in Aristo3's dark set takes AppKit's DarkAqua value in DarkAqua and
    keeps AppKit's Aqua value in Aqua.
*/
- (void)testTheSystemColorsOfTheDarkSetTakeAppKitsDarkAquaValues
{
    var expectedComponents = {
            "windowBackgroundColor":        [[1.0, 1.0, 1.0, 1.0], [0.1176, 0.1176, 0.1176, 1.0]],
            "_sourceListBackgroundColor":   [[0.9647, 0.9647, 0.9647, 0.8], [0.1765, 0.1765, 0.1765, 0.9]],
            "secondaryLabelColor":          [[0.0, 0.0, 0.0, 0.498], [1.0, 1.0, 1.0, 0.549]],
            "systemGrayColor":              [[0.5569, 0.5569, 0.5765, 1.0], [0.5961, 0.5961, 0.6157, 1.0]],
            "systemPurpleColor":            [[0.7961, 0.1882, 0.8784, 1.0], [0.8588, 0.2039, 0.949, 1.0]]
        },
        appearanceNames = [CPAppearanceNameAqua, CPAppearanceNameDarkAqua],
        mismatches = [];

    [CPTheme setDefaultTheme:[self aristo3]];

    for (var name in expectedComponents)
    {
        var color = [CPColor colorWithCatalogName:@"System" colorName:name];

        for (var i = 0; i < appearanceNames.length; i++)
        {
            var expected = expectedComponents[name][i],
                components = nil;

            [[CPAppearance appearanceNamed:appearanceNames[i]] performAsCurrentDrawingAppearance:function()
            {
                components = [[color colorUsingColorSpaceName:nil] components];
            }];

            for (var j = 0; j < 4; j++)
            {
                if (ROUND(components[j] * 10000) !== ROUND(expected[j] * 10000))
                {
                    mismatches.push(name + " in " + appearanceNames[i] + ": " + components.join(", ") + " should be " + expected.join(", "));
                    break;
                }
            }
        }
    }

    [self assertTrue:mismatches.length === 0 message:mismatches.join("\n")];
}

/*
    A site that joins a named colour into a string with + writes the colour's description.
    Every CSS value converts in Aqua and in DarkAqua, and no text holds the description of
    an object.
*/
- (void)testNoConvertedValueHoldsTheDescriptionOfAnObject
{
    var theme = [self aristo3],
        violations = [];

    [CPTheme setDefaultTheme:theme];

    [CPAppearanceNameAqua, CPAppearanceNameDarkAqua].forEach(function(anAppearanceName)
    {
        [[CPAppearance appearanceNamed:anAppearanceName] performAsCurrentDrawingAppearance:function()
        {
            [self visitTheme:theme with:function(aValue, aLocation)
            {
                var text = nil;

                if (typeof aValue === "string")
                    text = aValue;
                else if (aValue.isa && ([aValue isKindOfClass:[CPColor class]] || [aValue isKindOfClass:[CPImage class]]) &&
                         ![aValue isKindOfClass:[_CPDynamicColor class]] && ![aValue isKindOfClass:[_CPDynamicImage class]] && [aValue isCSSBased])
                {
                    try
                    {
                        text = _CPCSSObjectText(aValue);
                    }
                    catch (anException)
                    {
                        violations.push(anAppearanceName + " " + aLocation + ": " + anException);
                        return;
                    }
                }

                if (text === nil)
                    return;

                for (var i = 0; i < Aristo3ThemeColorsTestObjectDescriptions.length; i++)
                    if (text.indexOf(Aristo3ThemeColorsTestObjectDescriptions[i]) !== -1)
                        violations.push(anAppearanceName + " " + aLocation + ": " + text);
            }];
        }];
    });

    [self assertTrue:violations.length === 0 message:violations.join("\n")];
}

@end
