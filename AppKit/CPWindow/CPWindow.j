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

@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPUndoManager.j>

@import "CGGeometry.j"
@import "CPAnimation.j"
@import "CPResponder.j"

#include "../Platform/Platform.h"
#include "../Platform/DOM/CPDOMDisplayServer.h"

#include "../CoreGraphics/CGGeometry.h"


/*
    Borderless window mask option.
    @global
    @class CPWindow
*/
CPBorderlessWindowMask          = 0;
/*
    Titled window mask option.
    @global
    @class CPWindow
*/
CPTitledWindowMask              = 1 << 0;
/*
    Closeable window mask option.
    @global
    @class CPWindow
*/
CPClosableWindowMask            = 1 << 1;
/*
    Miniaturizabe window mask option.
    @global
    @class CPWindow
*/
CPMiniaturizableWindowMask      = 1 << 2;
/*
    Resizable window mask option.
    @global
    @class CPWindow
*/
CPResizableWindowMask           = 1 << 3;
/*
    Textured window mask option.
    @global
    @class CPWindow
*/
CPTexturedBackgroundWindowMask  = 1 << 8;
/*
    @global
    @class CPWindow
*/
CPBorderlessBridgeWindowMask    = 1 << 20;
/*
    @global
    @class CPWindow
*/
CPHUDBackgroundWindowMask       = 1 << 21;

CPWindowNotSizable              = 0;
CPWindowMinXMargin              = 1;
CPWindowWidthSizable            = 2;
CPWindowMaxXMargin              = 4;
CPWindowMinYMargin              = 8;
CPWindowHeightSizable           = 16;
CPWindowMaxYMargin              = 32;

CPBackgroundWindowLevel         = -1;
/*
    Default level for windows
    @group CPWindowLevel
    @global
*/
CPNormalWindowLevel             = 4;
/*
    Floating palette type window
    @group CPWindowLevel
    @global
*/
CPFloatingWindowLevel           = 5;
/*
    Submenu type window
    @group CPWindowLevel
    @global
*/
CPSubmenuWindowLevel            = 6;
/*
    For a torn-off menu
    @group CPWindowLevel
    @global
*/
CPTornOffMenuWindowLevel        = 6;
/*
    For the application's main menu
    @group CPWindowLevel
    @global
*/
CPMainMenuWindowLevel           = 8;
/*
    Status window level
    @group CPWindowLevel
    @global
*/
CPStatusWindowLevel             = 9;
/*
    Level for a modal panel
    @group CPWindowLevel
    @global
*/
CPModalPanelWindowLevel         = 10;
/*
    Level for a pop up menu
    @group CPWindowLevel
    @global
*/
CPPopUpMenuWindowLevel          = 11;
/*
    Level for a window being dragged
    @group CPWindowLevel
    @global
*/
CPDraggingWindowLevel           = 12;
/*
    Level for the screens saver
    @group CPWindowLevel
    @global
*/
CPScreenSaverWindowLevel        = 13;

/*
    The receiver is removed from the screen list and hidden.
    @global
    @class CPWindowOrderingMode
*/
CPWindowOut                     = 0;
/*
    The receiver is placed directly in front of the window specified.
    @global
    @class CPWindowOrderingMode
*/
CPWindowAbove                   = 1;
/*
    The receiver is placed directly behind the window specified.
    @global
    @class CPWindowOrderingMode
*/
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

