/*
 * CPWindow.j
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

import <Foundation/CPNotificationCenter.j>
import <Foundation/CPUndoManager.j>

import "CGGeometry.j"
import "CPAnimation.j"
import "CPResponder.j"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

#include "CoreGraphics/CGGeometry.h"


CPBorderlessWindowMask          = 0;
CPTitledWindowMask              = 1 << 0;
CPClosableWindowMask            = 1 << 1;
CPMiniaturizableWindowMask      = 1 << 2;
CPResizableWindowMask           = 1 << 3;
CPTexturedBackgroundWindowMask  = 1 << 8;

CPBorderlessBridgeWindowMask    = 1 << 20;
CPHUDBackgroundWindowMask       = 1 << 21;

CPWindowNotSizable              = 0;
CPWindowMinXMargin              = 1;
CPWindowWidthSizable            = 2;
CPWindowMaxXMargin              = 4;
CPWindowMinYMargin              = 8;
CPWindowHeightSizable           = 16;
CPWindowMaxYMargin              = 32;

CPNormalWindowLevel             = 4;
CPFloatingWindowLevel           = 5;
CPSubmenuWindowLevel            = 6;
CPTornOffMenuWindowLevel        = 6;
CPMainMenuWindowLevel           = 8;
CPStatusWindowLevel             = 9;
CPModalPanelWindowLevel         = 10;
CPPopUpMenuWindowLevel          = 11;
CPDraggingWindowLevel           = 12;
CPScreenSaverWindowLevel        = 13;

CPWindowOut                     = 0;
CPWindowAbove                   = 1;
CPWindowBelow                   = 2;

CPWindowWillCloseNotification       = @"CPWindowWillCloseNotification";
CPWindowDidBecomeMainNotification   = @"CPWindowDidBecomeMainNotification";
CPWindowDidResignMainNotification   = @"CPWindowDidResignMainNotification";


var SHADOW_MARGIN_LEFT      = 20.0,
    SHADOW_MARGIN_RIGHT     = 19.0,
    SHADOW_MARGIN_TOP       = 10.0,
    SHADOW_MARGIN_BOTTOM    = 10.0,
    SHADOW_DISTANCE         = 5.0,
    
    _CPWindowShadowColor    = nil;
    
var CPWindowSaveImage       = nil,
    CPWindowSavingImage     = nil;

@implementation CPWindow : CPResponder
{
    int                 _windowNumber;
    unsigned            _styleMask;
    CGRect              _frame;
    int                 _level;
    BOOL                _isVisible;
    BOOL                _isAnimating;
    BOOL                _hasShadow;
    BOOL                _isMovableByWindowBackground;
    
    BOOL                _isDocumentEdited;
    BOOL                _isDocumentSaving;
    
    CPNinePartImageView _shadowView;
    
    CPView              _windowView;
    CPView              _contentView;
    CPView              _toolbarView;
    
    CPView              _mouseOverView;
    CPView              _leftMouseDownView;
    CPView              _rightMouseDownView;
    
    CPToolbar           _toolbar;
    CPResponder         _firstResponder;
    id                  _delegate;
    
    CPString            _title;
    
    BOOL                _acceptsMouseMovedEvents;
    
    CPWindowController  _windowController;
    
    CGSize              _minSize;
    CGSize              _maxSize;
    
    CGRect              _resizeFrame;
    CGPoint             _mouseDraggedPoint;
    
    CPUndoManager       _undoManager;
    CPURL               _representedURL;
    
    // Bridge Support
    DOMElement          _DOMElement;
    CPDOMWindowBridge   _bridge;
    unsigned            _autoresizingMask;
    
    BOOL                _delegateRespondsToWindowWillReturnUndoManagerSelector;
}

+ (void)initialize
{
    if (self != [CPWindow class])
        return;
    
    var bundle = [CPBundle bundleForClass:[CPWindow class]];
    
    CPWindowResizeIndicatorImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindowResizeIndicator.png"] size:CGSizeMake(12.0, 12.0)];
    
    CPWindowSavingImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(16.0, 16.0)]
}

- (id)initWithContentRect:(CGRect)aContentRect styleMask:(unsigned int)aStyleMask
{
    return [self initWithContentRect:aContentRect styleMask:aStyleMask bridge:[CPDOMWindowBridge sharedDOMWindowBridge]];
}

- (id)initWithContentRect:(CGRect)aContentRect styleMask:(unsigned int)aStyleMask bridge:(CPDOMWindowBridge)aBridge
{
    self = [super init];
    
    if (self)
    {
        // Set up our window number.
        _windowNumber = [CPApp._windows count];
        CPApp._windows[_windowNumber] = self;
        
        _styleMask = aStyleMask;
        
        _frame = [self frameRectForContentRect:aContentRect];
        
        _level = CPNormalWindowLevel;
        _hasShadow = NO;
        
        _minSize = CGSizeMake(0.0, 0.0);
        _maxSize = CGSizeMake(1000000.0, 1000000.0);
        
        if (_styleMask & CPBorderlessBridgeWindowMask)
            _autoresizingMask = CPWindowWidthSizable | CPWindowHeightSizable;

        // Create our border view which is the actual root of our view hierarchy.
        _windowView = [[_CPWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame)) forStyleMask:_styleMask];
        
        [_windowView _setWindow:self];
        [_windowView setNextResponder:self];
        
        [self setMovableByWindowBackground:aStyleMask & CPHUDBackgroundWindowMask];
        
        // Create a generic content view.
        [self setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];

        _firstResponder = self;
        
        _DOMElement = document.createElement("div");
        
        _DOMElement.style.position = "absolute";
        _DOMElement.style.visibility = "visible";
        _DOMElement.style.zIndex = 0;
        
        CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, _CGRectGetMinX(_frame), _CGRectGetMinY(_frame));
        CPDOMDisplayServerSetStyleSize(_DOMElement, 1, 1);
        
        CPDOMDisplayServerAppendChild(_DOMElement, _windowView._DOMElement);
       
        [self setBridge:aBridge];
        
        [self setNextResponder:CPApp];
    }
    
    return self;
}

- (unsigned)styleMask
{
    return _styleMask;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect styleMask:(unsigned)aStyleMask
{
    var frame = CGRectMakeCopy(aContentRect);
    
    return frame;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrame
{
    // FIXME: EXTRA RECT COPY
    var contentRect = CGRectMakeCopy([_windowView bounds]);
    
    if (_styleMask & CPHUDBackgroundWindowMask)
    {
        contentRect.origin.x += 7.0;
        contentRect.origin.y += 30.0;
        contentRect.size.width -= 14.0;
        contentRect.size.height -= 40.0;
    }
    
    else if (_styleMask & CPBorderlessBridgeWindowMask)
    {
        // The full width, like borderless.
    }
    
    if ([_toolbar isVisible])
    {
        var toolbarHeight = CGRectGetHeight([_toolbarView frame]);
        
        contentRect.origin.y += toolbarHeight;
        contentRect.size.height -= toolbarHeight;
    }
    
    return contentRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    if (_styleMask & CPBorderlessBridgeWindowMask)
        return _bridge ? [_bridge visibleFrame] : CGRectMakeZero();
        
    var frame = [[self class] frameRectForContentRect:aContentRect styleMask:_styleMask];
    
    return frame; 
}

- (CGRect)frame
{
    return _frame;
}

- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    if (shouldAnimate)
    {
        var animation = [[_CPWindowFrameAnimation alloc] initWithWindow:self targetFrame:aFrame];
    
        [animation startAnimation];
    }
    else
    {
        [self setFrameOrigin:aFrame.origin];
        [self setFrameSize:aFrame.size];
    }
}

- (void)setFrame:(CGRect)aFrame
{
    [self setFrame:aFrame display:YES animate:NO];
}

- (void)setFrameOrigin:(CGPoint)anOrigin
{
    var origin = _frame.origin;
    
    if (_CGPointEqualToPoint(origin, anOrigin))
        return;
    
    origin.x = anOrigin.x;
    origin.y = anOrigin.y;
    
#if PLATFORM(DOM)
    CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, origin.x, origin.y);
#endif
}

- (void)setFrameSize:(CGSize)aSize
{
    aSize = _CGSizeMake(MIN(MAX(aSize.width, _minSize.width), _maxSize.width), MIN(MAX(aSize.height, _minSize.height), _maxSize.height));
    
    if (_CGSizeEqualToSize(_frame.size, aSize))
        return;
    
    _frame.size = aSize;
    
    [_windowView setFrameSize:aSize];
    
    if (_hasShadow)
        [_shadowView setFrameSize:_CGSizeMake(SHADOW_MARGIN_LEFT + aSize.width + SHADOW_MARGIN_RIGHT, SHADOW_MARGIN_BOTTOM + aSize.height + SHADOW_MARGIN_TOP + SHADOW_DISTANCE)];
    
    if (!_isAnimating && [_delegate respondsToSelector:@selector(windowDidResize:)])
        [_delegate windowDidResize:self];
}

- (void)trackMoveWithEvent:(CPEvent)anEvent
{
    var type = [anEvent type];
        
    if (type == CPLeftMouseUp)
        return;
    
    else if (type == CPLeftMouseDown)
        _mouseDraggedPoint = [self convertBaseToBridge:[anEvent locationInWindow]];
    
    else if (type == CPLeftMouseDragged)
    {
        var location = [self convertBaseToBridge:[anEvent locationInWindow]];
        
        [self setFrameOrigin:CGPointMake(_CGRectGetMinX(_frame) + (location.x - _mouseDraggedPoint.x), _CGRectGetMinY(_frame) + (location.y - _mouseDraggedPoint.y))];
        
        _mouseDraggedPoint = location;
    }
    
    [CPApp setTarget:self selector:@selector(trackMoveWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)trackResizeWithEvent:(CPEvent)anEvent
{
    var location = [anEvent locationInWindow],
        type = [anEvent type];
        
    if (type == CPLeftMouseUp)
        return;
    
    else if (type == CPLeftMouseDown)
        _resizeFrame = CGRectMake(location.x, location.y, CGRectGetWidth(_frame), CGRectGetHeight(_frame));
    
    else if (type == CPLeftMouseDragged)
        [self setFrameSize:CGSizeMake(CGRectGetWidth(_resizeFrame) + location.x - CGRectGetMinX(_resizeFrame), CGRectGetHeight(_resizeFrame) + location.y - CGRectGetMinY(_resizeFrame))];
    
    [CPApp setTarget:self selector:@selector(trackResizeWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)orderFront:(id)aSender
{
    [_bridge order:CPWindowAbove window:self relativeTo:nil];
}

- (void)orderBack:(id)aSender
{
    //[_bridge order:CPWindowBelow
}

- (void)orderOut:(id)aSender
{
    if ([_delegate respondsToSelector:@selector(windowWillClose:)])
        [_delegate windowWillClose:self];
    
    [_bridge order:CPWindowOut window:self relativeTo:nil];
    
    if ([CPApp keyWindow] == self)
    {
        [self resignKeyWindow];
        
        CPApp._keyWindow = nil;
    }
}

- (void)orderWindow:(CPWindowOrderingMode)aPlace relativeTo:(int)otherWindowNumber
{
    [_bridge order:aPlace window:self relativeTo:CPApp._windows[otherWindowNumber]];
}

- (void)setLevel:(int)aLevel
{
    _level = aLevel;
}

- (int)level
{
    return _level;
}

- (BOOL)isVisible
{
    return _isVisible;
}

- (BOOL)showsResizeIndicator
{
    return [_windowView showsResizeIndicator];
}

- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{       
    [_windowView setShowsResizeIndicator:shouldShowResizeIndicator];
}

- (CGSize)resizeIndicatorOffset
{
    return [_windowView resizeIndicatorOffset];
}

- (void)setResizeIndicatorOffset:(CGSize)anOffset
{
    [_windowView setResizeIndicatorOffset:anOffset];
}

- (void)setContentView:(CPView)aView
{
    if (_contentView)
        [_contentView removeFromSuperview];
    
    _contentView = aView;
    [_contentView setFrame:[self contentRectForFrameRect:_frame]];
    
    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_windowView addSubview:_contentView positioned:CPWindowBelow relativeTo:nil];
}

- (CPView)contentView
{
    return _contentView;
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [_windowView setBackgroundColor:aColor];
}

- (CPColor)backgroundColor
{
    return [_windowView backgroundColor];
}

- (void)setMinSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_minSize, aSize))
        return;
    
    _minSize = CGSizeCreateCopy(aSize);

    var size = CGSizeMakeCopy([self frame].size),
        needsFrameChange = NO;
    
    if (size.width < _minSize.width)
    {
        size.width = _minSize.width;
        needsFrameChange = YES;
    }
    
    if (size.height < _minSize.height)
    {
        size.height = _minSize.height;
        needsFrameChange = YES;
    }
    
    if (needsFrameChange)
        [self setFrameSize:size];
}

- (CGSize)minSize
{
    return _minSize;
}

- (void)setMaxSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_maxSize, aSize))
        return;
    
    _maxSize = CGSizeCreateCopy(aSize);

    var size = CGSizeMakeCopy([self frame].size),
        needsFrameChange = NO;
    
    if (size.width > _maxSize.width)
    {
        size.width = _maxSize.width;
        needsFrameChange = YES;
    }
    
    if (size.height > _maxSize.height)
    {
        size.height = _maxSize.height;
        needsFrameChange = YES;
    }
    
    if (needsFrameChange)
        [self setFrameSize:size];
}

- (CGSize)maxSize
{
    return _maxSize;
}

- (BOOL)hasShadow
{
    return _hasShadow;
}

- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    if (_hasShadow == shouldHaveShadow)
        return;
    
    _hasShadow = shouldHaveShadow;
    
    if (_hasShadow)
    {
        var bounds = [_windowView bounds];
        
        _shadowView = [[CPView alloc] initWithFrame:CGRectMake(-SHADOW_MARGIN_LEFT, -SHADOW_MARGIN_TOP + SHADOW_DISTANCE, 
            SHADOW_MARGIN_LEFT + CGRectGetWidth(bounds) + SHADOW_MARGIN_RIGHT, SHADOW_MARGIN_TOP + CGRectGetHeight(bounds) + SHADOW_MARGIN_BOTTOM)];
    
        if (!_CPWindowShadowColor)
        {
            var bundle = [CPBundle bundleForClass:[self class]];
            
            _CPWindowShadowColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow0.png"] size:CGSizeMake(20.0, 19.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow1.png"] size:CGSizeMake(1.0, 19.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow2.png"] size:CGSizeMake(19.0, 19.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow3.png"] size:CGSizeMake(20.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow5.png"] size:CGSizeMake(19.0, 1.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow6.png"] size:CGSizeMake(20.0, 18.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow7.png"] size:CGSizeMake(1.0, 18.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowShadow8.png"] size:CGSizeMake(19.0, 18.0)]
                ]]];
        }

        [_shadowView setBackgroundColor:_CPWindowShadowColor];
        [_shadowView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        
        CPDOMDisplayServerInsertBefore(_DOMElement, _shadowView._DOMElement, _windowView._DOMElement);
    }
    else
    {
        CPDOMDisplayServerRemoveChild(_DOMElement, _shadowView._DOMElement);

        _shadowView = nil;
    }
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
    
    _delegateRespondsToWindowWillReturnUndoManagerSelector = [_delegate respondsToSelector:@selector(windowWillReturnUndoManager:)];

    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if ([_delegate respondsToSelector:@selector(windowDidBecomeMain:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidBecomeMain:)
                   name:CPWindowDidBecomeMainNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidResignMain:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidResignMain:)
                   name:CPWindowDidResignMainNotification
                 object:self];
}

- (id)delegate
{
    return _delegate;
}

- (void)setWindowController:(CPWindow)aWindowController
{
    _windowController = aWindowController;
}

- (CPWindowController)windowController
{
    return _windowController;
}

- (void)doCommandBySelector:(SEL)aSelector
{
    if ([_delegate respondsToSelector:aSelector])
        [_delegate performSelector:aSelector];
    else
        [super doCommandBySelector:aSelector];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)makeFirstResponder:(CPResponder)aResponder
{
    if (_firstResponder == aResponder)
        return YES;

    if(![_firstResponder resignFirstResponder])
        return NO;

    if(!aResponder || ![aResponder acceptsFirstResponder] || ![aResponder becomeFirstResponder])
    {
        _firstResponder = self;
    
        return NO;
    }

    _firstResponder = aResponder;

    return YES;
}

- (CPResponder)firstResponder
{
    return _firstResponder;
}

- (BOOL)acceptsMouseMovedEvents
{
    return _acceptsMouseMovedEvents;
}

- (void)setAcceptsMouseMovedEvents:(BOOL)shouldAcceptMouseMovedEvents
{
    _acceptsMouseMovedEvents = shouldAcceptMouseMovedEvents;
}

// Managing Titles

- (CPString)title
{
    return _title;
}

- (void)setTitle:(CPString)aTitle
{
    _title = aTitle;
    
    [_windowView setTitle:aTitle];
    
    [self _synchronizeMenuBarTitleWithWindowTitle];
}

- (void)setTitleWithRepresentedFilename:(CPString)aFilePath
{
    [self setRepresentedFilename:aFilePath];
    [self setTitle:[aFilePath lastPathComponent]];
}

- (void)setRepresentedFilename:(CPString)aFilePath
{
    // FIXME: urls vs filepaths and all.
    [self setRepresentedURL:aFilePath];
}

- (CPString)representedFilename
{
    return _representedURL;
}

- (void)setRepresentedURL:(CPURL)aURL
{
    _representedURL = aURL;
}

- (CPURL)representedURL
{
    return _representedURL;
}

// Moving

- (void)setMovableByWindowBackground:(BOOL)shouldBeMovableByWindowBackground
{
    _isMovableByWindowBackground = shouldBeMovableByWindowBackground;
}

- (BOOL)isMovableByWindowBackground
{
    return _isMovableByWindowBackground;
}

- (void)center
{
    var size = [self frame].size,
        bridgeSize = [_bridge contentBounds].size;
    
    [self setFrameOrigin:CGPointMake((bridgeSize.width - size.width) / 2.0, (bridgeSize.height - size.height) / 2.0)];
}

- (void)sendEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        point = [anEvent locationInWindow];

    switch (type)
    {
        case CPKeyUp:               return [[self firstResponder] keyUp:anEvent];
        case CPKeyDown:             return [[self firstResponder] keyDown:anEvent];

        case CPScrollWheel:         return [[_windowView hitTest:point] scrollWheel:anEvent];

        case CPLeftMouseUp:         if (!_leftMouseDownView)
                                        return [[_windowView hitTest:point] mouseUp:anEvent];
                                    
                                    [_leftMouseDownView mouseUp:anEvent]
                                    
                                    _leftMouseDownView = nil;
                                    
                                    return;
        case CPLeftMouseDown:       _leftMouseDownView = [_windowView hitTest:point];
                                    
                                    if (_leftMouseDownView != _firstResponder && [_leftMouseDownView acceptsFirstResponder])
                                        [self makeFirstResponder:_leftMouseDownView];
                
                                    var theWindow = [anEvent window];
                                    
                                    if ([theWindow isKeyWindow] || [theWindow becomesKeyOnlyIfNeeded])
                                        return [_leftMouseDownView mouseDown:anEvent];
                                    else
                                    {
                                        // FIXME: delayed ordering?
                                        [self makeKeyAndOrderFront:self];
                                        
                                        if ([_leftMouseDownView acceptsFirstMouse:anEvent])
                                            return [_leftMouseDownView mouseDown:anEvent]
                                    }
                                    break;
        case CPLeftMouseDragged:    if (!_leftMouseDownView)
                                        return [[_windowView hitTest:point] mouseDragged:anEvent];
                                    
                                    return [_leftMouseDownView mouseDragged:anEvent];
        
        case CPRightMouseUp:        return [_rightMouseDownView mouseUp:anEvent];
        case CPRightMouseDown:      _rightMouseDownView = [_windowView hitTest:point];
                                    return [_rightMouseDownView mouseDown:anEvent];
        case CPRightMouseDragged:   return [_rightMouseDownView mouseDragged:anEvent];
        
        case CPMouseMoved:          if (!_acceptsMouseMovedEvents)
                                        return;
                                    
                                    var hitTestView = [_windowView hitTest:point];
        
                                    if (hitTestView != _mouseOverView)
                                    {
                                        if (_mouseOverView)
                                            [_mouseOverView mouseExited:[CPEvent mouseEventWithType:CPMouseExited location:point 
                                                modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0]];
                                    
                                        if (hitTestView)
                                            [hitTestView mouseEntered:[CPEvent mouseEventWithType:CPMouseEntered location:point 
                                                modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0]];
                            
                                        _mouseOverView = hitTestView;
                                    }
                                    
                                    [_mouseOverView mouseMoved:anEvent];
    }
}

- (int)windowNumber
{
    return _windowNumber;
}

- (void)becomeKeyWindow
{
    if (_firstResponder != self && [_firstResponder respondsToSelector:@selector(becomeKeyWindow)])
        [_firstResponder becomeKeyWindow];
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)isKeyWindow
{
    return [CPApp keyWindow] == self;
}

- (void)makeKeyAndOrderFront:(id)aSender
{
    [self orderFront:self];
    
    [self makeKeyWindow];
    [self makeMainWindow];
}

- (void)makeKeyWindow
{
    if (![self canBecomeKeyWindow])
        return;

    [CPApp._keyWindow resignKeyWindow];
    
    CPApp._keyWindow = self;
    
    [self becomeKeyWindow];
}

- (void)resignKeyWindow
{
    if (_firstResponder != self && [_firstResponder respondsToSelector:@selector(resignKeyWindow)])
        [_firstResponder resignKeyWindow];
    
    if ([_delegate respondsToSelector:@selector(windowDidResignKey:)])
        [_delegate windowDidResignKey:self];
}

- (void)dragImage:(CPImage)anImage at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragImage:anImage fromWindow:self at:[self convertBaseToBridge:imageLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

- (void)dragView:(CPView)aView at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragView:aView fromWindow:self at:[self convertBaseToBridge:imageLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

// Accessing Editing Status

- (void)setDocumentEdited:(BOOL)isDocumentEdited
{
    if (_isDocumentEdited == isDocumentEdited)
        return;
    
    _isDocumentEdited = isDocumentEdited;
    
    [CPMenu _setMenuBarIconImageAlphaValue:_isDocumentEdited ? 0.5 : 1.0];
}

- (BOOL)isDocumentEdited
{
    return _isDocumentEdited;
}

- (void)setDocumentSaving:(BOOL)isDocumentSaving
{
    if (_isDocumentSaving == isDocumentSaving)
        return;
    
    _isDocumentSaving = isDocumentSaving;
    
    [self _synchronizeSaveMenuWithDocumentSaving];
    
    [_windowView windowDidChangeDocumentSaving];
}

- (BOOL)isDocumentSaving
{
    return _isDocumentSaving;
}

- (void)_synchronizeSaveMenuWithDocumentSaving
{
    if (![self isMainWindow])
        return;

    var mainMenu = [CPApp mainMenu],
        index = [mainMenu indexOfItemWithTitle:_isDocumentSaving ? @"Save" : @"Saving..."];
        
    if (index == CPNotFound)
        return;
    
    var item = [mainMenu itemAtIndex:index];
        
    if (_isDocumentSaving)
    {
        CPWindowSaveImage = [item image];
        
        [item setTitle:@"Saving..."];
        [item setImage:CPWindowSavingImage];
        [item setEnabled:NO];
    }
    else
    {
        [item setTitle:@"Save"];
        [item setImage:CPWindowSaveImage];
        [item setEnabled:YES];
    }
}

// Closing Windows

- (void)performClose:(id)aSender
{
    if ([_delegate respondsToSelector:@selector(windowShouldClose:)] && ![_delegate windowShouldClose:self] ||
        [self respondsToSelector:@selector(windowShouldClose:)] && ![self windowShouldClose:self])
        return;
    
    [self close];
}

- (void)close
{
   [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillCloseNotification object:self];

   [self orderOut:nil];
}

// Managing Main Status

- (BOOL)isMainWindow
{
    return [CPApp mainWindow] == self;
}

- (BOOL)canBecomeMainWindow
{
    // FIXME: Also check if we can resize and titlebar.
    if ([self isVisible])
        return YES;
        
    return NO;
}

- (void)makeMainWindow
{
    if (![self canBecomeMainWindow])
        return;

    [CPApp._mainWindow resignMainWindow];
    
    CPApp._mainWindow = self;
    
    [self becomeMainWindow];
}

- (void)becomeMainWindow
{
    [self _synchronizeMenuBarTitleWithWindowTitle];
    [self _synchronizeSaveMenuWithDocumentSaving];
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidBecomeMainNotification
                      object:self];
}

- (void)resignMainWindow
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidResignMainNotification
                      object:self];
}

// Managing Toolbars

- (CPToolbar)toolbar
{
    return _toolbar;
}

- (void)setToolbar:(CPView)aToolbar
{
    if (_toolbar == aToolbar)
        return;
    
    // Cleanup old toolbar
    if (_toolbar)
    {
        [self _setToolbarVisible:NO];
    
        _toolbar._window = nil;
        _toolbarView = nil;
    }
    
    if (_toolbar = aToolbar)
    {
        // Set up new toolbar
        _toolbar = aToolbar;
        _toolbar._window = self;
        
        if ([_toolbar isVisible])
            [self _setToolbarVisible:YES];
            
        [_toolbar _reloadToolbarItems];
    }
}

- (void)_setToolbarVisible:(BOOL)aFlag
{
    if (aFlag)
    {
        if (!_toolbarView)
            _toolbarView = [_toolbar _toolbarView];
        
        [_toolbarView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([_windowView bounds]), CGRectGetHeight([_toolbarView frame]))];
        [_windowView addSubview:_toolbarView];
    }
    else
        [_toolbarView removeFromSuperview];
    
    [_contentView setFrame:[self contentRectForFrameRect:[_windowView bounds]]];
}

// Managing Sheets

- (void)_setAttachedSheetFrameOrigin
{
    // Position the sheet above the contentRect.
    var contentRect = [[self contentView] frame],
        sheetFrame = CGRectMakeCopy([_attachedSheet frame]);
        
   sheetFrame.origin.y = CGRectGetMinY(_frame) + CGRectGetMinY(contentRect);
   sheetFrame.origin.x = CGRectGetMinX(_frame) + FLOOR((CGRectGetWidth(_frame) - CGRectGetWidth(sheetFrame)) / 2.0);
   
   [_attachedSheet setFrameOrigin:sheetFrame.origin];
}

- (void)_animateAttachedSheet
{
/*    NSWindow *sheet = [sheetContext sheet];
    NSRect sheetFrame;

    [_sheetContext autorelease];
   _sheetContext=[sheetContext retain];

   [self _setSheetOrigin];
   sheetFrame = [sheet frame];
   
   [(NSWindowBackgroundView *)[sheet _backgroundView] setBorderType:NSButtonBorder];
   [[sheet contentView] setAutoresizesSubviews:NO];
   [[sheet contentView] setAutoresizingMask:NSViewNotSizable];
   
//   [(NSWindowBackgroundView *)[sheet _backgroundView] cacheImageForAnimation];
   
   [_attachedSheet setFrame:CPRectMake(CGRectGetMinX(sheetFrame), CGRectGetMinY(sheetFrame), CGRectGetWidth(sheetFrame), 0.0) display:YES];
   [sheet setFrame:NSMakeRect(sheetFrame.origin.x, NSMaxY([self frame]), sheetFrame.size.width, 0) display:YES];
   [self _setSheetOriginAndFront];
   
   [sheet setFrame:sheetFrame display:YES animate:YES];*/
}

