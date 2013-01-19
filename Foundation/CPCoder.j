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

@import "CPException.j"
@import "CPObject.j"

@global _CPRaiseInvalidAbstractInvocation;

/*!
    @class CPCoder
    @ingroup foundation
    @brief Defines methods for use when archiving & restoring (enc/decoding).

    Top-level class defining methods for use when archiving (encoding) objects to a byte array
    or file, and when restoring (decoding) objects.
*/
@implementation CPCoder : CPObject
{
}

/*!
    Returns a flag indicating whether the receiver supports keyed coding. The default implementation returns
    \c NO. Subclasses supporting keyed coding must override this to return \c YES.
*/
- (BOOL)allowsKeyedCoding
{
   return NO;
}

/*!
    Encodes a structure or object of a specified type. Usually this
    is used for primitives though it can be used for objects as well.
    Subclasses must override this method.
    @param aType the structure or object type
    @param anObject the object to be encoded
*/
- (void)encodeValueOfObjCType:(CPString)aType at:(id)anObject
{
   _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Encodes a data object. Subclasses must override this method.
    @param aData the object to be encoded.
*/
- (void)encodeDataObject:(CPData)aData
{
   _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Encodes an object. Subclasses must override this method.
    @param anObject the object to be encoded
*/
- (void)encodeObject:(id)anObject
{
//   [self encodeValueOfObjCType:@encode(id) at:object];
}

/*!
    Encodes a point
    @param aPoint the point to be encoded.
*/
- (void)encodePoint:(CGPoint)aPoint
{
    [self encodeNumber:aPoint.x];
    [self encodeNumber:aPoint.y];
}

/*!
    Encodes a CGRect
    @param aRect the rectangle to be encoded.
*/
- (void)encodeRect:(CGRect)aRect
{
    [self encodePoint:aRect.origin];
    [self encodeSize:aRect.size];
}

/*!
    Encodes a CGSize
    @param aSize the size to be encoded
*/
- (void)encodeSize:(CGSize)aSize
{
    [self encodeNumber:aSize.width];
    [self encodeNumber:aSize.height];
}

/*!
    Encodes a property list. Not yet implemented.
    @param aPropertyList the property list to be encoded
*/
- (void)encodePropertyList:(id)aPropertyList
{
//   [self encodeValueOfObjCType:@encode(id) at:&propertyList];
}

/*!
    Encodes the root object of a group of Obj-J objects.
    @param rootObject the root object to be encoded.
*/
- (void)encodeRootObject:(id)anObject
{
   [self encodeObject:anObject];
}

/*!
    Encodes an object.
    @param anObject the object to be encoded.
*/
- (void)encodeBycopyObject:(id)anObject
{
   [self encodeObject:anObject];
}

/*!
    Encodes an object.
    @param anObject the object to be encoded.
*/
- (void)encodeConditionalObject:(id)anObject
{
   [self encodeObject:anObject];
}

@end

@implementation CPObject (CPCoding)

/*!
    Called after an object is unarchived in case a different object should be used in place of it.
    The default method returns \c self. Interested subclasses should override this.
    @param aDecoder
    @return the original object or it's substitute.
*/
- (id)awakeAfterUsingCoder:(CPCoder)aDecoder
{
    return self;
}

@end
