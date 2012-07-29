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

#import "Ref.h"

@import <Foundation/CPString.j>
@import <Foundation/CPFormatter.j>
@import <Foundation/CPDecimalNumber.j>

#define UPDATE_NUMBER_HANDLER_IF_NECESSARY() if (!_numberHandler) \
    _numberHandler = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:_roundingMode scale:_maximumFractionalDigits raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
#define SET_NEEDS_NUMBER_HANDLER_UPDATE() _numberHandler = nil;

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
    CPString                        _groupingSeparator @accessors(property=groupingSeparator);
    CPNumberFormatterRoundingMode   _roundingMode @accessors(property=roundingMode);
    CPUInteger                      _maximumFractionalDigits @accessors(property=maximalFractionalDigits);

    CPDecimalNumberHandler         _numberHandler;
}

- (id)init
{
    if (self = [super init])
    {
        _roundingMode = CPNumberFormatterRoundHalfUp;
        _maximumFractionalDigits = 3;
        _groupingSeparator = @",";
    }

    return self;
}

- (CPString)stringFromNumber:(CPNumber)number
{
    // TODO Add locale support.
    switch (_numberStyle)
    {
        case CPNumberFormatterDecimalStyle:
            UPDATE_NUMBER_HANDLER_IF_NECESSARY();

            var dcmn = [CPDecimalNumber numberWithFloat:number];
            dcmn = [dcmn decimalNumberByRoundingAccordingToBehavior:_numberHandler];

            var output = [dcmn descriptionWithLocale:nil],
                parts = [output componentsSeparatedByString:"."], // FIXME Locale specific.
                preFraction = parts[0],
                fraction = parts.length > 1 ? parts[1] : "",
                preFractionLength = [preFraction length],
                commaPosition = 3;

            // TODO This is just a temporary solution. Should be generalised.
            // Add in thousands separators.
            if (_groupingSeparator)
            {
                for (var commaPosition = 3, prefLength = [preFraction length]; commaPosition < prefLength; commaPosition += 4)
                {
                    preFraction = [preFraction stringByReplacingCharactersInRange:CPMakeRange(prefLength - commaPosition, 0) withString:_groupingSeparator];
                    prefLength += 1;
                }
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
    AT_DEREF(anObject, value);

    return YES;
}

- (void)setRoundingMode:(CPNumberFormatterRoundingMode)aRoundingMode
{
    _roundingMode = aRoundingMode;
    SET_NEEDS_NUMBER_HANDLER_UPDATE();
}

- (void)setMaximumFractionDigits:(CPUInteger)aNumber
{
    _maximumFractionalDigits = aNumber;
    SET_NEEDS_NUMBER_HANDLER_UPDATE();
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