/*! @class CPWindow

    An CPWindow instance represents a window, panel or menu on the screen.</p>

    <p>Each window has a style, which determines how the window is decorated; whether it has a border, a title bar, a resize bar, minimise and close buttons.</p>

    <p>A window has a frame. This is the frame of the entire window on the screen, including all decorations and borders. The origin of the frame represents its bottom left corner and the frame is expressed in screen coordinates.</p>

    <p>A window always contains a content view which is the highest level view available for public (application) use. This view fills the area of the window inside any decoration/border. This is the only part of the window that application programmers are allowed to draw in directly.</p>

    <p>You can convert between view coordinates and window base coordinates using the [CPView -convertPoint:fromView:], [CPView -convertPoint:toView:], [CPView -convertRect:fromView:], and [CPView -convertRect:toView:] methods with a nil view argument.
    
    @par Delegate Methods
    
    @delegate -(void)windowDidResize:(CPNotification)notification;
    Sent from the notification center when the window has been resized.
    @param notification contains information about the resize event
    
    @delegate  -(CPUndoManager)windowWillReturnUndoManager:(CPWindow)window;
    Called to obtain the undo manager for a window
    @param window the window for which to return the undo manager
    @return the window's undo manager
    
    @delegate -(void)windowDidBecomeMain:(CPNotification)notification;
    Sent from the notification center when the delegate's window becomes
    the main window.
    @param notification contains information about the event
    
    @delegate -(void)windowDidResignMain:(CPNotification)notification;
    Sent from the notification center when the delegate's window has
    resigned main window status.
    @param notification contains information about the event
    
    @delegate -(void)windowDidResignKey:(CPNotification)notification;
    Sent from the notification center when the delegate's window has
    resigned key window status.
    @param notification contains information about the event
    
    @delegate -(BOOL)windowShouldClose:(id)window;
    Called when the user tries to close the window.
    @param window the window to close
    @return <code>YES</code> allows the window to close. <code>NO</code>
    vetoes the close operation and leaves the window open.
*/
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
    BOOL                _ignoresMouseEvents;
    
    CPWindowController  _windowController;
    
    CGSize              _minSize;
    CGSize              _maxSize;
    
    CGRect              _resizeFrame;
    CGPoint             _mouseDraggedPoint;
    
    CPUndoManager       _undoManager;
    CPURL               _representedURL;
    
    CPArray             _registeredDraggedTypes;
    
    // Bridge Support
#if PLATFORM(DOM)
    DOMElement          _DOMElement;
#endif
    CPDOMWindowBridge   _bridge;
    unsigned            _autoresizingMask;
    
    BOOL                _delegateRespondsToWindowWillReturnUndoManagerSelector;
}

/*
    Private initializer for Objective-J
    @ignore
*/
+ (void)initialize
{
    if (self != [CPWindow class])
        return;
    
    var bundle = [CPBundle bundleForClass:[CPWindow class]];
    
    CPWindowSavingImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(16.0, 16.0)]
}

/*!
    Initializes the window. The method also takes a style bit mask made up
    of any of the following values:
<pre>
CPBorderlessWindowMask
CPTitledWindowMask
CPClosableWindowMask
CPMiniaturizableWindowMask
CPResizableWindowMask
CPTexturedBackgroundWindowMask
</pre>
    @param aContentRect the size and location of the window in screen space
    @param aStyleMask a style mask
    @return the initialized window
*/
- (id)initWithContentRect:(CGRect)aContentRect styleMask:(unsigned int)aStyleMask
{
#if PLATFORM(DOM)
    return [self initWithContentRect:aContentRect styleMask:aStyleMask bridge:[CPDOMWindowBridge sharedDOMWindowBridge]];
#else
    return [self initWithContentRect:aContentRect styleMask:aStyleMask bridge:nil];
#endif
}

