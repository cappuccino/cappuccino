/*
 * NSScrollView.j
 * nib2cib
 *
 * Created by Thomas Robinson.
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

@import <AppKit/CPScrollView.j>


@implementation CPScrollView (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        var flags = [aCoder decodeIntForKey:"NSsFlags"];
        
        _hasVerticalScroller    = Boolean(flags & (1 << 4));
        _hasHorizontalScroller  = Boolean(flags & (1 << 5));
        _autohidesScrollers     = Boolean(flags & (1 << 9));
        
        _verticalScroller   = [aCoder decodeObjectForKey:"NSVScroller"];
        _horizontalScroller = [aCoder decodeObjectForKey:"NSHScroller"];
        _contentView        = [aCoder decodeObjectForKey:"NSContentView"];
        
        //[aCoder decodeBytesForKey:"NSScrollAmts"];
        _verticalLineScroll = 10.0;
        _verticalPageScroll = 10.0;
        _horizontalLineScroll = 10.0;
        _horizontalPageScroll = 10.0;
    }
    
    return self;
}

@end

@implementation NSScrollView : CPScrollView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPScrollView class];
}

@end
