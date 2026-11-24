/*
 *  CPSplitViewInteractionTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-23.
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

@import <AppKit/CPApplication.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPSplitView.j>

@class _CPSplitViewInteractionTestDelegate

/*
    These tests state how a split view behaves as AppKit's NSSplitView does: divider drags and
    their delegate constraints, collapsing, double-clicks, hidden dividers, holding priorities,
    animated divider moves, notifications, hit testing, button bars, autosave, orientation,
    arranged subviews and archiving. They come before a refactoring and a rework of
    CPSplitView, so they test through public behaviour only. The one exception is
    -_restoreFromAutosave: today only a cib load starts a restore, so the autosave tests call
    it, as CPSplitViewTest does.

    Each test uses a vertical split view 300 points wide and 100 points high, with thin dividers
    (1 point under ojtest, where no theme is loaded). The first subview is 100 points wide; the
    divider is at x = 100; the second subview fills the rest, from x = 101.

    Mouse events go to -mouseDown: and then to -trackDivider:, as the application sends them
    during a drag. The split view has no window, so event locations are split view coordinates.
*/
@implementation CPSplitViewInteractionTest : OJTestCase
{
    CPSplitView                         splitView;
    CPView                              viewA;
    CPView                              viewB;
    _CPSplitViewInteractionTestDelegate testDelegate;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    viewA = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    viewB = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 199, 100)];

    [splitView setDividerStyle:CPSplitViewDividerStyleThin];
    [splitView setVertical:YES];
    [splitView addArrangedSubview:viewA];
    [splitView addArrangedSubview:viewB];
    [splitView adjustSubviews];
    [splitView setPosition:100 ofDividerAtIndex:0];

    testDelegate = [_CPSplitViewInteractionTestDelegate new];
}

// MARK: - Helpers

- (CPEvent)mouseEvent:(CPEventType)aType atX:(float)x y:(float)y clicks:(int)aClickCount
{
    return [CPEvent mouseEventWithType:aType
                              location:CGPointMake(x, y)
                         modifierFlags:0
                             timestamp:0
                          windowNumber:0
                               context:nil
                           eventNumber:0
                            clickCount:aClickCount
                              pressure:0];
}

/*
    Presses the mouse at a point, drags it to x, and releases it there.
*/
- (void)dragFromX:(float)startX y:(float)y toX:(float)endX
{
    [splitView mouseDown:[self mouseEvent:CPLeftMouseDown atX:startX y:y clicks:1]];
    [splitView trackDivider:[self mouseEvent:CPLeftMouseDragged atX:endX y:y clicks:1]];
    [splitView trackDivider:[self mouseEvent:CPLeftMouseUp atX:endX y:y clicks:1]];
}

/*
    Drags the divider at an index from its current place to x.
*/
- (void)dragDivider:(int)anIndex toX:(float)x
{
    [self dragFromX:CGRectGetMinX([splitView rectOfDividerAtIndex:anIndex]) y:50 toX:x];
}

- (void)doubleClickDivider:(int)anIndex
{
    var x = CGRectGetMinX([splitView rectOfDividerAtIndex:anIndex]);

    [splitView mouseDown:[self mouseEvent:CPLeftMouseDown atX:x y:50 clicks:2]];
    [splitView trackDivider:[self mouseEvent:CPLeftMouseUp atX:x y:50 clicks:2]];
}

- (void)assertFrame:(CGRect)aFrame of:(CPView)aView named:(CPString)aName
{
    [self assertTrue:CGRectEqualToRect(aFrame, [aView frame])
             message:aName + " is at " + CPStringFromRect([aView frame]) + ", expected " + CPStringFromRect(aFrame)];
}

- (void)useAutosaveStore
{
    [[CPUserDefaults standardUserDefaults] setPersistentStoreClass:_CPSplitViewInteractionTestStore forDomain:CPApplicationDomain reloadData:NO];
}

// MARK: - Divider drags

- (void)testDraggingTheDividerMovesIt
{
    [self dragDivider:0 toX:150];

    [self assertFrame:CGRectMake(0, 0, 150, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(151, 0, 149, 100) of:viewB named:@"the second subview"];
    [self assert:150 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider position"];
}

- (void)testDraggingStopsAtTheDelegateMinimum
{
    [testDelegate setMinimum:80];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:50];

    [self assert:80 equals:CGRectGetWidth([viewA frame]) message:@"the first subview stops at the minimum"];
}

- (void)testDraggingStopsAtTheDelegateMaximum
{
    [testDelegate setMaximum:200];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:260];

    [self assert:200 equals:CGRectGetWidth([viewA frame]) message:@"the first subview stops at the maximum"];
}

