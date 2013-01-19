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

@class CPCursor
@class CPMenu
@class CPPlatformWindow

@global CPApp
@global CPHUDBackgroundWindowMask
@global CPResizableWindowMask
@global CPWindowResizeSlop
@global CPWindowResizeStyle
@global CPWindowResizeStyleLegacy
@global CPWindowResizeStyleModern


var _CPWindowViewCornerResizeRectWidth = 10,
    _CPWindowViewResizeRegionNone = -1,
    _CPWindowViewResizeRegionTopLeft = 0,
    _CPWindowViewResizeRegionTop = 1,
    _CPWindowViewResizeRegionTopRight = 2,
    _CPWindowViewResizeRegionRight = 3,
    _CPWindowViewResizeRegionBottomRight = 4,
    _CPWindowViewResizeRegionBottom = 5,
    _CPWindowViewResizeRegionBottomLeft = 6,
    _CPWindowViewResizeRegionLeft = 7;

@implementation _CPWindowView : CPView
{
    unsigned    _styleMask;

    CPImageView _resizeIndicator;
    CGSize      _resizeIndicatorOffset;

    CPView      _toolbarView;
    CGSize      _toolbarOffset;
//    BOOL        _isAnimatingToolbar;

    CGRect      _resizeFrame;
    int         _resizeRegion;
    CGPoint     _mouseDraggedPoint;

    CGRect      _cachedScreenFrame;

    CPView      _sheetShadowView;
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    return _CGRectMakeCopy(aFrameRect);
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    return _CGRectMakeCopy(aContentRect);
}

+ (CPString)defaultThemeClass
{
    return "window";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[25, CGInsetMakeZero(), 5, [CPColor clearColor], CGSizeMakeZero(), [CPNull null], [CPColor blackColor], [CPNull null],[CPNull null], [CPNull null], [CPNull null], [CPNull null] , [CPColor blackColor], [CPFont systemFontOfSize:CPFontCurrentSystemSize], [CPNull null], _CGSizeMakeZero(), CPCenterTextAlignment, CPLineBreakByTruncatingTail, CPTopVerticalTextAlignment]
                                       forKeys:[    @"title-bar-height",
                                                    @"shadow-inset",
                                                    @"shadow-distance",
                                                    @"window-shadow-color",
                                                    @"size-indicator",
                                                    @"resize-indicator",
                                                    @"attached-sheet-shadow-color",
                                                    @"close-image-origin",
                                                    @"close-image-size",
                                                    @"close-image",
                                                    @"close-active-image",
                                                    @"bezel-color",
                                                    @"title-text-color",
                                                    @"title-font",
                                                    @"title-text-shadow-color",
                                                    @"title-text-shadow-offset",
                                                    @"title-alignment",
                                                    @"title-line-break-mode",
                                                    @"title-vertical-alignment"]];
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [[self class] contentRectForFrameRect:aFrameRect],
        theToolbar = [[self window] toolbar];

    if ([theToolbar isVisible])
    {
        var toolbarHeight = _CGRectGetHeight([[theToolbar _toolbarView] frame]);

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
        var toolbarHeight = _CGRectGetHeight([[theToolbar _toolbarView] frame]);

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
        _resizeIndicatorOffset = _CGSizeMakeZero();
        _toolbarOffset = _CGSizeMakeZero();
    }

    return self;
}

- (void)setDocumentEdited:(BOOL)isEdited
{
}

