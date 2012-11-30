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

@import <Foundation/CPCountedSet.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPUndoManager.j>

@import "CGGeometry.j"
@import "CPAnimation.j"
@import "CPPlatformWindow.j"
@import "CPResponder.j"
@import "CPScreen.j"


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
CPNormalWindowLevel             = 0;
/*
    Floating palette type window
    @group CPWindowLevel
    @global
*/
CPFloatingWindowLevel           = 3;
/*
    Submenu type window
    @group CPWindowLevel
    @global
*/
CPSubmenuWindowLevel            = 3;
/*
    For a torn-off menu
    @group CPWindowLevel
    @global
*/
CPTornOffMenuWindowLevel        = 3;
/*
    For the application's main menu
    @group CPWindowLevel
    @global
*/
CPMainMenuWindowLevel           = 24;
/*
    Status window level
    @group CPWindowLevel
    @global
*/
CPStatusWindowLevel             = 25;
/*
    Level for a modal panel
    @group CPWindowLevel
    @global
*/
CPModalPanelWindowLevel         = 8;
/*
    Level for a pop up menu
    @group CPWindowLevel
    @global
*/
CPPopUpMenuWindowLevel          = 101;
/*
    Level for a window being dragged
    @group CPWindowLevel
    @global
*/
CPDraggingWindowLevel           = 500;
/*
    Level for the screens saver
    @group CPWindowLevel
    @global
*/
CPScreenSaverWindowLevel        = 1000;

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

CPWindowWillCloseNotification                   = @"CPWindowWillCloseNotification";
CPWindowDidBecomeMainNotification               = @"CPWindowDidBecomeMainNotification";
CPWindowDidResignMainNotification               = @"CPWindowDidResignMainNotification";
CPWindowDidBecomeKeyNotification                = @"CPWindowDidBecomeKeyNotification";
CPWindowDidResignKeyNotification                = @"CPWindowDidResignKeyNotification";
CPWindowDidResizeNotification                   = @"CPWindowDidResizeNotification";
CPWindowDidMoveNotification                     = @"CPWindowDidMoveNotification";
CPWindowWillBeginSheetNotification              = @"CPWindowWillBeginSheetNotification";
CPWindowDidEndSheetNotification                 = @"CPWindowDidEndSheetNotification";
CPWindowDidMiniaturizeNotification              = @"CPWindowDidMiniaturizeNotification";
CPWindowWillMiniaturizeNotification             = @"CPWindowWillMiniaturizeNotification";
CPWindowDidDeminiaturizeNotification            = @"CPWindowDidDeminiaturizeNotification";

_CPWindowDidChangeFirstResponderNotification    = @"_CPWindowDidChangeFirstResponderNotification";

CPWindowShadowStyleStandard = 0;
CPWindowShadowStyleMenu     = 1;
CPWindowShadowStylePanel    = 2;

var SHADOW_MARGIN_LEFT      = 20.0,
    SHADOW_MARGIN_RIGHT     = 19.0,
    SHADOW_MARGIN_TOP       = 10.0,
    SHADOW_MARGIN_BOTTOM    = 10.0,
    SHADOW_DISTANCE         = 5.0,

    _CPWindowShadowColor    = nil;

var CPWindowSaveImage       = nil,
    CPWindowSavingImage     = nil,

    CPWindowResizeTime      = 0.2;

/*
    Keys for which action messages will be sent by default when unhandled, e.g. complete:.
*/
var CPWindowActionMessageKeys = [
        CPLeftArrowFunctionKey,
        CPRightArrowFunctionKey,
        CPUpArrowFunctionKey,
        CPDownArrowFunctionKey,
        CPPageUpFunctionKey,
        CPPageDownFunctionKey,
        CPHomeFunctionKey,
        CPEndFunctionKey,
        CPEscapeFunctionKey
    ];

/*!
    @ingroup appkit
    @class CPWindow

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
    @return \c YES allows the window to close. \c NO
    vetoes the close operation and leaves the window open.

    @delegate -(BOOL)windowWillBeginSheet:(CPNotification)notification;
    Sent from the notification center before sheet is visible on
    the delegate's window.
    @param notification contains information about the event

    @delegate -(BOOL)windowDidEndSheet:(CPNotification)notification;
    Sent from the notification center when an attached sheet on the
    delegate's window has been animated out and is no longer visible.
    @param notification contains information about the event
*/
@implementation CPWindow : CPResponder
{
    CPPlatformWindow                    _platformWindow;

    int                                 _windowNumber;
    unsigned                            _styleMask;
    CGRect                              _frame;
    int                                 _level;
    BOOL                                _isVisible;
    BOOL                                _isMiniaturized;
    BOOL                                _isAnimating;
    BOOL                                _hasShadow;
    BOOL                                _isMovableByWindowBackground;
    BOOL                                _isMovable;
    unsigned                            _shadowStyle;
    BOOL                                _showsResizeIndicator;

    int                                 _positioningMask;
    CGRect                              _positioningScreenRect;

    BOOL                                _isDocumentEdited;
    BOOL                                _isDocumentSaving;

    CPImageView                         _shadowView;

    CPView                              _windowView;
    CPView                              _contentView;
    CPView                              _toolbarView;

    CPArray                             _mouseEnteredStack;
    CPView                              _leftMouseDownView;
    CPView                              _rightMouseDownView;

    CPToolbar                           _toolbar;
    CPResponder                         _firstResponder;
    CPResponder                         _initialFirstResponder;
    id                                  _delegate;

    CPString                            _title;

    BOOL                                _acceptsMouseMovedEvents;
    BOOL                                _ignoresMouseEvents;

    CPWindowController                  _windowController;

    CGSize                              _minSize;
    CGSize                              _maxSize;

    CPUndoManager                       _undoManager;
    CPURL                               _representedURL;

    CPSet                               _registeredDraggedTypes;
    CPArray                             _registeredDraggedTypesArray;
    CPCountedSet                        _inclusiveRegisteredDraggedTypes;

    CPButton                            _defaultButton;
    BOOL                                _defaultButtonEnabled;

    BOOL                                _autorecalculatesKeyViewLoop;
    BOOL                                _keyViewLoopIsDirty;

    BOOL                                _sharesChromeWithPlatformWindow;

    // Bridge Support
#if PLATFORM(DOM)
    DOMElement                          _DOMElement;
#endif

    unsigned                            _autoresizingMask;

    BOOL                                _delegateRespondsToWindowWillReturnUndoManagerSelector;

    BOOL                                _isFullPlatformWindow;
    _CPWindowFullPlatformWindowSession  _fullPlatformWindowSession;

    CPDictionary                        _sheetContext;
    CPWindow                            _parentView;
    BOOL                                _isSheet;
    _CPWindowFrameAnimation             _frameAnimation;
}

/*
    Private initializer for Objective-J
    @ignore
*/
+ (void)initialize
{
    if (self !== [CPWindow class])
        return;

    var bundle = [CPBundle bundleForClass:[CPWindow class]];

    CPWindowSavingImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(16.0, 16.0)]
}

- (id)init
{
    return [self initWithContentRect:_CGRectMakeZero() styleMask:CPTitledWindowMask];
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
    self = [super init];

    if (self)
    {
        var windowViewClass = [[self class] _windowViewClassForStyleMask:aStyleMask];

        _frame = [windowViewClass frameRectForContentRect:aContentRect];

        [self _setSharesChromeWithPlatformWindow:![CPPlatform isBrowser]];

        if ([CPPlatform isBrowser])
            [self setPlatformWindow:[CPPlatformWindow primaryPlatformWindow]];
        else
        {
            // give zero sized borderless bridge windows a default size if we're not in the browser so they show up in NativeHost.
            if ((aStyleMask & CPBorderlessBridgeWindowMask) && aContentRect.size.width === 0 && aContentRect.size.height === 0)
            {
                var visibleFrame = [[[CPScreen alloc] init] visibleFrame];
                _frame.size.height = MIN(768.0, visibleFrame.size.height);
                _frame.size.width = MIN(1024.0, visibleFrame.size.width);
                _frame.origin.x = (visibleFrame.size.width - _frame.size.width) / 2;
                _frame.origin.y = (visibleFrame.size.height - _frame.size.height) / 2;
            }
            [self setPlatformWindow:[[CPPlatformWindow alloc] initWithContentRect:_frame]];
            [self platformWindow]._only = self;
        }

        _isFullPlatformWindow = NO;
        _registeredDraggedTypes = [CPSet set];
        _registeredDraggedTypesArray = [];
        _acceptsMouseMovedEvents = YES;
        _isMovable = YES;

        _isSheet = NO;
        _sheetContext = nil;
        _parentView = nil;

        // Set up our window number.
        _windowNumber = [CPApp._windows count];
        CPApp._windows[_windowNumber] = self;

        _styleMask = aStyleMask;

        [self setLevel:CPNormalWindowLevel];

        _minSize = CGSizeMake(0.0, 0.0);
        _maxSize = CGSizeMake(1000000.0, 1000000.0);

        // Create our border view which is the actual root of our view hierarchy.
        _windowView = [[windowViewClass alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame)) styleMask:aStyleMask];

        [_windowView _setWindow:self];
        [_windowView setNextResponder:self];

        [self setMovableByWindowBackground:aStyleMask & CPHUDBackgroundWindowMask];

        // Create a generic content view.
        [self setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
        [self setInitialFirstResponder:[self contentView]];

        _firstResponder = self;

#if PLATFORM(DOM)
        _DOMElement = document.createElement("div");

        _DOMElement.style.position = "absolute";
        _DOMElement.style.visibility = "visible";
        _DOMElement.style.zIndex = 0;

        if (![self _sharesChromeWithPlatformWindow])
        {
            CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, _CGRectGetMinX(_frame), _CGRectGetMinY(_frame));
        }

        CPDOMDisplayServerSetStyleSize(_DOMElement, 1, 1);
        CPDOMDisplayServerAppendChild(_DOMElement, _windowView._DOMElement);
#endif

        [self setNextResponder:CPApp];

        [self setHasShadow:aStyleMask !== CPBorderlessWindowMask];

        if (aStyleMask & CPBorderlessBridgeWindowMask)
            [self setFullPlatformWindow:YES];

        _autorecalculatesKeyViewLoop = NO;
        _defaultButtonEnabled = YES;
        _keyViewLoopIsDirty = YES;

        [self setShowsResizeIndicator:_styleMask & CPResizableWindowMask];
    }

    return self;
}

