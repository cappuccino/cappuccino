/*
 * NSCell.j
 * nib2cib
 *
 * Portions based on NSCell.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
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

@import <Foundation/CPObject.j>

@import "NSFont.j"


@implementation NSCell : CPObject
{
    CPFont  _font;
    id      _contents;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _font = [aCoder decodeObjectForKey:@"NSFont"];
        _contents = [aCoder decodeObjectForKey:@"NSContents"];
    }
    
    return self;
}

- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return nil;
}

//- (void)encodeWithCoder:(CPCoder)aCoder
//{


- (CPFont)font
{
    return _font;
}

- (id)contents
{
    return _contents;
}

@end