- (void)_attachSheet:(CPWindow)aSheet modalDelegate:(id)aModalDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    // Set this as our attached sheet.
    _attachedSheet = aSheet;
    
    // If a window is ever run as a sheet, then it's sheet bit is set to YES.
    aSheet._isSheet = YES;
    
    [self _setAttachedSheetFrameOrigin];
    
    // Place this window above ourselves.
    [_bridge order:CPWindowAbove window:aSheet relativeTo:self];
}

- (CPWindow)attachedSheet
{
    return _attachedSheet;
}

- (BOOL)isSheet
{
    return _isSheet;
}

//

- (BOOL)becomesKeyOnlyIfNeeded
{
    return NO;
}

- (BOOL)worksWhenModal
{
    return NO;
}

@end

@implementation CPWindow (MenuBar)

- (void)_synchronizeMenuBarTitleWithWindowTitle
{
    // Windows with Documents automatically update the native window title and the menu bar title.
    if (![_windowController document] || ![self isMainWindow])
        return;

    [CPMenu setMenuBarTitle:_title];
}

@end

@implementation CPWindow (BridgeSupport)

- (void)setBridge:(CPDOMWindowBridge)aBridge
{
    if (_bridge == aBridge)
        return;
        
    if (_bridge)
    {
        [self orderOut:self];
        // FIXME: If the bridge changes, then we have to recreate all of our subviews' DOM Elements.
    }

    _bridge = aBridge;
    
    if (_styleMask & CPBorderlessBridgeWindowMask)
        [self setFrame:[aBridge contentBounds]];
}

