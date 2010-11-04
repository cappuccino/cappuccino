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

@import "CPButtonBar.j"
@import "CPImage.j"
@import "CPView.j"


CPSplitViewDidResizeSubviewsNotification = @"CPSplitViewDidResizeSubviewsNotification";
CPSplitViewWillResizeSubviewsNotification = @"CPSplitViewWillResizeSubviewsNotification";

var CPSplitViewHorizontalImage = nil,
    CPSplitViewVerticalImage = nil;

/*!
    @ingroup appkit
*/

@implementation CPSplitView : CPView
{
    id          _delegate;
    BOOL        _isVertical;
    BOOL        _isPaneSplitter;

    int         _currentDivider;
    float       _initialOffset;
    float       _preCollapsePosition;

    CPString    _originComponent;
    CPString    _sizeComponent;

    CPArray     _DOMDividerElements;
    CPString    _dividerImagePath;
    int         _drawingDivider;

    BOOL        _needsResizeSubviews;

    CPArray     _buttonBars;
}

+ (CPString)defaultThemeClass
{
    return @"splitview";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[10.0, 1.0, [CPColor grayColor]]
                                       forKeys:[@"divider-thickness", @"pane-divider-thickness", @"pane-divider-color"]];
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self != [CPSplitView class])
        return;

    var bundle = [CPBundle bundleForClass:self];
    CPSplitViewHorizontalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewHorizontal.png"] size:CPSizeMake(5.0, 10.0)];
    CPSplitViewVerticalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewVertical.png"] size:CPSizeMake(10.0, 5.0)];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _currentDivider = CPNotFound;

        _DOMDividerElements = [];
        _buttonBars = [];

        [self _setVertical:YES];
    }

    return self;
}

- (float)dividerThickness
{
    return [self currentValueForThemeAttribute:[self isPaneSplitter] ? @"pane-divider-thickness" : @"divider-thickness"];
}

- (BOOL)isVertical
{
    return _isVertical;
}

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
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(ROUND((eachSize + dividerThickness) * index), 0, eachSize, frame.size.height)];
    else
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(0, ROUND((eachSize + dividerThickness) * index), frame.size.width, eachSize)];

    [self setNeedsDisplay:YES];

    [self _postNotificationDidResize];

}

- (BOOL)_setVertical:(BOOL)shouldBeVertical
{
    var changed = (_isVertical != shouldBeVertical);

    _isVertical = shouldBeVertical;

    _originComponent = [self isVertical] ? "x" : "y";
    _sizeComponent = [self isVertical] ? "width" : "height";
    _dividerImagePath = [self isVertical] ? [CPSplitViewVerticalImage filename] : [CPSplitViewHorizontalImage filename];

    return changed;
}

- (BOOL)isPaneSplitter
{
    return _isPaneSplitter;
}

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

- (BOOL)isSubviewCollapsed:(CPView)subview
{
    return [subview frame].size[_sizeComponent] < 1 ? YES : NO;
}

- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    var frame = [_subviews[aDivider] frame],
        rect = CGRectMakeZero();

    rect.size = [self frame].size;

    rect.size[_sizeComponent] = [self dividerThickness];
    rect.origin[_originComponent] = frame.origin[_originComponent] + frame.size[_sizeComponent];

    return rect;
}

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
    CPDOMDisplayServerSetStyleLeftTop(_DOMDividerElements[_drawingDivider], NULL, _CGRectGetMinX(aRect), _CGRectGetMinY(aRect));
    CPDOMDisplayServerSetStyleSize(_DOMDividerElements[_drawingDivider], _CGRectGetWidth(aRect), _CGRectGetHeight(aRect));
#endif
}

