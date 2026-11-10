/*
 *  CPVisualEffectViewTest.j
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
@import <AppKit/CPVisualEffectView.j>

@implementation CPVisualEffectViewTest : OJTestCase
{
    CPWindow    window;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask];
}

- (void)tearDown
{
    [CPApp setAppearance:nil];
}

- (CPVisualEffectView)effectView
{
    return [[CPVisualEffectView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
}

/*
    Returns the background colour that anEffectView takes when it lays out below a parent
    with the appearance named aName.
*/
- (CPColor)backgroundColorOf:(CPVisualEffectView)anEffectView belowParentNamed:(CPString)aName
{
    var parent = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    [parent setAppearance:[CPAppearance appearanceNamed:aName]];
    [parent addSubview:anEffectView];
    [[window contentView] addSubview:parent];

    [anEffectView setNeedsLayout];
    [anEffectView layoutIfNeeded];

    return [anEffectView backgroundColor];
}

- (void)testAnyAppearanceIsAccepted
{
    var view = [self effectView];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameAqua]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameAqua] same:[view appearance]];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua] same:[view appearance]];

    [view setAppearance:nil];
    [self assertNull:[view appearance]];
}

- (void)testAViewMadeInCodeHasVibrantDark
{
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] same:[[self effectView] appearance]];
}

- (void)testWithoutAnAppearanceTheViewFollowsItsParent
{
    var darkView = [self effectView],
        lightView = [self effectView];

    [darkView setAppearance:nil];
    [lightView setAppearance:nil];

    [self assertTrue:[[self backgroundColorOf:darkView belowParentNamed:CPAppearanceNameDarkAqua] isEqual:[CPColor colorWithHexString:@"1e1e1e"]]];
    [self assertTrue:[[self backgroundColorOf:lightView belowParentNamed:CPAppearanceNameAqua] isEqual:[CPColor whiteColor]]];
}

- (void)testAViewArchivedWithoutAnAppearanceDecodes
{
    var view = [self effectView],
        decoded = nil;

    [view setAppearance:nil];

    [self assertNoThrow:function()
    {
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]];
    }];

    [self assertNull:[decoded appearance]];
}

@end
