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

@import <AppKit/CPView.j>
@import <AppKit/CPEvent.j>
@import <AppKit/CPPasteboard.j>
@import <AppKit/CPImageView.j>


var CPSharedDragServer     = nil;
    
var CPDragServerView              = nil,
    CPDragServerSource            = nil,
    CPDragServerWindow            = nil,
    CPDragServerOffset            = nil,
    CPDragServerLocation          = nil,
    CPDragServerPasteboard        = nil,
    CPDragServerDestination       = nil,
    CPDragServerDraggingInfo      = nil;

var CPDragServerIsDraggingImage                           = NO,

    CPDragServerShouldSendDraggedViewMovedTo              = NO,
    CPDragServerShouldSendDraggedImageMovedTo             = NO,
    
    CPDragServerShouldSendDraggedViewEndedAtOperation     = NO,
    CPDragServerShouldSendDraggedImageEndedAtOperation    = NO;

var CPDragServerStartDragging = function(anEvent)
{
    CPDragServerUpdateDragging(anEvent);
}

var CPDragServerUpdateDragging = function(anEvent)
{
    // If this is a mouse up, then complete the drag.
    if([anEvent type] == CPLeftMouseUp)
    {
        CPDragServerLocation = [[CPDragServerDestination window] convertBridgeToBase:[[anEvent window] convertBaseToBridge:[anEvent locationInWindow]]];
        
        [CPDragServerView removeFromSuperview];
        [CPSharedDragServer._dragWindow orderOut:nil];

        if (CPDragServerDestination && 
            (![CPDragServerDestination respondsToSelector:@selector(prepareForDragOperation:)] || [CPDragServerDestination prepareForDragOperation:CPDragServerDraggingInfo]) && 
            (![CPDragServerDestination respondsToSelector:@selector(performDragOperation:)] || [CPDragServerDestination performDragOperation:CPDragServerDraggingInfo]) &&
            [CPDragServerDestination respondsToSelector:@selector(concludeDragOperation:)])
            [CPDragServerDestination concludeDragOperation:CPDragServerDraggingInfo];
 
        if (CPDragServerShouldSendDraggedImageEndedAtOperation)
            [CPDragServerSource draggedImage:[CPDragServerView image] endedAt:CPDragServerLocation operation:NO];
        else if (CPDragServerShouldSendDraggedViewEndedAtOperation)
            [CPDragServerSource draggedView:CPDragServerView endedAt:CPDragServerLocation operation:NO];
        
        CPDragServerIsDraggingImage = NO;
        CPDragServerDestination = nil;
        
        return;
    }

    // If we're not a mouse up, then we're going to want to grab the next event.
    [CPApp setCallback:CPDragServerUpdateDragging 
        forNextEventMatchingMask:CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask
        untilDate:nil inMode:0 dequeue:NO];

    var location = [anEvent locationInWindow],
        operation = 
        bridgeLocation = [[anEvent window] convertBaseToBridge:location];

    // We have to convert base to bridge since the drag event comes from the source window, not the drag window.
    var draggingDestination = [[CPDOMWindowBridge sharedDOMWindowBridge] _dragHitTest:bridgeLocation pasteboard:CPDragServerPasteboard];
    
    CPDragServerLocation = [[CPDragServerDestination window] convertBridgeToBase:bridgeLocation];
    
    if(draggingDestination != CPDragServerDestination) 
    {
        if (CPDragServerDestination && [CPDragServerDestination respondsToSelector:@selector(draggingExited:)])
            [CPDragServerDestination draggingExited:CPDragServerDraggingInfo];
        
        CPDragServerDestination = draggingDestination;
        
        if (CPDragServerDestination && [CPDragServerDestination respondsToSelector:@selector(draggingEntered:)])
            [CPDragServerDestination draggingEntered:CPDragServerDraggingInfo];
    }
    else if (CPDragServerDestination && [CPDragServerDestination respondsToSelector:@selector(draggingUpdated:)])
        [CPDragServerDestination draggingUpdated:CPDragServerDraggingInfo];
    
    location.x -= CPDragServerOffset.x;
    location.y -= CPDragServerOffset.y;
    
    [CPDragServerView setFrameOrigin:location];
    
    if (CPDragServerShouldSendDraggedImageMovedTo)
        [CPDragServerSource draggedImage:[CPDragServerView image] movedTo:location];
    else if (CPDragServerShouldSendDraggedViewMovedTo)
        [CPDragServerSource draggedView:CPDragServerView movedTo:location];
}

/*
    CPDraggingInfo is a container of information about a specific dragging session.
    @ignore
*/
@implementation CPDraggingInfo : CPObject
{
    CPWindow    _window;
}

/*
    Initializes the receiver with the window
*/
- (id)initWithWindow:(CPWindow)aWindow
{
    self = [super init];
    
    if (self)
        _window = aWindow;
    
    return this;
}

