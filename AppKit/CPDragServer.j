/*
 * CPDragServer.j
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

@import "CPDragServer_Constants.j"
@import "CPEvent.j"
@import "CPImageView.j"
@import "CPPasteboard.j"
@import "CPView.j"
@import "CPWindow_Constants.j"

@class CPWindow  // This file is imported by CPWindow.j
@class _CPDOMDataTransferPasteboard

@global CPApp

#define DRAGGING_WINDOW(anObject) ([anObject isKindOfClass:[CPWindow class]] ? anObject : [anObject window])

var CPDragServerPreviousEvent = nil,
    CPDragServerPeriodicUpdateInterval = 0.05;

var CPSharedDragServer = nil;

var CPDragServerSource             = nil,
    CPDragServerDraggingInfo       = nil;

/*
    CPDraggingInfo is a container of information about a specific dragging session.
    @ignore
*/
@implementation CPDraggingInfo : CPObject
{
}

- (CPPasteboard)draggingPasteboard
{
    if ([CPPlatform supportsDragAndDrop])
        return [_CPDOMDataTransferPasteboard DOMDataTransferPasteboard];

    return [[CPDragServer sharedDragServer] draggingPasteboard];
}

- (id)draggingSource
{
    return [[CPDragServer sharedDragServer] draggingSource];
}

/*
- (unsigned)draggingSourceOperationMask
*/

- (CGPoint)draggingLocation
{
    return [[CPDragServer sharedDragServer] draggingLocation];
}

- (CPWindow)draggingDestinationWindow
{
    return DRAGGING_WINDOW([[CPDragServer sharedDragServer] draggingDestination]);
}

- (CPImage)draggedImage
{
    return [[self draggedView] image];
}

- (CGPoint)draggedImageLocation
{
    return [self draggedViewLocation];
}

- (CPView)draggedView
{
    return [[CPDragServer sharedDragServer] draggedView];
}

- (CGPoint)draggedViewLocation
{
    var dragServer = [CPDragServer sharedDragServer];

    return [DRAGGING_WINDOW([dragServer draggingDestination]) convertPlatformWindowToBase:[[dragServer draggedView] frame].origin];
}

@end

var CPDraggingSource_draggedImage_movedTo_          = 1 << 0,
    CPDraggingSource_draggedImage_endedAt_operation_  = 1 << 1,
    CPDraggingSource_draggedView_movedTo_           = 1 << 2,
    CPDraggingSource_draggedView_endedAt_operation_ = 1 << 3;

@implementation CPDragServer : CPObject
{
    BOOL            _isDragging @accessors(readonly, getter=isDragging);

    CPWindow        _draggedWindow @accessors(readonly, getter=draggedWindow);
    CPView          _draggedView @accessors(readonly, getter=draggedView);
    CPImageView     _imageView;

    BOOL            _isDraggingImage;

    CGSize          _draggingOffset @accessors(readonly, getter=draggingOffset);

    CPPasteboard    _draggingPasteboard @accessors(readonly, getter=draggingPasteboard);

    id              _draggingSource @accessors(readonly, getter=draggingSource);
    unsigned        _implementedDraggingSourceMethods;

    CGPoint         _draggingLocation;
    id              _draggingDestination;
    BOOL            _draggingDestinationWantsPeriodicUpdates;

    CGPoint         _startDragLocation;
    BOOL            _shouldSlideBack;
    unsigned        _dragOperation;

    CPTimer         _draggingUpdateTimer;
}

/*
    Private Objective-J/Cappuccino method
    @ignore
*/
+ (void)initialize
{
    if (self !== [CPDragServer class])
        return;

    CPDragServerDraggingInfo = [[CPDraggingInfo alloc] init];
}

+ (CPDragServer)sharedDragServer
{
    if (!CPSharedDragServer)
        CPSharedDragServer = [[CPDragServer alloc] init];

    return CPSharedDragServer;
}

