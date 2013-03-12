/*
 * CPDecimal.j
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

 /*
   Ported From GNUStep :

   NSDecimal functions
   Copyright (C) 2000 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
   Created: July 2000

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   <title>NSDecimal class reference</title>
   $Date: 2008-06-12 04:44:00 -0600 (Thu, 12 Jun 2008) $ $Revision: 26630 $
   */

@import "CPArray.j"
@import "CPNumber.j"

// Decimal size limits
CPDecimalMaxDigits                   =   38;
CPDecimalMaxExponent                 =  127;
CPDecimalMinExponent                 = -128;

// Scale for no Rounding
CPDecimalNoScale                     = 128

// CPCalculationError enum
CPCalculationNoError                 = 0;
CPCalculationLossOfPrecision         = 1;
CPCalculationOverflow                = 2;
CPCalculationUnderflow               = 3;
CPCalculationDivideByZero            = 4;

//CPRoundingMode Enum
CPRoundPlain                         = 1;
CPRoundDown                          = 2;
CPRoundUp                            = 3;
CPRoundBankers                       = 4;
_CPRoundHalfDown                     = 5; // Private API rounding mode used by CPNumberFormatter.

//Exceptions
CPDecimalNumberOverflowException     = @"CPDecimalNumberOverflowException";
CPDecimalNumberUnderflowException    = @"CPDecimalNumberUnderflowException";
CPDecimalNumberExactnessException    = @"CPDecimalNumberExactnessException";
CPDecimalNumberDivideByZeroException = @"CPDecimalNumberDivideByZeroException";

/*
Initialisers for NSDecimal do not exist so here I have created my own.
The coefficient is called the 'mantissa' in this implementation as this is what Cocoa calls it.

CPDecimal format:
    ._mantissa   : CPArray, containing each digit of the number as an unsigned integer.
    ._exponent   : integer, the exponent of the number as an signed integer.
    ._isNegative : BOOL, sign of number
    ._isCompact  : BOOL, has number been compacted.
    ._isNaN      : BOOL, is NaN (Not a number) i.e. number is invalid.
*/

/*!
    @ingroup foundation
    Creates a CPDecimal object from a string representation of the decimal number.
    @param decimalString CPString of number
    @param roundingMode Rounding mode for when number is too large to fit in mantissa.
    @return A CPDecimal object, or nil on error.
*/
// FIXME: locale support and Cocoaify, needs to accept .1 and leading 0s
function CPDecimalMakeWithString(string, locale)
{
    if (!string)
        return CPDecimalMakeNaN();

    // Regexp solution as found in JSON spec, with working regexp (I added groupings)
    // Test here: http://www.regexplanet.com/simple/index.html
    // Info from: http://stackoverflow.com/questions/638565/parsing-scientific-notation-sensibly
    // ([+\-]?)((?:0|[0-9]\d*))  - integer part, can have leading zeros (follows Cocoa behaviour)
    //  (?:\.(\d*))?           - optional decimal part plus number in group
    //  (?:[eE]([+\-]?)(\d+))?   - optional exponent part plus number in group
    // group 0: string, 1: sign, 2: integer, 3: decimal, 4: exponent sign, 5: exponent

    // Note: this doesn't accept .01 for example, should it?
    // If yes simply add '?' after integer part group, i.e. ([+\-]?)((?:0|[1-9]\d*)?)
    // Note: now it accept .01 style.
    var matches = string.match(/^([+\-]?)((?:0|[0-9]\d*)?)(?:\.(\d*))?(?:[eE]([+\-]?)(\d+))?$/);

    if (!matches)
        return CPDecimalMakeNaN();

    var ds = matches[1],
        intpart = matches[2],
        decpart = matches[3],
        es = matches[4],
        exp = matches[5];

    var isNegative = NO;

    if (ds && ds === "-")
        isNegative = YES;

    var exponent = 0;

    if (exp)
        exponent = parseInt(exp) * ((es && es === "-")?-1:1);

    if (decpart) // push decimal point to last digit, then let compact handle the zeros
        exponent -= decpart.length;

    var inputlength = (intpart?intpart.length:0) + (decpart?decpart.length:0);

    if (inputlength > CPDecimalMaxDigits)
    {
        // input is too long, increase exponent and truncate
        exponent += inputlength - CPDecimalMaxDigits;
    }
    else if (inputlength === 0)
    {
        return CPDecimalMakeNaN();
    }

    if (exponent > CPDecimalMaxExponent || exponent < CPDecimalMinExponent)
        return CPDecimalMakeNaN();

    // Representation internally starts at most significant digit
    var m = [],
        i = 0;

    for (; i < (intpart?intpart.length:0); i++)
    {
        if (i >= CPDecimalMaxDigits)
            break; // truncate
        Array.prototype.push.call(m, parseInt(intpart.charAt(i)));
    }

    var j = 0;

    for (; j < (decpart?decpart.length:0); j++)
    {
        if ((i + j) >= CPDecimalMaxDigits)
            break; // truncate

        Array.prototype.push.call(m, parseInt(decpart.charAt(j)));
    }

    var dcm = {_exponent:exponent, _isNegative:isNegative, _isCompact:NO, _isNaN:NO, _mantissa:m};
    CPDecimalCompact(dcm);

    return dcm;
}