/*!
    Initializes the window. The method also takes a style bit mask made up
    of any of the following values:
<pre>
CPBorderlessWindowMask
CPTitledWindowMask
CPClosableWindowMask
CPMiniaturizableWindowMask
CPResizableWindowMask
CPTexturedBackgroundWindowMask
</pre>
    @param aContentRect the size and location of the window in screen space
    @param aStyleMask a style mask
    @param aBridge a DOM-Window bridge object
    @return the initialized window
    @ignore
*/
- (id)initWithContentRect:(CGRect)aContentRect styleMask:(unsigned int)aStyleMask bridge:(CPDOMWindowBridge)aBridge
{
    self = [super init];
    
    if (self)
    {
        // Set up our window number.
        _windowNumber = [CPApp._windows count];
        CPApp._windows[_windowNumber] = self;
        
        _styleMask = aStyleMask;
        _level = aStyleMask === CPBorderlessBridgeWindowMask ? CPBackgroundWindowLevel : CPNormalWindowLevel;
        
        _minSize = CGSizeMake(0.0, 0.0);
        _maxSize = CGSizeMake(1000000.0, 1000000.0);
        
        if (_styleMask & CPBorderlessBridgeWindowMask)
            _autoresizingMask = CPWindowWidthSizable | CPWindowHeightSizable;

        // Create our border view which is the actual root of our view hierarchy.
        var windowViewClass = [[self class] _windowViewClassForStyleMask:aStyleMask];
        
        _frame = [windowViewClass frameRectForContentRect:aContentRect];
        _windowView = [[windowViewClass alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame)) styleMask:aStyleMask owningWindow:self];

        [_windowView _setWindow:self];
        [_windowView setNextResponder:self];

        [self setMovableByWindowBackground:aStyleMask & CPHUDBackgroundWindowMask];
        
        // Create a generic content view.
        [self setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
        
        _firstResponder = self;

#if PLATFORM(DOM)
        _DOMElement = document.createElement("div");
        
        _DOMElement.style.position = "absolute";
        _DOMElement.style.visibility = "visible";
        _DOMElement.style.zIndex = 0;
        
        CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, _CGRectGetMinX(_frame), _CGRectGetMinY(_frame));
        CPDOMDisplayServerSetStyleSize(_DOMElement, 1, 1);
        
        CPDOMDisplayServerAppendChild(_DOMElement, _windowView._DOMElement);
#endif

        [self setBridge:aBridge];

        [self setNextResponder:CPApp];

        [self setHasShadow:aStyleMask !== CPBorderlessWindowMask && !(aStyleMask & CPBorderlessBridgeWindowMask)];
    }
    
    return self;
}

/*!
    @ignore
*/
+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    if (aStyleMask & CPHUDBackgroundWindowMask)
        return _CPHUDWindowView;
    
    else if (aStyleMask & CPBorderlessBridgeWindowMask)
        return _CPBorderlessBridgeWindowView;
    
    else if (aStyleMask === CPBorderlessWindowMask)
        return _CPBorderlessWindowView;
    
    return _CPStandardWindowView;
}

/*!
    Returns the window's style mask.
*/
- (unsigned)styleMask
{
    return _styleMask;
}

/*!
    Returns the frame rectangle used by a window.
    @param aContentRect the content rectangle of the window
    @param aStyleMask the style mask of the window
    @return the matching window's frame rectangle
*/
+ (CGRect)frameRectForContentRect:(CGRect)aContentRect styleMask:(unsigned)aStyleMask
{
    return [[[self class] _windowViewClassForStyleMask:_styleMask] frameRectForContentRect:aContentRect];
}

/*!
    Returns the receiver's content rectangle. A content rectangle does not include toolbars.
    @param aFrame the window's frame rectangle
*/
- (CGRect)contentRectForFrameRect:(CGRect)aFrame
{
    return [_windowView contentRectForFrameRect:aFrame];
}

/*!
    Retrieves the frame rectangle for this window.
    @param aContentRect the window's content rectangle
    @return the window's frame rectangle
*/
- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    return [_windowView frameRectForContentRect:aContentRect];
}

/*!
    Returns the window's frame rectangle
*/
- (CGRect)frame
{
    return _frame;
}

/*!
    Sets the window's frame rectangle. Also tells the window whether it should animate
    the resize operation, and redraw itself if necessary.
    @param aFrame the new size and location for the window
    @param shouldDisplay whether the window should redraw its views
    @param shouldAnimate whether the window resize should be animated
*/
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

