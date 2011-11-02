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


/*!
    @ignore

    This is a simple attached window like the one that pops up
    when you double click on a meeting in iCal
*/
@implementation _CPAttachedWindow : CPWindow
{
    BOOL            _animates           @accessors(property=animates);
    id              _targetView         @accessors(property=targetView);
    int             _appearance         @accessors(getter=appearance);

    BOOL            _closeOnBlur;
    BOOL            _isClosed;
    BOOL            _shouldPerformAnimation;
    CPButton        _closeButton;
    float           _animationDuration;
}

/*!
    override default windowView class loader

    @param aStyleMask the window mask
    @return the windowView class
*/

#pragma mark -
#pragma mark Class methods

+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    return _CPAttachedWindowView;
}


#pragma mark -
#pragma mark Initialization

/*!
    Create and init a _CPAttachedWindow with given size of and view

    @param aSize the size of the attached window
    @param aView the target view
    @return ready to use _CPAttachedWindow
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView
{
    return [_CPAttachedWindow attachedWindowWithSize:aSize forView:aView styleMask:nil];
}

/*!
    Create and init a _CPAttachedWindow with given size of and view

    @param aSize the size of the attached window
    @param aView the target view
    @return ready to use _CPAttachedWindow
    @param styleMask the window style mask  (combine CPClosableWindowMask and CPClosableOnBlurWindowMask)
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView styleMask:(int)aMask
{
    var attachedWindow = [[_CPAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, aSize.width, aSize.height) styleMask:aMask];

    [attachedWindow attachToView:aView];

    return attachedWindow;
}

/*!
    Create and init a _CPAttachedWindow with given frame

    @param aFrame the frame of the attached window
    @return ready to use _CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame
{
    self = [self initWithContentRect:aFrame styleMask:nil]
    return self;
}

/*!
    Create and init a _CPAttachedWindow with given frame

    @param aFrame the frame of the attached window
    @param styleMask the window style mask  (combine CPClosableWindowMask and CPClosableOnBlurWindowMask)
    @return ready to use _CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithContentRect:aFrame styleMask:aStyleMask])
    {
        _animates                   = YES;
        _animates                   = YES;
        _animationDuration          = 150;
        _closeOnBlur                = (aStyleMask & CPClosableOnBlurWindowMask);
        _isClosed                   = NO;
        _shouldPerformAnimation     = _animates;

        [self setLevel:CPStatusWindowLevel];
        [self setMovableByWindowBackground:YES];
        [self setHasShadow:NO];

        _DOMElement.style.WebkitBackfaceVisibility = "hidden";
        _DOMElement.style.WebkitTransitionProperty = "-webkit-transform, opacity";
        _DOMElement.style.WebkitTransitionDuration = _animationDuration + "ms";

        [_windowView setNeedsDisplay:YES];
    }

    return self;
}

#pragma mark -
#pragma mark Getters / Setters

- (void)setAppearance:(int)anAppearance
{
    if (_appearance == anAppearance)
        return;

    [_windowView setAppearance:anAppearance];
}

#pragma mark -
#pragma mark Observer

/*!
    Update the _CPAttachedWindow frame if a resize event is observed

*/
- (void)observeValueForKeyPath:(CPString)aPath ofObject:(id)anObject change:(CPDictionary)theChange context:(void)aContext
{
    if ([aPath isEqual:@"frame"])
    {
        // @TODO: not recompute everything, just compute the move offset
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
        [_closeButton setFrameOrigin:CPPointMake(1.0, 1.0)];
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPWindowDidMoveNotification object:self];
    }
}


#pragma mark -
#pragma mark Utilities

- (CPPoint)computeOrigin:(CPView)aView preferredEdge:(int)anEdge
{
    var frameView = [aView frame],
        currentView = aView,
        origin = [aView frameOrigin],
        lastView;

    // if somebody succeed to use the conversion function of CPView
    // to get this working, please do.
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

    return [self computeOriginFromRect:CPRectMake(origin.x, origin.y, CPRectGetWidth(frameView), CPRectGetHeight(frameView)) preferredEdge:anEdge];
}

- (CPPoint)computeOriginFromRect:(CPRect)aRect preferredEdge:(int)anEdge
{
    var nativeRect      = [[[CPApp mainWindow] platformWindow] nativeContentRect],
        originLeft      = CPPointCreateCopy(aRect.origin),
        originRight     = CPPointCreateCopy(aRect.origin),
        originTop       = CPPointCreateCopy(aRect.origin),
        originBottom    = CPPointCreateCopy(aRect.origin);

    // CPMaxXEdge
    originRight.x += aRect.size.width;
    originRight.y += (aRect.size.height / 2.0) - (CPRectGetHeight([self frame]) / 2.0)

    // CPMinXEdge
    originLeft.x -= CPRectGetWidth([self frame]);
    originLeft.y += (aRect.size.height / 2.0) - (CPRectGetHeight([self frame]) / 2.0)

    // CPMaxYEdge
    originBottom.x += aRect.size.width / 2.0 - CPRectGetWidth([self frame]) / 2.0;
    originBottom.y += aRect.size.height;

    // CPMinYEdge
    originTop.x += aRect.size.width / 2.0 - CPRectGetWidth([self frame]) / 2.0;
    originTop.y -= CPRectGetHeight([self frame]);

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
        if (o.x + CPRectGetWidth([self frame]) > nativeRect.size.width)
        {
            [_windowView setArrowOffsetX:(o.x + CPRectGetWidth([self frame]) - nativeRect.size.width)];
            o.x = nativeRect.size.width - CPRectGetWidth([self frame]);
        }
        if (o.y < 0)
        {
            [_windowView setArrowOffsetY:o.y];
            o.y = 0;
        }
        if (o.y + CPRectGetHeight([self frame]) > nativeRect.size.height)
        {
            [_windowView setArrowOffsetY:(CPRectGetHeight([self frame]) + o.y - nativeRect.size.height)];
            o.y = nativeRect.size.height - CPRectGetHeight([self frame]);
        }

        switch (g)
        {
            case CPMaxXEdge:
                if (o.x >= (aRect.origin.x + aRect.size.width))
                    return o;
                break;
            case CPMinXEdge:
                if ((o.x + _frame.size.width) <= aRect.origin.x)
                    return o;
                break;
            case CPMaxYEdge:
                if (o.y >= (aRect.origin.y + aRect.size.height))
                    return o;
                break;
            case CPMinYEdge:
                if ((o.y + _frame.size.height) <= aRect.origin.y)
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
    [_closeButton setFrameOrigin:CPPointMake(1.0, 1.0)];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];

    _targetView = aView;
    [_targetView addObserver:self forKeyPath:@"frame" options:nil context:nil];
}

