/*
 * CPPlatformString.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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


@implementation CPBasePlatformString : CPObject
{
}

+ (void)bootstrap
{
}

+ (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
    return CGSizeMakeZero();
}

@end

#if PLATFORM(DOM)
#include "DOM/CPPlatformString.j"
#else
@implementation CPPlatformString : CPBasePlatformString

+ (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
    return CGSizeMakeZero();
}

+ (CPDictionary)metricsOfFont:(CPFont)aFont
{
    return @{
            @"ascender": 0,
            @"descender": 0,
            @"lineHeight": 0,
        };
}

@end
#endif
