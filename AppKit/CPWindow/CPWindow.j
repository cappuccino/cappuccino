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
@import "CPCursor.j"
@import "CPDragServer.j"
@import "CPEvent.j"
@import "CPPlatformWindow.j"
#if PLATFORM(BROWSER)
@import "CPPlatformWindow+DOM.j"
#endif
@import "CPResponder.j"
@import "CPScreen.j"
@import "CPText.j"
@import "CPView.j"
@import "CPWindow_Constants.j"
@import "_CPBorderlessBridgeWindowView.j"
@import "_CPBorderlessWindowView.j"
@import "_CPDocModalWindowView.j"
@import "_CPHUDWindowView.j"
@import "_CPModalWindowView.j"
@import "_CPPopoverWindowView.j"
@import "_CPShadowWindowView.j"
@import "_CPStandardWindowView.j"
@import "_CPToolTipWindowView.j"

@class CPMenu
@class CPProgressIndicator

@global CPApp

var CPWindowSaveImage       = nil,

    CPWindowResizeTime      = 0.2,
    CPWindowResizeStyleGlobalChangeNotification = @"CPWindowResizeStyleGlobalChangeNotification",

    CPWindowMinVisibleHorizontalMargin = 40,
    CPWindowMinVisibleVerticalMargin = 2;

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

    @delegate  -(CPUndoManager)windowWillReturnUndoManager:(CPWindow)aWindow;
    Called to obtain the undo manager for a window
    @param aWindow the window for which to return the undo manager
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

    @delegate -(BOOL)windowShouldClose:(id)aWindow;
    Called when the user tries to close the window.
    @param aWindow the window to close
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
    BOOL                                _hasBeenOrderedIn @accessors;
    BOOL                                _isMiniaturized;
    BOOL                                _isAnimating;
    BOOL                                _hasShadow;
    BOOL                                _isMovableByWindowBackground;
    BOOL                                _isMovable;
    BOOL                                _constrainsToUsableScreen;
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
    BOOL                                _hasBecomeKeyWindow;
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

    CPWindow                            _parentWindow;
    CPArray                             _childWindows;
    CPWindowOrderingMode                _childOrdering @accessors(setter=_setChildOrdering);

    CPDictionary                        _sheetContext;
    CPWindow                            _parentView;
    BOOL                                _isSheet;
    _CPWindowFrameAnimation             _frameAnimation;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if ([aBinding hasPrefix:CPDisplayPatternTitleBinding])
        return [CPTitleWithPatternBinding class];

    return [super _binderClassForBinding:aBinding];
}

- (id)init
{
    return [self initWithContentRect:CGRectMakeZero() styleMask:CPTitledWindowMask];
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
        _constrainsToUsableScreen = YES;

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
        _hasBeenOrderedIn = NO;

        _parentWindow = nil;
        _childWindows = [];
        _childOrdering = CPWindowOut;

        _isSheet = NO;
        _sheetContext = nil;
        _parentView = nil;

        // Set up our window number.
        _windowNumber = [CPApp._windows count];
        CPApp._windows[_windowNumber] = self;

        _styleMask = aStyleMask;

        [self setLevel:CPNormalWindowLevel];

        // Create our border view which is the actual root of our view hierarchy.
        _windowView = [[windowViewClass alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame)) styleMask:aStyleMask];

        [_windowView _setWindow:self];
        [_windowView setNextResponder:self];

        // Size calculation needs _windowView
        _minSize = [self _calculateMinSizeForProposedSize:CGSizeMake(0.0, 0.0)];
        _maxSize = CGSizeMake(1000000.0, 1000000.0);

        [self setMovableByWindowBackground:aStyleMask & CPHUDBackgroundWindowMask];

        // Create a generic content view.
        [self setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];

        _firstResponder = self;

#if PLATFORM(DOM)
        _DOMElement = document.createElement("div");

        _DOMElement.style.position = "absolute";
        _DOMElement.style.visibility = "visible";
        _DOMElement.style.zIndex = 0;

        if (![self _sharesChromeWithPlatformWindow])
        {
            CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, CGRectGetMinX(_frame), CGRectGetMinY(_frame));
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
        _keyViewLoopIsDirty = NO;
        _hasBecomeKeyWindow = NO;

        [self setShowsResizeIndicator:_styleMask & CPResizableWindowMask];

        [[CPNotificationCenter defaultCenter] addObserver:self
                                 selector:@selector(_didReceiveResizeStyleChange:)
                                     name:CPWindowResizeStyleGlobalChangeNotification
                                   object:nil];
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

    else if (aStyleMask & _CPModalWindowMask)
        return _CPModalWindowView;

    return _CPStandardWindowView;
}

+ (Class)_windowViewClassForFullPlatformWindowStyleMask:(unsigned)aStyleMask
{
    return _CPBorderlessBridgeWindowView;
}

- (void)awakeFromCib
{
    // At this time we know the final screen (or browser) size
    // and can apply the positioning mask, if any, from the nib.
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

    /*
        Calculate the key view loop if necessary. Note that Cocoa does not call recalculateKeyViewLoop when awaking a nib. If a key view loop was set in the cib, we have to chain it to the content view.
    */
    if ([self _hasKeyViewLoop:[_contentView subviews]])
    {
        var views = [self _viewsSortedByPosition],
            count = [views count];

        // The first view is the content view.
        // Find the first subview that has a next key view.
        for (var i = 1; i < count; ++i)
        {
            var view = views[i];

            if ([view nextKeyView])
            {
                [_contentView setNextKeyView:view];
                break;
            }
        }
    }
    else
    {
        // Cooca does NOT call the public method recalculateKeyViewLoop for nibs,
        // but it does calculate the loop.
        [self _doRecalculateKeyViewLoop];
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
    return CGRectMakeCopy(_frame);
}

/*!
    Sets the frame of the window.

    @param aFrame - A CGRect of the new frame for the receiver.
    @param shouldDisplay - YES if the window should call setNeedsDisplay otherwise NO.
    @param shouldAnimate - YES if the window should animate to it's new size and position, otherwise NO.
*/
- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    [self _setFrame:aFrame display:shouldDisplay animate:shouldAnimate constrainWidth:NO constrainHeight:YES];
}

