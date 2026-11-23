/*
 * CPSplitView+Dividers.j
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

@global CPApp

@implementation CPSplitView (Dividers)

// MARK: -

/*!
    Returns YES if the supplied subview is collapsed, otherwise NO. As in AppKit, a collapsed
    subview is an arranged subview that is hidden. It keeps its size and takes no space.

    2026-11-23: a subview counted as collapsed when its size was below one point. A collapse
    set the size to zero and kept the subview visible, so the size from before the collapse
    was lost, and a separate table of positions keyed by divider index tried to restore it.
    @param aSubview - the subview you are interested in.
    @return BOOL - YES if the subview is collapsed, otherwise NO.
*/
- (BOOL)isSubviewCollapsed:(CPView)subview
{
    return [subview isHidden] && [_arrangedSubviews containsObjectIdenticalTo:subview];
}

/*!
    Draws the divider at a given rect.
    @param aRect - the rect of the divider to draw.
*/
- (void)drawDividerInRect:(CGRect)aRect
{
    // This is declared for Cocoa compatibility but has no effect in Cappuccino
}

- (BOOL)cursorAtPoint:(CGPoint)aPoint hitDividerAtIndex:(int)anIndex
{
    var effectiveRect      = [self effectiveRectOfDividerAtIndex:anIndex],
        leftButtonBar      = _buttonBars[anIndex],
        rightButtonBar     = _buttonBars[anIndex+1],
        leftButtonBarRect  = nil,
        rightButtonBarRect = nil,
        additionalRect     = nil;

    if (leftButtonBar && [leftButtonBar hasRightResizeControl])
    {
        leftButtonBarRect        = [leftButtonBar rightResizeControlFrame];
        leftButtonBarRect.origin = [self convertPoint:leftButtonBarRect.origin fromView:leftButtonBar];
    }

    if (rightButtonBar && [rightButtonBar hasLeftResizeControl])
    {
        rightButtonBarRect        = [rightButtonBar leftResizeControlFrame];
        rightButtonBarRect.origin = [self convertPoint:rightButtonBarRect.origin fromView:rightButtonBar];
    }

    // A hidden divider has no drag area of its own; see -effectiveRectOfDividerAtIndex:.
    if ([self _isDividerHiddenAtIndex:anIndex])
        effectiveRect = nil;
    else
        effectiveRect = [self _sendDelegateSplitViewEffectiveRect:effectiveRect forDrawnRect:effectiveRect ofDividerAtIndex:anIndex];

    additionalRect = [self _sendDelegateSplitViewAdditionalEffectiveRectOfDividerAtIndex:anIndex];

    return (effectiveRect && CGRectContainsPoint(effectiveRect, aPoint)) ||
           (additionalRect && CGRectContainsPoint(additionalRect, aPoint)) ||
           (leftButtonBarRect && CGRectContainsPoint(leftButtonBarRect, aPoint)) ||
           (rightButtonBarRect && CGRectContainsPoint(rightButtonBarRect, aPoint));
}

- (CPView)hitTest:(CGPoint)aPoint
{
    if ([self isHidden] || ![self hitTests] || !CGRectContainsPoint([self frame], aPoint))
        return nil;

    var point = [self convertPoint:aPoint fromView:[self superview]],
        dividerIndex = [self _dividerAtPoint:point];

    if (dividerIndex !== CPNotFound)
        return self;

    return [super hitTest:aPoint];
}