/*!
    Sets the window's frame rectangle
*/
- (void)setFrame:(CGRect)aFrame
{
    [self setFrame:aFrame display:YES animate:NO];
}

/*!
    Sets the window's location.
    @param anOrigin the new location for the window
*/
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

/*!
    Sets the window's size.
    @param aSize the new size for the window
*/
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

/*!
    Makes the receiver the front most window in the screen ordering.
    @param aSender the object that requested this
*/
- (void)orderFront:(id)aSender
{
    [_bridge order:CPWindowAbove window:self relativeTo:nil];
}

/*
    Makes the receiver the last window in the screen ordering.
    @param aSender the object that requested this
    @ignore
*/
- (void)orderBack:(id)aSender
{
    //[_bridge order:CPWindowBelow
}

/*!
    Hides the window.
    @param the object that requested this
*/
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

/*!
    Relocates the window in the screen list.
    @param aPlace the positioning relative to <code>otherWindowNumber</code>
    @param otherWindowNumber the window relative to which the receiver should be placed
*/
- (void)orderWindow:(CPWindowOrderingMode)aPlace relativeTo:(int)otherWindowNumber
{
    [_bridge order:aPlace window:self relativeTo:CPApp._windows[otherWindowNumber]];
}

/*!
    Sets the window's level
    @param the window's new level
*/
- (void)setLevel:(int)aLevel
{
    _level = aLevel;
}

/*!
    Returns the window's current level
*/
- (int)level
{
    return _level;
}

/*!
    Returns <code>YES</code> if the window is visible. It does not mean that the window is not obscured by other windows.
*/
- (BOOL)isVisible
{
    return _isVisible;
}

/*!
    Returns <code>YES</code> if the window's resize indicator is showing. <code>NO</code> otherwise.
*/
- (BOOL)showsResizeIndicator
{
    return [_windowView showsResizeIndicator];
}

/*!
    Sets the window's resize indicator.
    @param shouldShowResizeIndicator <code>YES</code> sets the window to show its resize indicator.
*/
- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{       
    [_windowView setShowsResizeIndicator:shouldShowResizeIndicator];
}

/*!
    Returns the offset of the window's resize indicator.
*/
- (CGSize)resizeIndicatorOffset
{
    return [_windowView resizeIndicatorOffset];
}

/*!
    Sets the offset of the window's resize indicator.
    @param aSize the offset for the resize indicator
*/
- (void)setResizeIndicatorOffset:(CGSize)anOffset
{
    [_windowView setResizeIndicatorOffset:anOffset];
}

/*!
    Sets the window's content view. The new view will be resized to fit
    inside the content rectangle of the window.
    @param aView the new content view for the receiver
*/
- (void)setContentView:(CPView)aView
{
    if (_contentView)
        [_contentView removeFromSuperview];
    
    var bounds = CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame));
    
    _contentView = aView;
    [_contentView setFrame:[self contentRectForFrameRect:bounds]];
    
    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_windowView addSubview:_contentView];// positioned:CPWindowBelow relativeTo:nil];
}

/*!
    Returns the window's current content view.
*/
- (CPView)contentView
{
    return _contentView;
}

/*!
    Sets the window's background color.
    @param aColor the new color for the background
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    [_windowView setBackgroundColor:aColor];
}

/*!
    Returns the window's background color.
*/
- (CPColor)backgroundColor
{
    return [_windowView backgroundColor];
}

/*!
    Sets the window's minimum size. If the provided
    size is the same as the current minimum size, the method simply returns.
    @aSize the new minimum size for the window
*/
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

/*!
    Returns the windows minimum size.
*/
- (CGSize)minSize
{
    return _minSize;
}

/*!
    Sets the window's maximum size. If the provided
    size is the same as the current maximum size,
    the method simply returns.
    @param aSize the new maximum size
*/
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

