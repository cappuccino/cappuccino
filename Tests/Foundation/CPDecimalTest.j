/*
 * CPDecimalTest.j
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
@import <Foundation/CPDecimal.j>

@implementation CPDecimalTest : OJTestCase

- (void)testInitialisers
{
    // max digits
    [self assertNotNull:CPDecimalMakeWithString(@"9999999999999999999999999999999999") message:"CPDecimalMakeWithString() Tmx1: max digits string"];
    [self assertNotNull:CPDecimalMakeWithString(@"-1111111111111111111111111111111111") message:"CPDecimalMakeWithString() Tmx2: negative max digits string"];

    // too big digit, round
    var dcm = CPDecimalMakeWithString(@"11111111111111111111111111111111111111111");
    [self assertNotNull:dcm message:"CPDecimalMakeWithString() Tb1: mantissa rounding string"];
    [self assert:3 equals:dcm._exponent message:"CPDecimalMakeWithString() Tb1: exponent"];
    [self assert:[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] equals:dcm._mantissa message:"CPDecimalMakeWithString() Tb1: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalMakeWithString() Tb1: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithString() Tb1: NaN is incorrectly set"];

    // format tests
    dcm = CPDecimalMakeWithString(@"+0.01e+1");
    [self assertNotNull:dcm message:"CPDecimalMakeWithString() Tf1: mantissa rounding string"];
    [self assert:-1 equals:dcm._exponent message:"CPDecimalMakeWithString() Tf1: exponent"];
    [self assert:[1] equals:dcm._mantissa message:"CPDecimalMakeWithString() Tf1: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalMakeWithString() Tf1: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithString() Tf1: NaN is incorrectly set"];

    dcm = CPDecimalMakeWithString(@"+99e-5");
    [self assertNotNull:dcm message:"CPDecimalMakeWithString() Tf2: mantissa rounding string"];
    [self assert:-5 equals:dcm._exponent message:"CPDecimalMakeWithString() Tf2: exponent"];
    [self assert:[9,9] equals:dcm._mantissa message:"CPDecimalMakeWithString() Tf2: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalMakeWithString() Tf2: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithString() Tf2: NaN is incorrectly set"];

    dcm = CPDecimalMakeWithString(@"-1234.5678e100");
    [self assertNotNull:dcm message:"CPDecimalMakeWithString() Tf3: mantissa rounding string"];
    [self assert:96 equals:dcm._exponent message:"CPDecimalMakeWithString() Tf3: exponent"];
    [self assert:[1, 2, 3, 4, 5, 6, 7, 8] equals:dcm._mantissa message:"CPDecimalMakeWithString() Tf3: mantissa"];
    [self assert:YES equals:dcm._isNegative message:"CPDecimalMakeWithString() Tf3: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithString() Tf3: NaN is incorrectly set"];

    dcm = CPDecimalMakeWithString(@"0.00000000000000000000000001");
    [self assertNotNull:dcm message:"CPDecimalMakeWithString() Tf4: mantissa rounding string"];
    [self assert:-26 equals:dcm._exponent message:"CPDecimalMakeWithString() Tf4: exponent"];
    [self assert:[1] equals:dcm._mantissa message:"CPDecimalMakeWithString() Tf4: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalMakeWithString() Tf4: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithString() Tf4: NaN is incorrectly set"];

    dcm = CPDecimalMakeWithString(@"000000000000000000");
    [self assertFalse:dcm._isNaN message:"CPDecimalMakeWithString() Tf5: Should be valid"];

    // too large return NaN
    dcm = CPDecimalMakeWithString(@"111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() To1: number overflow handling. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"-1e1000");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() To2: exponent overflow not caught. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"-1e-2342");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() To3: exponent underflow not caught. Should return NaN"];

    // Tests for invalid strings
    dcm = CPDecimalMakeWithString(@"abc");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti1: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"123a");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti2: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"12.7e");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti3: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"e");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti4: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"12 ");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti5: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"1 2 3");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti6: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"e10");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti7: catch of invalid number string. Should return NaN"];
    dcm = CPDecimalMakeWithString(@"123ee");
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithString() Ti8: catch of invalid number string. Should return NaN"];

    // this behaviour has changed to match Cocoa. Making a decimal with a leading zero should return the decimal.
    dcm = CPDecimalMakeWithString(@"0001");
    [self assertFalse:dcm._isNaN message:"CPDecimalMakeWithString() Ti9: Numbers with leading zeros are valid numbers. Expected False when evaluating against NaN, got True."];
    dcm = CPDecimalMakeWithString(@"-0001");
    [self assertFalse:dcm._isNaN message:"CPDecimalMakeWithString() Ti10: Numbers with leading zeros are valid numbers. Expected False when evaluating against NaN, got True."];

    //test make with parts
    dcm = CPDecimalMakeWithParts(10127658, 2);
    [self assert:2 equals:dcm._exponent message:"CPDecimalMakeWithParts() Tmp1: exponent"];
    [self assert:[1, 0, 1, 2, 7, 6, 5, 8] equals:dcm._mantissa message:"CPDecimalMakeWithParts() Tmp1: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalMakeWithParts() Tmp1: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithParts() Tmp1: NaN is incorrectly set"];
    dcm = CPDecimalMakeWithParts(-1000000, 0);
    [self assert:6 equals:dcm._exponent message:"CPDecimalMakeWithParts() Tmp2: exponent"];
    [self assert:[1] equals:dcm._mantissa message:"CPDecimalMakeWithParts() Tmp2: mantissa"];
    [self assert:YES equals:dcm._isNegative message:"CPDecimalMakeWithParts() Tmp2: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalMakeWithParts() Tmp2: NaN is incorrectly set"];

    dcm = CPDecimalMakeWithParts(1, 10000);
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithParts() Tmp3: exponent overflow not caught. Should return NaN"];
    dcm = CPDecimalMakeWithParts(-1, -1000);
    [self assertTrue:dcm._isNaN message:"CPDecimalMakeWithParts() Tmp4: exponent underflow not caught. Should return NaN"];
}

- (void)testZeros
{
    var dcm = CPDecimalMakeWithString(@"0");
    [self assertTrue:CPDecimalIsZero(dcm) message:"CPDecimalMakeWithString(0) and CPDecimalIsZero()"];
    dcm = CPDecimalMakeWithString(@"-0.000000000000e-0");
    [self assertTrue:CPDecimalIsZero(dcm) message:"CPDecimalMakeWithString(0) and CPDecimalIsZero()"];
    dcm = CPDecimalMakeWithParts(0,0);
    [self assertTrue:CPDecimalIsZero(dcm) message:"CPDecimalMakeWithParts(0)"];
    dcm = CPDecimalMakeZero();
    [self assertTrue:CPDecimalIsZero(dcm) message:"CPDecimalMakeZero()"];
}

- (void)testOnes
{
    var dcm = CPDecimalMakeOne();
    [self assertTrue:CPDecimalIsOne(dcm) message:"CPDecimalMakeOne() and CPDecimalIsOne()"];
    dcm = CPDecimalMakeWithString(@"1.00000e1");
    [self assertTrue:CPDecimalIsOne(dcm) message:"CPDecimalMakeWithString(1)"];
    dcm = CPDecimalMakeWithString(@"0.00100000e-3");
    [self assertTrue:CPDecimalIsOne(dcm) message:"CPDecimalMakeWithString(1)"];
    [self assert:1 equals:dcm._mantissa[0] message:"CPDecimalMakeWithString(1)"];
}

- (void)testNormalize
{
    var dcm1 = CPDecimalMakeWithString( @"200" ),
        dcm2 = CPDecimalMakeWithString( @"2" );
    [self assert:0 equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tn1:call" ];
    [self assert:[2,0,0] equals:dcm1._mantissa message:"CPDecimalNormalise() Tn1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalNormalise() Tn1: exponent"];
    [self assert:[2] equals:dcm2._mantissa message:"CPDecimalNormalise() Tn1: mantissa"];
    [self assert:0 equals:dcm2._exponent message:"CPDecimalNormalise() Tn1: exponent"];

    dcm1 = CPDecimalMakeWithString( @"0.001" );
    dcm2 = CPDecimalMakeWithString( @"123" );
    [self assert:0 equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tn2:call" ];
    [self assert:[1] equals:dcm1._mantissa message:"CPDecimalNormalise() Tn2: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalNormalise() Tn2: exponent"];
    [self assert:[1,2,3,0,0,0] equals:dcm2._mantissa message:"CPDecimalNormalise() Tn2: mantissa"];
    [self assert:-3 equals:dcm2._exponent message:"CPDecimalNormalise() Tn2: exponent"];

    dcm1 = CPDecimalMakeWithString( @"123" );
    dcm2 = CPDecimalMakeWithString( @"0.001" );
    [self assert:0 equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tn3:call" ];
    [self assert:[1] equals:dcm2._mantissa message:"CPDecimalNormalise() Tn3: mantissa"];
    [self assert:-3 equals:dcm2._exponent message:"CPDecimalNormalise() Tn3: exponent"];
    [self assert:[1,2,3,0,0,0] equals:dcm1._mantissa message:"CPDecimalNormalise() Tn3: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalNormalise() Tn3: exponent"];

    dcm1 = CPDecimalMakeWithString( @"-1e-7" );
    dcm2 = CPDecimalMakeWithString( @"-21e-8" );
    [self assert:0 equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tn4:call" ];
    [self assert:[1,0] equals:dcm1._mantissa message:"CPDecimalNormalise() Tn4: mantissa"];
    [self assert:-8 equals:dcm1._exponent message:"CPDecimalNormalise() Tn4: exponent"];
    [self assert:[2, 1] equals:dcm2._mantissa message:"CPDecimalNormalise() Tn4: mantissa"];
    [self assert:-8 equals:dcm2._exponent message:"CPDecimalNormalise() Tn4: exponent"];

    // these will result in one number becoming zero.
    dcm1 = CPDecimalMakeWithString( @"1e0" );
    dcm2 = CPDecimalMakeWithString( @"10000000000000000000000000000000000001e2" );
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tnp1:call should ret LossOfPrecision" ];
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalNormalise() Tnp1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalNormalise() Tnp1: exponent"];
    [self assert:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 1] equals:dcm2._mantissa message:"CPDecimalNormalise() Tnp1: mantissa"];
    [self assert:2 equals:dcm2._exponent message:"CPDecimalNormalise() Tnp1: exponent"];

    dcm1 = CPDecimalMakeWithString( @"10000000000000000000000000000000000001e2" );
    dcm2 = CPDecimalMakeWithString( @"1e0" );
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tnp2:call should ret LossOfPrecision" ];
    [self assert:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 1] equals:dcm1._mantissa message:"CPDecimalNormalise() Tnp2: mantissa"];
    [self assert:2 equals:dcm1._exponent message:"CPDecimalNormalise() Tnp2:exponent"];
    [self assert:[0] equals:dcm2._mantissa message:"CPDecimalNormalise() Tnp2: mantissa"];
    [self assert:0 equals:dcm2._exponent message:"CPDecimalNormalise() Tnp2: exponent"];

    dcm1 = CPDecimalMakeWithString( @"10000000000000000000000000000000000001e127" );
    dcm2 = CPDecimalMakeWithString( @"1e0" );
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tnp3:call should ret LossOfPrecision" ];
    [self assert:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 1] equals:dcm1._mantissa message:"CPDecimalNormalise() Tnp3: mantissa"];
    [self assert:127 equals:dcm1._exponent message:"CPDecimalNormalise() Tnp3: exponent"];
    [self assert:[0] equals:dcm2._mantissa message:"CPDecimalNormalise() Tnp3: mantissa"];
    [self assert:0 equals:dcm2._exponent message:"CPDecimalNormalise() Tnp3: exponent"];

    dcm1 = CPDecimalMakeWithString( @"1e-3" );
    dcm2 = CPDecimalMakeWithString( @"1e36" );
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalNormalize(dcm1,dcm2,CPRoundDown) message:"CPDecimalNormalise() Tnp4:call should ret LossOfPrecision" ];
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalNormalise() Tnp4: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalNormalise() Tnp4: exponent"];
    [self assert:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] equals:dcm2._mantissa message:"CPDecimalNormalise() Tnp4: mantissa"];
    [self assert:-1 equals:dcm2._exponent message:"CPDecimalNormalise() Tnp4: exponent"];
}


- (void)testRound
{
    var dcm = CPDecimalMakeWithString(@"0.00123");
    CPDecimalRound(dcm,dcm,3,CPRoundUp);
    [self assert:[2] equals:dcm._mantissa message:"CPDecimalRound() Tr1: mantissa"];
    [self assert:-3 equals:dcm._exponent message:"CPDecimalRound() Tr1: exponent"];

    // plain
    var dcm1 = CPDecimalMakeZero();
    dcm = CPDecimalMakeWithString(@"123.456");
    CPDecimalRound(dcm1,dcm,0,CPRoundPlain);
    [self assert:[1,2,3] equals:dcm1._mantissa message:"CPDecimalRound() Tp1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tp1: exponent"];

    CPDecimalRound(dcm1,dcm,2,CPRoundPlain);
    [self assert:[1,2,3,4,6] equals:dcm1._mantissa message:"CPDecimalRound() Tp2: mantissa"];
    [self assert:-2 equals:dcm1._exponent message:"CPDecimalRound() Tp2: exponent"];

    CPDecimalRound(dcm1,dcm,-2,CPRoundPlain);
    [self assert:[1] equals:dcm1._mantissa message:"CPDecimalRound() Tp3: mantissa"];
    [self assert:2 equals:dcm1._exponent message:"CPDecimalRound() Tp3: exponent"];

    CPDecimalRound(dcm1,dcm,-4,CPRoundPlain);
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalRound() Tp4: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tp4: exponent"];

    CPDecimalRound(dcm1,dcm,6,CPRoundPlain);
    [self assert:[1,2,3,4,5,6] equals:dcm1._mantissa message:"CPDecimalRound() Tp5: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalRound() Tp5: exponent"];

    // down
    CPDecimalRound(dcm1,dcm,0,CPRoundDown);
    [self assert:[1,2,3] equals:dcm1._mantissa message:"CPDecimalRound() Td1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Td1: exponent"];

    CPDecimalRound(dcm1,dcm,2,CPRoundDown);
    [self assert:[1,2,3,4,5] equals:dcm1._mantissa message:"CPDecimalRound() Td2: mantissa"];
    [self assert:-2 equals:dcm1._exponent message:"CPDecimalRound() Td2: exponent"];

    CPDecimalRound(dcm1,dcm,-2,CPRoundDown);
    [self assert:[1] equals:dcm1._mantissa message:"CPDecimalRound() Td3: mantissa"];
    [self assert:2 equals:dcm1._exponent message:"CPDecimalRound() Td3: exponent"];

    CPDecimalRound(dcm1,dcm,-4,CPRoundDown);
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalRound() Td4: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Td4: exponent"];

    CPDecimalRound(dcm1,dcm,6,CPRoundDown);
    [self assert:[1,2,3,4,5,6] equals:dcm1._mantissa message:"CPDecimalRound() Td5: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalRound() Td5: exponent"];

    // up
    CPDecimalRound(dcm1,dcm,0,CPRoundUp);
    [self assert:[1,2,4] equals:dcm1._mantissa message:"CPDecimalRound() Tu1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tu1: exponent"];

    CPDecimalRound(dcm1,dcm,2,CPRoundUp);
    [self assert:[1,2,3,4,6] equals:dcm1._mantissa message:"CPDecimalRound() Tu2: mantissa"];
    [self assert:-2 equals:dcm1._exponent message:"CPDecimalRound() Tu2: exponent"];

    CPDecimalRound(dcm1,dcm,-2,CPRoundUp);
    [self assert:[2] equals:dcm1._mantissa message:"CPDecimalRound() Tu3: mantissa"];
    [self assert:2 equals:dcm1._exponent message:"CPDecimalRound() Tu3: exponent"];

    CPDecimalRound(dcm1,dcm,-4,CPRoundUp);
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalRound() Tu4: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tu4: exponent"];

    CPDecimalRound(dcm1,dcm,6,CPRoundUp);
    [self assert:[1,2,3,4,5,6] equals:dcm1._mantissa message:"CPDecimalRound() Tu5: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalRound() Tu5: exponent"];

    // bankers
    CPDecimalRound(dcm1,dcm,0,CPRoundBankers);
    [self assert:[1,2,3] equals:dcm1._mantissa message:"CPDecimalRound() Tb1: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tb1: exponent"];

    CPDecimalRound(dcm1,dcm,2,CPRoundBankers);
    [self assert:[1,2,3,4,6] equals:dcm1._mantissa message:"CPDecimalRound() Tb2: mantissa"];
    [self assert:-2 equals:dcm1._exponent message:"CPDecimalRound() Tb2: exponent"];

    CPDecimalRound(dcm1,dcm,-2,CPRoundBankers);
    [self assert:[1] equals:dcm1._mantissa message:"CPDecimalRound() Tb3: mantissa"];
    [self assert:2 equals:dcm1._exponent message:"CPDecimalRound() Tb3: exponent"];

    CPDecimalRound(dcm1,dcm,-4,CPRoundBankers);
    [self assert:[0] equals:dcm1._mantissa message:"CPDecimalRound() Tb4: mantissa"];
    [self assert:0 equals:dcm1._exponent message:"CPDecimalRound() Tb4: exponent"];

    CPDecimalRound(dcm1,dcm,6,CPRoundBankers);
    [self assert:[1,2,3,4,5,6] equals:dcm1._mantissa message:"CPDecimalRound() Tb5: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalRound() Tb5: exponent"];

    // Noscale
    dcm1 = CPDecimalMakeZero();
    CPDecimalRound(dcm1,dcm,CPDecimalNoScale,CPRoundPlain);
    [self assert:[1,2,3,4,5,6] equals:dcm1._mantissa message:"CPDecimalRound() Tns1: mantissa"];
    [self assert:-3 equals:dcm1._exponent message:"CPDecimalRound() Tns1: exponent"];
}

- (void)testCompare
{
    var dcm1 = CPDecimalMakeWithString(@"75836"),
        dcm = CPDecimalMakeWithString(@"75836"),
        c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedSame equals:c message:"CPDecimalCompare() Tc1: should be same"];

    dcm1 = CPDecimalMakeWithString(@"75836");
    dcm = CPDecimalMakeWithString(@"75836e-9");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare() Tc2: should be descending"];

    dcm1 = CPDecimalMakeWithString(@"823479");
    dcm = CPDecimalMakeWithString(@"7082371231252");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedAscending equals:c message:"CPDecimalCompare() Tc3: should be descending"];

    dcm1 = CPDecimalMakeWithString(@"0.00000000002");
    dcm = CPDecimalMakeWithString(@"-1e-9");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare() Tc4: should be descending"];

    dcm1 = CPDecimalMakeWithString(@"-23412345123e12");
    dcm = CPDecimalMakeWithString(@"-1e100");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare() Tc4: should be descending"];

    dcm1 = CPDecimalMakeWithString(@"0.0");
    dcm = CPDecimalMakeWithString(@"0.5");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedAscending equals:c message:"CPDecimalCompare() (0.0, 0.5) should be ascending"];

    dcm1 = CPDecimalMakeWithString(@"0.0");
    dcm = CPDecimalMakeWithString(@"-0.5");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare() (0, -0.5) should be descending"];

    dcm1 = CPDecimalMakeZero();
    dcm = CPDecimalMakeZero();
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedSame equals:c message:"CPDecimalCompare(): zeros should be same"];

    dcm1 = CPDecimalMakeWithString(@"0.0001");
    dcm = CPDecimalMakeZero();
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare(): (0.0001, 0) should be descending"];

    dcm1 = CPDecimalMakeZero();
    dcm = CPDecimalMakeWithString(@"0.0001");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedAscending equals:c message:"CPDecimalCompare(): (0, 0.0001) should be ascending"];

    dcm1 = CPDecimalMakeWithString(@"-0.0001");
    dcm = CPDecimalMakeZero();
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedAscending equals:c message:"CPDecimalCompare(): (-0.0001, 0) should be ascending"];

    dcm1 = CPDecimalMakeZero();
    dcm = CPDecimalMakeWithString(@"-0.0001");
    c = CPDecimalCompare(dcm1,dcm);
    [self assert:CPOrderedDescending equals:c message:"CPDecimalCompare(): (0, -0.0001) should be descending"];
}

- (void)testCompact
{
    var dcm = CPDecimalMakeZero();
    dcm._mantissa = [0,0,0,0, 1,0,0,0,0, 1];
    dcm._exponent = 2;
    CPDecimalCompact(dcm);
    [self assert:2 equals:dcm._exponent message:"CPDecimalCompact() Tcm1: exponent"];
    [self assert:[1,0,0,0,0, 1] equals:dcm._mantissa message:"CPDecimalCompact() Tcm1: mantissa"];

    dcm = CPDecimalMakeZero();
    dcm._mantissa = [0,0,0,0, 1,2,0,0,0,0];
    dcm._exponent = -4;
    dcm._isNegative = YES;
    CPDecimalCompact(dcm);
    [self assert:0 equals:dcm._exponent message:"CPDecimalCompact() Tcm2: exponent"];
    [self assert:[1,2] equals:dcm._mantissa message:"CPDecimalCompact() Tcm2: mantissa"];
    [self assert:YES equals:dcm._isNegative message:"CPDecimalCompact() Tcm2: sign"];

    dcm = CPDecimalMakeZero();
    dcm._mantissa = [1,2,0,0,0,0];
    dcm._exponent = -1;
    CPDecimalCompact(dcm);
    [self assert:3 equals:dcm._exponent message:"CPDecimalCompact() Tcm3: exponent"];
    [self assert:[1,2] equals:dcm._mantissa message:"CPDecimalCompact() Tcm3: mantissa"];
    [self assert:NO equals:dcm._isNegative message:"CPDecimalCompact() Tcm3: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalCompact() Tcm3: NaN is incorrectly set"];

    dcm = CPDecimalMakeZero();
    dcm._mantissa = [8,9,0,0,0,0, 1,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    dcm._exponent = -20;
    dcm._isNegative = YES;
    CPDecimalCompact(dcm);
    [self assert:-5 equals:dcm._exponent message:"CPDecimalCompact() Tcm4: exponent"];
    [self assert:[8,9,0,0,0,0, 1,2,3] equals:dcm._mantissa message:"CPDecimalCompact() Tcm4: mantissa"];
    [self assert:YES equals:dcm._isNegative message:"CPDecimalCompact() Tcm4: sign"];
    [self assert:NO equals:dcm._isNaN message:"CPDecimalCompact() Tcm4: NaN is incorrectly set"];
}

- (void)testAdd
{
    // test addition of positives
    var d1 = CPDecimalMakeWithString(@"1"),
        d2 = CPDecimalMakeWithParts(1, 0),
        dcm = CPDecimalMakeZero(),
        i = 50;
    while (i--)
        [self assert:CPDecimalAdd(d1, d1, d2, CPRoundPlain) equals:CPCalculationNoError message:"CPDecimalAdd() Tap1: addition"];
    [self assert:0 equals:d1._exponent message:"CPDecimalAdd() Tap1: exponent"];
    [self assert:[5, 1] equals:d1._mantissa message:"CPDecimalAdd() Tap1: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalAdd() Tap1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalAdd() Tap1: NaN is incorrectly set"];

    // test addition with negatives
    d1 = CPDecimalMakeWithString(@"-1");
    d2 = CPDecimalMakeWithString(@"-1e-10");
    [self assert:CPCalculationNoError equals:CPDecimalAdd(d1, d1, d2, CPRoundPlain) message:"CPDecimalAdd() Tan1: addition of 2 negatives"];
    [self assert:-10 equals:d1._exponent message:"CPDecimalAdd() Tan1: exponent"];
    [self assert:[1,0,0,0,0,0,0,0,0,0, 1] equals:d1._mantissa message:"CPDecimalAdd() Tan1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalAdd() Tan1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalAdd() Tan1: NaN is incorrectly set"];

    d1 = CPDecimalMakeWithString(@"-5");
    d2 = CPDecimalMakeWithString(@"11");
    [self assert:CPCalculationNoError equals:CPDecimalAdd(d1, d1, d2, CPRoundPlain) message:"CPDecimalAdd() Tan2: addition with negatives"];
    [self assert:0 equals:d1._exponent message:"CPDecimalAdd() Tan2: exponent"];
    [self assert:[6] equals:d1._mantissa message:"CPDecimalAdd() Tan2: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalAdd() Tan2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalAdd() Tan2: NaN is incorrectly set"];

    d1 = CPDecimalMakeWithString(@"11");
    d2 = CPDecimalMakeWithString(@"-12");
    [self assert:CPCalculationNoError equals:CPDecimalAdd(d1, d1, d2, CPRoundPlain) message:"CPDecimalAdd() Tan3: addition with negatives"];
    [self assert:0 equals:d1._exponent message:"CPDecimalAdd() Tan3: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalAdd() Tan3: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalAdd() Tan3: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalAdd() Tan3: NaN is incorrectly set"];

    // FIXME: test mantissa overflow handling - is there a loss of precision?? not according to gnustep - check cocoa!!!! CPCalculationLossOfPrecision?
    d1 = CPDecimalMakeWithString(@"12345");
    d2 = CPDecimalMakeWithString(@"99999999999999999999999999999999999999");
    [self assert:0 equals:CPDecimalAdd(d1, d1, d2, CPRoundPlain) message:"CPDecimalAdd() Tapc1: addition with mantissa overflow and rounding"];
    [self assert:1 equals:d1._exponent message:"CPDecimalAdd() Tapc1: exponent"];
    [self assert:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 1,2,3,4] equals:d1._mantissa message:"CPDecimalAdd() Tapc1: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalAdd() Tapc1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalAdd() Tapc1: NaN is incorrectly set"];

    d1 = CPDecimalMakeWithString(@"1e127");
    d2 = CPDecimalMakeWithString(@"99999999999999999999999999999999999999");
    [self assert:CPDecimalAdd(d1, d1, d2, CPRoundPlain) equals:CPCalculationLossOfPrecision message:"CPDecimalAdd() Tapc2: addition loss of precision"];

    // Overflow
    d1 = CPDecimalMakeWithString(@"1e127");
    d2 = CPDecimalMakeWithString(@"99999999999999999999999999999999999999e127");
    [self assert:CPDecimalAdd(d1, d1, d2, CPRoundPlain) equals:CPCalculationOverflow message:"CPDecimalAdd() Tao1: addition loss of precision"];
}

- (void)testSubtract
{
    var d1 = CPDecimalMakeZero(),
        d2 = CPDecimalMakeWithString(@"0.875"),
        d3 = CPDecimalMakeWithString(@"12.67");
    [self assert:CPCalculationNoError equals:CPDecimalSubtract(d1,d2,d3,CPRoundPlain) message:"CPDecimalSubtract(): Ts1: Should succeed"];
    [self assert:-3 equals:d1._exponent message:"CPDecimalSubtract(): Ts1: exponent"];
    [self assert:[1, 1,7,9,5] equals:d1._mantissa message:"CPDecimalSubtract(): Ts1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalSubtract(): Ts1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalSubtract(): Ts1: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-0.875");
    d3 = CPDecimalMakeWithString(@"-12.67");
    [self assert:CPCalculationNoError equals:CPDecimalSubtract(d1,d2,d3,CPRoundPlain) message:"CPDecimalSubtract(): Ts2: Should succeed"];
    [self assert:-3 equals:d1._exponent message:"CPDecimalSubtract(): Ts2: exponent"];
    [self assert:[1, 1,7,9,5] equals:d1._mantissa message:"CPDecimalSubtract(): Ts2: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalSubtract(): Ts2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalSubtract(): Ts2: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-0.875");
    d3 = CPDecimalMakeWithString(@"12.67e2");
    [self assert:CPCalculationNoError equals:CPDecimalSubtract(d1,d2,d3,CPRoundPlain) message:"CPDecimalSubtract(): Ts3: Should succeed"];
    [self assert:-3 equals:d1._exponent message:"CPDecimalSubtract(): Ts3: exponent"];
    [self assert:[1,2,6,7,8,7,5] equals:d1._mantissa message:"CPDecimalSubtract(): Ts3: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalSubtract(): Ts3: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalSubtract(): Ts3: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"0.875");
    d3 = CPDecimalMakeWithString(@"-12.67");
    [self assert:CPCalculationNoError equals:CPDecimalSubtract(d1,d2,d3,CPRoundPlain) message:"CPDecimalSubtract(): Ts4: Should succeed"];
    [self assert:-3 equals:d1._exponent message:"CPDecimalSubtract(): Ts4: exponent"];
    [self assert:[1,3,5,4,5] equals:d1._mantissa message:"CPDecimalSubtract(): Ts4: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalSubtract(): Ts4: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalSubtract(): Ts4: NaN is incorrectly set"];

    // loss of precision
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"1e-128");
    d3 = CPDecimalMakeWithString(@"1");
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalSubtract(d1,d2,d3,CPRoundPlain) message:"CPDecimalSubtract(): Tsp1: Should throw loss of precision"];
    [self assert:0 equals:d1._exponent message:"CPDecimalSubtract(): Tsp1: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalSubtract(): Tsp1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalSubtract(): Tsp1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalSubtract(): Tsp1: NaN is incorrectly set"];
}

- (void)testDivide
{
    var d1 = CPDecimalMakeZero(),
        d2 = CPDecimalMakeWithString(@"55e12"),
        d3 = CPDecimalMakeWithString(@"-5e20");
    [self assert:CPCalculationNoError equals:CPDecimalDivide(d1,d2,d3,CPRoundPlain) message:"CPDecimalDivide(): Td1: Should succeed"];
    [self assert:-8 equals:d1._exponent message:"CPDecimalDivide(): Td1: exponent"];
    [self assert:[1, 1] equals:d1._mantissa message:"CPDecimalDivide(): Td1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalDivide(): Td1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Td1: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-1e12");
    d3 = CPDecimalMakeWithString(@"-1e6");
    [self assert:CPCalculationNoError equals:CPDecimalDivide(d1,d2,d3,CPRoundPlain) message:"CPDecimalDivide(): Td2: Should succeed"];
    [self assert:6 equals:d1._exponent message:"CPDecimalDivide(): Td2: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalDivide(): Td2: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalDivide(): Td2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Td2: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"1");
    d3 = CPDecimalMakeWithString(@"0.00001");
    [self assert:CPCalculationNoError equals:CPDecimalDivide(d1,d2,d3,CPRoundPlain) message:"CPDecimalDivide(): Td3: Should succeed"];
    [self assert:5 equals:d1._exponent message:"CPDecimalDivide(): Td3: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalDivide(): Td3: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalDivide(): Td3: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Td3: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"1");
    d3 = CPDecimalMakeWithString(@"3");
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalDivide(d1,d2,d3,CPRoundPlain) message:"CPDecimalDivide(): Tdp1: Should Loss of precision"];
    [self assert:-38 equals:d1._exponent message:"CPDecimalDivide(): Tdp1: exponent"];
    [self assert:[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3] equals:d1._mantissa message:"CPDecimalDivide(): Tdp1: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalDivide(): Tdp1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Tdp1: NaN is incorrectly set"];

    // Why doesnt Cocoa round the final digit up?
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-0.875");
    d3 = CPDecimalMakeWithString(@"12");
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalDivide(d1,d2,d3,CPRoundUp) message:"CPDecimalDivide(): Tdp2: Should Loss of precision"];
    [self assert:-39 equals:d1._exponent message:"CPDecimalDivide(): Td2: exponent"];
    [self assert:[7,2,9, 1,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6] equals:d1._mantissa message:"CPDecimalDivide(): Td2: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalDivide(): Td2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Td2: NaN is incorrectly set"];

    // div zero
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-0.875");
    d3 = CPDecimalMakeWithString(@"0");
    [self assert:CPCalculationDivideByZero equals:CPDecimalDivide(d1,d2,d3,CPRoundUp) message:"CPDecimalDivide(): Tdp2: Should Loss of precision"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"11");
    d3 = CPDecimalMakeWithString(@"11");

    [self assert:CPCalculationNoError equals:CPDecimalDivide(d1, d2, d3, CPRoundPlain) message:"CPDecimalDivide(): Td4: Should succeed"];
    [self assert:0 equals:d1._exponent message:"CPDecimalDivide(): Td4: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalDivide(): Td4: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalDivide(): Td4: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalDivide(): Td4: NaN is incorrectly set"];
}

- (void)testMultiply
{
    var d1 = CPDecimalMakeZero(),
        d2 = CPDecimalMakeWithString(@"12"),
        d3 = CPDecimalMakeWithString(@"-1441231251321235231");
    [self assert:CPCalculationNoError equals:CPDecimalMultiply(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiply(): Tm1: Should succeed"];
    [self assert:0 equals:d1._exponent message:"CPDecimalMultiply(): Tm1: exponent"];
    [self assert:[1,7,2,9,4,7,7,5,0, 1,5,8,5,4,8,2,2,7,7,2] equals:d1._mantissa message:"CPDecimalMultiply(): Tm1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalMultiply(): Tm1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiply(): Tm1: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"23e100");
    d3 = CPDecimalMakeWithString(@"-13e-76");
    [self assert:CPCalculationNoError equals:CPDecimalMultiply(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiply(): Tm2: Should succeed"];
    [self assert:24 equals:d1._exponent message:"CPDecimalMultiply(): Tm2: exponent"];
    [self assert:[2,9,9] equals:d1._mantissa message:"CPDecimalMultiply(): Tm2: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalMultiply(): Tm2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiply(): Tm2: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-0.8888");
    d3 = CPDecimalMakeWithString(@"8.88e2");
    [self assert:CPCalculationNoError equals:CPDecimalMultiply(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiply(): Tm3: Should succeed"];
    [self assert:-4 equals:d1._exponent message:"CPDecimalMultiply(): Tm3: exponent"];
    [self assert:[7,8,9,2,5,4,4] equals:d1._mantissa message:"CPDecimalMultiply(): Tm3: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalMultiply(): Tm3: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiply(): Tm3: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"-1e111");
    d3 = CPDecimalMakeWithString(@"-1e-120");
    [self assert:CPCalculationNoError equals:CPDecimalMultiply(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiply(): Tm4: Should succeed"];
    [self assert:-9 equals:d1._exponent message:"CPDecimalMultiply(): Tm4: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalMultiply(): Tm4: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalMultiply(): Tm4: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiply(): Tm4: NaN is incorrectly set"];

    // loss of precision
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"212341251123892374823742638472481124");
    d3 = CPDecimalMakeWithString(@"127889465810478913");
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalMultiply(d1,d2,d3,CPRoundDown) message:"CPDecimalMultiply(): Tmp1: Should throw loss of precision"];
    [self assert:15 equals:d1._exponent message:"CPDecimalMultiply(): Tmp1: exponent"]; // 69 diff
    [self assert:[2,7, 1,5,6,2,0,9, 1,7,5,7,6,3,3,5,0,9,2,9,7,4,0,2,3,5,6,0,8,0,6,9,5,2,8,3,9, 1] equals:d1._mantissa message:"CPDecimalMultiply(): Tmp1: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalMultiply(): Tmp1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiply(): Tmp1: NaN is incorrectly set"];

    // overflow
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"1e110");
    d3 = CPDecimalMakeWithString(@"1e111");
    [self assert:CPCalculationOverflow equals:CPDecimalMultiply(d1,d2,d3,CPRoundDown) message:"CPDecimalMultiply(): Tmo1: Should throw overflow"];
    [self assert:YES equals:d1._isNaN message:"CPDecimalMultiply(): Tmo1: NaN is incorrectly set"];
}

// Power is unsigned
- (void)testPower
{
    var d1 = CPDecimalMakeZero(),
        d2 = CPDecimalMakeWithString(@"123"),
        d3 = 12;
    [self assert:CPCalculationNoError equals:CPDecimalPower(d1,d2,d3,CPRoundPlain) message:"CPDecimalPower(): Tp1: Should succeed"];
    [self assert:0 equals:d1._exponent message:"CPDecimalPower(): Tp1: exponent"];
    [self assert:[1, 1,9,9, 1, 1,6,3,8,4,8,7, 1,6,9,0,6,2,9,7,0,7,2,7,2, 1] equals:d1._mantissa message:"CPDecimalPower(): Tp1: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalPower(): Tp1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalPower(): Tp1: NaN is incorrectly set"];

    //0.00000 13893554059925661274821814636807535200 1 cocoa (39 digits)
    //0.00000 13893554059925661274821814636807535204 This , a few off
    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"0.875");
    d3 = 101;
    [self assert:CPCalculationLossOfPrecision equals:CPDecimalPower(d1,d2,d3,CPRoundUp) message:"CPDecimalPower(): Tp2: Should throw Loss of precision"];
    [self assert:-43 equals:d1._exponent message:"CPDecimalPower(): Tp2: exponent"];
    [self assert:[1,3,8,9,3,5,5,4,0,5,9,9,2,5,6,6, 1,2,7,4,8,2, 1,8, 1,4,6,3,6,8,0,7,5,3,5,2,0,4] equals:d1._mantissa message:"CPDecimalPower(): Tp2: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalPower(): Tp2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalPower(): Tp2: NaN is incorrectly set"];

}

- (void)testPower10
{
    var d1 = CPDecimalMakeZero(),
        d2 = CPDecimalMakeWithString(@"-0.875"),
        d3 = 3;
    [self assert:CPCalculationNoError equals:CPDecimalMultiplyByPowerOf10(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiplyByPowerOf10(): Tpp1: Should succeed"];
    [self assert:0 equals:d1._exponent message:"CPDecimalMultiplyByPowerOf10(): Tpp1: exponent"];
    [self assert:[8,7,5] equals:d1._mantissa message:"CPDecimalMultiplyByPowerOf10(): Tpp1: mantissa"];
    [self assert:YES equals:d1._isNegative message:"CPDecimalMultiplyByPowerOf10(): Tpp1: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiplyByPowerOf10(): Tpp1: NaN is incorrectly set"];

    d1 = CPDecimalMakeZero();
    d2 = CPDecimalMakeWithString(@"1e-120");
    d3 = 130;
    [self assert:CPCalculationNoError equals:CPDecimalMultiplyByPowerOf10(d1,d2,d3,CPRoundPlain) message:"CPDecimalMultiplyByPowerOf10(): Tpp2: Should succeed"];
    [self assert:10 equals:d1._exponent message:"CPDecimalMultiplyByPowerOf10(): Tpp2: exponent"];
    [self assert:[1] equals:d1._mantissa message:"CPDecimalMultiplyByPowerOf10(): Tpp2: mantissa"];
    [self assert:NO equals:d1._isNegative message:"CPDecimalMultiplyByPowerOf10(): Tpp2: sign"];
    [self assert:NO equals:d1._isNaN message:"CPDecimalMultiplyByPowerOf10(): Tpp2: NaN is incorrectly set"];
}

- (void)testString
{
    var dcm = CPDecimalMakeWithString(@"0.00123");
    [self assert:"0.00123" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts1"];
    dcm = CPDecimalMakeWithString(@"2e3");
    [self assert:"2000" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts2"];
    dcm = CPDecimalMakeWithString(@"0.00876e-5");
    [self assert:"0.0000000876" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts3"];
    dcm = CPDecimalMakeWithString(@"98.56e10");
    [self assert:"985600000000" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts4"];
    dcm = CPDecimalMakeWithString(@"-1e-1");
    [self assert:"-0.1" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts5"];
    dcm = CPDecimalMakeWithString(@"-5e20");
    [self assert:"-500000000000000000000" equals:CPDecimalString(dcm,nil) message:"CPDecimalString() Ts6"];
}

@end
