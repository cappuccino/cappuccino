/*
 * _CPToolTipWindowView.j
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
@import "CPWindow.j"


CPClosableOnBlurWindowMask  = 1 << 4;
CPPopoverAppearanceMinimal  = 0;
CPPopoverAppearanceHUD      = 1;

var _CPAttachedWindow_attachedWindowShouldClose_    = 1 << 0,
    _CPAttachedWindow_attachedWindowDidClose_       = 1 << 1;


/*!
    @ignore

    This is a simple attached window like the one that pops up
    when you double click on a meeting in iCal.
*/
@implementation _CPAttachedWindow : CPWindow
{
    BOOL            _animates           @accessors(property=animates);
    id              _targetView         @accessors(property=targetView);
    int             _appearance         @accessors(getter=appearance);

    BOOL            _closeOnBlur;
    BOOL            _isClosing;
    BOOL            _browserAnimates;
    BOOL            _shouldPerformAnimation;
    CPButton        _closeButton;
    CPInteger       _implementedDelegateMethods;
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
    return _CPAttachedWindowView;
}


#pragma mark -
#pragma mark Initialization

/*!
    Create and init a _CPAttachedWindow with the given size and view.

    @param aSize the size of the attached window
    @param aView the target view
    @return ready to use _CPAttachedWindow
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView
{
    return [_CPAttachedWindow attachedWindowWithSize:aSize forView:aView styleMask:nil];
}

/*!
    Create and init a _CPAttachedWindow with given the size, view and style mask.

    @param aSize the size of the attached window
    @param aView the target view
    @param styleMask the window style mask  (combine CPClosableWindowMask and CPClosableOnBlurWindowMask)
    @return ready to use _CPAttachedWindow
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView styleMask:(int)aMask
{
    var attachedWindow = [[_CPAttachedWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, aSize.width, aSize.height) styleMask:aMask];

    [attachedWindow attachToView:aView];

    return attachedWindow;
}

/*!
    Create and init a _CPAttachedWindow with given the given frame.

    @param aFrame the frame of the attached window
    @return ready to use _CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame
{
    self = [self initWithContentRect:aFrame styleMask:nil];
    return self;
}

/*!
    Create and init a _CPAttachedWindow with the given frame and style mask.

    @param aFrame the frame of the attached window
    @param styleMask the window style mask  (combine CPClosableWindowMask and CPClosableOnBlurWindowMask)
    @return ready to use _CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithContentRect:aFrame styleMask:aStyleMask])
    {
        _animates                   = YES;
        _closeOnBlur                = (aStyleMask & CPClosableOnBlurWindowMask);
        _isClosing                  = NO;
        _browserAnimates            = [self browserSupportsAnimation];
        _shouldPerformAnimation     = YES;

        [self setLevel:CPStatusWindowLevel];
        [self setMovableByWindowBackground:YES];
        [self setHasShadow:NO];

        [self setCSS3Property:@"TransitionProperty" value:@"-webkit-transform, opacity"];

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

- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(attachedWindowShouldClose:)])
        _implementedDelegateMethods |= _CPAttachedWindow_attachedWindowShouldClose_;

    if ([_delegate respondsToSelector:@selector(attachedWindowDidClose:)])
        _implementedDelegateMethods |= _CPAttachedWindow_attachedWindowDidClose_;
}

#pragma mark -
#pragma mark Observer

/*!
    Update the _CPAttachedWindow frame if a resize event is observed.
*/
- (void)observeValueForKeyPath:(CPString)aPath ofObject:(id)anObject change:(CPDictionary)theChange context:(void)aContext
{
    if ([aPath isEqual:@"frame"])
    {
        // TODO: don't recompute everything, just compute the move offset
        var g = [_windowView preferredEdge];

        [self positionRelativeToView:_targetView preferredEdge:g];
    }
}


#pragma mark -
#pragma mark Notification handlers

- (void)_attachedWindowDidMove:(CPNotification)aNotification
{
    if ([_windowView isMouseDownPressed])
    {
        [_targetView removeObserver:self forKeyPath:@"frame"];
        [_windowView hideCursor];
        [self setLevel:CPNormalWindowLevel];
        [_closeButton setFrameOrigin:CGPointMake(1.0, 1.0)];
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPWindowDidMoveNotification object:self];
    }
}


#pragma mark -
#pragma mark Utilities

