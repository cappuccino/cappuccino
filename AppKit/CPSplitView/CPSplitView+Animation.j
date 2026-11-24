/*
 * CPSplitView+Animation.j
 * AppKit
 *
 * Created by David Richardson on 2026-11-23.
 * Copyright David Richardson 2026.
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
@import "CPViewAnimator.j"

/*
    The animator proxy of a split view. A divider move sent to it animates inside the current
    CPAnimationContext group: the two subviews beside the divider and the divider itself move
    to their new frames. A subview that collapses shrinks to nothing and is then hidden with its
    size kept; a subview that expands grows from nothing. Without a group duration, or where the
    browser has no CSS animation, the move is the same as the split view's own method.

    2026-11-23: the animator proxy forwarded the move to the split view, which set the frames at
    once. An application had to animate the subviews itself, and could not do it without
    knowing how the split view places them and hides a collapsed subview.
*/
@implementation CPSplitViewAnimator : CPViewAnimator

- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    [_target _animateToPosition:position ofDividerAtIndex:dividerIndex];
}

@end

@implementation CPSplitView (Animation)

/*
    Moves a divider as -setPosition:ofDividerAtIndex: does, and animates the views that change.
    The split view takes its final state at once, so its ratios, autosave and notifications are
    those of the end of the move; only the frames on screen animate.
*/
- (void)_animateToPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    [self _animateLayoutChange:function()
    {
        [self setPosition:position ofDividerAtIndex:dividerIndex];
    }];
}

/*
    Runs a change to the layout of the split view and animates each arranged subview and
    divider that the change moves, resizes, hides or shows. The change itself runs at once and
    gives the split view its final state; a split view controller uses this to animate the
    collapse and expansion of its items.
*/
- (void)_animateLayoutChange:(Function)aChange
{
    var views = [_arrangedSubviews arrayByAddingObjectsFromArray:_dividerSubviews],
        startStates = [];

    for (var i = 0, count = views.length; i < count; i++)
        startStates.push({ frame: CGRectMakeCopy([views[i] frame]), hidden: !![views[i] isHidden] });

    aChange();

    for (var i = 0, count = views.length; i < count; i++)
        if ([views[i] superview] === self)
            [self _animateView:views[i] fromState:startStates[i]];
}

/*
    Animates a view from the state it had before a layout change to the state the change gave it.
    A view that is hidden at the end animates to no size along the split, and one that was
    hidden at the start animates from no size; the end state is applied when the animation
    ends, or at once when there is no animation.
*/
- (void)_animateView:(CPView)aView fromState:(Object)aStartState
{
    var endFrame = CGRectMakeCopy([aView frame]),
        endHidden = !![aView isHidden];

    if (aStartState.hidden && endHidden)
        return;

    if (!aStartState.hidden && !endHidden && CGRectEqualToRect(endFrame, aStartState.frame))
        return;

    var startFrame = aStartState.frame,
        targetFrame = endFrame;

    if (aStartState.hidden)
    {
        startFrame = CGRectMakeCopy(endFrame);
        startFrame.size[_sizeComponent] = 0;
    }

    if (endHidden)
    {
        targetFrame = CGRectMakeCopy(endFrame);
        targetFrame.size[_sizeComponent] = 0;
    }

    var finish = function()
    {
        [aView setFrame:endFrame];
        [aView setHidden:endHidden];
    };

    [aView setHidden:NO];
    [aView setFrame:startFrame];
    [[aView animator] _setTargetValue:targetFrame withKeyPath:@"frame" fallback:finish completion:finish];
}

@end
