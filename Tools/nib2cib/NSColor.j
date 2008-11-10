/*
 * NSColor.j
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

@import <AppKit/CPColor.j>
 
var NSUnknownColorSpaceModel    = -1,
    NSGrayColorSpaceModel       = 0,
    NSRGBColorSpaceModel        = 1,
    NSCMYKColorSpaceModel       = 2,
    NSLABColorSpaceModel        = 3,
    NSDeviceNColorSpaceModel    = 4,
    NSIndexedColorSpaceModel    = 5,
    NSPatternColorSpaceModel    = 6;

@implementation CPColor (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    //var colorSpace = [aCoder decodeIntForKey:@"NSColorSpace"];
    return self = [CPColor blueColor];
}

@end

@implementation NSColor : CPColor
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPColor class];
}

@end