/*!
    @ingroup foundation
    Creates a CPDecimal object from a given mantissa and exponent. The sign is taken from the sign of the mantissa. This cant do a full 34 digit mantissa representation as JS's 32 bits or 64bit binary FP numbers cant represent that. So use the CPDecimalMakeWithString if you want longer mantissa.
    @param mantissa the mantissa (though see above note)
    @param exponent the exponent
    @return A CPDecimal object, or nil on error.
*/
function CPDecimalMakeWithParts(mantissa, exponent)
{
    var m = [],
        isNegative = NO;

    if (mantissa < 0)
    {
        isNegative = YES;
        mantissa = ABS(mantissa);
    }

    if (mantissa == 0)
        Array.prototype.push.call(m, 0);

    if (exponent > CPDecimalMaxExponent || exponent < CPDecimalMinExponent)
        return CPDecimalMakeNaN();

    // remaining digits are disposed of via truncation
    while ((mantissa > 0) && (m.length < CPDecimalMaxDigits))
    {
        Array.prototype.unshift.call(m, parseInt(mantissa % 10));
        mantissa = FLOOR(mantissa / 10);
    }

    var dcm = {_exponent:exponent, _isNegative:isNegative, _isCompact:YES, _isNaN:NO, _mantissa:m};

    CPDecimalCompact(dcm);

    return dcm;
}

/*!
    @ingroup foundation
    Creates a CPDecimal 0.
    @return A CPDecimal object containing the value 0.
*/
function CPDecimalMakeZero()
{
    return CPDecimalMakeWithParts(0, 0);
}

/*!
    @ingroup foundation
    Creates a CPDecimal 1.
    @return A CPDecimal object containing the value 1.
*/
function CPDecimalMakeOne()
{
    return CPDecimalMakeWithParts(1, 0);
}


/*!
    @ingroup foundation
    Creates a CPDecimal NaN.
    @return A CPDecimal object containing the value NaN
*/
function CPDecimalMakeNaN()
{
    var d = CPDecimalMakeWithParts(0, 0);
    d._isNaN = YES;
    return d;
}

// private methods
function _CPDecimalMakeMaximum()
{
    var s = @"",
        i = 0;
    for (; i < CPDecimalMaxDigits; i++)
        s += "9";
    s += "e" + CPDecimalMaxExponent;
    return CPDecimalMakeWithString(s);
}

function _CPDecimalMakeMinimum()
{
    var s = @"-",
        i = 0;
    for (; i < CPDecimalMaxDigits; i++)
        s += "9";
    s += "e" + CPDecimalMaxExponent;
    return CPDecimalMakeWithString(s);
}

/*!
    @ingroup foundation
    Checks to see if a CPDecimal is zero. Can handle uncompacted strings.
    @return TRUE on zero.
*/
function CPDecimalIsZero(dcm)
{
    // exponent doesn't matter as long as mantissa = 0
    if (!dcm._isNaN)
    {
        for (var i = 0; i < dcm._mantissa.length; i++)
            if (dcm._mantissa[i] !== 0)
                return NO;

        return YES;
    }

    return NO;
}

/*!
    @ingroup foundation
    Checks to see if a CPDecimal is 1. Can handle uncompacted strings (it compacts them).
    @return TRUE on 1.
*/
function CPDecimalIsOne(dcm)
{
    CPDecimalCompact(dcm);

    // exponent doesn't matter as long as mantissa = 0
    if (!dcm._isNaN)
    {
        if (dcm._mantissa && (dcm._mantissa.length == 1) && (dcm._mantissa[0] == 1))
            return YES;
    }
    return NO;
}

//private method to copy attribute values
function _CPDecimalSet(t, s)
{
    // should all be [x copy] ?
    t._exponent = s._exponent;
    t._isNegative = s._isNegative;
    t._isCompact = s._isCompact;
    t._isNaN = s._isNaN;
    t._mantissa = Array.prototype.slice.call(s._mantissa, 0);
}

function _CPDecimalSetZero(result)
{
    result._mantissa = [0];
    result._exponent = 0;
    result._isNegative = NO;
    result._isCompact = YES;
    result._isNaN = NO;
}

function _CPDecimalSetOne(result)
{
    result._mantissa = [1];
    result._exponent = 0;
    result._isNegative = NO;
    result._isCompact = YES;
    result._isNaN = NO;
}

/*!
    @ingroup foundation
    Checks to see if a CPDecimal is Not A Number.
    @return TRUE on NaN.
*/
function CPDecimalIsNotANumber(dcm)
{
    return (dcm._isNaN)?YES:NO;
}

/*!
    @ingroup foundation
    Create a copy of a CPDecimal object
    @param dcm the CPDecimal number to copy.
    @return a new CPDecimal.
*/
function CPDecimalCopy(dcm)
{
    return {_exponent:dcm._exponent,
            _isNegative:dcm._isNegative,
            _isCompact:dcm._isCompact,
            _isNaN:dcm._isNaN,
            _mantissa:Array.prototype.slice.call(dcm._mantissa, 0)
            };
}

