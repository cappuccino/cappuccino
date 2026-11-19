/*
 *  CPBorderlessBridgeWindowViewTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-19.
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
    A window that fills its platform window draws a default background: the theme's bezel
    colour, else +[CPColor windowBackgroundColor]. A colour that the application sets stays,
    and nil returns to the default. Other windows have no default background.

    Only a browser platform window supports full platform windows, so outside the browser a
    window with CPBorderlessBridgeWindowMask keeps a standard window view. These tests
    therefore make the bridge window view directly.
*/
@implementation CPBorderlessBridgeWindowViewTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)tearDown
{
    [CPAppearance setCurrentAppearance:nil];
}

// MARK: Helpers

/*
    Returns a bridge window view that takes its values from aTheme. With a nil theme, the view
    takes a theme that gives no window view a value.
*/
- (_CPBorderlessBridgeWindowView)bridgeViewWithTheme:(CPTheme)aTheme
{
    var windowView = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:CPBorderlessBridgeWindowMask];

    [windowView setTheme:aTheme || [[CPTheme alloc] initWithName:@"CPBorderlessBridgeWindowViewTest"]];
    [self layOut:windowView];

    return windowView;
}

- (void)layOut:(CPView)aView
{
    [aView setNeedsLayout];
    [aView layoutIfNeeded];
}

/*
    Returns a theme that gives the bridge window view the bezel colour aColor.
*/
- (CPTheme)themeWithBridgeBezelColor:(CPColor)aColor
{
    var theme = [[CPTheme alloc] initWithName:@"CPBorderlessBridgeWindowViewTestBezel"],
        template = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0) styleMask:CPBorderlessBridgeWindowMask];

    [template setValue:aColor forThemeAttribute:@"bezel-color"];
    [theme takeThemeFromObject:template];

    return theme;
}

/*
    Gives aView the dark appearance. The change marks the view for layout.
*/
- (void)setDarkAppearanceOf:(CPView)aView
{
    [aView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [aView layoutIfNeeded];
}

// MARK: Default background

- (void)testABridgeWindowViewDrawsTheWindowBackgroundByDefault
{
    var windowView = [self bridgeViewWithTheme:nil];

    [self assert:[CPColor windowBackgroundColor] same:[windowView backgroundColor]];
}

/*
    The window background colour is one object whose value depends on the appearance, so the
    default stays that object when the appearance changes.
*/
- (void)testTheDefaultBackgroundFollowsAChangeOfAppearance
{
    var windowView = [self bridgeViewWithTheme:nil];

    [self setDarkAppearanceOf:windowView];

    [self assert:[CPColor windowBackgroundColor] same:[windowView backgroundColor]];
}

- (void)testTheThemeBezelColorComesBeforeTheWindowBackground
{
    var bezelColor = [CPColor colorWithRed:0.1 green:0.2 blue:0.3 alpha:1.0],
        windowView = [self bridgeViewWithTheme:[self themeWithBridgeBezelColor:bezelColor]];

    [self assert:bezelColor same:[windowView backgroundColor]];
}

- (void)testABorderlessWindowHasNoDefaultBackground
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:CPBorderlessWindowMask];

    [self assertNull:[window backgroundColor]];
}

// MARK: Colour of the window's own

- (void)testAColorOfTheWindowsOwnSurvivesLayoutAndAChangeOfAppearance
{
    var windowView = [self bridgeViewWithTheme:nil],
        color = [CPColor colorWithRed:0.4 green:0.5 blue:0.6 alpha:1.0];

    [windowView setBackgroundColor:color];
    [self layOut:windowView];

    [self assert:color same:[windowView backgroundColor] message:@"after layout"];

    [self setDarkAppearanceOf:windowView];

    [self assert:color same:[windowView backgroundColor] message:@"after a change of appearance"];
}

- (void)testNilReturnsToTheDefaultBackground
{
    var windowView = [self bridgeViewWithTheme:nil];

    [windowView setBackgroundColor:[CPColor colorWithRed:0.4 green:0.5 blue:0.6 alpha:1.0]];
    [windowView setBackgroundColor:nil];

    [self assert:[CPColor windowBackgroundColor] same:[windowView backgroundColor] message:@"after the setter"];

    [self layOut:windowView];

    [self assert:[CPColor windowBackgroundColor] same:[windowView backgroundColor] message:@"after layout"];
}

/*
    A window that shows the page behind it sets the clear colour.
*/
- (void)testTheClearColorStaysClear
{
    var windowView = [self bridgeViewWithTheme:nil];

    [windowView setBackgroundColor:[CPColor clearColor]];
    [self layOut:windowView];
    [self setDarkAppearanceOf:windowView];

    [self assert:[CPColor clearColor] same:[windowView backgroundColor]];
}

@end