- (CGPoint)computeOrigin:(CPView)aView preferredEdge:(int)anEdge
{
    var frameView = [aView frame],
        currentView = aView,
        origin = [aView frameOrigin],
        lastView;

    // FIXME: make this work with the conversion function of CPView
    while (currentView = [currentView superview])
    {
        origin.x += [currentView frameOrigin].x;
        origin.y += [currentView frameOrigin].y;
        lastView = currentView;
    }

    origin.x += [[lastView window] frame].origin.x;
    origin.y += [[lastView window] frame].origin.y;

    // take care of the scrolling point
    if ([aView enclosingScrollView])
    {
        var offsetPoint = [[[aView enclosingScrollView] contentView] boundsOrigin];
        origin.x -= offsetPoint.x;
        origin.y -= offsetPoint.y;
    }

    return [self computeOriginFromRect:CGRectMake(origin.x, origin.y, CGRectGetWidth(frameView), CGRectGetHeight(frameView)) preferredEdge:anEdge];
}

- (CGPoint)computeOriginFromRect:(CGRect)aRect preferredEdge:(int)anEdge
{
    var nativeRect      = [[[CPApp mainWindow] platformWindow] nativeContentRect],
        originLeft      = CGPointCreateCopy(aRect.origin),
        originRight     = CGPointCreateCopy(aRect.origin),
        originTop       = CGPointCreateCopy(aRect.origin),
        originBottom    = CGPointCreateCopy(aRect.origin),
        frameSize       = [self frame].size;

    // CPMaxXEdge
    originRight.x += aRect.size.width;
    originRight.y += (aRect.size.height / 2.0) - (frameSize.height / 2.0);

    // CPMinXEdge
    originLeft.x -= frameSize.width;
    originLeft.y += (aRect.size.height / 2.0) - (frameSize.height / 2.0);

    // CPMaxYEdge
    originBottom.x += aRect.size.width / 2.0 - frameSize.width / 2.0;
    originBottom.y += aRect.size.height;

    // CPMinYEdge
    originTop.x += aRect.size.width / 2.0 - frameSize.width / 2.0;
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
        var o = origins[i],
            g = edges[i];

        [_windowView setArrowOffsetX:0];
        [_windowView setArrowOffsetY:0];
        [_windowView setPreferredEdge:g];

        if (o.x < 0)
        {
            [_windowView setArrowOffsetX:o.x];
            o.x = 0;
        }
        if (o.x + frameSize.width > nativeRect.size.width)
        {
            [_windowView setArrowOffsetX:(o.x + frameSize.width - nativeRect.size.width)];
            o.x = nativeRect.size.width - frameSize.width;
        }
        if (o.y < 0)
        {
            [_windowView setArrowOffsetY:o.y];
            o.y = 0;
        }
        if (o.y + frameSize.height > nativeRect.size.height)
        {
            [_windowView setArrowOffsetY:(frameSize.height + o.y - nativeRect.size.height)];
            o.y = nativeRect.size.height - frameSize.height;
        }

        switch (g)
        {
            case CPMaxXEdge:
                if (o.x >= (aRect.origin.x + aRect.size.width))
                    return o;
                break;
            case CPMinXEdge:
                if ((o.x + frameSize.width) <= aRect.origin.x)
                    return o;
                break;
            case CPMaxYEdge:
                if (o.y >= (aRect.origin.y + aRect.size.height))
                    return o;
                break;
            case CPMinYEdge:
                if ((o.y + frameSize.height) <= aRect.origin.y)
                    return o;
                break;
        }
    }

    [_windowView setPreferredEdge:nil];
    return requestedOrigin;
}

/*!
    Compute the frame needed to be placed to the given view
    and position the attached window according to this view (edge will be automatic)

    @param aView the view where _CPAttachedWindow must be attached
*/
- (void)positionRelativeToView:(CPView)aView
{
    [self positionRelativeToView:aView preferredEdge:nil];
}

/*!
    Compute the frame needed to be placed to the given view
    and position the attached window according to this view

    @param aView the view where _CPAttachedWindow must be attached
    @param anEdge the preferd edge to use
*/
- (void)positionRelativeToView:(CPView)aView preferredEdge:(int)anEdge
{
    var point = [self computeOrigin:aView preferredEdge:anEdge];

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [self setLevel:CPStatusWindowLevel];
    [_closeButton setFrameOrigin:CGPointMake(1.0, 1.0)];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];

    _targetView = aView;
    [_targetView addObserver:self forKeyPath:@"frame" options:nil context:nil];
}

/*!
    Position the _CPAttachedWindow relative to a given rect,
    automatically calculating the edge.

    @param aPoint the point where the _CPAttachedWindow will be attached
*/
- (void)positionRelativeToRect:(CGRect)aRect
{
    [self positionRelativeToRect:aRect preferredEdge:nil];
}

