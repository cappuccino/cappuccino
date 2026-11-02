/*
 *  CPViewThemeStateTest.j
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
    A theme value is chosen by the state of a view, so a view with the wrong state
    draws wrongly with a correct theme. These tests check that the states that depend
    on a view's surroundings stay correct as views enter and leave windows and as
    windows change. The states are the key window state, the first responder state
    and the appearance states. Only a window's own window view has the main window
    state.

    These tests run with no theme loaded. They check the states, and not what a theme
    does with them.
*/

@implementation _CPThemeStateRecordingView : CPView
{
    CPArray     calls @accessors;
    BOOL        hadKeyStateOnArrival @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        calls = [];

    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)viewWillMoveToWindow:(CPWindow)aWindow
{
    calls.push({ @"call": @"willMove", @"from": [self window], @"to": aWindow });
}

- (void)viewDidMoveToWindow
{
    hadKeyStateOnArrival = [self hasThemeState:CPThemeStateKeyWindow];
    calls.push({ @"call": @"didMove", @"window": [self window] });
}

@end

@implementation CPViewThemeStateTest : OJTestCase
{
    CPWindow                        firstWindow;
    CPWindow                        secondWindow;
    _CPThemeStateRecordingView      parentView;
    _CPThemeStateRecordingView      childView;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    firstWindow = [self newWindow];
    secondWindow = [self newWindow];

    parentView = [[_CPThemeStateRecordingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    childView = [[_CPThemeStateRecordingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];

    [parentView addSubview:childView];
}

- (CPWindow)newWindow
{
    return [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 200.0) styleMask:CPTitledWindowMask];
}

- (void)assertKeyState:(BOOL)shouldHaveState
{
    [self assert:shouldHaveState equals:[parentView hasThemeState:CPThemeStateKeyWindow] message:@"parent view"];
    [self assert:shouldHaveState equals:[childView hasThemeState:CPThemeStateKeyWindow] message:@"child view"];
}

- (void)assertFirstResponderState:(BOOL)shouldHaveState
{
    [self assert:shouldHaveState equals:[parentView hasThemeState:CPThemeStateFirstResponder] message:@"parent view"];
    [self assert:shouldHaveState equals:[childView hasThemeState:CPThemeStateFirstResponder] message:@"child view"];
}

- (void)clearCalls
{
    [parentView setCalls:[]];
    [childView setCalls:[]];
}

// MARK: Key window state

- (void)testAViewOutsideAWindowHasNoKeyState
{
    [self assertKeyState:NO];
}

- (void)testBecomingKeyReachesNestedViews
{
    [[firstWindow contentView] addSubview:parentView];
    [self assertKeyState:NO];

    [firstWindow makeKeyWindow];
    [self assertKeyState:YES];
}

- (void)testResigningKeyReachesNestedViews
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeKeyWindow];
    [firstWindow resignKeyWindow];

    [self assertKeyState:NO];
}

- (void)testAnotherWindowBecomingKeyClearsTheState
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeKeyWindow];
    [secondWindow makeKeyWindow];

    [self assertKeyState:NO];
}

- (void)testAViewAddedToAKeyWindowGainsTheState
{
    [firstWindow makeKeyWindow];
    [[firstWindow contentView] addSubview:parentView];

    [self assertKeyState:YES];
}

- (void)testAViewAddedBelowAViewInAKeyWindowGainsTheState
{
    var lateView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeKeyWindow];
    [childView addSubview:lateView];

    [self assertTrue:[lateView hasThemeState:CPThemeStateKeyWindow]];
}

- (void)testAViewRemovedFromAKeyWindowLosesTheState
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeKeyWindow];
    [parentView removeFromSuperview];

    [self assertKeyState:NO];
}

- (void)testMovingToANonKeyWindowClearsTheState
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeKeyWindow];
    [[secondWindow contentView] addSubview:parentView];

    [self assertKeyState:NO];
}

- (void)testMovingToAKeyWindowSetsTheState
{
    [[firstWindow contentView] addSubview:parentView];
    [secondWindow makeKeyWindow];
    [[secondWindow contentView] addSubview:parentView];

    [self assertKeyState:YES];
}

- (void)testANewContentViewGainsTheState
{
    [firstWindow makeKeyWindow];
    [firstWindow setContentView:parentView];

    [self assertKeyState:YES];
}

- (void)testTheStateIsCorrectInViewDidMoveToWindow
{
    [firstWindow makeKeyWindow];
    [[firstWindow contentView] addSubview:parentView];

    [self assertTrue:[parentView hadKeyStateOnArrival]];
    [self assertTrue:[childView hadKeyStateOnArrival]];
}

// MARK: Window view

