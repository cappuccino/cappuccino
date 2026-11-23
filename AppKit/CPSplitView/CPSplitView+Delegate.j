/*
 * CPSplitView+Delegate.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
 *
 * Adapted by Didier Korthoudt
 * Copyright 2019, Cappuccino Project.
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

@import "CPSplitViewCore.j"

var CPSplitViewDelegate_splitView_canCollapseSubview_                                   = 1 << 0,
    CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_                            = 1 << 1,
    CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_ = 1 << 2,
    CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_              = 1 << 3,
    CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_          = 1 << 4,
    CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_                   = 1 << 5,
    CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_                   = 1 << 6,
    CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_                   = 1 << 7,
    CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_                            = 1 << 8,
    CPSplitViewDelegate_splitViewDidResizeSubviews_                                     = 1 << 9,
    CPSplitViewDelegate_splitViewWillResizeSubviews_                                    = 1 << 10,
    CPSplitViewDelegate_splitView_shouldHideDividerAtIndex_                             = 1 << 11;

@implementation CPSplitView (CPSplitViewDelegate)

/*!
 Sets the delegate of the receiver.
 Possible delegate methods to implement are listed below.

 Notifies the delegate when the subviews have resized.
 @code
 - (void)splitViewDidResizeSubviews:(CPNotification)aNotification;
 @endcode

 Notifies the delegate when the subviews will be resized.
 @code
 - (void)splitViewWillResizeSubviews:(CPNotification)aNotification;
 @endcode

 Allows the delegate to specify which of the CPSplitView's subviews should adjust if the window is resized.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView shouldAdjustSizeOfSubview:(CPView)aSubView
 @endcode

 Lets the delegate specify a different rect for which the user can drag the splitView divider.
 @code
 - (CGRect)splitView:(CPSplitView)aSplitView effectiveRect:(CGRect)aRect forDrawnRect:(CGRect)aDrawnRect ofDividerAtIndex:(int)aDividerIndex;
 @endcode

 Lets the delegate specify an additional rect for which the user can drag the splitview divider.
 @code
 - (CGRect)splitView:(CPSplitView)aSplitView additionalEffectiveRectOfDividerAtIndex:(int)indexOfDivider;
 @endcode

 Notifies the delegate that the splitview is about to be collapsed. This usually happens when the user
 Double clicks on the divider. Return YES if the subview can be collapsed, otherwise NO.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview;
 @endcode

 Notifies the delegate that the subview at indexOfDivider is about to be collapsed. This usually happens when the user
 Double clicks on the divider. Return YES if the subview should be collapsed, otherwise NO.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView shouldCollapseSubview:(CPView)aSubview forDoubleClickOnDividerAtIndex:(int)indexOfDivider;
 @endcode

 Allows the delegate to constrain the subview beings resized. This method is called continuously as the user resizes the divider.
 For example if the subview needs to have a width which is a multiple of a certain number you could return that multiple with this method.
 @code
 - (float)splitView:(CPSplitView)aSpiltView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the delegate to constrain the minimum position of a subview.
 @code
 - (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the delegate to constrain the maximum position of a subview.
 @code
 - (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the splitview to specify a custom resizing behavior. This is called when the splitview is resized.
 The sum of the views and the sum of the dividers should be equal to the size of the splitview.
 @code
 - (void)splitView:(CPSplitView)aSplitView resizeSubviewsWithOldSize:(CGSize)oldSize;
 @endcode

 Lets the delegate hide a divider. A hidden divider has zero thickness and takes no space, and
 the user cannot drag it by its own rect.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView shouldHideDividerAtIndex:(int)dividerIndex;
 @endcode

 @param delegate - The delegate of the splitview.
 */