- (CPInteger)_dividerAtPoint:(CGPoint)aPoint
{
    for (var i = 0, count = [_dividerSubviews count]; i < count; i++)
    {
        if ([self cursorAtPoint:aPoint hitDividerAtIndex:i])
            return i;
    }

    return CPNotFound;
}
/*
    Tracks the divider.
    @param anEvent the input event
*/
- (void)trackDivider:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type == CPLeftMouseUp)
    {
        if ([anEvent clickCount] == 2 || (_isTracking && _currentDivider != CPNotFound))
        {
            // We disabled autosaving during tracking.
            _shouldAutosave = YES;
            _currentDivider = CPNotFound;
            _isTracking = NO;

            [self _autosave];
            [self _updateResizeCursor:anEvent];
        }

        return;
    }

    if (type == CPLeftMouseDown)
    {
        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        _currentDivider = [self _dividerAtPoint:point];

        var startPosition = [_arrangedSubviews[_currentDivider] frame].origin[_originComponent] + [self _sizeOfArrangedSubviewAtIndex:_currentDivider];

        if ([anEvent clickCount] == 2 &&
            [self _delegateRespondsToSplitViewCanCollapseSubview] &&
            [self _delegateRespondsToSplitViewshouldCollapseSubviewForDoubleClickOnDividerAtIndex])
        {
            /*
                A collapsed subview keeps its size, so the expansion restores that size. A
                subview with no size to restore opens to the middle of the available range.
            */
            var minPosition = [self minPossiblePositionOfDividerAtIndex:_currentDivider],
                maxPosition = [self maxPossiblePositionOfDividerAtIndex:_currentDivider],
                middlePosition = minPosition + (maxPosition - minPosition) / 2,
                viewA = _arrangedSubviews[_currentDivider],
                viewB = _arrangedSubviews[_currentDivider + 1];

            if ([self _sendDelegateSplitViewCanCollapseSubview:viewA] && [self _sendDelegateSplitViewShouldCollapseSubview:viewA forDoubleClickOnDividerAtIndex:_currentDivider])
            {
                var keptSizeA = [viewA frameSize][_sizeComponent];

                if ([self isSubviewCollapsed:viewA])
                    [self setPosition:keptSizeA >= 1 ? minPosition + keptSizeA : middlePosition ofDividerAtIndex:_currentDivider];
                else
                    [self setPosition:minPosition ofDividerAtIndex:_currentDivider];
            }
            else if ([self _sendDelegateSplitViewCanCollapseSubview:viewB] && [self _sendDelegateSplitViewShouldCollapseSubview:viewB forDoubleClickOnDividerAtIndex:_currentDivider])
            {
                var keptSizeB = [viewB frameSize][_sizeComponent];

                if ([self isSubviewCollapsed:viewB])
                    [self setPosition:keptSizeB >= 1 ? maxPosition - keptSizeB : middlePosition ofDividerAtIndex:_currentDivider];
                else
                    [self setPosition:maxPosition ofDividerAtIndex:_currentDivider];
            }
        }
        else
        {
            _initialOffset = startPosition - point[_originComponent];
            // Don't autosave during a resize. We'll wait until it's done.
            _shouldAutosave = NO;
        }

    }
    else if (type == CPLeftMouseDragged && _currentDivider != CPNotFound)
    {
        /*
            Each -setPosition:ofDividerAtIndex: posts a will-resize and a did-resize notification,
            as NSSplitView does for each step of a drag.

            2026-11-23: the mouse-down and the first drag event also posted a will-resize
            notification, with no did-resize notification to match. One drag posted three
            will-resize notifications and one did-resize notification.
        */
        if (!_isTracking)
        {
            // Don't autosave during a resize. We'll wait until it's done.
            _shouldAutosave = NO;
            _isTracking = YES;
        }

        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

        [self setPosition:(point[_originComponent] + _initialOffset) ofDividerAtIndex:_currentDivider];
        // Cursor might change if we reach a resize limit.
        [self _updateResizeCursor:anEvent];
    }

    [CPApp setTarget:self selector:@selector(trackDivider:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        dividerIndex = [self _dividerAtPoint:point];

    if (dividerIndex !== CPNotFound)
        [self trackDivider:anEvent];
}

- (void)viewDidMoveToWindow
{
    // Enable split view resize cursors. Commented out pending CPTrackingArea implementation.
    //[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)_updateResizeCursor:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if ([anEvent type] === CPLeftMouseUp && ![[self window] acceptsMouseMovedEvents])
    {
        [[CPCursor arrowCursor] set];
        return;
    }

    for (var i = 0, count = [_arrangedSubviews count] - 1; i < count; i++)
    {
        // If we are currently tracking, keep the resize cursor active even outside of hit areas.
        if (_currentDivider === i || (_currentDivider == CPNotFound && [self cursorAtPoint:point hitDividerAtIndex:i]))
        {
            var startPosition = [_arrangedSubviews[i] frame].origin[_originComponent] + [self _sizeOfArrangedSubviewAtIndex:i],
                canShrink = [self _realPositionForPosition:startPosition - 1 ofDividerAtIndex:i] < startPosition,
                canGrow = [self _realPositionForPosition:startPosition + 1 ofDividerAtIndex:i] > startPosition,
                cursor = [CPCursor arrowCursor];

            if ([self isSubviewCollapsed:_arrangedSubviews[i]])
                canGrow = YES; // Subview is collapsed.
            else if (!canShrink && [self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[i]])
                canShrink = YES; // Subview is collapsible.

            if ([self isSubviewCollapsed:_arrangedSubviews[i + 1]])
                // Right/lower subview is collapsed.
                canGrow = NO;
            else if (!canGrow && [self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[i + 1]])
                canGrow = YES; // Right/lower subview is collapsible.

            if (_isVertical && canShrink && canGrow)
                cursor = [CPCursor resizeLeftRightCursor];
            else if (_isVertical && canShrink)
                cursor = [CPCursor resizeLeftCursor];
            else if (_isVertical && canGrow)
                cursor = [CPCursor resizeRightCursor];
            else if (canShrink && canGrow)
                cursor = [CPCursor resizeUpDownCursor];
            else if (canShrink)
                cursor = [CPCursor resizeUpCursor];
            else if (canGrow)
                cursor = [CPCursor resizeDownCursor];

            [cursor set];
            return;
        }
    }

    [[CPCursor arrowCursor] set];
}

/*!
    Returns the maximum possible position of a divider at a given index.
    @param the index of the divider.
    @return float - the max possible position.
*/
- (float)maxPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    if (dividerIndex + 1 < [_arrangedSubviews count] - 1)
        return [_arrangedSubviews[dividerIndex + 1] frame].origin[_originComponent] + [self _sizeOfArrangedSubviewAtIndex:dividerIndex + 1] - [self _thicknessOfDividerAtIndex:dividerIndex];
    else
        return [self frame].size[_sizeComponent] - [self _thicknessOfDividerAtIndex:dividerIndex];
}