/*
    @ignore
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _draggedWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessWindowMask];

        [_draggedWindow setLevel:CPDraggingWindowLevel];
    }

    return self;
}

- (id)draggingDestination
{
    return _draggingDestination;
}

- (CGPoint)draggingLocation
{
    return _draggingLocation
}

- (void)draggingStartedInPlatformWindow:(CPPlatformWindow)aPlatformWindow globalLocation:(CGPoint)aLocation
{
    if (_isDraggingImage)
    {
        if ([_draggingSource respondsToSelector:@selector(draggedImage:beganAt:)])
            [_draggingSource draggedImage:[_draggedView image] beganAt:aLocation];
    }
    else
    {
        if ([_draggingSource respondsToSelector:@selector(draggedView:beganAt:)])
            [_draggingSource draggedView:_draggedView beganAt:aLocation];
    }

    if (![CPPlatform supportsDragAndDrop])
        [_draggedWindow orderFront:self];
}

- (void)draggingSourceUpdatedWithGlobalLocation:(CGPoint)aGlobalLocation
{
    if (![CPPlatform supportsDragAndDrop])
    {
        var frame = [_draggedWindow frame];
        frame.origin.x = aGlobalLocation.x - _draggingOffset.width;
        frame.origin.y = aGlobalLocation.y - _draggingOffset.height;
        [_draggedWindow _setFrame:frame display:YES animate:NO constrainWidth:NO constrainHeight:NO];
    }

    if (_implementedDraggingSourceMethods & CPDraggingSource_draggedImage_movedTo_)
        [_draggingSource draggedImage:[_draggedView image] movedTo:aGlobalLocation];

    else if (_implementedDraggingSourceMethods & CPDraggingSource_draggedView_movedTo_)
        [_draggingSource draggedView:_draggedView movedTo:aGlobalLocation];
}

- (CPDragOperation)draggingUpdatedInPlatformWindow:(CPPlatformWindow)aPlatformWindow location:(CGPoint)aLocation
{
    [_draggingUpdateTimer invalidate];
    _draggingUpdateTimer = nil;

    var dragOperation = CPDragOperationCopy,
    // We have to convert base to bridge since the drag event comes from the source window, not the drag window.
        draggingDestination = [aPlatformWindow _dragHitTest:aLocation pasteboard:[CPDragServerDraggingInfo draggingPasteboard]];

    if (draggingDestination)
        _draggingLocation = [DRAGGING_WINDOW(draggingDestination) convertPlatformWindowToBase:aLocation];

    if (draggingDestination !== _draggingDestination)
    {
        if ([_draggingDestination respondsToSelector:@selector(draggingExited:)])
            [_draggingDestination draggingExited:CPDragServerDraggingInfo];

        _draggingDestination = draggingDestination;

        if ([_draggingDestination respondsToSelector:@selector(wantsPeriodicDraggingUpdates)])
            _draggingDestinationWantsPeriodicUpdates = [_draggingDestination wantsPeriodicDraggingUpdates];
        else
            _draggingDestinationWantsPeriodicUpdates = YES;

        if ([_draggingDestination respondsToSelector:@selector(draggingEntered:)])
            dragOperation = [_draggingDestination draggingEntered:CPDragServerDraggingInfo];
    }
    else if ([_draggingDestination respondsToSelector:@selector(draggingUpdated:)])
        dragOperation = [_draggingDestination draggingUpdated:CPDragServerDraggingInfo];

    if (!_draggingDestination)
        dragOperation = CPDragOperationNone;
    else
    {
        if (_draggingDestinationWantsPeriodicUpdates)
            _draggingUpdateTimer = [CPTimer scheduledTimerWithTimeInterval:CPDragServerPeriodicUpdateInterval
                                                                    target:self
                                                                  selector:@selector(_sendPeriodicDraggingUpdate:)
                                                                  userInfo:@{ "platformWindow":aPlatformWindow, "location":aLocation }
                                                                   repeats:NO];

        var scrollView = [_draggingDestination isKindOfClass:[CPView class]] ? [_draggingDestination enclosingScrollView] : nil;
        if (scrollView)
        {
            var contentView = [scrollView contentView],
                bounds = [contentView bounds],
                insetBounds = CGRectInset(bounds, 30, 30),
                eventLocation = [contentView convertPoint:_draggingLocation fromView:nil],
                deltaX = 0,
                deltaY = 0;

            if (!CGRectContainsPoint(insetBounds, eventLocation))
            {
                if ([scrollView hasVerticalScroller])
                {
                    if (eventLocation.y < CGRectGetMinY(insetBounds))
                        deltaY = CGRectGetMinY(insetBounds) - eventLocation.y;
                    else if (eventLocation.y > CGRectGetMaxY(insetBounds))
                        deltaY = CGRectGetMaxY(insetBounds) - eventLocation.y;
                    if (deltaY < -insetBounds.size.height)
                        deltaY = -insetBounds.size.height;
                    if (deltaY > insetBounds.size.height)
                        deltaY = insetBounds.size.height;
                }

                if ([scrollView hasHorizontalScroller])
                {
                    if (eventLocation.x < CGRectGetMinX(insetBounds))
                        deltaX = CGRectGetMinX(insetBounds) - eventLocation.x;
                    else if (eventLocation.x > CGRectGetMaxX(insetBounds))
                        deltaX = CGRectGetMaxX(insetBounds) - eventLocation.x;
                    if (deltaX < -insetBounds.size.width)
                        deltaX = -insetBounds.size.width;
                    if (deltaX > insetBounds.size.width)
                        deltaX = insetBounds.size.width;
                }

                var scrollPoint = CGPointMake(bounds.origin.x - deltaX, bounds.origin.y - deltaY);

                [contentView scrollToPoint:scrollPoint];
                [[scrollView _headerView] scrollPoint:scrollPoint];

            }
        }
    }

    return dragOperation;
}

- (void)_sendPeriodicDraggingUpdate:(CPTimer)aTimer
{
    var userInfo = [aTimer userInfo];
    _dragOperation = [self draggingUpdatedInPlatformWindow:[userInfo objectForKey:@"platformWindow"]
                                                  location:[userInfo objectForKey:@"location"]];
}

- (void)draggingEndedInPlatformWindow:(CPPlatformWindow)aPlatformWindow globalLocation:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    [_draggingUpdateTimer invalidate];
    _draggingUpdateTimer = nil;

    [_draggedView removeFromSuperview];

    if (![CPPlatform supportsDragAndDrop])
        [_draggedWindow orderOut:self];

    if (_implementedDraggingSourceMethods & CPDraggingSource_draggedImage_endedAt_operation_)
        [_draggingSource draggedImage:[_draggedView image] endedAt:aLocation operation:anOperation];
    else if (_implementedDraggingSourceMethods & CPDraggingSource_draggedView_endedAt_operation_)
        [_draggingSource draggedView:_draggedView endedAt:aLocation operation:anOperation];

    _isDragging = NO;
}

- (void)performDragOperationInPlatformWindow:(CPPlatformWindow)aPlatformWindow
{
    if (_draggingDestination &&
        (![_draggingDestination respondsToSelector:@selector(prepareForDragOperation:)] || [_draggingDestination prepareForDragOperation:CPDragServerDraggingInfo]) &&
        (![_draggingDestination respondsToSelector:@selector(performDragOperation:)] || [_draggingDestination performDragOperation:CPDragServerDraggingInfo]) &&
        [_draggingDestination respondsToSelector:@selector(concludeDragOperation:)])
        [_draggingDestination concludeDragOperation:CPDragServerDraggingInfo];
}

/*!
    Initiates a drag session.
    @param aView the view being dragged
    @param aWindow the window where the drag source is
    @param viewLocation
    @param mouseOffset
    @param anEvent
    @param aPasteboard the pasteboard that contains the drag data
    @param aSourceObject the object where the drag started
    @param slideBack if \c YES, \c aView slides back to
    its origin on a failed drop
*/
- (void)dragView:(CPView)aView fromWindow:(CPWindow)aWindow at:(CGPoint)viewLocation offset:(CGSize)mouseOffset event:(CPEvent)mouseDownEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    _isDragging = YES;

    _draggedView = aView;
    _draggingPasteboard = aPasteboard || [CPPasteboard pasteboardWithName:CPDragPboard];
    _draggingSource = aSourceObject;
    _draggingDestination = nil;
    _shouldSlideBack = slideBack;

    // The offset is based on the distance from where we want the view to be initially from where the mouse is initially
    // Hence the use of mouseDownEvent's location and view's location in global coordinates.
    var mouseDownWindow = [mouseDownEvent window],
        mouseDownEventLocation = [mouseDownEvent locationInWindow];

    if (mouseDownEventLocation)
    {
        if (mouseDownWindow)
            mouseDownEventLocation = [mouseDownWindow convertBaseToGlobal:mouseDownEventLocation];

        _draggingOffset = CGSizeMake(mouseDownEventLocation.x - viewLocation.x, mouseDownEventLocation.y - viewLocation.y);
    }
    else
        _draggingOffset = CGSizeMakeZero();

    if ([CPPlatform isBrowser])
        [_draggedWindow setPlatformWindow:[aWindow platformWindow]];

    [aView setFrameOrigin:CGPointMakeZero()];

    var mouseLocation = [CPEvent mouseLocation],
        viewSize = [aView frameSize],
        startDragLocationX = mouseLocation.x - _draggingOffset.width,
        startDragLocationY = mouseLocation.y - _draggingOffset.height,
        draggedWindowFrame = CGRectMake(startDragLocationX, startDragLocationY, viewSize.width, viewSize.height);

    // Place it where the mouse pointer is.
    _startDragLocation = CGPointMake(startDragLocationX, startDragLocationY);

    [_draggedWindow _setFrame:draggedWindowFrame display:YES animate:NO constrainWidth:NO constrainHeight:NO];

    [[_draggedWindow contentView] addSubview:aView];

    _implementedDraggingSourceMethods = 0;

    if (_draggedView === _imageView)
    {
        if ([_draggingSource respondsToSelector:@selector(draggedImage:movedTo:)])
            _implementedDraggingSourceMethods |= CPDraggingSource_draggedImage_movedTo_;

        if ([_draggingSource respondsToSelector:@selector(draggedImage:endedAt:operation:)])
            _implementedDraggingSourceMethods |= CPDraggingSource_draggedImage_endedAt_operation_;
    }
    else
    {
        if ([_draggingSource respondsToSelector:@selector(draggedView:movedTo:)])
            _implementedDraggingSourceMethods |= CPDraggingSource_draggedView_movedTo_;

        if ([_draggingSource respondsToSelector:@selector(draggedView:endedAt:operation:)])
            _implementedDraggingSourceMethods |= CPDraggingSource_draggedView_endedAt_operation_;
    }

    if (![CPPlatform supportsDragAndDrop])
    {
        [self draggingStartedInPlatformWindow:[aWindow platformWindow] globalLocation:mouseLocation];
        [self trackDragging:mouseDownEvent];
    }
}

