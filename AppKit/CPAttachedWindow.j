/*
 * CPAttachedWindow.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2009, Antoine Mercadal
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

@import "CPButton.j"
@import "CPColor.j"
@import "CPImage.j"
@import "CPImageView.j"
@import "CPView.j"
@import "CPWindow.j"


CPClosableOnBlurWindowMask      = 1 << 4;
CPAttachedWhiteWindowMask       = 1 << 25;
CPAttachedBlackWindowMask       = 1 << 26;

/*! @ingroup appkit
    This is a simple attached window like the one that pops up
    when you double click on a meeting in iCal
*/
@implementation CPAttachedWindow : CPWindow
{
    id              _targetView         @accessors(property=targetView);
    BOOL            _isClosed;
    BOOL            _closeOnBlur;

    CPButton        _closeButton;
}

/*! override default windowView class loader
    @param aStyleMask the window mask
    @return the windowView class
*/

+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    if (aStyleMask & CPAttachedWhiteWindowMask)
        return _CPAttachedWindowViewWhite;
    
    return _CPAttachedWindowViewBlack;
}


#pragma mark -
#pragma mark Initialization

/*! create and init a CPAttachedWindow with given size of and view
    @param aSize the size of the attached window
    @param aView the target view
    @return ready to use CPAttachedWindow
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView
{
    return [CPAttachedWindow attachedWindowWithSize:aSize forView:aView styleMask:nil];
}

/*! create and init a CPAttachedWindow with given size of and view
    @param aSize the size of the attached window
    @param aView the target view
    @return ready to use CPAttachedWindow
    @param styleMask the window style mask  (combine CPClosableWindowMask, CPAttachedWhiteWindowMask, CPAttachedBlackWindowMask and CPClosableOnBlurWindowMask)
*/
+ (id)attachedWindowWithSize:(CGSize)aSize forView:(CPView)aView styleMask:(int)aMask
{
    var attachedWindow = [[CPAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, aSize.width, aSize.height) styleMask:aMask];

    [attachedWindow attachToView:aView];

    return attachedWindow;
}

/*! create and init a CPAttachedWindow with given frame
    @param aFrame the frame of the attached window
    @return ready to use CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame
{
    self = [self initWithContentRect:aFrame styleMask:CPAttachedWhiteWindowMask]
    return self;
}

/*! create and init a CPAttachedWindow with given frame
    @param aFrame the frame of the attached window
    @param styleMask the window style mask  (combine CPClosableWindowMask, CPAttachedWhiteWindowMask, CPAttachedBlackWindowMask and CPClosableOnBlurWindowMask)
    @return ready to use CPAttachedWindow
*/
- (id)initWithContentRect:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithContentRect:aFrame styleMask:aStyleMask])
    {
        _isClosed = NO;

        var bundle = [CPBundle bundleForClass:[self class]],
            buttonClose = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAttachedWindow/attached-window-button-close.png"] size:CPSizeMake(15.0, 15.0)],
            buttonClosePressed = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAttachedWindow/attached-window-button-close-highlighted.png"] size:CPSizeMake(15.0, 15.0)];

        if (aStyleMask & CPClosableWindowMask)
        {
            _closeButton = [[CPButton alloc] initWithFrame:CPRectMake(8.0, 1.0, 14.0, 14.0)];
            [_closeButton setImageScaling:CPScaleProportionally];
            [_closeButton setBordered:NO];
            [_closeButton setImage:buttonClose]; // this avoid the blinking..
            [_closeButton setValue:buttonClose forThemeAttribute:@"image"];
            [_closeButton setValue:buttonClosePressed forThemeAttribute:@"image" inState:CPThemeStateHighlighted];
            [_closeButton setTarget:self];
            [_closeButton setAction:@selector(close:)];
            [[self contentView] addSubview:_closeButton];
        }

        _closeOnBlur = (aStyleMask & CPClosableOnBlurWindowMask);

        [self setLevel:CPStatusWindowLevel];
        [self setMovableByWindowBackground:YES];
        [self setHasShadow:NO];

        [_windowView setNeedsDisplay:YES];
    }

    return self;
}

#pragma mark -
#pragma mark Window actions

/*! called when the window is loowing focus and close the window
    if CPClosableOnBlurWindowMask is setted
*/
- (void)resignMainWindow
{
    if (_closeOnBlur && !_isClosed)
    {
        // set a close flag to avoid infinite loop
        _isClosed = YES;
        [self close];

        if (_delegate && [_delegate respondsToSelector:@selector(didAttachedWindowClose:)])
            [_delegate didAttachedWindowClose:self];
    }
}

#pragma mark -
#pragma mark Utilities

