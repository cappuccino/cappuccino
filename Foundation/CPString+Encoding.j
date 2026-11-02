/*
 *  CPString+Encoding.j
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

@import "CPArray.j"
@import "CPData.j"
@import "CPDictionary.j"
@import "CPString.j"

@typedef CPStringEncoding

@global TextDecoder

/*
    String encodings. The values are Cocoa's, so that archived values and values exchanged with
    Cocoa applications agree.
*/
CPASCIIStringEncoding               = 1;
CPNEXTSTEPStringEncoding            = 2;
CPJapaneseEUCStringEncoding         = 3;
CPUTF8StringEncoding                = 4;
CPISOLatin1StringEncoding           = 5;
CPSymbolStringEncoding              = 6;
CPNonLossyASCIIStringEncoding       = 7;
CPShiftJISStringEncoding            = 8;
CPISOLatin2StringEncoding           = 9;
CPUnicodeStringEncoding             = 10;
CPWindowsCP1251StringEncoding       = 11;
CPWindowsCP1252StringEncoding       = 12;
CPWindowsCP1253StringEncoding       = 13;
CPWindowsCP1254StringEncoding       = 14;
CPWindowsCP1250StringEncoding       = 15;
CPISO2022JPStringEncoding           = 21;
CPMacOSRomanStringEncoding          = 30;
CPUTF16StringEncoding               = CPUnicodeStringEncoding;
CPUTF16BigEndianStringEncoding      = 0x90000100;
CPUTF16LittleEndianStringEncoding   = 0x94000100;
CPUTF32StringEncoding               = 0x8c000100;
CPUTF32BigEndianStringEncoding      = 0x98000100;
CPUTF32LittleEndianStringEncoding   = 0x9c000100;

/*
    TODO: Cocoa defines three more detection option keys, which can be supported:
    CPStringEncodingDetectionFromWindowsKey, to prefer the Windows code pages;
    CPStringEncodingDetectionLossySubstitutionKey, the text that replaces bytes which cannot be
    decoded; and CPStringEncodingDetectionLikelyLanguageKey, a language that orders the candidate
    encodings.
*/
/*
    Keys for the options of +stringEncodingForData:encodingOptions:convertedString:usedLossyConversion:.
*/
CPStringEncodingDetectionSuggestedEncodingsKey          = @"CPStringEncodingDetectionSuggestedEncodingsKey";
CPStringEncodingDetectionUseOnlySuggestedEncodingsKey   = @"CPStringEncodingDetectionUseOnlySuggestedEncodingsKey";
CPStringEncodingDetectionAllowLossyKey                  = @"CPStringEncodingDetectionAllowLossyKey";

var CPStringEncodingChunkSize = 8192,
    CPStringEncodingReplacementCharacter = 0xFFFD,
    CPStringEncodingSingleByteMaps = {};

// MARK: Decoding

/*
    Returns a string made from an array of UTF-16 code units. The array is converted in chunks,
    because a very long argument list exceeds the JavaScript engine's limit.
*/
var CPStringEncodingStringFromCodeUnits = function(codeUnits)
{
    var output = "";

    for (var i = 0, count = codeUnits.length; i < count; i += CPStringEncodingChunkSize)
        output += String.fromCharCode.apply(null, codeUnits.slice(i, i + CPStringEncodingChunkSize));

    return output;
};

/*
    Adds a code point to an array of UTF-16 code units, as a surrogate pair when needed.
*/
var CPStringEncodingPushCodePoint = function(codeUnits, codePoint)
{
    if (codePoint < 0x10000)
        codeUnits.push(codePoint);
    else
    {
        codePoint -= 0x10000;
        codeUnits.push(0xD800 + (codePoint >> 10), 0xDC00 + (codePoint & 0x3FF));
    }
};

/*
    Decodes bytes with the browser's TextDecoder, which knows the encodings of the WHATWG Encoding
    Standard. Returns nil when the bytes are not valid in the encoding, or when there is no
    TextDecoder. With isLossy, invalid bytes become U+FFFD instead.
*/
var CPStringEncodingDecodeWithTextDecoder = function(aLabel, bytes, isLossy)
{
    if (typeof TextDecoder === "undefined")
        return nil;

    try
    {
        return new TextDecoder(aLabel, { fatal: !isLossy }).decode(bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes));
    }
    catch (anException)
    {
        return nil;
    }
};

/*
    Decodes ISO Latin 1, in which each byte is the code point of the same value. The browser's
    TextDecoder cannot be used: the Encoding Standard treats ISO Latin 1 as Windows-1252.
*/
var CPStringEncodingDecodeLatin1 = function(bytes)
{
    return CPStringEncodingStringFromCodeUnits(bytes);
};