/*!
    Returns the window's maximum size.
*/
- (CGSize)maxSize
{
    return _maxSize;
}

/*!
    Returns <code>YES</code> if the window has a drop shadow. <code>NO</code> otherwise.
*/
- (BOOL)hasShadow
{
    return _hasShadow;
}

/*!
    Sets whether the window should have a drop shadow.
    @param shouldHaveShadow <code>YES</code> to have a drop shadow.
*/
- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    if (_hasShadow === shouldHaveShadow)
        return;
    
    _hasShadow = shouldHaveShadow;
    
    if (_hasShadow)
    {
        var bounds = [_windowView bounds];
        
        _shadowView = [[CPView alloc] initWithFrame:CGRectMake(-SHADOW_MARGIN_LEFT, -SHADOW_MARGIN_TOP + SHADOW_DISTANCE, 
            SHADOW_MARGIN_LEFT + CGRectGetWidth(bounds) + SHADOW_MARGIN_RIGHT, SHADOW_MARGIN_TOP + CGRectGetHeight(bounds) + SHADOW_MARGIN_BOTTOM)];
    
        if (!_CPWindowShadowColor)
        {
            var bundle = [CPBundle bundleForClass:[CPWindow class]];
            
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
        
#if PLATFORM(DOM)
        CPDOMDisplayServerInsertBefore(_DOMElement, _shadowView._DOMElement, _windowView._DOMElement);
#endif
    }
    else if (_shadowView)
    {
#if PLATFORM(DOM)
        CPDOMDisplayServerRemoveChild(_DOMElement, _shadowView._DOMElement);
#endif
        _shadowView = nil;
    }
}

/*!
    Sets the delegate for the window. Passing <code>nil</code> will just remove the window's current delegate.
    @param aDelegate an object to respond to the various delegate methods of CPWindow
*/
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

/*!
    Returns window's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the window's controller
    @param aWindowController a window controller
*/
- (void)setWindowController:(CPWindowController)aWindowController
{
    _windowController = aWindowController;
}

/*!
    Returns the window's controller.
*/
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

/*!
    Attempts to make the <code>aResponder</code> the first responder. Before trying
    to make it the first responder, the receiver will ask the current first responder
    to resign its first responder status. If it resigns, it will ask
    <code>aResponder</code> accept first responder, then finally tell it to become first responder.
    @return <code>YES</code> if the attempt was successful. <code>NO</code> otherwise.
*/
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

/*!
    Returns the window's current first responder.
*/
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

- (BOOL)ignoresMouseEvents
{
    return _ignoresMouseEvents;
}

- (void)setIgnoresMouseEvents:(BOOL)shouldIgnoreMouseEvents
{
    _ignoresMouseEvents = shouldIgnoreMouseEvents;
}

// Managing Titles

/*!
    Returns the window's title bar string
*/
- (CPString)title
{
    return _title;
}

/*!
    Sets the window's title bar string
*/
- (void)setTitle:(CPString)aTitle
{
    _title = aTitle;
    
    [_windowView setTitle:aTitle];
    
    [self _synchronizeMenuBarTitleWithWindowTitle];
}

/*!
    Sets the title bar to represent a file path
*/
- (void)setTitleWithRepresentedFilename:(CPString)aFilePath
{
    [self setRepresentedFilename:aFilePath];
    [self setTitle:[aFilePath lastPathComponent]];
}

/*!
    Sets the path to the file the receiver represents
*/
- (void)setRepresentedFilename:(CPString)aFilePath
{
    // FIXME: urls vs filepaths and all.
    [self setRepresentedURL:aFilePath];
}

/*!
    Returns the path to the file the receiver represents
*/
- (CPString)representedFilename
{
    return _representedURL;
}

/*!
    Sets the URL that the receiver represents
*/
- (void)setRepresentedURL:(CPURL)aURL
{
    _representedURL = aURL;
}

