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


var _CPWindowViewResizeIndicatorImage = nil;

@implementation _CPWindowView : CPView
{
    unsigned    _styleMask;

    CPImageView _resizeIndicator;
    CGSize      _resizeIndicatorOffset;

    CPView      _toolbarView;
    CGSize      _toolbarOffset;
//    BOOL        _isAnimatingToolbar;

    CGRect      _resizeFrame;
    CGPoint     _mouseDraggedPoint;

    CGRect      _cachedScreenFrame;

    CPView      _sheetShadowView;
}

+ (void)initialize
{
    if (self !== [_CPWindowView class])
        return;

    _CPWindowViewResizeIndicatorImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPWindow class]] pathForResource:@"_CPWindowView/_CPWindowViewResizeIndicator.png"] size:CGSizeMake(12.0, 12.0)];
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
    return [CPDictionary dictionaryWithObjects:[[CPColor blackColor], [CPFont systemFontOfSize:CPFontCurrentSystemSize], [CPNull null], _CGSizeMakeZero(), CPCenterTextAlignment, CPLineBreakByTruncatingTail, CPTopVerticalTextAlignment]
                                       forKeys:[@"title-text-color", @"title-font", @"title-text-shadow-color", @"title-text-shadow-offset", @"title-alignment", @"title-line-break-mode", @"title-vertical-alignment"]];
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

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
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

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var theWindow = [self window];

    if ((_styleMask & CPResizableWindowMask) && _resizeIndicator)
    {
        // FIXME: This should be better
        var frame = [_resizeIndicator frame];

        if (CGRectContainsPoint(frame, [self convertPoint:[anEvent locationInWindow] fromView:nil]))
            return [self trackResizeWithEvent:anEvent];
    }

    if ([theWindow isMovable] && [theWindow isMovableByWindowBackground])
        [self trackMoveWithEvent:anEvent];
    else
        [super mouseDown:anEvent];
}

- (void)trackResizeWithEvent:(CPEvent)anEvent
{
    var location = [anEvent locationInWindow],
        type = [anEvent type];

    if (type === CPLeftMouseUp)
        return;

    var theWindow = [self window];

    if (type === CPLeftMouseDown)
    {
        var frame = [theWindow frame];

        _resizeFrame = CGRectMake(location.x, location.y, CGRectGetWidth(frame), CGRectGetHeight(frame));
    }

    else if (type === CPLeftMouseDragged)
    {
        var newSize = CGSizeMake(CGRectGetWidth(_resizeFrame) + location.x - CGRectGetMinX(_resizeFrame), CGRectGetHeight(_resizeFrame) + location.y - CGRectGetMinY(_resizeFrame));

        if (theWindow._isSheet && theWindow._parentView && (theWindow._frame.size.width !== newSize.width))
            [theWindow._parentView _setAttachedSheetFrameOrigin];

        [theWindow setFrameSize:newSize];
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

    restrictedPoint.x = MIN(MAX(aPoint.x, -_frame.size.width + 4.0), CGRectGetMaxX(visibleFrame) - 4.0);
    restrictedPoint.y = MIN(MAX(aPoint.y, minPointY), CGRectGetMaxY(visibleFrame) - 8.0);

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
    if (shouldShowResizeIndicator)
    {
        var size = [_CPWindowViewResizeIndicatorImage size],
            boundsSize = [self frame].size;

        _resizeIndicator = [[CPImageView alloc] initWithFrame:CGRectMake(boundsSize.width - size.width - _resizeIndicatorOffset.width, boundsSize.height - size.height - _resizeIndicatorOffset.height, size.width, size.height)];

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