- (void)resizeWithOldBridgeSize:(CGSize)aSize
{
    if (_styleMask & CPBorderlessBridgeWindowMask)
        return [self setFrame:[_bridge visibleFrame]];
    
    if (_autoresizingMask == CPWindowNotSizable)
        return;

    var frame = [_bridge contentBounds],
        newFrame = CGRectMakeCopy(_frame),
        dX = (CGRectGetWidth(frame) - aSize.width) /
            (((_autoresizingMask & CPWindowMinXMargin) ? 1 : 0) + (_autoresizingMask & CPWindowWidthSizable ? 1 : 0) + (_autoresizingMask & CPWindowMaxXMargin ? 1 : 0)),
        dY = (CGRectGetHeight(frame) - aSize.height) /
            ((_autoresizingMask & CPWindowMinYMargin ? 1 : 0) + (_autoresizingMask & CPWindowHeightSizable ? 1 : 0) + (_autoresizingMask & CPWindowMaxYMargin ? 1 : 0));

    if (_autoresizingMask & CPWindowMinXMargin)
        newFrame.origin.x += dX;
    if (_autoresizingMask & CPWindowWidthSizable)
        newFrame.size.width += dX;
    
    if (_autoresizingMask & CPWindowMinYMargin)
        newFrame.origin.y += dY;
    if (_autoresizingMask & CPWindowHeightSizable)
        newFrame.size.height += dY;

    [self setFrame:newFrame];
}

