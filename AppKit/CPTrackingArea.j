/*
 * CPTrackingArea.j
 * AppKit
 *
 * Created by Didier Korthoudt.
 * Copyright 2015, Cappuccino Project.
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

@import <Foundation/Foundation.j>
@import "CPView.j"

@typedef CPTrackingAreaOptions
CPTrackingMouseEnteredAndExited     = 1 << 1,
CPTrackingMouseMoved                = 1 << 2,
CPTrackingCursorUpdate              = 1 << 3,
CPTrackingActiveWhenFirstResponder  = 1 << 4,
CPTrackingActiveInKeyWindow         = 1 << 5,
CPTrackingActiveInActiveApp         = 1 << 6, // both mean the same in cappuccino context
CPTrackingActiveAlways              = 1 << 6,
CPTrackingAssumeInside              = 1 << 7,
CPTrackingInVisibleRect             = 1 << 8,
CPTrackingEnabledDuringMouseDrag    = 1 << 9;

var CPTrackingAreaRectKey            = @"CPTrackinkAreaRectKey",
    CPTrackingAreaOptionsKey         = @"CPTrackingAreaOptionsKey",
    CPTrackingAreaOwnerKey           = @"CPTrackingAreaOwnerKey",
    CPTrackingAreaUserInfoKey        = @"CPTrackingAreaUserInfoKey",
    CPTrackingAreaReferencingViewKey = @"CPTrackingAreaReferencingViewKey";


/*!
 @ingroup appkit
 
 A CPTrackingArea defines a region of view that generates mouse-tracking and
 cursor-update events when the mouse is over that region.
 */
@implementation CPTrackingArea : CPObject
{
    CGRect                  _rect           @accessors(getter=rect);
    CPTrackingAreaOptions   _options        @accessors(getter=options);
    id                      _owner          @accessors(getter=owner);
    CPDictionary            _userInfo       @accessors(getter=userInfo);
    
    CPView                  _referencingView;
}


#pragma mark -
#pragma mark Initialization

/*! Initializes and returns an object defining a region of a view to receive mouse-tracking events, mouse-moved events, cursor-update events, or possibly all these events.
 */
- (CPTrackingArea)initWithRect:(CGRect)aRect options:(CPTrackingAreaOptions)options owner:(id)owner userInfo:(CPDictionary)userInfo
{
    if (self = [super init])
    {
        if (!(options > 0))
            [CPException raise:CPInternalInconsistencyException reason:"Invalid CPTrackingArea options"];

        // Check options:
        // - at least one in CPTrackingMouseEnteredAndExited, CPTrackingMouseMoved, CPTrackingCursorUpdate
        // - exactly  one in CPTrackingActiveWhenFirstResponder, CPTrackingActiveInKeyWindow, CPTrackingActiveAlways
        // - no check on CPTrackingAssumeInside, CPTrackingInVisibleRect, CPTrackingEnableDuringMouseDrag
        
        if (!((options & CPTrackingMouseEnteredAndExited) || (options & CPTrackingMouseMoved) || (options & CPTrackingCursorUpdate)))
            [CPException raise:CPInternalInconsistencyException reason:"You must at least select a type of event message"];
        
        if ((((options & CPTrackingActiveWhenFirstResponder) > 0) + ((options & CPTrackingActiveInKeyWindow) > 0) + ((options & CPTrackingActiveAlways) > 0)) != 1)
            [CPException raise:CPInternalInconsistencyException reason:"You must select one and only one scope of tracking"];

        _rect     = aRect;
        _options  = options;
        _owner    = owner;
        _userInfo = userInfo;
        
        _referencingView = nil;
    }
    
    return self;
}


#pragma mark -
#pragma mark Implementation

- (void)_setReferencingView:(CPView)aView
{
    _referencingView = aView;
}

- (CPView)_referencingView
{
    return _referencingView;
}

- (BOOL)_isReferenced
{
    return (!!_referencingView);
}

#pragma mark -
#pragma mark CPCoding

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _rect            = [aCoder decodeObjectForKey:CPTrackingAreaRectKey];
        _options         = [aCoder decodeObjectForKey:CPTrackingAreaOptionsKey];
        _owner           = [aCoder decodeObjectForKey:CPTrackingAreaOwnerKey];
        _userInfo        = [aCoder decodeObjectForKey:CPTrackingAreaUserInfoKey];
        _referencingView = [aCoder decodeObjectForKey:CPTrackingAreaReferencingViewKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_rect            forKey:CPTrackingAreaRectKey];
    [aCoder encodeObject:_options         forKey:CPTrackingAreaOptionsKey];
    [aCoder encodeObject:_owner           forKey:CPTrackingAreaOwnerKey];
    [aCoder encodeObject:_userInfo        forKey:CPTrackingAreaUserInfoKey];
    [aCoder encodeObject:_referencingView forKey:CPTrackingAreaReferencingViewKey];
}

@end
