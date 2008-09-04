/*
 * CPString.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

import "CPObject.j"


CPCaseInsensitiveSearch = 1;
CPLiteralSearch         = 2;
CPBackwardsSearch       = 4;
CPAnchoredSearch        = 8;
CPNumericSearch         = 64;

var CPStringHashes      = new objj_dictionary();

@implementation CPString : CPObject

+ (id)alloc
{
    return new String;
}

+ (id)string
{
    return [[self alloc] init];
}

+ (id)stringWithHash:(unsigned)aHash
{
    var zeros = "000000",
        digits = aHash.toString(16);
    
    return zeros.substring(0, zeros.length - digits.length) + digits;
}

+ (id)stringWithString:(CPString)aString
{
    return [[self alloc] initWithString:aString];
}

- (id)initWithString:(CPString)aString
{
    return aString + "";
}

- (CPString)description
{
    return "<" + self.isa.name + " 0x" + [CPString stringWithHash:[self hash]] + " \"" + self + "\">";
}

- (int)length
{
    return length;
}

- (char)characterAtIndex:(unsigned)anIndex
{
    return charAt(anIndex);
}

// Combining strings

- (CPString)stringByAppendingString:(CPString)aString
{
    return self + aString;
}

- (CPString)stringByPaddingToLength:(unsigned)aLength withString:(CPString)aString startingAtIndex:(unsigned)anIndex
{
    if (length == aLength)
        return self;

    if (aLength < length)
        return substr(0, aLength);

    var string = self,
        substring = aString.substr(anIndex),
        difference = aLength - length;

    while ((difference -= substring.length) > 0)
        string += substring;
    
    if (difference) string += substring.substr(difference + substring.length);
}

- (CPArray)componentsSeparatedByString:(CPString)aString
{
    return split(aString);
}

- (CPString)substringFromIndex:(unsigned)anIndex
{
    return substr(anIndex);
}

- (CPString)substringWithRange:(CPRange)aRange
{
    return substr(aRange.location, aRange.length);
}

- (CPString)substringToIndex:(unsigned)anIndex
{
    return substring(0, anIndex);
}

// Finding characters and substrings

- (CPRange)rangeOfString:(CPString)aString
{
    var location = indexOf(aString);
    
    return CPMakeRange(location, location == CPNotFound ? 0 : aString.length);
}

- (CPRange)rangeOfString:(CPString)aString options:(int)aMask
{
    var string = self,
        location = CPNotFound;
    
    if (aMask & CPCaseInsensitiveSearch)
    {
        string = string.toLowerCase();
        aString = aString.toLowerCase();
    }
    
    if (CPBackwardsSearch) location = lastIndexOf(aString, aMask & CPAnchoredSearch ? length - aString.length : 0);
    else if (aMask & CPAnchoredSearch) location = substr(0, aString.length).indexOf(aString) != CPNotFound ? 0 : CPNotFound;
    else location = indexOf(aString);
    
    return CPMakeRange(location, location == CPNotFound ? 0 : aString.length);
}

// Identifying and comparing strings

- (CPComparisonResult)caseInsensitiveCompare:(CPString)aString
{
    return [self compare:aString options:CPCaseInsensitiveSearch]
}

- (CPComparisonResult)compare:(CPString)aString options:(int)aMask
{
    var lhs = self,
        rhs = aString;
    
    if (aMask & CPCaseInsensitiveSearch)
    {
        lhs = lhs.toLowerCase();
        rhs = rhs.toLowerCase();
    }
    
    if (lhs < rhs)
        return CPOrderedAscending;
    else if (lhs > rhs)
        return CPOrderedDescending;
    
    return CPOrderedSame;
}

- (BOOL)hasPrefix:(CPString)aString
{
    return aString && aString != "" && indexOf(aString) == 0;
}

- (BOOL)hasSuffix:(CPString)aString
{
    return aString && aString != "" && lastIndexOf(aString) == (length - aString.length);
}

- (BOOL)isEqualToString:(CPString)aString
{
    return self == aString;
}

- (unsigned)hash
{
    var hash = dictionary_getValue(CPStringHashes, self);
    
    if (!hash) 
    {
        hash = _objj_generateObjectHash();
        dictionary_setValue(CPStringHashes, self, hash);
    }
    
    return hash;
}

- (CPString)capitalizedString
{
    var i = 0,
        last = true,
        capitalized = self;
    
    for(; i < length; ++i)
    {
        var character = charAt(i);
        if (character == ' ' || character == '\t' || character == '\n') last = true;
        else
        {
            if (last) capitalized = capitalized.substr(0, i - 1) + character.toUpperCase() + capitalized.substr(i);
            last = false;
        }
    }
    
    return capitalized;
}

- (CPString)lowercaseString
{
    return toLowerCase();
}

- (CPString)uppercaseString
{
    return toUpperCase();
}

- (double)doubleValue
{
    return eval(self);
}

- (float)floatValue
{
    return eval(self);
}

- (int)intValue
{
    return parseInt(self);
}

- (CPArray)pathComponents
{
    return split('/');
}

- (CPString)pathExtension
{
    return substr(lastIndexOf('.')+1);
}

- (CPString)lastPathComponent
{
    var components = [self pathComponents];
    return components[components.length -1];
}

- (CPString)stringByDeletingLastPathComponent
{
    // FIMXE: this is wrong: a/a/ returns a/a/.
    return substr(0, lastIndexOf('/') + 1);  
}

- (CPString)stringByStandardizingPath
{
    return objj_standardize_path(self);
}

- (CPString)copy
{
    return new String(self);
}

@end


String.prototype.isa = CPString;
