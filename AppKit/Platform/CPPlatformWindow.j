/*
 * CPPlatformWindow.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

@import <Foundation/CPObject.j>


var PrimaryPlatformWindow   = NULL;

@implementation CPPlatformWindow : CPObject
{
    CGRect          _contentRect;

    CPInteger       _level;
    BOOL            _hasShadow;
    unsigned        _shadowStyle;

#if PLATFORM(DOM)
    DOMWindow       _DOMWindow;

    DOMElement      _DOMBodyElement;
    DOMElement      _DOMFocusElement;
    DOMElement      _DOMEventGuard;
    DOMElement      _DOMScrollingElement;
    id              _hideDOMScrollingElementTimeout;

    CPArray         _windowLevels;
    CPDictionary    _windowLayers;

    BOOL            _mouseIsDown;
    BOOL            _mouseDownIsRightClick;
    CPWindow        _mouseDownWindow;
    CPTimeInterval  _lastMouseUp;
    CPTimeInterval  _lastMouseDown;

    Object          _charCodes;
    unsigned        _keyCode;
    unsigned        _lastKey;
    BOOL            _capsLockActive;
    BOOL            _ignoreNativeCopyOrCutEvent;
    BOOL            _ignoreNativePastePreparation;

    BOOL            _DOMEventMode;

    // Native Pasteboard Support
    DOMElement      _DOMPasteboardElement;
    CPEvent         _pasteboardKeyDownEvent;

    CPString        _overriddenEventType;
#endif
}

+ (CPSet)visiblePlatformWindows
{
    return [CPSet set];
}

+ (BOOL)supportsMultipleInstances
{
#if PLATFORM(DOM)
    return !CPBrowserIsEngine(CPInternetExplorerBrowserEngine);
#else
    return NO;
#endif
}

+ (CPPlatformWindow)primaryPlatformWindow
{
    return PrimaryPlatformWindow;
}

+ (void)setPrimaryPlatformWindow:(CPPlatformWindow)aPlatformWindow
{
    PrimaryPlatformWindow = aPlatformWindow;
}

- (id)initWithContentRect:(CGRect)aRect
{
    self = [super init];

    if (self)
    {
        _contentRect = _CGRectMakeCopy(aRect);

#if PLATFORM(DOM)
        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];
        
        _charCodes = {};
#endif
    }

    return self;
}

- (id)init
{
    return [self initWithContentRect:_CGRectMake(0.0, 0.0, 400.0, 500.0)];
}

- (CGRect)contentRect
{
    return _CGRectMakeCopy(_contentRect);
}

- (CGRect)contentBounds
{
    var contentBounds = [self contentRect];

    contentBounds.origin = _CGPointMakeZero();

    return contentBounds;
}

- (CGRect)visibleFrame
{
    var frame = [self contentBounds];

    frame.origin = CGPointMakeZero();

    if ([CPMenu menuBarVisible] && [CPPlatformWindow primaryPlatformWindow] === self)
    {
        var menuBarHeight = [[CPApp mainMenu] menuBarHeight];

        frame.origin.y += menuBarHeight;
        frame.size.height -= menuBarHeight;
    }

    return frame;
}

- (CGRect)usableContentFrame
{
    return [self visibleFrame];
}

- (void)setContentRect:(CGRect)aRect
{
    if (!aRect || _CGRectEqualToRect(_contentRect, aRect))
        return;

    _contentRect = _CGRectMakeCopy(aRect);

#if PLATFORM(DOM)
     [self updateNativeContentRect];
#endif
}

- (void)updateFromNativeContentRect
{
    [self setContentRect:[self nativeContentRect]];
}

- (CGPoint)convertBaseToScreen:(CGPoint)aPoint
{
    var contentRect = [self contentRect];

    return _CGPointMake(aPoint.x + _CGRectGetMinX(contentRect), aPoint.y + _CGRectGetMinY(contentRect));
}

- (CGPoint)convertScreenToBase:(CGPoint)aPoint
{
    var contentRect = [self contentRect];

    return _CGPointMake(aPoint.x - _CGRectGetMinX(contentRect), aPoint.y - _CGRectGetMinY(contentRect));
}

- (BOOL)isVisible
{
#if PLATFORM(DOM)
    return _DOMWindow !== NULL;
#else
    return NO;
#endif
}

- (void)deminiaturize:(id)sender
{
#if PLATFORM(DOM)
    if (_DOMWindow && typeof _DOMWindow["cpDeminiaturize"] === "function")
        _DOMWindow.cpDeminiaturize();
#endif
}

- (void)miniaturize:(id)sender
{
#if PLATFORM(DOM)
    if (_DOMWindow && typeof _DOMWindow["cpMiniaturize"] === "function")
        _DOMWindow.cpMiniaturize();
#endif
}

- (void)moveWindow:(CPWindow)aWindow fromLevel:(int)fromLevel toLevel:(int)toLevel
{
#if PLATFORM(DOM)
    if (!aWindow._isVisible)
        return;

    var fromLayer = [self layerAtLevel:fromLevel create:NO],
        toLayer = [self layerAtLevel:toLevel create:YES];

    [fromLayer removeWindow:aWindow];
    [toLayer insertWindow:aWindow atIndex:CPNotFound];
#endif
}

- (void)setLevel:(CPInteger)aLevel
{
    _level = aLevel;

#if PLATFORM(DOM)
    if (_DOMWindow && _DOMWindow.cpSetLevel)
        _DOMWindow.cpSetLevel(aLevel);
#endif
}

- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    _hasShadow = shouldHaveShadow;

#if PLATFORM(DOM)
    if (_DOMWindow && _DOMWindow.cpSetHasShadow)
        _DOMWindow.cpSetHasShadow(shouldHaveShadow);
#endif
}

- (void)setShadowStyle:(int)aStyle
{
    _shadowStyle = aStyle;

#if PLATFORM(DOM)
    if (_DOMWindow && _DOMWindow.cpSetShadowStyle)
        _shadowStyle.cpSetShadowStyle(aStyle);
#endif
}

- (BOOL)supportsFullPlatformWindows
{
    return [CPPlatform isBrowser];
}

@end

#if PLATFORM(BROWSER)
@import "CPPlatformWindow+DOM.j"
#endif
