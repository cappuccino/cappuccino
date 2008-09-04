/*
 * CPView.j
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

import <Foundation/CPArray.j>
import <Foundation/CPObjJRuntime.j>

import "CGAffineTransform.j"
import "CGGeometry.j"

import "CPColor.j"
import "CPDOMDisplayServer.j"
import "CPGeometry.j"
import "CPResponder.j"
import "CPGraphicsContext.j"

#include "Platform/Platform.h"
#include "CoreGraphics/CGAffineTransform.h"
#include "CoreGraphics/CGGeometry.h"
#include "Platform/DOM/CPDOMDisplayServer.h"


CPViewNotSizable    = 0;
CPViewMinXMargin    = 1;
CPViewWidthSizable  = 2;
CPViewMaxXMargin    = 4;
CPViewMinYMargin    = 8;
CPViewHeightSizable = 16;
CPViewMaxYMargin    = 32;

CPViewBoundsDidChangeNotification   = @"CPViewBoundsDidChangeNotification";
CPViewFrameDidChangeNotification    = @"CPViewFrameDidChangeNotification";

var _DOMOriginUpdateMask        = 1 << 0,
    _DOMSizeUpdateMask          = 1 << 1;

var _CPViewNotificationCenter   = nil;

#if PLATFORM(DOM)
var DOMCanvasElementZIndex      = -1,
    DOMBackgroundElementZIndex  = -2,
    DOMElementPrototype         = nil,
    
    BackgroundTrivialColor              = 0,
    BackgroundVerticalThreePartImage    = 1,
    BackgroundHorizontalThreePartImage  = 2,
    BackgroundNinePartImage             = 3;
#endif

@implementation CPView : CPResponder
{
    CPWindow            _window;
    
    CPView              _superview;
    CPArray             _subviews;
    
    CPGraphicsContext   _graphicsContext;
    
    CGRect              _frame;
    CGRect              _bounds;
    CGAffineTransform   _boundsTransform;
    CGAffineTransform   _inverseBoundsTransform;
    
    CPArray             _registeredDraggedTypes;
    
    BOOL                _isHidden;
    BOOL                _hitTests;
    
    BOOL                _postsFrameChangedNotifications;
    BOOL                _postsBoundsChangedNotifications;
    BOOL                _inhibitFrameAndBoundsChangedNotifications;
    
    CPString            _displayHash;
    
#if PLATFORM(DOM)
    DOMElement          _DOMElement;
    CPArray             _DOMImageParts;
    CPArray             _DOMImageSizes;
    
    unsigned            _backgroundType;
    
    DOMElement          _DOMGraphicsElement;
#endif

    float               _opacity;
    CPColor             _backgroundColor;

    BOOL                _autoresizesSubviews;
    unsigned            _autoresizingMask;
    
    CALayer             _layer;
    BOOL                _wantsLayer;
    
    // Full Screen State
    BOOL                _isInFullScreenMode;
    
    _CPViewFullScreenModeState  _fullScreenModeState;
}

+ (void)initialize
{
    if (self != [CPView class])
        return;

#if PLATFORM(DOM)
    DOMElementPrototype =  document.createElement("div");
    
    var style = DOMElementPrototype.style;
    
    style.overflow = "hidden";
    style.position = "absolute";
    style.visibility = "visible";
    style.zIndex = 0;
#endif

    _CPViewNotificationCenter = [CPNotificationCenter defaultCenter];
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super init];
    
    if (self)
    {
        var width = _CGRectGetWidth(aFrame),
            height = _CGRectGetHeight(aFrame);
        
        _subviews = [];

        _frame = _CGRectMakeCopy(aFrame);
        _bounds = _CGRectMake(0.0, 0.0, width, height);

        _registeredDraggedTypes = [];

        _autoresizingMask = CPViewNotSizable;
        _autoresizesSubviews = YES;
    
        _opacity = 1.0;
        _isHidden = NO;
        _hitTests = YES;

        _displayHash = [self hash];

#if PLATFORM(DOM)
        _DOMElement = DOMElementPrototype.cloneNode(false);
        
        CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, _CGRectGetMinX(aFrame), _CGRectGetMinY(aFrame));
        CPDOMDisplayServerSetStyleSize(_DOMElement, width, height);
        
        _DOMImageParts = [];
        _DOMImageSizes = [];
#endif
    }
    
    return self;
}

- (CPView)superview
{
    return _superview;
}

- (CPArray)subviews
{
    return _subviews;
}

- (CPWindow)window
{
    return _window;
}

- (void)addSubview:(CPView)aSubview
{
    [self _insertSubview:aSubview atIndex:CPNotFound];
}

- (void)addSubview:(CPView)aSubview positioned:(CPWindowOrderingMode)anOrderingMode relativeTo:(CPView)anotherView
{
    var index = anotherView ? [_subviews indexOfObjectIdenticalTo:anotherView] : CPNotFound;
    
    // In other words, if no view, then either all the way at the bottom or all the way at the top.
    if (index == CPNotFound)
        index = (anOrderingMode == CPWindowAbove) ? [_subviews count] : 0;
    
    // else, if we have a view, above if above.
    else if (anOrderingMode == CPWindowAbove)
        ++index;
        
    [self _insertSubview:aSubview atIndex:index];
}

- (void)_insertSubview:(CPView)aSubview atIndex:(int)anIndex
{
    // We will have to adjust the z-index of all views starting at this index.
    var count = _subviews.length;
    
    // If this is already one of our subviews, remove it.
    if (aSubview._superview == self)
    {
        var index = [_subviews indexOfObjectIdenticalTo:aSubview];
        
        if (index == anIndex || index == count - 1 && anIndex == count)
            return;
        
        [_subviews removeObjectAtIndex:index];
        
#if PLATFORM(DOM)
        CPDOMDisplayServerRemoveChild(_DOMElement, aSubview._DOMElement);
#endif

        if (anIndex > index)
            --anIndex;
    }
    else
    {
        // Remove the view from its previous superview.
        [aSubview removeFromSuperview];

        // Set the subview's window to our own. 
        [aSubview _setWindow:_window];

        // Notify the subview that it will be moving.
        [aSubview viewWillMoveToSuperview:self];
    
        // Set ourselves as the superview.
        aSubview._superview = self;
    }
    
    if (anIndex == CPNotFound || anIndex >= count)
    {
        _subviews.push(aSubview);

#if PLATFORM(DOM)
        // Attach the actual node.
        CPDOMDisplayServerAppendChild(_DOMElement, aSubview._DOMElement);
#endif
    }
    else
    {
        _subviews.splice(anIndex, 0, aSubview);
    
#if PLATFORM(DOM)
        // Attach the actual node.
        CPDOMDisplayServerInsertBefore(_DOMElement, aSubview._DOMElement, _subviews[anIndex + 1]._DOMElement);
#endif
    }
    
    [aSubview setNextResponder:self];
    [aSubview viewDidMoveToSuperview];
    
    [self didAddSubview:aSubview];
}

- (void)didAddSubview:(CPView)aSubview
{
}

- (void)removeFromSuperview
{
    if (!_superview)
        return;

    [_superview willRemoveSubview:self];
    
    [[_superview subviews] removeObject:self];

#if PLATFORM(DOM)
        CPDOMDisplayServerRemoveChild(_superview._DOMElement, _DOMElement);
#endif
    _superview = nil;
    
    [self _setWindow:nil];
}

- (void)replaceSubview:(CPView)aSubview with:(CPView)aView
{
    if (aSubview._superview != self)
        return;
    
    var index = [_subviews indexOfObjectIdenticalTo:aSubview];
    
    [aSubview removeFromSuperview];
    
    [aView _insertSubview:aView atIndex:index];
}

- (void)_setWindow:(CPWindow)aWindow
{
    // FIXME: check _window == aWindow?  If not, comment why!
    if ([_window firstResponder] == self)
        [_window makeFirstResponder:nil];

    // Notify the view and its subviews
    [self viewWillMoveToWindow:aWindow];
    [_subviews makeObjectsPerformSelector:@selector(_setWindow:) withObject:aWindow];

    _window = aWindow;
    
    [self viewDidMoveToWindow];
}

- (BOOL)isDescendantOf:(CPView)aView
{
    var view = self;
    
    do
    {
        if (view == aView)
            return YES;
    } while(view = [view superview])
    
    return NO;
}

- (void)viewDidMoveToSuperview
{
    if (_graphicsContext)
        [self setNeedsDisplay:YES];
}

- (void)viewDidMoveToWindow
{
}

- (void)viewWillMoveToSuperview:(CPView)aView
{
}

- (void)viewWillMoveToWindow:(CPWindow)aWindow
{
}

- (void)willRemoveSubview:(CPView)aView
{
}

- (CPMenuItem)enclosingMenuItem
{
    var view = self;
    
    while (![view isKindOfClass:[_CPMenuItemView class]])
        view = [view superview];
    
    if (view)
        return view._menuItem;
    
    return nil;
/*    var view = self,
        enclosingMenuItem = _enclosingMenuItem;
    
    while (!enclosingMenuItem && (view = view._enclosingMenuItem))
        view = [view superview];
    
    return enclosingMenuItem;*/
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setFrame:(CPRect)aFrame
{
    if (_CGRectEqualToRect(_frame, aFrame))
        return;
        
    _inhibitFrameAndBoundsChangedNotifications = YES;
    
    [self setFrameOrigin:aFrame.origin];
    [self setFrameSize:aFrame.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsFrameChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewFrameDidChangeNotification object:self];
}

