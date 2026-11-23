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

 When you call this method, the split view’s subviews are resized proportionally; the relative sizes of the subviews do not change.

 The default implementation of this method resizes subviews proportionally so that the ratio of heights (when using horizontal dividers)
 or widths (when using vertical dividers) does not change, even though the absolute sizes change.

 Call this method on split views from which subviews have been added or removed, to reestablish the consistency of subview placement.

 This method invalidates the cursor when it is over a divider, ensuring the cursor is always of the correct type during and after resizing animations.
 */
- (void)adjustSubviews
{
    [self _maybePostWillResizeNotification];

    /*
        Two cases: there is enough space for the fixed subviews, or there is not. A collapsed
        subview takes no space and keeps its size, so it is left out of both cases. The ratios
        of the other subviews are scaled so that they share all the space.

        2026-11-23: a collapsed subview was a visible subview of size zero, so it needed no
        special case. Now that it keeps its size, counting it would leave a gap.
    */

    var sizeToFit   = [self frame].size[_sizeComponent] - [self _totalDividerThickness],
        fixedSize   = 0,
        nbSubviews  = _arrangedSubviews.length,
        flexibleRatios = 0,
        fixedRatios = 0,
        flexibleCount = 0,
        fixedCount = 0;

    for (var i = 0; i < nbSubviews; i++)
    {
        if ([_arrangedSubviews[i] isHidden])
            continue;

        if (_isFlexible[i])
        {
            flexibleRatios += _ratios[i];
            flexibleCount++;
        }
        else
        {
            fixedSize += [_arrangedSubviews[i] frameSize][_sizeComponent];
            fixedRatios += _ratios[i];
            fixedCount++;
        }
    }

    if (fixedSize < sizeToFit)
    {
        // There's enough space to maintain fixed and flexible subviews
        // So we only deal with flexible subviews, resizing them while keeping all ratios

        var newFlexibleSize = sizeToFit - fixedSize,
            remainingSpace  = newFlexibleSize;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
            if (_isFlexible[i] && ![_arrangedSubviews[i] isHidden])
            {
                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
                floatSize = MIN((newFlexibleSize * [self _shareOfRatio:_ratios[i] inTotal:flexibleRatios count:flexibleCount]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;

                [_arrangedSubviews[i] setFrameSize:size];
            }

        if (remainingSpace > 0)
            // Due to roundings, some pixels remain to attribute. We do this in reverse order of views.
            // For example, if we have 9px to distribute on 4 views, we do : +2 +2 +2 +3
            [self _distribute:remainingSpace amoung:flexibleCount onFlexible:YES fromIndex:0 toIndex:nbSubviews-1];
    }
    else
    {
        // There's not enough space to maintain fixed and flexible subviews
        // So we collapse all flexible subviews and shrink evenly fixed subviews

        var remainingSpace = sizeToFit;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
        {
            if ([_arrangedSubviews[i] isHidden])
                continue;

            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

            if (_isFlexible[i])
                size[_sizeComponent] = 0;
            else
            {
                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                floatSize = MIN((sizeToFit * [self _shareOfRatio:_ratios[i] inTotal:fixedRatios count:fixedCount]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;
            }

            [_arrangedSubviews[i] setFrameSize:size];
        }

        if (remainingSpace > 0)
            [self _distribute:remainingSpace amoung:fixedCount onFlexible:NO fromIndex:0 toIndex:nbSubviews-1];
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


- (void)_distribute:(CPInteger)remainingSpace amoung:(CPInteger)count onFlexible:(BOOL)onFlexible fromIndex:(CPInteger)fromIndex toIndex:(CPInteger)toIndex
{
    for (var i = toIndex, size, supplement; i >= fromIndex; i--)
        if (_isFlexible[i] == onFlexible && ![_arrangedSubviews[i] isHidden])
        {
            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
            remainingSpace -= supplement = CEIL(remainingSpace / count);
            size[_sizeComponent] += supplement;
            [_arrangedSubviews[i] setFrameSize:size];

            count--;
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
