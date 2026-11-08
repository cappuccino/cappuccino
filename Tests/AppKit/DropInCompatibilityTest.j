/*
 *  DropInCompatibilityTest.j
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

function DropInWindowButton(aStyleMask, aName)
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:aStyleMask],
        windowView = [aWindow _windowView];

    return windowView[aName];
}

/*
    Defaults that existing applications rely on. An application that updates its
    frameworks must keep these without any change of its own.
*/
@implementation DropInCompatibilityTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)testDefaultThemeNameIsAristo2WithoutInfoPlistKey
{
    [self assertNull:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPDefaultTheme"]];
    [self assert:@"Aristo2" equals:[CPApplication defaultThemeName]];
}

/*
    Window buttons follow Apple's guidelines under every theme, as a deliberate change
    to the drop-in contract: a standard titled window shows close, minimize and zoom,
    and enables each only when its style mask allows it. Until 2026-11, a window showed
    only the buttons its style mask allowed.
*/
- (void)testStandardTitledWindowShowsCloseMinimizeAndZoom
{
    [CPTitledWindowMask,
     CPTitledWindowMask | CPClosableWindowMask,
     CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask,
     CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask].forEach(function(aStyleMask)
    {
        [@"_closeButton", @"_minimizeButton", @"_zoomButton"].forEach(function(aName)
        {
            [self assertNotNull:DropInWindowButton(aStyleMask, aName) message:aName + ", style mask " + aStyleMask];
        });
    });
}

- (void)testCloseButtonIsEnabledOnlyForAClosableWindow
{
    [self assertTrue:[DropInWindowButton(CPTitledWindowMask | CPClosableWindowMask, @"_closeButton") isEnabled]];
    [self assertFalse:[DropInWindowButton(CPTitledWindowMask, @"_closeButton") isEnabled]];
}

- (void)testMinimizeButtonIsEnabledOnlyForAMiniaturizableWindow
{
    [self assertTrue:[DropInWindowButton(CPTitledWindowMask | CPMiniaturizableWindowMask, @"_minimizeButton") isEnabled]];
    [self assertFalse:[DropInWindowButton(CPTitledWindowMask | CPClosableWindowMask, @"_minimizeButton") isEnabled]];
}

- (void)testZoomButtonIsEnabledOnlyForAResizableWindow
{
    [self assertTrue:[DropInWindowButton(CPTitledWindowMask | CPResizableWindowMask, @"_zoomButton") isEnabled]];
    [self assertFalse:[DropInWindowButton(CPTitledWindowMask | CPClosableWindowMask, @"_zoomButton") isEnabled]];
}

- (void)testPopUpButtonKeepsTheDefaultButtonBezelStyle
{
    var frame = CGRectMake(0.0, 0.0, 100.0, 24.0),
        popUpButton = [[CPPopUpButton alloc] initWithFrame:frame pullsDown:NO],
        button = [[CPButton alloc] initWithFrame:frame];

    [self assert:[button bezelStyle] equals:[popUpButton bezelStyle]];
}

- (void)testTableViewGridColorHasAClassDefault
{
    [self assertFalse:[[[CPTableView themeAttributes] objectForKey:@"grid-color"] isEqual:[CPNull null]]];
}

- (void)testTableViewAlternatingRowColorsHaveAClassDefault
{
    [self assertFalse:[[[CPTableView themeAttributes] objectForKey:@"alternating-row-colors"] isEqual:[CPNull null]]];
}

@end