- (CPPlatformWindow)platformWindow
{
    return _platformWindow;
}

/*!
    Sets the platform window of the reciver.
    This method will first close the reciever,
    change the platform window, then reopen the window (if it was originally open).
*/
- (void)setPlatformWindow:(CPPlatformWindow)aPlatformWindow
{
    var wasVisible = [self isVisible];

    // we have to close it first, otherwise we get a DOM exception.
    if (wasVisible)
        [self close];

    _platformWindow = aPlatformWindow;
    [_platformWindow _setTitle:_title window:self];

    if (wasVisible)
        [self orderFront:self];
}


/*!
    @ignore
*/
+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    if (aStyleMask & CPHUDBackgroundWindowMask)
        return _CPHUDWindowView;

    else if (aStyleMask === CPBorderlessWindowMask)
        return _CPBorderlessWindowView;

    else if (aStyleMask & CPDocModalWindowMask)
        return _CPDocModalWindowView;

    return _CPStandardWindowView;
}

+ (Class)_windowViewClassForFullPlatformWindowStyleMask:(unsigned)aStyleMask
{
    return _CPBorderlessBridgeWindowView;
}

- (void)awakeFromCib
{
    _keyViewLoopIsDirty = ![self _hasKeyViewLoop];

    // If no key view loop has been specified by hand, and we are not intending to auto recalculate,
    // set up a default key view loop.
    if (_keyViewLoopIsDirty && ![self autorecalculatesKeyViewLoop])
        [self recalculateKeyViewLoop];

    // At this time we know the final screen (or browser) size and can apply the positioning mask, if any, from the nib.
    if (_positioningScreenRect)
    {
        var actualScreenRect = [CPPlatform isBrowser] ? [_platformWindow contentBounds] : [[self screen] visibleFrame],
            frame = [self frame],
            origin = frame.origin;

        if (actualScreenRect)
        {
            if ((_positioningMask & CPWindowPositionFlexibleLeft) && (_positioningMask & CPWindowPositionFlexibleRight))
            {
                // Proportional Horizontal.
                origin.x *= (actualScreenRect.size.width / _positioningScreenRect.size.width);
            }
            else if (_positioningMask & CPWindowPositionFlexibleLeft)
            {
                // Fixed from Right
                origin.x += actualScreenRect.size.width - _positioningScreenRect.size.width;
            }
            else if (_positioningMask & CPWindowPositionFlexibleRight)
            {
                // Fixed from Left
            }

            if ((_positioningMask & CPWindowPositionFlexibleTop) && (_positioningMask & CPWindowPositionFlexibleBottom))
            {
                // Proportional Vertical.
                origin.y *= (actualScreenRect.size.height / _positioningScreenRect.size.height);
            }
            else if (_positioningMask & CPWindowPositionFlexibleTop)
            {
                // Fixed from Bottom
                origin.y += actualScreenRect.size.height - _positioningScreenRect.size.height;
            }
            else if (_positioningMask & CPWindowPositionFlexibleBottom)
            {
               // Fixed from Top
            }

            [self setFrameOrigin:origin];
        }
    }
}

- (void)_setWindowView:(CPView)aWindowView
{
    if (_windowView === aWindowView)
        return;

    var oldWindowView = _windowView;

    _windowView = aWindowView;

    if (oldWindowView)
    {
        [oldWindowView _setWindow:nil];
        [oldWindowView noteToolbarChanged];

#if PLATFORM(DOM)
        CPDOMDisplayServerRemoveChild(_DOMElement, oldWindowView._DOMElement);
#endif
    }

    if (_windowView)
    {
#if PLATFORM(DOM)
        CPDOMDisplayServerAppendChild(_DOMElement, _windowView._DOMElement);
#endif

        var contentRect = [_contentView convertRect:[_contentView bounds] toView:nil];

        contentRect.origin = [self convertBaseToGlobal:contentRect.origin];

        [_windowView _setWindow:self];
        [_windowView setNextResponder:self];
        [_windowView addSubview:_contentView];
        [_windowView setTitle:_title];
        [_windowView noteToolbarChanged];
        [_windowView setShowsResizeIndicator:[self showsResizeIndicator]];

        [self setFrame:[self frameRectForContentRect:contentRect]];
    }
}

/*!
    Sets the receiver as a full platform window. If you pass YES the CPWindow instance will fill the entire browser content area,
    otherwise the CPWindow will be a window inside of your browser window which the user can drag around, and resize (if you allow).

    @param BOOL - YES if the window should fill the browser window, otherwise NO.
*/
- (void)setFullPlatformWindow:(BOOL)shouldBeFullPlatformWindow
{
    if (![_platformWindow supportsFullPlatformWindows])
        return;

    shouldBeFullPlatformWindow = !!shouldBeFullPlatformWindow;

    if (_isFullPlatformWindow === shouldBeFullPlatformWindow)
        return;

    _isFullPlatformWindow = shouldBeFullPlatformWindow;

    if (_isFullPlatformWindow)
    {
        _fullPlatformWindowSession = _CPWindowFullPlatformWindowSessionMake(_windowView, [self contentRectForFrameRect:[self frame]], [self hasShadow], [self level]);

        var fullPlatformWindowViewClass = [[self class] _windowViewClassForFullPlatformWindowStyleMask:_styleMask],
            windowView = [[fullPlatformWindowViewClass alloc] initWithFrame:CGRectMakeZero() styleMask:_styleMask];

        [self _setWindowView:windowView];

        [self setLevel:CPBackgroundWindowLevel];
        [self setHasShadow:NO];
        [self setAutoresizingMask:CPWindowWidthSizable | CPWindowHeightSizable];
        [self setFrame:[_platformWindow visibleFrame]];
    }
    else
    {
        var windowView = _fullPlatformWindowSession.windowView;

        [self _setWindowView:windowView];

        [self setLevel:_fullPlatformWindowSession.level];
        [self setHasShadow:_fullPlatformWindowSession.hasShadow];
        [self setAutoresizingMask:CPWindowNotSizable];

        [self setFrame:[windowView frameRectForContentRect:_fullPlatformWindowSession.contentRect]];
    }
}

/*!
    @return BOOL - YES if the CPWindow fills the browser window, otherwise NO.
*/
- (BOOL)isFullPlatformWindow
{
    return _isFullPlatformWindow;
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
    Style masks include:
    <pre>
    CPBorderlessWindowMask
    CPTitledWindowMask
    CPClosableWindowMask
    CPMiniaturizableWindowMask (NOTE: only available in NativeHost)
    CPResizableWindowMask
    CPTexturedBackgroundWindowMask
    CPBorderlessBridgeWindowMask
    CPHUDBackgroundWindowMask
    </pre>

    @param aContentRect the content rectangle of the window
    @param aStyleMask the style mask of the window
    @return the matching window's frame rectangle
*/
+ (CGRect)frameRectForContentRect:(CGRect)aContentRect styleMask:(unsigned)aStyleMask
{
    return [[[self class] _windowViewClassForStyleMask:aStyleMask] frameRectForContentRect:aContentRect];
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
    return _CGRectMakeCopy(_frame);
}

/*!
    Sets the window's frame rectangle. Also tells the window whether it should animate
    the resize operation, and redraw itself if necessary.
    @param aFrame the new size and location for the window
    @param shouldDisplay whether the window should redraw its views
    @param shouldAnimate whether the window resize should be animated.
*/
- (void)_setClippedFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    aFrame.size.width = MIN(MAX(aFrame.size.width, _minSize.width), _maxSize.width)
    aFrame.size.height = MIN(MAX(aFrame.size.height, _minSize.height), _maxSize.height);
    [self setFrame:aFrame display:shouldDisplay animate:shouldAnimate];
}