- (void)testTheDelegateCanSnapTheDividerPosition
{
    [testDelegate setSnap:25];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:140];

    [self assert:150 equals:CGRectGetWidth([viewA frame]) message:@"the divider snaps to a multiple of 25"];
}

/*
    Moving one divider changes only the two subviews beside it.
*/
- (void)testMovingADividerLeavesTheOtherSubviewsAlone
{
    var viewC = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 99, 100)];

    [splitView addArrangedSubview:viewC];
    [splitView adjustSubviews];
    [splitView setPosition:100 ofDividerAtIndex:0];
    [splitView setPosition:200 ofDividerAtIndex:1];

    [self assertFrame:CGRectMake(201, 0, 99, 100) of:viewC named:@"the third subview before the move"];

    [self dragDivider:0 toX:150];

    [self assertFrame:CGRectMake(0, 0, 150, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(151, 0, 49, 100) of:viewB named:@"the second subview"];
    [self assertFrame:CGRectMake(201, 0, 99, 100) of:viewC named:@"the third subview"];
}

// MARK: - Collapsing

/*
    A drag past half the distance between the minimum and the edge collapses a subview that the
    delegate lets collapse.
*/
- (void)testDraggingPastHalfTheMinimumCollapsesTheSubview
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:30];

    [self assertTrue:[splitView isSubviewCollapsed:viewA] message:@"the first subview is collapsed"];
    [self assert:0 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider is at the edge"];
    [self assertFrame:CGRectMake(1, 0, 299, 100) of:viewB named:@"the second subview"];
}

- (void)testDraggingNotPastHalfTheMinimumStopsAtTheMinimum
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:50];

    [self assertFalse:[splitView isSubviewCollapsed:viewA] message:@"the first subview is not collapsed"];
    [self assert:80 equals:CGRectGetWidth([viewA frame]) message:@"the first subview stops at the minimum"];
}

/*
    AppKit hides a collapsed subview and keeps the size it had before it collapsed.
*/
- (void)testACollapsedSubviewIsHiddenAndKeepsItsSize
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:30];

    [self assertTrue:[viewA isHidden] message:@"the collapsed subview is hidden"];
    [self assert:100 equals:CGRectGetWidth([viewA frame]) message:@"the collapsed subview keeps its size"];
}

- (void)testDraggingTheDividerOutExpandsACollapsedSubview
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:30];
    [self dragDivider:0 toX:120];

    [self assertFalse:[splitView isSubviewCollapsed:viewA] message:@"the first subview is expanded"];
    [self assertFalse:[viewA isHidden] message:@"the expanded subview is visible"];
    [self assertFrame:CGRectMake(0, 0, 120, 100) of:viewA named:@"the first subview"];
}

/*
    The halfway rule applies to the second subview too: a drag past half the distance between
    the maximum and the far edge collapses it, and the first subview fills the split view up to
    the divider.
*/
- (void)testDraggingPastHalfTheMaximumCollapsesTheSecondSubview
{
    [testDelegate setMaximum:200];
    [testDelegate setCollapsibleSubviews:[viewB]];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:290];

    [self assertTrue:[splitView isSubviewCollapsed:viewB] message:@"the second subview is collapsed"];
    [self assertTrue:[viewB isHidden] message:@"the collapsed subview is hidden"];
    [self assert:299 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider is at the far edge"];
    [self assert:299 equals:CGRectGetWidth([viewA frame]) message:@"the first subview fills the split view up to the divider"];
}

- (void)testADoubleClickOnTheDividerCollapsesTheSubview
{
    [testDelegate setCollapsibleSubviews:[viewA]];
    [testDelegate setCollapsesOnDoubleClick:YES];
    [splitView setDelegate:testDelegate];

    [self doubleClickDivider:0];

    [self assertTrue:[splitView isSubviewCollapsed:viewA] message:@"the first subview is collapsed"];
    [self assertTrue:[viewA isHidden] message:@"the collapsed subview is hidden"];
}

