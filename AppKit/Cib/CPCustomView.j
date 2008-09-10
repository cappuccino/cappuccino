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

var CPViewAutoresizingMaskKey       = @"CPViewAutoresizingMask",
    CPViewAutoresizesSubviewsKey    = @"CPViewAutoresizesSubviews",
    CPViewBackgroundColorKey        = @"CPViewBackgroundColor",
    CPViewBoundsKey                 = @"CPViewBoundsKey",
    CPViewFrameKey                  = @"CPViewFrameKey",
    CPViewHitTestsKey               = @"CPViewHitTestsKey",
    CPViewIsHiddenKey               = @"CPViewIsHiddenKey",
    CPViewOpacityKey                = @"CPViewOpacityKey",
    CPViewSubviewsKey               = @"CPViewSubviewsKey",
    CPViewSuperviewKey              = @"CPViewSuperviewKey",
    CPViewWindowKey                 = @"CPViewWindowKey";

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

    var frame = [aCoder decodeRectForKey:CPViewFrameKey];

    // If this is just a "CPView", don't bother with any funny business, just go ahead and create it with initWithCoder:
    if (theClass == [CPView class])
        self = [[CPView alloc] initWithFrame:frame];
        
    if (self)
    {    
        [self _setWindow:[aCoder decodeObjectForKey:CPViewWindowKey]];
        
        // Since the object replacement logic hasn't had a chance to kick in yet, we need to do it manually:
        var subviews = [aCoder decodeObjectForKey:CPViewSubviewsKey],
            index = 0,
            count = subviews.length;
        
        for (; index < count; ++index)
        {
            // This is a bogus superview "CPCustomView".
            subviews[index]._superview = nil;
            
            [self addSubview:subviews[index]];
        }
        
        _autoresizingMask = [aCoder decodeIntForKey:CPViewAutoresizingMaskKey];
        _autoresizesSubviews = [aCoder decodeBoolForKey:CPViewAutoresizesSubviewsKey];
            
        _hitTests = [aCoder decodeObjectForKey:CPViewHitTestsKey];
        _isHidden = [aCoder decodeObjectForKey:CPViewIsHiddenKey];
        _opacity = [aCoder decodeIntForKey:CPViewOpacityKey];
    
        [self setBackgroundColor:[aCoder decodeObjectForKey:CPViewBackgroundColorKey]];
    }
    
    return self;
}

@end