/*!
    Sets the frame of the window.

    @param aFrame - A CGRect of the new frame for the receiver.
    @param shouldDisplay - YES if the window should call setNeedsDisplay otherwise NO.
    @param shouldAnimate - YES if the window should animate to it's new size and position, otherwise NO.
*/
- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    aFrame = _CGRectMakeCopy(aFrame);

    var value = aFrame.origin.x,
        delta = value - FLOOR(value);

    if (delta)
        aFrame.origin.x = value > 0.879 ? CEIL(value) : FLOOR(value);

    value = aFrame.origin.y;
    delta = value - FLOOR(value);

    if (delta)
        aFrame.origin.y = value > 0.879 ? CEIL(value) : FLOOR(value);

    value = aFrame.size.width;
    delta = value - FLOOR(value);

    if (delta)
        aFrame.size.width = value > 0.15 ? CEIL(value) : FLOOR(value);

    value = aFrame.size.height;
    delta = value - FLOOR(value);

    if (delta)
        aFrame.size.height = value > 0.15 ? CEIL(value) : FLOOR(value);

    if (shouldAnimate)
    {
        [_frameAnimation stopAnimation];
        _frameAnimation = [[_CPWindowFrameAnimation alloc] initWithWindow:self targetFrame:aFrame];

        [_frameAnimation startAnimation];
    }
    else
    {
        var origin = _frame.origin,
            newOrigin = aFrame.origin;

        if (!_CGPointEqualToPoint(origin, newOrigin))
        {
            origin.x = newOrigin.x;
            origin.y = newOrigin.y;

#if PLATFORM(DOM)
            if (![self _sharesChromeWithPlatformWindow])
            {
                CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, origin.x, origin.y);
            }
#endif

            [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidMoveNotification object:self];
        }

        var size = _frame.size,
            newSize = aFrame.size;

        if (!_CGSizeEqualToSize(size, newSize))
        {
            size.width = newSize.width;
            size.height = newSize.height;

            [_windowView setFrameSize:size];

            if (_hasShadow)
            {
                // if the shadow would be taller/wider than the window height,
                // make it the same as the window height. this allows views to
                // become 0, 0 with no shadow on them and makes the sheet
                // animation look nicer
                var shadowSize = _CGSizeMake(size.width, size.height);

                if (size.width >= (SHADOW_MARGIN_LEFT + SHADOW_MARGIN_RIGHT))
                    shadowSize.width += SHADOW_MARGIN_LEFT + SHADOW_MARGIN_RIGHT;

                if (size.height >= (SHADOW_MARGIN_BOTTOM + SHADOW_MARGIN_TOP + SHADOW_DISTANCE))
                    shadowSize.height += SHADOW_MARGIN_BOTTOM + SHADOW_MARGIN_TOP + SHADOW_DISTANCE;

                [_shadowView setFrameSize:shadowSize];
            }

            if (!_isAnimating)
                [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidResizeNotification object:self];
        }

        if ([self _sharesChromeWithPlatformWindow])
            [_platformWindow setContentRect:_frame];
    }
}

/*!
    Sets the window's frame rect.
    @param aFrame - The new CGRect of the window.
    @param shouldDisplay - YES if the window should call setNeedsDisplay: otherwise NO.
*/
- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay
{
    [self _setClippedFrame:aFrame display:shouldDisplay animate:NO];
}

/*!
    Sets the window's frame rectangle
    @param aFrame - The CGRect of the windows new frame
*/
- (void)setFrame:(CGRect)aFrame
{
    [self _setClippedFrame:aFrame display:YES animate:NO];
}

/*!
    Sets the window's location.
    @param anOrigin the new location for the window
*/
- (void)setFrameOrigin:(CGPoint)anOrigin
{
    [self _setClippedFrame:_CGRectMake(anOrigin.x, anOrigin.y, _CGRectGetWidth(_frame), _CGRectGetHeight(_frame)) display:YES animate:NO];

    // reposition sheet
    if ([self attachedSheet])
        [self _setAttachedSheetFrameOrigin];
}

/*!
    Sets the window's size.
    @param aSize the new size for the window
*/
- (void)setFrameSize:(CGSize)aSize
{
    [self _setClippedFrame:_CGRectMake(_CGRectGetMinX(_frame), _CGRectGetMinY(_frame), aSize.width, aSize.height) display:YES animate:NO];
}

/*!
    Makes the receiver the front most window in the screen ordering.
    @param aSender the object that requested this
*/
- (void)orderFront:(id)aSender
{
#if PLATFORM(DOM)
    // -dw- if a sheet is clicked, the parent window should come up too
    if ([self isSheet])
        [_parentView orderFront:self];

    [_platformWindow orderFront:self];
    [_platformWindow order:CPWindowAbove window:self relativeTo:nil];
#endif

    if (!CPApp._keyWindow)
        [self makeKeyWindow];

    if ([self isKeyWindow] && (_firstResponder === self || !_firstResponder))
        [self makeFirstResponder:_initialFirstResponder];

    if (!CPApp._mainWindow)
        [self makeMainWindow];
}

/*
    Makes the receiver the last window in the screen ordering.
    @param aSender the object that requested this
    @ignore
*/
- (void)orderBack:(id)aSender
{
    //[_platformWindow order:CPWindowBelow
}

/*!
    Hides the window.
    @param the object that requested this
*/
- (void)orderOut:(id)aSender
{
    if ([self isSheet])
    {
        // -dw- as in Cocoa, orderOut: detaches the sheet and animates out
        [self._parentView _detachSheetWindow];
        return;
    }

#if PLATFORM(DOM)
    if ([self _sharesChromeWithPlatformWindow])
        [_platformWindow orderOut:self];
#endif

    if ([_delegate respondsToSelector:@selector(windowWillClose:)])
        [_delegate windowWillClose:self];

#if PLATFORM(DOM)
    [_platformWindow order:CPWindowOut window:self relativeTo:nil];
#endif

    [self _updateMainAndKeyWindows];
}

/*!
    Relocates the window in the screen list.
    @param aPlace the positioning relative to \c otherWindowNumber
    @param otherWindowNumber the window relative to which the receiver should be placed
*/
- (void)orderWindow:(CPWindowOrderingMode)aPlace relativeTo:(int)otherWindowNumber
{
#if PLATFORM(DOM)
    [_platformWindow order:aPlace window:self relativeTo:CPApp._windows[otherWindowNumber]];
#endif
}

/*!
    Sets the window's level
    @param the window's new level
*/
- (void)setLevel:(int)aLevel
{
    if (aLevel === _level)
        return;

    [_platformWindow moveWindow:self fromLevel:_level toLevel:aLevel];

    _level = aLevel;

    if ([self _sharesChromeWithPlatformWindow])
        [_platformWindow setLevel:aLevel];
}

/*!
    Returns the window's current level
*/
- (int)level
{
    return _level;
}

/*!
    Returns \c YES if the window is visible. It does not mean that the window is not obscured by other windows.
*/
- (BOOL)isVisible
{
    return _isVisible;
}

/*!
    Returns \c YES if the window's resize indicator is showing. \c NO otherwise.
*/
- (BOOL)showsResizeIndicator
{
    return _showsResizeIndicator;
}

/*!
    Sets the window's resize indicator.
    @param shouldShowResizeIndicator \c YES sets the window to show its resize indicator.
*/
- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{
    shouldShowResizeIndicator = !!shouldShowResizeIndicator;

    if (_showsResizeIndicator === shouldShowResizeIndicator)
        return;

    _showsResizeIndicator = shouldShowResizeIndicator;
    [_windowView setShowsResizeIndicator:[self showsResizeIndicator]];
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

    // During init the initial first responder is set to the contentView
    // if it hasn't changed in the mean time we need to update that reference
    // to the new contentView
    if (_initialFirstResponder === _contentView)
        [self setInitialFirstResponder:aView];

    _contentView = aView;
    [_contentView setFrame:[self contentRectForFrameRect:bounds]];

    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_windowView addSubview:_contentView];
}

/*!
    Returns the window's current content view.
*/
- (CPView)contentView
{
    return _contentView;
}

/*!
    Applies an alpha value to the window.
    @param aValue the alpha value to apply
*/
- (void)setAlphaValue:(float)aValue
{
    [_windowView setAlphaValue:aValue];
}

/*!
    Returns the alpha value of the window.
*/
- (float)alphaValue
{
    return [_windowView alphaValue];
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
    @param aSize the new minimum size for the window
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
    Returns \c YES if the window has a drop shadow. \c NO otherwise.
*/
- (BOOL)hasShadow
{
    return _hasShadow;
}

- (void)_updateShadow
{
    if ([self _sharesChromeWithPlatformWindow])
    {
        if (_shadowView)
        {
#if PLATFORM(DOM)
            CPDOMDisplayServerRemoveChild(_DOMElement, _shadowView._DOMElement);
#endif
            _shadowView = nil;
        }

        [_platformWindow setHasShadow:_hasShadow];

        return;
    }

    if (_hasShadow && !_shadowView)
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
    else if (!_hasShadow && _shadowView)
    {
#if PLATFORM(DOM)
        CPDOMDisplayServerRemoveChild(_DOMElement, _shadowView._DOMElement);
#endif
        _shadowView = nil;
    }
}

/*!
    Sets whether the window should have a drop shadow.
    @param shouldHaveShadow \c YES to have a drop shadow.
*/
- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    if (_hasShadow === shouldHaveShadow)
        return;

    _hasShadow = shouldHaveShadow;

    [self _updateShadow];
}

/*!
    Sets the shadow style of the receiver.
    Values are:
    <pre>
    CPWindowShadowStyleStandard
    CPWindowShadowStyleMenu
    CPWindowShadowStylePanel
    </pre>

    @param aStyle - The new shadow style of the receiver.
*/
- (void)setShadowStyle:(unsigned)aStyle
{
    _shadowStyle = aStyle;

    [[self platformWindow] setShadowStyle:_shadowStyle];
}

/*!
    Sets the delegate for the window. Passing \c nil will just remove the window's current delegate.
    @param aDelegate an object to respond to the various delegate methods of CPWindow
*/
- (void)setDelegate:(id)aDelegate
{
    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter removeObserver:_delegate name:CPWindowDidResignKeyNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidBecomeKeyNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidBecomeMainNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidResignMainNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidMoveNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidResizeNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowWillBeginSheetNotification object:self];
    [defaultCenter removeObserver:_delegate name:CPWindowDidEndSheetNotification object:self];

    _delegate = aDelegate;
    _delegateRespondsToWindowWillReturnUndoManagerSelector = [_delegate respondsToSelector:@selector(windowWillReturnUndoManager:)];

    if ([_delegate respondsToSelector:@selector(windowDidResignKey:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidResignKey:)
                   name:CPWindowDidResignKeyNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidBecomeKey:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidBecomeKey:)
                   name:CPWindowDidBecomeKeyNotification
                 object:self];

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

    if ([_delegate respondsToSelector:@selector(windowDidMove:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidMove:)
                   name:CPWindowDidMoveNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidResize:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidResize:)
                   name:CPWindowDidResizeNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowWillBeginSheet:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowWillBeginSheet:)
                   name:CPWindowWillBeginSheetNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidEndSheet:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidEndSheet:)
                   name:CPWindowDidEndSheetNotification
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
    return NO;
}