- (void)setDelegate:(id <CPSplitViewDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitViewWillResizeSubviews_;

    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitViewDidResizeSubviews_;

    if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_canCollapseSubview_;

    if ([_delegate respondsToSelector:@selector(splitView:shouldAdjustSizeOfSubview:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_;

    if ([_delegate respondsToSelector:@selector(splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:additionalEffectiveRectOfDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_;

    if ([_delegate respondsToSelector:@selector(splitView:shouldHideDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_shouldHideDividerAtIndex_;

    // We have to recompute flexible/fixed caches as the new delegate could consider things differently...
    [self _updateRatios];
}

- (id <CPSplitViewDelegate>)delegate
{
    return _delegate;
}

/*!
    @ignore
    Return YES if the delegate implements splitView:resizeSubviewsWithOldSize:
*/
- (BOOL)_delegateRespondsToSplitViewResizeSubviewsWithOldSize
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_;
}

/*!
    @ignore
    Return YES if the delegate implements splitView:canCollapseSubview:
*/
- (BOOL)_delegateRespondsToSplitViewCanCollapseSubview
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_canCollapseSubview_;
}

/*!
    @ignore
    Return YES if the delegate implements splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex
*/
- (BOOL)_delegateRespondsToSplitViewshouldCollapseSubviewForDoubleClickOnDividerAtIndex
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_;
}


/*!
    @ignore
    Call the delegate splitView:canCollapseSubview:
*/
- (BOOL)_sendDelegateSplitViewCanCollapseSubview:(CPView)aView
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_canCollapseSubview_))
        return NO;

    return [_delegate splitView:self canCollapseSubview:aView];
}

/*!
    @ignore
    Call the delegate splitView:shouldAdjustSizeOfSubview:
*/
- (BOOL)_sendDelegateSplitViewShouldAdjustSizeOfSubview:(CPView)aView
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_))
        return YES;

    return [_delegate splitView:self shouldAdjustSizeOfSubview:aView];
}

/*!
    @ignore
    Call the delegate splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:
*/
- (BOOL)_sendDelegateSplitViewShouldCollapseSubview:(CPView)aView forDoubleClickOnDividerAtIndex:(int)anIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_))
        return NO;

    return [_delegate splitView:self shouldCollapseSubview:aView forDoubleClickOnDividerAtIndex:anIndex];
}

/*!
    @ignore
    Call the delegate splitView:shouldHideDividerAtIndex:
*/
- (BOOL)_sendDelegateSplitViewShouldHideDividerAtIndex:(CPInteger)anIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldHideDividerAtIndex_))
        return NO;

    return !![_delegate splitView:self shouldHideDividerAtIndex:anIndex];
}

/*!
    @ignore
    Call the delegate splitView:additionalEffectiveRectOfDividerAtIndex:
*/
- (CGRect)_sendDelegateSplitViewAdditionalEffectiveRectOfDividerAtIndex:(int)anIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_))
        return nil;

    return [_delegate splitView:self additionalEffectiveRectOfDividerAtIndex:anIndex];
}

/*!
    @ignore
    Call the delegate splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:
*/
- (CGRect)_sendDelegateSplitViewEffectiveRect:(CGRect)proposedEffectiveRect forDrawnRect:(CGRect)drawnRect ofDividerAtIndex:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_))
        return proposedEffectiveRect;

    return [_delegate splitView:self effectiveRect:proposedEffectiveRect forDrawnRect:drawnRect ofDividerAtIndex:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainMaxCoordinate:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainMaxCoordinate:(float)proposedMax ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainMinCoordinate:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainMinCoordinate:(float)proposedMin ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainSplitPosition:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainSplitPosition:(float)proposedMax ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainSplitPosition:proposedMax ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:resizeSubviewsWithOldSize:
*/
- (void)_sendDelegateSplitViewResizeSubviewsWithOldSize:(CGSize)oldSize
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_))
        return;

    [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
}

/*!
    @ignore
    Call the delegate splitViewWillResizeSubviews:
*/
- (void)_sendDelegateSplitViewWillResizeSubviews
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    if (_implementedDelegateMethods & CPSplitViewDelegate_splitViewWillResizeSubviews_)
        [_delegate splitViewWillResizeSubviews:[[CPNotification alloc] initWithName:CPSplitViewWillResizeSubviewsNotification object:self userInfo:userInfo]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewWillResizeSubviewsNotification object:self userInfo:userInfo];
}

/*!
    @ignore
    Call the delegate splitViewDidResizeSubviews:
*/
- (void)_sendDelegateSplitViewDidResizeSubviews
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    if (_implementedDelegateMethods & CPSplitViewDelegate_splitViewDidResizeSubviews_)
        [_delegate splitViewDidResizeSubviews:[[CPNotification alloc] initWithName:CPSplitViewDidResizeSubviewsNotification object:self userInfo:userInfo]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewDidResizeSubviewsNotification object:self userInfo:userInfo];

    [self updateTrackingAreas];
}

@end