/*!
    Initiates a drag session.
    @param anImage the image to be dragged
    @param aWindow the source window of the drag session
    @param imageLocation
    @param mouseOffset
    @param anEvent
    @param aPasteboard the pasteboard where the drag data is located
    @param aSourceObject the object where the drag started
    @param slideBack if \c YES, \c aView slides back to
    its origin on a failed drop
*/
- (void)dragImage:(CPImage)anImage fromWindow:(CPWindow)aWindow at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    _isDraggingImage = YES;

    var imageSize = [anImage size];

    if (!_imageView)
        _imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, imageSize.width, imageSize.height)];

    [_imageView setImage:anImage];

    [self dragView:_imageView fromWindow:aWindow at:imageLocation offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

- (void)trackDragging:(CPEvent)anEvent
{
    var type = [anEvent type],
        platformWindow = [_draggedWindow platformWindow],
        platformWindowLocation = [[anEvent window] convertBaseToPlatformWindow:[anEvent locationInWindow]];

    if (type === CPLeftMouseUp)
    {
        // Make sure we do not finalize (cancel) the drag if the last drag update was disallowed
        if (_dragOperation !== CPDragOperationNone)
            [self performDragOperationInPlatformWindow:platformWindow];

        [self draggingEndedInPlatformWindow:platformWindow globalLocation:platformWindowLocation operation:_dragOperation];

        // Stop tracking events.
        return;
    }
    else if (type === CPKeyDown)
    {
        var characters = [anEvent characters];

        if (characters === CPEscapeFunctionKey)
        {
            _dragOperation = CPDragOperationNone;
            [self draggingEndedInPlatformWindow:platformWindow globalLocation:CGPointMakeZero() operation:_dragOperation];
            return;
        }
    }
    else
    {
        [self draggingSourceUpdatedWithGlobalLocation:platformWindowLocation];
        _dragOperation = [self draggingUpdatedInPlatformWindow:platformWindow location:platformWindowLocation];
    }

    // If we're not a mouse up, then we're going to want to grab the next event.
    [CPApp setTarget:self selector:@selector(trackDragging:)
        forNextEventMatchingMask:CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask | CPKeyDownMask
        untilDate:nil inMode:0 dequeue:YES];
}

@end