- (CPView)initialFirstResponder
{
    return _initialFirstResponder;
}

- (void)setInitialFirstResponder:(CPView)aView
{
    // Before an initial first responder is set, be sure to calculate the key loop
    [self _setupFirstResponder:aView];

    _initialFirstResponder = aView;
}

- (void)_setupFirstResponder:(CPView)anInitialFirstResponder
{
    /*
        If:

        - The key loop is dirty
        - The key loop does not auto-recalculate
        - No view within the window has become first responder
        - No initial first responder has been set

        Then calculate the key view loop and set the first responder
        to the first view in the loop if no initial responder has been set, since we should
        always have an initial first responder and a key loop by default.
    */
    if (_keyViewLoopIsDirty &&
        !_autorecalculatesKeyViewLoop &&
        _firstResponder === self &&
        _initialFirstResponder === [self contentView])
    {
        [self recalculateKeyViewLoop];

        if (anInitialFirstResponder)
            [self makeFirstResponder:anInitialFirstResponder];
        else
        {
            // Make the first key view of the content view the first responder
            var firstKeyView = [[self contentView] nextValidKeyView];

            [self makeFirstResponder:firstKeyView];
        }
    }
}

/*!
    Attempts to make the \c aResponder the first responder. Before trying
    to make it the first responder, the receiver will ask the current first responder
    to resign its first responder status. If it resigns, it will ask
    \c aResponder accept first responder, then finally tell it to become first responder.
    @return \c YES if the attempt was successful. \c NO otherwise.
*/
- (BOOL)makeFirstResponder:(CPResponder)aResponder
{
    if (_firstResponder === aResponder)
        return YES;

    if (![_firstResponder resignFirstResponder])
        return NO;

    if (!aResponder || ![aResponder acceptsFirstResponder] || ![aResponder becomeFirstResponder])
    {
        _firstResponder = self;

        return NO;
    }

    _firstResponder = aResponder;

    [[CPNotificationCenter defaultCenter] postNotificationName:_CPWindowDidChangeFirstResponderNotification object:self];

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
    [_platformWindow _setTitle:_title window:self];

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

- (CPScreen)screen
{
    return [[CPScreen alloc] init];
}

// Moving

/*!
    Sets whether the window can be moved by dragging its background. The default is based on the window style.
    @param shouldBeMovableByWindowBackground \c YES makes the window move from a background drag.
*/
- (void)setMovableByWindowBackground:(BOOL)shouldBeMovableByWindowBackground
{
    _isMovableByWindowBackground = shouldBeMovableByWindowBackground;
}

/*!
    Returns \c YES if the window can be moved by dragging its background.
*/
- (BOOL)isMovableByWindowBackground
{
    return _isMovableByWindowBackground;
}

/*!
    Sets whether the window can be moved.
    @param shouldBeMovable \c YES makes the window movable.
*/
- (void)setMovable:(BOOL)shouldBeMovable
{
    _isMovable = shouldBeMovable;
}

/*!
    Returns \c YES if the window can be moved.
*/
- (void)isMovable
{
    return _isMovable;
}

/*!
    Sets the window location to be the center of the screen
*/
- (void)center
{
    if (_isFullPlatformWindow)
        return;

    var size = [self frame].size,
        containerSize = [CPPlatform isBrowser] ? [_platformWindow contentBounds].size : [[self screen] visibleFrame].size;

    var origin = CGPointMake((containerSize.width - size.width) / 2.0, (containerSize.height - size.height) / 2.0);

    if (origin.x < 0.0)
        origin.x = 0.0;

    if (origin.y < 0.0)
        origin.y = 0.0;

    [self setFrameOrigin:origin];
}

/*!
    Dispatches events that are sent to it from CPApplication.
    @param anEvent the event to be dispatched
*/
- (void)sendEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        point = [anEvent locationInWindow];

    // If a sheet is attached events get filtered here.
    // It is not clear what events should be passed to the view, perhaps all?
    // CPLeftMouseDown is needed for window moving and resizing to work.
    // CPMouseMoved is needed for rollover effects on title bar buttons.
    var sheet = [self attachedSheet];
    if (sheet)
    {
        switch (type)
        {
            case CPLeftMouseDown:
                [_windowView mouseDown:anEvent];

                // -dw- if the window is clicked, the sheet should come to front, and become key,
                // and the window should be immediately behind
                [sheet makeKeyAndOrderFront:self];
                break;
            case CPMouseMoved:
                [_windowView mouseMoved:anEvent];
                break;
        }

        return;
    }

    switch (type)
    {
        case CPFlagsChanged:        return [[self firstResponder] flagsChanged:anEvent];

        case CPKeyUp:               return [[self firstResponder] keyUp:anEvent];

        case CPKeyDown:             if ([anEvent charactersIgnoringModifiers] === CPTabCharacter)
                                    {
                                        if ([anEvent modifierFlags] & CPShiftKeyMask)
                                            [self selectPreviousKeyView:self];
                                        else
                                            [self selectNextKeyView:self];
#if PLATFORM(DOM)
                                        // Make sure the browser doesn't try to do its own tab handling.
                                        // This is important or the browser might blur the shared text field or token field input field,
                                        // even that we just moved it to a new first responder.
                                        [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO]
#endif
                                        return;
                                    }
                                    else if ([anEvent charactersIgnoringModifiers] === CPBackTabCharacter)
                                    {
                                        var didTabBack = [self selectPreviousKeyView:self];
                                        if (didTabBack)
                                        {
#if PLATFORM(DOM)
                                            // Make sure the browser doesn't try to do its own tab handling.
                                            // This is important or the browser might blur the shared text field or token field input field,
                                            // even that we just moved it to a new first responder.
                                            [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO]
#endif
                                        }

                                        return didTabBack;
                                    }

                                    [[self firstResponder] keyDown:anEvent];

                                    // Trigger the default button if needed
                                    // FIXME: Is this only applicable in a sheet? See isse: #722.
                                    if (![self disableKeyEquivalentForDefaultButton])
                                    {
                                        var defaultButton = [self defaultButton],
                                            keyEquivalent = [defaultButton keyEquivalent],
                                            modifierMask = [defaultButton keyEquivalentModifierMask];

                                        if ([anEvent _triggersKeyEquivalent:keyEquivalent withModifierMask:modifierMask])
                                            [[self defaultButton] performClick:self];
                                    }

                                    return;

        case CPScrollWheel:         return [[_windowView hitTest:point] scrollWheel:anEvent];

        case CPLeftMouseUp:
        case CPRightMouseUp:        var hitTestedView = _leftMouseDownView,
                                        selector = type == CPRightMouseUp ? @selector(rightMouseUp:) : @selector(mouseUp:);

                                    if (!hitTestedView)
                                        hitTestedView = [_windowView hitTest:point];

                                    [hitTestedView performSelector:selector withObject:anEvent];

                                    _leftMouseDownView = nil;

                                    return;
        case CPLeftMouseDown:
        case CPRightMouseDown:      _leftMouseDownView = [_windowView hitTest:point];

                                    if (_leftMouseDownView != _firstResponder && [_leftMouseDownView acceptsFirstResponder])
                                        [self makeFirstResponder:_leftMouseDownView];

                                    [CPApp activateIgnoringOtherApps:YES];

                                    var theWindow = [anEvent window],
                                        selector = type == CPRightMouseDown ? @selector(rightMouseDown:) : @selector(mouseDown:);

                                    if ([theWindow isKeyWindow] || [theWindow becomesKeyOnlyIfNeeded] && ![_leftMouseDownView needsPanelToBecomeKey])
                                        return [_leftMouseDownView performSelector:selector withObject:anEvent];
                                    else
                                    {
                                        // FIXME: delayed ordering?
                                        [self makeKeyAndOrderFront:self];

                                        if ([_leftMouseDownView acceptsFirstMouse:anEvent])
                                            return [_leftMouseDownView performSelector:selector withObject:anEvent];
                                    }
                                    break;

        case CPLeftMouseDragged:
        case CPRightMouseDragged:   if (!_leftMouseDownView)
                                        return [[_windowView hitTest:point] mouseDragged:anEvent];

                                    var selector;
                                    if (type == CPRightMouseDragged)
                                    {
                                        selector = @selector(rightMouseDragged:)
                                        if (![_leftMouseDownView respondsToSelector:selector])
                                            selector = nil;
                                    }

                                    if (!selector)
                                        selector = @selector(mouseDragged:)

                                    return [_leftMouseDownView performSelector:selector withObject:anEvent];

        case CPMouseMoved:          if (!_acceptsMouseMovedEvents)
                                        return;

                                    if (!_mouseEnteredStack)
                                        _mouseEnteredStack = [];

                                    var hitTestView = [_windowView hitTest:point];

                                    if ([_mouseEnteredStack count] && [_mouseEnteredStack lastObject] === hitTestView)
                                        return [hitTestView mouseMoved:anEvent];

                                    var view = hitTestView,
                                        mouseEnteredStack = [];

                                    while (view)
                                    {
                                        mouseEnteredStack.unshift(view);

                                        view = [view superview];
                                    }

                                    var deviation = MIN(_mouseEnteredStack.length, mouseEnteredStack.length);

                                    while (deviation--)
                                        if (_mouseEnteredStack[deviation] === mouseEnteredStack[deviation])
                                            break;

                                    var index = deviation + 1,
                                        count = _mouseEnteredStack.length;

                                    if (index < count)
                                    {
                                        var event = [CPEvent mouseEventWithType:CPMouseExited location:point modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0];

                                        for (; index < count; ++index)
                                            [_mouseEnteredStack[index] mouseExited:event];
                                    }

                                    index = deviation + 1;
                                    count = mouseEnteredStack.length;

                                    if (index < count)
                                    {
                                        var event = [CPEvent mouseEventWithType:CPMouseEntered location:point modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0];

                                        for (; index < count; ++index)
                                            [mouseEnteredStack[index] mouseEntered:event];
                                    }

                                    _mouseEnteredStack = mouseEnteredStack;

                                    [hitTestView mouseMoved:anEvent];
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
    the \c -becomeKeyWindow message to the first responder.
*/
- (void)becomeKeyWindow
{
    CPApp._keyWindow = self;

    if (_firstResponder !== self && [_firstResponder respondsToSelector:@selector(becomeKeyWindow)])
        [_firstResponder becomeKeyWindow];

    [self _setupFirstResponder:nil];

    [_windowView noteKeyWindowStateChanged];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidBecomeKeyNotification
                      object:self];
}

/*!
    Determines if the window can become the key window.
    @return \c YES means the window can become the key window.
*/
- (BOOL)canBecomeKeyWindow
{
    // In Cocoa only resizable or titled windows return YES here by default. But the main browser window in Cappuccino
    // doesn't have these masks even that it's both titled and resizable, so we return YES when isFullPlatformWindow too.
    return (_styleMask & CPResizableWindowMask) || (_styleMask & CPResizableWindowMask) || [self isFullPlatformWindow];
}

/*!
    Returns \c YES if the window is the key window.
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
    if ([CPApp keyWindow] === self || ![self canBecomeKeyWindow])
        return;

    [[CPApp keyWindow] resignKeyWindow];
    [self becomeKeyWindow];
}

/*!
    Causes the window to resign it's key window status.
*/
- (void)resignKeyWindow
{
    if (_firstResponder !== self && [_firstResponder respondsToSelector:@selector(resignKeyWindow)])
        [_firstResponder resignKeyWindow];

    if (CPApp._keyWindow === self)
        CPApp._keyWindow = nil;

    [_windowView noteKeyWindowStateChanged];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPWindowDidResignKeyNotification
                      object:self];
}

