/*
 *  CPApplicationAppearanceTest.j
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
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

/*
    Gives the manager a media query for dark mode that the test controls.
*/
function CPApplicationAppearanceTestDarkMedia(isDark)
{
    var list = { media: "(prefers-color-scheme: dark)", matches: isDark, handlers: [] };

    list.addEventListener = function(aType, aHandler) { list.handlers.push(aHandler); };
    list.removeEventListener = function(aType, aHandler) { };

    return {
        matchMedia: function(aQuery)
        {
            return aQuery === list.media ? list : { media: aQuery, matches: false };
        },
        setDark: function(shouldBeDark)
        {
            list.matches = shouldBeDark;

            for (var i = 0; i < list.handlers.length; i++)
                list.handlers[i]({ media: list.media, matches: shouldBeDark });
        }
    };
}

@implementation CPApplicationAppearanceTestView : CPView
{
    int     hookCount;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
        hookCount = 0;

    return self;
}

- (void)viewDidChangeEffectiveAppearance
{
    hookCount++;
}

@end

@implementation CPApplicationAppearanceTest : OJTestCase
{
    CPArray     observedValues;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    observedValues = [];
}

- (void)tearDown
{
    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:nil];
    [CPApp setAppearance:nil];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [observedValues addObject:[aChange objectForKey:CPKeyValueChangeNewKey]];
}

- (CPApplicationAppearanceTestView)viewInWindow
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 200.0) styleMask:CPWindowNotSizable],
        view = [[CPApplicationAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];

    [[window contentView] addSubview:view];

    return view;
}

- (void)testWithoutAnAppearanceTheApplicationTakesTheSystemAppearance
{
    var manager = [_CPAppearanceManager sharedManager];

    [self assert:[manager systemAppearance] same:[CPApp effectiveAppearance]];

    [manager _setMatchMediaFunction:CPApplicationAppearanceTestDarkMedia(YES).matchMedia];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua] same:[CPApp effectiveAppearance]];
    [self assertNull:[CPApp appearance]];
}

- (void)testTheApplicationAppearanceWinsOverTheSystem
{
    var vibrantDark = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark];

    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:CPApplicationAppearanceTestDarkMedia(YES).matchMedia];

    [CPApp setAppearance:vibrantDark];
    [self assert:vibrantDark same:[CPApp appearance]];
    [self assert:vibrantDark same:[CPApp effectiveAppearance]];

    [CPApp setAppearance:nil];
    [self assertNull:[CPApp appearance]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua] same:[CPApp effectiveAppearance]];
}

- (void)testASystemChangeReachesAViewInAWindow
{
    var media = CPApplicationAppearanceTestDarkMedia(NO),
        view = [self viewInWindow];

    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:media.matchMedia];
    view.hookCount = 0;

    media.setDark(YES);

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua] same:[view effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceDarkAqua]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceAqua]];
    [self assert:1 equals:view.hookCount];
}

- (void)testASystemChangeChangesNothingWhileTheApplicationHasAnAppearance
{
    var media = CPApplicationAppearanceTestDarkMedia(NO),
        view = [self viewInWindow];

    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:media.matchMedia];
    [CPApp setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameAqua]];
    view.hookCount = 0;

    media.setDark(YES);

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameAqua] same:[view effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceAqua]];
    [self assert:0 equals:view.hookCount];
}

- (void)testAnObserverOfTheEffectiveAppearanceReceivesTheNewValue
{
    var media = CPApplicationAppearanceTestDarkMedia(NO),
        vibrantLight = [CPAppearance appearanceNamed:CPAppearanceNameVibrantLight];

    [[_CPAppearanceManager sharedManager] _setMatchMediaFunction:media.matchMedia];
    [CPApp addObserver:self forKeyPath:@"effectiveAppearance" options:CPKeyValueObservingOptionNew context:nil];

    try
    {
        media.setDark(YES);
        [CPApp setAppearance:vibrantLight];
    }
    finally
    {
        [CPApp removeObserver:self forKeyPath:@"effectiveAppearance"];
    }

    [self assert:[[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua], vibrantLight] equals:observedValues];
}

@end