- (id)draggingSource
{
    return CPDragServerSource;
}

- (CPPoint)draggingLocation
{
    return CPDragServerLocation;
}

- (CPPasteboard)draggingPasteboard
{
    return CPDragServerPasteboard;
}

- (CPImage)draggedImage
{
    return [CPDragServerView image];
}

- (CPView)draggedView
{
    return CPDragServerView;
}

@end

@implementation CPDragServer : CPObject
{
    CPWindow    _dragWindow;
    CPImageView _imageView;
}

/*
    Private Objective-J/Cappuccino method
    @ignore
*/
+ (void)initialize
{
    if (self != [CPDragServer class])
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
        _dragWindow = [[CPWindow alloc] initWithContentRect:CPRectMakeZero() styleMask:CPBorderlessWindowMask];
        [_dragWindow setLevel:CPDraggingWindowLevel];
    }
    
    return self;
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
    @param slideBack if <code>YES</code>, <code>aView</code> slides back to
    its origin on a failed drop
*/
- (void)dragView:(CPView)aView fromWindow:(CPWindow)aWindow at:(CGPoint)viewLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    var eventLocation = [anEvent locationInWindow];
    
    CPDragServerView = aView;
    CPDragServerSource = aSourceObject;
    CPDragServerWindow = aWindow;
    CPDragServerOffset = CPPointMake(eventLocation.x - viewLocation.x, eventLocation.y - viewLocation.y);
    CPDragServerPasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];//aPasteboard;

    [_dragWindow setFrameSize:CGSizeMakeCopy([[CPDOMWindowBridge sharedDOMWindowBridge] frame].size)];
    [_dragWindow orderFront:self];

    [aView setFrameOrigin:viewLocation];
    [[_dragWindow contentView] addSubview:aView];

    if (CPDragServerIsDraggingImage)
    {
        if ([CPDragServerSource respondsToSelector:@selector(draggedImage:beganAt:)])
            [CPDragServerSource draggedImage:[aView image] beganAt:viewLocation];
        
        CPDragServerShouldSendDraggedImageMovedTo = [CPDragServerSource respondsToSelector:@selector(draggedImage:movedTo:)];
        CPDragServerShouldSendDraggedImageEndedAtOperation = [CPDragServerSource respondsToSelector:@selector(draggedImage:endAt:operation:)];
        
        CPDragServerShouldSendDraggedViewMovedTo = NO;
        CPDragServerShouldSendDraggedViewEndedAtOperation = NO;
    }
    else
    {
        if ([CPDragServerSource respondsToSelector:@selector(draggedView:beganAt:)])
            [CPDragServerSource draggedView:aView beganAt:viewLocation];
     
        CPDragServerShouldSendDraggedViewMovedTo = [CPDragServerSource respondsToSelector:@selector(draggedView:movedTo:)];
        CPDragServerShouldSendDraggedViewEndedAtOperation = [CPDragServerSource respondsToSelector:@selector(draggedView:endedAt:operation:)];
        

        CPDragServerShouldSendDraggedImageMovedTo = NO;
        CPDragServerShouldSendDraggedImageEndedAtOperation = NO;
    }

    CPDragServerStartDragging(anEvent);
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
    @param slideBack if <code>YES</code>, <code>aView</code> slides back to
    its origin on a failed drop
*/
- (void)dragImage:(CPImage)anImage fromWindow:(CPWindow)aWindow at:(CGPoint)imageLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    CPDragServerIsDraggingImage = YES;
    
    if (!_imageView)
        _imageView = [[CPImageView alloc] initWithFrame:CPRectMakeZero()];
    
    [_imageView setImage:anImage];
    [_imageView setFrameSize:CGSizeMakeCopy([anImage size])];
    
    [self dragView:_imageView fromWindow:aWindow at:imageLocation offset:mouseOffset event:anEvent pasteboard:aPasteboard source:aSourceObject slideBack:slideBack];
}

@end

@implementation CPView (CPDraggingAdditions)

/* @ignore */
- (CPView)_dragHitTest:(CPPoint)aPoint pasteboard:(CPPasteboard)aPasteboard
{
    if(!CPRectContainsPoint(_frame, aPoint) || self == CPDragServerView)
        return nil;
    
    var view = nil,
        i = [_subviews count],
        adjustedPoint = CPPointMake(aPoint.x - CPRectGetMinX(_frame), aPoint.y - CPRectGetMinY(_frame));

    while (i--)
        if (view = [_subviews[i] _dragHitTest:adjustedPoint pasteboard:aPasteboard])
            return view;

    if ([aPasteboard availableTypeFromArray:_registeredDraggedTypes])
        return self;
    
    return nil;
}

@end
