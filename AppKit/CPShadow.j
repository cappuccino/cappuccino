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

@import <Foundation/CPObject.j>


/*!
    @deprecated
    @class CPShadow

    Instances of this class contain the attributes of a drop shadow used in Cappuccino.
*/
@implementation CPShadow : CPObject
{
    CPSize      _offset;
    float       _blurRadius;
    CPColor     _color;

    CPString    _cssString;
}

/*!
    Creates a shadow with the specified attributes.
    @param anOffset the shadow's offset
    @param aBlurRadius the shadow's blur radius
    @param aColor the shadow's color
    @return the new shadow
*/
+ (id)shadowWithOffset:(CGSize)anOffset blurRadius:(float)aBlurRadius color:(CPColor)aColor
{
    return [[CPShadow alloc] _initWithOffset:anOffset blurRadius:aBlurRadius color:aColor];
}

/* @ignore */
- (id)_initWithOffset:(CPSize)anOffset blurRadius:(float)aBlurRadius color:(CPColor)aColor
{
    self = [super init];

    if (self)
    {
        _offset = anOffset;
        _blurRadius = aBlurRadius;
        _color = aColor;

        _cssString = [_color cssString] + " " + ROUND(anOffset.width) + @"px " + ROUND(anOffset.height) + @"px " + ROUND(_blurRadius) + @"px";
    }

    return self;
}

/*!
    Returns the shadow's offset.
*/
- (CGSize)shadowOffset
{
    return _offset;
}

/*!
    Returns the shadow's blur radius
*/
- (float)shadowBlurRadius
{
    return _blurRadius;
}

/*!
    Returns the shadow's color.
*/
- (CPColor)shadowColor
{
    return _color;
}

/*!
    Returns a CSS string representation of the shadow.
*/
- (CPString)cssString
{
    return _cssString;
}

@end