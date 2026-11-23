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

    realRect.size[_sizeComponent] += padding * 2;
    realRect.origin[_originComponent] -= padding;

    return realRect;
}

- (void)setFrameSize:(CGSize)aSize
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = NO;

    [super setFrameSize:aSize];

    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = YES;
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
    [self _postNotificationWillResize];

    // 2 possibilities : we have, or not, enough flexible space to accomodate fixed size subviews

    var sizeToFit   = [self frame].size[_sizeComponent] - _dividerSubviews.length * [self dividerThickness],
        fixedSize   = 0,
        nbSubviews  = _arrangedSubviews.length;

    for (var i = 0; i < nbSubviews; i++)
        if (!_isFlexible[i])
            fixedSize += [_arrangedSubviews[i] frameSize][_sizeComponent];

    if (fixedSize < sizeToFit)
    {
        // There's enough space to maintain fixed and flexible subviews
        // So we only deal with flexible subviews, resizing them while keeping all ratios

        var newFlexibleSize = sizeToFit - fixedSize,
            remainingSpace  = newFlexibleSize,
            flexibleCount   = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
            if (_isFlexible[i])
            {
                flexibleCount++;

                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
                floatSize = MIN((newFlexibleSize * _ratios[i]), remainingSpace);
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

        var remainingSpace = sizeToFit,
            fixedCount     = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
        {
            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

            if (_isFlexible[i])
                size[_sizeComponent] = 0;
            else
            {
                fixedCount++;

                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                floatSize = MIN((sizeToFit * _ratios[i]), remainingSpace);
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
        position                += [_arrangedSubviews[i] frame].size[_sizeComponent];

        [_arrangedSubviews[i] setFrameOrigin:origin];

        if (i < count - 1)
        {
            origin                   = CGPointMakeZero();
            origin[_originComponent] = position;
            position                += [_dividerSubviews[i] frame].size[_sizeComponent];

            // Apply the color to the specific divider view
            [_dividerSubviews[i] setBackgroundColor:currentDividerColor];

            [_dividerSubviews[i] setFrameOrigin:origin];
        }
    }

    [self updateTrackingAreas];
}

// MARK: - Private layout utilities

/*
    Places each divider view after the subview before it, from that subview's frame. The divider
    keeps its thickness and fills the split view in the other direction.
*/
- (void)_layoutDividersFromArrangedSubviews
{
    var myOtherSize = [self frame].size[_otherSizeComponent],
        dividerColor = [self dividerColor];

    for (var i = 0, count = MIN(_dividerSubviews.length, _arrangedSubviews.length - 1); i < count; i++)
    {
        var subviewFrame = [_arrangedSubviews[i] frame],
            divider = _dividerSubviews[i],
            frame = CGRectMakeZero();

        frame.origin[_originComponent] = subviewFrame.origin[_originComponent] + subviewFrame.size[_sizeComponent];
        frame.size[_sizeComponent] = [divider frameSize][_sizeComponent];
        frame.size[_otherSizeComponent] = myOtherSize;

        [divider setBackgroundColor:dividerColor];
        [divider setFrame:frame];
    }

    [self updateTrackingAreas];
}


- (void)_distribute:(CPInteger)remainingSpace amoung:(CPInteger)count onFlexible:(BOOL)onFlexible fromIndex:(CPInteger)fromIndex toIndex:(CPInteger)toIndex
{
    for (var i = toIndex, size, supplement; i >= fromIndex; i--)
        if (_isFlexible[i] == onFlexible)
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