/*
    A window must be visible to become main, and ordering a window front needs a DOM.
    So this test sends becomeMainWindow directly, and it does not cover makeMainWindow.
*/
- (void)testTheWindowViewFollowsKeyAndMainStatus
{
    var windowView = [firstWindow _windowView];

    [firstWindow makeKeyWindow];
    [firstWindow becomeMainWindow];

    [self assertTrue:[windowView hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[windowView hasThemeState:CPThemeStateMainWindow]];

    [firstWindow resignKeyWindow];
    [firstWindow resignMainWindow];

    [self assertFalse:[windowView hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[windowView hasThemeState:CPThemeStateMainWindow]];
}

// MARK: First responder state

- (void)testBecomingFirstResponderReachesNestedViews
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeFirstResponder:parentView];

    [self assertFirstResponderState:YES];
}

- (void)testResigningFirstResponderReachesNestedViews
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeFirstResponder:parentView];
    [firstWindow makeFirstResponder:nil];

    [self assertFirstResponderState:NO];
}

- (void)testAViewAddedBelowTheFirstResponderGainsTheState
{
    var lateView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeFirstResponder:parentView];
    [childView addSubview:lateView];

    [self assertTrue:[lateView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testRemovingTheFirstResponderClearsTheState
{
    [[firstWindow contentView] addSubview:parentView];
    [firstWindow makeFirstResponder:parentView];
    [parentView removeFromSuperview];

    [self assertFirstResponderState:NO];
    [self assertFalse:[firstWindow firstResponder] === parentView];
}

// MARK: Window notifications

- (void)testEnteringAWindowNotifiesEachViewInOrder
{
    [[firstWindow contentView] addSubview:parentView];

    [parentView, childView].forEach(function(aView)
    {
        var calls = [aView calls];

        [self assert:2 equals:calls.length];
        [self assert:@"willMove" equals:calls[0].call];
        [self assert:firstWindow equals:calls[0].to];
        [self assertNull:calls[0].from];
        [self assert:@"didMove" equals:calls[1].call];
        [self assert:firstWindow equals:calls[1].window];
    });
}

- (void)testLeavingAWindowNotifiesEachView
{
    [[firstWindow contentView] addSubview:parentView];
    [self clearCalls];
    [parentView removeFromSuperview];

    [parentView, childView].forEach(function(aView)
    {
        var calls = [aView calls];

        [self assert:2 equals:calls.length];
        [self assertNull:calls[0].to];
        [self assert:firstWindow equals:calls[0].from];
        [self assertNull:calls[1].window];
    });
}

- (void)testMovingBetweenWindowsNotifiesEachView
{
    [[firstWindow contentView] addSubview:parentView];
    [self clearCalls];
    [[secondWindow contentView] addSubview:parentView];

    [parentView, childView].forEach(function(aView)
    {
        var calls = [aView calls];

        [self assert:2 equals:calls.length];
        [self assert:firstWindow equals:calls[0].from];
        [self assert:secondWindow equals:calls[0].to];
        [self assert:secondWindow equals:calls[1].window];
    });
}

/*
    Cocoa also sends these notifications when a view stays in its window and only its
    position in the view hierarchy changes.
*/
- (void)testMovingWithinAWindowNotifiesEachView
{
    var otherView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [[firstWindow contentView] addSubview:parentView];
    [[firstWindow contentView] addSubview:otherView];
    [self clearCalls];
    [otherView addSubview:parentView];

    [parentView, childView].forEach(function(aView)
    {
        var calls = [aView calls];

        [self assert:2 equals:calls.length];
        [self assert:@"willMove" equals:calls[0].call];
        [self assert:firstWindow equals:calls[0].to];
        [self assert:@"didMove" equals:calls[1].call];
        [self assert:firstWindow equals:calls[1].window];
    });
}

// MARK: Appearance states

- (void)testEffectiveAppearanceComesFromTheNearestAncestor
{
    var appearance = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark];

    [parentView setAppearance:appearance];

    [self assert:appearance equals:[childView effectiveAppearance]];
}

- (void)testOwnAppearanceOverridesAnAncestor
{
    var appearance = [CPAppearance appearanceNamed:CPAppearanceNameVibrantLight];

    [parentView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [childView setAppearance:appearance];

    [self assert:appearance equals:[childView effectiveAppearance]];
}

- (void)testAppearanceStateReachesNestedViews
{
    [parentView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [_CPDisplayServer run];

    [self assertTrue:[parentView hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertTrue:[childView hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testChangingAppearanceReplacesTheState
{
    [parentView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [_CPDisplayServer run];
    [parentView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [_CPDisplayServer run];

    [self assertFalse:[childView hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertTrue:[childView hasThemeState:CPThemeStateAppearanceVibrantLight]];
}

- (void)testAViewAddedBelowAnAppearanceGainsItsState
{
    var lateView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [parentView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [_CPDisplayServer run];
    [childView addSubview:lateView];
    [lateView setNeedsLayout];
    [_CPDisplayServer run];

    [self assertTrue:[lateView hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

@end