- (void)testASecondDoubleClickRestoresTheSubview
{
    [testDelegate setCollapsibleSubviews:[viewA]];
    [testDelegate setCollapsesOnDoubleClick:YES];
    [splitView setDelegate:testDelegate];

    [self doubleClickDivider:0];
    [self doubleClickDivider:0];

    [self assertFalse:[splitView isSubviewCollapsed:viewA] message:@"the first subview is expanded"];
    [self assertFalse:[viewA isHidden] message:@"the expanded subview is visible"];
    [self assertFrame:CGRectMake(0, 0, 100, 100) of:viewA named:@"the first subview has its size from before"];
}

// MARK: - Hidden dividers

/*
    AppKit asks the delegate whether to hide each divider. A hidden divider has zero thickness
    and takes no space, so the subviews share the whole split view.
*/
- (void)testAHiddenDividerTakesNoSpace
{
    [testDelegate setHiddenDividerIndexes:[0]];
    [splitView setDelegate:testDelegate];
    [splitView adjustSubviews];

    [self assertFrame:CGRectMake(0, 0, 100, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(100, 0, 200, 100) of:viewB named:@"the second subview"];
    [self assert:0 equals:CGRectGetWidth([splitView rectOfDividerAtIndex:0]) message:@"the hidden divider has zero thickness"];
}

/*
    A hidden divider has no drag area of its own.
*/
- (void)testAHiddenDividerCannotBeDragged
{
    [testDelegate setHiddenDividerIndexes:[0]];
    [splitView setDelegate:testDelegate];
    [splitView adjustSubviews];

    [self dragDivider:0 toX:140];

    [self assert:100 equals:CGRectGetWidth([viewA frame]) message:@"the first subview keeps its width"];
}

/*
    A delegate that hides the divider next to a collapsed subview gives the space of the divider
    to the other subview when the collapse happens.
*/
- (void)testCollapsingASubviewWhoseDividerHidesGivesTheSpaceToTheOtherSubview
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [testDelegate setHidesDividersOfCollapsedSubviews:YES];
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:30];

    [self assertTrue:[splitView isSubviewCollapsed:viewA] message:@"the first subview is collapsed"];
    [self assertFrame:CGRectMake(0, 0, 300, 100) of:viewB named:@"the second subview"];
    [self assert:0 equals:CGRectGetWidth([splitView rectOfDividerAtIndex:0]) message:@"the hidden divider has zero thickness"];
}

/*
    The divider of an expanded subview is shown again and takes its thickness.
*/
- (void)testExpandingASubviewShowsItsHiddenDivider
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [testDelegate setHidesDividersOfCollapsedSubviews:YES];
    [splitView setDelegate:testDelegate];
    [self dragDivider:0 toX:30];

    [splitView setPosition:140 ofDividerAtIndex:0];

    [self assertFalse:[splitView isSubviewCollapsed:viewA] message:@"the first subview is expanded"];
    [self assertFrame:CGRectMake(0, 0, 140, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(141, 0, 159, 100) of:viewB named:@"the second subview"];
    [self assert:1 equals:CGRectGetWidth([splitView rectOfDividerAtIndex:0]) message:@"the divider has its thickness again"];
}

// MARK: - Holding priorities

- (void)testTheDefaultHoldingPriorityIs250
{
    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:0] message:@"the first subview"];
    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:1] message:@"the second subview"];
}

- (void)testAHoldingPriorityIsKept
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];

    [self assert:260 equals:[splitView holdingPriorityForSubviewAtIndex:0] message:@"the first subview"];
    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:1] message:@"the second subview"];
}

- (void)testAnIndexOutOfRangeRaises
{
    [self assertThrows:function() { [splitView holdingPriorityForSubviewAtIndex:2]; }];
    [self assertThrows:function() { [splitView setHoldingPriority:260 forSubviewAtIndex:-1]; }];
}

- (void)testGrowingGivesTheSpaceToTheLowestHoldingPriority
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView setFrame:CGRectMake(0, 0, 400, 100)];

    [self assertFrame:CGRectMake(0, 0, 100, 100) of:viewA named:@"the subview that holds"];
    [self assertFrame:CGRectMake(101, 0, 299, 100) of:viewB named:@"the subview that grows"];
}

