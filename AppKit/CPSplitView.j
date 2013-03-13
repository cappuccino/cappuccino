/*
 * CPSplitView.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

#include "../Foundation/Foundation.h"

@import "CPButtonBar.j"
@import "CPImage.j"
@import "CPView.j"
@import "CPCursor.j"

@class CPUserDefaults
@global CPApp

#define SPLIT_VIEW_MAYBE_POST_WILL_RESIZE() \
    if ((_suppressResizeNotificationsMask & DidPostWillResizeNotification) === 0) \
    { \
        [self _postNotificationWillResize]; \
        _suppressResizeNotificationsMask |= DidPostWillResizeNotification; \
    }

#define SPLIT_VIEW_MAYBE_POST_DID_RESIZE() \
    if ((_suppressResizeNotificationsMask & ShouldSuppressResizeNotifications) !== 0) \
        _suppressResizeNotificationsMask |= DidSuppressResizeNotification; \
    else \
        [self _postNotificationDidResize];

#define SPLIT_VIEW_DID_SUPPRESS_RESIZE_NOTIFICATION() \
    ((_suppressResizeNotificationsMask & DidSuppressResizeNotification) !== 0)

#define SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(shouldSuppress) \
    if (shouldSuppress) \
        _suppressResizeNotificationsMask |= ShouldSuppressResizeNotifications; \
    else \
        _suppressResizeNotificationsMask = 0;

CPSplitViewDidResizeSubviewsNotification = @"CPSplitViewDidResizeSubviewsNotification";
CPSplitViewWillResizeSubviewsNotification = @"CPSplitViewWillResizeSubviewsNotification";

var ShouldSuppressResizeNotifications   = 1,
    DidPostWillResizeNotification       = 1 << 1,
    DidSuppressResizeNotification       = 1 << 2;

/*!
    @ingroup appkit
    @class CPSplitView

    CPSplitView is a view that allows you to stack several subviews vertically or horizontally. The user is given divider to resize the subviews.
    The divider indices are zero-based. So the divider on the top (or left for vertical dividers) will be index 0.

    CPSplitView can be supplied a delegate to provide control over the resizing of the splitview and subviews. Those methods are documented in setDelegate:

    CPSplitView will add dividers for each subview you add. So just like adding subviews to a CPView you should call addSubview: to add new resizable subviews in your splitview.
*/

@implementation CPSplitView : CPView
{
    id              _delegate;
    BOOL            _isVertical;
    BOOL            _isPaneSplitter;

    int             _currentDivider;
    float           _initialOffset;
    CPDictionary    _preCollapsePositions;

    CPString        _originComponent;
    CPString        _sizeComponent;

    CPArray         _DOMDividerElements;
    CPString        _dividerImagePath;
    int             _drawingDivider;

    CPString        _autosaveName;
    BOOL            _shouldAutosave;
    CGSize          _shouldRestoreFromAutosaveUnlessFrameSize;

    BOOL            _needsResizeSubviews;
    int             _suppressResizeNotificationsMask;

    CPArray         _buttonBars;
}

+ (CPString)defaultThemeClass
{
    return @"splitview";
}

+ (id)themeAttributes
{
    return @{
            @"divider-thickness": 1.0,
            @"pane-divider-thickness": 10.0,
            @"pane-divider-color": [CPColor grayColor],
            @"horizontal-divider-color": [CPNull null],
            @"vertical-divider-color": [CPNull null],
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _suppressResizeNotificationsMask = 0;
        _preCollapsePositions = [CPMutableDictionary new];
        _currentDivider = CPNotFound;

        _DOMDividerElements = [];
        _buttonBars = [];

        _shouldAutosave = YES;

        [self _setVertical:YES];
    }

    return self;
}

/*!
    Returns the thickness of the divider.
    @return float - the thickness of the divider.
*/
- (float)dividerThickness
{
    return [self currentValueForThemeAttribute:[self isPaneSplitter] ? @"pane-divider-thickness" : @"divider-thickness"];
}

/*!
    Returns YES if the dividers are vertical, otherwise NO.
    @return YES if vertical, otherwise NO.
*/
- (BOOL)isVertical
{
    return _isVertical;
}

