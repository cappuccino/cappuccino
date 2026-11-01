/*
 *  CPButtonBarTest.j
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
    CPButtonBar has no Cocoa counterpart. It is the strip of add, remove and action
    buttons that applications place below a table or outline view, and those buttons
    are often the only way a person can change the list above them.

    These tests run with no theme loaded. A button bar has to work whatever a theme
    chooses to define, so the class itself must supply usable buttons.
*/
@implementation CPButtonBarTest : OJTestCase
{
    CPWindow        theWindow;
    CPButtonBar     buttonBar;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];

    buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 26.0)];
    [[theWindow contentView] addSubview:buttonBar];
}

- (void)assertButtonHasStandardSize:(CPView)aButton
{
    [self assert:35.0 equals:CGRectGetWidth([aButton frame])];
    [self assert:25.0 equals:CGRectGetHeight([aButton frame])];
}

- (void)testPlusButtonHasTheStandardSize
{
    [self assertButtonHasStandardSize:[CPButtonBar plusButton]];
}

- (void)testMinusButtonHasTheStandardSize
{
    [self assertButtonHasStandardSize:[CPButtonBar minusButton]];
}

- (void)testActionPopupButtonHasTheStandardSize
{
    [self assertButtonHasStandardSize:[CPButtonBar actionPopupButton]];
}

/*
    A button must take up space in the bar and stay inside it, or a person cannot
    click it. The first button starts one point before the bar, so that its border
    falls outside the bar's edge.
*/
- (void)testLayoutPlacesEachButtonInsideTheBar
{
    var buttons = [[CPButtonBar plusButton], [CPButtonBar minusButton], [CPButtonBar actionPopupButton]];

    [buttonBar setButtons:buttons];
    [buttonBar layoutSubviews];

    buttons.forEach(function(aButton)
    {
        [self assert:buttonBar equals:[aButton superview]];
        [self assertTrue:CGRectGetWidth([aButton frame]) > 0.0];
        [self assertTrue:CGRectGetMinX([aButton frame]) >= -1.0];
        [self assertTrue:CGRectGetMaxX([aButton frame]) <= CGRectGetWidth([buttonBar bounds])];
    });
}

/*
    Adjacent buttons share a one-point border, and they overlap by no more than that.
*/
- (void)testLayoutPlacesButtonsInOrderSharingABorder
{
    var plusButton = [CPButtonBar plusButton],
        minusButton = [CPButtonBar minusButton];

    [buttonBar setButtons:[plusButton, minusButton]];
    [buttonBar layoutSubviews];

    [self assert:CGRectGetMaxX([plusButton frame]) - 1.0 equals:CGRectGetMinX([minusButton frame])];
}

/*
    A hidden button leaves no gap, and the buttons after it move up.
*/
- (void)testHidingAButtonClosesTheGap
{
    var plusButton = [CPButtonBar plusButton],
        minusButton = [CPButtonBar minusButton];

    [buttonBar setButtons:[plusButton, minusButton]];
    [buttonBar layoutSubviews];

    var firstOrigin = CGRectGetMinX([plusButton frame]);

    [plusButton setHidden:YES];
    [buttonBar layoutSubviews];

    [self assert:firstOrigin equals:CGRectGetMinX([minusButton frame])];
}

- (void)testRightButtonsAreAlignedToTheRightEdge
{
    var button = [CPButtonBar plusButton];

    [buttonBar setRightButtons:[button]];
    [buttonBar layoutSubviews];

    [self assert:buttonBar equals:[button superview]];
    [self assertTrue:CGRectGetWidth([button frame]) > 0.0];
    [self assertTrue:CGRectGetMaxX([button frame]) >= CGRectGetWidth([buttonBar bounds]) - 1.0];
}

/*
    Applications add their own buttons to a bar, so any button is acceptable, not
    only those the class creates.
*/
- (void)testAnApplicationButtonCanBeAdded
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 35.0, 25.0)];

    [buttonBar setButtons:[button]];
    [buttonBar layoutSubviews];

    [self assert:[button] equals:[buttonBar buttons]];
    [self assert:buttonBar equals:[button superview]];
}

@end
