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

@class CPView

/* @group CPTrackingAreaOptions */
@typedef CPTrackingAreaOptions
CPTrackingMouseEnteredAndExited     = 1 << 1;
CPTrackingMouseMoved                = 1 << 2;
CPTrackingCursorUpdate              = 1 << 3;
CPTrackingActiveWhenFirstResponder  = 1 << 4;
CPTrackingActiveInKeyWindow         = 1 << 5;
CPTrackingActiveInActiveApp         = 1 << 6;
CPTrackingActiveAlways              = 1 << 7;
CPTrackingAssumeInside              = 1 << 8;
CPTrackingInVisibleRect             = 1 << 9;
CPTrackingEnabledDuringMouseDrag    = 1 << 10;

var CPTrackingAreaViewRectKey        = @"CPTrackinkAreaViewRectKey",
    CPTrackingAreaOptionsKey         = @"CPTrackingAreaOptionsKey",
    CPTrackingAreaOwnerKey           = @"CPTrackingAreaOwnerKey",
    CPTrackingAreaUserInfoKey        = @"CPTrackingAreaUserInfoKey",
    CPTrackingAreaReferencingViewKey = @"CPTrackingAreaReferencingViewKey",
    CPTrackingAreaWindowRect         = @"CPTrackingAreaWindowRect";

CPTrackingOwnerImplementsMouseEntered = 1 << 1;
CPTrackingOwnerImplementsMouseExited  = 1 << 2;
CPTrackingOwnerImplementsMouseMoved   = 1 << 3;
CPTrackingOwnerImplementsCursorUpdate = 1 << 4;

/*!
 @ingroup appkit
 
 A CPTrackingArea defines a region of view that generates mouse-tracking and
 cursor-update events when the mouse is over that region.
 */
@implementation CPTrackingArea : CPObject
{
    CGRect                  _viewRect                   @accessors(getter=rect);
    CPTrackingAreaOptions   _options                    @accessors(getter=options);
    id                      _owner                      @accessors(getter=owner);
    CPDictionary            _userInfo                   @accessors(getter=userInfo);
    
    CPView                  _referencingView            @accessors(property=view);
    CGRect                  _windowRect                 @accessors(getter=windowRect);

    unsigned                _implementedOwnerMethods    @accessors(getter=implementedOwnerMethods);
}


#pragma mark -
#pragma mark Initialization

/*! 
 Initializes and returns an object defining a region of a view to receive mouse-tracking events, mouse-moved events, cursor-update events, or possibly 
 all these events.
 */
- (CPTrackingArea)initWithRect:(CGRect)aRect options:(CPTrackingAreaOptions)options owner:(id)owner userInfo:(CPDictionary)userInfo
{
    if (owner === nil)
        [CPException raise:CPInternalInconsistencyException reason:"No owner specified"];

    if (options === 0)
        [CPException raise:CPInternalInconsistencyException reason:"Invalid CPTrackingArea options"];

    // Check options:
    // - at least one of CPTrackingMouseEnteredAndExited, CPTrackingMouseMoved, CPTrackingCursorUpdate
    // - exactly  one of CPTrackingActiveWhenFirstResponder, CPTrackingActiveInKeyWindow, CPTrackingActiveInActiveApp, CPTrackingActiveAlways
    // - no check on CPTrackingAssumeInside, CPTrackingInVisibleRect, CPTrackingEnableDuringMouseDrag

    if (!((options & CPTrackingMouseEnteredAndExited) || (options & CPTrackingMouseMoved) || (options & CPTrackingCursorUpdate)))
        [CPException raise:CPInternalInconsistencyException reason:"Invalid CPTrackingAreaOptions: must use at least one of [CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingCursorUpdate]"];

    if ((((options & CPTrackingActiveWhenFirstResponder) > 0) + ((options & CPTrackingActiveInKeyWindow) > 0) + ((options & CPTrackingActiveInActiveApp) > 0) + ((options & CPTrackingActiveAlways) > 0)) !== 1)
        [CPException raise:CPInternalInconsistencyException reason:"Tracking area options may only specify one of [CPTrackingActiveWhenFirstResponder | CPTrackingActiveInKeyWindow | CPTrackingActiveInActiveApp | CPTrackingActiveAlways]."];

    if (self = [super init])
    {
        _viewRect = aRect;
        _options  = options;
        _owner    = owner;
        _userInfo = userInfo;

        // Cache owner implemented methods

        if ([_owner respondsToSelector:@selector(mouseEntered:)])
            _implementedOwnerMethods |= CPTrackingOwnerImplementsMouseEntered;

        if ([_owner respondsToSelector:@selector(mouseExited:)])
            _implementedOwnerMethods |= CPTrackingOwnerImplementsMouseExited;

        if ([_owner respondsToSelector:@selector(mouseMoved:)])
            _implementedOwnerMethods |= CPTrackingOwnerImplementsMouseMoved;

        if ([_owner respondsToSelector:@selector(cursorUpdate:)])
            _implementedOwnerMethods |= CPTrackingOwnerImplementsCursorUpdate;
    }
    
    return self;
}


#pragma mark -
#pragma mark Implementation

- (void)_updateWindowRect
{
    _windowRect = [_referencingView convertRect:((_options & CPTrackingInVisibleRect) ? [_referencingView visibleRect] : _viewRect) toView:[[_referencingView window] _windowView]];
}

@end

#pragma mark -
#pragma mark CPCoding

@implementation CPTrackingArea (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _viewRect        = [aCoder decodeObjectForKey:CPTrackingAreaViewRectKey];
        _options         = [aCoder decodeObjectForKey:CPTrackingAreaOptionsKey];
        _owner           = [aCoder decodeObjectForKey:CPTrackingAreaOwnerKey];
        _userInfo        = [aCoder decodeObjectForKey:CPTrackingAreaUserInfoKey];
        _referencingView = [aCoder decodeObjectForKey:CPTrackingAreaReferencingViewKey];
        _windowRect      = [aCoder decodeObjectForKey:CPTrackingAreaWindowRect];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_viewRect        forKey:CPTrackingAreaViewRectKey];
    [aCoder encodeObject:_options         forKey:CPTrackingAreaOptionsKey];
    [aCoder encodeObject:_owner           forKey:CPTrackingAreaOwnerKey];
    [aCoder encodeObject:_userInfo        forKey:CPTrackingAreaUserInfoKey];
    [aCoder encodeObject:_referencingView forKey:CPTrackingAreaReferencingViewKey];
    [aCoder encodeObject:_windowRect      forKey:CPTrackingAreaWindowRect];
}

@end