var CPStringEncodingDecodeASCII = function(bytes, isLossy)
{
    for (var i = 0, count = bytes.length; i < count; i++)
        if (bytes[i] > 0x7F)
        {
            if (!isLossy)
                return nil;

            bytes = Array.prototype.map.call(bytes, function(aByte) { return aByte > 0x7F ? CPStringEncodingReplacementCharacter : aByte; });
            break;
        }

    return CPStringEncodingStringFromCodeUnits(bytes);
};

/*
    Decodes UTF-16. A byte order mark, when allowed and present, sets the byte order and is
    removed. Unpaired surrogates are invalid.
*/
var CPStringEncodingDecodeUTF16 = function(bytes, isLittleEndian, readsByteOrderMark, isLossy)
{
    var start = 0,
        count = bytes.length;

    if (count % 2 && !isLossy)
        return nil;

    if (readsByteOrderMark && count >= 2)
    {
        if (bytes[0] === 0xFE && bytes[1] === 0xFF)
        {
            isLittleEndian = NO;
            start = 2;
        }
        else if (bytes[0] === 0xFF && bytes[1] === 0xFE)
        {
            isLittleEndian = YES;
            start = 2;
        }
    }

    var codeUnits = [];

    for (var i = start; i + 1 < count; i += 2)
        codeUnits.push(isLittleEndian ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1]);

    for (var i = 0, unitCount = codeUnits.length; i < unitCount; i++)
    {
        var unit = codeUnits[i];

        if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < unitCount && codeUnits[i + 1] >= 0xDC00 && codeUnits[i + 1] <= 0xDFFF)
            i++;
        else if (unit >= 0xD800 && unit <= 0xDFFF)
        {
            if (!isLossy)
                return nil;

            codeUnits[i] = CPStringEncodingReplacementCharacter;
        }
    }

    if (count % 2)
        codeUnits.push(CPStringEncodingReplacementCharacter);

    return CPStringEncodingStringFromCodeUnits(codeUnits);
};

/*
    Decodes UTF-32, which the browser's TextDecoder does not know. A byte order mark, when
    allowed and present, sets the byte order and is removed. Code points above U+10FFFF and
    surrogate code points are invalid.
*/
var CPStringEncodingDecodeUTF32 = function(bytes, isLittleEndian, readsByteOrderMark, isLossy)
{
    var start = 0,
        count = bytes.length;

    if (count % 4 && !isLossy)
        return nil;

    if (readsByteOrderMark && count >= 4)
    {
        if (bytes[0] === 0x00 && bytes[1] === 0x00 && bytes[2] === 0xFE && bytes[3] === 0xFF)
        {
            isLittleEndian = NO;
            start = 4;
        }
        else if (bytes[0] === 0xFF && bytes[1] === 0xFE && bytes[2] === 0x00 && bytes[3] === 0x00)
        {
            isLittleEndian = YES;
            start = 4;
        }
    }

    var codeUnits = [];

    for (var i = start; i + 3 < count; i += 4)
    {
        var codePoint = isLittleEndian ?
                (bytes[i] | (bytes[i + 1] << 8) | (bytes[i + 2] << 16) | (bytes[i + 3] << 24)) >>> 0 :
                ((bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3]) >>> 0;

        if (codePoint > 0x10FFFF || (codePoint >= 0xD800 && codePoint <= 0xDFFF))
        {
            if (!isLossy)
                return nil;

            codePoint = CPStringEncodingReplacementCharacter;
        }

        CPStringEncodingPushCodePoint(codeUnits, codePoint);
    }

    if (count % 4)
        codeUnits.push(CPStringEncodingReplacementCharacter);

    return CPStringEncodingStringFromCodeUnits(codeUnits);
};

/*
    Decodes non-lossy ASCII: 7-bit ASCII in which a backslash starts an escape. "\\" is a
    backslash, "\uXXXX" is a UTF-16 code unit in hexadecimal, and "\ddd" is a code unit up to
    0xFF in octal.
*/
var CPStringEncodingDecodeNonLossyASCII = function(bytes, isLossy)
{
    var codeUnits = [];

    for (var i = 0, count = bytes.length; i < count; i++)
    {
        var aByte = bytes[i];

        if (aByte > 0x7F)
        {
            if (!isLossy)
                return nil;

            codeUnits.push(CPStringEncodingReplacementCharacter);
            continue;
        }

        if (aByte !== 0x5C)
        {
            codeUnits.push(aByte);
            continue;
        }

        var rest = String.fromCharCode.apply(null, bytes.slice(i + 1, i + 6)),
            match = nil;

        if (rest.charAt(0) === "\\")
        {
            codeUnits.push(0x5C);
            i += 1;
        }
        else if ((match = /^u([0-9A-Fa-f]{4})/.exec(rest)))
        {
            codeUnits.push(parseInt(match[1], 16));
            i += 5;
        }
        else if ((match = /^([0-3][0-7]{2})/.exec(rest)))
        {
            codeUnits.push(parseInt(match[1], 8));
            i += 3;
        }
        else if (isLossy)
            codeUnits.push(0x5C);
        else
            return nil;
    }

    return CPStringEncodingStringFromCodeUnits(codeUnits);
};

