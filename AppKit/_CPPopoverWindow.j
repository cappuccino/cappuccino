/*
 * _CPPopoverWindow.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2011 <primalmotion@archipelproject.org>
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

@import "CPButton.j"
@import "CPMenu.j"
@import "CPPanel.j"

// Use forward declaration because this file is imported by CPPopover
@class CPPopover

@global CPApp

CPClosableOnBlurWindowMask  = 1 << 4;
CPPopoverAppearanceMinimal  = 0;
CPPopoverAppearanceHUD      = 1;

var _CPPopoverWindow_shouldClose_    = 1 << 0,
    _CPPopoverWindow_didClose_       = 1 << 1,
    _CPPopoverWindow_didShow_        = 1 << 2;


/*!
    @ignore

    This is a simple popover window like the one that pops up
    when you double click on a meeting in iCal.
*/
@implementation _CPPopoverWindow : CPPanel
{
    BOOL            _animates           @accessors(property=animates);
    id              _targetView         @accessors(property=targetView);
    int             _appearance         @accessors(getter=appearance);
    BOOL            _isClosing          @accessors(property=isClosing);

    BOOL            _closeOnBlur;
    BOOL            _browserAnimates;
    BOOL            _shouldPerformAnimation;
    CPInteger       _implementedDelegateMethods;
    JSObject        _orderOutTransitionFunction;
}


#pragma mark -
#pragma mark Class methods

/*!
    Overrides the default windowView class loader.

    @param aStyleMask the window mask
    @return the windowView class
*/
+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    return _CPPopoverWindowView;
}


#pragma mark -
#pragma mark Initialization

/*!
    Create and init a _CPPopoverWindow with given the given frame.

    @param aFrame the frame of the popover window
    @return ready to use _CPPopoverWindow
*/
- (id)initWithContentRect:(CGRect)aFrame
{
    return [self initWithContentRect:aFrame styleMask:0];
}

/*!
    Designated initializer. Create and init a _CPPopoverWindow with the given frame and style mask.

    @param aFrame the frame of the popover window
    @param styleMask the window style mask  (combine CPClosableWindowMask and CPClosableOnBlurWindowMask)
    @return ready to use _CPPopoverWindow
*/
- (id)initWithContentRect:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithContentRect:aFrame styleMask:aStyleMask])
    {
        _animates                   = YES;
        _isClosing                  = NO;
        _browserAnimates            = [self browserSupportsAnimation];
        _shouldPerformAnimation     = YES;
        _orderOutTransitionFunction = function() { [self _orderOutRecursively:YES]; };


        [self setStyleMask:aStyleMask];
        [self setBecomesKeyOnlyIfNeeded:YES];
        [self setMovableByWindowBackground:YES];
        [self setHasShadow:NO];

        [self setCSS3Property:@"TransitionProperty" value:CPBrowserCSSProperty('transform') + @", opacity"];

        [_windowView setNeedsDisplay:YES];
    }

    return self;
}

#pragma mark -
#pragma mark Getters / Setters

- (void)setAppearance:(int)anAppearance
{
    if (_appearance === anAppearance)
        return;

    [_windowView setAppearance:anAppearance];
}

- (void)setStyleMask:(unsigned)aStyleMask
{
    _closeOnBlur = (aStyleMask & CPClosableOnBlurWindowMask);
}

- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(popoverWindowShouldClose:)])
        _implementedDelegateMethods |= _CPPopoverWindow_shouldClose_;

    if ([_delegate respondsToSelector:@selector(popoverWindowDidClose:)])
        _implementedDelegateMethods |= _CPPopoverWindow_didClose_;

    if ([_delegate respondsToSelector:@selector(popoverWindowDidShow:)])
        _implementedDelegateMethods |= _CPPopoverWindow_didShow_;
}

#pragma mark -
#pragma mark Observer

/*!
    Update the _CPPopoverWindow frame if a resize event is observed.
*/
- (void)observeValueForKeyPath:(CPString)aPath ofObject:(id)anObject change:(CPDictionary)theChange context:(void)aContext
{
    if (aPath === @"frame")
    {
        if (![_targetView window])
            return;

        var point = [self computeOriginFromRect:[_targetView bounds] ofView:_targetView preferredEdge:[_windowView preferredEdge]];

        [self setFrameOrigin:point];
    }
}


#pragma mark -
#pragma mark Utilities

