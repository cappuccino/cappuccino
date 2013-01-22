/*
 * CPColorSpace.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2012, SlevenBits Ltd.
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

var sRGBColorSpace = nil;

/*!
    Represent color spaces.
*/
@implementation CPColorSpace : CPObject
{
    CGColorSpace _cgColorSpace;
}

/*!
    Return an object representing the standard sRGB color space.
*/
+ (CPColorSpace)sRGBColorSpace
{
    if (!sRGBColorSpace)
        sRGBColorSpace = [[self alloc] initWithCGColorSpace:CGColorSpaceCreateDeviceRGB()];
    return sRGBColorSpace;
}

- (id)initWithCGColorSpace:(CGColorSpace)cgColorSpace
{
    if (self = [super init])
    {
        _cgColorSpace = cgColorSpace;
    }

    return self;
}

/*!
    Return a Core Graphics color space representing the receiver.
*/
- (CGColorSpace)CGColorSpace
{
    return _cgColorSpace;
}

@end