- (void)testAHigherPriorityOnTheSecondSubviewMakesTheFirstGrow
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:1];
    [splitView setFrame:CGRectMake(0, 0, 400, 100)];

    [self assertFrame:CGRectMake(0, 0, 200, 100) of:viewA named:@"the subview that grows"];
    [self assertFrame:CGRectMake(201, 0, 199, 100) of:viewB named:@"the subview that holds"];
}

- (void)testShrinkingTakesTheSpaceFromTheLowestHoldingPriority
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView setFrame:CGRectMake(0, 0, 200, 100)];

    [self assertFrame:CGRectMake(0, 0, 100, 100) of:viewA named:@"the subview that holds"];
    [self assertFrame:CGRectMake(101, 0, 99, 100) of:viewB named:@"the subview that shrinks"];
}

/*
    When the subviews with the lowest priority reach zero, the rest of the change goes to the
    subviews with the next priority.
*/
- (void)testShrinkingPastZeroMovesToTheNextHoldingPriority
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView setFrame:CGRectMake(0, 0, 60, 100)];

    [self assertFrame:CGRectMake(0, 0, 59, 100) of:viewA named:@"the subview with the higher priority"];
    [self assertFrame:CGRectMake(60, 0, 0, 100) of:viewB named:@"the subview with the lower priority"];
}

- (void)testEqualHoldingPrioritiesShareTheChangeBySize
{
    [splitView setFrame:CGRectMake(0, 0, 400, 100)];

    [self assertFrame:CGRectMake(0, 0, 133, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(134, 0, 266, 100) of:viewB named:@"the second subview"];
}

/*
    A subview that the delegate does not let the split view resize changes only when the
    others cannot take the change, whatever its holding priority.
*/
- (void)testASubviewTheDelegateHoldsComesAfterEveryPriority
{
    [testDelegate setFixedSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [splitView setHoldingPriority:100 forSubviewAtIndex:0];
    [splitView setFrame:CGRectMake(0, 0, 400, 100)];

    [self assertFrame:CGRectMake(0, 0, 100, 100) of:viewA named:@"the subview the delegate holds"];
    [self assertFrame:CGRectMake(101, 0, 299, 100) of:viewB named:@"the other subview"];
}

- (void)testACollapsedSubviewKeepsItsSizeWhenTheSplitViewGrows
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [self dragDivider:0 toX:30];

    [splitView setHoldingPriority:260 forSubviewAtIndex:1];
    [splitView setFrame:CGRectMake(0, 0, 400, 100)];

    [self assert:100 equals:CGRectGetWidth([viewA frame]) message:@"the collapsed subview keeps its width"];
    [self assertFrame:CGRectMake(1, 0, 399, 100) of:viewB named:@"the visible subview"];
}

- (void)testAHoldingPriorityFollowsItsSubviewWhenASubviewIsInserted
{
    var viewC = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 50, 100)];

    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView insertArrangedSubview:viewC atIndex:0];

    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:0] message:@"the inserted subview"];
    [self assert:260 equals:[splitView holdingPriorityForSubviewAtIndex:1] message:@"the first subview"];
    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:2] message:@"the second subview"];
}

- (void)testRemovingASubviewRemovesItsHoldingPriority
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:1];
    [viewA removeFromSuperview];

    [self assert:260 equals:[splitView holdingPriorityForSubviewAtIndex:0] message:@"the remaining subview"];
    [self assertThrows:function() { [splitView holdingPriorityForSubviewAtIndex:1]; }];
}

// MARK: - Animated divider moves