/*!
    Sets if the splitview dividers are vertical.
    @param shouldBeVertical - YES if the splitview dividers should be vertical, otherwise NO.
*/
- (void)setVertical:(BOOL)shouldBeVertical
{
    if (![self _setVertical:shouldBeVertical])
        return;

    // Just re-adjust evenly.
    var frame = [self frame],
        dividerThickness = [self dividerThickness];

    [self _postNotificationWillResize];

    var eachSize = ROUND((frame.size[_sizeComponent] - dividerThickness * (_subviews.length - 1)) / _subviews.length),
        index = 0,
        count = _subviews.length;

    if ([self isVertical])
    {
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(ROUND((eachSize + dividerThickness) * index), 0, eachSize, frame.size.height)];
    }
    else
    {
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(0, ROUND((eachSize + dividerThickness) * index), frame.size.width, eachSize)];
    }

    [self setNeedsDisplay:YES];
    [self _postNotificationDidResize];

}

- (BOOL)_setVertical:(BOOL)shouldBeVertical
{
    var changed = (_isVertical != shouldBeVertical);

    _isVertical = shouldBeVertical;

    _originComponent = [self isVertical] ? "x" : "y";
    _sizeComponent = [self isVertical] ? "width" : "height";
    _dividerImagePath = [self isVertical] ? [[self valueForThemeAttribute:@"vertical-divider-color"] filename] : [[self valueForThemeAttribute:@"horizontal-divider-color"] filename];

    return changed;
}

/*!
    Use to find if the divider is a larger pane splitter.

    @return BOOL - YES if the dividers are the larger pane splitters. Otherwise NO.
*/
- (BOOL)isPaneSplitter
{
    return _isPaneSplitter;
}

/*!
    Used to set if the split view dividers should be the larger pane splitter.

    @param shouldBePaneSplitter - YES if the dividers should be the thicker pane splitter, otherwise NO.
*/
- (void)setIsPaneSplitter:(BOOL)shouldBePaneSplitter
{
    if (_isPaneSplitter == shouldBePaneSplitter)
        return;

    _isPaneSplitter = shouldBePaneSplitter;

    if (_DOMDividerElements[_drawingDivider])
        [self _setupDOMDivider];

    // The divider changes size when pane splitter mode is toggled, so the
    // subviews need to change size too.
    _needsResizeSubviews = YES;
    [self setNeedsDisplay:YES];
}

- (void)didAddSubview:(CPView)aSubview
{
    _needsResizeSubviews = YES;
}

/*!
    Returns YES if the supplied subview is collapsed, otherwise NO.
    @param aSubview - the subview you are interested in.
    @return BOOL - YES if the subview is collapsed, otherwise NO.
*/
- (BOOL)isSubviewCollapsed:(CPView)subview
{
    return [subview frame].size[_sizeComponent] < 1 ? YES : NO;
}

/*!
    Returns the CGRect of the divider at a given index.

    @param int - The index of a divider.
    @return CGRect - The rect of a divider.
*/
- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    var frame = [_subviews[aDivider] frame],
        rect = CGRectMakeZero();

    rect.size = [self frame].size;
    rect.size[_sizeComponent] = [self dividerThickness];
    rect.origin[_originComponent] = frame.origin[_originComponent] + frame.size[_sizeComponent];

    return rect;
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

- (void)drawRect:(CGRect)rect
{
    var count = [_subviews count] - 1;

    while ((count--) > 0)
    {
        _drawingDivider = count;
        [self drawDividerInRect:[self rectOfDividerAtIndex:count]];
    }
}

/*!
    @ignore
    Because we're use drawRect: to draw the dividers, but use DOM elements instead of CoreGraphics
    We must remove those DOM elements (the splitters) when the subview is removed.
*/
- (void)willRemoveSubview:(CPView)aView
{
#if PLATFORM(DOM)
    var dividerToRemove = _DOMDividerElements.pop();

    // The divider may not exist if we never rendered out the DOM.
    if (dividerToRemove)
        CPDOMDisplayServerRemoveChild(_DOMElement, dividerToRemove);
#endif

    _needsResizeSubviews = YES;
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)layoutSubviews
{
    [self _adjustSubviewsWithCalculatedSize]
}