/*!
    @ingroup foundation
    Compare two CPDecimal objects. Order is left to right (i.e. Ascending would
    mean left is smaller than right operand).
    @param leftOperand the left CPDecimal
    @param rightOperand the right CPDecimal
    @return CPOrderedAscending, CPOrderedDescending or CPOrderedSame.
*/
function CPDecimalCompare(leftOperand, rightOperand)
{
    if (leftOperand._isNaN && rightOperand._isNaN)
        return CPOrderedSame;

    if (leftOperand._isNegative != rightOperand._isNegative)
    {
        if (rightOperand._isNegative)
            return CPOrderedDescending;
        else
            return CPOrderedAscending;
    }

    // Before comparing number size check if zero (dont use CPDecimalIsZero as it is more computationally intensive)
    var leftIsZero = (leftOperand._mantissa.length == 1 && leftOperand._mantissa[0] == 0),
        rightIsZero = (rightOperand._mantissa.length == 1 && rightOperand._mantissa[0] == 0),
        // Sign is the same, quick check size (length + exp)
        s1 = leftOperand._exponent + leftOperand._mantissa.length,
        s2 = rightOperand._exponent + rightOperand._mantissa.length;

    if (leftIsZero && rightIsZero)
        return CPOrderedSame;

    if (leftIsZero || (s1 < s2 && !rightIsZero))
    {
        if (rightOperand._isNegative)
            return CPOrderedDescending;
        else
            return CPOrderedAscending;
    }
    if (rightIsZero || (s1 > s2 && !leftIsZero))
    {
        if (leftOperand._isNegative)
            return CPOrderedAscending;
        else
            return CPOrderedDescending;
    }

    // Same size, so check mantissa
    var l = MIN(leftOperand._mantissa.length, rightOperand._mantissa.length),
        i = 0;

    for (; i < l; i++)
    {
        var d = rightOperand._mantissa[i] - leftOperand._mantissa[i];

        if (d > 0)
        {
            if (rightOperand._isNegative)
                return CPOrderedDescending;
            else
                return CPOrderedAscending;
        }
        if (d < 0)
        {
            if (rightOperand._isNegative)
                return CPOrderedAscending;
            else
                return CPOrderedDescending;
        }
    }

    // Same digits, check length
    if (leftOperand._mantissa.length > rightOperand._mantissa.length)
    {
        if (rightOperand._isNegative)
            return CPOrderedAscending;
        else
            return CPOrderedDescending;
    }
    if (leftOperand._mantissa.length < rightOperand._mantissa.length)
    {
        if (rightOperand._isNegative)
            return CPOrderedDescending;
        else
            return CPOrderedAscending;
    }

    return CPOrderedSame;
}

// GNUSteps addition. This is standard O(n) complexity.
// longMode makes the addition not round for up to double max digits, this is
// to preserve precision during multiplication
function _SimpleAdd(result, leftOperand, rightOperand, roundingMode, longMode)
{
    var factor = (longMode)?2:1;

    _CPDecimalSet(result, leftOperand);

    var j = leftOperand._mantissa.length - rightOperand._mantissa.length,
        l = rightOperand._mantissa.length,
        i = l - 1,
        carry = 0,
        error = CPCalculationNoError;

    // Add all the digits
    for (; i >= 0; i--)
    {
        var d = rightOperand._mantissa[i] + result._mantissa[i + j] + carry;
        if (d >= 10)
        {
            d = d % 10;  // a division. subtraction and conditions faster?
            carry = 1;
        }
        else
            carry = 0;

        result._mantissa[i + j] = d;
    }

    if (carry)
    {
        for (i = j - 1; i >= 0; i--)
        {
            if (result._mantissa[i] != 9)
            {
                result._mantissa[i]++;
                carry = 0;
                break;
            }
            result._mantissa[i] = 0;
        }

        if (carry)
        {
            Array.prototype.splice.call(result._mantissa, 0, 0, 1);

            // The number must be shifted to the right
            if ((CPDecimalMaxDigits * factor) == leftOperand._mantissa.length)
            {
                var scale = - result._exponent - 1;
                CPDecimalRound(result, result, scale, roundingMode);
            }

            if (CPDecimalMaxExponent < result._exponent)
            {
                result._isNaN = YES;
                error = CPCalculationOverflow;
                result._exponent = CPDecimalMaxExponent;
            }
        }
    }
    return error;
}

