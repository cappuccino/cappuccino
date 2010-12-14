/*
 * CPDecimalNumber.j
 * Foundation
 *
 * Created by Stephen Paul Ierodiaconou
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

@import "CPObject.j"
@import "CPDecimal.j"
@import "CPException.j"

/* The protocol is defined as : Make sure CPDecimalNumberHandler implements these methods
@protocol CPDecimalNumberBehaviors
- (CPRoundingMode)roundingMode;
- (short)scale;
- (CPDecimalNumber)exceptionDuringOperation:(SEL)operation error:(CPCalculationError)error leftOperand:(CPDecimalNumber)leftOperand rightOperand:(CPDecimalNumber)rightOperand;
@end
*/

/*! @class CPDecimalNumberHandler
    @ingroup foundation
    @brief Decimal floating point number exception and rounding behavior. This
    class is mutable.
*/
// protocols this implements <CPCoding, CPDecimalNumberBehaviors>
@implementation CPDecimalNumberHandler : CPObject
{
    CPRoundingMode _roundingMode;
    short _scale;
    BOOL _raiseOnExactness;
    BOOL _raiseOnOverflow;
    BOOL _raiseOnUnderflow;
    BOOL _raiseOnDivideByZero;
}

// initializers
- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (id)initWithRoundingMode:(CPRoundingMode)roundingMode scale:(short)scale raiseOnExactness:(BOOL)exact raiseOnOverflow:(BOOL)overflow raiseOnUnderflow:(BOOL)underflow raiseOnDivideByZero:(BOOL)divideByZero
{
    if (self = [self init])
    {
        _roundingMode = roundingMode;
        _scale = scale;
        _raiseOnExactness = exact;
        _raiseOnOverflow = overflow;
        _raiseOnUnderflow = underflow;
        _raiseOnDivideByZero = divideByZero;
    }

    return self;
}

// class methods
+ (id)decimalNumberHandlerWithRoundingMode:(CPRoundingMode)roundingMode scale:(short)scale raiseOnExactness:(BOOL)exact raiseOnOverflow:(BOOL)overflow raiseOnUnderflow:(BOOL)underflow raiseOnDivideByZero:(BOOL)divideByZero
{
    return [[self alloc] initWithRoundingMode:roundingMode scale:scale raiseOnExactness:exact raiseOnOverflow:overflow raiseOnUnderflow:underflow raiseOnDivideByZero:divideByZero];
}

+ (id)defaultDecimalNumberHandler
{
    return _cappdefaultDcmHandler;
}

// CPCoding methods
- (void)encodeWithCoder:(CPCoder)aCoder
{
}

- (id)initWithCoder:(CPCoder)aDecoder
{
}

// CPDecimalNumberBehaviors methods
- (CPRoundingMode)roundingMode
{
    return _roundingMode;
}

- (short)scale
{
    return _scale;
}

