/*
 * CPShadow.j
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

import <Foundation/CPObject.j>

@implementation CPShadow : CPObject
{
    CPSize      _offset;
    float       _blurRadius;
    CPColor     _color;
    
    CPString    _cssString;
}

+ (id)shadowWithOffset:(CPSize)anOffset blurRadius:(float)aBlurRadius color:(CPColor)aColor
{
    return [[CPShadow alloc] _initWithOffset:anOffset blurRadius:aBlurRadius color:aColor];
}

- (id)_initWithOffset:(CPSize)anOffset blurRadius:(float)aBlurRadius color:(CPColor)aColor
{
    self = [super init];
    
    if (self)
    {
        _offset = anOffset;
        _blurRadius = aBlurRadius;
        _color = aColor;
        
        _cssString = [_color cssString] + " " + Math.round(anOffset.width) + @"px " + Math.round(anOffset.height) + @"px " + Math.round(_blurRadius) + @"px";
    }
    
    return self;
}

- (CPSize)shadowOffset
{
    return _offset;
}

- (float)shadowBlurRadius
{
    return _blurRadius;
}

- (CPColor)shadowColor
{
    return _color;
}

- (CPString)cssString
{
    return _cssString;
}

@end