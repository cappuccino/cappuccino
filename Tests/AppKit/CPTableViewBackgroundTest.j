/*
 *  CPTableViewBackgroundTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-12.
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
    A table view's background is the application's colour when it has one. Without one, it
    is the theme's background colour in the table view's current state, else the control
    background colour, AppKit's default. The source-list style sets the source-list
    background, as in AppKit.
*/
@implementation CPTableViewBackgroundTest : OJTestCase
{
    CPWindow        theWindow;
    CPTableView     tableView;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];
    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    [tableView addTableColumn:[[CPTableColumn alloc] initWithIdentifier:@"Column"]];
    [[theWindow contentView] addSubview:tableView];
}

/*
    Returns a theme that gives a table view aColor as its background colour, and aHUDColor
    in the HUD state. A nil colour gives no value.
*/
- (CPTheme)themeWithBackgroundColor:(CPColor)aColor HUDBackgroundColor:(CPColor)aHUDColor
{
    var template = [[CPTableView alloc] initWithFrame:CGRectMakeZero()],
        theme = [[CPTheme alloc] initWithName:@"CPTableViewBackgroundTestTheme"];

    if (aColor)
        [template setValue:aColor forThemeAttribute:@"background-color"];

    if (aHUDColor)
        [template setValue:aHUDColor forThemeAttribute:@"background-color" inState:CPThemeStateHUD];

    [theme takeThemeFromObject:template];

    return theme;
}

/*
    Gives aTableView aTheme and lays it out, as the display cycle does after a change of
    theme.
*/
- (void)setTheme:(CPTheme)aTheme ofTableView:(CPTableView)aTableView
{
    [aTableView setTheme:aTheme];
    [aTableView layoutIfNeeded];
}

- (void)testWithoutAColourOfItsOwnATableViewTakesTheThemeBackground
{
    var red = [CPColor redColor];

    [self setTheme:[self themeWithBackgroundColor:red HUDBackgroundColor:nil] ofTableView:tableView];

    [self assert:red same:[tableView backgroundColor]];
}

- (void)testWithoutAThemeBackgroundATableViewTakesTheControlBackgroundColor
{
    [self setTheme:[self themeWithBackgroundColor:nil HUDBackgroundColor:nil] ofTableView:tableView];

    [self assert:[CPColor controlBackgroundColor] same:[tableView backgroundColor]];
}

- (void)testTheThemeBackgroundFollowsTheThemeState
{
    var red = [CPColor redColor],
        blue = [CPColor blueColor];

    [self setTheme:[self themeWithBackgroundColor:red HUDBackgroundColor:blue] ofTableView:tableView];

    [tableView setThemeState:CPThemeStateHUD];
    [tableView layoutIfNeeded];
    [self assert:blue same:[tableView backgroundColor] message:@"HUD state"];

    [tableView unsetThemeState:CPThemeStateHUD];
    [tableView layoutIfNeeded];
    [self assert:red same:[tableView backgroundColor] message:@"normal state"];
}

- (void)testAColourOfItsOwnStaysInEachThemeState
{
    var green = [CPColor greenColor];

    [self setTheme:[self themeWithBackgroundColor:[CPColor redColor] HUDBackgroundColor:[CPColor blueColor]] ofTableView:tableView];
    [tableView setBackgroundColor:green];

    [tableView setThemeState:CPThemeStateHUD];
    [tableView layoutIfNeeded];
    [self assert:green same:[tableView backgroundColor] message:@"HUD state"];

    [tableView setThemeState:CPThemeStateKeyWindow];
    [tableView layoutIfNeeded];
    [self assert:green same:[tableView backgroundColor] message:@"key window state"];

    [tableView unsetThemeState:CPThemeStateHUD];
    [tableView unsetThemeState:CPThemeStateKeyWindow];
    [tableView layoutIfNeeded];
    [self assert:green same:[tableView backgroundColor] message:@"normal state"];
}

- (void)testANilColourGivesTheDefaultBackgroundAgain
{
    var red = [CPColor redColor],
        blue = [CPColor blueColor];

    [self setTheme:[self themeWithBackgroundColor:red HUDBackgroundColor:blue] ofTableView:tableView];
    [tableView setBackgroundColor:[CPColor greenColor]];
    [tableView setBackgroundColor:nil];

    [self assert:red same:[tableView backgroundColor] message:@"normal state"];

    [tableView setThemeState:CPThemeStateHUD];
    [tableView layoutIfNeeded];
    [self assert:blue same:[tableView backgroundColor] message:@"HUD state"];
}

- (void)testTheSourceListStyleSetsTheSourceListBackground
{
    var sourceListColor = [CPColor colorWithCatalogName:@"System" colorName:@"_sourceListBackgroundColor"];

    [self setTheme:[self themeWithBackgroundColor:[CPColor redColor] HUDBackgroundColor:[CPColor blueColor]] ofTableView:tableView];
    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];

    [self assert:sourceListColor same:[tableView backgroundColor] message:@"normal state"];

    [tableView setThemeState:CPThemeStateHUD];
    [tableView layoutIfNeeded];
    [self assert:sourceListColor same:[tableView backgroundColor] message:@"HUD state"];
}

- (void)testAColourSetAfterTheSourceListStyleReplacesTheSourceListBackground
{
    var green = [CPColor greenColor];

    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [tableView setBackgroundColor:green];

    [self assert:green same:[tableView backgroundColor]];
}

- (void)testADecodedTableViewTakesTheDefaultBackgroundFromItsTheme
{
    var yellow = [CPColor yellowColor];

    [self setTheme:[self themeWithBackgroundColor:[CPColor redColor] HUDBackgroundColor:nil] ofTableView:tableView];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:tableView]];

    [self setTheme:[self themeWithBackgroundColor:yellow HUDBackgroundColor:nil] ofTableView:decoded];

    [self assert:yellow equals:[decoded backgroundColor]];
}

- (void)testADecodedTableViewKeepsItsOwnColour
{
    [self setTheme:[self themeWithBackgroundColor:[CPColor redColor] HUDBackgroundColor:nil] ofTableView:tableView];
    [tableView setBackgroundColor:[CPColor greenColor]];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:tableView]];

    [self setTheme:[self themeWithBackgroundColor:[CPColor yellowColor] HUDBackgroundColor:nil] ofTableView:decoded];

    [self assert:[CPColor greenColor] equals:[decoded backgroundColor]];
}

@end