/*!
    Position the _CPAttachedWindow relative to a given rect's edge.

    @param aPoint the point where the _CPAttachedWindow will be attached
    @param anEdge the prefered edge
*/
- (void)positionRelativeToRect:(CGRect)aRect preferredEdge:(int)anEdge
{
    var point = [self computeOriginFromRect:aRect preferredEdge:anEdge];

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [self setLevel:CPStatusWindowLevel];
    [_closeButton setFrameOrigin:CGPointMake(1.0, 1.0)];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];
}

/*! @ignore */
- (void)setCSS3Property:(CPString)property value:(CPString)value
{
    _DOMElement.style['webkit' + property] = value;

    // Support other browsers here eventually
}

/*! @ignore */
- (BOOL)browserSupportsAnimation
{
    return typeof(_DOMElement.style.webkitTransition) !== "undefined";

    /*
        No others browsers supported yet.

           typeof(_DOMElement.style.MozTransition) !== "undefined" ||
           typeof(_DOMElement.style.MsTransition) !== "undefined" ||
           typeof(_DOMElement.style.OTransition) !== "undefined";
    */
}

#pragma mark -
#pragma mark Actions

/*!
    Closes the _CPAttachedWindow

    @param sender the sender of the action
*/
- (IBAction)close:(id)aSender
{
    [self close];
}


#pragma mark -
#pragma mark Overrides

/*!
    Called when the window is losing focus.
    Close the window if CPClosableOnBlurWindowMask is set.
*/
- (void)resignMainWindow
{
    if (_closeOnBlur && !_isClosing)
    {
        if (!_delegate || ((_implementedDelegateMethods & _CPAttachedWindow_attachedWindowShouldClose_)
            && [_delegate attachedWindowShouldClose:self]))
        [self close];
    }
}

/*!
    When the window appears, show animation if necessary.
    Also take this opportunity to keep track of window moves.

    @param sender the sender of the action
*/
- (IBAction)orderFront:(is)aSender
{
    [super orderFront:aSender];

    if (_animates && _browserAnimates && _shouldPerformAnimation)
    {
        var transformOrigin = "50% 100%",
            frame = [self frame],
            preferredEdge = [_windowView preferredEdge],
            posX;

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
            _DOMElement.style.opacity = 1;
            _DOMElement.style.height = frame.size.height + @"px";
            _DOMElement.style.width = frame.size.width + @"px";

            // Set up the pop-out transition
            [self setCSS3Property:@"Transform" value:@"scale(1.1)"];
            [self setCSS3Property:@"Transition" value:@"-webkit-transform 200ms ease-in"];

            var transitionEndFunction = function()
            {
                _DOMElement.removeEventListener("webkitTransitionEnd", transitionEndFunction, YES);

                // Now set up the pop-in to normal size transition.
                // Because we are watching the -webkit-transform, it will occur now.
                [self setCSS3Property:@"Transform" value:@"scale(1)"];
                [self setCSS3Property:@"Transition" value:@"-webkit-transform 50ms linear"];
            };

            _DOMElement.addEventListener("webkitTransitionEnd", transitionEndFunction, YES);
        }, 0);
    }
    else
    {
        [self setCSS3Property:@"Transition" value:@""];
        _DOMElement.style.opacity = 1;
    }

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_attachedWindowDidMove:) name:CPWindowDidMoveNotification object:self];

    _shouldPerformAnimation = NO;
    _isClosing = NO;
}

/*!
    Animate window closing.
*/
- (void)close
{
    // set a flag to avoid an infinite loop in resignMainWindow
    _isClosing = YES;

    if (_animates && _browserAnimates)
    {
        // Tell the element to fade out when the opacity changes
        [self setCSS3Property:@"Transition" value:@"opacity 250ms linear"];
        _DOMElement.style.opacity = 0;

        var transitionEndFunction = function()
        {
            _DOMElement.removeEventListener("webkitTransitionEnd", transitionEndFunction, YES);
            [self _close];
        };

        _DOMElement.addEventListener("webkitTransitionEnd", transitionEndFunction, YES);
    }
    else
    {
        [self _close];
    }
}

- (void)_close
{
    [super close];
    [_targetView removeObserver:self forKeyPath:@"frame"];

    _shouldPerformAnimation = YES;

    if (_implementedDelegateMethods & _CPAttachedWindow_attachedWindowDidClose_)
        [_delegate attachedWindowDidClose:self];
}

@end