/*!
    Draws the divider at a given rect.
    @param aRect - the rect of the divider to draw.
*/
- (void)drawDividerInRect:(CGRect)aRect
{
#if PLATFORM(DOM)
    if (!_DOMDividerElements[_drawingDivider])
    {
        _DOMDividerElements[_drawingDivider] = document.createElement("div");

        _DOMDividerElements[_drawingDivider].style.position = "absolute";
        _DOMDividerElements[_drawingDivider].style.backgroundRepeat = "repeat";

        CPDOMDisplayServerAppendChild(_DOMElement, _DOMDividerElements[_drawingDivider]);
    }

    [self _setupDOMDivider];
    CPDOMDisplayServerSetStyleLeftTop(_DOMDividerElements[_drawingDivider], NULL, CGRectGetMinX(aRect), CGRectGetMinY(aRect));
    CPDOMDisplayServerSetStyleSize(_DOMDividerElements[_drawingDivider], CGRectGetWidth(aRect), CGRectGetHeight(aRect));
#endif
}

- (void)_setupDOMDivider
{
    if (_isPaneSplitter)
    {
        _DOMDividerElements[_drawingDivider].style.backgroundColor = "";
        _DOMDividerElements[_drawingDivider].style.backgroundImage = "url('"+_dividerImagePath+"')";
    }
    else
    {
        _DOMDividerElements[_drawingDivider].style.backgroundColor = [[self currentValueForThemeAttribute:@"pane-divider-color"] cssString];
        _DOMDividerElements[_drawingDivider].style.backgroundImage = "";
    }
}

- (void)viewWillDraw
{
    [self _adjustSubviewsWithCalculatedSize];
}

- (void)_adjustSubviewsWithCalculatedSize
{
    if (!_needsResizeSubviews)
        return;

    _needsResizeSubviews = NO;

    [self resizeSubviewsWithOldSize:[self _calculateSize]];
}

- (CGSize)_calculateSize
{
    var subviews = [self subviews],
        count = subviews.length,
        size = CGSizeMakeZero();

    if ([self isVertical])
    {
        size.width += [self dividerThickness] * (count - 1);
        size.height = CGRectGetHeight([self frame]);
    }
    else
    {
        size.width = CGRectGetWidth([self frame]);
        size.height += [self dividerThickness] * (count - 1);
    }

    while (count--)
        size[_sizeComponent] += [subviews[count] frame].size[_sizeComponent];

    return size;
}

- (BOOL)cursorAtPoint:(CGPoint)aPoint hitDividerAtIndex:(int)anIndex
{
    var frame = [_subviews[anIndex] frame],
        startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent],
        effectiveRect = [self effectiveRectOfDividerAtIndex:anIndex],
        buttonBar = _buttonBars[anIndex],
        buttonBarRect = null,
        additionalRect = null;

    if (buttonBar != null)
    {
        buttonBarRect = [buttonBar resizeControlFrame];
        buttonBarRect.origin = [self convertPoint:buttonBarRect.origin fromView:buttonBar];
    }

    if ([_delegate respondsToSelector:@selector(splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:)])
        effectiveRect = [_delegate splitView:self effectiveRect:effectiveRect forDrawnRect:effectiveRect ofDividerAtIndex:anIndex];

    if ([_delegate respondsToSelector:@selector(splitView:additionalEffectiveRectOfDividerAtIndex:)])
        additionalRect = [_delegate splitView:self additionalEffectiveRectOfDividerAtIndex:anIndex];

    return CGRectContainsPoint(effectiveRect, aPoint) ||
           (additionalRect && CGRectContainsPoint(additionalRect, aPoint)) ||
           (buttonBarRect && CGRectContainsPoint(buttonBarRect, aPoint));
}

