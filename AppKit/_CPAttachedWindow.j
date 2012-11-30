/*
 * _CPAttachedWindow.j
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
    _CPAttachedWindow_attachedWindowDidClose_       = 1 << 1,
    _CPAttachedWindow_attachedWindowDidShow_        = 1 << 2;


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
    BOOL            _isClosing          @accessors(property=isClosing);

    BOOL            _closeOnBlur;
    BOOL            _browserAnimates;
    BOOL            _shouldPerformAnimation;
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
    return [_CPAttachedWindow attachedWindowWithSize:aSize forView:aView styleMask:0];
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
    var attachedWindow = [[_CPAttachedWindow alloc] initWithContentRect:_CGRectMake(0.0, 0.0, aSize.width, aSize.height) styleMask:aMask];

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
    return [self initWithContentRect:aFrame styleMask:0];
}

/*!
    Designated initializer. Create and init a _CPAttachedWindow with the given frame and style mask.

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

    if ([_delegate respondsToSelector:@selector(attachedWindowShouldClose:)])
        _implementedDelegateMethods |= _CPAttachedWindow_attachedWindowShouldClose_;

    if ([_delegate respondsToSelector:@selector(attachedWindowDidClose:)])
        _implementedDelegateMethods |= _CPAttachedWindow_attachedWindowDidClose_;

    if ([_delegate respondsToSelector:@selector(attachedWindowDidShow:)])
        _implementedDelegateMethods |= _CPAttachedWindow_attachedWindowDidShow_;
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
        var edge = [_windowView preferredEdge];

        [self positionRelativeToRect:nil ofView:_targetView preferredEdge:edge];
    }
}


#pragma mark -
#pragma mark Utilities

- (CGPoint)computeOriginFromRect:(CGRect)aRect ofView:(CPView)positioningView preferredEdge:(int)anEdge
{
    var mainWindow      = [positioningView window],
        platformWindow  = [mainWindow platformWindow],
        nativeRect      = [platformWindow nativeContentRect],
        baseOrigin      = [positioningView convertPointToBase:aRect.origin],
        platformOrigin  = [mainWindow convertBaseToPlatformWindow:baseOrigin],
        platformRect    = _CGRectMake(platformOrigin.x, platformOrigin.y, aRect.size.width, aRect.size.height),
        originLeft      = _CGPointCreateCopy(platformOrigin),
        originRight     = _CGPointCreateCopy(platformOrigin),
        originTop       = _CGPointCreateCopy(platformOrigin),
        originBottom    = _CGPointCreateCopy(platformOrigin),
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

        if (origin.x < 0)
        {
            [_windowView setArrowOffsetX:origin.x];
            origin.x = 0;
        }

        if (origin.x + frameSize.width > nativeRect.size.width)
        {
            [_windowView setArrowOffsetX:(origin.x + frameSize.width - nativeRect.size.width)];
            origin.x = nativeRect.size.width - frameSize.width;
        }

        if (origin.y < 0)
        {
            [_windowView setArrowOffsetY:origin.y];
            origin.y = 0;
        }

        if (origin.y + frameSize.height > nativeRect.size.height)
        {
            [_windowView setArrowOffsetY:(frameSize.height + origin.y - nativeRect.size.height)];
            origin.y = nativeRect.size.height - frameSize.height;
        }

        switch (edge)
        {
            case CPMaxXEdge:
                if (origin.x >= _CGRectGetMaxX(platformRect))
                    return origin;
                break;

            case CPMinXEdge:
                if ((origin.x + frameSize.width) <= platformRect.origin.x)
                    return origin;
                break;

            case CPMaxYEdge:
                if (origin.y >= _CGRectGetMaxY(platformRect))
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
    and position the attached window according to this view (edge will be automatic)

    @param aView the view where _CPAttachedWindow must be attached
*/
- (void)positionRelativeToView:(CPView)aView
{
    [self positionRelativeToRect:nil ofView:aView preferredEdge:nil];
}

/*!
    Position the _CPAttachedWindow relative to a given rect's edge.

    @param aRect the rect relative to which the attached window will be positioned
    @param positioningView the view to which the attached window is attached
    @param anEdge the prefered edge
*/
- (void)positionRelativeToRect:(CGRect)aRect ofView:(CPView)positioningView preferredEdge:(int)anEdge
{
    if (!aRect || _CGRectIsEmpty(aRect))
        aRect = [positioningView bounds];

    var point = [self computeOriginFromRect:aRect ofView:positioningView preferredEdge:anEdge];

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [self setLevel:CPStatusWindowLevel];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];

    if (positioningView !== _targetView)
    {
        [_targetView removeObserver:self forKeyPath:@"frame"];
        _targetView = positioningView;
        [_targetView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
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
*/
- (void)resignMainWindow
{
    if (_closeOnBlur && !_isClosing)
    {
        if (!_delegate ||
            ((_implementedDelegateMethods & _CPAttachedWindow_attachedWindowShouldClose_) &&
             [_delegate attachedWindowShouldClose:self]))
        {
            [self close];
        }
    }
}

/*!
    When the window appears, show animation if necessary.
    Also take this opportunity to keep track of window moves.

    @param sender the sender of the action
*/
- (IBAction)orderFront:(is)aSender
{
    if (![self isMainWindow])
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

                    var transitionCompleteFunction = function()
                    {
                        _DOMElement.removeEventListener("webkitTransitionEnd", transitionCompleteFunction, YES);
                        if (_implementedDelegateMethods & _CPAttachedWindow_attachedWindowDidShow_)
                             [_delegate attachedWindowDidShow:self];
                    }

                    _DOMElement.addEventListener("webkitTransitionEnd", transitionCompleteFunction, YES);
                };

                _DOMElement.addEventListener("webkitTransitionEnd", transitionEndFunction, YES);
            }, 0);
        }
        else
        {
            [self setCSS3Property:@"Transition" value:@""];
            _DOMElement.style.opacity = 1;
        }
    }

    _shouldPerformAnimation = NO;
    _isClosing = NO;
}

/*!
    Animate window closing.
*/
- (void)close
{
    if (![self isVisible])
        return;

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
    _isClosing = NO;

    if (_implementedDelegateMethods & _CPAttachedWindow_attachedWindowDidClose_)
        [_delegate attachedWindowDidClose:self];
}

@end