- (CGRect)frame
{
    return _CGRectMakeCopy(_frame);
}

- (void)setFrameOrigin:(CPPoint)aPoint
{
    var origin = _frame.origin;
    
    if (!aPoint || _CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewFrameDidChangeNotification object:self];

#if PLATFORM(DOM)
    CPDOMDisplayServerSetStyleLeftTop(_DOMElement, _superview ? _superview._boundsTransform : NULL, origin.x, origin.y);
#endif
}

- (void)setFrameSize:(CGSize)aSize
{
    var size = _frame.size;
    
    if (!aSize || _CGSizeEqualToSize(size, aSize))
        return;

    var oldSize = _CGSizeMakeCopy(size);

    size.width = aSize.width;
    size.height = aSize.height;

    if (YES)
    {
        _bounds.size.width = aSize.width;
        _bounds.size.height = aSize.height;
    }
    
    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewFrameDidChangeNotification object:self];

    if (_layer)
        [_layer _owningViewBoundsChanged];

    if (_autoresizesSubviews)
        [self resizeSubviewsWithOldSize:oldSize];

#if PLATFORM(DOM)
    CPDOMDisplayServerSetStyleSize(_DOMElement, size.width, size.height);
    
    if (_backgroundType == BackgroundTrivialColor)
        return;
        
    var images = [[_backgroundColor patternImage] imageSlices];

    if (_backgroundType == BackgroundVerticalThreePartImage)
    {
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], size.width, size.height - _DOMImageSizes[0].height - _DOMImageSizes[2].height);
    }
    
    else if (_backgroundType == BackgroundHorizontalThreePartImage)
    {
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], size.width - _DOMImageSizes[0].width - _DOMImageSizes[2].width, size.height);
    }
    
    else if (_backgroundType == BackgroundNinePartImage)
    {
        var width = size.width - _DOMImageSizes[0].width - _DOMImageSizes[2].width,
            height = size.height - _DOMImageSizes[0].height - _DOMImageSizes[6].height;
        
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], width, _DOMImageSizes[0].height);
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[3], _DOMImageSizes[3].width, height);
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[4], width, height);
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[5], _DOMImageSizes[5].width, height);
        CPDOMDisplayServerSetStyleSize(_DOMImageParts[7], width, _DOMImageSizes[7].height);
    }