// MARK: Encoding

/*
    Calls aFunction with each code point of a string. An unpaired surrogate is passed as -1.
*/
var CPStringEncodingForEachCodePoint = function(aString, aFunction)
{
    for (var i = 0, count = aString.length; i < count; i++)
    {
        var unit = aString.charCodeAt(i);

        if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < count)
        {
            var next = aString.charCodeAt(i + 1);

            if (next >= 0xDC00 && next <= 0xDFFF)
            {
                aFunction(0x10000 + ((unit - 0xD800) << 10) + (next - 0xDC00));
                i++;
                continue;
            }
        }

        aFunction(unit >= 0xD800 && unit <= 0xDFFF ? -1 : unit);
    }
};

/*
    Encodes UTF-8. An unpaired surrogate cannot be encoded: it makes the result nil, or with
    isLossy becomes U+FFFD.
*/
var CPStringEncodingEncodeUTF8 = function(aString, isLossy)
{
    var bytes = [],
        failed = NO;

    CPStringEncodingForEachCodePoint(aString, function(codePoint)
    {
        if (codePoint < 0)
        {
            if (!isLossy)
                failed = YES;

            codePoint = CPStringEncodingReplacementCharacter;
        }

        if (codePoint < 0x80)
            bytes.push(codePoint);
        else if (codePoint < 0x800)
            bytes.push(0xC0 | (codePoint >> 6), 0x80 | (codePoint & 0x3F));
        else if (codePoint < 0x10000)
            bytes.push(0xE0 | (codePoint >> 12), 0x80 | ((codePoint >> 6) & 0x3F), 0x80 | (codePoint & 0x3F));
        else
            bytes.push(0xF0 | (codePoint >> 18), 0x80 | ((codePoint >> 12) & 0x3F), 0x80 | ((codePoint >> 6) & 0x3F), 0x80 | (codePoint & 0x3F));
    });

    return failed ? nil : bytes;
};

var CPStringEncodingEncodeUTF16 = function(aString, isLittleEndian, writesByteOrderMark, isLossy)
{
    var bytes = writesByteOrderMark ? (isLittleEndian ? [0xFF, 0xFE] : [0xFE, 0xFF]) : [],
        failed = NO,
        pushUnit = function(unit)
        {
            if (isLittleEndian)
                bytes.push(unit & 0xFF, unit >> 8);
            else
                bytes.push(unit >> 8, unit & 0xFF);
        };

    CPStringEncodingForEachCodePoint(aString, function(codePoint)
    {
        if (codePoint < 0)
        {
            if (!isLossy)
                failed = YES;

            codePoint = CPStringEncodingReplacementCharacter;
        }

        if (codePoint < 0x10000)
            pushUnit(codePoint);
        else
        {
            pushUnit(0xD800 + ((codePoint - 0x10000) >> 10));
            pushUnit(0xDC00 + ((codePoint - 0x10000) & 0x3FF));
        }
    });

    return failed ? nil : bytes;
};

var CPStringEncodingEncodeUTF32 = function(aString, isLittleEndian, writesByteOrderMark, isLossy)
{
    var bytes = writesByteOrderMark ? (isLittleEndian ? [0xFF, 0xFE, 0x00, 0x00] : [0x00, 0x00, 0xFE, 0xFF]) : [],
        failed = NO;

    CPStringEncodingForEachCodePoint(aString, function(codePoint)
    {
        if (codePoint < 0)
        {
            if (!isLossy)
                failed = YES;

            codePoint = CPStringEncodingReplacementCharacter;
        }

        if (isLittleEndian)
            bytes.push(codePoint & 0xFF, (codePoint >> 8) & 0xFF, (codePoint >> 16) & 0xFF, 0x00);
        else
            bytes.push(0x00, (codePoint >> 16) & 0xFF, (codePoint >> 8) & 0xFF, codePoint & 0xFF);
    });

    return failed ? nil : bytes;
};