/*!
    Initiates a drag operation from the receiver to another view that accepts dragged data.
    @param anImage the image to be dragged
    @param aLocation the lower-left corner coordinate of \c anImage
    @param mouseOffset the distance from the \c -mouseDown: location and the current location
    @param anEvent the \c -mouseDown: that triggered the drag
    @param aPasteboard the pasteboard that holds the drag data
    @param aSourceObject the drag operation controller
    @param slideBack Whether the image should 'slide back' if the drag is rejected
*/
- (void)dragImage:(CPImage)anImage at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragImage:anImage fromWindow:self at:[self convertBaseToGlobal:imageLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

- (void)_noteRegisteredDraggedTypes:(CPSet)pasteboardTypes
{
    if (!pasteboardTypes)
        return;

    if (!_inclusiveRegisteredDraggedTypes)
        _inclusiveRegisteredDraggedTypes = [CPCountedSet set];

    [_inclusiveRegisteredDraggedTypes unionSet:pasteboardTypes];
}

- (void)_noteUnregisteredDraggedTypes:(CPSet)pasteboardTypes
{
    if (!pasteboardTypes)
        return;

    [_inclusiveRegisteredDraggedTypes minusSet:pasteboardTypes];

    if ([_inclusiveRegisteredDraggedTypes count] === 0)
        _inclusiveRegisteredDraggedTypes = nil;
}

/*!
    Initiates a drag operation from the receiver to another view that accepts dragged data.
    @param aView the view to be dragged
    @param aLocation the lower-left corner coordinate of \c aView
    @param mouseOffset the distance from the \c -mouseDown: location and the current location
    @param anEvent the \c -mouseDown: that triggered the drag
    @param aPasteboard the pasteboard that holds the drag data
    @param aSourceObject the drag operation controller
    @param slideBack Whether the view should 'slide back' if the drag is rejected
*/
- (void)dragView:(CPView)aView at:(CGPoint)viewLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    [[CPDragServer sharedDragServer] dragView:aView fromWindow:self at:[self convertBaseToGlobal:viewLocation] offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

/*!
    Sets the receiver's list of acceptable data types for a dragging operation.
    @param pasteboardTypes an array of CPPasteboards
*/
- (void)registerForDraggedTypes:(CPArray)pasteboardTypes
{
    if (!pasteboardTypes)
        return;

    [self _noteUnregisteredDraggedTypes:_registeredDraggedTypes];
    [_registeredDraggedTypes addObjectsFromArray:pasteboardTypes];
    [self _noteRegisteredDraggedTypes:_registeredDraggedTypes];

    _registeredDraggedTypesArray = nil;
}

/*!
    Returns an array of all types the receiver accepts for dragging operations.
    @return an array of CPPasteBoards
*/
- (CPArray)registeredDraggedTypes
{
    if (!_registeredDraggedTypesArray)
        _registeredDraggedTypesArray = [_registeredDraggedTypes allObjects];

    return _registeredDraggedTypesArray;
}

/*!
    Resets the array of acceptable data types for a dragging operation.
*/
- (void)unregisterDraggedTypes
{
    [self _noteUnregisteredDraggedTypes:_registeredDraggedTypes];

    _registeredDraggedTypes = [CPSet set];
    _registeredDraggedTypesArray = [];
}

// Accessing Editing Status

/*!
    Sets whether the document has been edited.
    @param isDocumentEdited \c YES if the document has been edited.
*/
- (void)setDocumentEdited:(BOOL)isDocumentEdited
{
    if (_isDocumentEdited == isDocumentEdited)
        return;

    _isDocumentEdited = isDocumentEdited;

    [CPMenu _setMenuBarIconImageAlphaValue:_isDocumentEdited ? 0.5 : 1.0];

    [_windowView setDocumentEdited:isDocumentEdited];
}

/*!
    Returns \c YES if the document has been edited.
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

// Minimizing Windows

/*!
    Simulates the user minimizing the window, then minimizes the window.
    @param aSender the object making this request
*/
- (void)performMiniaturize:(id)aSender
{
    //FIXME show stuff
    [self miniaturize:aSender];
}

/*!
    Minimizes the window. Posts a \c CPWindowWillMiniaturizeNotification to the
    notification center before minimizing the window.
*/
- (void)miniaturize:(id)sender
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillMiniaturizeNotification object:self];

    [[self platformWindow] miniaturize:sender];

    [self _updateMainAndKeyWindows];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidMiniaturizeNotification object:self];

    _isMiniaturized = YES;
}

/*!
    Restores a minimized window to it's original size.
*/
- (void)deminiaturize:(id)sender
{
    [[self platformWindow] deminiaturize:sender];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidDeminiaturizeNotification object:self];

    _isMiniaturized = NO;
}

/*!
    Returns YES if the window is minimized.
*/
- (void)isMiniaturized
{
    return _isMiniaturized;
}

// Closing Windows

/*!
    Simulates the user closing the window, then closes the window.
    @param aSender the object making this request
*/
- (void)performClose:(id)aSender
{
    if (!(_styleMask & CPClosableWindowMask))
        return;

    if ([self isFullBridge])
    {
        var event = [CPApp currentEvent];

        if ([event type] === CPKeyDown && [event characters] === "w" && ([event modifierFlags] & CPPlatformActionKeyMask))
        {
            [[self platformWindow] _propagateCurrentDOMEvent:YES];
            return;
        }
    }

    // Only send ONE windowShouldClose: message.
    if ([_delegate respondsToSelector:@selector(windowShouldClose:)])
    {
        if (![_delegate windowShouldClose:self])
            return;
    }

    // Only check self is delegate does NOT implement this.  This also ensures this when delegate == self (returns true).
    else if ([self respondsToSelector:@selector(windowShouldClose:)] && ![self windowShouldClose:self])
        return;

    var documents = [_windowController documents];
    if ([documents count])
    {
        var index = [documents indexOfObject:[_windowController document]];

        [documents[index] shouldCloseWindowController:_windowController
                                             delegate:self
                                  shouldCloseSelector:@selector(_windowControllerContainingDocument:shouldClose:contextInfo:)
                                          contextInfo:{documents:[documents copy], visited:0, index:index}];
    }
    else
        [self close];
}

- (void)_windowControllerContainingDocument:(CPDocument)document shouldClose:(BOOL)shouldClose contextInfo:(Object)context
{
    if (shouldClose)
    {
        var windowController = [self windowController],
            documents = context.documents,
            count = [documents count],
            visited = ++context.visited,
            index = ++context.index % count;

        [document removeWindowController:windowController];

        if (visited < count)
        {
            [windowController setDocument:documents[index]];

            [documents[index] shouldCloseWindowController:_windowController
                                                 delegate:self
                                      shouldCloseSelector:@selector(_windowControllerContainingDocument:shouldClose:contextInfo:)
                                              contextInfo:context];
        }
        else
            [self close];
    }
}

/*!
    Closes the window. Posts a \c CPWindowWillCloseNotification to the
    notification center before closing the window.
*/
- (void)close
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillCloseNotification object:self];

    [self orderOut:nil];
}