/*
    ojtest has no CSS animation, so a move sent to the animator takes the path without an
    animation. These tests state the end of a move, which both paths share, and that the move
    finishes inside an animation group.
*/
- (void)testTheAnimatorMovesTheDivider
{
    [[splitView animator] setPosition:140 ofDividerAtIndex:0];

    [self assertFrame:CGRectMake(0, 0, 140, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(141, 0, 159, 100) of:viewB named:@"the second subview"];
    [self assert:140 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider is at the new position"];
}

- (void)testAnAnimatedMoveEndsAtThePositionAndCallsTheCompletionHandler
{
    var completed = NO;

    [CPAnimationContext runAnimationGroup:function(context)
    {
        [context setDuration:0.25];
        [[splitView animator] setPosition:140 ofDividerAtIndex:0];
    }
    completionHandler:function()
    {
        completed = YES;
    }];

    [self assertTrue:completed message:@"the completion handler is called"];
    [self assertFrame:CGRectMake(0, 0, 140, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(141, 0, 159, 100) of:viewB named:@"the second subview"];
}

- (void)testAnAnimatedCollapseHidesTheSubviewAndKeepsItsSize
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];

    [CPAnimationContext runAnimationGroup:function(context)
    {
        [context setDuration:0.25];
        [[splitView animator] setPosition:0 ofDividerAtIndex:0];
    }
    completionHandler:nil];

    [self assertTrue:[splitView isSubviewCollapsed:viewA] message:@"the first subview is collapsed"];
    [self assertTrue:[viewA isHidden] message:@"the collapsed subview is hidden"];
    [self assert:100 equals:CGRectGetWidth([viewA frame]) message:@"the collapsed subview keeps its width"];
    [self assertFrame:CGRectMake(1, 0, 299, 100) of:viewB named:@"the second subview"];
}

- (void)testAnAnimatedExpansionShowsTheSubview
{
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [splitView setPosition:0 ofDividerAtIndex:0];

    [CPAnimationContext runAnimationGroup:function(context)
    {
        [context setDuration:0.25];
        [[splitView animator] setPosition:140 ofDividerAtIndex:0];
    }
    completionHandler:nil];

    [self assertFalse:[viewA isHidden] message:@"the first subview is shown"];
    [self assertFrame:CGRectMake(0, 0, 140, 100) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(141, 0, 159, 100) of:viewB named:@"the second subview"];
}

// MARK: - Notifications

- (void)testDraggingTheDividerPostsTheResizeNotifications
{
    var observer = [_CPSplitViewInteractionTestObserver new],
        center = [CPNotificationCenter defaultCenter];

    [center addObserver:observer selector:@selector(willResize:) name:CPSplitViewWillResizeSubviewsNotification object:splitView];
    [center addObserver:observer selector:@selector(didResize:) name:CPSplitViewDidResizeSubviewsNotification object:splitView];

    [self dragDivider:0 toX:150];

    [center removeObserver:observer];

    [self assertTrue:[observer willCount] > 0 message:@"the will-resize notification is posted"];
    [self assertTrue:[observer didCount] > 0 message:@"the did-resize notification is posted"];
    [self assert:[observer willCount] equals:[observer didCount] message:@"each will-resize notification has a did-resize notification"];
}

/*
    The delegate is told after the subviews have their new sizes.
*/
- (void)testTheDelegateIsToldAfterTheSubviewsResize
{
    [splitView setDelegate:testDelegate];

    [self dragDivider:0 toX:150];

    [self assertTrue:[testDelegate didResizeCount] > 0 message:@"the delegate is told"];
    [self assert:splitView same:[testDelegate lastNotificationObject] message:@"the notification object is the split view"];
    [self assert:150 equals:[testDelegate firstSubviewWidthWhenTold] message:@"the first subview has its new width when the delegate is told"];
}

// MARK: - Hit testing

- (void)testHitTestingTheDividerReturnsTheSplitView
{
    [self assert:splitView same:[splitView hitTest:CGPointMake(100.5, 50)] message:@"the divider belongs to the split view"];
    [self assert:viewA same:[splitView hitTest:CGPointMake(50, 50)] message:@"a point in the first subview belongs to it"];
}

/*
    The delegate can give a divider an additional rect, for example a grip in a subview. A drag
    that starts there moves the divider by the distance of the drag.
*/
- (void)testAnAdditionalEffectiveRectStartsADividerDrag
{
    [testDelegate setAdditionalRect:CGRectMake(40, 0, 20, 20)];
    [splitView setDelegate:testDelegate];

    [self dragFromX:50 y:10 toX:80];

    [self assert:130 equals:CGRectGetWidth([viewA frame]) message:@"the divider moves by the drag distance"];
}

// MARK: - Button bars

/*
    A button bar attached to a divider gets a resize control on the side of that divider.
*/
- (void)testAButtonBarInTheFirstSubviewGetsAResizeControlOnTheRight
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, 74, 100, 26)];

    [viewA addSubview:buttonBar];
    [splitView setButtonBar:buttonBar forDividerAtIndex:0];

    [self assertTrue:[buttonBar hasRightResizeControl] message:@"the resize control is on the right"];
    [self assertFalse:[buttonBar hasLeftResizeControl] message:@"there is no resize control on the left"];
}

