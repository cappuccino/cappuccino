/*
 *  CPAppearanceDarkSupportTest.j
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
@import <AppKit/CPPopover.j>

var CPAppearanceDarkSupportTestDark = "(prefers-color-scheme: dark)",
    CPAppearanceDarkSupportTestHighContrast = "(prefers-contrast: more)";

/*
    Returns a stand-in for the browser's media queries. Each query in someMatchingQueries
    matches; set() changes whether a query matches and sends the change event.
*/
function CPAppearanceDarkSupportTestMedia(someMatchingQueries)
{
    var media = { lists: {} };

    media.matchMedia = function(aQuery)
    {
        var list = media.lists[aQuery];

        if (!list)
        {
            list = { media: aQuery, matches: someMatchingQueries.indexOf(aQuery) !== -1, handlers: [] };
            list.addEventListener = function(aType, aHandler) { list.handlers.push(aHandler); };
            list.removeEventListener = function(aType, aHandler) { };
            media.lists[aQuery] = list;
        }

        return list;
    };

    media.set = function(aQuery, shouldMatch)
    {
        var list = media.matchMedia(aQuery);

        list.matches = shouldMatch;

        for (var i = 0; i < list.handlers.length; i++)
            list.handlers[i]({ media: aQuery, matches: shouldMatch });
    };

    return media;
}

/*
    An Info.plist with the key CPRequiresAquaSystemAppearance.
*/
@implementation CPAppearanceDarkSupportTestInfo : CPObject
{
    BOOL    requiresAqua;
}

- (id)objectForInfoDictionaryKey:(CPString)aKey
{
    return aKey === @"CPRequiresAquaSystemAppearance" ? requiresAqua : nil;
}

@end

@implementation CPAppearanceDarkSupportTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[[CPTheme alloc] initWithName:@"CPAppearanceDarkSupportTestNoList"]];
}

- (void)tearDown
{
    var manager = [_CPAppearanceManager sharedManager];

    [manager _setMatchMediaFunction:nil];
    [manager _setInfoBundle:nil];
    [CPApp setAppearance:nil];
    [CPTheme setDefaultTheme:_previousTheme];
}

// MARK: Helpers

- (CPAppearance)appearance:(CPString)aName
{
    return [CPAppearance appearanceNamed:aName];
}

/*
    Returns a theme whose attribute "supported-appearances" holds someNames.
*/
- (CPTheme)themeSupporting:(CPArray)someNames
{
    var theme = [[CPTheme alloc] initWithName:@"CPAppearanceDarkSupportTest " + someNames.join(" ")],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:someNames forThemeAttribute:@"supported-appearances"];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPString)systemAppearanceNameForQueries:(CPArray)someMatchingQueries
{
    var manager = [_CPAppearanceManager sharedManager];

    [manager _setMatchMediaFunction:CPAppearanceDarkSupportTestMedia(someMatchingQueries).matchMedia];

    return [[manager systemAppearance] name];
}

- (void)requireAqua:(BOOL)shouldRequireAqua
{
    var info = [[CPAppearanceDarkSupportTestInfo alloc] init];

    info.requiresAqua = shouldRequireAqua;
    [[_CPAppearanceManager sharedManager] _setInfoBundle:info];
}

- (CPView)viewInWindow
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 200.0) styleMask:CPWindowNotSizable],
        view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];

    [[window contentView] addSubview:view];

    return view;
}

// MARK: The supported form

