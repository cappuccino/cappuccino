/*
 *  _CPAppearanceManagerTest.j
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

@import <AppKit/CPApplication.j>
@import <AppKit/CPAppearance.j>

var _CPAppearanceManagerTestDark = "(prefers-color-scheme: dark)",
    _CPAppearanceManagerTestHighContrast = "(prefers-contrast: more)",
    _CPAppearanceManagerTestLowContrast = "(prefers-contrast: less)",
    _CPAppearanceManagerTestForcedColors = "(forced-colors: active)";

/*
    Returns a controlled stand-in for the browser's media queries. matchMedia gives one media
    query list per query; set() changes whether a query matches and sends the change event.
*/
function _CPAppearanceManagerTestMedia(someMatchingQueries)
{
    var media = { lists: {} };

    media.matchMedia = function(aQuery)
    {
        var list = media.lists[aQuery];

        if (!list)
        {
            list = { media: aQuery, matches: someMatchingQueries.indexOf(aQuery) !== -1, handlers: [] };

            list.addEventListener = function(aType, aHandler)
            {
                if (aType === "change")
                    list.handlers.push(aHandler);
            };

            list.removeEventListener = function(aType, aHandler)
            {
                var index = list.handlers.indexOf(aHandler);

                if (index !== -1)
                    list.handlers.splice(index, 1);
            };

            media.lists[aQuery] = list;
        }

        return list;
    };

    media.set = function(aQuery, shouldMatch)
    {
        var list = media.matchMedia(aQuery),
            handlers = list.handlers.slice();

        list.matches = shouldMatch;

        for (var i = 0; i < handlers.length; i++)
            handlers[i]({ media: aQuery, matches: shouldMatch });
    };

    return media;
}

@implementation _CPAppearanceManagerTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)tearDown
{
    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:nil];
}

- (CPString)systemAppearanceNameForQueries:(CPArray)someMatchingQueries
{
    var manager = [_CPAppearanceManager sharedManager];

    [manager _setMatchMediaFunction:_CPAppearanceManagerTestMedia(someMatchingQueries).matchMedia];

    return [[manager systemAppearance] name];
}

- (void)testTheTwoTraitsGiveTheFourSystemNames
{
    [self assert:CPAppearanceNameAqua equals:[self systemAppearanceNameForQueries:[]]];
    [self assert:CPAppearanceNameDarkAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestDark]]];
    [self assert:CPAppearanceNameAccessibilityHighContrastAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestHighContrast]]];
    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestDark, _CPAppearanceManagerTestHighContrast]]];
}

- (void)testForcedColorsGiveTheHighContrastNameOfTheCurrentLightness
{
    var manager = [_CPAppearanceManager sharedManager];

    [self assert:CPAppearanceNameAccessibilityHighContrastAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestForcedColors]]];
    [self assertTrue:[manager forcedColorsActive]];

    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestDark, _CPAppearanceManagerTestForcedColors]]];
    [self assertTrue:[manager forcedColorsActive]];

    [self systemAppearanceNameForQueries:[_CPAppearanceManagerTestHighContrast]];
    [self assertFalse:[manager forcedColorsActive]];
}

- (void)testLessContrastGivesNormalContrast
{
    [self assert:CPAppearanceNameAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestLowContrast]]];
    [self assert:CPAppearanceNameDarkAqua equals:[self systemAppearanceNameForQueries:[_CPAppearanceManagerTestDark, _CPAppearanceManagerTestLowContrast]]];
}

- (void)testWithoutMatchMediaTheSystemAppearanceIsAqua
{
    var manager = [_CPAppearanceManager sharedManager];

    [self systemAppearanceNameForQueries:[_CPAppearanceManagerTestDark, _CPAppearanceManagerTestHighContrast]];
    [manager _setMatchMediaFunction:nil];

    [self assert:CPAppearanceNameAqua equals:[[manager systemAppearance] name]];
    [self assertFalse:[manager forcedColorsActive]];
}

- (void)testAChangeEventChangesTheSystemAppearance
{
    var manager = [_CPAppearanceManager sharedManager],
        media = _CPAppearanceManagerTestMedia([]);

    [manager _setMatchMediaFunction:media.matchMedia];
    [self assert:CPAppearanceNameAqua equals:[[manager systemAppearance] name]];

    media.set(_CPAppearanceManagerTestDark, YES);
    [self assert:CPAppearanceNameDarkAqua equals:[[manager systemAppearance] name]];

    media.set(_CPAppearanceManagerTestHighContrast, YES);
    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua equals:[[manager systemAppearance] name]];

    media.set(_CPAppearanceManagerTestDark, NO);
    [self assert:CPAppearanceNameAccessibilityHighContrastAqua equals:[[manager systemAppearance] name]];
}

- (void)testAReplacedMatchMediaFunctionStopsObservingTheOldQueries
{
    var manager = [_CPAppearanceManager sharedManager],
        oldMedia = _CPAppearanceManagerTestMedia([]);

    [manager _setMatchMediaFunction:oldMedia.matchMedia];
    [manager _setMatchMediaFunction:_CPAppearanceManagerTestMedia([]).matchMedia];

    oldMedia.set(_CPAppearanceManagerTestDark, YES);

    [self assert:CPAppearanceNameAqua equals:[[manager systemAppearance] name]];
}

- (void)testTheSystemNeverGivesAVibrantNameOrLightContent
{
    var queries = [_CPAppearanceManagerTestDark, _CPAppearanceManagerTestHighContrast, _CPAppearanceManagerTestForcedColors],
        systemNames = [CPAppearanceNameAqua, CPAppearanceNameDarkAqua, CPAppearanceNameAccessibilityHighContrastAqua, CPAppearanceNameAccessibilityHighContrastDarkAqua];

    for (var combination = 0; combination < 8; combination++)
    {
        var matchingQueries = [];

        for (var i = 0; i < queries.length; i++)
        {
            if (combination & (1 << i))
                matchingQueries.push(queries[i]);
        }

        var name = [self systemAppearanceNameForQueries:matchingQueries];

        [self assertTrue:[systemNames containsObject:name] message:@"The queries " + matchingQueries + " give " + name];
    }
}

@end