/*
    TODO: Check the format against Cocoa's output. Cocoa may write characters from U+0080 to
    U+00FF as octal escapes rather than "\uXXXX". Decoding accepts both forms.
*/
/*
    Encodes non-lossy ASCII: ASCII characters stay as they are, a backslash becomes "\\", and
    every other UTF-16 code unit becomes "\uXXXX". Every string can be encoded.
*/
var CPStringEncodingEncodeNonLossyASCII = function(aString)
{
    var bytes = [];

    for (var i = 0, count = aString.length; i < count; i++)
    {
        var unit = aString.charCodeAt(i);

        if (unit === 0x5C)
            bytes.push(0x5C, 0x5C);
        else if (unit < 0x80)
            bytes.push(unit);
        else
        {
            var hex = ("000" + unit.toString(16)).slice(-4);

            bytes.push(0x5C, 0x75);

            for (var j = 0; j < 4; j++)
                bytes.push(hex.charCodeAt(j));
        }
    }

    return bytes;
};

/*
    Returns a map from code point to byte for a single-byte encoding. ASCII and ISO Latin 1 map
    code points to bytes of the same value. Other single-byte encodings are mapped by decoding
    each byte with the browser's TextDecoder, so that encoding and decoding agree. Returns nil
    when there is no TextDecoder.
*/
var CPStringEncodingSingleByteMap = function(aDescriptor)
{
    var map = CPStringEncodingSingleByteMaps[aDescriptor.encoding];

    if (map)
        return map;

    map = {};

    if (aDescriptor.maximumByte)
    {
        for (var aByte = 0; aByte <= aDescriptor.maximumByte; aByte++)
            map[aByte] = aByte;
    }
    else
    {
        if (typeof TextDecoder === "undefined")
            return nil;

        var decoder = new TextDecoder(aDescriptor.label);

        for (var aByte = 0; aByte <= 0xFF; aByte++)
        {
            var decoded = decoder.decode(new Uint8Array([aByte]));

            if (decoded.length === 1 && decoded.charCodeAt(0) !== CPStringEncodingReplacementCharacter)
                map[decoded.charCodeAt(0)] = aByte;
        }
    }

    CPStringEncodingSingleByteMaps[aDescriptor.encoding] = map;

    return map;
};

/*
    Encodes a single-byte encoding. A character with no byte makes the result nil. With isLossy,
    it becomes its base letter when that has a byte, so that "é" becomes "e", and otherwise "?".
*/
var CPStringEncodingEncodeSingleByte = function(aDescriptor, aString, isLossy)
{
    var map = CPStringEncodingSingleByteMap(aDescriptor),
        bytes = [],
        failed = NO;

    if (!map)
        return nil;

    CPStringEncodingForEachCodePoint(aString, function(codePoint)
    {
        var aByte = map[codePoint];

        if (aByte === undefined)
        {
            if (!isLossy)
            {
                failed = YES;
                return;
            }

            var base = codePoint >= 0 ? String.fromCodePoint(codePoint).normalize("NFD").charCodeAt(0) : -1;

            aByte = map[base];

            if (aByte === undefined)
                aByte = 0x3F;
        }

        bytes.push(aByte);
    });

    return failed ? nil : bytes;
};

// MARK: Encodings

/*
    Describes each supported encoding: its name, how to decode and encode it, and the most bytes
    one UTF-16 code unit can take. An encoding with a TextDecoder label needs the browser's
    TextDecoder. The Japanese encodings can be decoded but not encoded, because the browser has
    no encoder for them.
*/
var CPStringEncodingDescriptors = {},
    CPStringEncodingOrder = [];

var CPStringEncodingAddDescriptor = function(anEncoding, aName, aDescriptor)
{
    aDescriptor.encoding = anEncoding;
    aDescriptor.name = aName;

    CPStringEncodingDescriptors[anEncoding] = aDescriptor;
    CPStringEncodingOrder.push(anEncoding);
};

var CPStringEncodingAddSingleByteDescriptor = function(anEncoding, aName, aLabel)
{
    var descriptor = {
        label: aLabel,
        maximumLength: 1,
        decode: function(bytes, isLossy) { return CPStringEncodingDecodeWithTextDecoder(aLabel, bytes, isLossy); },
        encode: function(aString, isLossy) { return CPStringEncodingEncodeSingleByte(descriptor, aString, isLossy); }
    };

    CPStringEncodingAddDescriptor(anEncoding, aName, descriptor);
};

CPStringEncodingAddDescriptor(CPUTF8StringEncoding, @"Unicode (UTF-8)", {
    label: "utf-8",
    maximumLength: 3,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeWithTextDecoder("utf-8", bytes, isLossy); },
    encode: CPStringEncodingEncodeUTF8
});

CPStringEncodingAddDescriptor(CPASCIIStringEncoding, @"Western (ASCII)", {
    maximumByte: 0x7F,
    maximumLength: 1,
    decode: CPStringEncodingDecodeASCII,
    encode: function(aString, isLossy) { return CPStringEncodingEncodeSingleByte(CPStringEncodingDescriptors[CPASCIIStringEncoding], aString, isLossy); }
});