- (void)testAButtonBarInTheSecondSubviewGetsAResizeControlOnTheLeft
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, 74, 199, 26)];

    [viewB addSubview:buttonBar];
    [splitView setButtonBar:buttonBar forDividerAtIndex:0];

    [self assertTrue:[buttonBar hasLeftResizeControl] message:@"the resize control is on the left"];
    [self assertFalse:[buttonBar hasRightResizeControl] message:@"there is no resize control on the right"];
}

// MARK: - Autosave

- (void)testAutosaveRestoresADividerPosition
{
    [self useAutosaveStore];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Position"];
    [self dragDivider:0 toX:140];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self setUp];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Position"];
    [splitView _restoreFromAutosave];

    [self assert:140 equals:CGRectGetWidth([viewA frame]) message:@"the divider position is restored"];
}

/*
    A restored layout is the layout that later resizes keep: the next adjustSubviews leaves the
    restored sizes in place, and the divider is at the restored position.
*/
- (void)testAutosaveRestoredSizesSurviveTheNextAdjustment
{
    [self useAutosaveStore];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Ratios"];
    [self dragDivider:0 toX:140];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self setUp];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Ratios"];
    [splitView _restoreFromAutosave];

    [self assert:140 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider is at the restored position"];

    [splitView adjustSubviews];

    [self assert:140 equals:CGRectGetWidth([viewA frame]) message:@"the restored size survives adjustSubviews"];
    [self assert:140 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the divider stays at the restored position"];
}

/*
    A restore happens before the window gives the split view its final size. A subview with a
    higher holding priority keeps its restored width through that resize.
*/
- (void)testARestoredSidebarKeepsItsWidthWhenTheSplitViewResizes
{
    [self useAutosaveStore];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Sidebar"];
    [self dragDivider:0 toX:140];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self setUp];
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Sidebar"];
    [splitView _restoreFromAutosave];
    [splitView setFrame:CGRectMake(0, 0, 500, 100)];

    [self assertFrame:CGRectMake(0, 0, 140, 100) of:viewA named:@"the sidebar"];
    [self assertFrame:CGRectMake(141, 0, 359, 100) of:viewB named:@"the content"];
}

/*
    Saved state belongs to the subviews it was saved for. A split view that has gained a subview
    since the save keeps its current layout.
*/
- (void)testAutosaveIgnoresStateSavedForADifferentNumberOfSubviews
{
    [self useAutosaveStore];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Count"];
    [self dragDivider:0 toX:140];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self setUp];
    [splitView addArrangedSubview:[[CPView alloc] initWithFrame:CGRectMake(0, 0, 50, 100)]];
    [splitView adjustSubviews];

    var framesBefore = [[splitView arrangedSubviews] valueForKey:@"frame"];

    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Count"];
    [splitView _restoreFromAutosave];

    var framesAfter = [[splitView arrangedSubviews] valueForKey:@"frame"];

    for (var i = 0; i < 3; i++)
        [self assertTrue:CGRectEqualToRect(framesBefore[i], framesAfter[i]) message:@"subview " + i + " keeps its frame"];
}

/*
    AppKit saves whether each subview is collapsed, so a collapsed sidebar stays collapsed.
*/
- (void)testAutosaveRestoresACollapsedSubview
{
    [self useAutosaveStore];
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Collapsed"];
    [self dragDivider:0 toX:30];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self setUp];
    [testDelegate setMinimum:80];
    [testDelegate setCollapsibleSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [splitView setAutosaveName:@"CPSplitViewInteractionTest.Collapsed"];
    [splitView _restoreFromAutosave];

    [self assertTrue:[splitView isSubviewCollapsed:viewA] message:@"the first subview is collapsed after the restore"];
    [self assertTrue:[viewA isHidden] message:@"the collapsed subview is hidden after the restore"];
}

// MARK: - Orientation and arranged subviews

