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

@import "CPDecimal.j"
@import "CPException.j"
@import "CPNumber.j"
@import "CPObject.j"
@import "CPString.j"

// The default global behavior class, created lazily
var CPDefaultDcmHandler = nil;

/*!
    @class CPDecimalNumberHandler
    @ingroup foundation
    @brief Decimal floating point number exception and rounding behavior. This
    class is mutable.
*/
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
/*!
    Initialise a CPDecimalNumberHandler with 'Rounding' = \e CPRoundPlain,
    'Scale' = 0 and 'Raise On [exactness, overflow, underflow, divide by zero]'
    = [no, yes, yes, yes].
    @return the receiver CPDecimalNumberHandler object reference
*/
- (id)init
{
    return [self initWithRoundingMode:CPRoundPlain
                                scale:0
                     raiseOnExactness:NO
                      raiseOnOverflow:YES
                     raiseOnUnderflow:YES
                  raiseOnDivideByZero:YES];
}

/*!
    Initialise a CPDecimalNumberHandler object with the parameters specified.
    This class handles the behaviour of the decimal number calculation engine
    on certain exceptions.
    @param roundingMode the technique used for rounding (see \e CPRoundingMode)
    @param scale    The number of digits after the decimal point that a number
                    which is rounded should have
    @param exact    If true, a change in precision (i.e. rounding) will cause a
                    \e CPDecimalNumberExactnessException exception to be
                    raised, else they are ignored
    @param overflow If true, a calculation overflow will cause a \e
                    CPDecimalNumberOverflowException exception to be raised,
                    else the maximum possible valid number is returned
    @param underflow If true, a calculation underflow will cause a \e
                     CPDecimalNumberUnderflowException exception to be raised,
                     else the minimum possible valid number is returned
    @param divideByZero If true, a divide by zero will cause a \e
                        CPDecimalNumberDivideByZeroException exception to be
                        raised, else a NotANumber (NaN) CPDecimal is returned
    @return the reference to the receiver CPDecimalNumberHandler
*/
- (id)initWithRoundingMode:(CPRoundingMode)roundingMode scale:(short)scale raiseOnExactness:(BOOL)exact raiseOnOverflow:(BOOL)overflow raiseOnUnderflow:(BOOL)underflow raiseOnDivideByZero:(BOOL)divideByZero
{
    if (self = [super init])
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
/*!
    Create a new CPDecimalNumberHandler object with the parameters specified.
    This class handles the behaviour of the decimal number calculation engine
    on certain exception. For more details see \c -initWithRoundingMode:scale:raiseOnExactness:raiseOnOverflow:raiseOnUnderflow:raiseOnDivideByZero:
*/
+ (id)decimalNumberHandlerWithRoundingMode:(CPRoundingMode)roundingMode scale:(short)scale raiseOnExactness:(BOOL)exact raiseOnOverflow:(BOOL)overflow raiseOnUnderflow:(BOOL)underflow raiseOnDivideByZero:(BOOL)divideByZero
{
    return [[self alloc] initWithRoundingMode:roundingMode
                                        scale:scale
                             raiseOnExactness:exact
                              raiseOnOverflow:overflow
                             raiseOnUnderflow:underflow
                          raiseOnDivideByZero:divideByZero];
}

/*!
    Return the default Cappuccino CPDecimalNumberHandler object instance.
    @return the default CPDecimalNumberHandler object reference with
            Rounding = \e CPRoundPlain, Scale = 0 and Raise on [exactness,
            overflow, underflow, divide by zero] = [no, yes, yes, yes]
*/
+ (id)defaultDecimalNumberHandler
{
    if (!CPDefaultDcmHandler)
        CPDefaultDcmHandler = [[CPDecimalNumberHandler alloc] init];
    return CPDefaultDcmHandler;
}

@end

// CPDecimalNumberBehaviors protocol
@implementation CPDecimalNumberHandler (CPDecimalNumberBehaviors)

/*!
    Returns the current rounding mode. One of \e CPRoundingMode enum:
    CPRoundPlain, CPRoundDown, CPRoundUp, CPRoundBankers.
    @return the current rounding mode
*/
- (CPRoundingMode)roundingMode
{
    return _roundingMode;
}

/*!
    Returns the number of digits allowed after the decimal point.
    @return the current number of digits
*/
- (short)scale
{
    return _scale;
}

/*!
    This method is invoked by the framework when an exception occurs on a
    decimal operation. Depending on the specified behaviour of the
    CPDecimalNumberHandler this will throw exceptions accordingly with
    formatted error messages.
    @param operation    the selector of the method of the operation being
                        performed when the exception occured
    @param error        the actual error type. From the \e
                        CPCalculationError enum: CPCalculationNoError,
                        CPCalculationLossOfPrecision, CPCalculationOverflow,
                        CPCalculationUnderflow, CPCalculationDivideByZero
    @param leftOperand  the CPDecimalNumber left-hand side operand used in the
                        calculation that caused the exception
    @param rightOperand the CPDecimalNumber right-hand side operand used in the
                        calculation that caused the exception
    @return if appropriate a CPDecimalNumber is returned (either the maxumum,
            minimum or NaN values), or nil
*/
- (CPDecimalNumber)exceptionDuringOperation:(SEL)operation error:(CPCalculationError)error leftOperand:(CPDecimalNumber)leftOperand rightOperand:(CPDecimalNumber)rightOperand
{
    switch (error)
    {
        case CPCalculationNoError:          break;
        case CPCalculationOverflow:         if (_raiseOnOverflow)
                                                [CPException raise:CPDecimalNumberOverflowException reason:("A CPDecimalNumber overflow has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
                                            else
                                                return [CPDecimalNumber notANumber];
                                            break;
        case CPCalculationUnderflow:        if (_raiseOnUnderflow)
                                                [CPException raise:CPDecimalNumberUnderflowException reason:("A CPDecimalNumber underflow has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
                                            else
                                                return [CPDecimalNumber notANumber];
                                            break;
        case CPCalculationLossOfPrecision:  if (_raiseOnExactness)
                                                [CPException raise:CPDecimalNumberExactnessException reason:("A CPDecimalNumber has been rounded off during a calculation. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
                                            break;
        case CPCalculationDivideByZero:     if (_raiseOnDivideByZero)
                                                [CPException raise:CPDecimalNumberDivideByZeroException reason:("A CPDecimalNumber divide by zero has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
                                            else
                                                return [CPDecimalNumber notANumber]; // Div by zero returns NaN
                                            break;
        default:                            [CPException raise:CPInvalidArgumentException reason:("An unknown CPDecimalNumber error has occured. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
    }

    return nil;
}

@end

// CPCoding category
var CPDecimalNumberHandlerRoundingModeKey       = @"CPDecimalNumberHandlerRoundingModeKey",
    CPDecimalNumberHandlerScaleKey              = @"CPDecimalNumberHandlerScaleKey",
    CPDecimalNumberHandlerRaiseOnExactKey       = @"CPDecimalNumberHandlerRaiseOnExactKey",
    CPDecimalNumberHandlerRaiseOnOverflowKey    = @"CPDecimalNumberHandlerRaiseOnOverflowKey",
    CPDecimalNumberHandlerRaiseOnUnderflowKey   = @"CPDecimalNumberHandlerRaiseOnUnderflowKey",
    CPDecimalNumberHandlerDivideByZeroKey       = @"CPDecimalNumberHandlerDivideByZeroKey";

@implementation CPDecimalNumberHandler (CPCoding)

/*!
    Called by CPCoder's \e decodeObject: to initialise the object with an archived one.
    @param aCoder a \c CPCoder instance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        [self initWithRoundingMode:[aCoder decodeIntForKey:CPDecimalNumberHandlerRoundingModeKey]
                             scale:[aCoder decodeIntForKey:CPDecimalNumberHandlerScaleKey]
                  raiseOnExactness:[aCoder decodeBoolForKey:CPDecimalNumberHandlerRaiseOnExactKey]
                   raiseOnOverflow:[aCoder decodeBoolForKey:CPDecimalNumberHandlerRaiseOnOverflowKey]
                  raiseOnUnderflow:[aCoder decodeBoolForKey:CPDecimalNumberHandlerRaiseOnUnderflowKey]
               raiseOnDivideByZero:[aCoder decodeBoolForKey:CPDecimalNumberHandlerDivideByZeroKey]];
    }

    return self;
}

/*!
    Called by CPCoder's \e encodeObject: to archive the object instance.
    @param aCoder a \c CPCoder instance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:[self roundingMode] forKey:CPDecimalNumberHandlerRoundingModeKey];
    [aCoder encodeInt:[self scale] forKey:CPDecimalNumberHandlerScaleKey];
    [aCoder encodeBool:_raiseOnExactness forKey:CPDecimalNumberHandlerRaiseOnExactKey];
    [aCoder encodeBool:_raiseOnOverflow forKey:CPDecimalNumberHandlerRaiseOnOverflowKey];
    [aCoder encodeBool:_raiseOnUnderflow forKey:CPDecimalNumberHandlerRaiseOnUnderflowKey];
    [aCoder encodeBool:_raiseOnDivideByZero forKey:CPDecimalNumberHandlerDivideByZeroKey];
}

@end

/*!
    @class CPDecimalNumber
    @ingroup foundation
    @brief Decimal floating point number

    This class represents a decimal floating point number and the relavent mathematical operations to go with it.
    The default number handler can be accessed at [CPDecimalNumberHandler +defaultDecimalNumberHandler]
    This class is mutable.
*/
@implementation CPDecimalNumber : CPNumber
{
    CPDecimal _data;
}

// overriding alloc means CPDecimalNumbers are not toll free bridged
+ (id)alloc
{
    return class_createInstance(self);
}

// initializers
/*!
    Initialise a CPDecimalNumber object with NaN
    @return the reference to the receiver CPDecimalNumber
*/
- (id)init
{
    return [self initWithDecimal:CPDecimalMakeNaN()];
}

/*!
    Initialise a CPDecimalNumber object with the contents of a CPDecimal object
    @param dcm the CPDecimal object to copy
    @return the reference to the receiver CPDecimalNumber
*/
- (id)initWithDecimal:(CPDecimal)dcm
{
    if (self = [super init])
        _data = CPDecimalCopy(dcm);

    return self;
}

/*!
    Initialise a CPDecimalNumber object with the given mantissa and exponent.
    Note: that since 'long long' doesn't exist in JS the mantissa is smaller
    than possible in Cocoa and can thus not create the full number range
    possible for a CPDecimal. Also note that at extreme cases where overflow
    or truncation will occur to the parameters in Cocoa this method produces
    different results to its Cocoa counterpart.
    @param mantissa the mantissa of the decimal number
    @param exponent the exponent of the number
    @param flag true if number is negative
    @return the reference to the receiver CPDecimalNumber
*/
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

/*!
    Initialise a CPDecimalNumber with a string. If the string is badly formed
    or outside of the acceptable range of a CPDecimal then the number is
    initialised to NaN.
    @param numberValue the string to parse.
    @return the reference to the receiver CPDecimalNumber
*/
- (id)initWithString:(CPString)numberValue
{
    return [self initWithString:numberValue locale:nil];
}

/*!
    Initialise a CPDecimalNumber with a string using the given locale. If the
    string is badly formed or outside of the acceptable range of a CPDecimal
    then the number is initialised to NaN. NOTE: Locales are currently
    not supported.
    @param numberValue the string to parse
    @param locale the CPLocale object to use when parsing the number string
    @return the reference to the receiver CPDecimalNumber
*/
- (id)initWithString:(CPString)numberValue locale:(CPDictionary)locale
{
    if (self = [self init])
    {
        _data = CPDecimalMakeWithString(numberValue, locale);
    }

    return self;
}

// class methods
/*!
    Return a new CPDecimalNumber object with the contents of a CPDecimal object
    @param dcm the CPDecimal object to copy
    @return the new CPDecimalNumber object
*/
+ (CPDecimalNumber)decimalNumberWithDecimal:(CPDecimal)dcm
{
    return [[self alloc] initWithDecimal:dcm];
}

/*!
    Create a new CPDecimalNumber object with the given mantissa and exponent.
    See \c -initWithMantissa:exponent:isNegative: for some extra notes.
    @param mantissa the mantissa of the decimal number
    @param exponent the exponent of the number
    @param flag true if number is negative
    @return the new CPDecimalNumber object
*/
+ (CPDecimalNumber)decimalNumberWithMantissa:(unsigned long long)mantissa exponent:(short)exponent isNegative:(BOOL)flag
{
    return [[self alloc] initWithMantissa:mantissa exponent:exponent isNegative:flag];
}

/*!
    Create a new CPDecimalNumber with a string. If the string is badly formed
    or outside of the acceptable range of a CPDecimal then the number is
    initialised to NaN.
    @param numberValue the string to parse.
    @return the new CPDecimalNumber object
*/
+ (CPDecimalNumber)decimalNumberWithString:(CPString)numberValue
{
    return [[self alloc] initWithString:numberValue];
}

/*!
    Create a new CPDecimalNumber with a string using the given locale. If the
    string is badly formed or outside of the acceptable range of a CPDecimal
    then the number is initialised to NaN. NOTE: Locales are currently
    not supported.
    @param numberValue the string to parse
    @param locale the CPLocale object to use when parsing the number string
    @return the new CPDecimalNumber object
*/
+ (CPDecimalNumber)decimalNumberWithString:(CPString)numberValue locale:(CPDictionary)locale
{
    return [[self alloc] initWithString:numberValue locale:locale];
}

/*!
    Return the default \c CPDecimalNumberHandler object.
    @return the new default CPDecimalNumberHandler object
*/
+ (id)defaultBehavior
{
    return [CPDecimalNumberHandler defaultDecimalNumberHandler];
}

+ (void)setDefaultBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    CPDefaultDcmHandler = behavior;
}

/*!
    340282366920938463463374607431768211455e127
    99999999999999999999999999999999999999e127
*/
+ (CPDecimalNumber)maximumDecimalNumber
{
    return [[self alloc] initWithDecimal:_CPDecimalMakeMaximum()];
}

/*!
    -340282366920938463463374607431768211455e127
    -99999999999999999999999999999999999999e127
*/
+ (CPDecimalNumber)minimumDecimalNumber
{
    return [[self alloc] initWithDecimal:_CPDecimalMakeMinimum()];
}

+ (CPDecimalNumber)notANumber
{
    return [[self alloc] initWithDecimal:CPDecimalMakeNaN()];
}

+ (CPDecimalNumber)zero
{
    return [[self alloc] initWithDecimal:CPDecimalMakeZero()];
}

+ (CPDecimalNumber)one
{
    return [[self alloc] initWithDecimal:CPDecimalMakeOne()];
}

// instance methods
- (CPDecimalNumber)decimalNumberByAdding:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByAdding:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
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
    return [self decimalNumberBySubtracting:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
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
    return [self decimalNumberByDividingBy:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
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
    return [self decimalNumberByMultiplyingBy:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
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
    return [self decimalNumberByMultiplyingByPowerOf10:power withBehavior:[CPDecimalNumber defaultBehavior]];
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
    return [self decimalNumberByRaisingToPower:power withBehavior:[CPDecimalNumber defaultBehavior]];
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
    if (![decimalNumber isKindOfClass:[CPDecimalNumber class]])
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

// CPCoding category
var CPDecimalNumberDecimalExponent      = @"CPDecimalNumberDecimalExponent",
    CPDecimalNumberDecimalIsNegative    = @"CPDecimalNumberDecimalIsNegative",
    CPDecimalNumberDecimalIsCompact     = @"CPDecimalNumberDecimalIsCompact",
    CPDecimalNumberDecimalIsNaN         = @"CPDecimalNumberDecimalIsNaN",
    CPDecimalNumberDecimalMantissa      = @"CPDecimalNumberDecimalMantissa";

@implementation CPDecimalNumber (CPCoding)

/*!
    Called by CPCoder's \e decodeObject: to initialise the object with an archived one.
    @param aCoder a \c CPCoder instance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        var dcm = CPDecimalMakeZero();
        dcm._exponent       = [aCoder decodeIntForKey:CPDecimalNumberDecimalExponent];
        dcm._isNegative     = [aCoder decodeBoolForKey:CPDecimalNumberDecimalIsNegative];
        dcm._isCompact      = [aCoder decodeBoolForKey:CPDecimalNumberDecimalIsCompact];
        dcm._isNaN          = [aCoder decodeBoolForKey:CPDecimalNumberDecimalIsNaN];
        dcm._mantissa       = [aCoder decodeObjectForKey:CPDecimalNumberDecimalMantissa];
        [self initWithDecimal:dcm];
    }

    return self;
}

/*!
    Called by CPCoder's \e encodeObject: to archive the object instance.
    @param aCoder a \c CPCoder instance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:_data._exponent forKey:CPDecimalNumberDecimalExponent];
    [aCoder encodeBool:_data._isNegative forKey:CPDecimalNumberDecimalIsNegative];
    [aCoder encodeBool:_data._isCompact forKey:CPDecimalNumberDecimalIsCompact];
    [aCoder encodeBool:_data._isNaN forKey:CPDecimalNumberDecimalIsNaN];
    [aCoder encodeObject:_data._mantissa forKey:CPDecimalNumberDecimalMantissa];
}

@end
