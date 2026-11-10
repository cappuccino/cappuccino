/*
 *  _CPAppearanceManager.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

/*
    CPAppearance.j imports this file, so this file refers to CPAppearance and its names only
    when its methods run, and imports neither.
*/
@class CPAppearance

@global CPApp
@global CPAppearanceNameAqua
@global CPAppearanceNameDarkAqua
@global CPAppearanceNameAccessibilityHighContrastAqua
@global CPAppearanceNameAccessibilityHighContrastDarkAqua

var _CPAppearanceSharedManager = nil;

/*
    The media queries that give the system's appearance traits.
*/
var _CPAppearanceDarkQuery          = "(prefers-color-scheme: dark)",
    _CPAppearanceHighContrastQuery  = "(prefers-contrast: more)",
    _CPAppearanceForcedColorsQuery  = "(forced-colors: active)";

/*
    Returns the name of the system appearance for the two traits. The system selects neither
    a vibrant appearance nor light content.
*/
function _CPAppearanceNameForSystemTraits(isDark, isHighContrast)
{
    if (isHighContrast)
        return isDark ? CPAppearanceNameAccessibilityHighContrastDarkAqua : CPAppearanceNameAccessibilityHighContrastAqua;

    return isDark ? CPAppearanceNameDarkAqua : CPAppearanceNameAqua;
}

/*
    Returns the matchMedia function of the primary browser window, bound to that window, or
    nil where the page has none, as in the unit tests.
*/
function _CPAppearanceBrowserMatchMedia()
{
    if (typeof window === "undefined" || !window.matchMedia)
        return nil;

    return window.matchMedia.bind(window);
}

/*
    Returns YES when the media query list aQueryList matches.
*/
function _CPAppearanceQueryMatches(aQueryList)
{
    return !!(aQueryList && aQueryList.matches);
}

/*
    Attaches aHandler to the change event of the media query list aQueryList. Older browsers
    offer only addListener.
*/
function _CPAppearanceObserveQuery(aQueryList, aHandler)
{
    if (!aQueryList)
        return;

    if (aQueryList.addEventListener)
        aQueryList.addEventListener("change", aHandler);
    else if (aQueryList.addListener)
        aQueryList.addListener(aHandler);
}

/*
    Removes aHandler from the change event of the media query list aQueryList.
*/
function _CPAppearanceStopObservingQuery(aQueryList, aHandler)
{
    if (!aQueryList)
        return;

    if (aQueryList.removeEventListener)
        aQueryList.removeEventListener("change", aHandler);
    else if (aQueryList.removeListener)
        aQueryList.removeListener(aHandler);
}

/*
    Observes the browser's colour scheme, contrast and forced-colours settings, and gives the
    system appearance: Aqua, DarkAqua, or one of their high-contrast forms. Under forced colours
    the browser replaces the page's colours with a high-contrast scheme, so forced colours
    select the high-contrast name of the scheme's lightness, and set -forcedColorsActive. When
    the system appearance changes, the manager tells the application. Cocoa has no public
    counterpart, so the class is private.
*/
@implementation _CPAppearanceManager : CPObject
{
    JSObject    _darkQuery;
    JSObject    _highContrastQuery;
    JSObject    _forcedColorsQuery;
    Function    _changeHandler;

    CPString    _systemAppearanceName;
    BOOL        _forcedColorsActive;
}

/*
    Returns the shared manager. It is made at the first read of the system appearance, which
    attaches the observers. They stay for the life of the page: the media queries belong to
    the page, not to a platform window.
*/
+ (_CPAppearanceManager)sharedManager
{
    if (!_CPAppearanceSharedManager)
        _CPAppearanceSharedManager = [[self alloc] init];

    return _CPAppearanceSharedManager;
}

- (id)init
{
    if (self = [super init])
    {
        var manager = self;

        _changeHandler = function()
        {
            [manager _mediaQueriesDidChange];
        };

        [self _observeWithMatchMediaFunction:_CPAppearanceBrowserMatchMedia()];

        _forcedColorsActive = _CPAppearanceQueryMatches(_forcedColorsQuery);
        _systemAppearanceName = [self _nameFromQueries];
    }

    return self;
}

/*
    Returns the system appearance.
*/
- (CPAppearance)systemAppearance
{
    return [CPAppearance appearanceNamed:_systemAppearanceName];
}

/*
    Returns YES when the browser forces its own colours, for the forced-colours value set of a
    theme.
*/
- (BOOL)forcedColorsActive
{
    return _forcedColorsActive;
}

/*
    Replaces the matchMedia function, attaches the observers again and reads the queries. A
    change of the system appearance reaches the application as from a change event. The unit
    tests use this to supply media query lists that they control; nil removes them.
*/
- (void)_setMatchMediaFunction:(Function)aMatchMediaFunction
{
    [self _observeWithMatchMediaFunction:aMatchMediaFunction];
    [self _mediaQueriesDidChange];
}

- (void)_observeWithMatchMediaFunction:(Function)aMatchMediaFunction
{
    _CPAppearanceStopObservingQuery(_darkQuery, _changeHandler);
    _CPAppearanceStopObservingQuery(_highContrastQuery, _changeHandler);
    _CPAppearanceStopObservingQuery(_forcedColorsQuery, _changeHandler);

    _darkQuery = aMatchMediaFunction ? aMatchMediaFunction(_CPAppearanceDarkQuery) : nil;
    _highContrastQuery = aMatchMediaFunction ? aMatchMediaFunction(_CPAppearanceHighContrastQuery) : nil;
    _forcedColorsQuery = aMatchMediaFunction ? aMatchMediaFunction(_CPAppearanceForcedColorsQuery) : nil;

    _CPAppearanceObserveQuery(_darkQuery, _changeHandler);
    _CPAppearanceObserveQuery(_highContrastQuery, _changeHandler);
    _CPAppearanceObserveQuery(_forcedColorsQuery, _changeHandler);
}

- (CPString)_nameFromQueries
{
    var isDark = _CPAppearanceQueryMatches(_darkQuery),
        isHighContrast = _CPAppearanceQueryMatches(_highContrastQuery) || _CPAppearanceQueryMatches(_forcedColorsQuery);

    return _CPAppearanceNameForSystemTraits(isDark, isHighContrast);
}

/*
    Reads the queries again. When the name changes, the application's effective appearance
    changes too, unless the application has an appearance of its own. The run loop then runs
    once, as for a DOM event, so that layout and display happen in the same turn.
*/
- (void)_mediaQueriesDidChange
{
    var name = [self _nameFromQueries];

    _forcedColorsActive = _CPAppearanceQueryMatches(_forcedColorsQuery);

    if (name === _systemAppearanceName)
        return;

    var application = (typeof CPApp !== "undefined") ? CPApp : nil,
        applicationFollowsSystem = application && ![application appearance];

    if (applicationFollowsSystem)
        [application willChangeValueForKey:@"effectiveAppearance"];

    _systemAppearanceName = name;

    if (applicationFollowsSystem)
        [application didChangeValueForKey:@"effectiveAppearance"];

    [application _systemAppearanceDidChange];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