- (CGPoint)computeOriginFromRect:(CGRect)aRect ofView:(CPView)positioningView preferredEdge:(int)anEdge
{
    var mainWindow      = [positioningView window],
        platformWindow  = [mainWindow platformWindow],
        nativeRect      = [platformWindow usableContentFrame],
        baseOrigin      = [positioningView convertPointToBase:aRect.origin],
        platformOrigin  = [mainWindow convertBaseToPlatformWindow:baseOrigin],
        platformRect    = CGRectMake(platformOrigin.x, platformOrigin.y, aRect.size.width, aRect.size.height),
        originLeft      = CGPointCreateCopy(platformOrigin),
        originRight     = CGPointCreateCopy(platformOrigin),
        originTop       = CGPointCreateCopy(platformOrigin),
        originBottom    = CGPointCreateCopy(platformOrigin),
        frameSize       = [self frame].size;

    // CPMaxXEdge
    originRight.x += platformRect.size.width;
    originRight.y += (platformRect.size.height / 2.0) - (frameSize.height / 2.0);

    // CPMinXEdge
    originLeft.x -= frameSize.width;
    originLeft.y += (platformRect.size.height / 2.0) - (frameSize.height / 2.0);

    // CPMaxYEdge
    originBottom.x += platformRect.size.width / 2.0 - frameSize.width / 2.0;
    originBottom.y += platformRect.size.height;

    // CPMinYEdge
    originTop.x += platformRect.size.width / 2.0 - frameSize.width / 2.0;
    originTop.y -= frameSize.height;

    var requestedEdge = (anEdge !== nil) ? anEdge : CPMaxXEdge,
        requestedOrigin;

    switch (requestedEdge)
    {
        case CPMaxXEdge:
            requestedOrigin = originRight;
            break;

        case CPMinXEdge:
            requestedOrigin = originLeft;
            break;

        case CPMinYEdge:
            requestedOrigin = originTop;
            break;

        case CPMaxYEdge:
            requestedOrigin = originBottom;
            break;
    }

    var origins = [requestedOrigin, originRight, originLeft, originTop, originBottom],
        edges = [requestedEdge, CPMaxXEdge, CPMinXEdge, CPMinYEdge, CPMaxYEdge];

    for (var i = 0; i < origins.length; i++)
    {
        var origin = origins[i],
            edge = edges[i];

        [_windowView setArrowOffsetX:0];
        [_windowView setArrowOffsetY:0];
        [_windowView setPreferredEdge:edge];

        if (origin.x < CGRectGetMinX(nativeRect))
        {
            [_windowView setArrowOffsetX:origin.x];
            origin.x = CGRectGetMinX(nativeRect);
        }

        if (origin.x + frameSize.width > CGRectGetMaxX(nativeRect))
        {
            [_windowView setArrowOffsetX:(origin.x + frameSize.width - CGRectGetMaxX(nativeRect))];
            origin.x = CGRectGetMaxX(nativeRect) - frameSize.width;
        }

        if (origin.y < CGRectGetMinY(nativeRect))
        {
            [_windowView setArrowOffsetY:origin.y - CGRectGetMinY(nativeRect)];
            origin.y = CGRectGetMinY(nativeRect);
        }

        if (origin.y + frameSize.height > CGRectGetMaxY(nativeRect))
        {
            [_windowView setArrowOffsetY:(frameSize.height + origin.y - CGRectGetMaxY(nativeRect))];
            origin.y = CGRectGetMaxY(nativeRect) - frameSize.height;
        }

        switch (edge)
        {
            case CPMaxXEdge:
                if (origin.x >= CGRectGetMaxX(platformRect))
                    return origin;
                break;

            case CPMinXEdge:
                if ((origin.x + frameSize.width) <= platformRect.origin.x)
                    return origin;
                break;

            case CPMaxYEdge:
                if (origin.y >= CGRectGetMaxY(platformRect))
                    return origin;
                break;

            case CPMinYEdge:
                if ((origin.y + frameSize.height) <= platformRect.origin.y)
                    return origin;
                break;
        }
    }

    [_windowView setPreferredEdge:nil];
    return requestedOrigin;
}

/*!
    Compute the frame needed to be placed to the given view
    and position the popover window according to this view (edge will be automatic)

    @param aView the view where _CPPopoverWindow must be popover
*/
- (void)positionRelativeToView:(CPView)aView
{
    [self positionRelativeToRect:nil ofView:aView preferredEdge:nil];
}

