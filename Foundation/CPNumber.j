/*
 * CPNumber.j
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
@import "CPNull.j"
@import "CPObject.j"
@import "CPObjJRuntime.j"

#define CAST_TO_INT(x) ((x) >= 0 ? Math.floor((x)) : Math.ceil((x)))

var CPNumberUIDs    = new CFMutableDictionary();

/*!
    @class CPNumber
    @ingroup foundation
    @brief A bridged object to native Javascript numbers.

    This class primarily exists for source compatibility. The JavaScript
    \c Number type can be changed on the fly based on context,
    so there is no need to call any of these methods.

    In other words, native JavaScript numbers are bridged to CPNumber,
    so you can use them interchangeably (including operators and methods).
*/
@implementation CPNumber : CPObject

+ (id)alloc
{
    var result = new Number();
    result.isa = [self class];
    return result;
}

+ (id)numberWithBool:(BOOL)aBoolean
{
    return aBoolean ? 1 : 0;
}

+ (id)numberWithChar:(char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

+ (id)numberWithDouble:(double)aDouble
{
    return aDouble;
}

+ (id)numberWithFloat:(float)aFloat
{
    return aFloat;
}

+ (id)numberWithInt:(int)anInt
{
    return anInt;
}

+ (id)numberWithLong:(long)aLong
{
    return aLong;
}

+ (id)numberWithLongLong:(long long)aLongLong
{
    return aLongLong;
}

+ (id)numberWithShort:(short)aShort
{
    return aShort;
}

+ (id)numberWithUnsignedChar:(unsigned char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

+ (id)numberWithUnsignedInt:(unsigned)anUnsignedInt
{
    return anUnsignedInt;
}

+ (id)numberWithUnsignedLong:(unsigned long)anUnsignedLong
{
    return anUnsignedLong;
}
/*
+ (id)numberWithUnsignedLongLong:(unsigned long long)anUnsignedLongLong
{
    return anUnsignedLongLong;
}
*/
+ (id)numberWithUnsignedShort:(unsigned short)anUnsignedShort
{
    return anUnsignedShort;
}

- (id)initWithBool:(BOOL)aBoolean
{
    return aBoolean;
}

- (id)initWithChar:(char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

- (id)initWithDouble:(double)aDouble
{
    return aDouble;
}

- (id)initWithFloat:(float)aFloat
{
    return aFloat;
}

- (id)initWithInt:(int)anInt
{
    return anInt;
}

- (id)initWithLong:(long)aLong
{
    return aLong;
}

- (id)initWithLongLong:(long long)aLongLong
{
    return aLongLong;
}

- (id)initWithShort:(short)aShort
{
    return aShort;
}

- (id)initWithUnsignedChar:(unsigned char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

- (id)initWithUnsignedInt:(unsigned)anUnsignedInt
{
    return anUnsignedInt;
}

- (id)initWithUnsignedLong:(unsigned long)anUnsignedLong
{
    return anUnsignedLong;
}
/*
- (id)initWithUnsignedLongLong:(unsigned long long)anUnsignedLongLong
{
    return anUnsignedLongLong;
}
*/
- (id)initWithUnsignedShort:(unsigned short)anUnsignedShort
{
    return anUnsignedShort;
}

- (CPString)UID
{
    var UID = CPNumberUIDs.valueForKey(self);

    if (!UID)
    {
        UID = objj_generateObjectUID();
        CPNumberUIDs.setValueForKey(self, UID);
    }

    return UID + "";
}

- (BOOL)boolValue
{
    // Ensure we return actual booleans.
    return self ? true : false;
}

- (char)charValue
{
    return String.fromCharCode(self);
}

/*
FIXME: Do we need this?
*/
- (CPDecimal)decimalValue
{
    throw new Error("decimalValue: NOT YET IMPLEMENTED");
}

- (CPString)descriptionWithLocale:(CPDictionary)aDictionary
{
    if (!aDictionary)
        return self.toString();

    throw new Error("descriptionWithLocale: NOT YET IMPLEMENTED");
}

- (CPString)description
{
    return [self descriptionWithLocale:nil];
}

- (double)doubleValue
{
    if (typeof self == "boolean")
        return self ? 1 : 0;

    return self;
}

- (float)floatValue
{
    if (typeof self == "boolean")
        return self ? 1 : 0;

    return self;
}

- (int)intValue
{
    return CAST_TO_INT(self);
}

- (int)integerValue
{
    return CAST_TO_INT(self);
}

- (long long)longLongValue
{
    return CAST_TO_INT(self);
}

- (long)longValue
{
    return CAST_TO_INT(self);
}

- (short)shortValue
{
    return CAST_TO_INT(self);
}

- (CPString)stringValue
{
    return self.toString();
}

- (unsigned char)unsignedCharValue
{
    return String.fromCharCode(self);
}

- (unsigned int)unsignedIntValue
{
    // Despite the name this method does not make a negative value positive in Objective-C, so neither does it here.
    return CAST_TO_INT(self);
}
/*
- (unsigned long long)unsignedLongLongValue
{
    if (typeof self == "boolean") return self ? 1 : 0;
    return self;
}
*/
- (unsigned long)unsignedLongValue
{
    // Despite the name this method does not make a negative value positive in Objective-C, so neither does it here.
    return CAST_TO_INT(self);
}

- (unsigned short)unsignedShortValue
{
    // Despite the name this method does not make a negative value positive in Objective-C, so neither does it here.
    return CAST_TO_INT(self);
}

- (CPComparisonResult)compare:(CPNumber)aNumber
{
    if (aNumber === nil || aNumber['isa'] === CPNull)
        [CPException raise:CPInvalidArgumentException reason:"nil argument"];

    if (self > aNumber)
        return CPOrderedDescending;
    else if (self < aNumber)
        return CPOrderedAscending;

    return CPOrderedSame;
}

- (BOOL)isEqualToNumber:(CPNumber)aNumber
{
    return self == aNumber;
}

@end

@implementation CPNumber (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder decodeObjectForKey:@"self"];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeNumber:self forKey:@"self"];
}

@end

Number.prototype.isa = CPNumber;
Boolean.prototype.isa = CPNumber;
[CPNumber initialize];