/*!
    Position the _CPAttachedWindow to a random point

    @param aPoint the point where the _CPAttachedWindow will be attached
*/
- (void)positionRelativeToRect:(CPRect)aRect
{
    [self positionRelativeToRect:aRect preferredEdge:nil]
}

/*!
    Position the _CPAttachedWindow to a random point

    @param aPoint the point where the _CPAttachedWindow will be attached
    @param anEdge the prefered edge
*/
- (void)positionRelativeToRect:(CPRect)aRect preferredEdge:(int)anEdge
{
    var point = [self computeOriginFromRect:aRect preferredEdge:anEdge];

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [self setLevel:CPStatusWindowLevel];
    [_closeButton setFrameOrigin:CPPointMake(1.0, 1.0)];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];
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
    Called when the window is loowing focus and close the window if CPClosableOnBlurWindowMask is setted
*/
- (void)resignMainWindow
{
    if (_closeOnBlur && !_isClosed)
    {
        if (!_delegate || ([_delegate respondsToSelector:@selector(didAttachedWindowShouldClose:)]
            && [_delegate didAttachedWindowShouldClose:self]))
        [self close];
    }
}

/*!
    Order front the window as usual and add listener for CPWindowDidMoveNotification

    @param sender the sender of the action
*/
- (IBAction)orderFront:(is)aSender
{
    [super orderFront:aSender];

    var tranformOrigin = "50% 100%";

    switch ([_windowView preferredEdge])
    {
        case CPMaxYEdge:
            var posX = 50 + (([_windowView arrowOffsetX] * 100) / _frame.size.width);
            tranformOrigin = posX + "% 0%"; // 50 0
            break;
        case CPMinYEdge:
            var posX = 50 + (([_windowView arrowOffsetX] * 100) / _frame.size.width);
            tranformOrigin = posX + "% 100%"; // 50 100
            break;
        case CPMinXEdge:
            var posY = 50 + (([_windowView arrowOffsetY] * 100) / _frame.size.height);
            tranformOrigin = "100% " + posY + "%"; // 100 50
            break;
        case CPMaxXEdge:
            var posY = 50 + (([_windowView arrowOffsetY] * 100) / _frame.size.height);
            tranformOrigin = "0% "+ posY + "%"; // 0 50
            break;
    }

    // @TODO: implement for FF
    if (_animates && _shouldPerformAnimation && typeof(_DOMElement.style.WebkitTransform) != "undefined")
    {
        _DOMElement.style.opacity = 0;
        _DOMElement.style.WebkitTransform = "scale(0)";
        _DOMElement.style.WebkitTransformOrigin = tranformOrigin;
        window.setTimeout(function(){
            _DOMElement.style.height = _frame.size.height + @"px";
            _DOMElement.style.width = _frame.size.width + @"px";
            _DOMElement.style.opacity = 1;
            _DOMElement.style.WebkitTransform = "scale(1.1)";
            var transitionEndFunction = function(){
                _DOMElement.style.WebkitTransform = "scale(1)";
                _DOMElement.removeEventListener("webkitTransitionEnd", transitionEndFunction, YES);
            };
            _DOMElement.addEventListener("webkitTransitionEnd", transitionEndFunction, YES)
        },0);
    }

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_attachedWindowDidMove:) name:CPWindowDidMoveNotification object:self];

    _shouldPerformAnimation = NO;
    _isClosed = NO;
}

/*!
    Close the windo with animation
*/
- (void)close
{
    // set a close flag to avoid infinite loop
    _isClosed = YES;

    if (_animates && typeof(_DOMElement.style.WebkitTransform) != "undefined")
    {
        _DOMElement.style.opacity = 0;
        var transitionEndFunction = function(){
                [super close];
            _DOMElement.removeEventListener("webkitTransitionEnd", transitionEndFunction, YES);
        };
        _DOMElement.addEventListener("webkitTransitionEnd", transitionEndFunction, YES);
    }
    else
        [super close];

    [_targetView removeObserver:self forKeyPath:@"frame"];

    _shouldPerformAnimation = _animates;

    if (_delegate && [_delegate respondsToSelector:@selector(didAttachedWindowClose:)])
        [_delegate didAttachedWindowClose:self];
}

@end