/*!
    Returns the minimum possible position of a divider at a given index.
    @param the index of the divider.
    @return float - the min possible position.
*/
- (float)minPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    if (dividerIndex > 0)
    {
        return [_arrangedSubviews[dividerIndex - 1] frame].origin[_originComponent] + [self _sizeOfArrangedSubviewAtIndex:dividerIndex - 1] + [self _thicknessOfDividerAtIndex:dividerIndex - 1];
    }
    else
        return 0;
}

- (int)_realPositionForPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    // not sure where this should override other positions?
    var proposedPosition = [self _sendDelegateSplitViewConstrainSplitPosition:position ofSubviewAt:dividerIndex];

    // Silently ignore bad positions which could result from odd delegate responses. We don't want these
    // bad results to go into the system and cause havoc with frame sizes as the split view tries to resize
    // its subviews.
    if (CPIsNumeric(proposedPosition))
        position = proposedPosition;

    var proposedMax = [self maxPossiblePositionOfDividerAtIndex:dividerIndex],
        proposedMin = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        actualMax = proposedMax,
        actualMin = proposedMin,
        proposedActualMin = [self _sendDelegateSplitViewConstrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex],
        proposedActualMax = [self _sendDelegateSplitViewConstrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];

    if (CPIsNumeric(proposedActualMin))
        actualMin = proposedActualMin;

    if (CPIsNumeric(proposedActualMax))
        actualMax = proposedActualMax;

    var viewA = _arrangedSubviews[dividerIndex],
        viewB = _arrangedSubviews[dividerIndex + 1],
        realPosition = MAX(MIN(position, actualMax), actualMin);

    // Is this position past the halfway point to collapse?
    if ((position < proposedMin + (actualMin - proposedMin) / 2) && [self _sendDelegateSplitViewCanCollapseSubview:viewA])
        realPosition = proposedMin;

    // We can also collapse to the right.
    if ((position > proposedMax - (proposedMax - actualMax) / 2) && [self _sendDelegateSplitViewCanCollapseSubview:viewB])
        realPosition = proposedMax;

    return realPosition;
}