- (void)setAutoresizingMask:(unsigned)anAutoresizingMask
{
    _autoresizingMask = anAutoresizingMask;
}

- (unsigned)autoresizingMask
{
    return _autoresizingMask;
}

- (CGPoint)convertBaseToBridge:(CGPoint)aPoint
{
    var origin = [self frame].origin;
    
    return CGPointMake(aPoint.x + origin.x, aPoint.y + origin.y);
}

- (CGPoint)convertBridgeToBase:(CGPoint)aPoint
{
    var origin = [self frame].origin;
    
    return CGPointMake(aPoint.x - origin.x, aPoint.y - origin.y);
}

// Undo and Redo Support

- (CPUndoManager)undoManager
{
    if (_delegateRespondsToWindowWillReturnUndoManagerSelector)
        return [_delegate windowWillReturnUndoManager:self];
    
    if (!_undoManager)
        _undoManager = [[CPUndoManager alloc] init];

    return _undoManager;
}

- (void)undo:(id)aSender
{
    [[self undoManager] undo];
}

- (void)redo:(id)aSender
{
    [[self undoManager] redo];
}

@end

var interpolate = function(fromValue, toValue, progress)
{
    return fromValue + (toValue - fromValue) * progress;
}

@implementation _CPWindowFrameAnimation : CPAnimation
{
    CPWindow    _window;
    
    CGRect      _startFrame;
    CGRect      _targetFrame;
}

