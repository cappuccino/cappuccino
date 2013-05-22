/*
 * _CPWindowView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
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

@import "CPImageView.j"
@import "CPView.j"
@import "CPWindow_Constants.j"

@class CPCursor
@class CPMenu
@class CPPlatformWindow

@global CPApp

var _CPWindowViewCornerResizeRectWidth = 10,
    _CPWindowViewMinContentHeight = 2,

    _CPWindowViewResizeRegionNone = -1,
    _CPWindowViewResizeRegionTopLeft = 0,
    _CPWindowViewResizeRegionTop = 1,
    _CPWindowViewResizeRegionTopRight = 2,
    _CPWindowViewResizeRegionRight = 3,
    _CPWindowViewResizeRegionBottomRight = 4,
    _CPWindowViewResizeRegionBottom = 5,
    _CPWindowViewResizeRegionBottomLeft = 6,
    _CPWindowViewResizeRegionLeft = 7;

_CPWindowViewResizeSlop = 3;


@implementation _CPWindowView : CPView
{
    unsigned    _styleMask;

    CPImageView _resizeIndicator;
    CGSize      _resizeIndicatorOffset;

    CPView      _toolbarView;
    CGSize      _toolbarOffset;
//    BOOL        _isAnimatingToolbar;

    CGRect      _cachedFrame;
    int         _resizeRegion;
    CGPoint     _mouseDraggedPoint;

    CGRect      _cachedScreenFrame;

    CPView      _sheetShadowView;
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    return CGRectMakeCopy(aFrameRect);
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    return CGRectMakeCopy(aContentRect);
}

+ (CPString)defaultThemeClass
{
    return "window";
}

+ (id)themeAttributes
{
    return @{
            @"title-bar-height": 25,
            @"shadow-inset": CGInsetMakeZero(),
            @"shadow-distance": 5,
            @"window-shadow-color": [CPColor clearColor],
            @"size-indicator": CGSizeMakeZero(),
            @"resize-indicator": [CPNull null],
            @"attached-sheet-shadow-color": [CPColor blackColor],
            @"shadow-height": 8,
            @"close-image-origin": [CPNull null],
            @"close-image-size": [CPNull null],
            @"close-image": [CPNull null],
            @"close-active-image": [CPNull null],
            @"bezel-color": [CPNull null],
            @"title-text-color": [CPColor blackColor],
            @"title-font": [CPFont systemFontOfSize:CPFontCurrentSystemSize],
            @"title-text-shadow-color": [CPNull null],
            @"title-text-shadow-offset": CGSizeMakeZero(),
            @"title-alignment": CPCenterTextAlignment,
            @"title-line-break-mode": CPLineBreakByTruncatingTail,
            @"title-vertical-alignment": CPTopVerticalTextAlignment,
        };
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [[self class] contentRectForFrameRect:aFrameRect],
        theToolbar = [[self window] toolbar];

    if ([theToolbar isVisible])
    {
        var toolbarHeight = CGRectGetHeight([[theToolbar _toolbarView] frame]);

        contentRect.origin.y += toolbarHeight;
        contentRect.size.height -= toolbarHeight;
    }

    return contentRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = [[self class] frameRectForContentRect:aContentRect],
        theToolbar = [[self window] toolbar];

    if ([theToolbar isVisible])
    {
        var toolbarHeight = CGRectGetHeight([[theToolbar _toolbarView] frame]);

        frameRect.origin.y -= toolbarHeight;
        frameRect.size.height += toolbarHeight;
    }

    return frameRect;
}

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _styleMask = aStyleMask;
        _resizeIndicatorOffset = CGSizeMakeZero();
        _toolbarOffset = CGSizeMakeZero();
    }

    return self;
}

- (void)setDocumentEdited:(BOOL)isEdited
{
}

- (void)setTitle:(CPString)aTitle
{
}

- (CPView)hitTest:(CGPoint)locationInWindow
{
    var region = [self resizeRegionForPoint:[_window convertBaseToGlobal:locationInWindow]];

    if (region !== _CPWindowViewResizeRegionNone)
        return self;
    else
        return [super hitTest:locationInWindow];
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var theWindow = [self window],
        couldResize = _styleMask & CPResizableWindowMask && ![theWindow isFullPlatformWindow];

    couldResize = couldResize && (
        (CPWindowResizeStyle === CPWindowResizeStyleModern) ||
        ((CPWindowResizeStyle === CPWindowResizeStyleLegacy) && _resizeIndicator));

    if (couldResize)
    {
        var theWindow = [self window],
            windowFrame = [theWindow frame],
            shouldResize = NO;

        if (CPWindowResizeStyle === CPWindowResizeStyleModern)
        {
            var globalPoint = [theWindow convertBaseToGlobal:[anEvent locationInWindow]];

            _resizeRegion = [self resizeRegionForPoint:globalPoint];
            shouldResize = _resizeRegion !== _CPWindowViewResizeRegionNone;
        }
        else
        {
            // Extend the resize frame to the edge of the window frame
            var resizeFrame = [_resizeIndicator frame];
            resizeFrame.size.width = CGRectGetWidth(windowFrame) - CGRectGetMinX(resizeFrame);
            resizeFrame.size.height = CGRectGetHeight(windowFrame) - CGRectGetMinY(resizeFrame);

            var localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
            shouldResize = CGRectContainsPoint(resizeFrame, localPoint);

            // When in legacy mode, the only possible resize region is lower right
            _resizeRegion = shouldResize ? _CPWindowViewResizeRegionBottomRight : _CPWindowViewResizeRegionNone;
        }

        if (shouldResize)
            return [self trackResizeWithEvent:anEvent];
    }

    if ([self couldBeMoveEvent:anEvent])
        [self trackMoveWithEvent:anEvent];
    else
        [super mouseDown:anEvent];
}

- (BOOL)couldBeMoveEvent:(CPEvent)anEvent
{
    var theWindow = [self window];

    return [theWindow isMovable] && [theWindow isMovableByWindowBackground];
}

/*
    aPoint should be in global coordinates
*/
- (int)resizeRegionForPoint:(CGPoint)aPoint
{
    /*
        If the window is fixed width (minSize.width === maxSize.width), there
        are 2 possible resize rects: top and bottom.

        If the window is fixed height (minSize.height === maxSize.height), there
        are 2 possible resize rects: left and right.

        Otherwise there are 8 possible resize rects, 1 for each side and 1 for each corner.
        The four corner rects are the same size, and the top/bottom and left/right
        rects are the same size. So to save calculations, we can just create
        3 rects and move them around to do hit testing. Start with the corners
        and then do left/right and top/bottom.

        NOTE: If the window is a sheet, the top is never eligible for resizing.
    */
    var wind = [self window],
        frame = [wind frame],
        rect,
        minSize = [wind minSize],
        maxSize = [wind maxSize],
        isFixedWidth = minSize.width === maxSize.width,
        isFixedHeight = minSize.height === maxSize.height,
        isSheet = wind._isSheet;

    if (isFixedWidth)
    {
        rect = CGRectMake(frame.origin.x - _CPWindowViewResizeSlop,
                           frame.origin.y - _CPWindowViewResizeSlop,
                           frame.size.width + (_CPWindowViewResizeSlop * 2),
                           _CPWindowViewResizeSlop * 2);

        if (CGRectContainsPoint(rect, aPoint))
            return isSheet ? _CPWindowViewResizeRegionNone : _CPWindowViewResizeRegionTop;

        rect.origin.y = CGRectGetMaxY(frame) - _CPWindowViewResizeSlop;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottom;
    }
    else if (isFixedHeight)
    {
        rect = CGRectMake(frame.origin.x - _CPWindowViewResizeSlop,
                           frame.origin.y - _CPWindowViewResizeSlop,
                           _CPWindowViewResizeSlop * 2,
                           frame.size.height + (_CPWindowViewResizeSlop * 2));

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionLeft;

        rect.origin.x = CGRectGetMaxX(frame) - _CPWindowViewResizeSlop;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionRight;
    }
    else
    {
        rect = CGRectMake(frame.origin.x - _CPWindowViewResizeSlop,
                           frame.origin.y - _CPWindowViewResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + _CPWindowViewResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + _CPWindowViewResizeSlop);

        if (CGRectContainsPoint(rect, aPoint))
            return isSheet ? _CPWindowViewResizeRegionNone : _CPWindowViewResizeRegionTopLeft;

        rect.origin.x = CGRectGetMaxX(frame) - _CPWindowViewCornerResizeRectWidth;

        if (CGRectContainsPoint(rect, aPoint))
            return isSheet ? _CPWindowViewResizeRegionNone : _CPWindowViewResizeRegionTopRight;

        rect.origin.y = CGRectGetMaxY(frame) - _CPWindowViewCornerResizeRectWidth;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottomRight;

        rect.origin.x = frame.origin.x - _CPWindowViewResizeSlop;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottomLeft;

        rect = CGRectMake(rect.origin.x,
                           frame.origin.y + _CPWindowViewCornerResizeRectWidth,
                           _CPWindowViewResizeSlop * 2,
                           CGRectGetHeight(frame) - (_CPWindowViewCornerResizeRectWidth * 2));

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionLeft;

        rect.origin.x = CGRectGetMaxX(frame) - _CPWindowViewResizeSlop;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionRight;

        rect = CGRectMake(frame.origin.x + _CPWindowViewCornerResizeRectWidth,
                           frame.origin.y - _CPWindowViewResizeSlop,
                           CGRectGetWidth(frame) - (_CPWindowViewCornerResizeRectWidth * 2),
                           _CPWindowViewResizeSlop * 2);

        if (CGRectContainsPoint(rect, aPoint))
            return isSheet ? _CPWindowViewResizeRegionNone : _CPWindowViewResizeRegionTop;

        rect.origin.y = CGRectGetMaxY(frame) - _CPWindowViewResizeSlop;

        if (CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottom;
    }

    return _CPWindowViewResizeRegionNone;
}

/*
    aPoint is in window coordinates
*/
- (void)setCursorForLocation:(CGPoint)aPoint resizing:(BOOL)isResizing
{
    var theWindow = [self window];

    if ([theWindow isFullPlatformWindow] ||
        !(_styleMask & CPResizableWindowMask) ||
        (CPWindowResizeStyle !== CPWindowResizeStyleModern))
        return;

    var globalPoint = [theWindow convertBaseToGlobal:aPoint],
        resizeRegion = isResizing ? _resizeRegion : [self resizeRegionForPoint:globalPoint],
        minSize = nil,
        maxSize = nil,
        frameSize;

    if (resizeRegion !== _CPWindowViewResizeRegionNone)
    {
        minSize = [theWindow minSize];
        maxSize = [theWindow maxSize];
        frameSize = [theWindow frame].size;
    }

    switch (resizeRegion)
    {
        case _CPWindowViewResizeRegionTopLeft:
            if (minSize && CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeNorthwestCursor] set];
            else if (maxSize && CGSizeEqualToSize(frameSize, maxSize))
                [[CPCursor resizeSoutheastCursor] set];
            else
                [[CPCursor resizeNorthwestSoutheastCursor] set];
            break;

        case _CPWindowViewResizeRegionTop:
            if (minSize && (frameSize.height === minSize.height))
                [[CPCursor resizeUpCursor] set];
            else if (maxSize && (frameSize.height === maxSize.height))
                [[CPCursor resizeDownCursor] set];
            else if ([CPMenu menuBarVisible] && (CGRectGetMinY([theWindow frame]) <= [CPMenu menuBarHeight]))
                [[CPCursor resizeDownCursor] set];
            else
                [[CPCursor resizeNorthSouthCursor] set];
            break;

        case _CPWindowViewResizeRegionTopRight:
            if (minSize && CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeNortheastCursor] set];
            else if (maxSize && CGSizeEqualToSize(frameSize, maxSize))
                [[CPCursor resizeSouthwestCursor] set];
            else
                [[CPCursor resizeNortheastSouthwestCursor] set];
            break;

        case _CPWindowViewResizeRegionRight:
            if (minSize && (frameSize.width === minSize.width))
                [[CPCursor resizeRightCursor] set];
            else if (maxSize && (frameSize.width === maxSize.width))
                [[CPCursor resizeLeftCursor] set];
            else
                [[CPCursor resizeEastWestCursor] set];
            break;

        case _CPWindowViewResizeRegionBottomRight:
            if (minSize && CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeSoutheastCursor] set];
            else if (maxSize && CGSizeEqualToSize(frameSize, maxSize))
                [[CPCursor resizeNorthwestCursor] set];
            else
                [[CPCursor resizeNorthwestSoutheastCursor] set];
            break;

        case _CPWindowViewResizeRegionBottom:
            if (minSize && (frameSize.height === minSize.height))
                [[CPCursor resizeDownCursor] set];
            else if (maxSize && (frameSize.height === maxSize.height))
                [[CPCursor resizeUpCursor] set];
            else
                [[CPCursor resizeNorthSouthCursor] set];
            break;

        case _CPWindowViewResizeRegionBottomLeft:
            if (minSize && CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeSouthwestCursor] set];
            else if (maxSize && CGSizeEqualToSize(frameSize, maxSize))
                [[CPCursor resizeNortheastCursor] set];
            else
                [[CPCursor resizeNortheastSouthwestCursor] set];
            break;

        case _CPWindowViewResizeRegionLeft:
            if (minSize && (frameSize.width === minSize.width))
                [[CPCursor resizeLeftCursor] set];
            else if (maxSize && (frameSize.width === maxSize.width))
                [[CPCursor resizeRightCursor] set];
            else
                [[CPCursor resizeEastWestCursor] set];
            break;

        default:
            [[CPCursor arrowCursor] set];
    }
}

