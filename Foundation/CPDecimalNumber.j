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
                        performed when the exception occurred
    @param error        the actual error type. From the \e
                        CPCalculationError enum: CPCalculationNoError,
                        CPCalculationLossOfPrecision, CPCalculationOverflow,
                        CPCalculationUnderflow, CPCalculationDivideByZero
    @param leftOperand  the CPDecimalNumber left-hand side operand used in the
                        calculation that caused the exception
    @param rightOperand the CPDecimalNumber right-hand side operand used in the
                        calculation that caused the exception
    @return if appropriate a CPDecimalNumber is returned (either the maximum,
            minimum or NaN values), or nil
*/
- (CPDecimalNumber)exceptionDuringOperation:(SEL)operation error:(CPCalculationError)error leftOperand:(CPDecimalNumber)leftOperand rightOperand:(CPDecimalNumber)rightOperand
{
    switch (error)
    {
        case CPCalculationNoError:
            break;

        case CPCalculationOverflow:
            if (_raiseOnOverflow)
                [CPException raise:CPDecimalNumberOverflowException reason:("A CPDecimalNumber overflow has occurred. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
            else
                return [CPDecimalNumber notANumber];
            break;

        case CPCalculationUnderflow:
            if (_raiseOnUnderflow)
                [CPException raise:CPDecimalNumberUnderflowException reason:("A CPDecimalNumber underflow has occurred. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
            else
                return [CPDecimalNumber notANumber];
            break;

        case CPCalculationLossOfPrecision:
            if (_raiseOnExactness)
                [CPException raise:CPDecimalNumberExactnessException reason:("A CPDecimalNumber has been rounded off during a calculation. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
            break;

        case CPCalculationDivideByZero:
            if (_raiseOnDivideByZero)
                [CPException raise:CPDecimalNumberDivideByZeroException reason:("A CPDecimalNumber divide by zero has occurred. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')") ];
            else
                return [CPDecimalNumber notANumber]; // Div by zero returns NaN
            break;

        default:
            [CPException raise:CPInvalidArgumentException reason:("An unknown CPDecimalNumber error has occurred. (Left operand= '" + [leftOperand  descriptionWithLocale:nil] + "' Right operand= '" + [rightOperand  descriptionWithLocale:nil] + "' Selector= '" + operation + "')")];
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

    This class represents a decimal floating point number and the relevant
    mathematical operations to go with it. It guarantees accuracy up to 38
    digits in the mantissa/coefficient and can handle numbers in the range:
        +/- 99999999999999999999999999999999999999 x 10^(127/-128)
    Methods are available for: Addition, Subtraction, Multiplication, Division,
    Powers and Rounding.
    Exceptions can be thrown on: Overflow, Underflow, Loss of Precision
    (rounding) and Divide by zero, the behaviour of which is controlled via the
    CPDecimalNumberHandler class.

    Note: The aim here is to try to produce the exact same output as Cocoa.
    However, this is effectively not possible but to get as close as possible
    we must perform our calculations in a way such that we even get the same
    rounding errors building up, say when computing large powers which require
    many multiplications. The code here almost matches the results of Cocoa but
    there are some small differences as outlined below:

    An example where a small rounding error difference creeps in:
    For the calculation (0.875 ^ 101) the result becomes:
        In Cocoa:  0.00000(13893554059925661274821814636807535200)1
                the 38 digits are bracketed, the extra 39th digit in Cocoa
                is explained below.
        In Cappuccino: 0.00000(13893554059925661274821814636807535204)
        Difference: 4e-41

    Since, in Cocoa, NSDecimalNumber uses a binary internal format for
    the mantissa (coefficient) the maximum it can store before truly
    losing precision is actually 2^128, which is a 39 digit number. After this
    rounding and exponent changes occur. In our implementation each digit is
    stored separately hence the mantissa maximum value is the maximum possible
    38 digit number. Obviously Apple can only say precision is guaranteed to
    38 digits cause at some point in the 39 digits numbers rounding starts.
    Hence there will be inherent differences between Cocoa and Cappuccino
    answers if rounding occurs (see above example). They both still provide
    the same 38 digit guarantee however.

    So the actual range of NSDecimal is
    +/- 340282366920938463463374607431768211455 x 10^(127/-128)
    (Notice this is 39 digits)
    Compared to in Cappuccino:
    +/- 99999999999999999999999999999999999999 x 10^(127/-128)
*/
@implementation CPDecimalNumber : CPNumber
{
    CPDecimal _data;
}

/*!
    Create a new CPDecimalNumber object uninitialised.
    Note: even though CPDecimalNumber inherits from CPNumber it is not toll free
    bridged to a JS type as CPNumber is.
    @return a new CPDecimalNumber instance
*/
+ (id)alloc
{
    // overriding alloc means CPDecimalNumbers are not toll free bridged
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
    Creates a new CPDecimalNumber object with the given mantissa and exponent.
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
    Creates a new CPDecimalNumber with a string. If the string is badly formed
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
    Creates a new CPDecimalNumber with a string using the given locale. If the
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
    @return the default CPDecimalNumberHandler object
*/
+ (id)defaultBehavior
{
    return [CPDecimalNumberHandler defaultDecimalNumberHandler];
}

/*!
    Set the default \c CPDecimalNumberHandler object. This is a framework wide
    setting. All subsequent decimal number operations will use this behaviour.
    @param behavior the new default CPDecimalNumberHandler object
*/
+ (void)setDefaultBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    CPDefaultDcmHandler = behavior;
}

/*!
    Returns a new CPDecimalNumber with the maximum permissible decimal number
    value. Note: this is different to the number Cocoa returns. See
    CPDecimalNumber class description for details.
    @return a new CPDecimalNumber object
*/
+ (CPDecimalNumber)maximumDecimalNumber
{
    return [[self alloc] initWithDecimal:_CPDecimalMakeMaximum()];
}

/*!
    Returns a new CPDecimalNumber with the minimum permissible decimal number
    value. Note: this is different to the number Cocoa returns. See
    CPDecimalNumber class description for details.
    @return a new CPDecimalNumber object
*/
+ (CPDecimalNumber)minimumDecimalNumber
{
    return [[self alloc] initWithDecimal:_CPDecimalMakeMinimum()];
}

/*!
    Returns a new CPDecimalNumber initialised to \e NaN.
    @return a new CPDecimalNumber object
*/
+ (CPDecimalNumber)notANumber
{
    return [[self alloc] initWithDecimal:CPDecimalMakeNaN()];
}

/*!
    Returns a new CPDecimalNumber initialised to zero (0.0).
    @return a new CPDecimalNumber object
*/
+ (CPDecimalNumber)zero
{
    return [[self alloc] initWithDecimal:CPDecimalMakeZero()];
}

/*!
    Returns a new CPDecimalNumber initialised to one (1.0).
    @return a new CPDecimalNumber object
*/
+ (CPDecimalNumber)one
{
    return [[self alloc] initWithDecimal:CPDecimalMakeOne()];
}

// instance methods
/*!
    Returns a new CPDecimalNumber object with the result of the summation of
    the receiver object and \c decimalNumber. If overflow occurs then the
    consequence depends on the current default CPDecimalNumberHandler.
    @param decimalNumber the decimal number to add to the receiver
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByAdding:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByAdding:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of the summation of
    the receiver object and \c decimalNumber. If overflow occurs then the
    consequence depends on the CPDecimalNumberHandler object \e behavior.
    @param decimalNumber the decimal number to add to the receiver
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByAdding:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalAdd(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of the subtraction of
    \c decimalNumber from the receiver object. If underflow or loss of precision
    occurs then the consequence depends on the current default
    CPDecimalNumberHandler.
    @param decimalNumber the decimal number to subtract from the receiver
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberBySubtracting:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberBySubtracting:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of the subtraction of
    \c decimalNumber from the receiver object. If underflow or loss of
    precision occurs then the consequence depends on the CPDecimalNumberHandler
    object \e behavior.
    @param decimalNumber the decimal number to subtract from the receiver
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberBySubtracting:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalSubtract(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];

        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of dividing the
    receiver object by \c decimalNumber. If underflow, divide by zero or loss
    of precision occurs then the consequence depends on the current default
    CPDecimalNumberHandler object.
    @param decimalNumber the decimal number to divide the the receiver by
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByDividingBy:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByDividingBy:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of dividing the
    receiver object by \c decimalNumber. If underflow, divide by zero or loss
    of precision occurs then the consequence depends on the
    CPDecimalNumberHandler object \e behavior.
    @param decimalNumber the decimal number to divide the the receiver by
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByDividingBy:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalDivide(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];
        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of multiplying the
    receiver object by \c decimalNumber. If overflow or loss of precision
    occurs then the consequence depends on the current default
    CPDecimalNumberHandler object.
    @param decimalNumber the decimal number to multiply the the receiver by
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByMultiplyingBy:(CPDecimalNumber)decimalNumber
{
    return [self decimalNumberByMultiplyingBy:decimalNumber withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of multiplying the
    receiver object by \c decimalNumber. If overflow or loss of precision
    occurs then the consequence depends on the CPDecimalNumberHandler object
    \e behavior.
    @param decimalNumber the decimal number to multiply the the receiver by
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByMultiplyingBy:(CPDecimalNumber)decimalNumber withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalMultiply(result, [self decimalValue], [decimalNumber decimalValue], [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:decimalNumber];

        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of multiplying the
    receiver object by (10 ^ \c power). If overflow, underflow or loss of
    precision occurs then the consequence depends on the current default
    CPDecimalNumberHandler object.
    @param power the power of 10 to multiply the receiver by
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByMultiplyingByPowerOf10:(short)power
{
    return [self decimalNumberByMultiplyingByPowerOf10:power withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of multiplying the
    receiver object by (10 ^ \c power). If overflow, underflow or loss of
    precision occurs then the consequence depends on the CPDecimalNumberHandler
    object \e behavior.
    @param power the power of 10 to multiply the receiver by
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByMultiplyingByPowerOf10:(short)power withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero(),
        error = CPDecimalMultiplyByPowerOf10(result, [self decimalValue], power, [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];

        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of raising the
    receiver object to the power \c power. If overflow, underflow or loss of
    precision occurs then the consequence depends on the current default
    CPDecimalNumberHandler object.
    @param power the power to raise the receiver by
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByRaisingToPower:(unsigned)power
{
    return [self decimalNumberByRaisingToPower:power withBehavior:[CPDecimalNumber defaultBehavior]];
}

/*!
    Returns a new CPDecimalNumber object with the result of raising the
    receiver object to the power \c power. If overflow, underflow or loss of
    precision occurs then the consequence depends on the CPDecimalNumberHandler
    object \e behavior.
    @param power the power to raise the receiver by
    @param behavior a CPDecimalNumberHandler object
    @return a new CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByRaisingToPower:(unsigned)power withBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    if (power < 0)
        return [behavior exceptionDuringOperation:_cmd error:-1 leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];

    var result = CPDecimalMakeZero(),
        error = CPDecimalPower(result, [self decimalValue], power, [behavior roundingMode]);

    if (error > CPCalculationNoError)
    {
        var res = [behavior exceptionDuringOperation:_cmd error:error leftOperand:self rightOperand:[CPDecimalNumber decimalNumberWithString:power.toString()]];

        if (res != nil)
            return res;
    }

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Returns a new CPDecimalNumber object with the result of rounding the number
    according to the rounding behavior specified by the CPDecimalNumberHandler
    object \e behavior.
    @param behavior a CPDecimalNumberHandler object
    @return a new rounded CPDecimalNumber object
*/
- (CPDecimalNumber)decimalNumberByRoundingAccordingToBehavior:(id <CPDecimalNumberBehaviors>)behavior
{
    var result = CPDecimalMakeZero();

    CPDecimalRound(result, [self decimalValue], [behavior scale], [behavior roundingMode]);

    return [CPDecimalNumber decimalNumberWithDecimal:result];
}

/*!
    Compare the receiver CPDecimalNumber to \c aNumber. This is a CPNumber or
    subclass. Returns \e CPOrderedDescending, \e CPOrderedAscending or
    \e CPOrderedSame.
    @param aNumber an object of kind CPNumber to compare against.
    @return result from \e CPComparisonResult enum.
*/
- (CPComparisonResult)compare:(CPNumber)aNumber
{
    // aNumber type is checked to convert if appropriate
    if (![aNumber isKindOfClass:[CPDecimalNumber class]])
        aNumber = [CPDecimalNumber decimalNumberWithString:aNumber.toString()];

    return CPDecimalCompare([self decimalValue], [aNumber decimalValue]);
}

/*!
    The objective C type string. For compatibility reasons
    @return returns a CPString containing "d"
*/
- (CPString)objCType
{
    return @"d";
}

/*!
    Returns a string representation of the decimal number.
    @return a CPString
*/
- (CPString)description
{
    return [self descriptionWithLocale:nil]
}

/*!
    Returns a string representation of the decimal number given the specified
    locale. Note: locales are currently unsupported
    @param locale the locale
    @return a CPString
*/
- (CPString)descriptionWithLocale:(CPDictionary)locale
{
    return CPDecimalString(_data, locale);
}

/*!
    Returns a string representation of the decimal number.
    @return a CPString
*/
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
/*!
    Returns a JS float representation. Truncation may occur.
    @return a JS float
*/
- (double)doubleValue
{
    // FIXME: locale support / bounds check?
    return parseFloat([self stringValue]);
}

/*!
    Returns a JS bool representation.
    @return a JS bool
*/
- (BOOL)boolValue
{
    return (CPDecimalIsZero(_data))?NO:YES;
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (char)charValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS float representation. Truncation may occur.
    @return a JS float
*/
- (float)floatValue
{
    // FIXME: locale support / bounds check?
    return parseFloat([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (int)intValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (long long)longLongValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (long)longValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (short)shortValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (unsigned char)unsignedCharValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (unsigned int)unsignedIntValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (unsigned long)unsignedLongValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

/*!
    Returns a JS int representation. Truncation may occur.
    @return a JS int
*/
- (unsigned short)unsignedShortValue
{
    // FIXME: locale support / bounds check?
    return parseInt([self stringValue]);
}

// CPNumber inherited methods
/*!
    Compare the receiver CPDecimalNumber to \c aNumber and return \e YES if
    equal.
    @param aNumber an object of kind CPNumber to compare against.
    @return a boolean
*/
- (BOOL)isEqualToNumber:(CPNumber)aNumber
{
    return (CPDecimalCompare(CPDecimalMakeWithString(aNumber.toString(),nil), _data) == CPOrderedSame)?YES:NO;
}

/*!
    Create a new CPDecimalNumber initialised with \e aBoolean.
    @param aBoolean a JS boolean value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithBool:(BOOL)aBoolean
{
    return [[self alloc] initWithBool:aBoolean];
}

/*!
    Create a new CPDecimalNumber initialised with \e aChar.
    @param aChar a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithChar:(char)aChar
{
    return [[self alloc] initWithChar:aChar];
}

/*!
    Create a new CPDecimalNumber initialised with \e aDouble.
    @param aDouble a JS float value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithDouble:(double)aDouble
{
    return [[self alloc] initWithDouble:aDouble];
}

/*!
    Create a new CPDecimalNumber initialised with \e aFloat.
    @param aFloat a JS float value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithFloat:(float)aFloat
{
    return [[self alloc] initWithFloat:aFloat];
}

/*!
    Create a new CPDecimalNumber initialised with \e anInt.
    @param anInt a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithInt:(int)anInt
{
    return [[self alloc] initWithInt:anInt];
}

/*!
    Create a new CPDecimalNumber initialised with \e aLong.
    @param aLong a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithLong:(long)aLong
{
    return [[self alloc] initWithLong:aLong];
}

/*!
    Create a new CPDecimalNumber initialised with \e aLongLong.
    @param aLongLong a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithLongLong:(long long)aLongLong
{
    return [[self alloc] initWithLongLong:aLongLong];
}

/*!
    Create a new CPDecimalNumber initialised with \e aShort.
    @param aShort a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithShort:(short)aShort
{
    return [[self alloc] initWithShort:aShort];
}

/*!
    Create a new CPDecimalNumber initialised with \e aChar.
    @param aChar a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithUnsignedChar:(unsigned char)aChar
{
    return [[self alloc] initWithUnsignedChar:aChar];
}

/*!
    Create a new CPDecimalNumber initialised with \e anUnsignedInt.
    @param anUnsignedInt a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithUnsignedInt:(unsigned)anUnsignedInt
{
    return [[self alloc] initWithUnsignedInt:anUnsignedInt];
}

/*!
    Create a new CPDecimalNumber initialised with \e aChar.
    @param aChar a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithUnsignedLong:(unsigned long)anUnsignedLong
{
    return [[self alloc] initWithUnsignedLong:anUnsignedLong];
}

/*!
    Create a new CPDecimalNumber initialised with \e anUnsignedLongLong.
    @param anUnsignedLongLong a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithUnsignedLongLong:(unsigned long)anUnsignedLongLong
{
    return [[self alloc] initWithUnsignedLongLong:anUnsignedLongLong];
}

/*!
    Create a new CPDecimalNumber initialised with \e anUnsignedShort.
    @param anUnsignedShort a JS int value
    @return a new CPDecimalNumber object
*/
+ (id)numberWithUnsignedShort:(unsigned short)anUnsignedShort
{
    return [[self alloc] initWithUnsignedShort:anUnsignedShort];
}

/*!
    Initialise the receiver with a boolean \e value.
    @param value a JS boolean value
    @return a reference to the initialised object
*/
- (id)initWithBool:(BOOL)value
{
    if (self = [self init])
        _data = CPDecimalMakeWithParts((value)?1:0, 0);
    return self;
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithChar:(char)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with a float \e value.
    @param value a JS float value
    @return a reference to the initialised object
*/
- (id)initWithDouble:(double)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with a float \e value.
    @param value a JS float value
    @return a reference to the initialised object
*/
- (id)initWithFloat:(float)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithInt:(int)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithLong:(long)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithLongLong:(long long)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithShort:(short)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithUnsignedChar:(unsigned char)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithUnsignedInt:(unsigned)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithUnsignedLong:(unsigned long)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
- (id)initWithUnsignedLongLong:(unsigned long long)value
{
    return [self _initWithJSNumber:value];
}

/*!
    Initialise the receiver with an int \e value.
    @param value a JS int value
    @return a reference to the initialised object
*/
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
