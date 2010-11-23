/*
 * CPDecimalNumberHandlerTest.j
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

@import <Foundation/CPString.j>
@import <Foundation/CPDecimalNumber.j>

@implementation CPDecimalNumberHandlerTest : OJTestCase

- (void)testinitWithRoundingMode
{
    var h1 = [CPDecimalNumberHandler alloc];

    [self assertTrue:h1 message:"T1 initWithRoundingMode: failed to alloc"];

    [h1 initWithRoundingMode:CPRoundPlain scale:3 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];

    [self assert:3 equals:[h1 scale] message:"T1 initWithRoundingMode: scale wrong"];
}

- (void)testdecimalNumberHandlerWithRoundingMode
{
    var h1 = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundPlain scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];

    [self assertTrue:h1 message:"T1 decimalNumberHandlerWithRoundingMode: returned nil"];

    [self assertTrue:[h1 roundingMode] message:"T1 decimalNumberHandlerWithRoundingMode: rounding mode wrong"];
}

- (void)testdefaultDecimalNumberHandler
{
    [self assert:_cappdefaultDcmHandler equals:[CPDecimalNumberHandler defaultDecimalNumberHandler] message:"T1 defaultDecimalNumberHandler returned different handler than the current default"];
}

- (void)testroundingMode
{
    var h1 = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundDown scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];

    [self assertTrue:h1 message:"T1 roundingMode: no alloc"];

    [self assert:2 equals:[h1 roundingMode] message:"T1 roundingMode: rounding mode wrong"];
}

- (void)testscale
{
    var h1 = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundDown scale:-6 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];

    [self assertTrue:h1 message:"T1 roundingMode: no alloc"];

    [self assert:-6 equals:[h1 scale] message:"T1 roundingMode: scale wrong"];
}

- (void)testexceptionDuringOperation
{
    var h1 = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundDown scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    [self assertTrue:h1 message:"T1 exceptionDuringOperation: no alloc"];

    var a = [CPDecimalNumber decimalNumberWithString:@"100"];
    var b = [CPDecimalNumber decimalNumberWithString:@"100"];

    // no throw first
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationLossOfPrecision leftOperand:a rightOperand:b];
    }
    catch (e)
    {
        [self fail:"T2 exceptionDuringOperation: Should have not thrown a precision exception"];
    }
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationOverflow leftOperand:a rightOperand:b];
    }
    catch (e)
    {
        [self fail:"T3 exceptionDuringOperation: Should have not thrown an overflow exception"];
    }

    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationUnderflow leftOperand:a rightOperand:b];
    }
    catch (e)
    {
        [self fail:"T4 exceptionDuringOperation: Should have not thrown an underflow exception"];
    }
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationDivideByZero leftOperand:a rightOperand:b];
    }
    catch (e)
    {
        [self fail:"T5 exceptionDuringOperation: Should have not thrown a div by zero exception"];
    }

    // now throw
    h1 = [CPDecimalNumberHandler decimalNumberHandlerWithRoundingMode:CPRoundDown scale:0 raiseOnExactness:YES raiseOnOverflow:YES raiseOnUnderflow:YES raiseOnDivideByZero:YES];
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationLossOfPrecision leftOperand:a rightOperand:b];
        [self fail:"T6 exceptionDuringOperation: Should have thrown a precision exception"];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationOverflow leftOperand:a rightOperand:b];
        [self fail:"T3 exceptionDuringOperation: Should have thrown an overflow exception"];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationUnderflow leftOperand:a rightOperand:b];
        [self fail:"T4 exceptionDuringOperation: Should have thrown an underflow exception"];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
    try {
        [h1 exceptionDuringOperation:nil error:CPCalculationDivideByZero leftOperand:a rightOperand:b];
        [self fail:"T5 exceptionDuringOperation: Should have thrown a div by zero exception"];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
}

@end