- (void)setTitle:(CPString)aTitle
{
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var theWindow = [self window],
        couldResize = _styleMask & CPResizableWindowMask;

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
            resizeFrame.size.width = _CGRectGetWidth(windowFrame) - _CGRectGetMinX(resizeFrame);
            resizeFrame.size.height = _CGRectGetHeight(windowFrame) - _CGRectGetMinY(resizeFrame);

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
    */
    var wind = [self window],
        frame = [wind frame],
        rect,
        minSize = [wind minSize],
        maxSize = [wind maxSize],
        isFixedWidth = minSize.width === maxSize.width,
        isFixedHeight = minSize.height === maxSize.height;

    if (isFixedWidth)
    {
        rect = _CGRectMake(frame.origin.x - CPWindowResizeSlop,
                           frame.origin.y - CPWindowResizeSlop,
                           frame.size.width + (CPWindowResizeSlop * 2),
                           CPWindowResizeSlop * 2);

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionTop;

        rect.origin.y = _CGRectGetMaxY(frame) - CPWindowResizeSlop;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottom;
    }
    else if (isFixedHeight)
    {
        rect = _CGRectMake(frame.origin.x - CPWindowResizeSlop,
                           frame.origin.y - CPWindowResizeSlop,
                           CPWindowResizeSlop * 2,
                           frame.size.height + (CPWindowResizeSlop * 2));

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionLeft;

        rect.origin.x = _CGRectGetMaxX(frame) - CPWindowResizeSlop;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionRight;
    }
    else
    {
        rect = _CGRectMake(frame.origin.x - CPWindowResizeSlop,
                           frame.origin.y - CPWindowResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + CPWindowResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + CPWindowResizeSlop);

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionTopLeft;

        rect.origin.x = _CGRectGetMaxX(frame) - _CPWindowViewCornerResizeRectWidth;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionTopRight;

        rect.origin.y = _CGRectGetMaxY(frame) - _CPWindowViewCornerResizeRectWidth;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottomRight;

        rect.origin.x = frame.origin.x - CPWindowResizeSlop;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionBottomLeft;

        rect = _CGRectMake(rect.origin.x,
                           frame.origin.y + _CPWindowViewCornerResizeRectWidth,
                           CPWindowResizeSlop * 2,
                           _CGRectGetHeight(frame) - (_CPWindowViewCornerResizeRectWidth * 2));

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionLeft;

        rect.origin.x = _CGRectGetMaxX(frame) - CPWindowResizeSlop;

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionRight;

        rect = _CGRectMake(frame.origin.x + _CPWindowViewCornerResizeRectWidth,
                           frame.origin.y - CPWindowResizeSlop,
                           _CGRectGetWidth(frame) - (_CPWindowViewCornerResizeRectWidth * 2),
                           CPWindowResizeSlop * 2);

        if (_CGRectContainsPoint(rect, aPoint))
            return _CPWindowViewResizeRegionTop;

        rect.origin.y = _CGRectGetMaxY(frame) - CPWindowResizeSlop;

        if (_CGRectContainsPoint(rect, aPoint))
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
            if (minSize && _CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeNorthwestCursor] set];
            else if (maxSize && _CGSizeEqualToSize(frameSize, maxSize))
                [[CPCursor resizeSoutheastCursor] set];
            else
                [[CPCursor resizeNorthwestSoutheastCursor] set];
            break;

        case _CPWindowViewResizeRegionTop:
            if (minSize && (frameSize.height === minSize.height))
                [[CPCursor resizeUpCursor] set];
            else if (maxSize && (frameSize.height === maxSize.height))
                [[CPCursor resizeDownCursor] set];
            else if ([CPMenu menuBarVisible] && (_CGRectGetMinY([theWindow frame]) <= [CPMenu menuBarHeight]))
                [[CPCursor resizeDownCursor] set];
            else
                [[CPCursor resizeNorthSouthCursor] set];
            break;

        case _CPWindowViewResizeRegionTopRight:
            if (minSize && _CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeNortheastCursor] set];
            else if (maxSize && _CGSizeEqualToSize(frameSize, maxSize))
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
            if (minSize && _CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeSoutheastCursor] set];
            else if (maxSize && _CGSizeEqualToSize(frameSize, maxSize))
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
            if (minSize && _CGSizeEqualToSize(frameSize, minSize))
                [[CPCursor resizeSouthwestCursor] set];
            else if (maxSize && _CGSizeEqualToSize(frameSize, maxSize))
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
        return;

    var location = [anEvent locationInWindow],
        theWindow = [self window],
        globalLocation = [theWindow convertBaseToGlobal:location],
        frame = [theWindow frame];

    if (type === CPLeftMouseDown)
    {
        _mouseDraggedPoint = _CGPointMakeCopy(globalLocation);
        _resizeFrame = _CGRectMakeCopy(frame);
    }

    else if (type === CPLeftMouseDragged)
    {
        var diffX = globalLocation.x - _mouseDraggedPoint.x,
            diffY = globalLocation.y - _mouseDraggedPoint.y,
            newX = _CGRectGetMinX(_resizeFrame),
            newY = _CGRectGetMinY(_resizeFrame),
            newWidth = _CGRectGetWidth(_resizeFrame),
            newHeight = _CGRectGetHeight(_resizeFrame),
            platformFrame = [[theWindow platformWindow] usableContentFrame],
            minSize = [theWindow minSize],
            maxSize = [theWindow maxSize];

        // Calculate x and width first
        switch (_resizeRegion)
        {
            case _CPWindowViewResizeRegionTopLeft:
            case _CPWindowViewResizeRegionLeft:
            case _CPWindowViewResizeRegionBottomLeft:
                if (minSize && diffX > 0)
                    diffX = MIN(newWidth - minSize.width, diffX);
                else if (maxSize && diffX < 0)
                    diffX = MAX(newWidth - maxSize.width, diffX);

                newX += diffX,
                newWidth -= diffX;
                break;

            case _CPWindowViewResizeRegionTopRight:
            case _CPWindowViewResizeRegionRight:
            case _CPWindowViewResizeRegionBottomRight:
                newWidth += diffX;
                break;
        }

        // Now calculate y and height
        switch (_resizeRegion)
        {
            case _CPWindowViewResizeRegionTopLeft:
            case _CPWindowViewResizeRegionTop:
            case _CPWindowViewResizeRegionTopRight:
                if (minSize && diffY > 0)
                    diffY = MIN(newHeight - minSize.height, diffY);
                else if (maxSize && diffY < 0)
                    diffY = MAX(newHeight - maxSize.height, diffY);

                newY += diffY,
                newHeight -= diffY;
                break;

            case _CPWindowViewResizeRegionBottomLeft:
            case _CPWindowViewResizeRegionBottom:
            case _CPWindowViewResizeRegionBottomRight:
                newHeight += diffY;
                break;
        }

        if (theWindow._isSheet && theWindow._parentView && (frame.size.width !== newWidth))
            [theWindow._parentView _setAttachedSheetFrameOrigin];

        // Constrain resize to fit within the platform window.
        var newFrame = CGRectIntersection(_CGRectMake(newX, newY, newWidth, newHeight), platformFrame);

        [theWindow setFrame:newFrame];
        [self setCursorForLocation:location resizing:YES];
    }

    [CPApp setTarget:self selector:@selector(trackResizeWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (CGPoint)_pointWithinScreenFrame:(CGPoint)aPoint
{
    // FIXME: this is WRONG, all of this is WRONG
    if (![CPPlatform isBrowser])
        return aPoint;

    var visibleFrame = _cachedScreenFrame;

    if (!visibleFrame)
        visibleFrame = [[CPPlatformWindow primaryPlatformWindow] visibleFrame];

    var minPointY = 0;

    if ([CPMenu menuBarVisible])
        minPointY = [[CPApp mainMenu] menuBarHeight];

    var restrictedPoint = _CGPointMake(0, 0);

    restrictedPoint.x = MIN(MAX(aPoint.x, -_frame.size.width + 4.0), _CGRectGetMaxX(visibleFrame) - 4.0);
    restrictedPoint.y = MIN(MAX(aPoint.y, minPointY), _CGRectGetMaxY(visibleFrame) - 8.0);

    return restrictedPoint;
}

- (void)trackMoveWithEvent:(CPEvent)anEvent
{
    if (![[self window] isMovable])
        return;

    var type = [anEvent type];

    if (type === CPLeftMouseUp)
    {
        _cachedScreenFrame = nil;
        return;
    }
    else if (type === CPLeftMouseDown)
    {
        _mouseDraggedPoint = [[self window] convertBaseToGlobal:[anEvent locationInWindow]];
        _cachedScreenFrame = [[CPPlatformWindow primaryPlatformWindow] visibleFrame];
    }
    else if (type === CPLeftMouseDragged)
    {
        var theWindow = [self window],
            frame = [theWindow frame],
            location = [theWindow convertBaseToGlobal:[anEvent locationInWindow]],
            origin = [self _pointWithinScreenFrame:_CGPointMake(_CGRectGetMinX(frame) + (location.x - _mouseDraggedPoint.x),
                                                                _CGRectGetMinY(frame) + (location.y - _mouseDraggedPoint.y))];
        [theWindow setFrameOrigin:origin];

        _mouseDraggedPoint = [self _pointWithinScreenFrame:location];
    }

    [CPApp setTarget:self selector:@selector(trackMoveWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)setFrameSize:(CGSize)newSize
{
    [super setFrameSize:newSize];

    // reposition sheet if the parent window resizes or moves
    var theWindow = [self window];

    if ([theWindow attachedSheet])
        [theWindow _setAttachedSheetFrameOrigin];
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
    if (_CGSizeEqualToSize(_resizeIndicatorOffset, anOffset))
        return;

    _resizeIndicatorOffset = anOffset;

    if (!_resizeIndicator)
        return;

    var size = [_resizeIndicator frame].size,
        boundsSize = [self frame].size;

    [_resizeIndicator setFrameOrigin:_CGPointMake(boundsSize.width - size.width - anOffset.width, boundsSize.height - size.height - anOffset.height)];
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
    return YES;
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

    return _CGRectGetMaxY([_toolbarView frame]);
}

- (_CPToolbarView)toolbarView
{
    return _toolbarView;
}

- (void)tile
{
    var theWindow = [self window],
        bounds = [self bounds],
        width = _CGRectGetWidth(bounds);

    if ([[theWindow toolbar] isVisible])
    {
        var toolbarView = [self toolbarView],
            toolbarOffset = [self toolbarOffset];

        [toolbarView setFrame:_CGRectMake(toolbarOffset.width, toolbarOffset.height, width, _CGRectGetHeight([toolbarView frame]))];
    }

    if ([self showsResizeIndicator])
    {
        var size = [_resizeIndicator frame].size,
            boundsSize = [self bounds].size;

        [_resizeIndicator setFrameOrigin:_CGPointMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height)];
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

- (void)_enableSheet:(BOOL)enable
{
    if (enable)
    {
        _sheetShadowView = [[CPView alloc] initWithFrame:_CGRectMake(0, 0, _CGRectGetWidth([self bounds]), 8)];
        [_sheetShadowView setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:_sheetShadowView];
    }
    else
    {
        [_sheetShadowView removeFromSuperview];
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [_sheetShadowView setBackgroundColor:[self valueForThemeAttribute:@"attached-sheet-shadow-color"]];

    if(_resizeIndicator)
    {
        var size = [self valueForThemeAttribute:@"size-indicator"],
            boundsSize = [self frame].size;

        [_resizeIndicator setFrame:CGRectMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height, size.width, size.height)];
        [_resizeIndicator setImage:[self valueForThemeAttribute:@"resize-indicator"]];
    }
}

@end