CPStringEncodingAddDescriptor(CPISOLatin1StringEncoding, @"Western (ISO Latin 1)", {
    maximumByte: 0xFF,
    maximumLength: 1,
    decode: CPStringEncodingDecodeLatin1,
    encode: function(aString, isLossy) { return CPStringEncodingEncodeSingleByte(CPStringEncodingDescriptors[CPISOLatin1StringEncoding], aString, isLossy); }
});

CPStringEncodingAddDescriptor(CPNonLossyASCIIStringEncoding, @"Non-lossy ASCII", {
    maximumLength: 6,
    decode: CPStringEncodingDecodeNonLossyASCII,
    encode: CPStringEncodingEncodeNonLossyASCII
});

CPStringEncodingAddDescriptor(CPUnicodeStringEncoding, @"Unicode (UTF-16)", {
    maximumLength: 2,
    byteOrderMarkLength: 2,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF16(bytes, NO, YES, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF16(aString, YES, YES, isLossy); }
});

CPStringEncodingAddDescriptor(CPUTF16BigEndianStringEncoding, @"Unicode (UTF-16BE)", {
    maximumLength: 2,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF16(bytes, NO, NO, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF16(aString, NO, NO, isLossy); }
});

CPStringEncodingAddDescriptor(CPUTF16LittleEndianStringEncoding, @"Unicode (UTF-16LE)", {
    maximumLength: 2,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF16(bytes, YES, NO, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF16(aString, YES, NO, isLossy); }
});

CPStringEncodingAddDescriptor(CPUTF32StringEncoding, @"Unicode (UTF-32)", {
    maximumLength: 4,
    byteOrderMarkLength: 4,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF32(bytes, NO, YES, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF32(aString, YES, YES, isLossy); }
});

CPStringEncodingAddDescriptor(CPUTF32BigEndianStringEncoding, @"Unicode (UTF-32BE)", {
    maximumLength: 4,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF32(bytes, NO, NO, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF32(aString, NO, NO, isLossy); }
});

CPStringEncodingAddDescriptor(CPUTF32LittleEndianStringEncoding, @"Unicode (UTF-32LE)", {
    maximumLength: 4,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeUTF32(bytes, YES, NO, isLossy); },
    encode: function(aString, isLossy) { return CPStringEncodingEncodeUTF32(aString, YES, NO, isLossy); }
});

CPStringEncodingAddSingleByteDescriptor(CPWindowsCP1252StringEncoding, @"Western (Windows Latin 1)", "windows-1252");
CPStringEncodingAddSingleByteDescriptor(CPMacOSRomanStringEncoding, @"Western (Mac OS Roman)", "macintosh");
CPStringEncodingAddSingleByteDescriptor(CPWindowsCP1250StringEncoding, @"Central European (Windows Latin 2)", "windows-1250");
CPStringEncodingAddSingleByteDescriptor(CPISOLatin2StringEncoding, @"Central European (ISO Latin 2)", "iso-8859-2");
CPStringEncodingAddSingleByteDescriptor(CPWindowsCP1251StringEncoding, @"Cyrillic (Windows)", "windows-1251");
CPStringEncodingAddSingleByteDescriptor(CPWindowsCP1253StringEncoding, @"Greek (Windows)", "windows-1253");
CPStringEncodingAddSingleByteDescriptor(CPWindowsCP1254StringEncoding, @"Turkish (Windows Latin 5)", "windows-1254");

/*
    TODO: Encoders for EUC, Shift JIS and ISO 2022-JP. The browser has no encoder for them, so
    they need Cappuccino's own tables, built from JIS X 0208 and JIS X 0212.
*/
CPStringEncodingAddDescriptor(CPJapaneseEUCStringEncoding, @"Japanese (EUC)", {
    label: "euc-jp",
    maximumLength: 3,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeWithTextDecoder("euc-jp", bytes, isLossy); },
    encode: nil
});

CPStringEncodingAddDescriptor(CPShiftJISStringEncoding, @"Japanese (Shift JIS)", {
    label: "shift_jis",
    maximumLength: 2,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeWithTextDecoder("shift_jis", bytes, isLossy); },
    encode: nil
});

CPStringEncodingAddDescriptor(CPISO2022JPStringEncoding, @"Japanese (ISO 2022-JP)", {
    label: "iso-2022-jp",
    maximumLength: 5,
    extraLength: 3,
    decode: function(bytes, isLossy) { return CPStringEncodingDecodeWithTextDecoder("iso-2022-jp", bytes, isLossy); },
    encode: nil
});