// FIXME: LOCALE?
- (CPDecimalNumber)exceptionDuringOperation:(SEL)operation error:(CPCalculationError)error leftOperand:(CPDecimalNumber)leftOperand rightOperand:(CPDecimalNumber)rightOperand
{
    // default behavior of throwing exceptions a la gnustep
    switch (error)
    {
    case CPCalculationNoError:
        return nil;
    case CPCalculationOverflow:
        if (_raiseOnOverflow)
            [CPException raise:CPDecimalNumberOverflowException reason:("A CPDecimalNumber overflow has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
        else
            return [CPDecimalNumber maximumDecimalNumber]; // there was overflow return largest possible val
        break;
    case CPCalculationUnderflow:
        if (_raiseOnUnderflow)
            [CPException raise:CPDecimalNumberUnderflowException reason:("A CPDecimalNumber underflow has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
        else
            return [CPDecimalNumber minimumDecimalNumber]; // there was underflow, return smallest possible value
        break;
    case CPCalculationLossOfPrecision:
        if (_raiseOnExactness)
            [CPException raise:CPDecimalNumberExactnessException reason:("A CPDecimalNumber has been rounded off during a calculation. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
        else
            return nil; // Ignore.
        break;
    case CPCalculationDivideByZero:
        if (_raiseOnDivideByZero)
            [CPException raise:CPDecimalNumberDivideByZeroException reason:("A CPDecimalNumber divide by zero has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
        else
            return [CPDecimalNumber notANumber]; // Div by zero returns NaN
        break;
    default:
        [CPException raise:CPInvalidArgumentException reason:("An unknown CPDecimalNumber error has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
    }

  return nil;
}

@end

// create the default global behavior class
_cappdefaultDcmHandler = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundPlain scale:0 raiseOnExactness:NO raiseOnOverflow:YES raiseOnUnderflow:YES raiseOnDivideByZero:YES];

// After discussing with boucher about this it makes sense not to inherit, as
// CPNumber is toll free bridged and anyway its methods will need to be
// overrided here as CPDecimalNumber is not interchangable with CPNumbers.

/*! @class CPDecimalNumber
    @ingroup foundation
    @brief Decimal floating point number

    This class represents a decimal floating point number and the relavent
    mathematical operations to go with it.
    This class is mutable.
*/


@implementation CPDecimalNumber : CPNumber
{
    CPDecimal _data;
}

+ (id)alloc
{
    return class_createInstance(self);
}

// initializers
- (id)init
{
    if (self = [super init])
    {}
    return self;
}

/*!
    Initialise a CPDecimalNumber object with the contents of a CPDecimal object
    @param dcm the CPDecimal object to copy
    @return the reference to the receiver CPDecimalNumber
*/
- (id)initWithDecimal:(CPDecimal)dcm
{
    if (self = [self init])
        _data = CPDecimalCopy(dcm);

    return self;
}

// NOTE: long long doesnt exist in JS, so this is actually a double
- (id)initWithMantissa:(unsigned long long)mantissa exponent:(short)exponent isNegative:(BOOL)flag
{
    if (self = [self init])
    {
        if (flag)
            mantissa *= -1;

        _data = CPDecimalMakeWithParts(mantissa, exponent);
    }

    return self;
}

- (id)initWithString:(CPString)numberValue
{
    if (self = [self init])
    {
        _data = CPDecimalMakeWithString(numberValue, nil);
        if (_data === nil)
            [CPException raise:CPInvalidArgumentException reason:"A CPDecimalNumber has been passed an invalid string. '" + numberValue + "'"];
    }

    return self;
}

- (id)initWithString:(CPString)numberValue locale:(CPDictionary)locale
{
    if (self = [self init])
    {
        _data = CPDecimalMakeWithString(numberValue,locale);
        if (!_data)
            [CPException raise:CPInvalidArgumentException reason:"A CPDecimalNumber has been passed an invalid string. '" + numberValue + "'"];
    }

    return self;
}

// class methods
+ (CPDecimalNumber)decimalNumberWithDecimal:(CPDecimal)dcm
{
    return [[self alloc] initWithDecimal:dcm];
}

+ (CPDecimalNumber)decimalNumberWithMantissa:(unsigned long long)mantissa exponent:(short)exponent isNegative:(BOOL)flag
{
    return [[self alloc] initWithMantissa:mantissa exponent:exponent isNegative:flag];
}

+ (CPDecimalNumber)decimalNumberWithString:(CPString)numberValue
{
    return [[self alloc] initWithString:numberValue];
}

+ (CPDecimalNumber)decimalNumberWithString:(CPString)numberValue locale:(CPDictionary)locale
{
    return [[self alloc] initWithString:numberValue locale:locale];
}

+ (id)defaultBehavior
{
    return _cappdefaultDcmHandler;
}

+ (CPDecimalNumber)maximumDecimalNumber
{
    var s = @"",
        i = 0;
    for (;i < CPDecimalMaxDigits; i++)
        s += "9";
    s += "e" + CPDecimalMaxExponent;
    return [[self alloc] initWithString:s];
}

+ (CPDecimalNumber)minimumDecimalNumber
{
    var s = @"-",
        i = 0;
    for (;i < CPDecimalMaxDigits; i++)
        s += "9";
    s += "e" + CPDecimalMinExponent;
    return [[self alloc] initWithString:s];
}

+ (CPDecimalNumber)notANumber
{
    return [[self alloc] initWithDecimal:CPDecimalMakeNaN()];
}

+ (CPDecimalNumber)one
{
    return [[self alloc] initWithString:"1"];
}

+ (void)setDefaultBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    _cappdefaultDcmHandler = behavior;
}

+ (CPDecimalNumber)zero
{
    return [[self alloc] initWithString:"0"];
}

// instance methods
- (CPDecimalNumber)decimalNumberByAdding:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByAdding:decimalNumber withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberByAdding:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    // FIXME: Surely this can take CPNumber (any JS number) as an argument as CPNumber is CPDecimalNumbers super normally (not here tho)
    var result = CPDecimalMakeZero(),
        res = 0,
        error = CPDecimalAdd(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberBySubtracting:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberBySubtracting:decimalNumber withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberBySubtracting:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalSubtract(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberByDividingBy:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByDividingBy:decimalNumber withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberByDividingBy:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalDivide(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberByMultiplyingBy:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByMultiplyingBy:decimalNumber withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberByMultiplyingBy:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalMultiply(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberByMultiplyingByPowerOf10:(short)power
{
    return [self decimalNumberByMultiplyingByPowerOf10:power withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberByMultiplyingByPowerOf10:(short)power withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalMultiplyByPowerOf10(result, [self decimalValue], power, [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberByRaisingToPower:(unsigned)power
{
    return [self decimalNumberByRaisingToPower:power withBehavior:_cappdefaultDcmHandler];
}

- (CPDecimalNumber)decimalNumberByRaisingToPower:(unsigned)power withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    if (power < 0)
        return [behavior exceptionDuringOperation:_cmd error:-1 leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];

    var result = CPDecimalMakeZero(),
        error = CPDecimalPower(result, [self decimalValue], power, [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];
        // Gnustep does this, not sure if it is correct behavior
        if (res != nil)
            return res; // say on overflow and no exception handling, returns max decimal val
    }
    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

- (CPDecimalNumber)decimalNumberByRoundingAccordingToBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero();

    CPDecimalRound(result, [self decimalValue], [behavior scale], [behavior roundingMode]);

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

// This method takes a CPNumber. Thus the parameter may be a CPDecimalNumber or a CPNumber class.
// Thus the type is checked to send the operand to the correct compare function.
- (CPComparisonResult)compare:(CPNumber)decimalNumber
{
    if ([decimalNumber class] != CPDecimalNumber)
        decimalNumber = [CPDecimalNumber decimalNumberWithString:decimalNumber.toString()];
    return CPDecimalCompare([self decimalValue], [decimalNumber decimalValue]);
}

/*!
    Unimplemented
*/
- (CPString)hash
{
    [CPException raise:CPUnsupportedMethodException reason:"hash: NOT YET IMPLEMENTED"];
}

/*!
    The objective C type string. For compatability reasons
    @return returns a CPString containing "d"
*/
- (CPString)objCType
{
    return @"d";
}

- (CPString)description
{
    // FIXME:  I expect here locale should be some default locale
    return [self descriptionWithLocale:nil]
}

- (CPString)descriptionWithLocale:(CPDictionary)locale
{
    return CPDecimalString(_data, locale);
}

- (CPString)stringValue
{
    return [self description];
}

/*!
    Returns a new CPDecimal object (which effectively contains the
    internal decimal number representation).
    @return a new CPDecimal number copy
*/
- (CPDecimal)decimalValue
{
    return CPDecimalCopy(_data);
}

// Type Conversion Methods
- (double)doubleValue
{
    // FIXME: locale support / bounds check?
    return parseFloat([self stringValue]);
}

- (BOOL)boolValue
{
    return (CPDecimalIsZero(_data))?NO:YES;
}

- (char)charValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (float)floatValue
{
    // FIXME: locale support / bounds check?
    return parseFloat([self stringValue]);
}

- (int)intValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (long long)longLongValue
{
    // FIXME: locale support / bounds check?
    return parseFloat([self stringValue]);
}

- (long)longValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (short)shortValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (unsigned char)unsignedCharValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (unsigned int)unsignedIntValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (unsigned long)unsignedLongValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (unsigned short)unsignedShortValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

- (BOOL)isEqualToNumber:(CPNumber)aNumber
{
    return (CPDecimalCompare(CPDecimalMakeWithString(aNumber.toString(),nil), _data) == CPOrderedSame)?YES:NO;
}

// CPNumber inherited methods
+ (id)numberWithBool:(BOOL)aBoolean
{
    return [[self alloc] initWithBool:aBoolean];
}

+ (id)numberWithChar:(char)aChar
{
    return [[self alloc] initWithChar:aChar];
}

+ (id)numberWithDouble:(double)aDouble
{
    return [[self alloc] initWithDouble:aDouble];
}

+ (id)numberWithFloat:(float)aFloat
{
    return [[self alloc] initWithFloat:aFloat];
}

+ (id)numberWithInt:(int)anInt
{
    return [[self alloc] initWithInt:anInt];
}

+ (id)numberWithLong:(long)aLong
{
    return [[self alloc] initWithLong:aLong];
}

+ (id)numberWithLongLong:(long long)aLongLong
{
    return [[self alloc] initWithLongLong:aLongLong];
}

+ (id)numberWithShort:(short)aShort
{
    return [[self alloc] initWithShort:aShort];
}

+ (id)numberWithUnsignedChar:(unsigned char)aChar
{
    return [[self alloc] initWithUnsignedChar:aChar];
}

+ (id)numberWithUnsignedInt:(unsigned)anUnsignedInt
{
    return [[self alloc] initWithUnsignedInt:anUnsignedInt];
}

+ (id)numberWithUnsignedLong:(unsigned long)anUnsignedLong
{
    return [[self alloc] initWithUnsignedLong:anUnsignedLong];
}

+ (id)numberWithUnsignedLongLong:(unsigned long)anUnsignedLongLong
{
    return [[self alloc] initWithUnsignedLongLong:anUnsignedLongLong];
}

+ (id)numberWithUnsignedShort:(unsigned short)anUnsignedShort
{
    return [[self alloc] initWithUnsignedShort:anUnsignedShort];
}

- (id)initWithBool:(BOOL)value
{
    if (self = [self init])
        _data = CPDecimalMakeWithParts((value)?1:0, 0);
    return self;
}

- (id)initWithChar:(char)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithDouble:(double)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithFloat:(float)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithInt:(int)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithLong:(long)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithLongLong:(long long)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithShort:(short)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithUnsignedChar:(unsigned char)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithUnsignedInt:(unsigned)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithUnsignedLong:(unsigned long)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithUnsignedLongLong:(unsigned long long)value
{
    return [self _initWithJSNumber:value];
}

- (id)initWithUnsignedShort:(unsigned short)value
{
    return [self _initWithJSNumber:value];
}

- (id)_initWithJSNumber:value
{
    if (self = [self init])
        _data = CPDecimalMakeWithString(value.toString(), nil);
    return self;
}

@end