/*!
    Returns the URL that the receiver represents
*/
- (CPURL)representedURL
{
    return _representedURL;
}

// Moving

/*!
    Sets whether the window can be moved by dragging its background. The default is based on the window style.
    @param shouldBeMovableByWindowBackground <code>YES</code> makes the window move from a background drag.
*/
- (void)setMovableByWindowBackground:(BOOL)shouldBeMovableByWindowBackground
{
    _isMovableByWindowBackground = shouldBeMovableByWindowBackground;
}

/*!
    Returns <code>YES</code> if the window can be moved by dragging its background.
*/
- (BOOL)isMovableByWindowBackground
{
    return _isMovableByWindowBackground;
}

/*!
    Sets the window location to be the center of the screen
*/
- (void)center
{
    var size = [self frame].size,
        bridgeSize = [_bridge contentBounds].size;
    
    [self setFrameOrigin:CGPointMake((bridgeSize.width - size.width) / 2.0, (bridgeSize.height - size.height) / 2.0)];
}

/*!
    Dispatches events that are sent to it from CPApplication.
    @param anEvent the event to be dispatched
*/
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

/*!
    Returns the window's number in the desktop's screen list
*/
- (int)windowNumber
{
    return _windowNumber;
}

/*!
    Called when the receiver should become the key window. It also sends
    the <code>becomeKeyWindow</code> message to the first responder.
*/
- (void)becomeKeyWindow
{
    if (_firstResponder != self && [_firstResponder respondsToSelector:@selector(becomeKeyWindow)])
        [_firstResponder becomeKeyWindow];
}

/*!
    Determines if the window can become the key window.
    @return <code>YES</code> means the window can become the key window.
*/
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

/*!
    Returns <code>YES</code> if the window is the key window.
*/
- (BOOL)isKeyWindow
{
    return [CPApp keyWindow] == self;
}

/*!
    Makes the window the key window and brings it to the front of the screen list.
    @param aSender the object requesting this
*/
- (void)makeKeyAndOrderFront:(id)aSender
{
    [self orderFront:self];
    
    [self makeKeyWindow];
    [self makeMainWindow];
}

/*!
    Makes this window the key window.
*/
- (void)makeKeyWindow
{
    if (![self canBecomeKeyWindow])
        return;

    [CPApp._keyWindow resignKeyWindow];
    
    CPApp._keyWindow = self;
    
    [self becomeKeyWindow];
}

/*!
    Causes the window to resign it's key window status.
*/
- (void)resignKeyWindow
{
    if (_firstResponder != self && [_firstResponder respondsToSelector:@selector(resignKeyWindow)])
        [_firstResponder resignKeyWindow];
    
    if ([_delegate respondsToSelector:@selector(windowDidResignKey:)])
        [_delegate windowDidResignKey:self];
}

