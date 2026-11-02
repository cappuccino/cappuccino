/*
 *  CPViewThemeChangeTest.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
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
    A view resolves each theme attribute from its own values, then its theme, then its
    class default. When any of these changes, the view must resolve the new value and
    lay itself out again. These tests build small themes in code, so they depend on no
    real theme.
*/

@implementation _CPThemeChangeView : CPView
{
    int     layoutCount @accessors;
    int     themeChangeCount @accessors;
    int     displayRequestCount @accessors;
}

+ (CPString)defaultThemeClass
{
    return @"theme-change-view";
}

+ (CPDictionary)themeAttributes
{
    return @{
        @"accent": @"class default",
        @"margin": @"class default"
    };
}

- (void)layoutSubviews
{
    layoutCount++;
}

/*
    needsDisplay is true only for a view with its own drawRect:, so the request is
    recorded here.
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    if (aFlag)
        displayRequestCount++;

    [super setNeedsDisplay:aFlag];
}

- (void)objectDidChangeTheme
{
    themeChangeCount++;

    [super objectDidChangeTheme];
}

@end

@implementation CPViewThemeChangeTest : OJTestCase
{
    CPTheme                 firstTheme;
    CPTheme                 secondTheme;
    CPTheme                 defaultTheme;
    _CPThemeChangeView      view;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    defaultTheme = [CPTheme defaultTheme];
    firstTheme = [self themeNamed:@"theme-change-first" themeClass:nil accent:@"first"];
    secondTheme = [self themeNamed:@"theme-change-second" themeClass:nil accent:@"second"];
    view = [self newView];

    [view setTheme:firstTheme];
    [_CPDisplayServer run];
    [view setLayoutCount:0];
    [view setThemeChangeCount:0];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:defaultTheme];
}

- (_CPThemeChangeView)newView
{
    return [[_CPThemeChangeView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
}

- (CPTheme)themeNamed:(CPString)aName themeClass:(CPString)aThemeClass accent:(CPString)anAccent
{
    var theme = [[CPTheme alloc] initWithName:aName],
        template = [self newView];

    if (aThemeClass)
        [template setThemeClass:aThemeClass];

    [template setValue:anAccent forThemeAttribute:@"accent"];
    [theme takeThemeFromObject:template];

    return theme;
}

- (id)archived:(CPView)aView
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:aView]];
}

- (void)assertAccent:(CPString)aValue ofView:(CPView)aView
{
    [self assert:aValue equals:[aView currentValueForThemeAttribute:@"accent"]];
}

- (void)testAViewResolvesItsThemeValue
{
    [self assertAccent:@"first" ofView:view];
}

- (void)testAnAttributeTheThemeDoesNotDefineUsesTheClassDefault
{
    [self assert:@"class default" equals:[view currentValueForThemeAttribute:@"margin"]];
}

- (void)testAViewWithoutAThemeUsesTheClassDefault
{
    [view setTheme:nil];

    [self assertAccent:@"class default" ofView:view];
}

- (void)testSettingAThemeChangesTheResolvedValue
{
    [view setTheme:secondTheme];

    [self assertAccent:@"second" ofView:view];
}

- (void)testSettingAThemeNotifiesTheView
{
    [view setTheme:secondTheme];

    [self assert:1 equals:[view themeChangeCount]];
}

- (void)testSettingTheSameThemeDoesNothing
{
    [view setTheme:firstTheme];

    [self assert:0 equals:[view themeChangeCount]];
}

- (void)testSettingAThemeQueuesLayout
{
    [view setTheme:secondTheme];
    [_CPDisplayServer run];

    [self assert:1 equals:[view layoutCount]];
}

- (void)testSettingAThemeRequestsDisplay
{
    [view setDisplayRequestCount:0];
    [view setTheme:secondTheme];

    [self assertTrue:[view displayRequestCount] > 0];
}

- (void)testAThemeChangeReachesNestedViews
{
    var parent = [self newView],
        child = [self newView],
        grandchild = [self newView];

    [parent addSubview:child];
    [child addSubview:grandchild];
    [parent _setThemeIncludingDescendants:secondTheme];

    [self assertAccent:@"second" ofView:parent];
    [self assertAccent:@"second" ofView:child];
    [self assertAccent:@"second" ofView:grandchild];
}

- (void)testAPerViewValueTakesPriorityOverTheTheme
{
    [view setValue:@"own" forThemeAttribute:@"accent"];

    [self assertAccent:@"own" ofView:view];
}

- (void)testAPerViewValueSurvivesAThemeChange
{
    [view setValue:@"own" forThemeAttribute:@"accent"];
    [view setTheme:secondTheme];

    [self assertAccent:@"own" ofView:view];
}

- (void)testAPerViewValueQueuesLayout
{
    [view setValue:@"own" forThemeAttribute:@"accent"];
    [_CPDisplayServer run];

    [self assert:1 equals:[view layoutCount]];
}

- (void)testSettingTheSamePerViewValueQueuesNoLayout
{
    [view setValue:@"first" forThemeAttribute:@"accent"];
    [_CPDisplayServer run];

    [self assert:0 equals:[view layoutCount]];
}

- (void)testAStateSelectsItsValue
{
    [view setValue:@"disabled" forThemeAttribute:@"accent" inState:CPThemeStateDisabled];
    [self assertAccent:@"first" ofView:view];

    [view setThemeState:CPThemeStateDisabled];
    [self assertAccent:@"disabled" ofView:view];

    [view unsetThemeState:CPThemeStateDisabled];
    [self assertAccent:@"first" ofView:view];
}

- (void)testAStateChangeQueuesLayout
{
    [view setThemeState:CPThemeStateDisabled];
    [_CPDisplayServer run];

    [self assert:1 equals:[view layoutCount]];
}

- (void)testSettingAThemeClassChangesTheResolvedValue
{
    var theme = [self themeNamed:@"theme-change-class" themeClass:@"other-class" accent:@"other class"];

    [view setTheme:theme];
    [view setThemeClass:@"other-class"];

    [self assertAccent:@"other class" ofView:view];
}

- (void)testSettingAThemeClassQueuesLayout
{
    [view setThemeClass:@"other-class"];
    [_CPDisplayServer run];

    [self assert:1 equals:[view layoutCount]];
}

- (void)testANewViewUsesTheDefaultTheme
{
    [CPTheme setDefaultTheme:secondTheme];

    [self assertAccent:@"second" ofView:[self newView]];
}

- (void)testChangingTheDefaultThemeLeavesAnExistingViewUnchanged
{
    [CPTheme setDefaultTheme:secondTheme];

    [self assertAccent:@"first" ofView:view];
}

- (void)testADecodedViewUsesTheDefaultTheme
{
    [CPTheme setDefaultTheme:secondTheme];

    [self assertAccent:@"second" ofView:[self archived:view]];
}

- (void)testADecodedViewKeepsAPerViewValue
{
    [view setValue:@"own" forThemeAttribute:@"accent"];

    [self assertAccent:@"own" ofView:[self archived:view]];
}

- (void)testADecodedViewKeepsAPerViewStateValue
{
    [view setValue:@"disabled" forThemeAttribute:@"accent" inState:CPThemeStateDisabled];

    var decoded = [self archived:view];

    [decoded setThemeState:CPThemeStateDisabled];

    [self assertAccent:@"disabled" ofView:decoded];
}

- (void)testADecodedViewKeepsItsThemeState
{
    [view setThemeState:CPThemeStateDisabled];

    [self assertTrue:[[self archived:view] hasThemeState:CPThemeStateDisabled]];
}

- (void)testADecodedViewKeepsItsThemeClass
{
    [view setThemeClass:@"other-class"];

    [self assert:@"other-class" equals:[[self archived:view] themeClass]];
}

@end