- (id)initWithWindow:(CPWindow)aWindow targetFrame:(CGRect)aTargetFrame
{
    self = [super initWithDuration:0.2 animationCurve:CPAnimationLinear];
    
    if (self)
    {
        _window = aWindow;
        
        _targetFrame = CGRectMakeCopy(aTargetFrame);
        _startFrame = CGRectMakeCopy([_window frame]);
    }
    
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    
    _window._isAnimating = YES;
}

- (void)setCurrentProgress:(float)aProgress
{
    [super setCurrentProgress:aProgress];
    
    var value = [self currentValue];
    
    if (value == 1.0)
        _window._isAnimating = NO;
    
    [_window setFrameOrigin:CGPointMake(interpolate(CGRectGetMinX(_startFrame), CGRectGetMinX(_targetFrame), value), interpolate(CGRectGetMinY(_startFrame), CGRectGetMinY(_targetFrame), value))];
    [_window setFrameSize:CGSizeMake(interpolate(CGRectGetWidth(_startFrame), CGRectGetWidth(_targetFrame), value), interpolate(CGRectGetHeight(_startFrame), CGRectGetHeight(_targetFrame), value))];
}

@end

import "CPDragServer.j"
import "CPDOMWindowBridge.j"
import "_CPWindowView.j"
import "CPView.j"
