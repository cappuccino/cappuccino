/*
 * CPByteCountFormatter.j
 * Foundation
 *
 * Created by Aparajita Fishman.
 * Copyright 2013, Cappuccino Foundation.
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

@import "CPNumberFormatter.j"
@import "CPString.j"


// Allowed units
CPByteCountFormatterUseDefault      = 0;
CPByteCountFormatterUseBytes        = 1 << 0;
CPByteCountFormatterUseKB           = 1 << 1;
CPByteCountFormatterUseMB           = 1 << 2;
CPByteCountFormatterUseGB           = 1 << 3;
CPByteCountFormatterUseTB           = 1 << 4;
CPByteCountFormatterUsePB           = 1 << 5;
CPByteCountFormatterUseAll          = 0xFFFF;

// Note: The Cocoa documentation says File is binary, but in practice it's decimal
CPByteCountFormatterCountStyleFile      = 0;
CPByteCountFormatterCountStyleMemory    = 1;
CPByteCountFormatterCountStyleDecimal   = 2;
CPByteCountFormatterCountStyleBinary    = 3;

var CPByteCountFormatterUnits = [ @"bytes", @"KB", @"MB", @"GB", @"TB", @"PB" ];


/*!
    @ingroup foundation
    @class CPByteCountFormatter

    A complete implementation of NSByteCountFormatter. See
    https://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSByteCountFormatter_Class/Reference/Reference.html
*/
@implementation CPByteCountFormatter : CPFormatter
{
    int                 _countStyle;
    BOOL                _allowsNonnumericFormatting;
    BOOL                _includesActualByteCount;
    BOOL                _includesCount;
    BOOL                _includesUnit;
    BOOL                _adaptive;
    BOOL                _zeroPadsFractionDigits;
    int                 _allowedUnits;
    CPNumberFormatter   _numberFormatter;
}

- (id)init
{
    if (self = [super init])
    {
        _adaptive = YES;
        _allowedUnits = CPByteCountFormatterUseDefault;
        _allowsNonnumericFormatting = YES;
        _countStyle = CPByteCountFormatterCountStyleFile;
        _includesActualByteCount = NO;
        _includesCount = YES;
        _includesUnit = YES;
        _zeroPadsFractionDigits = NO;
        _numberFormatter = [CPNumberFormatter new];
        [_numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
        [_numberFormatter setMinimumFractionDigits:0];
    }

    return self;
}

/*! @name Creating Strings from Byte Count */

+ (CPString)stringFromByteCount:(int)byteCount countStyle:(int)countStyle
{
    var formatter = [CPByteCountFormatter new];

    [formatter setCountStyle:countStyle];

    return [formatter stringFromByteCount:byteCount];
}

- (CPString)stringFromByteCount:(int)byteCount
{
    var divisor,
        exponent = 0,
        unitIndex = ((_allowedUnits === 0) || (_allowedUnits & CPByteCountFormatterUseBytes)) ? 0 : -1,
        bytes = byteCount,
        unitBytes = bytes,
        unitCount = [CPByteCountFormatterUnits count];

    if (_countStyle === CPByteCountFormatterCountStyleFile ||
        _countStyle === CPByteCountFormatterCountStyleDecimal)
        divisor = 1000;
    else
        divisor = 1024;

    while ((bytes >= divisor) && (exponent < unitCount))
    {
        bytes /= divisor;
        ++exponent;

        // If there is a valid unit for this exponent,
        // update the unit we will use and the byte count for that unit
        if (_allowedUnits === 0 || (_allowedUnits & (1 << exponent)))
        {
            unitIndex = exponent;
            unitBytes = bytes;
        }
    }

    /*
        If no allowed unit was found before bytes < divisor,
        keep dividing until we find an allowed unit. We can skip
        bytes, if that is allowed unit, unitIndex will be >= 0.
    */
    if (unitIndex === -1)
        for (var i = 1; i < unitCount; ++i)
        {
            unitBytes /= divisor;

            if ((_allowedUnits === 0) || (_allowedUnits & (1 << i)))
            {
                unitIndex = i;
                break;
            }
        }

    var minDigits = 0,
        maxDigits = CPDecimalNoScale;

    // Fractional units get as many digits as they need
    if (unitBytes >= 1.0)
    {
        if (_adaptive)
        {
            // 0 fraction digits for bytes and K, 1 fraction digit for MB, 2 digits for GB and above
            var digits;

            if (exponent <= 1)
                digits = 0;
            else if (exponent == 2)
                digits = 1;
            else
                digits = 2;

            maxDigits = digits;

            if (_zeroPadsFractionDigits)
                minDigits = digits;
        }
        else
        {
            if (_zeroPadsFractionDigits)
                minDigits = 2;

            if (bytes >= 1)
                maxDigits = 2;
        }
    }

    [_numberFormatter setMinimumFractionDigits:minDigits];
    [_numberFormatter setMaximumFractionDigits:maxDigits];

    var parts = [];

    if (_includesCount)
    {
        if (_allowsNonnumericFormatting && bytes === 0)
            [parts addObject:@"Zero"];
        else
            [parts addObject:[_numberFormatter stringFromNumber:unitBytes]];
    }

    if (_includesUnit)
        [parts addObject:CPByteCountFormatterUnits[unitIndex]];

    if ((unitIndex > 0) && _includesCount && _includesUnit && _includesActualByteCount)
    {
        [_numberFormatter setMaximumFractionDigits:0];
        [parts addObject:[CPString stringWithFormat:@"(%s bytes)", [_numberFormatter stringFromNumber:byteCount]]];
    }

    var result = [parts componentsJoinedByString:@" "];

    if (byteCount === 1)
        return [result stringByReplacingOccurrencesOfString:@"bytes" withString:@"byte"];
    else
        return result;
}

/*!
    Cocoa returns nil if anObject is not a number.
*/
- (CPString)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:CPNumber])
        return [self stringFromByteCount:anObject];
    else
        return nil;
}