- (CPPoint)computeOrigin:(CPView)aView gravity:(int)gravity
{
    var frameView = [aView frame],
        currentView = aView,
        origin = [aView frameOrigin],
        nativeRect = [[[CPApp mainWindow] platformWindow] nativeContentRect],
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

    var originLeft      = CPPointCreateCopy(origin),
        originRight     = CPPointCreateCopy(origin),
        originTop       = CPPointCreateCopy(origin),
        originBottom    = CPPointCreateCopy(origin);

    // CPAttachedWindowGravityRight
    originRight.x += CPRectGetWidth(frameView);
    originRight.y += (CPRectGetHeight(frameView) / 2.0) - (CPRectGetHeight([self frame]) / 2.0)

    // CPAttachedWindowGravityLeft
    originLeft.x -= CPRectGetWidth([self frame]);
    originLeft.y += (CPRectGetHeight(frameView) / 2.0) - (CPRectGetHeight([self frame]) / 2.0)

    // CPAttachedWindowGravityBottom
    originBottom.x += CPRectGetWidth(frameView) / 2.0 - CPRectGetWidth([self frame]) / 2.0;
    originBottom.y += CPRectGetHeight(frameView);

    // CPAttachedWindowGravityTop
    originTop.x += CPRectGetWidth(frameView) / 2.0 - CPRectGetWidth([self frame]) / 2.0;
    originTop.y -= CPRectGetHeight([self frame]);


    if (gravity === CPAttachedWindowGravityAuto)
    {
        var frameCopy = CPRectCreateCopy([self frame]);

        nativeRect.origin.x = 0.0;
        nativeRect.origin.y = 0.0;

        var tests = [originRight, originLeft, originTop, originBottom];

        gravity = CPAttachedWindowGravityRight;
        for (var i = 0; i < tests.length; i++)
        {
            frameCopy.origin = tests[i];

            if (CPRectContainsRect(nativeRect, frameCopy))
            {
                if (CPPointEqualToPoint(tests[i], originRight))
                {
                    gravity = CPAttachedWindowGravityRight
                    break;
                }
                else if (CPPointEqualToPoint(tests[i], originLeft))
                {
                    gravity = CPAttachedWindowGravityLeft
                    break;
                }
                else if (CPPointEqualToPoint(tests[i], originTop))
                {
                    gravity = CPAttachedWindowGravityUp
                    break;
                }
                else if (CPPointEqualToPoint(tests[i], originBottom))
                {
                    gravity = CPAttachedWindowGravityDown
                    break;
                }
            }
        }
    }

    var originToBeReturned;
    switch (gravity)
    {
        case CPAttachedWindowGravityRight:
            originToBeReturned = originRight;
            break;
        case CPAttachedWindowGravityLeft:
            originToBeReturned = originLeft;
            break;
        case CPAttachedWindowGravityDown:
            originToBeReturned = originBottom;
            break;
        case CPAttachedWindowGravityUp:
            originToBeReturned = originTop;
            break;
    }

    [_windowView setGravity:gravity];

    var o = originToBeReturned;
    if (o.x < 0)
    {
        [_windowView setGravity:nil];
        o.x = 0;
    }
    if (o.x + CPRectGetWidth([self frame]) > nativeRect.size.width)
    {
        [_windowView setGravity:nil];
        o.x = nativeRect.size.width - CPRectGetWidth([self frame]);
    }
    if (o.y < 0)
    {
        [_windowView setGravity:nil];
        o.y = 0;
    }
    if (o.y + CPRectGetHeight([self frame]) > nativeRect.size.height)
    {
        [_windowView setGravity:nil];
        o.y = nativeRect.size.height - CPRectGetHeight([self frame]);
    }

    return originToBeReturned;
}


#pragma mark -
#pragma mark Notification handlers

- (void)_attachedWindowDidMove:(CPNotification)aNotification
{
    if ([_windowView isMouseDownPressed])
    {
        [_windowView hideCursor];
        [self setLevel:CPNormalWindowLevel];
        [_closeButton setFrameOrigin:CPPointMake(1.0, 1.0)];
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPWindowDidMoveNotification object:self];
    }
}


#pragma mark -
#pragma mark Utilities

/*! compute the frame needed to be placed to the given view
    and position the attached window according to this view (gravity will be CPAttachedWindowGravityAuto)
    @param aView the view where CPAttachedWindow must be attached
*/
- (void)positionRelativeToView:(CPView)aView
{
    [self positionRelativeToView:aView gravity:CPAttachedWindowGravityAuto];
}

/*! compute the frame needed to be placed to the given view
    and position the attached window according to this view
    @param aView the view where CPAttachedWindow must be attached
    @param aGravity the gravity to use
*/
- (void)positionRelativeToView:(CPView)aView gravity:(int)aGravity
{
    var frameView = [aView frame],
        posX = frameView.origin.x + CPRectGetWidth(frameView),
        posY = frameView.origin.y + (CPRectGetHeight(frameView) / 2.0) - (CPRectGetHeight([self frame]) / 2.0),
        point = [self computeOrigin:aView gravity:aGravity];

    point.y = MAX(point.y, 0);

    [self setFrameOrigin:point];
    [_windowView showCursor];
    [self setLevel:CPStatusWindowLevel];
    [_closeButton setFrameOrigin:CPPointMake(1.0, 1.0)];
    [_windowView setNeedsDisplay:YES];
    [self makeKeyAndOrderFront:nil];
}

/*! set the _targetView and attach the CPAttachedWindow to it
    @param aView the view where CPAttachedWindow must be attached
*/
- (void)attachToView:(CPView)aView
{
    _targetView = aView;
    [self positionRelativeToView:_targetView];

    [_targetView addObserver:self forKeyPath:@"window.frame" options:nil context:nil];
}


#pragma mark -
#pragma mark Actions

/*! closes the CPAttachedWindow
    @param sender the sender of the action
*/
- (IBAction)close:(id)aSender
{
    [self close];

    [_targetView removeObserver:self forKeyPath:@"window.frame"];

    if (_delegate && [_delegate respondsToSelector:@selector(didAttachedWindowClose:)])
        [_delegate didAttachedWindowClose:self];
}

/*! order front the window as usual and add listener for CPWindowDidMoveNotification
    @param sender the sender of the action
*/
- (IBAction)makeKeyAndOrderFront:(is)aSender
{
    [super makeKeyAndOrderFront:aSender];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_attachedWindowDidMove:) name:CPWindowDidMoveNotification object:self];
}

/*! update the CPAttachedWindow frame if a resize event is observed

*/
- (void)observeValueForKeyPath:(CPString)aPath ofObject:(id)anObject change:(CPDictionary)theChange context:(void)aContext
{
    if ([aPath isEqual:@"window.frame"])
    {
        [self positionRelativeToView:_targetView];
    }
}

@end