// Managing Main Status
/*!
    Returns \c YES if this the main window.
*/
- (BOOL)isMainWindow
{
    return [CPApp mainWindow] === self;
}

/*!
    Returns \c YES if the window can become the main window.
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
    if ([CPApp mainWindow] === self || ![self canBecomeMainWindow])
        return;

    [[CPApp mainWindow] resignMainWindow];
    [self becomeMainWindow];
}

/*!
    Called to tell the receiver that it has become the main window.
*/
- (void)becomeMainWindow
{
    CPApp._mainWindow = self;

    [self _synchronizeMenuBarTitleWithWindowTitle];
    [self _synchronizeSaveMenuWithDocumentSaving];

    [_windowView noteMainWindowStateChanged];

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

    if (CPApp._mainWindow === self)
        CPApp._mainWindow = nil;

    [_windowView noteMainWindowStateChanged];
}

- (void)_updateMainAndKeyWindows
{
    var allWindows = [CPApp orderedWindows],
        windowCount = [allWindows count];

    if ([self isKeyWindow])
    {
        var keyWindow = [CPApp keyWindow];
        [self resignKeyWindow];

        if (keyWindow && keyWindow !== self && [keyWindow canBecomeKeyWindow])
            [keyWindow makeKeyWindow];
        else
        {
            var mainMenu = [CPApp mainMenu],
                menuBarClass = objj_getClass("_CPMenuBarWindow"),
                menuWindow;

            for (var i = 0; i < windowCount; i++)
            {
                var currentWindow = allWindows[i];

                if ([currentWindow isKindOfClass:menuBarClass])
                    menuWindow = currentWindow;

                if (currentWindow === self || currentWindow === menuWindow)
                    continue;

                if ([currentWindow isVisible] && [currentWindow canBecomeKeyWindow])
                {
                    [currentWindow makeKeyWindow];
                    break;
                }
            }

            if (![CPApp keyWindow])
                [menuWindow makeKeyWindow];
        }
    }

    if ([self isMainWindow])
    {
        var mainWindow = [CPApp mainWindow];
        [self resignMainWindow];

        if (mainWindow && mainWindow !== self && [mainWindow canBecomeMainWindow])
            [mainWindow makeMainWindow];
        else
        {
            var mainMenu = [CPApp mainMenu],
                menuBarClass = objj_getClass("_CPMenuBarWindow"),
                menuWindow;

            for (var i = 0; i < windowCount; i++)
            {
                var currentWindow = allWindows[i];

                if ([currentWindow isKindOfClass:menuBarClass])
                    menuWindow = currentWindow;

                if (currentWindow === self || currentWindow === menuWindow)
                    continue;

                if ([currentWindow isVisible] && [currentWindow canBecomeMainWindow])
                {
                    [currentWindow makeMainWindow];
                    break;
                }
            }
        }
    }
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
    var frame = CGRectMakeCopy([self frame]),
        newFrame;

    [_windowView noteToolbarChanged];

    if (_isFullPlatformWindow)
        newFrame = [_platformWindow visibleFrame];
    else
    {
        newFrame = CGRectMakeCopy([self frame]);

        newFrame.origin = frame.origin;
    }

    [self setFrame:newFrame];
    /*
    [_windowView setAnimatingToolbar:YES];
    [self setFrame:frame];
    [self setFrame:newFrame display:YES animate:YES];
    [_windowView setAnimatingToolbar:NO];
    */
}

- (void)_setFrame:(CGRect)aFrame delegate:(id)delegate duration:(int)duration curve:(CPAnimationCurve)curve
{
    [_frameAnimation stopAnimation];
    _frameAnimation = [[_CPWindowFrameAnimation alloc] initWithWindow:self targetFrame:aFrame];
    [_frameAnimation setDelegate:delegate];
    [_frameAnimation setAnimationCurve:curve];
    [_frameAnimation setDuration:duration];
    [_frameAnimation startAnimation];
}

- (CPTimeInterval)animationResizeTime:(CGRect)newWindowFrame
{
    return CPWindowResizeTime;
}

/* @ignore */
- (void)_setAttachedSheetFrameOrigin
{
    // Position the sheet above the contentRect.
    var attachedSheet = [self attachedSheet];
    var contentRect = [[self contentView] frame],
        sheetFrame = CGRectMakeCopy([attachedSheet frame]);

    sheetFrame.origin.y = CGRectGetMinY(_frame) + CGRectGetMinY(contentRect);
    sheetFrame.origin.x = CGRectGetMinX(_frame) + FLOOR((CGRectGetWidth(_frame) - CGRectGetWidth(sheetFrame)) / 2.0);

    [attachedSheet setFrame:sheetFrame display:YES animate:NO];
}

/* @ignore
    Starting point for sheet session, called from CPApplication beginSheet:
*/
- (void)_attachSheet:(CPWindow)aSheet modalDelegate:(id)aModalDelegate
        didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    if (_sheetContext)
    {
        [CPException raise:CPInternalInconsistencyException
            reason:@"The target window of beginSheet: already has a sheet, did you forget orderOut: ?"];
        return;
    }

    var sheetFrame = [aSheet frame];

    _sheetContext = {"sheet": aSheet, "modalDelegate": aModalDelegate, "endSelector": aDidEndSelector,
        "contextInfo": aContextInfo, "frame": _CGRectMakeCopy(sheetFrame), "returnCode": -1,
        "opened": NO};

    [self _attachSheetWindow];
}

/* @ignore
    Called to animate the sheet in. The timer seems to solve a bug where sheets would
    be partially animated under certain conditions.
*/
- (void)_attachSheetWindow
{
    _sheetContext["isAttached"] = YES;

    // it would be ideal to block here and spin an event loop, until attach is complete
    [CPTimer scheduledTimerWithTimeInterval:0.0
        target:self
        selector:@selector(_sheetShouldAnimateIn:)
        userInfo:nil
        repeats:NO];
}

/* @ignore
    Called to end the sheet. Note that orderOut: is needed to animate the sheet out, as in Cocoa.
    The sheet isn't completely gone until _cleanupSheetWindow gets called.
*/
- (void)_endSheet
{
    var delegate = _sheetContext["modalDelegate"],
        endSelector = _sheetContext["endSelector"];

    // If the sheet has been ordered out, defer didEndSelector until after sheet animates out.
    // This must be done since we cannot block and wait for the animation to complete.
    if (delegate && endSelector)
    {
        if (_sheetContext["isAttached"])
            objj_msgSend(delegate, endSelector, _sheetContext["sheet"], _sheetContext["returnCode"],
                _sheetContext["contextInfo"]);
        else
            _sheetContext["deferDidEndSelector"] = YES;
    }
}

/* @ignore
    Called to animate the sheet out. If called while animating in, schedules an animate
    out at completion
*/
- (void)_detachSheetWindow
{
    _sheetContext["isAttached"] = NO;

    // it would be ideal to block here and spin the event loop, until attach is complete
    [CPTimer scheduledTimerWithTimeInterval:0.0
        target:self
        selector:@selector(_sheetShouldAnimateOut:)
        userInfo:nil
        repeats:NO];
}

/* @ignore
    Called to cleanup sheet, when we are definitely done with it
*/
- (void)_cleanupSheetWindow
{
    var sheet = _sheetContext["sheet"],
        lastFrame = _sheetContext["frame"],
        deferDidEnd = _sheetContext["deferDidEndSelector"];

    [sheet setFrame:lastFrame];
    [self _restoreMasksForView:[sheet contentView]];

    // if the parent window is modal, the sheet started its own modal session
    if (sheet._isModal)
        [CPApp stopModal];

    // restore the state of window before it was sheetified
    [sheet._windowView _enableSheet:NO];

    // close it
    sheet._isSheet = NO;
    [sheet orderOut:self];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidEndSheetNotification object:self];

    if (deferDidEnd)
    {
        var delegate = _sheetContext["modalDelegate"],
            selector = _sheetContext["endSelector"],
            returnCode = _sheetContext["returnCode"],
            contextInfo = _sheetContext["contextInfo"];

        // context must be destroyed, since didEnd might want to attach another sheet
        _sheetContext = nil;
        sheet._parentView = nil;

        objj_msgSend(delegate, selector, sheet, returnCode, contextInfo);
    }
    else
    {
        _sheetContext = nil;
        sheet._parentView = nil;
    }
}

/* @ignore */
- (void)animationDidEnd:(id)anim
{
    var sheet = _sheetContext["sheet"];
    if (anim._window != sheet)
        return;

    [CPTimer scheduledTimerWithTimeInterval:0.0
        target:self
        selector:@selector(_sheetAnimationDidEnd:)
        userInfo:nil
        repeats:NO];
}

/* @ignore */
- (void)_sheetShouldAnimateIn:(CPTimer)timer
{
    // can't open sheet while opening or closing animation is going on
    if (_sheetContext["isOpening"] ||
        _sheetContext["isClosing"])
        return;

    var sheet = _sheetContext["sheet"],
        sheetFrame = [sheet frame],
        frame = [self frame];

    [self _setUpMasksForView:[sheet contentView]];

    sheet._isSheet = YES;
    sheet._parentView = self;

    var originx = frame.origin.x + FLOOR((frame.size.width - sheetFrame.size.width) / 2),
        originy = frame.origin.y + [[self contentView] frame].origin.y,
        startFrame = CGRectMake(originx, originy, sheetFrame.size.width, 0),
        endFrame = CGRectMake(originx, originy, sheetFrame.size.width, sheetFrame.size.height);

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillBeginSheetNotification object:self];

    // if sheet is attached to a modal window, the sheet runs
    // as if itself and the parent window are modal
    sheet._isModal = NO;
    if ([CPApp modalWindow] === self)
    {
        [CPApp runModalForWindow:sheet];
        sheet._isModal = YES;
    }

    [sheet orderFront:self];
    [sheet setFrame:startFrame display:YES animate:NO];

    _sheetContext["opened"] = YES;
    _sheetContext["shouldClose"] = NO;
    _sheetContext["isOpening"] = YES;

    [sheet _setFrame:endFrame delegate:self duration:[self animationResizeTime:endFrame] curve:CPAnimationEaseOut];

    // NOTE: cocoa doesn't make window key until animation is done, but a
    // keypress while animating eventually gets to the window. Therefore,
    // there must be a runloop specifically designed for sheets?
    [sheet makeKeyWindow];
}