/*!
    Initiates a drag operation from the receiver to another view that accepts dragged data.
    @param anImage the image to be dragged
    @param aLocation the lower-left corner coordinate of <code>anImage</code>
    @param mouseOffset the distance from the <code>mouseDown:</code> location and the current location
    @param anEvent the <code>mouseDown:</code> that triggered the drag
    @param aPastebaord the pasteboard that holds the drag data
    @param aSourceObject the drag operation controller
    @param slideBack Whether the image should 'slide back' if the drag is rejected
*/
- (void)dragImage:(CPImage)anImage at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragImage:anImage fromWindow:self at:[self convertBaseToBridge:imageLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

/*!
    Initiates a drag operation from the receiver to another view that accepts dragged data.
    @param aView the view to be dragged
    @param aLocation the lower-left corner coordinate of <code>aView</code>
    @param mouseOffset the distance from the <code>mouseDown:</code> location and the current location
    @param anEvent the <code>mouseDown:</code> that triggered the drag
    @param aPastebaord the pasteboard that holds the drag data
    @param aSourceObject the drag operation controller
    @param slideBack Whether the view should 'slide back' if the drag is rejected
*/
- (void)dragView:(CPView)aView at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragView:aView fromWindow:self at:[self convertBaseToBridge:imageLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

/*!
    Sets the receiver's list of acceptable data types for a dragging operation.
    @param pasteboardTypes an array of CPPasteboards
*/
- (void)registerForDraggedTypes:(CPArray)pasteboardTypes
{
    _registeredDraggedTypes = [pasteboardTypes copy];
}

/*!
    Returns an array of all types the receiver accepts for dragging operations.
    @return an array of CPPasteBoards
*/
- (CPArray)registeredDraggedTypes
{
    return _registeredDraggedTypes;
}

/*!
    Resets the array of acceptable data types for a dragging operation.
*/
- (void)unregisterDraggedTypes
{
    _registeredDraggedTypes = nil;
}

// Accessing Editing Status

/*!
    Sets whether the document has been edited.
    @param isDocumentEdited <code>YES</code> if the document has been edited.
*/
- (void)setDocumentEdited:(BOOL)isDocumentEdited
{
    if (_isDocumentEdited == isDocumentEdited)
        return;
    
    _isDocumentEdited = isDocumentEdited;
    
    [CPMenu _setMenuBarIconImageAlphaValue:_isDocumentEdited ? 0.5 : 1.0];
}

/*!
    Returns <code>YES</code> if the document has been edited.
*/
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

/* @ignore */
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

/*!
    Simulates the user closing the window, then closes the window.
    @param aSender the object making this request
*/
- (void)performClose:(id)aSender
{
    // Only send ONE windowShouldClose: message.
    if ([_delegate respondsToSelector:@selector(windowShouldClose:)])
    {
        if (![_delegate windowShouldClose:self])
            return;
    }
    
    // Only check self is delegate does NOT implement this.  This also ensures this when delegate == self (returns true).
    else if ([self respondsToSelector:@selector(windowShouldClose:)] && ![self windowShouldClose:self])
        return;
    
    [self close];
}

/*!
    Closes the window. Posts a <code>CPWindowWillCloseNotification</code> to the
    notification center before closing the window.
*/
- (void)close
{
   [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillCloseNotification object:self];

   [self orderOut:nil];
}

// Managing Main Status
/*!
    Returns <code>YES</code> if this the main window.
*/
- (BOOL)isMainWindow
{
    return [CPApp mainWindow] == self;
}

/*!
    Returns <code>YES</code> if the window can become the main window.
*/
- (BOOL)canBecomeMainWindow
{
    // FIXME: Also check if we can resize and titlebar.
    if ([self isVisible])
        return YES;
        
    return NO;
}

/*!
    Makes the receiver the main window.
*/
- (void)makeMainWindow
{
    if (![self canBecomeMainWindow])
        return;

    [CPApp._mainWindow resignMainWindow];
    
    CPApp._mainWindow = self;
    
    [self becomeMainWindow];
}

/*!
    Called to tell the receiver that it has become the main window.
*/
- (void)becomeMainWindow
{
    [self _synchronizeMenuBarTitleWithWindowTitle];
    [self _synchronizeSaveMenuWithDocumentSaving];
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidBecomeMainNotification
                      object:self];
}

/*!
    Called when the window resigns main window status.
*/
- (void)resignMainWindow
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidResignMainNotification
                      object:self];
}

// Managing Toolbars
/*!
    Return's the window's toolbar
*/
- (CPToolbar)toolbar
{
    return _toolbar;
}

/*!
    Sets the window's toolbar.
    @param aToolbar the window's new toolbar
*/
- (void)setToolbar:(CPToolbar)aToolbar
{
    if (_toolbar === aToolbar)
        return;
    
    // If this has an owner, dump it!
    [[aToolbar _window] setToolbar:nil];
    
    // This is no longer out toolbar.
    [_toolbar _setWindow:nil];
    
    _toolbar = aToolbar;
    
    // THIS is our toolbar.
    [_toolbar _setWindow:self];
    
    [self _noteToolbarChanged];
}