- (void)testChangingTheOrientationStacksTheSubviews
{
    /*
        The split view places its subviews in its layout pass, as NSSplitView does. A view
        outside a window gets no display cycle, so the test runs the pending pass itself.
    */
    [splitView setVertical:NO];
    [splitView layoutIfNeeded];

    var frameA = [viewA frame],
        frameB = [viewB frame];

    [self assert:0 equals:CGRectGetMinY(frameA) message:@"the first subview is at the top"];
    [self assert:300 equals:CGRectGetWidth(frameA) message:@"the first subview fills the width"];
    [self assert:300 equals:CGRectGetWidth(frameB) message:@"the second subview fills the width"];
    [self assert:0 equals:CGRectGetMinX(frameB) message:@"the second subview starts at the left edge"];
    [self assert:CGRectGetMaxY(frameA) + 1 equals:CGRectGetMinY(frameB) message:@"the second subview is below the divider"];
    [self assert:100 equals:CGRectGetHeight(frameA) + 1 + CGRectGetHeight(frameB) message:@"the subviews and the divider fill the height"];
}

- (void)testChangingTheOrientationKeepsTheProportions
{
    [splitView setVertical:NO];

    [self assertFrame:CGRectMake(0, 0, 300, 33) of:viewA named:@"the first subview"];
    [self assertFrame:CGRectMake(0, 34, 300, 66) of:viewB named:@"the second subview"];
}

/*
    The subviews share the space by their sizes, whether or not the delegate lets the split
    view resize them.
*/
- (void)testChangingTheOrientationWithASubviewTheDelegateHoldsFillsTheSplitView
{
    [testDelegate setFixedSubviews:[viewA]];
    [splitView setDelegate:testDelegate];
    [splitView setVertical:NO];

    [self assertFrame:CGRectMake(0, 0, 300, 33) of:viewA named:@"the subview the delegate holds"];
    [self assertFrame:CGRectMake(0, 34, 300, 66) of:viewB named:@"the other subview"];
}

- (void)testChangingTheOrientationKeepsTheHoldingPriorities
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];
    [splitView setVertical:NO];

    [self assert:260 equals:[splitView holdingPriorityForSubviewAtIndex:0] message:@"the first subview"];
    [self assert:250 equals:[splitView holdingPriorityForSubviewAtIndex:1] message:@"the second subview"];
}

- (void)testASubviewAddedWhileNotArrangingAllSubviewsIsNotArranged
{
    var viewC = [[CPView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];

    [splitView setArrangesAllSubviews:NO];
    [splitView addSubview:viewC];
    [splitView adjustSubviews];

    [self assertFalse:[[splitView arrangedSubviews] containsObject:viewC] message:@"the new subview is not arranged"];
    [self assert:2 equals:[[splitView arrangedSubviews] count] message:@"the arranged subviews are unchanged"];
    [self assertFrame:CGRectMake(10, 10, 20, 20) of:viewC named:@"the subview that is not arranged"];
}

- (void)testArrangingAllSubviewsArrangesTheExistingSubviews
{
    var otherSplitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)],
        first = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        second = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    [otherSplitView setArrangesAllSubviews:NO];
    [otherSplitView addSubview:first];
    [otherSplitView addSubview:second];
    [otherSplitView setArrangesAllSubviews:YES];

    [self assert:[first, second] equals:[otherSplitView arrangedSubviews] message:@"both subviews are arranged, in order"];
}

- (void)testReplacingASubviewThatIsNotArrangedKeepsSubviewManagement
{
    var extra = [[CPView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)],
        replacement = [[CPView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];

    [splitView setArrangesAllSubviews:NO];
    [splitView addSubview:extra];
    [splitView replaceSubview:extra with:replacement];
    [viewB removeFromSuperview];

    [self assert:[viewA] equals:[splitView arrangedSubviews] message:@"a removed subview leaves the arranged subviews"];
}

// MARK: - Archiving

- (void)testArchivingKeepsTheLayout
{
    [self dragDivider:0 toX:140];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:splitView]],
        arranged = [copy arrangedSubviews];

    [self assertTrue:[copy isVertical] message:@"the copy is vertical"];
    [self assert:CPSplitViewDividerStyleThin equals:[copy dividerStyle] message:@"the copy has thin dividers"];
    [self assert:2 equals:[arranged count] message:@"the copy has two arranged subviews"];
    [self assert:140 equals:CGRectGetWidth([arranged[0] frame]) message:@"the first subview of the copy keeps its width"];
}

