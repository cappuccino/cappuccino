/*
 * CPClipView.j
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

@import "CPView.j"

@class CPScrollView

/*!
    @ingroup appkit
    @class CPClipView

    CPClipView allows you to define a clip rect and display only that portion of its containing view.
    It is used to hold the document view in a CPScrollView.
*/
@implementation CPClipView : CPView
{
    CPView  _documentView;
}

/*!
    Sets the document view to be \c aView.
    @param aView the new document view. It's frame origin will be changed to \c (0,0) after calling this method.
*/
- (void)setDocumentView:(CPView)aView
{
    if (_documentView == aView)
        return;

    if (_documentView)
    {
        var defaultCenter = [CPNotificationCenter defaultCenter];

        [defaultCenter
            removeObserver:self
                      name:CPViewFrameDidChangeNotification
                    object:_documentView];

        [defaultCenter
            removeObserver:self
                      name:CPViewBoundsDidChangeNotification
                    object:_documentView];

        [_documentView removeFromSuperview];
    }

    _documentView = aView;

    if (_documentView)
    {
        [self addSubview:_documentView];
        [self _observeDocumentView];
    }
}

- (void)_observeDocumentView
{
    var defaultCenter = [CPNotificationCenter defaultCenter];

    [_documentView setPostsFrameChangedNotifications:YES];
    [_documentView setPostsBoundsChangedNotifications:YES];

    [defaultCenter
        addObserver:self
           selector:@selector(viewFrameChanged:)
               name:CPViewFrameDidChangeNotification
             object:_documentView];

    [defaultCenter
        addObserver:self
           selector:@selector(viewBoundsChanged:)
               name:CPViewBoundsDidChangeNotification
             object:_documentView];
}

/*!
    Returns the document view.
*/
- (id)documentView
{
    return _documentView;
}

/*!
    Returns a new point that may be adjusted from \c aPoint
    to make sure it lies within the document view.
    @param aPoint
    @return the adjusted point
*/
- (CGPoint)constrainScrollPoint:(CGPoint)aPoint
{
    if (!_documentView)
        return CGPointMakeZero();

    var documentFrame = [_documentView frame];

    aPoint.x = MAX(0.0, MIN(aPoint.x, MAX(CGRectGetWidth(documentFrame) - CGRectGetWidth(_bounds), 0.0)));
    aPoint.y = MAX(0.0, MIN(aPoint.y, MAX(CGRectGetHeight(documentFrame) - CGRectGetHeight(_bounds), 0.0)));

    return aPoint;
}

- (void)setBoundsOrigin:(CGPoint)aPoint
{
    if (CGPointEqualToPoint(_bounds.origin, aPoint))
        return;

    [super setBoundsOrigin:aPoint];

    var superview = [self superview],

        // This is hack to avoid having to import CPScrollView.
        // FIXME: Should CPScrollView be finding out about this on its own somehow?
        scrollViewClass = objj_getClass("CPScrollView");

    if ([superview isKindOfClass:scrollViewClass])
        [superview reflectScrolledClipView:self];
}

/*!
    Scrolls the clip view to the specified point. The method
    sets its bounds origin to \c aPoint.
*/
- (void)scrollToPoint:(CGPoint)aPoint
{
    [self setBoundsOrigin:[self constrainScrollPoint:aPoint]];
}

/*!
    Handles a CPViewBoundsDidChangeNotification.
    @param aNotification the notification event
*/
- (void)viewBoundsChanged:(CPNotification)aNotification
{
    [self _constrainScrollPoint];
}

/*!
    Handles a CPViewFrameDidChangeNotification.
    @param aNotification the notification event
*/
- (void)viewFrameChanged:(CPNotification)aNotification
{
    [self _constrainScrollPoint];
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [super resizeSubviewsWithOldSize:aSize];
    [self _constrainScrollPoint];
}

- (void)_constrainScrollPoint
{
    var oldScrollPoint = [self bounds].origin;

    // Call scrollToPoint: because the current scroll point may no longer make
    // sense given the new frame of the document view.
    [self scrollToPoint:oldScrollPoint];

    // scrollToPoint: takes care of reflectScrollClipView: for us, so bail if
    // the scroll points are not equal (meaning scrollToPoint: didn't early bail).
    if (!CGPointEqualToPoint(oldScrollPoint, [self bounds].origin))
        return;

    // ... and we're in a scroll view of course.
    var superview = [self superview],

        // This is hack to avoid having to import CPScrollView.
        // FIXME: Should CPScrollView be finding out about this on its own somehow?
        scrollViewClass = objj_getClass("CPScrollView");

    if ([superview isKindOfClass:scrollViewClass])
        [superview reflectScrolledClipView:self];
}

- (BOOL)autoscroll:(CPEvent)anEvent
{
    var bounds = [self bounds],
        eventLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        superview = [self superview],
        deltaX = 0,
        deltaY = 0;

    if (CGRectContainsPoint(bounds, eventLocation))
        return NO;

    if (![superview isKindOfClass:[CPScrollView class]] || [superview hasVerticalScroller])
    {
        if (eventLocation.y < CGRectGetMinY(bounds))
            deltaY = CGRectGetMinY(bounds) - eventLocation.y;
        else if (eventLocation.y > CGRectGetMaxY(bounds))
            deltaY = CGRectGetMaxY(bounds) - eventLocation.y;
        if (deltaY < -bounds.size.height)
            deltaY = -bounds.size.height;
        if (deltaY > bounds.size.height)
            deltaY = bounds.size.height;
    }

    if (![superview isKindOfClass:[CPScrollView class]] || [superview hasHorizontalScroller])
    {
        if (eventLocation.x < CGRectGetMinX(bounds))
            deltaX = CGRectGetMinX(bounds) - eventLocation.x;
        else if (eventLocation.x > CGRectGetMaxX(bounds))
            deltaX = CGRectGetMaxX(bounds) - eventLocation.x;
        if (deltaX < -bounds.size.width)
            deltaX = -bounds.size.width;
        if (deltaX > bounds.size.width)
            deltaX = bounds.size.width;
    }

    return [self scrollToPoint:CGPointMake(bounds.origin.x - deltaX, bounds.origin.y - deltaY)];
}

@end


var CPClipViewDocumentViewKey = @"CPScrollViewDocumentView";

@implementation CPClipView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        // Don't call setDocumentView: here. It calls addSubview:, but it's A) not necessary since the
        // view hierarchy is fully encoded and B) dangerous if the subview is not fully decoded.
        _documentView = [aCoder decodeObjectForKey:CPClipViewDocumentViewKey];
        [self _observeDocumentView];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_documentView forKey:CPClipViewDocumentViewKey];
}

@end