#endif
}

- (void)setBounds:(CGRect)bounds
{
    if (_CGRectEqualToRect(_bounds, bounds))
        return;
        
    _inhibitFrameAndBoundsChangedNotifications = YES;
    
    [self setBoundsOrigin:bounds.origin];
    [self setBoundsSize:bounds.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewBoundsDidChangeNotification object:self];
}

- (CGRect)bounds
{
    return _CGRectMakeCopy(_bounds);
}

- (void)setBoundsOrigin:(CGPoint)aPoint
{
    var origin = _bounds.origin;
    
    if (_CGPointEqualToPoint(origin, aPoint))
        return;
        
    origin.x = aPoint.x;
    origin.y = aPoint.y;
    
    if (origin.x != 0 || origin.y != 0)
    {
        _boundsTransform = _CGAffineTransformMakeTranslation(-origin.x, -origin.y);
        _inverseBoundsTransform = CGAffineTransformInvert(_boundsTransform);
    }
    else
    {
        _boundsTransform = nil;
        _inverseBoundsTransform = nil;
    }
    
#if PLATFORM(DOM)
    var index = _subviews.length;
    
    while (index--)
    {
        var view = _subviews[index],
            origin = view._frame.origin;
        
        CPDOMDisplayServerSetStyleLeftTop(view._DOMElement, _boundsTransform, origin.x, origin.y);
    }
#endif
    
    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewBoundsDidChangeNotification object:self];
}

- (void)setBoundsSize:(CGSize)aSize
{
    var size = _bounds.size;
    
    if (_CGSizeEqualToSize(size, aSize))
        return;

    var frameSize = _frame.size;

    if (!_CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;
        
        origin.x /= size.width / frameSize.width;
        origin.y /= size.height / frameSize.height;
    }
    
    size.width = aSize.width;
    size.height = aSize.height;
    
    if (!_CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;
        
        origin.x *= size.width / frameSize.width;
        origin.y *= size.height / frameSize.height;
    }
    
    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewBoundsDidChangeNotification object:self];
}