- (CPView)hitTest:(CGPoint)aPoint
{
    if ([self isHidden] || ![self hitTests] || !CGRectContainsPoint([self frame], aPoint))
        return nil;

    var point = [self convertPoint:aPoint fromView:[self superview]],
        count = [_subviews count] - 1;

    for (var i = 0; i < count; i++)
    {
        if ([self cursorAtPoint:point hitDividerAtIndex:i])
            return self;
    }

    return [super hitTest:aPoint];
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
        // We disabled autosaving during tracking.
        _shouldAutosave = YES;

        if (_currentDivider != CPNotFound)
        {
            _currentDivider = CPNotFound;
            [self _autosave];
            [self _updateResizeCursor:anEvent];
        }

        return;
    }

    if (type == CPLeftMouseDown)
    {
        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
            count = [_subviews count] - 1;

        _currentDivider = CPNotFound;

        for (var i = 0; i < count; i++)
        {
            var frame = [_subviews[i] frame],
                startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent];

            if ([self cursorAtPoint:point hitDividerAtIndex:i])
            {
                if ([anEvent clickCount] == 2 &&
                    [_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)] &&
                    [_delegate respondsToSelector:@selector(splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:)])
                {
                    var minPosition = [self minPossiblePositionOfDividerAtIndex:i],
                        maxPosition = [self maxPossiblePositionOfDividerAtIndex:i],
                        preCollapsePosition = [_preCollapsePositions objectForKey:"" + i] || 0;

                    if ([_delegate splitView:self canCollapseSubview:_subviews[i]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i]])
                            [self setPosition:preCollapsePosition ? preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:minPosition ofDividerAtIndex:i];
                    }
                    else if ([_delegate splitView:self canCollapseSubview:_subviews[i + 1]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i + 1] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i + 1]])
                            [self setPosition:preCollapsePosition ? preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:maxPosition ofDividerAtIndex:i];
                    }
                }
                else
                {
                    _currentDivider = i;
                    _initialOffset = startPosition - point[_originComponent];

                    // Don't autosave during a resize. We'll wait until it's done.
                    _shouldAutosave = NO;
                    [self _postNotificationWillResize];
                }
            }
        }

        if (_currentDivider === CPNotFound)
            return;
    }

    else if (type == CPLeftMouseDragged && _currentDivider != CPNotFound)
    {
        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

        [self setPosition:(point[_originComponent] + _initialOffset) ofDividerAtIndex:_currentDivider];
        // Cursor might change if we reach a resize limit.
        [self _updateResizeCursor:anEvent];
    }

    [CPApp setTarget:self selector:@selector(trackDivider:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    // FIXME: This should not trap events if not on a divider!
    [self trackDivider:anEvent];
}

- (void)viewDidMoveToWindow
{
    // Enable split view resize cursors. Commented out pending CPTrackingArea implementation.
    //[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    // Tracking code handles cursor by itself.
    if (_currentDivider == CPNotFound)
        [self _updateResizeCursor:anEvent];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    if (_currentDivider == CPNotFound)
        [self _updateResizeCursor:anEvent];
}

- (void)mouseExited:(CPEvent)anEvent
{
    if (_currentDivider == CPNotFound)
        // FIXME: we should use CPCursor push/pop (if previous currentCursor != arrow).
        [[CPCursor arrowCursor] set];
}

- (void)_updateResizeCursor:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if ([anEvent type] === CPLeftMouseUp && ![[self window] acceptsMouseMovedEvents])
    {
        [[CPCursor arrowCursor] set];
        return;
    }

    for (var i = 0, count = [_subviews count] - 1; i < count; i++)
    {
        // If we are currently tracking, keep the resize cursor active even outside of hit areas.
        if (_currentDivider === i || (_currentDivider == CPNotFound && [self cursorAtPoint:point hitDividerAtIndex:i]))
        {
            var frameA = [_subviews[i] frame],
                sizeA = frameA.size[_sizeComponent],
                startPosition = frameA.origin[_originComponent] + sizeA,
                frameB = [_subviews[i + 1] frame],
                sizeB = frameB.size[_sizeComponent],
                canShrink = [self _realPositionForPosition:startPosition - 1 ofDividerAtIndex:i] < startPosition,
                canGrow = [self _realPositionForPosition:startPosition + 1 ofDividerAtIndex:i] > startPosition,
                cursor = [CPCursor arrowCursor];

            if (sizeA === 0)
                canGrow = YES; // Subview is collapsed.
            else if (!canShrink &&
                     [_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)] &&
                     [_delegate splitView:self canCollapseSubview:_subviews[i]])
            {
                canShrink = YES; // Subview is collapsible.
            }

            if (sizeB === 0)
            {
                // Right/lower subview is collapsed.
                canGrow = NO;
                // It's safe to assume it can always be uncollapsed.
                canShrink = YES;
            }
            else if (!canGrow &&
                     [_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)] &&
                     [_delegate splitView:self canCollapseSubview:_subviews[i + 1]])
            {
                canGrow = YES; // Right/lower subview is collapsible.
            }

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
    var frame = [_subviews[dividerIndex + 1] frame];

    if (dividerIndex + 1 < [_subviews count] - 1)
        return frame.origin[_originComponent] + frame.size[_sizeComponent] - [self dividerThickness];
    else
        return [self frame].size[_sizeComponent] - [self dividerThickness];
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
        var frame = [_subviews[dividerIndex - 1] frame];

        return frame.origin[_originComponent] + frame.size[_sizeComponent] + [self dividerThickness];
    }
    else
        return 0;
}