/*
    Names of the encodings that are defined for compatibility but not supported: the browser
    has no decoder for them.
*/
var CPStringEncodingUnsupportedNames = {};

CPStringEncodingUnsupportedNames[CPNEXTSTEPStringEncoding] = @"Western (NextStep)";
CPStringEncodingUnsupportedNames[CPSymbolStringEncoding] = @"Symbol";

/*
    Returns YES if an encoding can be decoded in this environment. An encoding that needs the
    browser's TextDecoder is available only where it exists and knows the encoding.
*/
var CPStringEncodingIsAvailable = function(aDescriptor)
{
    if (!aDescriptor)
        return NO;

    if (!aDescriptor.label)
        return YES;

    if (typeof TextDecoder === "undefined")
        return NO;

    try
    {
        new TextDecoder(aDescriptor.label);
        return YES;
    }
    catch (anException)
    {
        return NO;
    }
};

/*
    Returns the bytes of data as an array of bytes. Data that holds a binary string, such as
    file contents from CPItemProvider, is converted to a Uint8Array, which takes one byte for
    each byte. Asking CPData for its bytes would build a plain array of JavaScript numbers, many
    times the size, because CFData stores bytes that way, and keep it in the data.
*/
var CPStringEncodingBytesOfData = function(someData)
{
    if (!someData)
        return [];

    if (someData._bytes)
        return someData._bytes;

    var string = someData.rawString(),
        count = string.length,
        bytes = new Uint8Array(count);

    for (var i = 0; i < count; i++)
        bytes[i] = string.charCodeAt(i) & 0xFF;

    return bytes;
};

/*
    Returns the bytes from anIndex to the end, without copying when the bytes are a Uint8Array.
*/
var CPStringEncodingBytesFromIndex = function(bytes, anIndex)
{
    return bytes.subarray ? bytes.subarray(anIndex) : bytes.slice(anIndex);
};

var CPStringEncodingDecode = function(bytes, anEncoding, isLossy)
{
    var descriptor = CPStringEncodingDescriptors[anEncoding];

    if (!CPStringEncodingIsAvailable(descriptor))
        return nil;

    return descriptor.decode(bytes || [], isLossy);
};

/*
    TODO: Gaps against NSString's encoding API that can be filled:

    - -getBytes:maxLength:usedLength:encoding:options:range:remainingRange:, with the
      CPStringEncodingConversionAllowLossy and CPStringEncodingConversionExternalRepresentation
      options. The buffer would be a CPArray passed by reference.
    - The CPProprietaryStringEncoding constant.
    - The category names. Cocoa declares these methods in NSString (NSStringExtensionMethods)
      and NSString (NSStringEncodingDetection). This category's name is the same as the
      CPStringEncoding type.
*/

/*!
    @class CPString
    @ingroup foundation

    String encodings convert between strings and bytes. The encodings and their values are
    Cocoa's. In a browser:

    - Every encoding in -availableStringEncodings can be decoded. The browser's TextDecoder
      decodes most of them; ASCII, ISO Latin 1, non-lossy ASCII, UTF-16 and UTF-32 are decoded
      directly.
    - Every available encoding except the Japanese ones can also be encoded. The browser has no
      encoder for EUC, Shift JIS or ISO 2022-JP, so a string cannot be converted to them.
    - NEXTSTEP and Symbol are defined for compatibility, but not available.
    - Encoding names are in English.
    - C strings do not exist, so Cocoa's C string methods are not provided.
*/
@implementation CPString (CPStringEncoding)

// MARK: Encodings

/*!
    Returns the encodings that can be decoded in this environment. The array ends with 0, as in
    Cocoa, so that code which loops until it reaches 0 works unchanged:

    <pre>
    var encodings = [CPString availableStringEncodings];

    for (var i = 0; encodings[i] !== 0; i++)
        [self addEncoding:encodings[i]];
    </pre>

    The 0 is an element of the array, so -count includes it.
*/
+ (CPArray)availableStringEncodings
{
    var encodings = [];

    for (var i = 0, count = CPStringEncodingOrder.length; i < count; i++)
        if (CPStringEncodingIsAvailable(CPStringEncodingDescriptors[CPStringEncodingOrder[i]]))
            encodings.push(CPStringEncodingOrder[i]);

    encodings.push(0);

    return encodings;
}

/*!
    Returns the name of an encoding, such as "Unicode (UTF-8)", or an empty string for an
    unknown encoding.
*/
+ (CPString)localizedNameOfStringEncoding:(CPStringEncoding)anEncoding
{
    var descriptor = CPStringEncodingDescriptors[anEncoding];

    if (descriptor)
        return descriptor.name;

    return CPStringEncodingUnsupportedNames[anEncoding] || @"";
}

