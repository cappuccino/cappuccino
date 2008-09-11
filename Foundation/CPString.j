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
import "CPException.j"

/*
    A case insensitive search
    @global
    @class CPString
*/
CPCaseInsensitiveSearch = 1;
/*
    Exact character match
    @global
    @class CPString
*/
CPLiteralSearch         = 2;
/*
    Start searching from the end of the string
    @global
    @class CPString
*/
CPBackwardsSearch       = 4;
/*
    @global
    @class CPString
*/
CPAnchoredSearch        = 8;
/*
    Numbers in the string are compared as numbers instead of strings
    @global
    @class CPString
*/
CPNumericSearch         = 64;

var CPStringHashes      = new objj_dictionary();

/*
    <objj>CPString</objj> is an object that allows management of strings. Because <objj>CPString</objj> is
    based on the JavaScript <code>String</code> object, <objj>CPString</objj>s are immutable, although the
    class does have methods that create new <objj>CPString</objj>s generated from modifications to the
    receiving instance.</p>

    <p>A handy feature of <objj>CPString</objj> instances is that they can be used wherever a JavaScript is
    required, and vice versa.
*/
@implementation CPString : CPObject

/*
    @ignore
*/
+ (id)alloc
{
    return new String;
}

/*
    Returns a new string
*/
+ (id)string
{
    return [[self alloc] init];
}

/*
    Returns a <objj>CPString</objj> containing the specified hash.
    @param aHash the hash to represent as a string
*/
+ (id)stringWithHash:(unsigned)aHash
{
    var zeros = "000000",
        digits = aHash.toString(16);
    
    return zeros.substring(0, zeros.length - digits.length) + digits;
}

/*
    Returns a copy of the specified string.
    @param aString a non-<code>nil</code> string to copy
    @throws CPInvalidArgumentException if <code>aString</code> is <code>nil</code>
    @return the new <objj>CPString</objj>
*/
+ (id)stringWithString:(CPString)aString
{
    if (!aString)
        [CPException raise:CPInvalidArgumentException
                    reason:"stringWithString: the string can't be 'nil'"];

    return [[self alloc] initWithString:aString];
}

/*
    Initializes the string with data from the specified string.
    @param aString the string to copy data from
    @return the initialized <objj>CPString</objj>
*/
- (id)initWithString:(CPString)aString
{
    return aString + "";
}

/*
    Returns a description of this <objj>CPString</objj> object.
*/
- (CPString)description
{
    return "<" + self.isa.name + " 0x" + [CPString stringWithHash:[self hash]] + " \"" + self + "\">";
}

/*
    Returns the number of UTF-8 characters in the string.
*/
- (int)length
{
    return length;
}

/*
    Returns the character at the specified index.
    @param anIndex the index of the desired character
*/
- (CPString)characterAtIndex:(unsigned)anIndex
{
    return charAt(anIndex);
}

// Combining strings
/*
    Creates a new <objj>CPString</objj> from the concatenation of the receiver and the specified string.
    @param aString the string to append to the receiver
    @return the new string
*/
- (CPString)stringByAppendingString:(CPString)aString
{
    return self + aString;
}

/*
    Returns a new string formed by padding characters or removing them.
    If the padding length is shorter than the receiver's length, the
    new string will be trimmed down to the padding length size.
    If the padding length is longer than the receiver's length, then the
    new string is repeatedly padded with the characters from the
    specified string starting at the specified index.
    @param aLength the desired length of the new <objj>CPString</objj>
    @param aString the padding string to use (if necessary)
    @param anIndex the index of the padding string to start from (if necessary to use)
    @return the new padded string
*/
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

/*
    Tokenizes the receiver string using the specified
    delimiter. For example, if the receiver is:
    <pre>"arash.francisco.ross.tom"</pre>
    and the delimiter is:
    <pre>"."</pre>
    the returned array would contain:
    <pre>["arash", "francisco", "ross", "tom"]</pre>
    @param the delimiter
    @return the array of tokens
*/
- (CPArray)componentsSeparatedByString:(CPString)aString
{
    return split(aString);
}

/*
    Returns a substring starting from the specified index to the end of the receiver.
    @param anIndex the starting string (inclusive)
    @return the substring
*/
- (CPString)substringFromIndex:(unsigned)anIndex
{
    return substr(anIndex);
}