- (void)_setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate constrainWidth:(BOOL)shouldConstrainWidth constrainHeight:(BOOL)shouldConstrainHeight
{
    var frame = CGRectMakeCopy(aFrame),
        value = frame.origin.x,
        delta = value - FLOOR(value);

    if (delta)
        frame.origin.x = value > 0.879 ? CEIL(value) : FLOOR(value);

    value = frame.origin.y;
    delta = value - FLOOR(value);

    if (delta)
        frame.origin.y = value > 0.879 ? CEIL(value) : FLOOR(value);

    value = frame.size.width;
    delta = value - FLOOR(value);

    if (delta)
        frame.size.width = value > 0.15 ? CEIL(value) : FLOOR(value);

    value = frame.size.height;
    delta = value - FLOOR(value);

    if (delta)
        frame.size.height = value > 0.15 ? CEIL(value) : FLOOR(value);

    frame = [self _constrainFrame:frame toUsableScreenWidth:shouldConstrainWidth andHeight:shouldConstrainHeight];

    if (shouldAnimate)
    {
        [_frameAnimation stopAnimation];
        _frameAnimation = [[_CPWindowFrameAnimation alloc] initWithWindow:self targetFrame:frame];

        [_frameAnimation startAnimation];
    }
    else
    {
        var origin = _frame.origin,
            newOrigin = frame.origin,
            originMoved = !CGPointEqualToPoint(origin, newOrigin);

        if (originMoved)
        {
            delta = CGPointMake(newOrigin.x - origin.x, newOrigin.y - origin.y);
            origin.x = newOrigin.x;
            origin.y = newOrigin.y;

#if PLATFORM(DOM)
            if (![self _sharesChromeWithPlatformWindow])
            {
                CPDOMDisplayServerSetStyleLeftTop(_DOMElement, NULL, origin.x, origin.y);
            }
#endif

            // reposition sheet
            if ([self attachedSheet])
                [self _setAttachedSheetFrameOrigin];

            [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidMoveNotification object:self];
        }

        var size = _frame.size,
            newSize = frame.size;

        if (!CGSizeEqualToSize(size, newSize))
        {
            size.width = newSize.width;
            size.height = newSize.height;

            [_windowView setFrameSize:size];

            if (_hasShadow)
                [_shadowView setNeedsLayout];

            if (!_isAnimating)
                [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidResizeNotification object:self];
        }

        if ([self _sharesChromeWithPlatformWindow])
            [_platformWindow setContentRect:_frame];

        if (originMoved)
            [self _moveChildWindows:delta];
    }
}

- (CGRect)_constrainFrame:(CGRect)aFrame toUsableScreenWidth:(BOOL)constrainWidth andHeight:(BOOL)constrainHeight
{
    var frame = CGRectMakeCopy(aFrame);

    if (!_constrainsToUsableScreen || !_isVisible)
        return frame;

    var usableRect = [_platformWindow usableContentFrame];

    if (constrainWidth)
    {
        // First move the frame right to ensure the left side is within the usable rect.
        frame.origin.x = MAX(frame.origin.x, usableRect.origin.x);

        // Now move the frame left so that the right side is within the usable rect.
        var maxX = MIN(CGRectGetMaxX(frame), CGRectGetMaxX(usableRect));
        frame.origin.x = maxX - frame.size.width;

        // Finally, adjust the left + width to ensure the left side is within the usable rect.
        var usableWidth = CGRectGetWidth(usableRect);

        if (CGRectGetWidth(frame) > usableWidth)
        {
            frame.origin.x = CGRectGetMinX(usableRect);
            frame.size.width = usableWidth;
        }
    }

    if (constrainHeight)
    {
        // First move the frame down to ensure the top is within the usable rect.
        frame.origin.y = MAX(frame.origin.y, usableRect.origin.y);

        // Now move the frame up so that the bottom is within the usable rect.
        var maxY = MIN(CGRectGetMaxY(frame), CGRectGetMaxY(usableRect));
        frame.origin.y = maxY - frame.size.height;

        // Finally, adjust the top + height to ensure the top is within the usable rect.
        var usableHeight = CGRectGetHeight(usableRect);

        if (CGRectGetHeight(frame) > usableHeight)
        {
            frame.origin.y = CGRectGetMinY(usableRect);
            frame.size.height = usableHeight;
        }
    }

    return frame;
}

