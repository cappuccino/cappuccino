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

- (void)testResizableWindowHasOnlyACloseButton
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0)
                                              styleMask:CPClosableWindowMask | CPResizableWindowMask],
        subviews = [[aWindow _windowView] subviews],
        count = [subviews count],
        buttonCount = 0;

    while (count--)
        if ([subviews[count] isKindOfClass:[CPButton class]])
            buttonCount++;

    [self assert:1 equals:buttonCount];
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