- (void)resizeWithOldSuperviewSize:(CPSize)aSize
{
    var mask = _autoresizingMask;
    
    if(mask == CPViewNotSizable)
        return;

    var frame = _superview._frame,
        newFrame = _CGRectMakeCopy(_frame),
        dX = (_CGRectGetWidth(frame) - aSize.width) /
            (((mask & CPViewMinXMargin) ? 1 : 0) + (mask & CPViewWidthSizable ? 1 : 0) + (mask & CPViewMaxXMargin ? 1 : 0)),
        dY = (_CGRectGetHeight(frame) - aSize.height) /
            ((mask & CPViewMinYMargin ? 1 : 0) + (mask & CPViewHeightSizable ? 1 : 0) + (mask & CPViewMaxYMargin ? 1 : 0));

    if (mask & CPViewMinXMargin)
        newFrame.origin.x += dX;
    if (mask & CPViewWidthSizable)
        newFrame.size.width += dX;
    
    if (mask & CPViewMinYMargin)
        newFrame.origin.y += dY;
    if (mask & CPViewHeightSizable)
        newFrame.size.height += dY;

    [self setFrame:newFrame];
}

- (void)resizeSubviewsWithOldSize:(CPSize)aSize
{
    var count = _subviews.length;
    
    while (count--)
        [_subviews[count] resizeWithOldSuperviewSize:aSize];
}

- (void)setAutoresizesSubviews:(BOOL)aFlag
{
    _autoresizesSubviews = aFlag;
}

- (BOOL)autoresizesSubviews
{
    return _autoresizesSubviews;
}

- (void)setAutoresizingMask:(unsigned)aMask
{
    _autoresizingMask = aMask;
}

- (unsigned)autoresizingMask
{
    return _autoresizingMask;
}

// Fullscreen Mode

