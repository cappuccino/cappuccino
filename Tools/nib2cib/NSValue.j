/*
 * NSValue.j
 * nib2cib
 *
 * Created by Alexander Ljungberg.
 * Copyright 2013, SlevenBits Ltd.
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

@import <Foundation/CPException.j>
@import <Foundation/CPKeyedUnarchiver.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPRange.j>
@import <Foundation/CPValue.j>

@import <AppKit/CGGeometry.j>

var NSPointNSValueType = 1,
    NSSizeNSValueType = 2,
    NSRectNSValueType = 3,
    NSRangeNSValueType = 4;

@implementation NSValue : CPObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NS.special"];

    switch (type)
    {
        case NSPointNSValueType:
            return [[CPValue alloc] initWithJSObject:CGPointFromString([aCoder decodeObjectForKey:@"NS.pointval"])];
        case NSSizeNSValueType:
            return [[CPValue alloc] initWithJSObject:CGSizeFromString([aCoder decodeObjectForKey:@"NS.sizeval"])];
        case NSRectNSValueType:
            return [[CPValue alloc] initWithJSObject:CGRectFromString([aCoder decodeObjectForKey:@"NS.rectval"])];
        case NSRangeNSValueType:
            return [[CPValue alloc] initWithJSObject:CPMakeRange([aCoder decodeIntForKey:@"NS.rangeval.location"], [aCoder decodeIntForKey:@"NS.rangeval.length"])];
        default:
            [CPException raise:CPInvalidUnarchiveOperationException format:@"NSValue type %d is not supported by nib2cib.", type];
    }
}

@end
