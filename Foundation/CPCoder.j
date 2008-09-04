/*
 * CPCoder.j
 * Foundation
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

import "CPObject.j"
import "CPException.j"

@implementation CPCoder : CPObject
{

}

-(BOOL)allowsKeyedCoding
{
   return NO;
}

-(void)encodeValueOfObjCType:(const char *)aType at:(const void *)anObject
{
   NSInvalidAbstractInvocation();
}

-(void)encodeDataObject:(CPData)aData
{
   NSInvalidAbstractInvocation();
}

-(void)encodeObject:(id)anObject
{
//   [self encodeValueOfObjCType:@encode(id) at:object];
}

- (void)encodePoint:(CPPoint)aPoint
{
    [self encodeNumber:aPoint.x];
    [self encodeNumber:aPoint.y];
}

- (void)encodeRect:(CPRect)aRect
{
    [self encodePoint:aRect.origin];
    [self encodeSize:aRect.size];
}

- (void)encodeSize:(CPSize)aSize
{
    [self encodeNumber:aSize.width];
    [self encodeNumber:aSize.height];
}

-(void)encodePropertyList:(id)aPropertyList
{
//   [self encodeValueOfObjCType:@encode(id) at:&propertyList];
}

-(void)encodeRootObject:(id)anObject
{
   [self encodeObject:anObject];
}


-(void)encodeBycopyObject:(id)anObject
{
   [self encodeObject:object];
}


-(void)encodeConditionalObject:(id)anObject
{
   [self encodeObject:object];
}

@end

@implementation CPObject (CPCoding)

- (id)awakeAfterUsingCoder:(CPCoder)aDecoder
{
    return self;
}

@end