- (int)_realPositionForPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    // not sure where this should override other positions?
    if ([_delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)])
    {
        var proposedPosition = [_delegate splitView:self constrainSplitPosition:position ofSubviewAt:dividerIndex];

        // Silently ignore bad positions which could result from odd delegate responses. We don't want these
        // bad results to go into the system and cause havoc with frame sizes as the split view tries to resize
        // its subviews.
        if (_IS_NUMERIC(proposedPosition))
            position = proposedPosition;
    }

    var proposedMax = [self maxPossiblePositionOfDividerAtIndex:dividerIndex],
        proposedMin = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        actualMax = proposedMax,
        actualMin = proposedMin;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
    {
        var proposedActualMin = [_delegate splitView:self constrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex];

        if (_IS_NUMERIC(proposedActualMin))
            actualMin = proposedActualMin;
    }

    if ([_delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
    {
        var proposedActualMax = [_delegate splitView:self constrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];

        if (_IS_NUMERIC(proposedActualMax))
            actualMax = proposedActualMax;
    }

    var viewA = _subviews[dividerIndex],
        viewB = _subviews[dividerIndex + 1],
        realPosition = MAX(MIN(position, actualMax), actualMin);

    // Is this position past the halfway point to collapse?
    if (position < proposedMin + (actualMin - proposedMin) / 2)
        if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
            if ([_delegate splitView:self canCollapseSubview:viewA])
                realPosition = proposedMin;

    // We can also collapse to the right.
    if (position > proposedMax - (proposedMax - actualMax) / 2)
        if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
            if ([_delegate splitView:self canCollapseSubview:viewB])
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
    // Any manual changes to the divider position should override anything we are restoring from
    // autosave.
    _shouldRestoreFromAutosaveUnlessFrameSize = nil;

    SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(YES);
    [self _adjustSubviewsWithCalculatedSize];

    var realPosition = [self _realPositionForPosition:position ofDividerAtIndex:dividerIndex],
        viewA = _subviews[dividerIndex],
        frameA = [viewA frame],
        viewB = _subviews[dividerIndex + 1],
        frameB = [viewB frame],
        preCollapsePosition = 0,
        preSize = frameA.size[_sizeComponent];

    frameA.size[_sizeComponent] = realPosition - frameA.origin[_originComponent];

    if (preSize !== 0 && frameA.size[_sizeComponent] === 0)
        preCollapsePosition = preSize;

    if (preSize !== frameA.size[_sizeComponent])
    {
        SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
        [_subviews[dividerIndex] setFrame:frameA];
        SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
    }

    preSize = frameB.size[_sizeComponent];

    var preOrigin = frameB.origin[_originComponent];
    frameB.size[_sizeComponent] = frameB.origin[_originComponent] + frameB.size[_sizeComponent] - realPosition - [self dividerThickness];

    if (preSize !== 0 && frameB.size[_sizeComponent] === 0)
        preCollapsePosition = frameB.origin[_originComponent];

    frameB.origin[_originComponent] = realPosition + [self dividerThickness];

    if (preSize !== frameB.size[_sizeComponent] || preOrigin !== frameB.origin[_originComponent])
    {
        SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
        [_subviews[dividerIndex + 1] setFrame:frameB];
        SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
    }

    if (preCollapsePosition)
        [_preCollapsePositions setObject:preCollapsePosition forKey:"" + dividerIndex];

    [self setNeedsDisplay:YES];

    if (SPLIT_VIEW_DID_SUPPRESS_RESIZE_NOTIFICATION())
        [self _postNotificationDidResize];

    SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(NO);
}

- (void)setFrameSize:(CGSize)aSize
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = NO;
    else
        [self _adjustSubviewsWithCalculatedSize];

    [super setFrameSize:aSize];

    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = YES;

    [self setNeedsDisplay:YES];
}

