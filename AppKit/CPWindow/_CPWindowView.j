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


var _CPWindowViewResizeIndicatorImage = nil,
    _CPWindowViewCornerResizeRectWidth = 10,

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

+ (void)initialize
{
    if (self !== [_CPWindowView class])
        return;

    _CPWindowViewResizeIndicatorImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPWindow class]] pathForResource:@"_CPWindowView/_CPWindowViewResizeIndicator.png"] size:_CGSizeMake(12.0, 12.0)];
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
    return [CPDictionary dictionaryWithObjects:[[CPColor blackColor], [CPFont systemFontOfSize:CPFontCurrentSystemSize], [CPNull null], _CGSizeMakeZero(), CPCenterTextAlignment, CPLineBreakByTruncatingTail, CPTopVerticalTextAlignment]
                                       forKeys:[@"title-text-color", @"title-font", @"title-text-shadow-color", @"title-text-shadow-offset", @"title-alignment", @"title-line-break-mode", @"title-vertical-alignment"]];
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

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
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

            _resizeRegion = [self resizeRegionForPoint:globalPoint inFrame:windowFrame];
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
- (int)resizeRegionForPoint:(CGPoint)aPoint inFrame:(CGRect)aFrame
{
    /*
        There are 8 possible resize rects, 1 for each side and 1 for each corner.
        The four corner rects are the same size, and the top/bottom and left/right
        rects are the same size. So to save calculations, we can just create
        3 rects and move them around to do hit testing. Start with the corners
        and then do left/right and top/bottom.
    */
    var rect = _CGRectMake(aFrame.origin.x - CPWindowResizeSlop,
                           aFrame.origin.y - CPWindowResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + CPWindowResizeSlop,
                           _CPWindowViewCornerResizeRectWidth + CPWindowResizeSlop);

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionTopLeft;

    rect.origin.x = _CGRectGetMaxX(aFrame) - _CPWindowViewCornerResizeRectWidth;

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionTopRight;

    rect.origin.y = _CGRectGetMaxY(aFrame) - _CPWindowViewCornerResizeRectWidth;

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionBottomRight;

    rect.origin.x = aFrame.origin.x - CPWindowResizeSlop;

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionBottomLeft;

    rect = _CGRectMake(rect.origin.x,
                       aFrame.origin.y + _CPWindowViewCornerResizeRectWidth,
                       CPWindowResizeSlop * 2,
                       _CGRectGetHeight(aFrame) - (_CPWindowViewCornerResizeRectWidth * 2));

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionLeft;

    rect.origin.x = _CGRectGetMaxX(aFrame) - CPWindowResizeSlop;

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionRight;

    rect = _CGRectMake(aFrame.origin.x + _CPWindowViewCornerResizeRectWidth,
                       aFrame.origin.y - CPWindowResizeSlop,
                       _CGRectGetWidth(aFrame) - (_CPWindowViewCornerResizeRectWidth * 2),
                       CPWindowResizeSlop * 2);

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionTop;

    rect.origin.y = _CGRectGetMaxY(aFrame) - CPWindowResizeSlop;

    if (_CGRectContainsPoint(rect, aPoint))
        return _CPWindowViewResizeRegionBottom;

    return _CPWindowViewResizeRegionNone;
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
            newHeight = _CGRectGetHeight(_resizeFrame);

        // Calculate x and width first
        switch (_resizeRegion)
        {
            case _CPWindowViewResizeRegionTopLeft:
            case _CPWindowViewResizeRegionLeft:
            case _CPWindowViewResizeRegionBottomLeft:
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

        [theWindow setFrame:_CGRectMake(newX, newY, newWidth, newHeight)];
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

    var restrictedPoint = CGPointMake(0, 0);

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
            origin = [self _pointWithinScreenFrame:CGPointMake(_CGRectGetMinX(frame) + (location.x - _mouseDraggedPoint.x),
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
        var size = [_CPWindowViewResizeIndicatorImage size],
            boundsSize = [self frame].size;

        _resizeIndicator = [[CPImageView alloc] initWithFrame:_CGRectMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height, size.width, size.height)];

        [_resizeIndicator setImage:_CPWindowViewResizeIndicatorImage];
        [_resizeIndicator setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];

        [self addSubview:_resizeIndicator];
    }
    else
    {
        [_resizeIndicator removeFromSuperview];

        _resizeIndicator = nil;
    }
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

- (void)_enableSheet:(BOOL)enable
{
    if (enable)
    {
        var bundle = [CPBundle bundleForClass:[CPWindow class]];
        _sheetShadowView = [[CPView alloc] initWithFrame:_CGRectMake(0, 0, _CGRectGetWidth([self bounds]), 8)];
        [_sheetShadowView setAutoresizingMask:CPViewWidthSizable];
        [_sheetShadowView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc]
            initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowAttachedSheetShadow.png"] size:_CGSizeMake(9, 8)]]];
        [self addSubview:_sheetShadowView];
    }
    else
    {
        [_sheetShadowView removeFromSuperview];
    }
}

@end
