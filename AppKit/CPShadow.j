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
    CGSize      _offset @accessors(property=shadowOffset);
    float       _blurRadius @accessors(property=shadowBlurRadius);
    CPColor     _color @accessors(property=shadowColor);
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
- (id)_initWithOffset:(CGSize)anOffset blurRadius:(float)aBlurRadius color:(CPColor)aColor
{
    self = [super init];

    if (self)
    {
        _offset = anOffset;
        _blurRadius = aBlurRadius;
        _color = aColor;
    }

    return self;
}

- (void)set
{
   var context = [[CPGraphicsContext currentContext] graphicsPort];

   CGContextSetShadowWithColor(context, _offset, _blurRadius, _color);
}

/*!
    Returns a CSS string representation of the shadow.
*/
- (CPString)cssString
{
    return [_color cssString] + " " + ROUND(_offset.width) + @"px " + ROUND(_offset.height) + @"px " + ROUND(_blurRadius) + @"px";
}

@end