/*!
    Sets the position of a divider at a given index.
    @param position - The float value of the position to place the divider.
    @param dividerIndex - The index of the divider to position.
*/
- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    [self _setResizeNotificationsSuppressed:YES];

    /*
        A divider at the start of its range collapses the subview before it, and a divider at
        the end of its range collapses the subview after it, when the delegate lets them
        collapse. A collapsed subview is hidden and keeps its size; a divider that moves away
        shows it again with the size the new position gives it.
    */
    var realPosition = [self _realPositionForPosition:position ofDividerAtIndex:dividerIndex],
        viewA = _arrangedSubviews[dividerIndex],
        viewB = _arrangedSubviews[dividerIndex + 1],
        thickness = [self _thicknessOfDividerAtIndex:dividerIndex],
        startA = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        endB = [self maxPossiblePositionOfDividerAtIndex:dividerIndex] + thickness,
        collapsesA = realPosition <= startA && [self _sendDelegateSplitViewCanCollapseSubview:viewA],
        collapsesB = !collapsesA && realPosition + thickness >= endB && [self _sendDelegateSplitViewCanCollapseSubview:viewB];

    [self _placeArrangedSubview:viewA from:startA to:realPosition collapsed:collapsesA];
    [self _placeArrangedSubview:viewB from:realPosition + thickness to:endB collapsed:collapsesB];

    /*
        The delegate can hide the divider next to a collapsed subview, so the collapse or the
        expansion can change the thickness of the divider. The subviews are then placed again
        with the new thickness. A divider that collapses the subview after it stays at the end
        of its range.
    */
    var newThickness = [self _thicknessOfDividerAtIndex:dividerIndex];

    if (newThickness !== thickness)
    {
        if (collapsesB)
            realPosition = endB - newThickness;

        [self _placeArrangedSubview:viewA from:startA to:realPosition collapsed:collapsesA];
        [self _placeArrangedSubview:viewB from:realPosition + newThickness to:endB collapsed:collapsesB];
    }

    [self _placeDividerAtIndex:dividerIndex at:realPosition];

    [self _updateRatios];

    if ([self _didSuppressResizeNotifications])
        [self _postNotificationDidResize];

    [self _setResizeNotificationsSuppressed:NO];
}

/*
    Places an arranged subview between two positions along the split. A collapsed subview is
    hidden at the start position and keeps its size; otherwise the subview is shown and fills
    the space between the positions. The resize notifications are posted only for a change.
*/
- (void)_placeArrangedSubview:(CPView)aSubview from:(float)start to:(float)end collapsed:(BOOL)shouldCollapse
{
    var oldFrame = [aSubview frame],
        frame = CGRectMakeCopy(oldFrame);

    frame.origin[_originComponent] = start;

    if (!shouldCollapse)
        frame.size[_sizeComponent] = end - start;

    if (CGRectEqualToRect(frame, oldFrame) && !![aSubview isHidden] === !!shouldCollapse)
        return;

    [self _maybePostWillResizeNotification];
    [aSubview setHidden:shouldCollapse];
    [aSubview setFrame:frame];
    [self _maybePostDidResizeNotification];
}

/*!
    Set the button bar who's resize control should act as a control for this splitview.
    Each divider can have at most one button bar assigned to it, and that button bar must be
    a subview of one of the split view's subviews.

    Calling this method with nil as the button bar will remove any currently assigned button bar
    for the divider at that index. Indexes will not be adjusted as new subviews are added, so you
    should usually call this method after adding all the desired subviews to the split view.

    This method will automatically configure the hasResizeControl and resizeControlIsLeftAligned
    parameters of the button bar, and will override any currently set values.

    @param CPButtonBar - The supplied button bar.
    @param unsigned int - The divider index the button bar will be assigned to.
*/
// FIXME Should be renamed to setButtonBar:ofDividerAtIndex:.
- (void)setButtonBar:(CPButtonBar)aButtonBar forDividerAtIndex:(CPUInteger)dividerIndex
{
    // For compatibility with previous behavior
    if ([aButtonBar respondsToSelector:@selector(setAutomaticResizeControl:)])
    {
        [aButtonBar setAutomaticResizeControl:YES];
        [self attachButtonBar:aButtonBar];
    }
}