/* @ignore */
- (void)_sheetShouldAnimateOut:(CPTimer)timer
{
    var sheet = _sheetContext["sheet"],
        startFrame = [sheet frame],
        endFrame = CGRectMakeCopy(startFrame);

    if (_sheetContext["isOpening"])
    {
        // allow sheet to be closed while opening, it will close when animate in completes
        _sheetContext["shouldClose"] = YES;
        return;
    }

    if (_sheetContext["isClosing"])
        return;

    _sheetContext["opened"] = NO;
    _sheetContext["frame"] = startFrame;
    _sheetContext["isClosing"] = YES;

    // the parent window can be orderedOut to disable the sheet animate out, as in Cocoa
    if ([self isVisible])
    {
        endFrame.size.height = 0;
        [self _setUpMasksForView:[sheet contentView]];
        [sheet _setFrame:endFrame delegate:self duration:[self animationResizeTime:endFrame] curve:CPAnimationEaseIn];
    }
    else
    {
        [self _sheetAnimationDidEnd:nil];
    }
}

/* @ignore */
- (void)_sheetAnimationDidEnd:(CPTimer)timer
{
    var sheet = _sheetContext["sheet"];

    _sheetContext["isOpening"] = NO;
    _sheetContext["isClosing"] = NO;

    if (_sheetContext["opened"] === YES)
    {
        // sheet is open and completely visible
        [self _restoreMasksForView:[sheet contentView]];

        // we wanted to close the sheet while it animated in, do that now
        if (_sheetContext["shouldClose"] === YES)
            [self _detachSheetWindow];
    }
    else
    {
        // sheet is closed and not visible
        [self _cleanupSheetWindow];
    }
}

- (void)_setUpMasksForView:(CPView)aView
{
    var views = [aView subviews];

    [views addObject:aView];

    for (var i = 0, count = [views count]; i < count; i++)
    {
        var view = [views objectAtIndex:i],
            mask = [view autoresizingMask],
            maskToAdd = (mask & CPViewMinYMargin) ? 128 : CPViewMinYMargin;

        [view setAutoresizingMask:(mask | maskToAdd)];
    }
}

- (void)_restoreMasksForView:(CPView)aView
{
    var views = [aView subviews];

    [views addObject:aView];

    for (var i = 0, count = [views count]; i < count; i++)
    {
        var view = [views objectAtIndex:i],
            mask = [view autoresizingMask],
            maskToRemove = (mask & 128) ? 128 : CPViewMinYMargin;

        [view setAutoresizingMask:(mask & (~ maskToRemove))];
    }
}

/*!
    Returns the window's attached sheet.
*/
- (CPWindow)attachedSheet
{
    if (_sheetContext === nil)
        return nil;

   return _sheetContext["sheet"];
}

/*!
    Returns \c YES if the window has ever run as a sheet.
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
    Returns \c YES if the receiver is able to receive input events
    even when a modal session is active.
*/
- (BOOL)worksWhenModal
{
    return NO;
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    // FIXME: should we be starting at the root, in other words _windowView?
    // The evidence seems to point to no...
    return [[self contentView] performKeyEquivalent:anEvent];
}

- (void)keyDown:(CPEvent)anEvent
{
    // It's not clear why we do performKeyEquivalent again here...
    // Perhaps to allow something to happen between sendEvent: and keyDown:?
    if ([anEvent _couldBeKeyEquivalent] && [self performKeyEquivalent:anEvent])
        return;

    // Apple's documentation is inconsistent with their behavior here. According to the docs
    // an event going of the responder chain is passed to the input system as a last resort.
    // However, the only methods I could get Cocoa to call automatically are
    // moveUp: moveDown: moveLeft: moveRight: pageUp: pageDown: and complete:
    // Unhandled events just travel further up the responder chain _past_ the window.
    if (![self _processKeyboardUIKey:anEvent])
        [super keyDown:anEvent];
}

/*
    @ignore
    Interprets the key event for action messages and sends the action message down the responder chain
    Cocoa only sends moveDown:, moveUp:, moveLeft:, moveRight:, pageUp:, pageDown: and complete: messages.
    We deviate from this by sending (the default) scrollPageUp:, scrollPageDown:, scrollToBeginningOfDocument: and scrollToEndOfDocument: for pageUp, pageDown, home and end keys.
    @param anEvent the event to handle.
    @return YES if the key event was handled, NO if no responder handled the key event
*/
- (BOOL)_processKeyboardUIKey:(CPEvent)anEvent
{
    var character = [anEvent charactersIgnoringModifiers];

    if (![CPWindowActionMessageKeys containsObject:character])
        return NO;

    var selectors = [CPKeyBinding selectorsForKey:character modifierFlags:0];

    if ([selectors count] <= 0)
        return NO;

    if (character !== CPEscapeFunctionKey)
    {
        var selector = [selectors objectAtIndex:0];
        return [[self firstResponder] tryToPerform:selector with:self];
    }
    else
    {
        // Cocoa sends complete: for the escape key (in stead of the default cancelOperation:)
        // This is also the only action that is not sent directly to the first responder, but through doCommandBySelector.
        // The difference is that doCommandBySelector: will also send the action to the window and application delegates.
        [[self firstResponder] doCommandBySelector:@selector(complete:)];
    }

    return NO;
}

- (void)_dirtyKeyViewLoop
{
    if (_autorecalculatesKeyViewLoop)
        _keyViewLoopIsDirty = YES;
}

- (BOOL)_hasKeyViewLoop
{
    var views = allViews(self),
        index = [views count];

    while (index--)
        if ([views[index] nextKeyView])
            return YES;

    return NO;
}

- (void)recalculateKeyViewLoop
{
    var views = allViews(self);

    [views sortUsingFunction:keyViewComparator context:nil];

    for (var index = 0, count = [views count]; index < count; ++index)
        [views[index] setNextKeyView:views[(index + 1) % count]];

    _keyViewLoopIsDirty = NO;
}

- (void)setAutorecalculatesKeyViewLoop:(BOOL)shouldRecalculate
{
    if (_autorecalculatesKeyViewLoop === shouldRecalculate)
        return;

    _autorecalculatesKeyViewLoop = shouldRecalculate;

    if (_autorecalculatesKeyViewLoop)
        [self _dirtyKeyViewLoop];
}

- (BOOL)autorecalculatesKeyViewLoop
{
    return _autorecalculatesKeyViewLoop;
}

- (void)selectNextKeyView:(id)sender
{
    if (_keyViewLoopIsDirty && [self autorecalculatesKeyViewLoop])
        [self recalculateKeyViewLoop];

    var nextValidKeyView = nil;

    if ([_firstResponder isKindOfClass:[CPView class]])
        nextValidKeyView = [_firstResponder nextValidKeyView];

    if (!nextValidKeyView)
    {
        var initialFirstResponder = _initialFirstResponder;

        if ([initialFirstResponder acceptsFirstResponder])
            nextValidKeyView = initialFirstResponder;
        else
            nextValidKeyView = [initialFirstResponder nextValidKeyView];
    }

    [self makeFirstResponder:nextValidKeyView];
}

- (void)selectPreviousKeyView:(id)sender
{
    if (_keyViewLoopIsDirty && [self autorecalculatesKeyViewLoop])
        [self recalculateKeyViewLoop];

    var previousValidKeyView = nil;

    if ([_firstResponder isKindOfClass:[CPView class]])
        previousValidKeyView = [_firstResponder previousValidKeyView];

    if (!previousValidKeyView)
    {
        var initialFirstResponder = _initialFirstResponder;

        if ([initialFirstResponder acceptsFirstResponder])
            previousValidKeyView = initialFirstResponder;
        else
            previousValidKeyView = [initialFirstResponder previousValidKeyView];
    }

    [self makeFirstResponder:previousValidKeyView];
}

- (void)selectKeyViewFollowingView:(CPView)aView
{
    if (_keyViewLoopIsDirty && [self autorecalculatesKeyViewLoop])
        [self recalculateKeyViewLoop];

    var nextValidKeyView = [aView nextValidKeyView];

    if ([nextValidKeyView isKindOfClass:[CPView class]])
        [self makeFirstResponder:nextValidKeyView];
}

- (void)selectKeyViewPrecedingView:(CPView)aView
{
    if (_keyViewLoopIsDirty && [self autorecalculatesKeyViewLoop])
        [self recalculateKeyViewLoop];

    var previousValidKeyView = [aView previousValidKeyView];

    if ([previousValidKeyView isKindOfClass:[CPView class]])
        [self makeFirstResponder:previousValidKeyView];
}

/*!
    Sets the default button for the window.
    Note: this method is deprecated use setDefaultButton: instead.
    @param aButton - The button that should become default.
*/
- (void)setDefaultButtonCell:(CPButton)aButton
{
    [self setDefaultButton:aButton];
}