/*!
    Position the _CPPopoverWindow relative to a given rect's edge.

    @param aRect the rect relative to which the popover window will be positioned
    @param positioningView the view to which the popover window is popover
    @param anEdge the prefered edge
*/
- (void)positionRelativeToRect:(CGRect)aRect ofView:(CPView)positioningView preferredEdge:(int)anEdge
{
    var wasVisible = [self isVisible];

    if (!aRect || CGRectIsEmpty(aRect))
        aRect = [positioningView bounds];

    var point = [self computeOriginFromRect:aRect ofView:positioningView preferredEdge:anEdge];

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];

    if (positioningView !== _targetView)
    {
        [[_targetView window] removeChildWindow:self];
        [_targetView removeObserver:self forKeyPath:@"frame"];
        _targetView = positioningView;
    }

    /*
        If _targetView's window is not a full platform window,
        add us as a child, because when we close we are detached from
        the parent, and the parent may cache this window and reopen it.
    */
    var targetWindow = [_targetView window];

    if (![targetWindow isFullPlatformWindow])
        [[_targetView window] addChildWindow:self ordered:CPWindowAbove];

    if (!wasVisible)
        [self _trapNextMouseDown];
}

/*! @ignore */
- (void)setCSS3Property:(CPString)aProperty value:(CPString)value
{
    var browserProperty = CPBrowserStyleProperty(aProperty);

#if PLATFORM(DOM)
    if (browserProperty)
        _DOMElement.style[browserProperty] = value;
#endif
}

/*! @ignore */
- (BOOL)browserSupportsAnimation
{
    return CPBrowserStyleProperty('transition') && CPBrowserStyleProperty('transitionend');
}

#pragma mark -
#pragma mark Actions

/*!
    @ignore
    Closes the _CPPopoverWindow

    @param sender the sender of the action
*/
- (IBAction)close:(id)aSender
{
    [self close];
}


#pragma mark -
#pragma mark Overrides

/*!
    @ignore
    Show animation if necessary.
*/
- (void)close
{
    [self orderOut:self];
    [self _detachFromChildrenClosing:YES];
}

/*!
    @ignore
    When the window appears, show animation if necessary.
    Also take this opportunity to keep track of window moves.

    @param sender the sender of the action
*/
- (IBAction)orderFront:(is)aSender
{
    if (![self isKeyWindow])
    {
        [super orderFront:aSender];

        if (_animates && _browserAnimates && _shouldPerformAnimation)
        {
            var transformOrigin = "50% 100%",
                frame = [self frame],
                preferredEdge = [_windowView preferredEdge],
                posX, posY;

            switch (preferredEdge)
            {
                case CPMaxYEdge:
                case CPMinYEdge:
                    posX = 50 + (([_windowView arrowOffsetX] * 100) / frame.size.width);
                    transformOrigin = posX + "% " + (preferredEdge === CPMaxYEdge ? "0%" : "100%");
                    break;

                case CPMinXEdge:
                case CPMaxXEdge:
                    posY = 50 + (([_windowView arrowOffsetY] * 100) / frame.size.height);
                    transformOrigin = (preferredEdge === CPMaxXEdge ? "0% " : "100% ") + posY + "%";
                    break;
            }

            // This is the initial transform. We start scaled to zero and watch for opacity changes.
            [self setCSS3Property:@"Transform" value:@"scale(0)"];
            [self setCSS3Property:@"TransformOrigin" value:transformOrigin];
            [self setCSS3Property:@"Transition" value:"opacity 0 linear"];

            window.setTimeout(function()
            {
                // We are watching opacity, so this triggers the next transition
#if PLATFORM(DOM)
                _DOMElement.style.opacity = 1;
                _DOMElement.style.height = frame.size.height + @"px";
                _DOMElement.style.width = frame.size.width + @"px";
#endif

                // Set up the pop-out transition
                [self setCSS3Property:@"Transform" value:@"scale(1.1)"];
                [self setCSS3Property:@"Transition" value:CPBrowserCSSProperty('transform') + @" 200ms ease-in"];

                var orderFrontTransitionFunction = function()
                {
#if PLATFORM(DOM)
                    _DOMElement.removeEventListener(CPBrowserStyleProperty('transitionend'), orderFrontTransitionFunction, YES);
#endif

                    // Now set up the pop-in to normal size transition.
                    // Because we are watching the -webkit-transform, it will occur now.
                    [self setCSS3Property:@"Transform" value:@"scale(1)"];
                    [self setCSS3Property:@"Transition" value:CPBrowserCSSProperty('transform') + @" 50ms linear"];

                    var transitionCompleteFunction = function()
                    {
#if PLATFORM(DOM)
                        _DOMElement.removeEventListener(CPBrowserStyleProperty('transitionend'), transitionCompleteFunction, YES);

                        // Make sure to clear these properties when the animation is done. Without this,
                        // the window becomes blurry in Chrome, presumably because the browser composits
                        // a layer with a transform differently even when it's an identity transform.
                        [self setCSS3Property:@"Transform" value:nil];
                        [self setCSS3Property:@"TransformOrigin" value:nil];
                        [self setCSS3Property:@"Transition" value:nil];
#endif
                        if (_implementedDelegateMethods & _CPPopoverWindow_didShow_)
                             [_delegate popoverWindowDidShow:self];
                    }

#if PLATFORM(DOM)
                    _DOMElement.addEventListener(CPBrowserStyleProperty('transitionend'), transitionCompleteFunction, YES);
#endif
                };

#if PLATFORM(DOM)
                _DOMElement.addEventListener(CPBrowserStyleProperty('transitionend'), orderFrontTransitionFunction, YES);
#endif
            }, 0);
        }
        else
        {
            [self setCSS3Property:@"Transition" value:@""];
#if PLATFORM(DOM)
            _DOMElement.style.opacity = 1;
#endif
        }
    }

    _shouldPerformAnimation = NO;
    _isClosing = NO;
}