/*
    TODO: Cocoa returns the system's C string encoding, usually Mac OS Roman on macOS. Decide
    whether to match it.
*/
/*!
    Returns the encoding used when no other is specified: UTF-8.
*/
+ (CPStringEncoding)defaultCStringEncoding
{
    return CPUTF8StringEncoding;
}

// MARK: Creating Strings from Bytes

/*!
    Returns a string decoded from data in an encoding, or nil when the data is not valid in the
    encoding, or the encoding is not available.
*/
- (id)initWithData:(CPData)someData encoding:(CPStringEncoding)anEncoding
{
    var decoded = CPStringEncodingDecode(CPStringEncodingBytesOfData(someData), anEncoding, NO);

    if (decoded === nil)
        return nil;

    return [self initWithString:decoded];
}

/*!
    Returns a string decoded from the first \c aLength bytes of an array of bytes, or nil when
    the bytes are not valid in the encoding, or the encoding is not available.
*/
- (id)initWithBytes:(CPArray)someBytes length:(unsigned)aLength encoding:(CPStringEncoding)anEncoding
{
    var bytes = (someBytes || []).slice(0, aLength),
        decoded = CPStringEncodingDecode(bytes, anEncoding, NO);

    if (decoded === nil)
        return nil;

    return [self initWithString:decoded];
}

/*
    TODO: Cocoa scores candidate encodings statistically, so it can choose a different encoding
    than these fixed rules do. Decide how close detection must come to Cocoa's results.
*/
/*!
    Returns the encoding of data, and the string decoded from it.

    The encoding is chosen in this order:

    - A byte order mark for UTF-8, UTF-16 or UTF-32.
    - UTF-8, when the data is valid UTF-8, unless only suggested encodings may be used.
    - The suggested encodings, in their order.
    - Windows Latin 1, which every byte sequence decodes in, unless only suggested encodings may
      be used.
    - When lossy conversion is allowed, the first candidate, with invalid bytes replaced.

    The options are:

    - CPStringEncodingDetectionSuggestedEncodingsKey: an array of encodings to try.
    - CPStringEncodingDetectionUseOnlySuggestedEncodingsKey: YES to try only the suggested
      encodings, after a byte order mark.
    - CPStringEncodingDetectionAllowLossyKey: NO to refuse lossy conversion. The default is YES.

    @param someData the data to decode
    @param someOptions the options, or nil
    @param aStringRef a reference that receives the decoded string, or nil
    @param aLossyRef a reference that receives YES if the conversion was lossy, or nil
    @return the encoding, or 0 when no encoding fits
*/
+ (CPStringEncoding)stringEncodingForData:(CPData)someData encodingOptions:(CPDictionary)someOptions convertedString:(CPStringRef)aStringRef usedLossyConversion:(BOOLRef)aLossyRef
{
    var bytes = CPStringEncodingBytesOfData(someData),
        suggested = [someOptions objectForKey:CPStringEncodingDetectionSuggestedEncodingsKey] || [],
        usesOnlySuggested = !![someOptions objectForKey:CPStringEncodingDetectionUseOnlySuggestedEncodingsKey],
        allowLossy = [someOptions objectForKey:CPStringEncodingDetectionAllowLossyKey],
        result = function(anEncoding, aString, isLossy)
        {
            if (aStringRef)
                @deref(aStringRef) = aString;

            if (aLossyRef)
                @deref(aLossyRef) = isLossy;

            return anEncoding;
        };

    allowLossy = allowLossy === nil || allowLossy === undefined ? YES : !!allowLossy;

    var byteOrderMarks = [
            [[0xEF, 0xBB, 0xBF], CPUTF8StringEncoding],
            [[0xFF, 0xFE, 0x00, 0x00], CPUTF32LittleEndianStringEncoding],
            [[0x00, 0x00, 0xFE, 0xFF], CPUTF32BigEndianStringEncoding],
            [[0xFE, 0xFF], CPUTF16BigEndianStringEncoding],
            [[0xFF, 0xFE], CPUTF16LittleEndianStringEncoding]
        ];

    for (var i = 0; i < byteOrderMarks.length; i++)
    {
        var mark = byteOrderMarks[i][0];

        if (bytes.length >= mark.length && mark.every(function(aByte, anIndex) { return bytes[anIndex] === aByte; }))
        {
            var decoded = CPStringEncodingDecode(CPStringEncodingBytesFromIndex(bytes, mark.length), byteOrderMarks[i][1], NO);

            if (decoded !== nil)
                return result(byteOrderMarks[i][1], decoded, NO);
        }
    }

    var candidates = usesOnlySuggested ? [] : [CPUTF8StringEncoding];

    candidates = candidates.concat(suggested);

    if (!usesOnlySuggested)
        candidates.push(CPWindowsCP1252StringEncoding);

    for (var i = 0; i < candidates.length; i++)
    {
        var decoded = CPStringEncodingDecode(bytes, candidates[i], NO);

        if (decoded !== nil)
            return result(candidates[i], decoded, NO);
    }

    if (allowLossy)
    {
        for (var i = 0; i < candidates.length; i++)
        {
            var decoded = CPStringEncodingDecode(bytes, candidates[i], YES);

            if (decoded !== nil)
                return result(candidates[i], decoded, YES);
        }
    }

    result(0, nil, NO);

    return 0;
}