- (void)trackResizeWithEvent:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPLeftMouseUp)
    {
        _cachedScreenFrame = nil;
        return;
    }

    var location = [anEvent locationInWindow],
        theWindow = [self window],
        globalLocation = [theWindow convertBaseToGlobal:location],
        frame = [theWindow frame];

    if (type === CPLeftMouseDown)
    {
        _mouseDraggedPoint = CGPointMake(globalLocation.x, globalLocation.y);
        _cachedFrame = CGRectMakeCopy(frame);
        _cachedScreenFrame = [[CPPlatformWindow primaryPlatformWindow] visibleFrame];
    }
    else if (type === CPLeftMouseDragged)
    {
        var deltaX = globalLocation.x - _mouseDraggedPoint.x,
            deltaY = globalLocation.y - _mouseDraggedPoint.y,
            startX = CGRectGetMinX(_cachedFrame),
            startY = CGRectGetMinY(_cachedFrame),
            startWidth = CGRectGetWidth(_cachedFrame),
            startHeight = CGRectGetHeight(_cachedFrame),
            newX,
            newY,
            newWidth,
            newHeight,
            resizeMinSize = [self _minimumResizeSize],
            minSize = [theWindow minSize],
            maxSize = [theWindow maxSize];

        minSize = CGSizeMake(MAX(minSize.width, resizeMinSize.width), MAX(minSize.height, resizeMinSize.height));

        // If it's a sheet, horizontal resizing is symmetrical, so the movement is effectively doubled
        if (theWindow._isSheet)
            deltaX *= 2;

        // Calculate x and width first
        switch (_resizeRegion)
        {
            case _CPWindowViewResizeRegionTopLeft:
            case _CPWindowViewResizeRegionLeft:
            case _CPWindowViewResizeRegionBottomLeft:
                // If it is shrinking from the left edge, the maximum distance it can move
                // is the distance between the original width and the min width.
                if (deltaX > 0)
                    deltaX = MIN(startWidth - minSize.width, deltaX);

                // If it is growing from the left edge, the maximum distance it can move
                // is the distance between the original width and the max width.
                else if (deltaX < 0)
                    deltaX = -MIN(maxSize.width - startWidth, ABS(deltaX));

                if (theWindow._isSheet)
                    deltaX = FLOOR(deltaX / 2);

                newX = startX + deltaX;

                // Pin the left edge to the usable screen left edge
                var pinnedX = MAX(newX, CGRectGetMinX(_cachedScreenFrame));

                if (pinnedX !== newX)
                {
                    deltaX += pinnedX - newX;
                    newX = pinnedX;
                }

                // When resizing from the left, we change the origin and the width
                if (theWindow._isSheet)
                    deltaX *= 2;

                newWidth = startWidth - deltaX;
                break;

            case _CPWindowViewResizeRegionTopRight:
            case _CPWindowViewResizeRegionRight:
            case _CPWindowViewResizeRegionBottomRight:
                // If it is growing from the right edge, the maximum distance it can move
                // is the distance between the original width and the max width.
                if (deltaX > 0)
                    deltaX = MIN(maxSize.width - startWidth, deltaX);

                // If it is shrinking from the right edge, the maximum distance it can move
                // is the distance between the original width and the min width.
                else if (deltaX < 0)
                    deltaX = -MIN(startWidth - minSize.width, ABS(deltaX));

                if (theWindow._isSheet)
                    deltaX = FLOOR(deltaX / 2);

                // Pin the right edge to the usable screen right edge
                var newMaxX = startX + startWidth + deltaX,
                    pinnedX = MIN(newMaxX, CGRectGetMaxX(_cachedScreenFrame));

                if (pinnedX !== newMaxX)
                    deltaX += pinnedX - newMaxX;

                if (theWindow._isSheet)
                {
                    newWidth = startWidth + (deltaX * 2);
                    newX = startX - FLOOR((newWidth - startWidth) / 2);
                }
                else
                {
                    newWidth = startWidth + deltaX;
                    newX = startX;
                }
                break;

            default:
                newX = startX;
                newWidth = startWidth;
        }

        // Now calculate y and height
        switch (_resizeRegion)
        {
            case _CPWindowViewResizeRegionTopLeft:
            case _CPWindowViewResizeRegionTop:
            case _CPWindowViewResizeRegionTopRight:
                // If it is shrinking from the top edge, the maximum distance it can move
                // is the distance between the original height and the min height.
                if (deltaY > 0)
                    deltaY = MIN(startHeight - minSize.height, deltaY);

                // If it is growing from the top edge, the maximum distance it can move
                // is the distance between the original height and the max height.
                else if (deltaY < 0)
                    deltaY = -MIN(maxSize.height - startHeight, ABS(deltaY));

                newY = startY + deltaY;

                // Pin the top edge to the usable screen top edge
                var pinnedY = MAX(newY, CGRectGetMinY(_cachedScreenFrame));

                if (pinnedY !== newY)
                {
                    deltaY += pinnedY - newY;
                    newY = pinnedY;
                }

                // When resizing from the top, change the origin and the height
                newHeight = startHeight - deltaY;
                break;

            case _CPWindowViewResizeRegionBottomLeft:
            case _CPWindowViewResizeRegionBottom:
            case _CPWindowViewResizeRegionBottomRight:
                // If it is growing from the bottom edge, the maximum distance it can move
                // is the distance between the original height and the max height.
                if (deltaY > 0)
                    deltaY = MIN(maxSize.height - startHeight, deltaY);

                // If it is shrinking from the bottom edge, the maximum distance it can move
                // is the distance between the original height and the min height.
                else if (deltaY < 0)
                    deltaY = -MIN(startHeight - minSize.height, ABS(deltaY));

                newY = startY;

                // Pin the bottom edge to the usable screen bottom edge
                var newMaxY = startY + startHeight + deltaY,
                    pinnedY = MIN(newMaxY, CGRectGetMaxY(_cachedScreenFrame));

                if (pinnedY !== newMaxY)
                    deltaY += pinnedY - newMaxY;

                // When resizing from the bottom, change only the height
                newHeight = startHeight + deltaY;
                break;

            default:
                newY = startY;
                newHeight = startHeight;
        }

        [theWindow _setFrame:CGRectMake(newX, newY, newWidth, newHeight) display:YES animate:NO constrainWidth:NO constrainHeight:NO];
        [self setCursorForLocation:location resizing:YES];
    }

    [CPApp setTarget:self selector:@selector(trackResizeWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)trackMoveWithEvent:(CPEvent)anEvent
{
    var theWindow = [self window];

    if (![theWindow isMovable])
        return;

    var type = [anEvent type];

    if (type === CPLeftMouseUp)
    {
        return;
    }
    else if (type === CPLeftMouseDown)
    {
        _mouseDraggedPoint = [theWindow convertBaseToGlobal:[anEvent locationInWindow]];
        _cachedFrame = CGRectMakeCopy([theWindow frame]);
    }
    else if (type === CPLeftMouseDragged)
    {
        var theWindow = [self window],
            location = [theWindow convertBaseToGlobal:[anEvent locationInWindow]],
            deltaX = location.x - _mouseDraggedPoint.x,
            deltaY = location.y - _mouseDraggedPoint.y,
            origin = CGPointMake(_cachedFrame.origin.x + deltaX, _cachedFrame.origin.y + deltaY);

        [theWindow setFrameOrigin:origin];
    }

    [CPApp setTarget:self selector:@selector(trackMoveWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)setFrameSize:(CGSize)newSize
{
    [super setFrameSize:newSize];

    // reposition sheet if the parent window resizes or moves
    var theWindow = [self window],
        sheet = [theWindow attachedSheet];

    if (sheet)
    {
        [theWindow _setAttachedSheetFrameOrigin];
        [sheet._windowView _adjustShadowViewSize];
    }
    else if (theWindow && theWindow._isSheet)
        [self _adjustShadowViewSize];
}

- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{
    if (shouldShowResizeIndicator && CPWindowResizeStyle === CPWindowResizeStyleLegacy)
    {
        _resizeIndicator = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        [_resizeIndicator setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

        [self addSubview:_resizeIndicator];
    }
    else
    {
        [_resizeIndicator removeFromSuperview];

        _resizeIndicator = nil;
    }

    [self setNeedsLayout];
}

- (BOOL)showsResizeIndicator
{
    return _resizeIndicator !== nil;
}

- (void)setResizeIndicatorOffset:(CGSize)anOffset
{
    if (CGSizeEqualToSize(_resizeIndicatorOffset, anOffset))
        return;

    _resizeIndicatorOffset = anOffset;

    if (!_resizeIndicator)
        return;

    var size = [_resizeIndicator frame].size,
        boundsSize = [self frame].size;

    [_resizeIndicator setFrameOrigin:CGPointMake(boundsSize.width - size.width - anOffset.width, boundsSize.height - size.height - anOffset.height)];
}

- (CGSize)resizeIndicatorOffset
{
    return _resizeIndicatorOffset;
}

- (void)windowDidChangeDocumentEdited
{
}

- (void)windowDidChangeDocumentSaving
{
}

- (BOOL)showsToolbar
{
    var styleMaskWindow = [[self window] styleMask];

    return styleMaskWindow & CPBorderlessWindowMask || styleMaskWindow & CPTitledWindowMask || styleMaskWindow & CPHUDBackgroundWindowMask || styleMaskWindow & CPBorderlessBridgeWindowMask;
}

- (CGSize)toolbarOffset
{
    return _toolbarOffset;
}

- (CPColor)toolbarLabelColor
{
    return [CPColor blackColor];
}

- (float)toolbarMaxY
{
    if (!_toolbarView || [_toolbarView isHidden])
        return [self toolbarOffset].height;

    return CGRectGetMaxY([_toolbarView frame]);
}

- (_CPToolbarView)toolbarView
{
    return _toolbarView;
}

- (void)tile
{
    var theWindow = [self window],
        bounds = [self bounds],
        width = CGRectGetWidth(bounds);

    if ([[theWindow toolbar] isVisible])
    {
        var toolbarView = [self toolbarView],
            toolbarOffset = [self toolbarOffset];

        [toolbarView setFrame:CGRectMake(toolbarOffset.width, toolbarOffset.height, width, CGRectGetHeight([toolbarView frame]))];
    }

    if ([self showsResizeIndicator])
    {
        var size = [_resizeIndicator frame].size,
            boundsSize = [self bounds].size;

        [_resizeIndicator setFrameOrigin:CGPointMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height)];
    }
}

- (void)noteToolbarChanged
{
    var theWindow = [self window],
        toolbar = [theWindow toolbar],
        toolbarView = [toolbar _toolbarView];

    if (_toolbarView !== toolbarView)
    {
        [_toolbarView removeFromSuperview];

        if (toolbarView)
        {
            [toolbarView removeFromSuperview];
            [toolbarView FIXME_setIsHUD:_styleMask & CPHUDBackgroundWindowMask];

            [self addSubview:toolbarView];
        }

        _toolbarView = toolbarView;
    }

    [toolbarView setHidden:![self showsToolbar] || ![toolbar isVisible]];

    if (theWindow)
    {
        var contentRect = [self convertRect:[[theWindow contentView] frame] toView:nil];

        contentRect.origin = [theWindow convertBaseToGlobal:contentRect.origin];

        [self setAutoresizesSubviews:NO];
        [theWindow setFrame:[theWindow frameRectForContentRect:contentRect]];
        [self setAutoresizesSubviews:YES];
    }

    [self tile];
}

- (void)noteKeyWindowStateChanged
{
    if ([[self window] isKeyWindow])
        [self setThemeState:CPThemeStateKeyWindow];
    else
        [self unsetThemeState:CPThemeStateKeyWindow];
}

- (void)noteMainWindowStateChanged
{
    if ([[self window] isMainWindow])
        [self setThemeState:CPThemeStateMainWindow];
    else
        [self unsetThemeState:CPThemeStateMainWindow];
}

/*
- (void)setAnimatingToolbar:(BOOL)isAnimatingToolbar
{
    _isAnimatingToolbar = isAnimatingToolbar;
}

- (BOOL)isAnimatingToolbar
{
    return _isAnimatingToolbar;
}
*/

- (void)didAddSubview:(CPView)aView
{
    if (!_resizeIndicator || aView === _resizeIndicator)
        return;

    [self addSubview:_resizeIndicator];
}

- (void)_enableSheet:(BOOL)enable inWindow:(CPWindow)parentWindow
{
    if (enable)
    {
        // Clip the shadow view width to the parent's content view
        var myWidth = [self bounds].size.width,
            shadowWidth = [self _shadowViewWidthForParentWindow:parentWindow],
            shadowHeight = [self currentValueForThemeAttribute:@"shadow-height"];

        _sheetShadowView = [[CPView alloc] initWithFrame:CGRectMake(FLOOR((myWidth - shadowWidth) / 2), 0, shadowWidth, shadowHeight)];
        [_sheetShadowView setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:_sheetShadowView];
    }
    else
    {
        [_sheetShadowView removeFromSuperview];
        _sheetShadowView = nil;
    }

    [self setNeedsLayout];
}

- (CGRect)_shadowViewWidthForParentWindow:(CPWindow)parentWindow
{
    var myWidth = [self bounds].size.width,
        parentWidth = [[parentWindow contentView] bounds].size.width;

    return MIN(myWidth, parentWidth);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [_sheetShadowView setBackgroundColor:[self valueForThemeAttribute:@"attached-sheet-shadow-color"]];

    if (_resizeIndicator)
    {
        var size = [self valueForThemeAttribute:@"size-indicator"],
            boundsSize = [self frame].size;

        [_resizeIndicator setFrame:CGRectMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height, size.width, size.height)];
        [_resizeIndicator setImage:[self valueForThemeAttribute:@"resize-indicator"]];
    }
}

- (void)_adjustShadowViewSize
{
    if (!_sheetShadowView)
        return;

    var myWidth = [self frame].size.width,
        shadowFrame = [_sheetShadowView frame],
        shadowWidth = [self _shadowViewWidthForParentWindow:_window._parentView];

    shadowFrame.origin.x = FLOOR((myWidth - shadowWidth) / 2);
    shadowFrame.size.width = shadowWidth;
    [_sheetShadowView setFrame:shadowFrame];
}

- (CGSize)_minimumResizeSize
{
    return CGSizeMake(0, _CPWindowViewMinContentHeight);
}

- (int)bodyOffset
{
    return [self frame].origin.y;
}

@end