- (void)_orderFront
{
    if (![self isVisible])
        [_targetView addObserver:self forKeyPath:@"frame" options:0 context:nil];

    [super _orderFront];
}

- (void)_parentDidOrderInChild
{
    [_targetView addObserver:self forKeyPath:@"frame" options:0 context:nil];
}

/*!
    @ignore
    Animate window closing.
*/
- (void)orderOut:(id)aSender
{
    if (![self isVisible])
        return;

    _isClosing = YES;

    if (_animates && _browserAnimates)
    {
        // Tell the element to fade out when the opacity changes
        [self setCSS3Property:@"Transition" value:@"opacity 250ms linear"];
#if PLATFORM(DOM)
        _DOMElement.style.opacity = 0;
        _DOMElement.addEventListener(CPBrowserStyleProperty("transitionend"), _orderOutTransitionFunction, YES);
#endif
    }
    else
    {
        [self _orderOutRecursively:YES];
    }
}

- (void)_orderOutRecursively:(BOOL)recursive
{
    // Make absolutely sure no dangling event listeners are left
#if PLATFORM(DOM)
    _DOMElement.removeEventListener(CPBrowserStyleProperty("transitionend"), _orderOutTransitionFunction, YES);
#endif

    [_targetView removeObserver:self forKeyPath:@"frame"];
    [_parentWindow removeChildWindow:self];
    [super _orderOutRecursively:recursive];

    _shouldPerformAnimation = YES;
    _isClosing = NO;

    if (_implementedDelegateMethods & _CPPopoverWindow_didClose_)
        [_delegate popoverWindowDidClose:self];
}


#pragma mark -
#pragma mark Private

- (void)_mouseWasClicked:(CPEvent)anEvent
{
    /*
        If the mouse was clicked inside us, trap the next mouse down.
        If the mouse was clicked outside of us, we close and send this
        message to any parent popovers so they have a chance to close
        if necessary.
    */
    if (![self isVisible])
        return;

    var mouseWindow = [anEvent window];

    // Consider clicks in child windows to be "inside". This keeps a transient popover from
    // closing if e.g. the window containing the menu of a token field is clicked.
    if (mouseWindow === self || [mouseWindow _hasAncestorWindow:self])
        [self _trapNextMouseDown];
    else
    {
        // Send _close to the delegate so popoverWillClose is sent to the popover's delegate
        if (_closeOnBlur)
            [_delegate _close];

        // Give a transient parent popover a chance to close
        var parent = [self parentWindow];

        if ([parent isKindOfClass:[self class]])
            [parent _mouseWasClicked:anEvent];
    }
}

- (void)_trapNextMouseDown
{
    // Don't dequeue the event so clicks in controls will work
    [CPApp setTarget:self selector:@selector(_mouseWasClicked:) forNextEventMatchingMask:CPLeftMouseDownMask untilDate:nil inMode:CPDefaultRunLoopMode dequeue:NO];
}

@end