- (void)toggleToolbarShown:(id)aSender
{
    var toolbar = [self toolbar];
    
    [toolbar setVisible:![toolbar isVisible]];
}

- (void)_noteToolbarChanged
{
    [_windowView noteToolbarChanged];
}

/* @ignore */
- (void)_setAttachedSheetFrameOrigin
{
    // Position the sheet above the contentRect.
    var contentRect = [[self contentView] frame],
        sheetFrame = CGRectMakeCopy([_attachedSheet frame]);
        
   sheetFrame.origin.y = CGRectGetMinY(_frame) + CGRectGetMinY(contentRect);
   sheetFrame.origin.x = CGRectGetMinX(_frame) + FLOOR((CGRectGetWidth(_frame) - CGRectGetWidth(sheetFrame)) / 2.0);
   
   [_attachedSheet setFrameOrigin:sheetFrame.origin];
}

/* @ignore */
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

/* @ignore */
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

/*!
    Returns the window's attached sheet.
*/
- (CPWindow)attachedSheet
{
    return _attachedSheet;
}

/*!
    Returns <code>YES</code> if the window has ever run as a sheet.
*/
- (BOOL)isSheet
{
    return _isSheet;
}

//
/*
    Used privately.
    @ignore
*/
- (BOOL)becomesKeyOnlyIfNeeded
{
    return NO;
}

/*!
    Returns <code>YES</code> if the receiver is able to receive input events
    even when a modal session is active.
*/
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

/*
    Sets the DOM-Window bridge for this window.
    @ignore
*/
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

/*
    @ignore
*/
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

/*
    @ignore
*/
- (void)setAutoresizingMask:(unsigned)anAutoresizingMask
{
    _autoresizingMask = anAutoresizingMask;
}

/*
    @ignore
*/
- (unsigned)autoresizingMask
{
    return _autoresizingMask;
}

/*
    @ignore
*/
- (CGPoint)convertBaseToBridge:(CGPoint)aPoint
{
    var origin = [self frame].origin;
    
    return CGPointMake(aPoint.x + origin.x, aPoint.y + origin.y);
}

/*
    @ignore
*/
- (CGPoint)convertBridgeToBase:(CGPoint)aPoint
{
    var origin = [self frame].origin;
    
    return CGPointMake(aPoint.x - origin.x, aPoint.y - origin.y);
}

// Undo and Redo Support
/*!
    Returns the window's undo manager.
*/
- (CPUndoManager)undoManager
{
    if (_delegateRespondsToWindowWillReturnUndoManagerSelector)
        return [_delegate windowWillReturnUndoManager:self];
    
    if (!_undoManager)
        _undoManager = [[CPUndoManager alloc] init];

    return _undoManager;
}

/*!
    Sends the undo manager an <code>undo</code> message.
    @param aSender the object requesting this
*/
- (void)undo:(id)aSender
{
    [[self undoManager] undo];
}

/*!
    Sends the undo manager a <code>redo:</code> message.
    @param aSender the object requesting this
*/
- (void)redo:(id)aSender
{
    [[self undoManager] redo];
}

- (BOOL)containsPoint:(CGPoint)aPoint
{
    return CGRectContainsPoint(_frame, aPoint);
}

@end

var interpolate = function(fromValue, toValue, progress)
{
    return fromValue + (toValue - fromValue) * progress;
}

/* @ignore */
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

@import "_CPWindowView.j"
@import "_CPStandardWindowView.j"
@import "_CPHUDWindowView.j"
@import "_CPBorderlessWindowView.j"
@import "_CPBorderlessBridgeWindowView.j"
@import "CPDragServer.j"
@import "CPDOMWindowBridge.j"
@import "CPView.j"