/*!
    @ingroup foundation
    Performs the addition of 2 CPDecimal numbers.
    @param result the CPDecimal object in which to put the result
    @param leftOperand the left CPDecimal operand
    @param rightOperand the right CPDecimal operand
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalAdd(result, leftOperand, rightOperand, roundingMode, longMode)
{
    if (leftOperand._isNaN || rightOperand._isNaN)
    {
        result._isNaN = YES;
        return CPCalculationNoError;
    }

    // check for zero
    if (CPDecimalIsZero(leftOperand))
    {
        _CPDecimalSet(result, rightOperand);
        return CPCalculationNoError;
    }

    if (CPDecimalIsZero(rightOperand))
    {
        _CPDecimalSet(result, leftOperand);
        return CPCalculationNoError;
    }

    var n1 = CPDecimalCopy(leftOperand),
        n2 = CPDecimalCopy(rightOperand);

    // For different signs use subtraction
    if (leftOperand._isNegative != rightOperand._isNegative)
    {
        if (leftOperand._isNegative)
        {
            n1._isNegative = NO;
            return CPDecimalSubtract(result, rightOperand, n1, roundingMode);
        }
        else
        {
            n2._isNegative = NO;
            return CPDecimalSubtract(result, leftOperand, n2, roundingMode);
        }
    }

    var normerror = CPDecimalNormalize(n1, n2, roundingMode, longMode);

    // below is equiv. of simple compare
    var comp = 0,
        ll = n1._mantissa.length,
        lr = n2._mantissa.length;

    if (ll == lr)
        comp = CPOrderedSame;
    else if (ll > lr)
        comp = CPOrderedDescending;
    else
        comp = CPOrderedAscending;

    // both negative, make positive
    if (leftOperand._isNegative)
    {
        n1._isNegative = NO;
        n2._isNegative = NO;

        // SimpleCompare does not look at sign
        if (comp == CPOrderedDescending)
        {
            adderror = _SimpleAdd(result, n1, n2, roundingMode, longMode);
        }
        else
        {
            adderror = _SimpleAdd(result, n2, n1, roundingMode, longMode);
        }

        result._isNegative = YES;

        // swap sign over over/underflow exception
        if (CPCalculationUnderflow == adderror)
            adderror = CPCalculationOverflow;
        else if (CPCalculationUnderflow == adderror)
            adderror = CPCalculationUnderflow;
    }
    else
    {
        if (comp == CPOrderedAscending)
        {
            adderror = _SimpleAdd(result, n2, n1, roundingMode, longMode);
        }
        else
        {
            adderror = _SimpleAdd(result, n1, n2, roundingMode, longMode);
        }
    }

    CPDecimalCompact(result);

    if (adderror == CPCalculationNoError)
        return normerror;
    else
        return adderror;
}

// GNUStep port internal subtract
function _SimpleSubtract(result, leftOperand, rightOperand, roundingMode)
{
    var error = CPCalculationNoError,
        borrow = 0,
        l = rightOperand._mantissa.length,
        j = leftOperand._mantissa.length - l,
        i = l - 1;

    _CPDecimalSet(result, leftOperand);

    // Now subtract all digits
    for (; i >= 0; i--)
    {
        var d = result._mantissa[i + j] - rightOperand._mantissa[i] - borrow;

        if (d < 0)
        {
            d = d + 10;
            borrow = 1;
        }
        else
            borrow = 0;

        result._mantissa[i + j] = d;
    }

    if (borrow)
    {
        for (i = j - 1; i >= 0; i--)
        {
            if (result._mantissa[i] != 0)
            {
                result._mantissa[i]--;
                break;
            }
            result._mantissa[i] = 9;
        }

        if (-1 == i)
        {
            error = nil;
        }
    }

    return error;
}

/*!
    @ingroup foundation
    Performs the subtraction of 2 CPDecimal numbers.
    @param result the CPDecimal object in which to put the result
    @param leftOperand the left CPDecimal operand
    @param rightOperand the right CPDecimal operand
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalSubtract(result, leftOperand, rightOperand, roundingMode)
{
    if (leftOperand._isNaN || rightOperand._isNaN)
    {
        result._isNaN = YES;
        return CPCalculationNoError;
    }

    // check for zero
    if (CPDecimalIsZero(leftOperand))
    {
        _CPDecimalSet(result, rightOperand);
        result._isNegative = !result._isNegative;
        return CPCalculationNoError;
    }

    if (CPDecimalIsZero(rightOperand))
    {
        _CPDecimalSet(result, leftOperand);
        return CPCalculationNoError;
    }

    var n1 = CPDecimalCopy(leftOperand),
        n2 = CPDecimalCopy(rightOperand),
        error1 = CPCalculationNoError;

    // For different signs use addition
    if (leftOperand._isNegative != rightOperand._isNegative)
    {
        if (leftOperand._isNegative)
        {
            n1._isNegative = NO;
            error1 = CPDecimalAdd(result, n1, rightOperand, roundingMode);
            result._isNegative = YES;

            if (error1 == CPCalculationUnderflow)
                error1 = CPCalculationOverflow;
            else if (error1 == CPCalculationOverflow) // gnustep has bug here
                error1 = CPCalculationUnderflow;

            return error1;
        }
        else
        {
            n2._isNegative = NO;
            return CPDecimalAdd(result, leftOperand, n2, roundingMode);
        }
    }

    var error = CPDecimalNormalize(n1, n2, roundingMode),
        comp = CPDecimalCompare(leftOperand, rightOperand);

    if (comp == CPOrderedSame)
    {
        _CPDecimalSetZero(result);
        return CPCalculationNoError;
    }

    // both negative, make positive and change order
    if (leftOperand._isNegative)
    {
        n1._isNegative = NO;
        n2._isNegative = NO;

        if (comp == CPOrderedAscending)
        {
            error1 = _SimpleSubtract(result, n1, n2, roundingMode);
            result._isNegative = YES;
        }
        else
        {
            error1 = _SimpleSubtract(result, n2, n1, roundingMode);
        }
    }
    else
    {
        if (comp == CPOrderedAscending)
        {
            error1 = _SimpleSubtract(result, n2, n1, roundingMode);
            result._isNegative = YES;
        }
        else
        {
            error1 = _SimpleSubtract(result, n1, n2, roundingMode);
        }
    }

    CPDecimalCompact(result);

    if (error1 == CPCalculationNoError)
        return error;
    else
        return error1;
}

// this is a very simple O(n^2) implementation that uses subtract. Are there faster divides?
function _SimpleDivide(result, leftOperand, rightOperand, roundingMode)
{
    var error = CPCalculationNoError,
        n1 = CPDecimalMakeZero(),
        k = 0,
        firsttime = YES,
        stopk = CPDecimalMaxDigits + 1,
        used = 0; // How many digits of l have been used?

    _CPDecimalSetZero(result);

    n1._mantissa = [];

    while ((used < leftOperand._mantissa.length) || (n1._mantissa.length
                                                    && !((n1._mantissa.length == 1) && (n1._mantissa[0] == 0))))
    {
        while (CPOrderedAscending == CPDecimalCompare(n1, rightOperand))
        {
            if (stopk == k)
                break;

            if (n1._exponent)
            {
                // Put back zeros removed by compacting
                Array.prototype.push.call(n1._mantissa, 0);
                n1._exponent--;
                n1._isCompact = NO;
            }
            else
            {
                if (used < leftOperand._mantissa.length)
                {
                    // Fill up with own digits
                    if (n1._mantissa.length || leftOperand._mantissa[used])
                    {
                        // only add 0 if there is already something
                        Array.prototype.push.call(n1._mantissa, (leftOperand._mantissa[used]));
                        n1._isCompact = NO;
                    }

                    used++;
                }
                else
                {
                    if (result._exponent == CPDecimalMinExponent)
                    {
                        // use this as an end flag
                        k = stopk;
                        break;
                    }

                    // Borrow one digit
                    Array.prototype.push.call(n1._mantissa, 0);
                    result._exponent--;
                }

                // Zeros must be added while enough digits are fetched to do the
                // subtraction, but first time round this just add zeros at the
                // start of the number , increases k, and hence reduces
                // the available precision. To solve this only inc k/add zeros if
                // this isn't first time round.
                if (!firsttime)
                {
                    k++;
                    result._mantissa[k - 1] = 0;
                }
            }
        }

        // At this point digit in result we are working on is (k-1) so when
        // k == (CPDecimalMaxDigits+1) then we should stop i.e. last subtract
        // was last valid one.
        if (stopk == k)
        {
            error = CPCalculationLossOfPrecision;
            break;
        }

        if (firsttime)
        {
            firsttime = NO;
            k++;
        }

        error1 = CPDecimalSubtract(n1, n1, rightOperand, roundingMode);

        if (error1 != CPCalculationNoError)
            error = error1;

        result._mantissa[k - 1]++;
    }

    return error;
}

/*!
    @ingroup foundation
    Performs a division of 2 CPDecimal numbers.
    @param result the CPDecimal object in which to put the result
    @param leftOperand the left CPDecimal operand
    @param rightOperand the right CPDecimal operand
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalDivide(result, leftOperand, rightOperand, roundingMode)
{
    var error = CPCalculationNoError,
        exp = leftOperand._exponent - rightOperand._exponent,
        neg = (leftOperand._isNegative != rightOperand._isNegative);

    if (leftOperand._isNaN || rightOperand._isNaN)
    {
        result._isNaN = YES;
        return CPCalculationNoError;
    }

    // check for zero
    if (CPDecimalIsZero(rightOperand))
    {
        result._isNaN = YES;
        return CPCalculationDivideByZero;
    }

    if (CPDecimalIsZero(leftOperand))
    {
        _CPDecimalSetZero(result);
        return CPCalculationNoError;
    }

    //FIXME: Should also check for one

    var n1 = CPDecimalCopy(leftOperand),
        n2 = CPDecimalCopy(rightOperand);

    n1._exponent = 0;
    n1._isNegative = NO;
    n2._exponent = 0;
    n2._isNegative = NO;

    error = _SimpleDivide(result, n1, n2, roundingMode);
    CPDecimalCompact(result);

    if (result._exponent + exp > CPDecimalMaxExponent)
    {
        result._isNaN = YES;
        if (neg)
            return CPCalculationUnderflow;
        else
            return CPCalculationOverflow;
    }
    else if (result._exponent + exp < CPDecimalMinExponent)
    {
        // We must cut off some digits
        CPDecimalRound(result, result, exp + CPDecimalMaxExponent + 1, roundingMode);
        error = CPCalculationLossOfPrecision;

        if (result._exponent + exp < CPDecimalMinExponent)
        {
            CPDecimalSetZero(result);
            return error;
        }
    }

    result._exponent += exp;
    result._isNegative = neg;
    return error;
}

// Simple multiply O(n^2) , replace with something faster, like divide-n-conquer algo?
function _SimpleMultiply(result, leftOperand, rightOperand, roundingMode, powerMode)
{
    var error = CPCalculationNoError,
        carry = 0,
        exp = 0,
        n = CPDecimalMakeZero();

    _CPDecimalSetZero(result);

    // Do every digit of the second number
    for (var i = 0; i < rightOperand._mantissa.length; i++)
    {
        _CPDecimalSetZero(n);

        n._exponent = rightOperand._mantissa.length - i - 1;
        carry = 0;
        d = rightOperand._mantissa[i];

        if (d == 0)
            continue;

        for (var j = leftOperand._mantissa.length - 1; j >= 0; j--)
        {
            e = leftOperand._mantissa[j] * d + carry;

            if (e >= 10)
            {
                carry = FLOOR(e / 10);
                e = e % 10;
            }
            else
                carry = 0;

            // This is one off to allow final carry
            n._mantissa[j + 1] = e;
        }

        n._mantissa[0] = carry;

        CPDecimalCompact(n);

        error1 = CPDecimalAdd(result, result, n, roundingMode, YES);

        if (error1 != CPCalculationNoError)
            error = error1;
    }

    if (result._exponent + exp > CPDecimalMaxExponent)
    {
        // This should almost never happen
        result._isNaN = YES;
        return CPCalculationOverflow;
    }

    result._exponent += exp;

    // perform round to CPDecimalMaxDigits
    if (result._mantissa.length > CPDecimalMaxDigits && !powerMode)
    {
        result._isCompact = NO;

        var scale = CPDecimalMaxDigits - (result._mantissa.length + result._exponent);
        CPDecimalRound(result, result, scale, roundingMode); // calls compact

        error = CPCalculationLossOfPrecision;
    }

    return error;
}

/*!
    @ingroup foundation
    Performs multiplication of 2 CPDecimal numbers.
    @param result the CPDecimal object in which to put the result
    @param leftOperand the left CPDecimal operand
    @param rightOperand the right CPDecimal operand
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalMultiply(result, leftOperand, rightOperand, roundingMode, powerMode)
{
    var error = CPCalculationNoError,
        exp = leftOperand._exponent + rightOperand._exponent,
        neg = (leftOperand._isNegative != rightOperand._isNegative);

    if (leftOperand._isNaN || rightOperand._isNaN)
    {
        result._isNaN = YES;
        return CPCalculationNoError;
    }

    // check for zero
    if (CPDecimalIsZero(rightOperand) || CPDecimalIsZero(leftOperand))
    {
        _CPDecimalSetZero(result);
        return CPCalculationNoError;
    }

    //FIXME: Should also check for one

    if (exp > CPDecimalMaxExponent)
    {
        result._isNaN = YES;

        if (neg)
            return CPCalculationUnderflow;
        else
            return CPCalculationOverflow;
    }

    var n1 = CPDecimalCopy(leftOperand),
        n2 = CPDecimalCopy(rightOperand);

    n1._exponent = 0;
    n2._exponent = 0;
    n1._isNegative = NO;
    n2._isNegative = NO;

    // below is equiv. of simple compare
    var comp = 0,
        ll = n1._mantissa.length,
        lr = n2._mantissa.length;

    if (ll == lr)
        comp = CPOrderedSame;
    else if (ll > lr)
        comp = CPOrderedDescending;
    else
        comp = CPOrderedAscending;

    if (comp == CPOrderedDescending)
    {
        error = _SimpleMultiply(result, n1, n2, roundingMode, powerMode);
    }
    else
    {
        error = _SimpleMultiply(result, n2, n1, roundingMode, powerMode);
    }

    CPDecimalCompact(result);

    if (result._exponent + exp > CPDecimalMaxExponent)
    {
        result._isNaN = YES;

        if (neg)
            return CPCalculationUnderflow;
        else
            return CPCalculationOverflow;
    }
    else if (result._exponent + exp < CPDecimalMinExponent)
    {
        // We must cut off some digits
        CPDecimalRound(result, result, exp + CPDecimalMaxExponent + 1, roundingMode);
        error = CPCalculationLossOfPrecision;

        if (result._exponent + exp < CPDecimalMinExponent)
        {
            _CPDecimalSetZero(result);
            return error;
        }
    }

    result._exponent += exp;
    result._isNegative = neg;

    return error;
}

/*!
    @ingroup foundation
    Raises a CPDecimal number to a power of 10.
    @param result the CPDecimal object in which to put the result
    @param dcm the CPDecimal operand
    @param power the power to raise to
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalMultiplyByPowerOf10(result, dcm, power, roundingMode)
{
    _CPDecimalSet(result, dcm);

    var p = result._exponent + power;

    if (p > CPDecimalMaxExponent)
    {
        result._isNaN = YES;
        return CPCalculationOverflow;
    }

    if (p < CPDecimalMinExponent)
    {
        result._isNaN = YES;
        return CPCalculationUnderflow;
    }

    result._exponent += power;
    return CPCalculationNoError;
}

/*!
    @ingroup foundation
    Raises a CPDecimal number to the given power.
    @param result the CPDecimal object in which to put the result
    @param dcm the CPDecimal operand
    @param power the power to raise to
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalPower(result, dcm, power, roundingMode)
{
    var error = CPCalculationNoError,
        neg = (dcm._isNegative && (power % 2)),
        n1 = CPDecimalCopy(dcm);

    n1._isNegative = NO;

    _CPDecimalSetOne(result);

    var e = power;

    while (e)
    {
        if (e & 1)
        {
            error = CPDecimalMultiply(result, result, n1, roundingMode); //, YES); // enable for high precision powers
        }

        error = CPDecimalMultiply(n1, n1, n1, roundingMode); //, YES); // enable for high precision powers

        e >>= 1;

        if (error > CPCalculationLossOfPrecision)
            break;
    }

    result._isNegative = neg;

/*  // enable is powerMode to do finally rounding to Max Digits.
    if ([result._mantissa count] > CPDecimalMaxDigits)
    {
        result._isCompact = NO;
        var scale = CPDecimalMaxDigits - ([result._mantissa count] + result._exponent);
        CPDecimalRound(result, result, scale ,roundingMode); // calls compact
        error = CPCalculationLossOfPrecision;
    }
*/

    CPDecimalCompact(result);

    return error;
}

