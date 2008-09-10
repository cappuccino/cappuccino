/*
 * CPCustomView.j
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

/* @ignore */
@implementation CPCustomView : CPView
{
    CPString    _className;
}

@end

var CPCustomViewClassNameKey    = @"CPCustomViewClassNameKey";

@implementation CPCustomView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
   _className = [aCoder decodeObjectForKey:CPCustomViewClassNameKey];
    
    var theClass = CPClassFromString(_className);
    
    // If we don't have this class, just use CPView.
    // FIXME: Should we instead throw an exception?
    if (!theClass)
        theClass = [CPView class];
        
    // If this is just a "CPView", don't bother with any funny business, just go ahead and create it with initWithCoder:
    if (theClass == [CPView class])
        self = [[CPView alloc] initWithCoder:aCoder];
    
    return self;
    // If not, fall back to initWithFrame:
/*
    var frame = [aCoder decodeRectForKey:CPViewFrameKey];

    self = [[theClass alloc] initWithFrame:frame];
    
    if (self)
    {
        _bounds = [aCoder decodeRectForKey:CPViewBoundsKey];

        _window = [aCoder decodeObjectForKey:CPViewWindowKey];
        _subviews = [aCoder decodeObjectForKey:CPViewSubviewsKey];
        _superview = [aCoder decodeObjectForKey:CPViewSuperviewKey];
        
        _autoresizingMask = [aCoder decodeIntForKey:CPViewAutoresizingMaskKey];
        _autoresizesSubviews = [aCoder decodeBoolForKey:CPViewAutoresizesSubviewsKey];
        
        // FIXME: UGH!!!!
        _index = [aCoder decodeIntForKey:FIXME_indexKey];
        
        _hitTests = [aCoder decodeObjectForKey:CPViewHitTestsKey];
        _isHidden = [aCoder decodeObjectForKey:CPViewIsHiddenKey];
        _opacity = [aCoder decodeIntForKey:CPViewOpacityKey];
    
        [self setBackgroundColor:[aCoder decodeObjectForKey:CPViewBackgroundColorKey]];

    }
    
    return self;*/
}

@end