- (void)_setupDOMDivider
{
    if (_isPaneSplitter)
    {
        _DOMDividerElements[_drawingDivider].style.backgroundColor = [[self currentValueForThemeAttribute:@"pane-divider-color"] cssString];
        _DOMDividerElements[_drawingDivider].style.backgroundImage = "";
    }
    else
    {
        _DOMDividerElements[_drawingDivider].style.backgroundColor = "";
        _DOMDividerElements[_drawingDivider].style.backgroundImage = "url('"+_dividerImagePath+"')";
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

    var subviews = [self subviews],
        count = subviews.length,
        oldSize = CGSizeMakeZero();

    if ([self isVertical])
    {
        oldSize.width += [self dividerThickness] * (count - 1);
        oldSize.height = CGRectGetHeight([self frame]);
    }
    else
    {
        oldSize.width = CGRectGetWidth([self frame]);
        oldSize.height += [self dividerThickness] * (count - 1);
    }

    while (count--)
        oldSize[_sizeComponent] += [subviews[count] frame].size[_sizeComponent];

    [self resizeSubviewsWithOldSize:oldSize];
}

- (BOOL)cursorAtPoint:(CPPoint)aPoint hitDividerAtIndex:(int)anIndex
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
        if (_currentDivider != CPNotFound)
        {
            _currentDivider = CPNotFound;
            [self _updateResizeCursor:anEvent];
            [self _postNotificationDidResize];
        }

        return;
    }

    if (type == CPLeftMouseDown)
    {
        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

        _currentDivider = CPNotFound;
        var count = [_subviews count] - 1;
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
                        maxPosition = [self maxPossiblePositionOfDividerAtIndex:i];

                    if ([_delegate splitView:self canCollapseSubview:_subviews[i]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i]])
                            [self setPosition:_preCollapsePosition ? _preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:minPosition ofDividerAtIndex:i];
                    }
                    else if ([_delegate splitView:self canCollapseSubview:_subviews[i + 1]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i + 1] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i + 1]])
                            [self setPosition:_preCollapsePosition ? _preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:maxPosition ofDividerAtIndex:i];
                    }
                }
                else
                {
                    _currentDivider = i;
                    _initialOffset = startPosition - point[_originComponent];

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
            var frame = [_subviews[i] frame],
                size = frame.size[_sizeComponent],
                startPosition = frame.origin[_originComponent] + size,
                canShrink = [self _realPositionForPosition:startPosition - 1 ofDividerAtIndex:i] < startPosition,
                canGrow = [self _realPositionForPosition:startPosition + 1 ofDividerAtIndex:i] > startPosition,
                cursor = [CPCursor arrowCursor];

            if (size === 0)
                canGrow = YES; // Subview is collapsed.
            else if (!canShrink &&
                [_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)] &&
                [_delegate splitView:self canCollapseSubview:_subviews[i]])
                canShrink = YES; // Subview is collapsible.

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

