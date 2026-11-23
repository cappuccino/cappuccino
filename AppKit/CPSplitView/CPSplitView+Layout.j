/*
 * CPSplitView+Layout.j
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

@implementation CPSplitView (Layout)

// MARK: - Layout subviews

- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    return [_dividerSubviews[aDivider] frame];
}

/*!
 Returns the rect of the divider which the user is able to drag to resize.

 @param int - The index of the divider.
 @return CGRect - The rect the user can drag.
 */
- (CGRect)effectiveRectOfDividerAtIndex:(int)aDivider
{
    var realRect = [self rectOfDividerAtIndex:aDivider],
        padding = 2;

    /*
        A hidden divider has no drag area of its own: its rect has zero thickness and gets no
        padding. The additional effective rect from the delegate and the resize controls of
        button bars still apply.
    */
    if ([self _isDividerHiddenAtIndex:aDivider])
        return realRect;

    realRect.size[_sizeComponent] += padding * 2;
    realRect.origin[_originComponent] -= padding;

    return realRect;
}

- (void)resizeSubviewsWithOldSize:(CGSize)oldSize
{
    if ([self _delegateRespondsToSplitViewResizeSubviewsWithOldSize])
    {
        [self _sendDelegateSplitViewResizeSubviewsWithOldSize:oldSize];

        /*
            The delegate sets the frames of the subviews only, as in AppKit. This method returned
            here, so the divider views kept their old frames: only the split view's own path below
            moved them.
        */
        [self _layoutDividersFromArrangedSubviews];
        return;
    }

    // We adapt here only the "other" size (that is height for a vertical split view / width for an horizontal split view)
    // The complicated size will be treated in adjustSubviews

    var myOtherSize = [self frame].size[_otherSizeComponent];

    for (var i = 0, count = _arrangedSubviews.length, size; i < count; i++)
    {
        size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

        size[_otherSizeComponent] = myOtherSize;

        [_arrangedSubviews[i] setFrameSize:size];
    }

    for (var i = 0, count = _dividerSubviews.length, size; i < count; i++)
    {
        size = CGSizeMakeCopy([_dividerSubviews[i] frameSize]);

        size[_otherSizeComponent] = myOtherSize;

        [_dividerSubviews[i] setFrameSize:size];
    }

    [self adjustSubviews];
}

/*!
 Adjusts the sizes of the split view’s subviews so they (plus the dividers) fill the split view.

 The change in size goes first to the subviews with the lowest holding priority. When they cannot shrink further, the rest of the
 change goes to the subviews with the next priority. Subviews with the same holding priority share the change proportionally, so the
 ratio of their heights (when using horizontal dividers) or widths (when using vertical dividers) does not change. Subviews for which
 the delegate returns NO from splitView:shouldAdjustSizeOfSubview: change only when the other subviews cannot take the change.

 Call this method on split views from which subviews have been added or removed, to reestablish the consistency of subview placement.

 This method invalidates the cursor when it is over a divider, ensuring the cursor is always of the correct type during and after resizing animations.
 */
- (void)adjustSubviews
{
    [self _maybePostWillResizeNotification];

    /*
        The change in size goes to groups of subviews in turn. Subviews that the delegate lets
        the split view resize come first, then the others; within each, the subviews with the
        lowest holding priority come first. A group takes the whole change, and when it cannot
        shrink past zero the rest of the change goes to the next group. In a group, the
        subviews share the new size by their ratios. A collapsed subview takes no space and
        keeps its size, so it belongs to no group.

        The first group always gets its sizes from its ratios, even when the change is zero, so
        a call reestablishes the proportions of the subviews that resize first. A later group
        changes only when the change reaches it.

        2026-11-23: the split view had no holding priorities. Every subview that the delegate
        let it resize took a part of each change, so a sidebar grew and shrank with the window.
    */
    var sizeToFit = MAX(0, [self frame].size[_sizeComponent] - [self _totalDividerThickness]),
        groups = [self _resizeGroups],
        change = sizeToFit;

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        change -= [self _sizeOfArrangedSubviewAtIndex:i];

    for (var g = 0, groupCount = groups.length; g < groupCount; g++)
    {
        if (g > 0 && change === 0)
            break;

        var group = groups[g],
            groupSize = 0;

        for (var i = 0, count = group.length; i < count; i++)
            groupSize += [self _sizeOfArrangedSubviewAtIndex:group[i]];

        var newGroupSize = MAX(0, groupSize + change);

        [self _setSize:newGroupSize ofResizeGroup:group];
        change -= newGroupSize - groupSize;
    }

    [self _maybePostDidResizeNotification];

    [self _layoutSubviewsInEffectiveAppearance];
}