- (void)attachButtonBar:(CPButtonBar)aButtonBar
{
    // Search the subview containing the button bar
    var view    = [aButtonBar superview],
        subview = aButtonBar;

    while (view && (view !== self))
    {
        subview = view;
        view    = [view superview];
    }

    if (view !== self)
        [CPException raise:CPInvalidArgumentException
                    reason:@"CPSplitView button bar must be a subview of the split view."];

    // ATTENTION !
    // If the button bar is created via IB, at this moment, the split view may not be ready : subviews are OK but
    // not arrangedSubviews. We can then assume that all subviews will be arranged subviews (as subviews declared
    // in IB are, in fact, arranged subviews).
    // BUT if the split view is ready, when must work on arranged subviews.
    //
    // To determine if the split view is ready, we have to make an hypothesis :
    //      if the number of subviews > 0 and the number of arranged subviews = 0, then the split view is not ready
    //
    // This hypothesis could be false if the split view doesn't arrange all subviews and if all subviews are not
    // arranged subviews. BUT this would mean that the split view has no real panes. And this should never happen
    // in real life.

    var arrangedSubviews      = [self arrangedSubviews],
        arrangedSubviewsCount = [arrangedSubviews count],
        subviews              = [self subviews],
        subviewsCount         = [subviews count],
        splitViewIsNotReady   = (subviewsCount > 0) && (arrangedSubviewsCount == 0),
        viewIndex             = [(splitViewIsNotReady ? subviews : arrangedSubviews) indexOfObject:subview];

    _buttonBars[viewIndex] = aButtonBar;

    // If needed, add resize control(s)
    if ([aButtonBar automaticResizeControl])
    {
        [aButtonBar setHasLeftResizeControl:(viewIndex > 0)];
        [aButtonBar setHasRightResizeControl:(viewIndex < (splitViewIsNotReady ? subviewsCount : arrangedSubviewsCount) - 1)];
    }
}

@end

// MARK: -

@implementation CPSplitView (CPTrackingArea)
{
    CPMutableArray  _splitViewTrackingAreas;
    CPMutableArray  _splitViewResizeControlTrackingAreas;
}

- (void)updateTrackingAreas
{
    if (_splitViewTrackingAreas)
    {
        for (var i = 0, count = _splitViewTrackingAreas.length; i < count; i++)
            [self removeTrackingArea:_splitViewTrackingAreas[i]];

        _splitViewTrackingAreas = nil;
    }

    if (_splitViewResizeControlTrackingAreas)
    {
        for (var i = 0, count = _splitViewResizeControlTrackingAreas.length; i < count; i++)
            [self removeTrackingArea:_splitViewResizeControlTrackingAreas[i]];

        _splitViewResizeControlTrackingAreas = nil;
    }

    var options = CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow;

    _splitViewTrackingAreas = @[];
    _splitViewResizeControlTrackingAreas = @[];

    // Seems to be needed when compiling themes
    if (_dividerSubviews)
    {
        for (var i = 0, count = _dividerSubviews.length; i < count; i++)
        {
            [_splitViewTrackingAreas addObject:[[CPTrackingArea alloc] initWithRect:[self effectiveRectOfDividerAtIndex:i]
                                                                            options:options
                                                                              owner:self
                                                                           userInfo:nil]];

            [self addTrackingArea:_splitViewTrackingAreas[i]];
        }

        for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        {
            if ([_buttonBars[i] hasLeftResizeControl])
            {
                var trackingArea = [[CPTrackingArea alloc] initWithRect:[self convertRect:[_buttonBars[i] leftResizeControlFrame] fromView:_buttonBars[i]]
                                                                options:options
                                                                  owner:self
                                                               userInfo:nil];

                [_splitViewResizeControlTrackingAreas addObject:trackingArea];
                [self addTrackingArea:trackingArea];
            }

            if ([_buttonBars[i] hasRightResizeControl])
            {
                var trackingArea = [[CPTrackingArea alloc] initWithRect:[self convertRect:[_buttonBars[i] rightResizeControlFrame] fromView:_buttonBars[i]]
                                                                options:options
                                                                  owner:self
                                                               userInfo:nil];

                [_splitViewResizeControlTrackingAreas addObject:trackingArea];
                [self addTrackingArea:trackingArea];
            }
        }
    }

    [super updateTrackingAreas];
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    [self _updateResizeCursor:anEvent];
}

@end