- (void)resizeSubviewsWithOldSize:(CGSize)oldSize
{
    if ([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
    {
        [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
        return;
    }

    [self adjustSubviews];
}

- (void)adjustSubviews
{
    var count = [_subviews count];

    if (!count)
        return;

    SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
    [self _postNotificationWillResize];

    var index = 0,
        bounds = [self bounds],
        boundsSize = bounds.size[_sizeComponent],
        oldSize = [self _calculateSize],
        dividerThickness = [self dividerThickness],
        totalDividers = count - 1,
        oldFlexibleSpace = 0,
        totalSizablePanes = 0,
        isSizableMap = {},
        viewSizes = [],
        delegateRespondsToShouldAdjust = [_delegate respondsToSelector:@selector(splitView:shouldAdjustSizeOfSubview:)];

    // What we want to do is to preserve non resizable sizes first, and then to preserve the ratio of size to available
    // non fixed space for every other subview. E.g. assume fixed space was 20 pixels initially, view 1 was 20 and
    // view 2 was 30 pixels, for a total of 70 pixels. Then the new total size becomes 140 pixels. Now we want the fixed
    // space to still be 20 pixels, view 1 to be 48 pixels and view 2 to be 72 pixels. This way the relative size of
    // view 1 to view 2 remains the same - view 1 was 66% of view 2 initially and after the resize view 1 is still
    // 66% of view 2's size.
    //
    // For this calculation, we can consider the dividers themselves to also be fixed size areas - they should remain
    // the same size before and after.

    // How much flexible size do we have in pre-resize pixels?
    for (index = 0; index < count; ++index)
    {
        var view = _subviews[index],
            isSizable = !delegateRespondsToShouldAdjust || [_delegate splitView:self shouldAdjustSizeOfSubview:view],
            size = [view frame].size[_sizeComponent];

        isSizableMap[index] = isSizable;
        viewSizes.push(size);

        if (isSizable)
        {
            oldFlexibleSpace += size;
            totalSizablePanes++;
        }
    }

    // nonSizableSpace is the number of fixed pixels in pre-resize terms and the desired number post-resize.
    var nonSizableSpace = oldSize[_sizeComponent] - oldFlexibleSpace,
        newFlexibleSpace = boundsSize - nonSizableSpace,
        remainingFixedPixelsToRemove = 0;

    if (newFlexibleSpace < 0)
    {
        remainingFixedPixelsToRemove = -newFlexibleSpace;
        newFlexibleSpace = 0;
    }

    var remainingFixedPanes = count - totalSizablePanes;

    for (index = 0; index < count; ++index)
    {
        var view = _subviews[index],
            viewFrame = CGRectMakeCopy(bounds),
            isSizable = isSizableMap[index],
            targetSize = 0;

        // The last area must take up exactly the remaining space, fixed or not.
        if (index + 1 === count)
            targetSize = boundsSize - viewFrame.origin[_originComponent];
        // Try to keep fixed size areas the same size.
        else if (!isSizable)
        {
            var removedFixedPixels = MIN(remainingFixedPixelsToRemove / remainingFixedPanes, viewSizes[index]);
            targetSize = viewSizes[index] - removedFixedPixels;
            remainingFixedPixelsToRemove -= removedFixedPixels;
            remainingFixedPanes--;
        }
        // (new size / flexible size available) == (old size / old flexible size available)
        else if (oldFlexibleSpace > 0)
            targetSize = newFlexibleSpace * viewSizes[index] / oldFlexibleSpace;
        // oldFlexibleSpace <= 0 so all flexible areas were crushed. When we get space, allocate it evenly.
        // totalSizablePanes cannot be 0 since isSizable.
        else
            targetSize = newFlexibleSpace / totalSizablePanes;

        targetSize = MAX(0, ROUND(targetSize));
        viewFrame.size[_sizeComponent] = targetSize;
        [view setFrame:viewFrame];
        bounds.origin[_originComponent] += targetSize + dividerThickness;
    }

    SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
}

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

    @param delegate - The delegate of the splitview.
*/
- (void)setDelegate:(id)delegate
{
    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        [[CPNotificationCenter defaultCenter] removeObserver:_delegate name:CPSplitViewDidResizeSubviewsNotification object:self];
    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        [[CPNotificationCenter defaultCenter] removeObserver:_delegate name:CPSplitViewWillResizeSubviewsNotification object:self];

   _delegate = delegate;

   if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
       [[CPNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewDidResizeSubviews:)
                                                    name:CPSplitViewDidResizeSubviewsNotification
                                                  object:self];
   if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
       [[CPNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewWillResizeSubviews:)
                                                    name:CPSplitViewWillResizeSubviewsNotification
                                                  object:self];
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
- (void)setButtonBar:(CPButtonBar)aButtonBar forDividerAtIndex:(unsigned)dividerIndex
{
    if (!aButtonBar)
    {
        _buttonBars[dividerIndex] = nil;
        return;
    }

    var view = [aButtonBar superview],
        subview = aButtonBar;

    while (view && view !== self)
    {
        subview = view;
        view = [view superview];
    }

    if (view !== self)
        [CPException raise:CPInvalidArgumentException
                    reason:@"CPSplitView button bar must be a subview of the split view."];

    var viewIndex = [[self subviews] indexOfObject:subview];

    [aButtonBar setHasResizeControl:YES];
    [aButtonBar setResizeControlIsLeftAligned:dividerIndex < viewIndex];

    _buttonBars[dividerIndex] = aButtonBar;
}

- (void)_postNotificationWillResize
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewWillResizeSubviewsNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)_postNotificationDidResize
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewDidResizeSubviewsNotification
                                                        object:self
                                                      userInfo:userInfo];


    // TODO Cocoa always autosaves on "viewDidEndLiveResize". If Cappuccino adds support for this we
    // should do the same.
    [self _autosave];
}

/*!
    Set the name under which the split view divider positions is automatically saved to CPUserDefaults.

    @param autosaveName the name to save under or nil to not save
*/
- (void)setAutosaveName:(CPString)autosaveName
{
    if (_autosaveName == autosaveName)
        return;

    _autosaveName = autosaveName;
}

/*!
    Get the name under which the split view divider position is automatically saved to CPUserDefaults.

    @return the name to save under or nil if no autosave is active
*/
- (CPString)autosaveName
{
    return _autosaveName;
}

/*!
    @ignore
*/
- (void)_autosave
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize || !_shouldAutosave || !_autosaveName)
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        count = [_subviews count],
        positions = [CPMutableArray new],
        preCollapseArray = [CPMutableArray new];

    for (var i = 0; i < count; i++)
    {
        var frame = [_subviews[i] frame];
        [positions addObject:CGStringFromRect(frame)];
        [preCollapseArray addObject:[_preCollapsePositions objectForKey:"" + i]];
    }

    [userDefaults setObject:positions forKey:autosaveName];
    [userDefaults setObject:preCollapseArray forKey:autosavePrecollapseName];
}