- (void)layoutSubviews
{
    // Retrieve the current color based on the current theme state (Standard vs HUD)
    var currentDividerColor = [self dividerColor];

    for (var i = 0, count = _arrangedSubviews.length, position = 0, origin; i < count; i++)
    {
        origin                   = CGPointMakeZero();
        origin[_originComponent] = position;
        position                += [self _sizeOfArrangedSubviewAtIndex:i];

        [_arrangedSubviews[i] setFrameOrigin:origin];

        if (i < count - 1)
        {
            // Apply the color to the specific divider view
            [_dividerSubviews[i] setBackgroundColor:currentDividerColor];

            [self _placeDividerAtIndex:i at:position];
            position += [self _thicknessOfDividerAtIndex:i];
        }
    }

    [self updateTrackingAreas];
}

// MARK: - Holding priorities

/*!
 Returns the holding priority of the arranged subview at an index. The default is 250.

 @param subviewIndex - The index of the arranged subview.
 @return float - The holding priority.
 */
- (float)holdingPriorityForSubviewAtIndex:(CPInteger)subviewIndex
{
    [self _checkArrangedSubviewIndex:subviewIndex];

    return _holdingPriorities[subviewIndex];
}

/*!
 Sets the holding priority of the arranged subview at an index. When the split view changes size, the subviews with the lowest
 holding priority take the change first. The priority takes effect at the next change in size.

 @param priority - The holding priority.
 @param subviewIndex - The index of the arranged subview.
 */
- (void)setHoldingPriority:(float)priority forSubviewAtIndex:(CPInteger)subviewIndex
{
    [self _checkArrangedSubviewIndex:subviewIndex];

    _holdingPriorities[subviewIndex] = priority;
}

/*
    Raises a range exception when an index is not the index of an arranged subview.
*/
- (void)_checkArrangedSubviewIndex:(CPInteger)anIndex
{
    if (anIndex < 0 || anIndex >= _arrangedSubviews.length)
        [CPException raise:CPRangeException reason:@"CPSplitView: index " + anIndex + " is out of range of the " + _arrangedSubviews.length + " arranged subviews"];
}

// MARK: - Private layout utilities

/*
    Returns YES when the delegate hides the divider at an index. As in AppKit, a hidden divider
    has zero thickness and takes no space.

    2026-11-23: the split view did not ask the delegate, so every divider took its full
    thickness. A collapsed sidebar left a divider line at the edge of the window.
*/
- (BOOL)_isDividerHiddenAtIndex:(CPInteger)anIndex
{
    return [self _sendDelegateSplitViewShouldHideDividerAtIndex:anIndex];
}

/*
    Returns the space that the divider at an index takes along the split.
*/
- (float)_thicknessOfDividerAtIndex:(CPInteger)anIndex
{
    return [self _isDividerHiddenAtIndex:anIndex] ? 0 : [self dividerThickness];
}

/*
    Returns the space that all the dividers take along the split.
*/
- (float)_totalDividerThickness
{
    var total = 0;

    for (var i = 0, count = _dividerSubviews.length; i < count; i++)
        total += [self _thicknessOfDividerAtIndex:i];

    return total;
}

/*
    Places the divider view at an index at a position along the split. The view has the
    thickness of the divider, fills the split view in the other direction, and is hidden when
    the divider is hidden.
*/
- (void)_placeDividerAtIndex:(CPInteger)anIndex at:(float)aPosition
{
    var divider = _dividerSubviews[anIndex],
        isHidden = [self _isDividerHiddenAtIndex:anIndex],
        frame = CGRectMakeZero();

    frame.origin[_originComponent] = aPosition;
    frame.size[_sizeComponent] = isHidden ? 0 : [self dividerThickness];
    frame.size[_otherSizeComponent] = [self frame].size[_otherSizeComponent];

    [divider setFrame:frame];
    [divider setHidden:isHidden];
}

/*
    Returns the space that the arranged subview at an index takes along the split. A collapsed
    subview takes no space, but it keeps its frame size for its expansion.
*/
- (float)_sizeOfArrangedSubviewAtIndex:(CPInteger)anIndex
{
    var subview = _arrangedSubviews[anIndex];

    return [subview isHidden] ? 0 : [subview frameSize][_sizeComponent];
}