- (float)maxPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    var frame = [_subviews[dividerIndex + 1] frame];

    if (dividerIndex + 1 < [_subviews count] - 1)
        return frame.origin[_originComponent] + frame.size[_sizeComponent] - [self dividerThickness];
    else
        return [self frame].size[_sizeComponent] - [self dividerThickness];
}

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
        position = [_delegate splitView:self constrainSplitPosition:position ofSubviewAt:dividerIndex];

    var proposedMax = [self maxPossiblePositionOfDividerAtIndex:dividerIndex],
        proposedMin = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        actualMax = proposedMax,
        actualMin = proposedMin;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
        actualMin = [_delegate splitView:self constrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex];

    if ([_delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
        actualMax = [_delegate splitView:self constrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];

    var viewA = _subviews[dividerIndex],
        realPosition = MAX(MIN(position, actualMax), actualMin);

    if (position <  proposedMin + (actualMin - proposedMin) / 2)
        if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
            if ([_delegate splitView:self canCollapseSubview:viewA])
                realPosition = proposedMin;

    return realPosition;
}

- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    [self _adjustSubviewsWithCalculatedSize];

    var realPosition = [self _realPositionForPosition:position ofDividerAtIndex:dividerIndex];

    var viewA = _subviews[dividerIndex],
        frameA = [viewA frame],
        viewB = _subviews[dividerIndex + 1],
        frameB = [viewB frame];

    _preCollapsePosition = 0;

    var preSize = frameA.size[_sizeComponent];
    frameA.size[_sizeComponent] = realPosition - frameA.origin[_originComponent];
    if (preSize !== 0 && frameA.size[_sizeComponent] === 0)
        _preCollapsePosition = preSize;
    [_subviews[dividerIndex] setFrame:frameA];

    preSize = frameB.size[_sizeComponent];
    frameB.size[_sizeComponent] = frameB.origin[_originComponent] + frameB.size[_sizeComponent] - realPosition - [self dividerThickness];
    if (preSize !== 0 && frameB.size[_sizeComponent] === 0)
        _preCollapsePosition = preSize;
    frameB.origin[_originComponent] = realPosition + [self dividerThickness];
    [_subviews[dividerIndex + 1] setFrame:frameB];

    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(CGSize)aSize
{
    [self _adjustSubviewsWithCalculatedSize];

    [super setFrameSize:aSize];

    [self setNeedsDisplay:YES];
}

- (void)resizeSubviewsWithOldSize:(CPSize)oldSize
{
    if ([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
    {
        [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
        return;
    }

    [self _postNotificationWillResize];

    var index = 0,
        count = [_subviews count],
        bounds = [self bounds],
        dividerThickness = [self dividerThickness],
        totalDividers = count - 1,
        totalSizableSpace = 0,
        nonSizableSpace = 0,
        lastSizableIndex = -1,
        totalSizablePanes = 0,
        isVertical = [self isVertical];

    for (index = 0; index < count; ++index)
    {
        var view = _subviews[index],
            isSizable = isVertical ? [view autoresizingMask] & CPViewWidthSizable : [view autoresizingMask] & CPViewHeightSizable;

        if (isSizable)
        {
            totalSizableSpace += [view frame].size[_sizeComponent];
            lastSizableIndex = index;
            totalSizablePanes++;
        }
    }

    if (totalSizablePanes === count)
        totalSizableSpace = 0;

    var nonSizableSpace = totalSizableSpace ? bounds.size[_sizeComponent] - totalSizableSpace : 0,
        remainingFlexibleSpace = bounds.size[_sizeComponent] - oldSize[_sizeComponent],
        oldDimension = (oldSize[_sizeComponent] - totalDividers * dividerThickness - nonSizableSpace),
        ratio = oldDimension <= 0 ? 0 : (bounds.size[_sizeComponent] - totalDividers * dividerThickness - nonSizableSpace) / oldDimension;

    for (index = 0; index < count; ++index)
    {
        var view = _subviews[index],
            viewFrame = CGRectMakeCopy(bounds),
            isSizable = isVertical ? [view autoresizingMask] & CPViewWidthSizable : [view autoresizingMask] & CPViewHeightSizable;

            if (index + 1 == count)
                viewFrame.size[_sizeComponent] = bounds.size[_sizeComponent] - viewFrame.origin[_originComponent];
            else if (totalSizableSpace && isSizable && lastSizableIndex === index)
                viewFrame.size[_sizeComponent] = MAX(0, ROUND([view frame].size[_sizeComponent] + remainingFlexibleSpace))
            else if (isSizable || !totalSizableSpace)
            {
                viewFrame.size[_sizeComponent] = MAX(0, ROUND(ratio * [view frame].size[_sizeComponent]));
                remainingFlexibleSpace -= (viewFrame.size[_sizeComponent] - [view frame].size[_sizeComponent]);
            }
            else if (totalSizableSpace && !isSizable)
                viewFrame.size[_sizeComponent] = [view frame].size[_sizeComponent];

        bounds.origin[_originComponent] += viewFrame.size[_sizeComponent] + dividerThickness;

        [view setFrame:viewFrame];
    }

    [self _postNotificationDidResize];
}

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
*/
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
    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewWillResizeSubviewsNotification object:self];
}

- (void)_postNotificationDidResize
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewDidResizeSubviewsNotification object:self];
}

@end

var CPSplitViewDelegateKey          = "CPSplitViewDelegateKey",
    CPSplitViewIsVerticalKey        = "CPSplitViewIsVerticalKey",
    CPSplitViewIsPaneSplitterKey    = "CPSplitViewIsPaneSplitterKey",
    CPSplitViewButtonBarsKey        = "CPSplitViewButtonBarsKey";

@implementation CPSplitView (CPCoding)

/*
    Initializes the split view by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPSplitView.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _currentDivider = CPNotFound;

        _DOMDividerElements = [];

        _buttonBars = [aCoder decodeObjectForKey:CPSplitViewButtonBarsKey] || [];

        _delegate = [aCoder decodeObjectForKey:CPSplitViewDelegateKey];

        _isPaneSplitter = [aCoder decodeBoolForKey:CPSplitViewIsPaneSplitterKey];
        [self _setVertical:[aCoder decodeBoolForKey:CPSplitViewIsVerticalKey]];
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
}

@end
