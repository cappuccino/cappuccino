/*
 *  CPPopoverAppearanceTest.j
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

@import <AppKit/AppKit.j>
@import <AppKit/CPPopover.j>

@implementation CPPopoverAppearanceTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (CPAppearance)appearance:(CPString)aName
{
    return [CPAppearance appearanceNamed:aName];
}

- (void)testTheDefaultIsMinimalAndVibrantLight
{
    var popover = [[CPPopover alloc] init];

    [self assert:CPPopoverAppearanceMinimal equals:[popover appearance]];
    [self assert:[self appearance:CPAppearanceNameVibrantLight] same:[popover effectiveAppearance]];
}

- (void)testTheLegacyHUDValueGivesVibrantDark
{
    var popover = [[CPPopover alloc] init];

    [popover setAppearance:CPPopoverAppearanceHUD];

    [self assert:CPPopoverAppearanceHUD equals:[popover appearance]];
    [self assert:[self appearance:CPAppearanceNameVibrantDark] same:[popover effectiveAppearance]];

    [popover setAppearance:nil];

    [self assertNull:[popover appearance]];
    [self assert:[self appearance:CPAppearanceNameVibrantLight] same:[popover effectiveAppearance]];
}

- (void)testAnAppearanceObjectIsReturnedByBothGetters
{
    var popover = [[CPPopover alloc] init],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [popover setAppearance:darkAqua];

    [self assert:darkAqua same:[popover appearance]];
    [self assert:darkAqua same:[popover effectiveAppearance]];
}

/*
    A unit test cannot show a popover: the initialiser of _CPPopoverWindow reads
    CPBrowserStyleProperty, which creates a DOM element. The test puts a plain window in the
    place of the popover window, and checks the path from the popover through its window to
    its views. The manual test CPAppearanceTest shows popovers.
*/
- (void)testAPopoverGivesItsAppearanceToItsWindowAndViews
{
    var popover = [[CPPopover alloc] init],
        popoverWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 100.0, 80.0) styleMask:CPBorderlessWindowMask],
        contentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 80.0)],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark],
        vibrantLight = [self appearance:CPAppearanceNameVibrantLight];

    [popoverWindow setContentView:contentView];
    popover._popoverWindow = popoverWindow;

    [popover setAppearance:CPPopoverAppearanceHUD];

    [self assert:vibrantDark same:[popoverWindow appearance]];
    [self assert:vibrantDark same:[[popoverWindow _windowView] effectiveAppearance]];
    [self assert:vibrantDark same:[contentView effectiveAppearance]];
    [self assertTrue:[contentView hasThemeState:CPThemeStateAppearanceVibrantDark]];

    [popover setAppearance:CPPopoverAppearanceMinimal];

    [self assert:vibrantLight same:[popoverWindow appearance]];
    [self assert:vibrantLight same:[contentView effectiveAppearance]];
    [self assertTrue:[contentView hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[contentView hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testTheLegacyIntegerArchiveIsUnchanged
{
    var popover = [[CPPopover alloc] init];

    [popover setAppearance:CPPopoverAppearanceHUD];

    var data = [CPKeyedArchiver archivedDataWithRootObject:popover],
        archive = [data rawString],
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    [self assertTrue:archive.indexOf(@"CPPopoverAppearanceKey") !== -1 message:@"The integer keeps its key"];
    [self assertTrue:archive.indexOf(@"CPPopoverAppearanceObjectKey") === -1 message:@"An integer writes no appearance object"];
    [self assert:CPPopoverAppearanceHUD equals:[decoded appearance]];
}

- (void)testAnAppearanceObjectSurvivesAnArchiveRoundTrip
{
    var popover = [[CPPopover alloc] init],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [popover setAppearance:darkAqua];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:popover]];

    [self assert:darkAqua same:[decoded appearance]];
    [self assert:darkAqua same:[decoded effectiveAppearance]];
}

@end