- (BOOL)enterFullScreenMode:(CPScreen)aScreen withOptions:(CPDictionary)options
{
    _fullScreenModeState = _CPViewFullScreenModeStateMake(self);
    
    var fullScreenWindow = [[CPWindow alloc] initWithContentRect:[[CPDOMWindowBridge sharedDOMWindowBridge] contentBounds] styleMask:CPBorderlessWindowMask];
    
    [fullScreenWindow setLevel:CPScreenSaverWindowLevel];
    [fullScreenWindow setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    var contentView = [fullScreenWindow contentView];
    
    [contentView setBackgroundColor:[CPColor blackColor]];
    [contentView addSubview:self];

    [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self setFrame:CGRectMakeCopy([contentView bounds])];

    [fullScreenWindow makeKeyAndOrderFront:self];
    
    [fullScreenWindow makeFirstResponder:self];
    
    _isInFullScreenMode = YES;
    
    return YES;
}

- (void)exitFullScreenModeWithOptions:(CPDictionary)options
{
    if (!_isInFullScreenMode)
        return;
    
    _isInFullScreenMode = NO;
    
    [self setFrame:_fullScreenModeState.frame];
    [self setAutoresizingMask:_fullScreenModeState.autoresizingMask];
    [_fullScreenModeState.superview _insertSubview:self atIndex:_fullScreenModeState.index];
    
    [[self window] orderOut:self];
}

- (BOOL)isInFullScreenMode
{
    return _isInFullScreenMode;
}

- (void)setHidden:(BOOL)aFlag
{
    if(_isHidden == aFlag) 
        return;
//  FIXME: Should we return to visibility?  This breaks in FireFox, Opera, and IE.
//    _DOMElement.style.visibility = (_isHidden = aFlag) ? "hidden" : "visible";
    _isHidden = aFlag;
#if PLATFORM(DOM)
    _DOMElement.style.display = _isHidden ? "none" : "block";
#endif
}

- (BOOL)isHidden
{
    return _isHidden;
}

- (void)setAlphaValue:(float)anAlphaValue
{
    if (_opacity == anAlphaValue)
        return;
    
    _opacity = anAlphaValue;
    
#if PLATFORM(DOM)
    _DOMElement.style.opacity = anAlphaValue;
    
    if (anAlphaValue == 1.0)
        try { _DOMElement.style.removeAttribute("filter") } catch (anException) { }
    else
        _DOMElement.style.filter = "alpha(opacity=" + anAlphaValue * 100 + ")";
#endif
}

- (float)alphaValue
{
    return _opacity;
}

- (void)setOpacity:(float)anOpacity
{
    [self setAlphaValue:anOpacity];
}

- (float)opacity
{
    return _opacity;
}
    
- (BOOL)isHiddenOrHasHiddenAncestor
{
    var view = self;
    
    while (![view isHidden])
        view = [view superview];
    
    return view != nil;
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (BOOL)hitTests
{
    return YES;
}

- (void)setHitTests:(BOOL)shouldHitTest
{
    _hitTests = shouldHitTest;
}

- (CPView)hitTest:(CPPoint)aPoint
{
    if(_isHidden || !_hitTests || !CPRectContainsPoint(_frame, aPoint))
        return nil;
    
    var view = nil,
        i = _subviews.length,
        adjustedPoint = _CGPointMake(aPoint.x - _CGRectGetMinX(_frame), aPoint.y - _CGRectGetMinY(_frame));

    if (_inverseBoundsTransform)
        adjustedPoint = _CGPointApplyAffineTransform(adjustedPoint, _inverseBoundsTransform);

    while (i--)
        if (view = [_subviews[i] hitTest:adjustedPoint])
            return view;

    return self;
}

- (BOOL)mouseDownCanMoveWindow
{
    return ![self isOpaque];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self mouseDownCanMoveWindow])
        [super mouseDown:anEvent];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    if (_backgroundColor == aColor)
        return;
    
    _backgroundColor = aColor;
    
#if PLATFORM(DOM)
    var patternImage = [_backgroundColor patternImage],
        amount = 0;
    
    if ([patternImage isThreePartImage])
    {
        _backgroundType = [patternImage isVertical] ? BackgroundVerticalThreePartImage : BackgroundHorizontalThreePartImage;
        
        amount = 3 - _DOMImageParts.length;
    }
    else if ([patternImage isNinePartImage])
    {
        _backgroundType = BackgroundNinePartImage;
        
        amount = 9 - _DOMImageParts.length;   
    }
    else
    {
        _backgroundType = BackgroundTrivialColor;

        amount = 0 - _DOMImageParts.length;
    }
    
    if (amount > 0)
        while (amount--)
        {
            var DOMElement = DOMElementPrototype.cloneNode(false);
            
            DOMElement.style.zIndex = -1000;
            
            _DOMImageParts.push(DOMElement);
            _DOMElement.appendChild(DOMElement);
        }
    else
    {
        amount = -amount;
        
        while (amount--)
            _DOMElement.removeChild(_DOMImageParts.pop());
    }
    
    if (_backgroundType == BackgroundTrivialColor)
    
        // Opera doesn't like DOM properties set to nil.
        // https://trac.280north.com/ticket/7
        _DOMElement.style.background = _backgroundColor ? [_backgroundColor cssString] : "";
    
    else
    {
        var slices = [patternImage imageSlices],
            count = slices.length,
            frameSize = _frame.size;
        
        while (count--)
        {
            var image = slices[count],
                size = _DOMImageSizes[count] = image ? [image size] : _CGSizeMakeZero();
            
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[count], size.width, size.height);
            
            _DOMImageParts[count].style.background = image ? "url(\"" + [image filename] + "\")" : "";
        }
        
        if (_backgroundType == BackgroundNinePartImage)
        {
            var width = frameSize.width - _DOMImageSizes[0].width - _DOMImageSizes[2].width,
                height = frameSize.height - _DOMImageSizes[0].height - _DOMImageSizes[6].height;
            
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], width, _DOMImageSizes[0].height);
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[3], _DOMImageSizes[3].width, height);
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[4], width, height);
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[5], _DOMImageSizes[5].width, height);
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[7], width, _DOMImageSizes[7].height);
                
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[0], NULL, 0.0, 0.0);            
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[1], NULL, _DOMImageSizes[0].width, 0.0);
            CPDOMDisplayServerSetStyleRightTop(_DOMImageParts[2], NULL, 0.0, 0.0);
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[3], NULL, 0.0, _DOMImageSizes[1].height);
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[4], NULL, _DOMImageSizes[0].width, _DOMImageSizes[0].height);
            CPDOMDisplayServerSetStyleRightTop(_DOMImageParts[5], NULL, 0.0, _DOMImageSizes[1].height);
            CPDOMDisplayServerSetStyleLeftBottom(_DOMImageParts[6], NULL, 0.0, 0.0);
            CPDOMDisplayServerSetStyleLeftBottom(_DOMImageParts[7], NULL, _DOMImageSizes[6].width, 0.0);
            CPDOMDisplayServerSetStyleRightBottom(_DOMImageParts[8], NULL, 0.0, 0.0);      
        }
        else if (_backgroundType == BackgroundVerticalThreePartImage)
        {    
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], frameSize.width, frameSize.height - _DOMImageSizes[0].height - _DOMImageSizes[2].height);
            
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[0], NULL, 0.0, 0.0);
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[1], NULL, 0.0, _DOMImageSizes[0].height);        
            CPDOMDisplayServerSetStyleLeftBottom(_DOMImageParts[2], NULL, 0.0, 0.0);
        }
        else if (_backgroundType == BackgroundHorizontalThreePartImage)
        {
            CPDOMDisplayServerSetStyleSize(_DOMImageParts[1], frameSize.width - _DOMImageSizes[0].width - _DOMImageSizes[2].width, frameSize.height);
        
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[0], NULL, 0.0, 0.0);
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageParts[1], NULL, _DOMImageSizes[0].width, 0.0);        
            CPDOMDisplayServerSetStyleRightTop(_DOMImageParts[2], NULL, 0.0, 0.0);
        }
    }
#endif
}