// MARK: Converting Strings to Bytes

/*!
    Returns the string encoded in an encoding, or nil when a character cannot be encoded in it.
*/
- (CPData)dataUsingEncoding:(CPStringEncoding)anEncoding
{
    return [self dataUsingEncoding:anEncoding allowLossyConversion:NO];
}

/*!
    Returns the string encoded in an encoding. With lossy conversion, a character that cannot be
    encoded becomes its base letter when the encoding has it, and otherwise "?". Returns nil when
    the encoding cannot be encoded in this environment, or, without lossy conversion, when a
    character cannot be encoded. UTF-16 and UTF-32 without a stated byte order start with a
    byte order mark, and are little-endian.
*/
- (CPData)dataUsingEncoding:(CPStringEncoding)anEncoding allowLossyConversion:(BOOL)isLossy
{
    var bytes = [self _bytesUsingEncoding:anEncoding allowLossyConversion:isLossy];

    return bytes ? [CPData dataWithBytes:bytes] : nil;
}

/*!
    @ignore
*/
- (CPArray)_bytesUsingEncoding:(CPStringEncoding)anEncoding allowLossyConversion:(BOOL)isLossy
{
    var descriptor = CPStringEncodingDescriptors[anEncoding];

    if (!CPStringEncodingIsAvailable(descriptor) || !descriptor.encode)
        return nil;

    return descriptor.encode(String(self), !!isLossy);
}

/*!
    Returns YES if every character of the string can be encoded in an encoding.
*/
- (BOOL)canBeConvertedToEncoding:(CPStringEncoding)anEncoding
{
    return [self _bytesUsingEncoding:anEncoding allowLossyConversion:NO] !== nil;
}

/*!
    Returns the number of bytes the string takes in an encoding, or 0 when it cannot be encoded
    in it.
*/
- (unsigned)lengthOfBytesUsingEncoding:(CPStringEncoding)anEncoding
{
    var bytes = [self _bytesUsingEncoding:anEncoding allowLossyConversion:NO];

    return bytes ? bytes.length : 0;
}

/*
    TODO: Check whether Cocoa counts the byte order mark for UTF-16 and UTF-32, as this method
    does.
*/
/*!
    Returns the most bytes the string can take in an encoding, without encoding it. The result
    may be much larger than the real length. Returns 0 for an unknown encoding.
*/
- (unsigned)maximumLengthOfBytesUsingEncoding:(CPStringEncoding)anEncoding
{
    var descriptor = CPStringEncodingDescriptors[anEncoding];

    if (!descriptor)
        return 0;

    return self.length * descriptor.maximumLength + (descriptor.byteOrderMarkLength || 0) + (descriptor.extraLength || 0);
}

/*!
    Returns the encoding in which the string converts fastest: UTF-16, the string's own form.
*/
- (CPStringEncoding)fastestEncoding
{
    return CPUnicodeStringEncoding;
}

/*
    TODO: Cocoa considers every encoding that represents the string without loss. This method
    compares only ASCII, ISO Latin 1, UTF-8 and UTF-16.
*/
/*!
    Returns the encoding, of ASCII, ISO Latin 1, UTF-8 and UTF-16, in which the string takes the
    fewest bytes without loss.
*/
- (CPStringEncoding)smallestEncoding
{
    var encodings = [CPASCIIStringEncoding, CPISOLatin1StringEncoding, CPUTF8StringEncoding, CPUTF16LittleEndianStringEncoding],
        smallestEncoding = CPUnicodeStringEncoding,
        smallestLength = Infinity;

    for (var i = 0; i < encodings.length; i++)
    {
        var bytes = [self _bytesUsingEncoding:encodings[i] allowLossyConversion:NO];

        if (bytes && bytes.length < smallestLength)
        {
            smallestEncoding = encodings[i] === CPUTF16LittleEndianStringEncoding ? CPUnicodeStringEncoding : encodings[i];
            smallestLength = bytes.length;
        }
    }

    return smallestEncoding;
}

@end