/*!
    This is called sometime later after a split view has been restored from a Cib.
    See notes in initWithCoder.

    @ignore
*/
- (void)_restoreFromAutosaveIfNeeded
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize && !CGSizeEqualToSize([self frameSize], _shouldRestoreFromAutosaveUnlessFrameSize))
    {
        [self _restoreFromAutosave];
    }

    _shouldRestoreFromAutosaveUnlessFrameSize = nil;
}

/*!
    @ignore
*/
- (void)_restoreFromAutosave
{
    if (!_autosaveName)
        return;

    var autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        userDefaults = [CPUserDefaults standardUserDefaults],
        frames = [userDefaults objectForKey:autosaveName],
        preCollapseArray = [userDefaults objectForKey:autosavePrecollapseName];

    if (frames)
    {
        var dividerThickness = [self dividerThickness],
            position = 0;

        _shouldAutosave = NO;

        for (var i = 0, count = [frames count] - 1; i < count; i++)
        {
            var frame = CGRectFromString(frames[i]);
            position += frame.size[_sizeComponent];

            [self setPosition:position ofDividerAtIndex:i];

            position += dividerThickness;
        }

        _shouldAutosave = YES;
    }

    if (preCollapseArray)
    {
        _preCollapsePositions = [CPMutableDictionary new];

        for (var i = 0, count = [preCollapseArray count]; i < count; i++)
        {
            var item = preCollapseArray[i];

            if (item === nil)
                [_preCollapsePositions removeObjectForKey:String(i)];
            else
                [_preCollapsePositions setObject:item forKey:String(i)];
        }
    }
}

