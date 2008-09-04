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

import "CPView.j"

#include "CoreGraphics/CGGeometry.h"


@implementation CPClipView : CPView
{
    CPView  _documentView;
}

- (void)setDocumentView:(CPView)aView
{
    if (_documentView == aView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_documentView)
    {
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
        // FIXME: remove when bounds.
        [_documentView setFrameOrigin:CGPointMake(0.0, 0.0)];
            
        [self addSubview:_documentView];
        
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
}

- (id)documentView
{
    return _documentView;
}

- (CGPoint)constrainScrollPoint:(CGPoint)aPoint
{
    var documentFrame = [_documentView frame];
    
    aPoint.x = MAX(0.0, MIN(aPoint.x, MAX(_CGRectGetWidth(documentFrame) - _CGRectGetWidth(_bounds), 0.0)));
    aPoint.y = MAX(0.0, MIN(aPoint.y, MAX(_CGRectGetHeight(documentFrame) - _CGRectGetHeight(_bounds), 0.0)));

    return aPoint;
}

- (void)setBoundsOrigin:(CGPoint)aPoint
{
    if (_CGPointEqualToPoint(_bounds.origin, aPoint))
        return;
        
    [super setBoundsOrigin:aPoint];

    var superview = [self superview];
    
    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

- (void)scrollToPoint:(CPPoint)aPoint
{
    [self setBoundsOrigin:[self constrainScrollPoint:aPoint]];
}

- (void)viewBoundsChanged:(CPNotification)aNotification
{
    var superview = [self superview];
    
    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

- (void)viewFrameChanged:(CPNotification)aNotification
{
    var superview = [self superview];

    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

@end