- (CGRect)_constrainOriginOfFrame:(CGRect)aFrame
{
    var frame = CGRectMakeCopy(aFrame);

    if (!_constrainsToUsableScreen || !_isVisible)
        return frame;

    /*
        - CPWindowMinVisibleHorizontalMargin is kept onscreen at the left/right of the window.
        - The top of the window is kept below the top of the usable content.
        - The top of the contentView + CPWindowMinVisibleVerticalMargin is kept above the bottom of the usable content.
    */
    var usableRect = [_platformWindow usableContentFrame],
        maxUsableY = CGRectGetMaxY(usableRect) - CGRectGetMinY([_contentView frame]) - CPWindowMinVisibleVerticalMargin;

    frame.origin.x = MAX(frame.origin.x, CGRectGetMinX(usableRect) + CPWindowMinVisibleHorizontalMargin - CGRectGetWidth(frame));
    frame.origin.x = MIN(frame.origin.x, CGRectGetMaxX(usableRect) - CPWindowMinVisibleHorizontalMargin);

    frame.origin.y = MAX(frame.origin.y, CGRectGetMinY(usableRect));
    frame.origin.y = MIN(frame.origin.y, maxUsableY);

    return frame;
}

- (void)_moveChildWindows:(CGPoint)delta
{
    [_childWindows enumerateObjectsUsingBlock:function(childWindow)
        {
            var origin = [childWindow frame].origin;

            [childWindow setFrameOrigin:CGPointMake(origin.x + delta.x, origin.y + delta.y)];
        }
    ];
}

/*!
    Sets the window's frame rect.
    @param aFrame - The new CGRect of the window.
    @param shouldDisplay - YES if the window should call setNeedsDisplay: otherwise NO.
*/
- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay
{
    [self setFrame:aFrame display:shouldDisplay animate:NO];
}

/*!
    Sets the window's frame rectangle
    @param aFrame - The CGRect of the windows new frame
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
    var frame = [self _constrainOriginOfFrame:CGRectMake(anOrigin.x, anOrigin.y, _frame.size.width, _frame.size.height)];
    [self _setFrame:frame display:YES animate:NO constrainWidth:NO constrainHeight:NO];
}

/*!
    Sets the window's size.
    @param aSize the new size for the window
*/
- (void)setFrameSize:(CGSize)aSize
{
    [self setFrame:CGRectMake(CGRectGetMinX(_frame), CGRectGetMinY(_frame), aSize.width, aSize.height) display:YES animate:NO];
}

/*!
    Makes the receiver the front most window in the screen ordering.
    @param aSender the object that requested this
*/
- (void)orderFront:(id)aSender
{
    [self orderWindow:CPWindowAbove relativeTo:0];
}

- (void)_orderFront
{
#if PLATFORM(DOM)
    // -dw- if a sheet is clicked, the parent window should come up too
    if (_isSheet)
        [_parentView orderFront:self];

    if (!_isVisible)
        [self _setFrame:_frame display:YES animate:NO constrainWidth:YES constrainHeight:YES];

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
    Called when a parent window orders in a child window directly.
    without going through the ordering methods in CPWindow.
*/
- (void)_parentDidOrderInChild
{
}

/*
    Makes the receiver the last window in the screen ordering.
    @param aSender the object that requested this
    @ignore
*/
- (void)orderBack:(id)aSender
{
    [self orderWindow:CPWindowBelow relativeTo:0];
}

- (void)_orderBack
{
    // FIXME: Implement this
}

/*!
    Hides the window.
    @param the object that requested this
*/
- (void)orderOut:(id)aSender
{
    [self orderWindow:CPWindowOut relativeTo:0];
}

- (void)_orderOutRecursively:(BOOL)recursive
{
    if (!_isVisible)
        return;

    if ([self isSheet])
    {
        // -dw- as in Cocoa, orderOut: detaches the sheet and animates out
        [self._parentView _detachSheetWindow];
        return;
    }

    if (recursive)
        [_childWindows makeObjectsPerformSelector:@selector(_orderOutRecursively:) withObject:recursive];

#if PLATFORM(DOM)
    if ([self _sharesChromeWithPlatformWindow])
        [_platformWindow orderOut:self];

    [_platformWindow order:CPWindowOut window:self relativeTo:nil];
#endif

    [self _updateMainAndKeyWindows];
}

/*!
    Relocates the window in the screen list.
    @param orderingMode the positioning relative to \c otherWindowNumber
    @param otherWindowNumber the window relative to which the receiver should be placed
*/
- (void)orderWindow:(CPWindowOrderingMode)orderingMode relativeTo:(int)otherWindowNumber
{
    if (orderingMode === CPWindowOut)
    {
        // Directly ordering out will detach a child window
        [_parentWindow removeChildWindow:self];

        // In Cocoa, a window orders out its child windows only if it has no parent
        [self _orderOutRecursively:!_parentWindow];
    }
    else if (orderingMode === CPWindowAbove && otherWindowNumber === 0)
        [self _orderFront];
    else if (orderingMode === CPWindowBelow && otherWindowNumber === 0)
        [self _orderBack];
#if PLATFORM(DOM)
    else
        [_platformWindow order:orderingMode window:self relativeTo:CPApp._windows[otherWindowNumber]];
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
    [_childWindows makeObjectsPerformSelector:@selector(setLevel:) withObject:_level];

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
    Globally sets whether windows resize following the legacy style (using a resize thumb
    in the bottom right corner), or the modern style (no resize thumb, resizing
    can be done on all edges).
*/
+ (void)setGlobalResizeStyle:(int)aStyle
{
    if (CPWindowResizeStyle === aStyle)
        return;

    CPWindowResizeStyle = aStyle;
    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowResizeStyleGlobalChangeNotification object:nil];
}

- (void)_didReceiveResizeStyleChange:(CPNotification)aNotification
{
    [_windowView setShowsResizeIndicator:_styleMask & CPResizableWindowMask];
}

/*!
    Returns the global window resizing style.
*/
+ (int)globalResizeStyle
{
    return CPWindowResizeStyle;
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

    _contentView = aView;
    [_contentView setFrame:[self contentRectForFrameRect:bounds]];

    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_windowView addSubview:_contentView];

    /*
        If the initial first responder has been set to something other than
        the window, set it to the window because it will no longer be valid.
    */
    if (_initialFirstResponder && _initialFirstResponder !== self)
        _initialFirstResponder = self;
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
    The height is pinned to the difference in height between the frame rect
    and content rect, to account for a title bar + toolbar.
    @param aSize the new minimum size for the window
*/
- (void)setMinSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_minSize, aSize))
        return;

    _minSize = [self _calculateMinSizeForProposedSize:aSize];

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

