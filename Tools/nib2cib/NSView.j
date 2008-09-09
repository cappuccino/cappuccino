/*
 * NSView.j
 * nib2cib
 *
 * Portions based on NSView.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
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

import <AppKit/CPView.j>


@implementation CPView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    _frame = CGRectMakeZero();
    
    if ([aCoder containsValueForKey:@"NSFrame"])
        _frame = [aCoder decodeRectForKey:@"NSFrame"];
    else if ([aCoder containsValueForKey:@"NSFrameSize"])
        _frame.size = [aCoder decodeSizeForKey:@"NSFrameSize"];   

    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        _bounds = CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame));
    
        _window = [aCoder decodeObjectForKey:@"NSWindow"];
        _superview = [aCoder decodeObjectForKey:@"NSSuperview"];
        _subviews = [aCoder decodeObjectForKey:@"NSSubviews"];

        if (!_subviews)
            _subviews = [];
        
        var vFlags = [aCoder decodeIntForKey:@"NSvFlags"];
        
        _autoresizingMask = vFlags & (0x3F << 1);
        _autoresizesSubviews = vFlags & (1 << 8);
        
        _hitTests = YES;
        _isHidden = NO;//[aCoder decodeObjectForKey:CPViewIsHiddenKey];
        _opacity = 1.0;//[aCoder decodeIntForKey:CPViewOpacityKey];
        
        if (YES/*[_superview isFlipped]*/)
        {
            var height = CGRectGetHeight([self bounds]),
                count = [_subviews count];
          
            while (count--)
            {
                var subview = _subviews[count],
                    frame = [subview frame];
                
                [subview setFrameOrigin:CGPointMake(CGRectGetMinX(frame), height - CGRectGetMaxY(frame))];
            }
        }
    }
    
    return self;
}

@end

@implementation NSView : CPView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[CPView alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPView class];
}

@end