- (CPColor)backgroundColor
{
    return _backgroundColor;
}

// Converting Coordinates

- (CGPoint)convertPoint:(CGPoint)aPoint fromView:(CPView)aView
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(aView, self));
}

- (CGPoint)convertPoint:(CGPoint)aPoint toView:(CPView)aView
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(self, aView));
}

- (CGSize)convertSize:(CGSize)aSize fromView:(CPView)aView
{
    return CGSizeApplyAffineTransform(aSize, _CPViewGetTransform(aView, self));
}

- (CGSize)convertSize:(CGSize)aSize toView:(CPView)aView
{
    return CGSizeApplyAffineTransform(aSize, _CPViewGetTransform(self, aView));
}

- (CGRect)convertRect:(CGRect)aRect fromView:(CPView)aView
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(aView, self));
}
 
- (CGRect)convertRect:(CGRect)aRect toView:(CPView)aView
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(self, aView));
}

- (void)setPostsFrameChangedNotifications:(BOOL)shouldPostFrameChangedNotifications
{
    if (_postsFrameChangedNotifications == shouldPostFrameChangedNotifications)
        return;
    
    _postsFrameChangedNotifications = shouldPostFrameChangedNotifications;
    
    if (_postsFrameChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewFrameDidChangeNotification object:self];
}

- (BOOL)postsFrameChangedNotifications
{
    return _postsFrameChangedNotifications;
}

- (void)setPostsBoundsChangedNotifications:(BOOL)shouldPostBoundsChangedNotifications
{
    if (_postsBoundsChangedNotifications == shouldPostBoundsChangedNotifications)
        return;
    
    _postsBoundsChangedNotifications = shouldPostBoundsChangedNotifications;
    
    if (_postsBoundsChangedNotifications)
        [_CPViewNotificationCenter postNotificationName:CPViewBoundsDidChangeNotification object:self];
}

- (BOOL)postsBoundsChangedNotifications
{
    return _postsBoundsChangedNotifications;
}