/*! @ignore */
- (CGSize)_calculateMinSizeForProposedSize:(CGSize)proposedSize
{
    var contentFrame = [self contentRectForFrameRect:_frame],
        minHeight = CGRectGetHeight(_frame) - CGRectGetHeight(contentFrame);

    return CGSizeMake(MAX(proposedSize.width, 0), MAX(proposedSize.height, minHeight));
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

    _maxSize = CGSizeMakeCopy(aSize);

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
        _shadowView = [[_CPShadowWindowView alloc] initWithFrame:CGRectMakeZero()];

        [_shadowView setWindowView:_windowView];
        [_shadowView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_shadowView setNeedsLayout];

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
    _initialFirstResponder = aView;
}

- (void)_setupFirstResponder
{
    /*
        When the window is first made the key window, if the first responder is the window, use the initial first responder if there is one. If there is a first responder and it is not the window, ignore the initial first responder.
    */
    if (!_hasBecomeKeyWindow)
    {
        if (_firstResponder === self)
        {
            if (_initialFirstResponder)
                [self makeFirstResponder:_initialFirstResponder];
            else
            {
                // Make the first valid key view the first responder
                var view = [_contentView nextValidKeyView];

                if (view)
                    [self makeFirstResponder:view];
            }

            return;
        }
    }

    if (_firstResponder)
        [self makeFirstResponder:_firstResponder];
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

- (void)_mouseExitedResizeRect
{
    [[CPCursor arrowCursor] set];
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
    [self setRepresentedURL:[CPURL URLWithString:aFilePath]];
}

/*!
    Returns the path to the file the receiver represents
*/
- (CPString)representedFilename
{
    return [_representedURL absoluteString];
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
        sheet = [self attachedSheet];

    // If a sheet is attached events get filtered here.
    // It is not clear what events should be passed to the view, perhaps all?
    // CPLeftMouseDown is needed for window moving and resizing to work.
    // CPMouseMoved is needed for rollover effects on title bar buttons.

    if (sheet)
    {
        switch (type)
        {
            case CPLeftMouseDown:
                [_windowView mouseDown:anEvent];

                // -dw- if the window is clicked, the sheet should come to front, and become key,
                // and the window should be immediately behind
                [sheet makeKeyAndOrderFront:self];
                return;

            case CPMouseMoved:
                // Allow these through to the parent
                break;

            default:
                // Everything else is filtered
                return;
        }
    }

    var point = [anEvent locationInWindow];

    switch (type)
    {
        case CPFlagsChanged:
            return [[self firstResponder] flagsChanged:anEvent];

        case CPKeyUp:
            return [[self firstResponder] keyUp:anEvent];

        case CPKeyDown:
            if ([anEvent charactersIgnoringModifiers] === CPTabCharacter)
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

        case CPScrollWheel:
            return [[_windowView hitTest:point] scrollWheel:anEvent];

        case CPLeftMouseUp:
        case CPRightMouseUp:
            var hitTestedView = _leftMouseDownView,
                selector = type == CPRightMouseUp ? @selector(rightMouseUp:) : @selector(mouseUp:);

            if (!hitTestedView)
                hitTestedView = [_windowView hitTest:point];

            [hitTestedView performSelector:selector withObject:anEvent];

            _leftMouseDownView = nil;

            return;

        case CPLeftMouseDown:
        case CPRightMouseDown:
            // This will return _windowView if it is within a resize region
            _leftMouseDownView = [_windowView hitTest:point];

            if (_leftMouseDownView !== _firstResponder && [_leftMouseDownView acceptsFirstResponder])
                [self makeFirstResponder:_leftMouseDownView];

            [CPApp activateIgnoringOtherApps:YES];

            var theWindow = [anEvent window],
                selector = type == CPRightMouseDown ? @selector(rightMouseDown:) : @selector(mouseDown:);

            if ([theWindow isKeyWindow] || ([theWindow becomesKeyOnlyIfNeeded] && ![_leftMouseDownView needsPanelToBecomeKey]))
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
        case CPRightMouseDragged:
            if (!_leftMouseDownView)
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

        case CPMouseMoved:
            [_windowView setCursorForLocation:point resizing:NO];

            // Ignore mouse moves for parents of sheets
            if (!_acceptsMouseMovedEvents || sheet)
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
    Called when the receiver should become the key window. It sends
    the \c -becomeKeyWindow message to the first responder if it responds,
    and posts \c CPWindowDidBecomeKeyNotification.
*/
- (void)becomeKeyWindow
{
    CPApp._keyWindow = self;

    if (_firstResponder !== self && [_firstResponder respondsToSelector:@selector(becomeKeyWindow)])
        [_firstResponder becomeKeyWindow];

    if (!_hasBecomeKeyWindow)
    {
        // The first time a window is loaded, if it does not have a key view loop
        // established, calculate it now.
        if (![self _hasKeyViewLoop:[_contentView subviews]])
            [self recalculateKeyViewLoop];
    }

    [self _setupFirstResponder];
    _hasBecomeKeyWindow = YES;

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
    /*
        In Cocoa only titled windows return YES here by default. But the main browser
        window in Cappuccino doesn't have a title bar even that it's both titled and
        resizable, so we return YES when isFullPlatformWindow too.

        Note that Cocoa will return NO for a non-titled, resizable window. The Cocoa documention
        says it will return YES if there is a "resize bar", but in practice
        that is not the same as the resizable mask.
    */
    return (_styleMask & CPTitledWindowMask) || [self isFullPlatformWindow] || _isSheet;
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
        [item setImage:[[CPTheme defaultTheme] valueForAttributeWithName:@"spinning-regular-gif" forClass:CPProgressIndicator]];
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

    if ([self isFullPlatformWindow])
    {
        var event = [CPApp currentEvent];

        if ([event type] === CPKeyDown && [event characters] === "w" && ([event modifierFlags] & CPPlatformActionKeyMask))
        {
            [[self platformWindow] _propagateCurrentDOMEvent:YES];
            return;
        }
    }

    // The Cocoa docs say that if both the delegate and the window implement
    // windowShouldClose:, only the delegate receives the message.
    if ([_delegate respondsToSelector:@selector(windowShouldClose:)])
    {
        if (![_delegate windowShouldClose:self])
            return;
    }
    else if ([self respondsToSelector:@selector(windowShouldClose:)])
    {
        if (![self windowShouldClose:self])
            return;
    }

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
    if ([_delegate respondsToSelector:@selector(windowWillClose:)])
        [_delegate windowWillClose:self];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillCloseNotification object:self];

    [_parentWindow removeChildWindow:self];
    [self _orderOutRecursively:NO];
    [self _detachFromChildrenClosing:!_parentWindow];
}

- (void)_detachFromChildrenClosing:(BOOL)shouldCloseChildren
{
    // When a window is closed, it must detach itself from all children
    [_childWindows enumerateObjectsUsingBlock:function(child)
        {
            [child setParentWindow:nil];
        }
    ];

    if (shouldCloseChildren)
    {
        [_childWindows enumerateObjectsUsingBlock:function(child)
            {
                // Cocoa does NOT call close or orderOut when closing child windows,
                // they are summarily closed.
                [child _orderOutRecursively:NO];
                [child _detachFromChildrenClosing:![child parentWindow]];
            }
        ];
    }

    _childWindows = [];
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
    // Note that the Cocoa documentation says that this method returns YES if
    // the window is visible and has a title bar or a "resize mechanism". It turns
    // out a "resize mechanism" is not the same as having the resize mask set.
    // In practice a window must have a title bar to become main, but we make
    // an exception for a full platform window.
    return ([self isVisible] && ((_styleMask & CPTitledWindowMask) || _isFullPlatformWindow));
}

/*!
    Makes the receiver the main window.
*/
- (void)makeMainWindow
{
    // Sheets cannot be main. Their parent window becomes main.
    if (_isSheet)
    {
        [_parentView makeMainWindow];
        return;
    }

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

    // This is no longer our toolbar.
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

/*!
    Do NOT modify the array returned by this method!
*/
- (CPArray)childWindows
{
    return _childWindows;
}

- (void)addChildWindow:(CPWindow)childWindow ordered:(CPWindowOrderingMode)orderingMode
{
    // Don't add the child if it is already in our list
    if ([_childWindows indexOfObject:childWindow] >= 0)
        return;

    if (orderingMode === CPWindowAbove || orderingMode === CPWindowBelow)
        [_childWindows addObject:childWindow];
    else
        [CPException raise:CPInvalidArgumentException
                    reason:_cmd + @" unrecognized ordering mode " + orderingMode];

    [childWindow setParentWindow:self];
    [childWindow _setChildOrdering:orderingMode];
    [childWindow setLevel:[self level]];

    if ([self isVisible] && ![childWindow isVisible])
        [childWindow orderWindow:orderingMode relativeTo:_windowNumber];
}

- (void)removeChildWindow:(CPWindow)childWindow
{
    var index = [_childWindows indexOfObject:childWindow];

    if (index === CPNotFound)
        return;

    [_childWindows removeObjectAtIndex:index];
    [childWindow setParentWindow:nil];
}

- (CPWindow)parentWindow
{
    return _parentWindow;
}

/*!
    Return YES if anAncestor is the parent or a higher ancestor of the receiver.

    @ignore
*/
- (BOOL)_hasAncestorWindow:(CPWindow)anAncestor
{
    if (!_parentWindow || !anAncestor)
        return NO;

    if (anAncestor === _parentWindow)
        return YES;

    return [_parentWindow _hasAncestorWindow:anAncestor];
}

- (CPWindow)setParentWindow:(CPWindow)parentWindow
{
    _parentWindow = parentWindow;
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

- (void)_setAttachedSheetFrameOrigin
{
    // Position the sheet above the contentRect.
    var attachedSheet = [self attachedSheet],
        contentRect = [_contentView frame],
        sheetFrame = CGRectMakeCopy([attachedSheet frame]);

    sheetFrame.origin.y = CGRectGetMinY(_frame) + CGRectGetMinY(contentRect);
    sheetFrame.origin.x = CGRectGetMinX(_frame) + FLOOR((CGRectGetWidth(_frame) - CGRectGetWidth(sheetFrame)) / 2.0);

    [attachedSheet setFrame:sheetFrame display:YES animate:NO];
}

/*
    Starting point for sheet session, called from CPApplication beginSheet:
*/
- (void)_attachSheet:(CPWindow)aSheet modalDelegate:(id)aModalDelegate
        didEndSelector:(SEL)didEndSelector contextInfo:(id)contextInfo
{
    if (_sheetContext)
    {
        [CPException raise:CPInternalInconsistencyException
            reason:@"The target window of beginSheet: already has a sheet, did you forget orderOut: ?"];
        return;
    }

    _sheetContext = {
        "sheet": aSheet,
        "modalDelegate": aModalDelegate,
        "endSelector": didEndSelector,
        "contextInfo": contextInfo,
        "returnCode": -1,
        "opened": NO,
        "isAttached": YES,
        "savedConstrains": aSheet._constrainsToUsableScreen
    };

    // Sheets are not constrained, they are controlled by their parent
    aSheet._constrainsToUsableScreen = NO;

    // A timer seems to be necessary for the animation to work correctly
    [CPTimer scheduledTimerWithTimeInterval:0.0
        target:self
        selector:@selector(_sheetShouldAnimateIn:)
        userInfo:nil
        repeats:NO];
}

/*
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

/*
    Called to animate the sheet out. If called while animating in, schedules an animate
    out at completion
*/
- (void)_detachSheetWindow
{
    _sheetContext["isAttached"] = NO;

    // A timer seems to be necessary for the animation to work correctly.
    // It would be ideal to block here and spin the event loop, until attach is complete.
    [CPTimer scheduledTimerWithTimeInterval:0.0
        target:self
        selector:@selector(_sheetShouldAnimateOut:)
        userInfo:nil
        repeats:NO];
}

/*
    Called to cleanup sheet, when we are definitely done with it
*/
- (void)_cleanupSheetWindow
{
    var sheet = _sheetContext["sheet"],
        deferDidEnd = _sheetContext["deferDidEndSelector"];

    // If the parent window is modal, the sheet started its own modal session
    if (sheet._isModal)
        [CPApp stopModal];

    [self _removeClipForSheet:sheet];

    // Restore the state of window before it was sheetified
    sheet._isSheet = NO;
    [sheet._windowView _enableSheet:NO inWindow:self];
    sheet._constrainsToUsableScreen = _sheetContext["savedConstrains"];

    // Close it
    [sheet orderOut:self];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidEndSheetNotification object:self];

    if (deferDidEnd)
    {
        var delegate = _sheetContext["modalDelegate"],
            selector = _sheetContext["endSelector"],
            returnCode = _sheetContext["returnCode"],
            contextInfo = _sheetContext["contextInfo"];

        // Context must be destroyed, since didEnd might want to attach another sheet
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

- (void)_sheetShouldAnimateIn:(CPTimer)timer
{
    // Can't open sheet while opening or closing animation is going on
    if (_sheetContext["isOpening"] || _sheetContext["isClosing"])
        return;

    var sheet = _sheetContext["sheet"];
    sheet._isSheet = YES;
    sheet._parentView = self;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillBeginSheetNotification object:self];

    // If sheet is attached to a modal window, the sheet runs
    // as if itself and the parent window are modal
    sheet._isModal = NO;

    if ([CPApp modalWindow] === self)
    {
        [CPApp runModalForWindow:sheet];
        sheet._isModal = YES;
    }

    // The sheet starts hidden just above the top of a clip rect
    // TODO : Make properly for the -1 in endY
    var sheetFrame = [sheet frame],
        sheetShadowFrame = sheet._hasShadow ? [sheet._shadowView frame] : sheetFrame,
        frame = [self frame],
        originX = frame.origin.x + FLOOR((frame.size.width - sheetFrame.size.width) / 2),
        startFrame = CGRectMake(originX, -sheetShadowFrame.size.height, sheetFrame.size.width, sheetFrame.size.height),
        endY = -1 + [_windowView bodyOffset] - [[self contentView] frame].origin.y,
        endFrame = CGRectMake(originX, endY, sheetFrame.size.width, sheetFrame.size.height);

    if (_toolbar && [_windowView showsToolbar] && [self isFullPlatformWindow])
    {
        endY    += [[_toolbar _toolbarView] frameSize].height;
        endFrame = CGRectMake(originX, endY, sheetFrame.size.width, sheetFrame.size.height);
    }

    // Move the sheet offscreen before ordering front so it doesn't appear briefly
    [sheet setFrameOrigin:CGPointMake(0, -13000)];

    // Because clipping does funny thing with the DOM, we have to orderFront before clipping
    [sheet orderFront:self];
    [self _clipSheet:sheet];

    [sheet setFrame:startFrame display:YES animate:NO];

    _sheetContext["opened"] = YES;
    _sheetContext["shouldClose"] = NO;
    _sheetContext["isOpening"] = YES;

    [sheet _setFrame:endFrame delegate:self duration:[self animationResizeTime:endFrame] curve:CPAnimationEaseOut];
}

- (void)_sheetShouldAnimateOut:(CPTimer)timer
{
    if (_sheetContext["isOpening"])
    {
        // Allow sheet to be closed while opening, it will close when animate in completes
        _sheetContext["shouldClose"] = YES;
        return;
    }

    if (_sheetContext["isClosing"])
        return;

    _sheetContext["opened"] = NO;
    _sheetContext["isClosing"] = YES;

    // The parent window can be orderedOut to disable the sheet animate out, as in Cocoa
    if ([self isVisible])
    {
        var sheet = _sheetContext["sheet"],
            sheetFrame = [sheet frame],
            fullHeight = sheet._hasShadow ? [sheet._shadowView frame].size.height : sheetFrame.size.height,
            endFrame = CGRectMakeCopy(sheetFrame),
            contentOrigin = [self convertBaseToGlobal:[[self contentView] frame].origin];

        // Don't constrain sheets, they are controlled by the parent
        sheet._constrainsToUsableScreen = NO;

        [sheet setFrameOrigin:CGPointMake(sheetFrame.origin.x, sheetFrame.origin.y - contentOrigin.y)];
        [self _clipSheet:sheet];

        endFrame.origin.y = -fullHeight;
        [sheet _setFrame:endFrame delegate:self duration:[self animationResizeTime:endFrame] curve:CPAnimationEaseIn];
    }
    else
    {
        [self _sheetAnimationDidEnd:nil];
    }
}

- (void)_sheetAnimationDidEnd:(CPTimer)timer
{
    var sheet = _sheetContext["sheet"];

    _sheetContext["isOpening"] = NO;
    _sheetContext["isClosing"] = NO;

    if (_sheetContext["opened"] === YES)
    {
        var sheetFrame = [sheet frame],
            sheetOrigin = CGPointMakeCopy(sheetFrame.origin);

        [self _removeClipForSheet:sheet];
        [sheet setFrameOrigin:CGPointMake(sheetOrigin.x, [sheet frame].origin.y + sheetOrigin.y)];

        // we wanted to close the sheet while it animated in, do that now
        if (_sheetContext["shouldClose"] === YES)
            [self _detachSheetWindow];
        else
            [sheet makeKeyWindow];
    }
    else
    {
        // sheet is closed and not visible
        [self _cleanupSheetWindow];
    }
}

- (void)_clipSheet:(CPWindow)aSheet
{
    var clipRect = [_platformWindow contentBounds];
    clipRect.origin.y = [self frame].origin.y + [[self contentView] frame].origin.y;

    [[_platformWindow layerAtLevel:_level create:NO] clipWindow:aSheet toRect:clipRect];
}

- (void)_removeClipForSheet:(CPWindow)aSheet
{
    [[_platformWindow layerAtLevel:_level create:NO] removeClipForWindow:aSheet];
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
    return [_contentView performKeyEquivalent:anEvent];
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
        /*
            Cocoa sends complete: for the escape key (instead of the default cancelOperation:). This is also the only action that is not sent directly to the first responder, but through doCommandBySelector. The difference is that doCommandBySelector: will also send the action to the window and application delegates.
        */
        [[self firstResponder] doCommandBySelector:@selector(complete:)];
    }

    return NO;
}

- (void)_dirtyKeyViewLoop
{
    if (_autorecalculatesKeyViewLoop)
        _keyViewLoopIsDirty = YES;
}

/*
    Recursively traverse an array of views (depth last) until we find one that has a next or previous key view set. Return nil if none can be found.

    We don't use _viewsSortedByPosition here because it is wasteful to enumerate the entire view hierarchy when we will probably find a key view at the top level.
*/
- (BOOL)_hasKeyViewLoop:(CPArray)theViews
{
    var i,
        count = [theViews count];

    for (i = 0; i < count; ++i)
    {
        var view = theViews[i];

        if ([view nextKeyView] || [view previousKeyView])
            return YES;
    }

    for (i = 0; i < count; ++i)
    {
        var subviews = [theViews[i] subviews];

        if ([subviews count] && [self _hasKeyViewLoop:subviews])
            return YES;
    }

    return NO;
}

/*!
    Recalculates the key view loop, based on geometric position.
    Note that the Cocoa documentation says that this method only marks the loop
    as dirty, the recalculation is not done until the next or previous key view
    of the window is requested. In reality, Cocoa does recalculate the loop
    when this method is called.
*/
- (void)recalculateKeyViewLoop
{
    [self _doRecalculateKeyViewLoop];
}

- (CPArray)_viewsSortedByPosition
{
    var views = [CPArray arrayWithObject:_contentView];

    views = views.concat([self _subviewsSortedByPosition:[_contentView subviews]]);

    return views;
}

- (CPArray)_subviewsSortedByPosition:(CPArray)theSubviews
{
    /*
        We first sort the subviews according to geometric order.
        Then we go through each subview, and if it has subviews,
        they are sorted and inserted after the superview. This
        is done recursively.
    */
    theSubviews = [theSubviews copy];
    [theSubviews sortUsingFunction:keyViewComparator context:nil];

    var sortedViews = [];

    for (var i = 0, count = [theSubviews count]; i < count; ++i)
    {
        var view = theSubviews[i],
            subviews = [view subviews];

        sortedViews.push(view);

        if ([subviews count])
            sortedViews = sortedViews.concat([self _subviewsSortedByPosition:subviews]);
    }

    return sortedViews;
}

- (void)_doRecalculateKeyViewLoop
{
    var views = [self _viewsSortedByPosition];

    for (var index = 0, count = [views count]; index < count; ++index)
        [views[index] setNextKeyView:views[(index + 1) % count]];

    _keyViewLoopIsDirty = NO;
}

- (void)setAutorecalculatesKeyViewLoop:(BOOL)shouldRecalculate
{
    if (_autorecalculatesKeyViewLoop === shouldRecalculate)
        return;

    _autorecalculatesKeyViewLoop = shouldRecalculate;
}

- (BOOL)autorecalculatesKeyViewLoop
{
    return _autorecalculatesKeyViewLoop;
}

- (void)selectNextKeyView:(id)sender
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var nextValidKeyView = nil;

    if ([_firstResponder isKindOfClass:[CPView class]])
        nextValidKeyView = [_firstResponder nextValidKeyView];

    if (!nextValidKeyView)
    {
        if ([_initialFirstResponder acceptsFirstResponder])
            nextValidKeyView = _initialFirstResponder;
        else
            nextValidKeyView = [_initialFirstResponder nextValidKeyView];
    }

    if (nextValidKeyView)
        [self makeFirstResponder:nextValidKeyView];
}

- (void)selectPreviousKeyView:(id)sender
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var previousValidKeyView = nil;

    if ([_firstResponder isKindOfClass:[CPView class]])
        previousValidKeyView = [_firstResponder previousValidKeyView];

    if (!previousValidKeyView)
    {
        if ([_initialFirstResponder acceptsFirstResponder])
            previousValidKeyView = _initialFirstResponder;
        else
            previousValidKeyView = [_initialFirstResponder previousValidKeyView];
    }

    if (previousValidKeyView)
        [self makeFirstResponder:previousValidKeyView];
}

- (void)selectKeyViewFollowingView:(CPView)aView
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var nextValidKeyView = [aView nextValidKeyView];

    if ([nextValidKeyView isKindOfClass:[CPView class]])
        [self makeFirstResponder:nextValidKeyView];
}

