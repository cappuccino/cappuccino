/*
 *  CPThemeDataTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-03.
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
    A theme holds values: colours, images, metrics, fonts and flags. It holds no
    code. Behaviour, such as animation, event handling and layout logic, stays in
    the class, where an application can override it, so that a change of theme
    changes appearance and never behaviour.

    These tests read every theme in the built blends and fail on any value that is
    a function, or a string holding a function's source. They read the build, so
    they need the themes built first, as `npx jake build` does.
*/
var CPThemeDataTestCodePattern = /^\s*\(?\s*(async\s+)?function\b|^\s*\(?[\w\s,]*\)?\s*=>/;

@implementation CPThemeDataTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

/*
    Adds a description of every code value inside aValue to someViolations. Arrays
    and dictionaries, such as CSS dictionaries, are searched.
*/
- (void)collectCodeIn:(id)aValue at:(CPString)aLocation into:(CPArray)someViolations
{
    if (aValue === nil || aValue === undefined)
        return;

    if (typeof aValue === "function")
    {
        someViolations.push(aLocation + " is a function");
        return;
    }

    if (typeof aValue === "string")
    {
        if (CPThemeDataTestCodePattern.test(aValue))
            someViolations.push(aLocation + " is a string holding a function's source");

        return;
    }

    if (!aValue.isa)
        return;

    if ([aValue isKindOfClass:[CPArray class]])
    {
        for (var i = 0; i < aValue.length; i++)
            [self collectCodeIn:aValue[i] at:aLocation + "[" + i + "]" into:someViolations];
    }
    else if ([aValue isKindOfClass:[CPDictionary class]])
    {
        var keys = [aValue allKeys];

        for (var i = 0; i < keys.length; i++)
            [self collectCodeIn:[aValue objectForKey:keys[i]] at:aLocation + "." + keys[i] into:someViolations];
    }
}

- (void)testThemeValuesAreData
{
    var themes = BuiltThemes(),
        violations = [];

    [self assertTrue:themes.length > 0 message:@"No themes were found in the built blends. Build the themes first."];

    for (var j = 0; j < themes.length; j++)
    {
        var theme = themes[j],
            classNames = [[theme classNames] sortedArrayUsingSelector:@selector(compare:)];

        for (var k = 0; k < classNames.length; k++)
        {
            var attributes = [theme attributesForClass:classNames[k]],
                names = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];

            for (var m = 0; m < names.length; m++)
            {
                var attribute = [attributes objectForKey:names[m]],
                    location = [theme name] + " " + classNames[k] + " " + names[m],
                    values = [attribute values],
                    states = [values allKeys];

                [self collectCodeIn:[attribute defaultValue] at:location + " (default)" into:violations];

                for (var n = 0; n < states.length; n++)
                    [self collectCodeIn:[values objectForKey:states[n]] at:location + " (" + states[n] + ")" into:violations];
            }
        }
    }

    [self assertTrue:violations.length === 0 message:@"Theme values must be data, not code:\n" + violations.join("\n")];
}

@end