- (void)dragImage:(CPImage)anImage at:(CPPoint)aLocation offset:(CPSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [_window dragImage:anImage at:[self convertPoint:aLocation toView:nil] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

- (void)dragView:(CPView)aView at:(CPPoint)aLocation offset:(CPSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [_window dragView:aView at:[self convertPoint:aLocation toView:nil] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

- (void)registerForDraggedTypes:(CPArray)pasteboardTypes
{
    _registeredDraggedTypes = [pasteboardTypes copy];
}

- (CPArray)registeredDraggedTypes
{
    return _registeredDraggedTypes;
}

- (void)unregisterDraggedTypes
{
    _registeredDraggedTypes = nil;
}

//

- (void)drawRect:(CPRect)aRect
{

}

// Focus

- (void)lockFocus
{
    // If we don't yet have a graphics context, then we must first create a 
    // canvas element, then use its 2d context.
    if (!_graphicsContext)
    {
        var context = CGBitmapGraphicsContextCreate();
        
#if PLATFORM(DOM)
        _DOMGraphicsElement = context.DOMElement;
        
        _DOMGraphicsElement.style.position = "absolute";
        _DOMGraphicsElement.style.top = "0px";
        _DOMGraphicsElement.style.left = "0px";
        _DOMGraphicsElement.style.zIndex = DOMCanvasElementZIndex;
        
        _DOMGraphicsElement.width = CPRectGetWidth(_frame);
        _DOMGraphicsElement.height = CPRectGetHeight(_frame);

        _DOMGraphicsElement.style.width = CPRectGetWidth(_frame) + "px";
        _DOMGraphicsElement.style.height = CPRectGetHeight(_frame) + "px";

        _DOMElement.appendChild(_DOMGraphicsElement);
#endif
        _graphicsContext = [CPGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    }
    
    [CPGraphicsContext setCurrentContext:_graphicsContext];
    
    CGContextSaveGState([_graphicsContext graphicsPort]);
}

- (void)unlockFocus
{
    var graphicsPort = [_graphicsContext graphicsPort];
    
    CGContextRestoreGState(graphicsPort);
    
    [CPGraphicsContext setCurrentContext:nil];
}

// Displaying

- (void)setNeedsDisplay:(BOOL)aFlag
{
    if (aFlag)
        [self display];
}

- (void)setNeedsDisplayInRect:(CPRect)aRect
{
    [self displayRect:aRect];
}

- (void)displayIfNeeded
{
}

- (void)display
{
    [self displayRect:_bounds];
}

- (void)displayRect:(CPRect)aRect
{   
    [self lockFocus];
    [self drawRect:aRect];
    [self unlockFocus];
}

- (BOOL)isOpaque
{
    return NO;
}

- (CGRect)visibleRect
{
    if (!_superview)
        return _bounds;
    
    return CGRectIntersection([self convertRect:[_superview visibleRect] fromView:_superview], _bounds);
}

// Scrolling

- (CPScrollView)_enclosingClipView
{
    var superview = _superview,
        clipViewClass = [CPClipView class];

    while(superview && ![superview isKindOfClass:clipViewClass]) 
        superview = superview._superview;

    return superview;
}

- (void)scrollPoint:(CGPoint)aPoint
{
    var clipView = [self _enclosingClipView];
    
    if (!clipView)
        return;
    
    [clipView scrollToPoint:[self convertPoint:aPoint toView:clipView]];
}

- (BOOL)scrollRectToVisible:(CGRect)aRect
{
    var visibleRect = [self visibleRect];
    
    // Make sure we have a rect that exists.
    aRect = CGRectIntersection(aRect, _bounds);
    
    // If aRect is empty or is already visible then no scrolling required.
    if (_CGRectIsEmpty(aRect) || CGRectContainsRect(visibleRect, aRect))
        return NO;

    var enclosingClipView = [self _enclosingClipView];
    
    // If we're not in a clip view, then there isn't much we can do.
    if (!enclosingClipView)
        return NO;
    
    var scrollPoint = _CGPointMakeCopy(visibleRect.origin);
            
    // One of the following has to be true since our current visible rect didn't contain aRect.
    if (_CGRectGetMinX(aRect) <= _CGRectGetMinX(visibleRect))
        scrollPoint.x = _CGRectGetMinX(aRect);
    else if (_CGRectGetMaxX(aRect) > _CGRectGetMaxX(visibleRect))
        scrollPoint.x += _CGRectGetMaxX(aRect) - _CGRectGetMaxX(visibleRect);
    
    if (_CGRectGetMinY(aRect) <= _CGRectGetMinY(visibleRect))
        scrollPoint.y = CGRectGetMinY(aRect);
    else if (_CGRectGetMaxY(aRect) > _CGRectGetMaxY(visibleRect))
        scrollPoint.y += _CGRectGetMaxY(aRect) - _CGRectGetMaxY(visibleRect);
    
    [enclosingClipView scrollToPoint:CGPointMake(scrollPoint.x, scrollPoint.y)];
    
    return YES;
}

- (BOOL)autoscroll:(CPEvent)anEvent
{
    // FIXME: Implement.
    return NO;
}

- (CGRect)adjustScroll:(CGRect)proposedVisibleRect
{
    return proposedVisibleRect;
}

- (void)scrollRect:(CGRect)aRect by:(float)anAmount
{

}

- (CPScrollView)enclosingScrollView
{
    var superview = _superview,
        scrollViewClass = [CPScrollView class];

    while(superview && ![superview isKindOfClass:scrollViewClass]) 
        superview = superview._superview;

    return superview;
}

- (void)scrollClipView:(CPClipView)aClipView toPoint:(CGPoint)aPoint
{
    [aClipView scrollToPoint:aPoint];
}

- (void)reflectScrolledClipView:(CPClipView)aClipView
{
}

@end

@implementation CPView (CoreAnimationAdditions)

- (void)setLayer:(CALayer)aLayer
{
    if (_layer == aLayer)
        return;
    
    if (_layer)
    {
        _layer._owningView = nil;
#if PLATFORM(DOM)
        _DOMElement.removeChild(_layer._DOMElement);
#endif
    }
    
    _layer = aLayer;
    
    if (_layer)
    {
        var bounds = CGRectMakeCopy([self bounds]);
        
        [_layer _setOwningView:self];
        
#if PLATFORM(DOM)
        _layer._DOMElement.style.zIndex = 100;
        
        _DOMElement.appendChild(_layer._DOMElement);
#endif
    }
}

- (CALayer)layer
{
    return _layer;
}

- (void)setWantsLayer:(BOOL)aFlag
{
    _wantsLayer = aFlag;
}

- (CALayer)wantsLayer
{
    return _wantsLayer;
}

@end

var CPViewAutoresizingMaskKey       = @"CPViewAutoresizingMask",
    CPViewAutoresizesSubviewsKey    = @"CPViewAutoresizesSubviews",
    CPViewBackgroundColorKey        = @"CPViewBackgroundColor",
    CPViewBoundsKey                 = @"CPViewBoundsKey",
    CPViewFrameKey                  = @"CPViewFrameKey",
    CPViewHitTestsKey               = @"CPViewHitTestsKey",
    CPViewIsHiddenKey               = @"CPViewIsHiddenKey",
    CPViewOpacityKey                = @"CPViewOpacityKey",
    CPViewSubviewsKey               = @"CPViewSubviewsKey",
    CPViewSuperviewKey              = @"CPViewSuperviewKey",
    CPViewWindowKey                 = @"CPViewWindowKey";

@implementation CPView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    // We create the DOMElement "early" because there is a change that we 
    // will decode our superview before we are done decoding, at which point 
    // we have to have an element to place in the tree.  Perhaps there is 
    // a more "elegant" way to do this...?
#if PLATFORM(DOM)
    _DOMElement = DOMElementPrototype.cloneNode(false);
#endif

    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _frame = [aCoder decodeRectForKey:CPViewFrameKey];
        _bounds = [aCoder decodeRectForKey:CPViewBoundsKey];

        _window = [aCoder decodeObjectForKey:CPViewWindowKey];
        _subviews = [aCoder decodeObjectForKey:CPViewSubviewsKey];
        _superview = [aCoder decodeObjectForKey:CPViewSuperviewKey];
        
        _autoresizingMask = [aCoder decodeIntForKey:CPViewAutoresizingMaskKey];
        _autoresizesSubviews = [aCoder decodeBoolForKey:CPViewAutoresizesSubviewsKey];
        
        _hitTests = [aCoder decodeObjectForKey:CPViewHitTestsKey];
        _isHidden = [aCoder decodeObjectForKey:CPViewIsHiddenKey];
        _opacity = [aCoder decodeIntForKey:CPViewOpacityKey];
    
        // DOM SETUP
#if PLATFORM(DOM)
        _DOMImageParts = [];
        _DOMImageSizes = [];

        CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, _CGRectGetMinX(_frame), _CGRectGetMinY(_frame));
        CPDOMDisplayServerSetStyleSize(_DOMElement, _CGRectGetWidth(_frame), _CGRectGetHeight(_frame));
        
        var index = 0,
            count = _subviews.length;
    
        for (; index < count; ++index)
        {
            CPDOMDisplayServerAppendChild(_DOMElement, _subviews[index]._DOMElement);
        }
#endif
        _displayHash = [self hash];

        [self setBackgroundColor:[aCoder decodeObjectForKey:CPViewBackgroundColorKey]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeRect:_frame forKey:CPViewFrameKey];
    [aCoder encodeRect:_bounds forKey:CPViewBoundsKey];
    
    [aCoder encodeConditionalObject:_window forKey:CPViewWindowKey];
    [aCoder encodeObject:_subviews forKey:CPViewSubviewsKey];
    [aCoder encodeConditionalObject:_superview forKey:CPViewSuperviewKey];
        
    [aCoder encodeInt:_autoresizingMask forKey:CPViewAutoresizingMaskKey];
    [aCoder encodeBool:_autoresizesSubviews forKey:CPViewAutoresizesSubviewsKey];
        
    [aCoder encodeObject:_backgroundColor forKey:CPViewBackgroundColorKey];
        
    [aCoder encodeBool:_hitTests forKey:CPViewHitTestsKey];
    [aCoder encodeBool:_isHidden forKey:CPViewIsHiddenKey];
    [aCoder encodeFloat:_opacity forKey:CPViewOpacityKey];
}

@end

var _CPViewFullScreenModeStateMake = function(aView)
{
    var superview = aView._superview;
    
    return { autoresizingMask:aView._autoresizingMask, frame:CGRectMakeCopy(aView._frame), index:(superview ? [superview._subviews indexOfObjectIdenticalTo:aView] : 0), superview:superview };
}

var _CPViewGetTransform = function(/*CPView*/ fromView, /*CPView */ toView)
{
    var transform = CGAffineTransformMakeIdentity();
    
    if (fromView)
    {
        var view = fromView;
        
        // If we have a fromView, "climb up" the view tree until 
        // we hit the root node or we hit the toLayer.
        while (view && view != toView)
        {
            var frame = view._frame;
            
            transform.tx += _CGRectGetMinX(frame);
            transform.ty += _CGRectGetMinY(frame);
            
            if (view._boundsTransform)
            {
                _CGAffineTransformConcatTo(transform, view._boundsTransform, transform);
            }
            
            view = view._superview;
        }
        
        // If we hit toView, then we're done.
        if (view == toView)
            return transform;
    }
    
    // FIXME: For now we can do things this way, but eventually we need to do them the "hard" way.
    var view = toView;
    
    while (view)
    {
        var frame = view._frame;
            
        transform.tx -= _CGRectGetMinX(frame);
        transform.ty -= _CGRectGetMinY(frame);
        
        if (view._boundsTransform)
        {
            _CGAffineTransformConcatTo(transform, view._inverseBoundsTransform, transform);
        }
        
        view = view._superview;
    }
    
/*    var views = [],
        view = toView;
    
    while (view)
    {
        views.push(view);
        view = view._superview;
    }
    
    var index = views.length;
    
    while (index--)
    {
        var frame = views[index]._frame;
            
        transform.tx -= _CGRectGetMinX(frame);
        transform.ty -= _CGRectGetMinY(frame);
    }*/
    
    return transform;
}