- (BOOL)getObjectValue:(id)anObject forString:(CPString)aString errorDescription:(CPString)anError
{
    // Not implemented
    return NO;
}

/*! @name Setting Formatting Styles */

- (int)countStyle
{
    return _countStyle;
}

- (void)setCountStyle:(int)style
{
    _countStyle = style;
}

- (BOOL)allowsNonnumericFormatting
{
    return _allowsNonnumericFormatting;
}

- (void)setAllowsNonnumericFormatting:(BOOL)shouldAllowNonnumericFormatting
{
    _allowsNonnumericFormatting = shouldAllowNonnumericFormatting;
}

- (BOOL)includesActualByteCount
{
    return _includesActualByteCount;
}

- (void)setIncludesActualByteCount:(BOOL)shouldIncludeActualByteCount
{
    _includesActualByteCount = shouldIncludeActualByteCount;
}

- (BOOL)isAdaptive
{
    return _adaptive;
}

- (void)setAdaptive:(BOOL)shouldBeAdaptive
{
    _adaptive = shouldBeAdaptive;
}

- (int)allowedUnits
{
    return _allowedUnits;
}

- (void)setAllowedUnits:(int)allowed
{
    // Note: CPByteCountFormatterUseDefault is equivalent to UseAll
    _allowedUnits = allowed;
}

- (BOOL)includesCount
{
    return _includesCount;
}

- (void)setIncludesCount:(BOOL)shouldIncludeCount
{
    _includesCount = shouldIncludeCount;
}

- (BOOL)includesUnit
{
    return _includesUnit;
}

- (void)setIncludesUnit:(BOOL)shouldIncludeUnit
{
    _includesUnit = shouldIncludeUnit;
}

- (BOOL)zeroPadsFractionDigits
{
    return _zeroPadsFractionDigits;
}

- (void)setZeroPadsFractionDigits:(BOOL)shouldZeroPad
{
    _zeroPadsFractionDigits = shouldZeroPad;
}

@end


var CPByteCountFormatterCountStyleKey                   = @"CPByteCountFormatterCountStyleKey",
    CPByteCountFormatterAllowsNonnumericFormattingKey   = @"CPByteCountFormatterAllowsNonnumericFormattingKey",
    CPByteCountFormatterIncludesActualByteCountKey      = @"CPByteCountFormatterIncludesActualByteCountKey",
    CPByteCountFormatterIncludesCountKey                = @"CPByteCountFormatterIncludesCountKey",
    CPByteCountFormatterIncludesUnitKey                 = @"CPByteCountFormatterIncludesUnitKey",
    CPByteCountFormatterAdaptiveKey                     = @"CPByteCountFormatterAdaptiveKey",
    CPByteCountFormatterZeroPadsFractionDigitsKey       = @"CPByteCountFormatterZeroPadsFractionDigitsKey",
    CPByteCountFormatterAllowedUnitsKey                 = @"CPByteCountFormatterAllowedUnitsKey";

@implementation CPByteCountFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _countStyle = [aCoder decodeIntForKey:CPByteCountFormatterCountStyleKey];
        _allowsNonnumericFormatting = [aCoder decodeBoolForKey:CPByteCountFormatterAllowsNonnumericFormattingKey];
        _includesActualByteCount = [aCoder decodeBoolForKey:CPByteCountFormatterIncludesActualByteCountKey];
        _includesCount = [aCoder decodeBoolForKey:CPByteCountFormatterIncludesCountKey];
        _includesUnit = [aCoder decodeBoolForKey:CPByteCountFormatterIncludesUnitKey];
        _adaptive = [aCoder decodeBoolForKey:CPByteCountFormatterAdaptiveKey];
        _zeroPadsFractionDigits = [aCoder decodeBoolForKey:CPByteCountFormatterZeroPadsFractionDigitsKey];
        _allowedUnits = [aCoder decodeIntForKey:CPByteCountFormatterAllowedUnitsKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_countStyle forKey:CPByteCountFormatterCountStyleKey];
    [aCoder encodeBool:_allowsNonnumericFormatting forKey:CPByteCountFormatterAllowsNonnumericFormattingKey];
    [aCoder encodeBool:_includesActualByteCount forKey:CPByteCountFormatterIncludesActualByteCountKey];
    [aCoder encodeBool:_includesCount forKey:CPByteCountFormatterIncludesCountKey];
    [aCoder encodeBool:_includesUnit forKey:CPByteCountFormatterIncludesUnitKey];
    [aCoder encodeBool:_adaptive forKey:CPByteCountFormatterAdaptiveKey];
    [aCoder encodeBool:_zeroPadsFractionDigits forKey:CPByteCountFormatterZeroPadsFractionDigitsKey];
    [aCoder encodeInt:_allowedUnits forKey:CPByteCountFormatterAllowedUnitsKey];
}

@end