/*
    Returns a substring starting from the specified range <code>location</code> to the range <code>length</code>.
    @param the range of the substring
    @return the substring
*/
- (CPString)substringWithRange:(CPRange)aRange
{
    return substr(aRange.location, aRange.length);
}

/*
    Creates a substring from the beginning of the receiver to the specified index.
    @param anIndex the last index of the receiver to use for the substring (inclusive)
    @return the substring
*/
- (CPString)substringToIndex:(unsigned)anIndex
{
    return substring(0, anIndex);
}

// Finding characters and substrings
/*
    Finds the range of characters in the receiver where the specified string exists. If the string
    does not exist in the receiver, the range <code>length</code> will be 0.
    @param aString the string to search for in the receiver
    @return the range of charactrs in the receiver
*/
- (CPRange)rangeOfString:(CPString)aString
{
    var location = indexOf(aString);
    
    return CPMakeRange(location, location == CPNotFound ? 0 : aString.length);
}

/*
    Finds the range of characters in the receiver
    where the specified string exists. The search
    is subject to the options specified in the
    specified mask which can be a combination of:
<pre>
CPCaseInsensitiveSearch
CPLiteralSearch
CPBackwardsSearch
CPAnchoredSearch
CPNumericSearch
</pre>
    @param aString the string to search for
    @param aMask the options to use in the search
    @return the range of characters in the receiver. If the string was not found,
    the <code>length</code> of the range will be 0.
*/
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
/*
    Compares the receiver to the specified string.
    @param aString the string with which to compare
    @return the result of the comparison
*/
- (CPComparisonResult)caseInsensitiveCompare:(CPString)aString
{
    return [self compare:aString options:CPCaseInsensitiveSearch]
}

/*
    Compares the receiver to the specified string, using options.
    @param aString the string with which to compare
    @param aMask the options to use for the comparison
    @return the result of the comparison
*/
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

/*
    Returns <code>YES</code> if the receiver starts
    with the specified string. If <code>aString</code>
    is empty, the method will return <code>NO</code>.
*/
- (BOOL)hasPrefix:(CPString)aString
{
    return aString && aString != "" && indexOf(aString) == 0;
}

/*
    Returns <code>NO</code> if the receiver ends
    with the specified string. If <code>aString</code>
    is empty, the method will return <code>NO</code>.
*/
- (BOOL)hasSuffix:(CPString)aString
{
    return aString && aString != "" && lastIndexOf(aString) == (length - aString.length);
}

/*
    Returns <code>YES</code> if the specified string contains the same characters as the receiver.
*/
- (BOOL)isEqualToString:(CPString)aString
{
    return self == aString;
}

/*
    Returns a hash of the string instance.
*/
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

/*
    Returns a copy of the receiver with all the first letters of words capitalized.
*/
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

/*
    Returns a copy of the string with all its characters made lower case.
*/
- (CPString)lowercaseString
{
    return toLowerCase();
}

/*
    Returns a copy of the string with all its characters made upper case.
*/
- (CPString)uppercaseString
{
    return toUpperCase();
}

/*
    Returns the text as a floating point value.
*/
- (double)doubleValue
{
    return eval(self);
}

/*
    Returns the text as a float point value.
*/
- (float)floatValue
{
    return eval(self);
}

/*
    Returns the text as an integer
*/
- (int)intValue
{
    return parseInt(self);
}

/*
    Returns an the path components of this string. This
    method assumes that the string's contents is a '/'
    separated file system path.
*/
- (CPArray)pathComponents
{
    return split('/');
}

/*
    Returns the extension of the file denoted by this string.
    The '.' is not a part of the extension. This method assumes
    that the string's contents is the path to a file or just a filename.
*/
- (CPString)pathExtension
{
    return substr(lastIndexOf('.')+1);
}

- (CPString)lastPathComponent
{
    var components = [self pathComponents];
    return components[components.length -1];
}

/*
    Until this is corrected
    @ignore
*/
- (CPString)stringByDeletingLastPathComponent
{
    // FIMXE: this is wrong: a/a/ returns a/a/.
    return substr(0, lastIndexOf('/')+1);  
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