/*
    Each row gives a list and the supported form of each of the nine appearances under it, in
    the order of the names below.
*/
- (void)testTheSupportedFormOfEachAppearanceUnderFourLists
{
    var names = [CPAppearanceNameAqua, CPAppearanceNameDarkAqua, CPAppearanceNameLightContent,
                 CPAppearanceNameVibrantLight, CPAppearanceNameVibrantDark,
                 CPAppearanceNameAccessibilityHighContrastAqua, CPAppearanceNameAccessibilityHighContrastDarkAqua,
                 CPAppearanceNameAccessibilityHighContrastVibrantLight, CPAppearanceNameAccessibilityHighContrastVibrantDark],
        rows = [
            {
                list: [CPAppearanceNameAqua],
                forms: [CPAppearanceNameAqua, CPAppearanceNameAqua, CPAppearanceNameLightContent,
                        CPAppearanceNameVibrantLight, CPAppearanceNameVibrantLight,
                        CPAppearanceNameAccessibilityHighContrastAqua, CPAppearanceNameAccessibilityHighContrastAqua,
                        CPAppearanceNameAccessibilityHighContrastVibrantLight, CPAppearanceNameAccessibilityHighContrastVibrantLight]
            },
            {
                list: [CPAppearanceNameAqua, CPAppearanceNameDarkAqua],
                forms: names
            },
            {
                list: [CPAppearanceNameDarkAqua],
                forms: [CPAppearanceNameDarkAqua, CPAppearanceNameDarkAqua, CPAppearanceNameDarkAqua,
                        CPAppearanceNameVibrantDark, CPAppearanceNameVibrantDark,
                        CPAppearanceNameAccessibilityHighContrastDarkAqua, CPAppearanceNameAccessibilityHighContrastDarkAqua,
                        CPAppearanceNameAccessibilityHighContrastVibrantDark, CPAppearanceNameAccessibilityHighContrastVibrantDark]
            },
            {
                list: [CPAppearanceNameAqua, CPAppearanceNameVibrantDark],
                forms: [CPAppearanceNameAqua, CPAppearanceNameAqua, CPAppearanceNameLightContent,
                        CPAppearanceNameVibrantLight, CPAppearanceNameVibrantDark,
                        CPAppearanceNameAccessibilityHighContrastAqua, CPAppearanceNameAccessibilityHighContrastAqua,
                        CPAppearanceNameAccessibilityHighContrastVibrantLight, CPAppearanceNameAccessibilityHighContrastVibrantDark]
            }
        ];

    for (var i = 0; i < rows.length; i++)
    {
        [CPTheme setDefaultTheme:[self themeSupporting:rows[i].list]];

        for (var j = 0; j < names.length; j++)
            [self assert:rows[i].forms[j] equals:_CPAppearanceSupportedName(names[j]) message:@"The list " + rows[i].list + ", the appearance " + names[j]];
    }
}

- (void)testAThemeWithoutAListSupportsAquaOnly
{
    [self assert:[CPAppearanceNameAqua] equals:_CPAppearanceSupportedNames()];
    [self assert:CPAppearanceNameAqua equals:_CPAppearanceSupportedName(CPAppearanceNameDarkAqua)];
}

- (void)testAListWithNeitherAquaNorDarkAquaCountsAsTheDefault
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameVibrantDark]]];

    [self assert:[CPAppearanceNameAqua] equals:_CPAppearanceSupportedNames()];
    [self assert:CPAppearanceNameVibrantLight equals:_CPAppearanceSupportedName(CPAppearanceNameVibrantDark)];
}

// MARK: The system appearance

- (void)testADarkSystemGivesAquaUnderAThemeWithoutDarkSupport
{
    [self assert:CPAppearanceNameAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark]]];
    [self assert:[self appearance:CPAppearanceNameAqua] same:[CPApp effectiveAppearance]];
}

- (void)testADarkSystemGivesDarkAquaUnderAThemeWithDarkSupport
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];

    [self assert:CPAppearanceNameDarkAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark]]];
    [self assert:[self appearance:CPAppearanceNameDarkAqua] same:[CPApp effectiveAppearance]];
}

- (void)testHighContrastIsKeptUnderTheLimit
{
    [self assert:CPAppearanceNameAccessibilityHighContrastAqua
          equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark, CPAppearanceDarkSupportTestHighContrast]]];
}

- (void)testAThemeWithDarkAquaOnlyGivesDarkAquaInALightSystem
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameDarkAqua]]];

    [self assert:CPAppearanceNameDarkAqua equals:[self systemAppearanceNameForQueries:[]]];
    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestHighContrast]]];
}

- (void)testRequiringAquaKeepsADarkSystemLight
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [self requireAqua:YES];

    [self assert:CPAppearanceNameAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark]]];
    [self assert:CPAppearanceNameAccessibilityHighContrastAqua
          equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark, CPAppearanceDarkSupportTestHighContrast]]];

    [self requireAqua:NO];

    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua equals:[[[_CPAppearanceManager sharedManager] systemAppearance] name]];
}

