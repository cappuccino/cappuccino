/*
 * CPNumberFormatter.j
 * Foundation
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
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


@import <Foundation/CPString.j>
@import <Foundation/CPFormatter.j>
@import <Foundation/CPDecimalNumber.j>

CPNumberFormatterNoStyle            = 0;
CPNumberFormatterDecimalStyle       = 1;
CPNumberFormatterCurrencyStyle      = 2;
CPNumberFormatterPercentStyle       = 3;
CPNumberFormatterScientificStyle    = 4;
CPNumberFormatterSpellOutStyle      = 5;

CPNumberFormatterRoundCeiling       = CPRoundUp;
CPNumberFormatterRoundFloor         = CPRoundDown;
CPNumberFormatterRoundDown          = CPRoundDown;
CPNumberFormatterRoundUp            = CPRoundUp;
CPNumberFormatterRoundHalfEven      = CPRoundBankers;
CPNumberFormatterRoundHalfDown      = _CPRoundHalfDown;
CPNumberFormatterRoundHalfUp        = CPRoundPlain;

/*!
    @ingroup foundation
    @class CPNumberFormatter

    CPNumberFormatter takes a numeric NSNumber value and formats it as text for
    display. It also supports the converse, taking text and interpreting it as a
    CPNumber by configurable formatting rules.
*/
@implementation CPNumberFormatter : CPFormatter
{
    CPNumberFormatterStyle          _numberStyle @accessors(property=numberStyle);
    CPString                        _perMillSymbol @accessors(property=perMillSymbol);
    CPNumberFormatterRoundingMode   _roundingMode @accessors(property=roundingMode);
}

- (id)init
{
    if (self = [super init])
    {
        _roundingMode = CPNumberFormatterRoundHalfUp;
    }

    return self;
}

- (CPString)stringFromNumber:(CPNumber)number
{
    // TODO Add locale support.
    switch(_numberStyle)
    {
        case CPNumberFormatterDecimalStyle:
            var dcmn = [CPDecimalNumber numberWithFloat:number],
                roundingMode = [self roundingMode],
                numberHandler = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:roundingMode scale:3 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];

            dcmn = [dcmn decimalNumberByRoundingAccordingToBehavior:numberHandler];

            var output = [dcmn descriptionWithLocale:nil],
                parts = [output componentsSeparatedByString:"."], // FIXME Locale specific.
                preFraction = parts[0],
                fraction = parts.length > 1 ? parts[1] : "",
                preFractionLength = [preFraction length],
                commaPosition = 3,
                perMillSymbol = [self _effectivePerMillSymbol];

            // TODO This is just a temporary solution. Should be generalised.
            // Add in thousands separators.
            if (perMillSymbol)
                while(commaPosition < [preFraction length])
                {
                    preFraction = [preFraction stringByReplacingCharactersInRange:CPMakeRange(commaPosition, 0) withString:perMillSymbol];
                    commaPosition += 4;
                }

            if (fraction)
                return preFraction + "." + fraction;
            else
                return preFraction;
        default:
            return [number description];
    }
}

- (CPNumber)numberFromString:(CPString)string
{
    // TODO
    return parseFloat(string);
}

- (CPString)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[CPNumber class]])
        return [self stringFromNumber:anObject];
    else
        return [anObject description];
}

- (CPString)editingStringForObjectValue:(id)anObject
{
    return [self stringForObjectValue:anObject];
}

- (BOOL)getObjectValue:(id)anObject forString:(CPString)aString errorDescription:(CPString)anError
{
    // TODO Error handling.
    var value = [self numberFromString:aString];
    @deref(anObject, value);
    return YES;
}

/*!
    @ignore
    Return the perMillSymbol if set, otherwise the locale default.
*/
- (CPString)_effectivePerMillSymbol
{
    if (_perMillSymbol === nil || _perMillSymbol === undefined)
        return ","; // (FIXME US Locale specific.)
    return _perMillSymbol;
}

@end

var CPNumberFormatterStyleKey = "CPNumberFormatterStyleKey";

@implementation CPNumberFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _numberStyle = [aCoder decodeIntForKey:CPNumberFormatterStyleKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_numberStyle forKey:CPNumberFormatterStyleKey];
}

@end
