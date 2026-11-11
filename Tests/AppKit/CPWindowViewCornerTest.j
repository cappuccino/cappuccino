/*
 *  CPWindowViewCornerTest.j
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

@implementation CPWindowViewCornerTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (CPWindow)window
{
    return [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:CPTitledWindowMask];
}

- (void)testAnInnerCornerHasTheOuterRadiusLessEachInset
{
    [self assert:@"max(0px, 7px - 1px) max(0px, 7px - 2px)" equals:_CPWindowViewInnerCornerRadius(@"7px", 1, 2)];
}

- (void)testAnEmptyOuterRadiusGivesNoInnerRadius
{
    [self assert:@"" equals:_CPWindowViewInnerCornerRadius(@"", 1, 1)];
    [self assert:@"" equals:_CPWindowViewInnerCornerRadius(nil, 1, 1)];
}

- (void)testAFrameBorderCornerHasTheOuterRadiusPlusTheWidth
{
    [self assert:@"calc(7px + 1px)" equals:_CPWindowViewFrameBorderRadius(@"7px", 1)];
    [self assert:@"calc(0px + 1px)" equals:_CPWindowViewFrameBorderRadius(@"", 1)];
}

- (void)testASheetTakesTheFrameShapeOfADocumentModalWindow
{
    var parent = [self window],
        sheet = [self window],
        windowView = [sheet _windowView];

    [self assert:[windowView class] same:[windowView _frameClass] message:@"A window takes the frame shape of its own window view class"];

    [windowView _enableSheet:YES inWindow:parent];

    [self assert:_CPDocModalWindowView same:[windowView _frameClass] message:@"A sheet takes the frame shape of a document-modal window"];

    [windowView _enableSheet:NO inWindow:parent];

    [self assert:[windowView class] same:[windowView _frameClass] message:@"A former sheet takes its own frame shape again"];
}

/*
    The subview frame has the insets left 1, top 30, right 2 and bottom 4. Each corner of the
    subview takes the insets of its own two sides.
*/
- (void)testEachSubviewCornerTakesTheInsetsOfItsOwnSides
{
    var windowView = [[self window] _windowView],
        bounds = [windowView bounds],
        frame = CGRectMake(1.0, 30.0, CGRectGetWidth(bounds) - 3.0, CGRectGetHeight(bounds) - 34.0),
        radii = [windowView _cornerRadii],
        subviewRadii = [windowView _cornerRadiiForSubviewFrame:frame];

    [self assert:_CPWindowViewInnerCornerRadius(radii.topLeft, 1, 30) equals:subviewRadii.topLeft];
    [self assert:_CPWindowViewInnerCornerRadius(radii.topRight, 2, 30) equals:subviewRadii.topRight];
    [self assert:_CPWindowViewInnerCornerRadius(radii.bottomLeft, 1, 4) equals:subviewRadii.bottomLeft];
    [self assert:_CPWindowViewInnerCornerRadius(radii.bottomRight, 2, 4) equals:subviewRadii.bottomRight];
}

- (void)testTheWindowViewRoundsTheCornersOfTheCurrentContentView
{
    var window = [self window],
        windowView = [window _windowView],
        contentView = [window contentView],
        otherView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [windowView layoutIfNeeded];

    [self assert:contentView same:windowView._cornerClippedView message:@"The first layout rounds the content view"];

    [window setContentView:otherView];

    [self assertNull:windowView._cornerClippedView message:@"The old content view loses its corners when it leaves the window view"];
    [self assertTrue:[windowView needsLayout] message:@"A new content view marks the window view for layout"];

    [windowView layoutIfNeeded];

    [self assert:otherView same:windowView._cornerClippedView message:@"The next layout rounds the new content view"];
}

@end