/*!
    Returns the default button of the receiver.
    NOTE: This method is deprecated. Use defaultButton instead.
*/
- (CPButton)defaultButtonCell
{
    return [self defaultButton];
}

/*!
    Sets the default button for the window.
    This is equivalent to setting the the key equivalent of the button to "return".
    Additionally this will turn your button blue (with the Aristo theme).
    @param aButton - The button that should become default.
*/
- (void)setDefaultButton:(CPButton)aButton
{
    if (_defaultButton === aButton)
        return;

    if ([_defaultButton keyEquivalent] === CPCarriageReturnCharacter)
        [_defaultButton setKeyEquivalent:nil];

    _defaultButton = aButton;

    if ([_defaultButton keyEquivalent] !== CPCarriageReturnCharacter)
        [_defaultButton setKeyEquivalent:CPCarriageReturnCharacter];
}

/*!
    Returns the default button of the receiver.
*/
- (CPButton)defaultButton
{
    return _defaultButton;
}

/*!
    Sets the default button key equivalent to "return".
*/
- (void)enableKeyEquivalentForDefaultButton
{
    _defaultButtonEnabled = YES;
}

/*!
    Sets the default button key equivalent to "return".
    NOTE: this method is deprecated. Use enableKeyEquivalentForDefaultButton instead.
*/
- (void)enableKeyEquivalentForDefaultButtonCell
{
    [self enableKeyEquivalentForDefaultButton];
}

/*!
    Removes the key equivalent for the default button.
*/
- (void)disableKeyEquivalentForDefaultButton
{
    _defaultButtonEnabled = NO;
}

/*!
    Removes the key equivalent for the default button.
    Note: this method is deprecated. Use disableKeyEquivalentForDefaultButton instead.
*/
- (void)disableKeyEquivalentForDefaultButtonCell
{
    [self disableKeyEquivalentForDefaultButton];
}

@end

var allViews = function(aWindow)
{
    var views = [CPArray arrayWithObject:[aWindow contentView]];

    [views addObjectsFromArray:[[aWindow contentView] subviews]];

    // Start from index 1 because index 0 is the contentView and its subviews have already been added
    for (var index = 1; index < views.length; ++index)
        views = views.concat([views[index] subviews]);

    return views;
};

var keyViewComparator = function(lhs, rhs, context)
{
    var lhsBounds = [lhs convertRect:[lhs bounds] toView:nil],
        rhsBounds = [rhs convertRect:[rhs bounds] toView:nil],
        lhsY = _CGRectGetMinY(lhsBounds),
        rhsY = _CGRectGetMinY(rhsBounds),
        lhsX = _CGRectGetMinX(lhsBounds),
        rhsX = _CGRectGetMinX(rhsBounds),
        intersectsVertically = MIN(_CGRectGetMaxY(lhsBounds), _CGRectGetMaxY(rhsBounds)) - MAX(lhsY, rhsY);

    // If two views are "on the same line" (intersect vertically), then rely on the x comparison.
    if (intersectsVertically > 0)
    {
        if (lhsX < rhsX)
            return CPOrderedAscending;

        if (lhsX === rhsX)
            return CPOrderedSame;

        return CPOrderedDescending;
    }

    if (lhsY < rhsY)
        return CPOrderedAscending;

    if (lhsY === rhsY)
        return CPOrderedSame;

    return CPOrderedDescending;
};

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
    @ignore
*/
- (void)resizeWithOldPlatformWindowSize:(CGSize)aSize
{
    if ([self isFullPlatformWindow])
        return [self setFrame:[_platformWindow visibleFrame]];

    if (_autoresizingMask == CPWindowNotSizable)
        return;

    var frame = [_platformWindow contentBounds],
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

/*!
    Converts aPoint from the window coordinate system to the global coordinate system.
*/
- (CGPoint)convertBaseToGlobal:(CGPoint)aPoint
{
    return [CPPlatform isBrowser] ? [self convertBaseToPlatformWindow:aPoint] : [self convertBaseToScreen:aPoint];
}

/*!
    Converts aPoint from the global coordinate system to the window coordinate system.
*/
- (CGPoint)convertGlobalToBase:(CGPoint)aPoint
{
    return [CPPlatform isBrowser] ? [self convertPlatformWindowToBase:aPoint] : [self convertScreenToBase:aPoint];
}

/*!
    Converts aPoint from the window coordinate system to the coordinate system of the parent platform window.
*/
- (CGPoint)convertBaseToPlatformWindow:(CGPoint)aPoint
{
    if ([self _sharesChromeWithPlatformWindow])
        return _CGPointMakeCopy(aPoint);

    var origin = [self frame].origin;

    return _CGPointMake(aPoint.x + origin.x, aPoint.y + origin.y);
}

/*!
    Converts aPoint from the parent platform window coordinate system to the window's coordinate system.
*/
- (CGPoint)convertPlatformWindowToBase:(CGPoint)aPoint
{
    if ([self _sharesChromeWithPlatformWindow])
        return _CGPointMakeCopy(aPoint);

    var origin = [self frame].origin;

    return _CGPointMake(aPoint.x - origin.x, aPoint.y - origin.y);
}

- (CGPoint)convertScreenToBase:(CGPoint)aPoint
{
    return [self convertPlatformWindowToBase:[_platformWindow convertScreenToBase:aPoint]];
}

- (CGPoint)convertBaseToScreen:(CGPoint)aPoint
{
    return [_platformWindow convertBaseToScreen:[self convertBaseToPlatformWindow:aPoint]];
}

- (void)_setSharesChromeWithPlatformWindow:(BOOL)shouldShareFrameWithPlatformWindow
{
    // We canna' do it captain! We just don't have the power!
    if (shouldShareFrameWithPlatformWindow && [CPPlatform isBrowser])
        return;

    _sharesChromeWithPlatformWindow = shouldShareFrameWithPlatformWindow;

    [self _updateShadow];
}

- (BOOL)_sharesChromeWithPlatformWindow
{
    return _sharesChromeWithPlatformWindow;
}

// Undo and Redo Support
/*!
    Returns the window's undo manager.
*/
- (CPUndoManager)undoManager
{
    // If we've ever created an undo manager, return it.
    if (_undoManager)
        return _undoManager;

    // If not, check to see if the document has one.
    var documentUndoManager = [[_windowController document] undoManager];

    if (documentUndoManager)
        return documentUndoManager;

    // If not, check to see if the delegate has one.
    if (_delegateRespondsToWindowWillReturnUndoManagerSelector)
        return [_delegate windowWillReturnUndoManager:self];

    // If not, create one.
    if (!_undoManager)
        _undoManager = [[CPUndoManager alloc] init];

    return _undoManager;
}

/*!
    Sends the undo manager an \c -undo: message.
    @param aSender the object requesting this
*/
- (void)undo:(id)aSender
{
    [[self undoManager] undo];
}

/*!
    Sends the undo manager a \c -redo: message.
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

@implementation CPWindow (Deprecated)
/*!
    Sets the CPWindow to fill the whole browser window.
    NOTE: this method has been deprecated in favor of setFullPlatformWindow:
*/
- (void)setFullBridge:(BOOL)shouldBeFullBridge
{
    [self setFullPlatformWindow:shouldBeFullBridge];
}

/*!
    Returns YES if the window fills the full browser window, otherwise NO.
    NOTE: this method has been deprecated in favor of isFullPlatformWindow.
*/
- (BOOL)isFullBridge
{
    return [self isFullPlatformWindow];
}

/*
    @ignore
*/
- (CGPoint)convertBaseToBridge:(CGPoint)aPoint
{
    return [self convertBaseToPlatformWindow:aPoint];
}

/*
    @ignore
*/
- (CGPoint)convertBridgeToBase:(CGPoint)aPoint
{
    return [self convertPlatformWindowToBase:aPoint];
}

@end

var interpolate = function(fromValue, toValue, progress)
{
    return fromValue + (toValue - fromValue) * progress;
};

/* @ignore */
@implementation _CPWindowFrameAnimation : CPAnimation
{
    CPWindow    _window;

    CGRect      _startFrame;
    CGRect      _targetFrame;
}

- (id)initWithWindow:(CPWindow)aWindow targetFrame:(CGRect)aTargetFrame
{
    self = [super initWithDuration:[aWindow animationResizeTime:aTargetFrame] animationCurve:CPAnimationLinear];

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

    var newFrame = CGRectMake(interpolate(CGRectGetMinX(_startFrame), CGRectGetMinX(_targetFrame), value),
                              interpolate(CGRectGetMinY(_startFrame), CGRectGetMinY(_targetFrame), value),
                              interpolate(CGRectGetWidth(_startFrame), CGRectGetWidth(_targetFrame), value),
                              interpolate(CGRectGetHeight(_startFrame), CGRectGetHeight(_targetFrame), value));

    [_window setFrame:newFrame display:YES animate:NO];
}

@end

function _CPWindowFullPlatformWindowSessionMake(aWindowView, aContentRect, hasShadow, aLevel)
{
    return { windowView:aWindowView, contentRect:aContentRect, hasShadow:hasShadow, level:aLevel };
}

CPStandardWindowShadowStyle = 0;
CPMenuWindowShadowStyle     = 1;
CPPanelWindowShadowStyle    = 2;
CPCustomWindowShadowStyle   = 3;


@import "_CPWindowView.j"
@import "_CPStandardWindowView.j"
@import "_CPDocModalWindowView.j"
@import "_CPToolTipWindowView.j"
@import "_CPHUDWindowView.j"
@import "_CPBorderlessWindowView.j"
@import "_CPBorderlessBridgeWindowView.j"
@import "_CPAttachedWindowView.j"
@import "CPDragServer.j"
@import "CPView.j"