- (void)testArchivingKeepsTheHoldingPriorities
{
    [splitView setHoldingPriority:260 forSubviewAtIndex:0];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:splitView]];

    [self assert:260 equals:[copy holdingPriorityForSubviewAtIndex:0] message:@"the first subview of the copy"];
    [self assert:250 equals:[copy holdingPriorityForSubviewAtIndex:1] message:@"the second subview of the copy"];
}

@end

// MARK: -

/*
    A split view delegate whose answers each test sets. A limit or snap of 0 means none.
*/
@implementation _CPSplitViewInteractionTestDelegate : CPObject
{
    float       _minimum                    @accessors(property=minimum);
    float       _maximum                    @accessors(property=maximum);
    float       _snap                       @accessors(property=snap);
    CPArray     _collapsibleSubviews        @accessors(property=collapsibleSubviews);
    CPArray     _fixedSubviews              @accessors(property=fixedSubviews);
    BOOL        _collapsesOnDoubleClick     @accessors(property=collapsesOnDoubleClick);
    CGRect      _additionalRect             @accessors(property=additionalRect);
    CPArray     _hiddenDividerIndexes       @accessors(property=hiddenDividerIndexes);
    BOOL        _hidesDividersOfCollapsedSubviews @accessors(property=hidesDividersOfCollapsedSubviews);

    int         _didResizeCount             @accessors(readonly, property=didResizeCount);
    id          _lastNotificationObject     @accessors(readonly, property=lastNotificationObject);
    float       _firstSubviewWidthWhenTold  @accessors(readonly, property=firstSubviewWidthWhenTold);
}

- (id)init
{
    if (self = [super init])
    {
        _collapsibleSubviews = [];
        _fixedSubviews = [];
        _hiddenDividerIndexes = [];
        _didResizeCount = 0;
    }

    return self;
}

- (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)anIndex
{
    return _minimum ? MAX(proposedMin, _minimum) : proposedMin;
}

- (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)anIndex
{
    return _maximum ? MIN(proposedMax, _maximum) : proposedMax;
}

- (float)splitView:(CPSplitView)aSplitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)anIndex
{
    return _snap ? ROUND(proposedPosition / _snap) * _snap : proposedPosition;
}

- (BOOL)splitView:(CPSplitView)aSplitView shouldAdjustSizeOfSubview:(CPView)aSubview
{
    return ![_fixedSubviews containsObject:aSubview];
}

- (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview
{
    return [_collapsibleSubviews containsObject:aSubview];
}

- (BOOL)splitView:(CPSplitView)aSplitView shouldCollapseSubview:(CPView)aSubview forDoubleClickOnDividerAtIndex:(int)anIndex
{
    return _collapsesOnDoubleClick;
}

- (CGRect)splitView:(CPSplitView)aSplitView additionalEffectiveRectOfDividerAtIndex:(int)anIndex
{
    return _additionalRect || CGRectMakeZero();
}

- (BOOL)splitView:(CPSplitView)aSplitView shouldHideDividerAtIndex:(int)anIndex
{
    if ([_hiddenDividerIndexes containsObject:anIndex])
        return YES;

    if (!_hidesDividersOfCollapsedSubviews)
        return NO;

    var subviews = [aSplitView arrangedSubviews];

    return [aSplitView isSubviewCollapsed:subviews[anIndex]] || [aSplitView isSubviewCollapsed:subviews[anIndex + 1]];
}

- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var splitView = [aNotification object];

    _didResizeCount++;
    _lastNotificationObject = splitView;
    _firstSubviewWidthWhenTold = CGRectGetWidth([[splitView arrangedSubviews][0] frame]);
}

@end

@implementation _CPSplitViewInteractionTestObserver : CPObject
{
    int     _willCount  @accessors(readonly, property=willCount);
    int     _didCount   @accessors(readonly, property=didCount);
}

- (id)init
{
    if (self = [super init])
    {
        _willCount = 0;
        _didCount = 0;
    }

    return self;
}

- (void)willResize:(CPNotification)aNotification
{
    _willCount++;
}

- (void)didResize:(CPNotification)aNotification
{
    _didCount++;
}

@end

/*
    A user defaults store that keeps its data in memory for the autosave tests.
*/
@implementation _CPSplitViewInteractionTestStore : CPUserDefaultsStore
{
    CPData  _data;
}

- (CPData)data
{
    return _data;
}

- (void)setData:(CPData)aData
{
    _data = aData;
}

@end