/*!
    @ingroup foundation
    Normalises 2 CPDecimals. Normalisation is the process of modifying a
    numbers mantissa to ensure that both CPDecimals have the same exponent.
    @param dcm1 the first CPDecimal
    @param dcm2 the second CPDecimal
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalNormalize(dcm1, dcm2, roundingMode, longMode)
{
    var factor = (longMode) ? 2 : 1;

    if (dcm1._isNaN || dcm2._isNaN)
        return CPCalculationNoError; // FIXME: correct behavior?

    // ensure compact
    if (!dcm1._isCompact)
        CPDecimalCompact(dcm1);

    if (!dcm2._isCompact)
        CPDecimalCompact(dcm2);

    if (dcm1._exponent == dcm2._exponent)
        return CPCalculationNoError;

    var e1 = dcm1._exponent,
        e2 = dcm2._exponent;

    // Add zeros
    var l2 = dcm2._mantissa.length,
        l1 = dcm1._mantissa.length,
        l = 0;

    var e = 0;

    if (e2 > e1 && e1 >= 0 && e2 >= 0)
        e = e2 - e1;
    else if (e2 > e1 && e1 < 0 && e2 >= 0)
        e = e2 - e1;
    else if (e2 > e1 && e1 < 0 && e2 < 0)
        e = e2 - e1;
    else if (e2 < e1 && e1 >= 0 && e2 >= 0)
        e = e1 - e2;
    else if (e2 < e1 && e1 >= 0 && e2 < 0)
        e = e1 - e2;
    else if (e2 < e1 && e1 < 0 && e2 < 0)
        e = e1 - e2;

    if (e2 > e1)
        l = MIN((CPDecimalMaxDigits * factor) - l2, e); //(e2 - e1));
    else
        l = MIN((CPDecimalMaxDigits * factor) - l1, e); //(e1 - e2));

    for (var i = 0; i < l; i++)
    {
        if (e2 > e1)
            Array.prototype.push.call(dcm2._mantissa, 0); //dcm2._mantissa[i + l2] = 0;
        else
            Array.prototype.push.call(dcm1._mantissa, 0);
    }

    if (e2 > e1)
    {
        dcm2._exponent -= l;
        dcm2._isCompact = NO;
    }
    else
    {
        dcm1._exponent -= l;
        dcm1._isCompact = NO;
    }

    // has been normalised?
    if (l != ABS(e2 - e1))//e2 - e1)
    {
        // no..
        // Round of some digits to increase exponent - will compact too
        // One number may become zero after this
        if (e2 > e1)
        {
            CPDecimalRound(dcm1, dcm1, -dcm2._exponent, roundingMode);
            l1 = CPDecimalIsZero(dcm1);
        }
        else
        {
            CPDecimalRound(dcm2, dcm2, -dcm1._exponent, roundingMode);
            l2 = CPDecimalIsZero(dcm2);
        }

        if ((dcm1._exponent != dcm2._exponent) && ((!l1) || (!l2)))
        {
            // Some zeros where cut of again by compacting
            if (e2 > e1)
            {
                l1 = dcm1._mantissa.length;
                l = MIN((CPDecimalMaxDigits * factor) - l1, ABS(dcm1._exponent - dcm2._exponent));
                for (var i = 0; i < l; i++)
                {
                    dcm1._mantissa[i + l1] = 0; // or addObject: ? one faster than other?
                }
                dcm1._isCompact = NO;
                dcm1._exponent = dcm2._exponent;
            }
            else
            {
                l2 = dcm2._mantissa.length;
                l = MIN((CPDecimalMaxDigits * factor) - l2, ABS(dcm2._exponent - dcm1._exponent));
                for (var i = 0; i < l; i++)
                {
                    dcm2._mantissa[i + l2] = 0; // or addObject: ? one faster than other?
                }
                dcm2._exponent = dcm1._exponent;
                dcm2._isCompact = NO;
            }
        }

        return CPCalculationLossOfPrecision;
    }

    return CPCalculationNoError;
}

/*!
    @ingroup foundation
    Rounds a CPDecimal off at a given decimal position. scale specifies the
    position. Negative values of scale imply rounding in the whole numbers and
    positive values rounding in the decimal places. A scale of 0 rounds to
    the first whole number.
    @param result the CPDecimal object in which to put the result
    @param dcm the CPDecimal operand
    @param scale the position to round to
    @param roundingMode the rounding mode for the operation
    @return a CPCalculationError status value.
*/
function CPDecimalRound(result, dcm, scale, roundingMode)
{
    _CPDecimalSet(result, dcm);

    if (dcm._isNaN)
        return;

    if (!dcm._isCompact)
        CPDecimalCompact(dcm);

    // FIXME: check for valid inputs (eg scale etc)

    // FIXME: if in longMode should this double?
    if (scale == CPDecimalNoScale)
        return;

    var mc = result._mantissa.length,
        l = mc + scale + result._exponent;

    if (mc <= l)
        return;

    else if (l <= 0)
    {
        _CPDecimalSetZero(result);
        return;
    }
    else
    {
        var c = 0,
            n = 0,
            up = 0;

        // Adjust length and exponent
        result._exponent += mc - l;

        switch (roundingMode)
        {
            case CPRoundDown:
                up = result._isNegative;
                break;

            case CPRoundUp:
                up = !result._isNegative;
                break;

            case CPRoundPlain:
                n = result._mantissa[l];
                up = (n >= 5);
                break;

            case _CPRoundHalfDown:
                n = result._mantissa[l];
                up = (n > 5);
                break;

            case CPRoundBankers:
                n = result._mantissa[l];

                if (n > 5)
                    up = YES;
                else if (n < 5)
                    up = NO;
                else
                {
                    if (l == 0)
                        c = 0;
                    else
                        c = result._mantissa[l - 1];
                    up = ((c % 2) != 0);
                }
                break;

            default:
                up = NO;
                break;
        }

        // cut mantissa
        result._mantissa = Array.prototype.slice.call(result._mantissa, 0, l);

        if (up)
        {
            for (var i = l-1; i >= 0; i--)
            {
                if (result._mantissa[i] != 9)
                {
                    result._mantissa[i]++;
                    break;
                }

                result._mantissa[i] = 0;
            }

            // Final overflow?
            if (i == -1)
            {
                // As all digits are zeros, just change the first
                result._mantissa[0] = 1;

                if (result._exponent >= CPDecimalMaxExponent)
                {
                    // Overflow in rounding.
                    // Add one zero add the end. There must be space as
                    // we just cut off some digits.
                    Array.prototype.push.call(result._mantissa, 0);
                }
                else
                    result._exponent++;
            }
        }
    }

    CPDecimalCompact(result);
}