/*
    Returns the part of the space that one ratio gets when a group of ratios share it. When the
    ratios of the group add up to zero, each member gets an equal part.
*/
- (float)_shareOfRatio:(float)aRatio inTotal:(float)aTotal count:(CPInteger)aCount
{
    if (aTotal > 0)
        return aRatio / aTotal;

    return aCount > 0 ? 1 / aCount : 0;
}

/*
    Places each divider view after the subview before it, from that subview's frame. The divider
    keeps its thickness and fills the split view in the other direction.
*/
- (void)_layoutDividersFromArrangedSubviews
{
    var dividerColor = [self dividerColor];

    for (var i = 0, count = MIN(_dividerSubviews.length, _arrangedSubviews.length - 1); i < count; i++)
    {
        var subviewFrame = [_arrangedSubviews[i] frame];

        [_dividerSubviews[i] setBackgroundColor:dividerColor];
        [self _placeDividerAtIndex:i at:subviewFrame.origin[_originComponent] + [self _sizeOfArrangedSubviewAtIndex:i]];
    }

    [self updateTrackingAreas];
}



/*
    Returns the indexes of the visible arranged subviews in the groups that take a change in
    size, in the order in which they take it: first the subviews that the delegate lets the
    split view resize, then the others, and in each by ascending holding priority. Subviews of
    a group have the same holding priority.
*/
- (CPArray)_resizeGroups
{
    var indexes = [];

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (![_arrangedSubviews[i] isHidden])
            indexes.push(i);

    var tier = function(anIndex) { return _isFlexible[anIndex] ? 0 : 1; };

    indexes.sort(function(a, b)
    {
        return (tier(a) - tier(b)) || (_holdingPriorities[a] - _holdingPriorities[b]) || (a - b);
    });

    var groups = [];

    for (var i = 0, count = indexes.length, group = nil; i < count; i++)
    {
        var index = indexes[i];

        if (!group || tier(index) !== tier(group[0]) || _holdingPriorities[index] !== _holdingPriorities[group[0]])
            groups.push(group = []);

        group.push(index);
    }

    return groups;
}

/*
    Gives the subviews of a resize group their shares of a size, by their ratios. The sizes are
    rounded so that their running total stays on the running total of the shares; the last
    subview takes what is left, so the sizes add up to the given size.
*/
- (void)_setSize:(float)aSize ofResizeGroup:(CPArray)aGroup
{
    var totalRatio = 0,
        count = aGroup.length;

    for (var i = 0; i < count; i++)
        totalRatio += _ratios[aGroup[i]];

    for (var i = 0, cumulativeFloatSize = 0, cumulativeIntSize = 0; i < count; i++)
    {
        var subview = _arrangedSubviews[aGroup[i]],
            size = CGSizeMakeCopy([subview frameSize]),
            intSize;

        if (i === count - 1)
            intSize = aSize - cumulativeIntSize;
        else
        {
            cumulativeFloatSize += aSize * [self _shareOfRatio:_ratios[aGroup[i]] inTotal:totalRatio count:count];
            intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
        }

        cumulativeIntSize += intSize;
        size[_sizeComponent] = intSize;

        [subview setFrameSize:size];
    }
}

- (void)_updateRatios
{
    // Compute new ratios based on new sizes

    var flexibleSpace = 0,
        flexibleCount = 0,
        fixedSpace    = 0,
        fixedCount    = 0;

    // We have to reinitialize this cache as flexibility can change over time (determined by the delegate)
    _isFlexible   = @[];
    _initialSizes = @[];

    for (var i = 0, count = _arrangedSubviews.length, isFlexible; i < count; i++)
    {
        [_isFlexible   addObject:(isFlexible = [self _sendDelegateSplitViewShouldAdjustSizeOfSubview:_arrangedSubviews[i]])];
        [_initialSizes addObject:[_arrangedSubviews[i] frame].size[_sizeComponent]];

        if (isFlexible)
        {
            flexibleSpace += _initialSizes[i];
            flexibleCount++;
        }
        else
        {
            fixedSpace += _initialSizes[i];
            fixedCount++;
        }
    }

    _ratios = @[];

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (_isFlexible[i])
            [_ratios addObject:(_initialSizes[i] / flexibleSpace)];
        else
            [_ratios addObject:(_initialSizes[i] / fixedSpace)];
}

@end
