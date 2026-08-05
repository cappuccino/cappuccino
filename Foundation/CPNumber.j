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

// MODIFICATION: Added FIXME to highlight global mutable state anti-pattern.
// FIXME: Anti-pattern: Global Mutable State. This dictionary tracks UIDs for primitives
// and grows indefinitely in long-running processes, causing memory leaks.
const CPNumberUIDs = new CFMutableDictionary();

/*!
 @class CPNumber
 @ingroup foundation
 @brief A bridged object to native Javascript numbers.
 */
@implementation CPNumber : CPObject

+ (id)alloc
{
    // MODIFICATION: Replaced 'var' with 'let' for block scoping.
    let result = new Number();
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

- (id)initWithUnsignedShort:(unsigned short)anUnsignedShort
{
    return anUnsignedShort;
}

- (CPString)UID
{
    // MODIFICATION: Replaced 'var' with 'let' for block scoping.
    let UID = CPNumberUIDs.valueForKey(self);

    if (!UID)
    {
        UID = objj_generateObjectUID();
        CPNumberUIDs.setValueForKey(self, UID);
    }

    return UID + "";
}

- (BOOL)boolValue
{
    // MODIFICATION: Replaced conditional logic with double-not operator for strict boolean coercion.
    return !!self;
}

// MODIFICATION: Added FIXME to highlight unimplemented feature.
// FIXME: Unimplemented Feature. CPDecimal is not natively supported.
// This should either be removed or throw a proper CPInvalidArgumentException.
- (CPDecimal)decimalValue
{
    throw new Error("decimalValue: NOT YET IMPLEMENTED");
}

- (CPString)descriptionWithLocale:(CPDictionary)aDictionary
{
    // MODIFICATION: Removed hostile runtime Error throw. Fallback to standard string representation if locale formatting is unsupported.
    return self.toString();
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
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (int)integerValue
{
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (long long)longLongValue
{
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (long)longValue
{
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (short)shortValue
{
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
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
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (unsigned long)unsignedLongValue
{
    // Despite the name this method does not make a negative value positive in Objective-C, so neither does it here.
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (unsigned short)unsignedShortValue
{
    // Despite the name this method does not make a negative value positive in Objective-C, so neither does it here.
    // MODIFICATION: Removed CAST_TO_INT macro, replaced with native ES6 Math.trunc().
    return Math.trunc(self);
}

- (CPComparisonResult)compare:(CPNumber)aNumber
{
    if (aNumber == nil || aNumber['isa'] === CPNull)
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

if (Number.prototype.isa !== CPNumber)
{
    Object.defineProperties(Number.prototype,
                            {
    isa:
        {
            value: CPNumber,
            enumerable: false,
            writable: true
        }
    });
}
if (Boolean.prototype.isa !== CPNumber)
{
    Object.defineProperties(Boolean.prototype,
                            {
    isa:
        {
            value: CPNumber,
            enumerable: false,
            writable: true
        }
    });
}

[CPNumber initialize];