/*!
    @ingroup foundation
    Remove trailing and leading zeros from mantissa.
    @param dcm the CPDecimal operand
*/
function CPDecimalCompact(dcm)
{
    // if positive or zero exp leading zeros simply delete, trailing ones u need to increment exponent
    if (!dcm || dcm._mantissa.length == 0 || CPDecimalIsNotANumber(dcm))
        return;

    if (CPDecimalIsZero(dcm))
    {
        // handle zero number compacting
        _CPDecimalSetZero(dcm);
        return;
    }

    // leading zeros, when exponent is zero these mean we need to move our decimal point to compact
    // if exp is zero does it make sense to have them? don't think so so delete them
    while (dcm._mantissa[0] === 0)
        Array.prototype.shift.call(dcm._mantissa);

    // trailing zeros, strip them
    while (dcm._mantissa[dcm._mantissa.length - 1] === 0)
    {
        Array.prototype.pop.call(dcm._mantissa);
        dcm._exponent++;

        if (dcm._exponent + 1 > CPDecimalMaxExponent)
        {
          // TODO: test case for this
          // overflow if we compact anymore, so don't
          break;
        }
    }

    dcm._isCompact = YES;
}

/*!
    @ingroup foundation
    Convert a CPDecimal to a string representation.
    @param dcm the CPDecimal operand
    @param locale the locale to use for the conversion
    @return a CPString
*/
function CPDecimalString(dcm, locale)
{
    // Cocoa seems to just add all the zeros... this maybe controlled by locale,
    // will check.
    if (dcm._isNaN)
        return @"NaN";

    var string = @"",
        i = 0;

    if (dcm._isNegative)
        string += "-";

    var k = dcm._mantissa.length,
        l = ((dcm._exponent < 0) ? dcm._exponent : 0) + k;

    if (l < 0)
    {
        // add leading zeros
        string += "0.";
        for (i = 0; i < ABS(l); i++)
        {
            string += "0";
        }
        l = k;
    }
    else if (l == 0)
    {
        string += "0";
    }

    for (i = 0; i < l; i++)
    {
        string += dcm._mantissa[i];
    }

    if (l < k)
    {
        string += ".";
        for (i = l; i < k; i++)
        {
            string += dcm._mantissa[i];
        }
    }

    for (i = 0; i < dcm._exponent; i++)
    {
        string += "0";
    }

    return string;
 /*
    // GNUStep
    if (dcm._isNaN)
        return @"NaN";

    var sep = 0;
    if ((locale == nil) || (sep = [locale objectForKey: CPDecimalSeparator]) == nil)
        sep = @".";

    if (CPDecimalIsZero(dcm))
        return @"0" + sep + "0";

    var string = @"";

    if (dcm._isNegative)
        string += "-";

    var len = [dcm._mantissa count],
        size = len + dcm._exponent;

    if ((len <= 6) && (0 < size) && (size < 7))
    {
        // For small numbers use the normal format
        var i = 0
        for (; i < len; i++)
        {
            if (size == i)
                string += sep;
            d = dcm._mantissa[i];
            string += d.toString();
        }
        for (i = 0; i < dcm._exponent; i++)
        {
            string += "0";
        }
    }
    else if ((len <= 6) && (0 >= size) && (size > -3))
    {
        // For small numbers use the normal format
        string += "0";
        string += sep;

        var i = 0;
        for (; i > size; i--)
        {
            string += "0";
        }
        for (i = 0; i < len; i++)
        {
            d = dcm._mantissa[i];
            string += d.toString();
        }
    }
    else
    {
        // Scientific format
        var i = 0;
        for (; i < len; i++)
        {
            if (1 == i)
                string += sep;
            d = dcm._mantissa[i];
            string += d.toString();
        }
        if (size != 1)
        {
            //s = [NSString stringWithFormat: @"E%d", size-1];
            //[string appendString: s];
            string += "E" + (size - 1).toString();
        }
    }

  return string;
  */
}