- (void)selectKeyViewPrecedingView:(CPView)aView
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

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

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    if (aKey === CPDisplayPatternTitleBinding)
        [self setTitle:aValue || @""];
    else
        [super setValue:aValue forKey:aKey];
}

@end

var keyViewComparator = function(lhs, rhs, context)
{
    var lhsBounds = [lhs convertRect:[lhs bounds] toView:nil],
        rhsBounds = [rhs convertRect:[rhs bounds] toView:nil],
        lhsY = CGRectGetMinY(lhsBounds),
        rhsY = CGRectGetMinY(rhsBounds),
        lhsX = CGRectGetMinX(lhsBounds),
        rhsX = CGRectGetMinX(rhsBounds),
        intersectsVertically = MIN(CGRectGetMaxY(lhsBounds), CGRectGetMaxY(rhsBounds)) - MAX(lhsY, rhsY);

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

@implementation CPWindow (BridgeSupport)

/*
    @ignore
*/
- (void)resizeWithOldPlatformWindowSize:(CGSize)aSize
{
    if ([self isFullPlatformWindow])
        return [self setFrame:[_platformWindow visibleFrame]];

    if (_autoresizingMask === CPWindowNotSizable)
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
        return CGPointMakeCopy(aPoint);

    var origin = [self frame].origin;

    return CGPointMake(aPoint.x + origin.x, aPoint.y + origin.y);
}

/*!
    Converts aPoint from the parent platform window coordinate system to the window's coordinate system.
*/
- (CGPoint)convertPlatformWindowToBase:(CGPoint)aPoint
{
    if ([self _sharesChromeWithPlatformWindow])
        return CGPointMakeCopy(aPoint);

    var origin = [self frame].origin;

    return CGPointMake(aPoint.x - origin.x, aPoint.y - origin.y);
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

/* aPoint should be global */
- (BOOL)_isValidMousePoint:(CGPoint)aPoint
{
    // If we are using the new resizing mode, mouse events are valid
    // outside the window's frame for non-full platform windows.
    var mouseFrame = (!_isFullPlatformWindow && (_styleMask & CPResizableWindowMask) && (CPWindowResizeStyle === CPWindowResizeStyleModern)) ? CGRectInset(_frame, -_CPWindowViewResizeSlop, -_CPWindowViewResizeSlop) : _frame;

    return CGRectContainsPoint(mouseFrame, aPoint);
}

@end

@implementation CPWindow (Deprecated)
/*!
    Sets the CPWindow to fill the whole browser window.
    NOTE: this method has been deprecated in favor of setFullPlatformWindow:
*/
- (void)setFullBridge:(BOOL)shouldBeFullBridge
{
    _CPReportLenientDeprecation([self class], _cmd, @selector(setFullPlatformWindow:));

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

    var newFrame = CGRectMake(
            interpolate(CGRectGetMinX(_startFrame), CGRectGetMinX(_targetFrame), value),
            interpolate(CGRectGetMinY(_startFrame), CGRectGetMinY(_targetFrame), value),
            interpolate(CGRectGetWidth(_startFrame), CGRectGetWidth(_targetFrame), value),
            interpolate(CGRectGetHeight(_startFrame), CGRectGetHeight(_targetFrame), value));

    [_window setFrame:newFrame display:YES animate:NO];
}

@end


@implementation CPWindow (CPDraggingAdditions)

/* @ignore */
- (id)_dragHitTest:(CGPoint)aPoint pasteboard:(CPPasteboard)aPasteboard
{
    // If none of our views or ourselves has registered for drag events...
    if (!_inclusiveRegisteredDraggedTypes)
        return nil;

// We don't need to do this because the only place this gets called
// -_dragHitTest: in CPPlatformWindow does this already. Perhaps to
// be safe?
//    if (![self containsPoint:aPoint])
//        return nil;

    var adjustedPoint = [self convertPlatformWindowToBase:aPoint],
        hitView = [_windowView hitTest:adjustedPoint];

    while (hitView && ![aPasteboard availableTypeFromArray:[hitView registeredDraggedTypes]])
        hitView = [hitView superview];

    if (hitView)
        return hitView;

    if ([aPasteboard availableTypeFromArray:[self registeredDraggedTypes]])
        return self;

    return nil;
}

@end

function _CPWindowFullPlatformWindowSessionMake(aWindowView, aContentRect, hasShadow, aLevel)
{
    return { windowView:aWindowView, contentRect:aContentRect, hasShadow:hasShadow, level:aLevel };
}