/*!
    @ignore
*/
- (CPString)_framesKeyForAutosaveName:(CPString)theAutosaveName
{
    if (!theAutosaveName)
        return nil;

    return @"CPSplitView Subview Frames " + theAutosaveName;
}

/*!
    @ignore
*/
- (CPString)_precollapseKeyForAutosaveName:(CPString)theAutosaveName
{
    if (!theAutosaveName)
        return nil;

    return @"CPSplitView Subview Precollapse Positions " + theAutosaveName;
}

@end

var CPSplitViewDelegateKey          = "CPSplitViewDelegateKey",
    CPSplitViewIsVerticalKey        = "CPSplitViewIsVerticalKey",
    CPSplitViewIsPaneSplitterKey    = "CPSplitViewIsPaneSplitterKey",
    CPSplitViewButtonBarsKey        = "CPSplitViewButtonBarsKey",
    CPSplitViewAutosaveNameKey      = "CPSplitViewAutosaveNameKey";

@implementation CPSplitView (CPCoding)

/*
    Initializes the split view by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPSplitView.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    // We need to restore this property before calling super's initWithCoder:.
    _autosaveName = [aCoder decodeObjectForKey:CPSplitViewAutosaveNameKey];

    /*

    It is common for the main window of a Cappuccino app window to be resized to match the browser
    window size at the end of the UI being loaded from a cib. But at decoding time (now) whatever
    window size was originally saved will be in place, so if we try to restore the autosaved divider
    positions now they might be constrained to the wrong positions due to the difference in frame size,
    and in addition they might move later when the window is resized.

    The workaround is to restore the position once now (so it's approximately correct during loading),
    and then once more in the next runloop cycle when any `setFullPlatformWindow` calls are done.

    (However if the frame size doesn't change before the next cycle, we should not restore the position
    again because that would overwrite any changes the app developer might have made in user code.)

    The other consideration is that any parent split views need to be restored before any child
    subviews, otherwise the parent restore will also change the positioning of the child.

    */
    if (_autosaveName)
    {
        // Schedule /before/ [super initWithCoder:]. This way this instance's _restoreFromAutosaveIfNeeded
        // will happen before that of any subviews loaded by [super initWithCoder:].
        [[CPRunLoop currentRunLoop] performSelector:@selector(_restoreFromAutosaveIfNeeded) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    }

    self = [super initWithCoder:aCoder];

    if (self)
    {
        _suppressResizeNotificationsMask = 0;
        _preCollapsePositions = [CPMutableDictionary new];

        _currentDivider = CPNotFound;
        _shouldAutosave = YES;

        _DOMDividerElements = [];

        _buttonBars = [aCoder decodeObjectForKey:CPSplitViewButtonBarsKey] || [];

        [self setDelegate:[aCoder decodeObjectForKey:CPSplitViewDelegateKey]];

        _isPaneSplitter = [aCoder decodeBoolForKey:CPSplitViewIsPaneSplitterKey];
        [self _setVertical:[aCoder decodeBoolForKey:CPSplitViewIsVerticalKey]];

        if (_autosaveName)
        {
            [self _restoreFromAutosave];
            // Remember the frame size we had at this point so that we can restore again if it changes
            // before the next runloop cycle. See above notes.
            _shouldRestoreFromAutosaveUnlessFrameSize = [self frameSize];
        }
    }

    return self;
}

/*
    Archives this split view into the provided coder.
    @param aCoder the coder to which the button's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    //FIXME how should we handle this?
    //[aCoder encodeObject:_buttonBars forKey:CPSplitViewButtonBarsKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPSplitViewDelegateKey];

    [aCoder encodeBool:_isVertical forKey:CPSplitViewIsVerticalKey];
    [aCoder encodeBool:_isPaneSplitter forKey:CPSplitViewIsPaneSplitterKey];

    [aCoder encodeObject:_autosaveName forKey:CPSplitViewAutosaveNameKey];
}

@end
