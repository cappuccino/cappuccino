/*
 *  CPStringEncodingTest.j
 *  Foundation
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
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

@import <Foundation/CPData.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString+Encoding.j>

@implementation CPStringEncodingTest : OJTestCase
{
}

- (CPString)stringFromBytes:(CPArray)bytes encoding:(CPStringEncoding)anEncoding
{
    return [[CPString alloc] initWithData:[CPData dataWithBytes:bytes] encoding:anEncoding];
}

- (CPArray)bytesOfString:(CPString)aString encoding:(CPStringEncoding)anEncoding
{
    return [[aString dataUsingEncoding:anEncoding] bytes];
}

- (void)testUTF8
{
    var text = @"héllo € 𝄞";

    [self assert:[0xC3, 0xA9] equals:[self bytesOfString:@"é" encoding:CPUTF8StringEncoding]];
    [self assert:[0xF0, 0x9D, 0x84, 0x9E] equals:[self bytesOfString:@"𝄞" encoding:CPUTF8StringEncoding]];
    [self assert:text equals:[self stringFromBytes:[self bytesOfString:text encoding:CPUTF8StringEncoding] encoding:CPUTF8StringEncoding]];
    [self assertNull:[self stringFromBytes:[0xC3] encoding:CPUTF8StringEncoding]];
    [self assertNull:[@"\ud834" dataUsingEncoding:CPUTF8StringEncoding]];
    [self assert:[0xEF, 0xBF, 0xBD] equals:[[@"\ud834" dataUsingEncoding:CPUTF8StringEncoding allowLossyConversion:YES] bytes]];
}

- (void)testASCII
{
    [self assert:[0x61, 0x62] equals:[self bytesOfString:@"ab" encoding:CPASCIIStringEncoding]];
    [self assertNull:[@"é" dataUsingEncoding:CPASCIIStringEncoding]];
    [self assert:[0x65, 0x3F] equals:[[@"é€" dataUsingEncoding:CPASCIIStringEncoding allowLossyConversion:YES] bytes]];
    [self assertNull:[self stringFromBytes:[0x80] encoding:CPASCIIStringEncoding]];
}

- (void)testISOLatin1
{
    [self assert:@"é\u0080" equals:[self stringFromBytes:[0xE9, 0x80] encoding:CPISOLatin1StringEncoding]];
    [self assert:[0xE9] equals:[self bytesOfString:@"é" encoding:CPISOLatin1StringEncoding]];
    [self assertFalse:[@"€" canBeConvertedToEncoding:CPISOLatin1StringEncoding]];
}

- (void)testSingleByteCodePages
{
    [self assert:@"€" equals:[self stringFromBytes:[0x80] encoding:CPWindowsCP1252StringEncoding]];
    [self assert:[0x80] equals:[self bytesOfString:@"€" encoding:CPWindowsCP1252StringEncoding]];
    [self assert:@"é" equals:[self stringFromBytes:[0x8E] encoding:CPMacOSRomanStringEncoding]];
    [self assert:[0x8E] equals:[self bytesOfString:@"é" encoding:CPMacOSRomanStringEncoding]];
    [self assert:@"Ж" equals:[self stringFromBytes:[0xC6] encoding:CPWindowsCP1251StringEncoding]];
}

- (void)testUTF16
{
    [self assert:[0xFF, 0xFE, 0x41, 0x00] equals:[self bytesOfString:@"A" encoding:CPUnicodeStringEncoding]];
    [self assert:[0x00, 0x41] equals:[self bytesOfString:@"A" encoding:CPUTF16BigEndianStringEncoding]];
    [self assert:[0x41, 0x00] equals:[self bytesOfString:@"A" encoding:CPUTF16LittleEndianStringEncoding]];
    [self assert:@"A" equals:[self stringFromBytes:[0x00, 0x41] encoding:CPUTF16StringEncoding]];
    [self assert:@"A" equals:[self stringFromBytes:[0xFF, 0xFE, 0x41, 0x00] encoding:CPUTF16StringEncoding]];
    [self assert:@"𝄞" equals:[self stringFromBytes:[0xD8, 0x34, 0xDD, 0x1E] encoding:CPUTF16BigEndianStringEncoding]];
    [self assertNull:[self stringFromBytes:[0xD8, 0x34] encoding:CPUTF16BigEndianStringEncoding]];
    [self assertNull:[self stringFromBytes:[0x00] encoding:CPUTF16BigEndianStringEncoding]];
}

- (void)testUTF32
{
    [self assert:[0xFF, 0xFE, 0x00, 0x00, 0x1E, 0xD1, 0x01, 0x00] equals:[self bytesOfString:@"𝄞" encoding:CPUTF32StringEncoding]];
    [self assert:[0x00, 0x01, 0xD1, 0x1E] equals:[self bytesOfString:@"𝄞" encoding:CPUTF32BigEndianStringEncoding]];
    [self assert:@"𝄞" equals:[self stringFromBytes:[0x1E, 0xD1, 0x01, 0x00] encoding:CPUTF32LittleEndianStringEncoding]];
    [self assertNull:[self stringFromBytes:[0x00, 0x11, 0x00, 0x00] encoding:CPUTF32BigEndianStringEncoding]];
}

- (void)testNonLossyASCII
{
    var bytes = [self bytesOfString:@"a\\é" encoding:CPNonLossyASCIIStringEncoding];

    [self assert:@"a\\\\\\u00e9" equals:String.fromCharCode.apply(null, bytes)];
    [self assert:@"a\\é" equals:[self stringFromBytes:bytes encoding:CPNonLossyASCIIStringEncoding]];
    [self assert:@"é" equals:[self stringFromBytes:[0x5C, 0x33, 0x35, 0x31] encoding:CPNonLossyASCIIStringEncoding]];
    [self assertNull:[self stringFromBytes:[0xE9] encoding:CPNonLossyASCIIStringEncoding]];
}

- (void)testJapaneseDecodesButDoesNotEncode
{
    [self assert:@"日" equals:[self stringFromBytes:[0x93, 0xFA] encoding:CPShiftJISStringEncoding]];
    [self assertFalse:[@"日" canBeConvertedToEncoding:CPShiftJISStringEncoding]];
    [self assertNull:[@"日" dataUsingEncoding:CPShiftJISStringEncoding allowLossyConversion:YES]];
}

- (void)testInitWithBytesLength
{
    [self assert:@"ab" equals:[[CPString alloc] initWithBytes:[0x61, 0x62, 0x63] length:2 encoding:CPUTF8StringEncoding]];
}

- (void)testLengths
{
    [self assert:2 equals:[@"é" lengthOfBytesUsingEncoding:CPUTF8StringEncoding]];
    [self assert:0 equals:[@"é" lengthOfBytesUsingEncoding:CPASCIIStringEncoding]];
    [self assert:6 equals:[@"ab" maximumLengthOfBytesUsingEncoding:CPUTF8StringEncoding]];
    [self assert:6 equals:[@"ab" maximumLengthOfBytesUsingEncoding:CPUnicodeStringEncoding]];
    [self assert:0 equals:[@"ab" maximumLengthOfBytesUsingEncoding:12345]];
}

- (void)testSmallestAndFastestEncoding
{
    [self assert:CPASCIIStringEncoding equals:[@"abc" smallestEncoding]];
    [self assert:CPISOLatin1StringEncoding equals:[@"é" smallestEncoding]];
    [self assert:CPUnicodeStringEncoding equals:[@"日本" smallestEncoding]];
    [self assert:CPUnicodeStringEncoding equals:[@"abc" fastestEncoding]];
}

- (void)testAvailableEncodingsAndNames
{
    var encodings = [CPString availableStringEncodings];

    [self assertTrue:[encodings containsObject:CPUTF8StringEncoding]];
    [self assertTrue:[encodings containsObject:CPUTF32StringEncoding]];
    [self assertFalse:[encodings containsObject:CPNEXTSTEPStringEncoding]];
    [self assert:0 equals:[encodings lastObject]];
    [self assert:[encodings count] - 1 equals:[encodings indexOfObject:0]];
    [self assert:@"Unicode (UTF-8)" equals:[CPString localizedNameOfStringEncoding:CPUTF8StringEncoding]];
    [self assert:@"Symbol" equals:[CPString localizedNameOfStringEncoding:CPSymbolStringEncoding]];
    [self assert:@"" equals:[CPString localizedNameOfStringEncoding:12345]];
    [self assert:CPUTF8StringEncoding equals:[CPString defaultCStringEncoding]];
}

- (void)testDetectionByteOrderMark
{
    var string = nil,
        lossy = YES,
        encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0xEF, 0xBB, 0xBF, 0x61]] encodingOptions:nil convertedString:@ref(string) usedLossyConversion:@ref(lossy)];

    [self assert:CPUTF8StringEncoding equals:encoding];
    [self assert:@"a" equals:string];
    [self assertFalse:lossy];

    encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0xFF, 0xFE, 0x61, 0x00]] encodingOptions:nil convertedString:@ref(string) usedLossyConversion:nil];

    [self assert:CPUTF16LittleEndianStringEncoding equals:encoding];
    [self assert:@"a" equals:string];
}

- (void)testDetectionPrefersUTF8ThenWindowsLatin1
{
    var string = nil,
        encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0xC3, 0xA9]] encodingOptions:nil convertedString:@ref(string) usedLossyConversion:nil];

    [self assert:CPUTF8StringEncoding equals:encoding];
    [self assert:@"é" equals:string];

    encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0xE9]] encodingOptions:nil convertedString:@ref(string) usedLossyConversion:nil];

    [self assert:CPWindowsCP1252StringEncoding equals:encoding];
    [self assert:@"é" equals:string];
}

- (void)testDetectionWithOnlySuggestedEncodings
{
    var string = nil,
        lossy = NO,
        options = @{
            CPStringEncodingDetectionSuggestedEncodingsKey: [CPASCIIStringEncoding],
            CPStringEncodingDetectionUseOnlySuggestedEncodingsKey: YES,
            CPStringEncodingDetectionAllowLossyKey: NO
        },
        encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0x61, 0xE9]] encodingOptions:options convertedString:@ref(string) usedLossyConversion:@ref(lossy)];

    [self assert:0 equals:encoding];
    [self assertNull:string];

    options = @{
        CPStringEncodingDetectionSuggestedEncodingsKey: [CPASCIIStringEncoding],
        CPStringEncodingDetectionUseOnlySuggestedEncodingsKey: YES,
        CPStringEncodingDetectionAllowLossyKey: YES
    };
    encoding = [CPString stringEncodingForData:[CPData dataWithBytes:[0x61, 0xE9]] encodingOptions:options convertedString:@ref(string) usedLossyConversion:@ref(lossy)];

    [self assert:CPASCIIStringEncoding equals:encoding];
    [self assert:@"a�" equals:string];
    [self assertTrue:lossy];
}

@end