- (void)testRequiringAquaGivesDarkAquaUnderAThemeWithDarkAquaOnly
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameDarkAqua]]];
    [self requireAqua:YES];

    [self assert:CPAppearanceNameDarkAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark]]];
}

- (void)testAnExplicitDarkAppearanceStaysUnderAThemeWithoutDarkSupport
{
    var darkAqua = [self appearance:CPAppearanceNameDarkAqua],
        view = [self viewInWindow];

    [view setAppearance:darkAqua];

    [self assert:darkAqua same:[view effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceDarkAqua]];

    [CPApp setAppearance:darkAqua];

    [self assert:darkAqua same:[CPApp effectiveAppearance]];
}

- (void)testAThemeSwitchWhileTheSystemIsDarkMovesTheLimit
{
    var withDark = [self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]],
        withoutDark = [self themeSupporting:[CPAppearanceNameAqua]],
        view = [self viewInWindow];

    [self assert:CPAppearanceNameAqua equals:[self systemAppearanceNameForQueries:[CPAppearanceDarkSupportTestDark]]];

    [CPTheme setDefaultTheme:withDark];

    [self assert:[self appearance:CPAppearanceNameDarkAqua] same:[CPApp effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceDarkAqua]];

    [CPTheme setDefaultTheme:withoutDark];

    [self assert:[self appearance:CPAppearanceNameAqua] same:[CPApp effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceAqua]];
}

- (void)testAMediaChangeIsLimitedToo
{
    var media = CPAppearanceDarkSupportTestMedia([]),
        manager = [_CPAppearanceManager sharedManager];

    [manager _setMatchMediaFunction:media.matchMedia];
    media.set(CPAppearanceDarkSupportTestDark, YES);

    [self assert:CPAppearanceNameAqua equals:[[manager systemAppearance] name]];

    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    media.set(CPAppearanceDarkSupportTestDark, NO);
    media.set(CPAppearanceDarkSupportTestDark, YES);

    [self assert:CPAppearanceNameDarkAqua equals:[[manager systemAppearance] name]];
}

// MARK: The popover default

/*
    A unit test cannot show a popover (see CPPopoverAppearanceTest). The popover records its
    positioning view when it is shown, so the tests set that view.
*/
- (CPPopover)popoverShownFrom:(CPView)aView
{
    var popover = [[CPPopover alloc] init];

    popover._positioningView = aView;

    return popover;
}

- (void)testADefaultPopoverFollowsADarkViewWhenTheThemeSupportsVibrantDark
{
    var view = [self viewInWindow];

    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [view setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[self appearance:CPAppearanceNameVibrantDark] same:[[self popoverShownFrom:view] effectiveAppearance]];

    [view setAppearance:[self appearance:CPAppearanceNameAqua]];

    [self assert:[self appearance:CPAppearanceNameVibrantLight] same:[[self popoverShownFrom:view] effectiveAppearance]];
}

- (void)testADefaultPopoverStaysLightUnderAThemeWithoutDarkSupport
{
    var view = [self viewInWindow];

    [view setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[self appearance:CPAppearanceNameVibrantLight] same:[[self popoverShownFrom:view] effectiveAppearance]];
}

- (void)testADefaultPopoverIsLightBeforeItIsShown
{
    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [CPApp setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[self appearance:CPAppearanceNameVibrantLight] same:[[[CPPopover alloc] init] effectiveAppearance]];
}

- (void)testTheLegacyHUDValueAndAnExplicitAppearanceIgnoreThePositioningView
{
    var view = [self viewInWindow],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua],
        popover = [self popoverShownFrom:view];

    [view setAppearance:[self appearance:CPAppearanceNameAqua]];
    [popover setAppearance:CPPopoverAppearanceHUD];

    [self assert:[self appearance:CPAppearanceNameVibrantDark] same:[popover effectiveAppearance]];

    [CPTheme setDefaultTheme:[self themeSupporting:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [view setAppearance:darkAqua];
    [popover setAppearance:[self appearance:CPAppearanceNameAqua]];

    [self assert:[self appearance:CPAppearanceNameAqua] same:[popover effectiveAppearance]];
}

@end
