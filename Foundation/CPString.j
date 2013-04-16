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

@import "CPException.j"
@import "CPObject.j"
@import "CPObjJRuntime.j"
@import "CPRange.j"
@import "CPSortDescriptor.j"
@import "CPURL.j"
@import "CPValue.j"

@class CPException
@class CPURL

@global CPInvalidArgumentException
@global CPRangeException

/*!
    A case insensitive search
    @global
    @class CPString
*/
CPCaseInsensitiveSearch = 1;
/*!
    Exact character match
    @global
    @class CPString
*/
CPLiteralSearch         = 2;
/*!
    Start searching from the end of the string
    @global
    @class CPString
*/
CPBackwardsSearch       = 4;
/*!
    @global
    @class CPString
*/
CPAnchoredSearch        = 8;
/*!
    Numbers in the string are compared as numbers instead of strings
    @global
    @class CPString
*/
CPNumericSearch         = 64;
/*!
    Search ignores diacritic marks.
    @global
    @class CPString
*/
CPDiacriticInsensitiveSearch = 128;

var CPStringUIDs = new CFMutableDictionary(),

    CPStringRegexSpecialCharacters = [
      '/', '.', '*', '+', '?', '|', '$', '^',
      '(', ')', '[', ']', '{', '}', '\\'
    ],
    CPStringRegexEscapeExpression = new RegExp("(\\" + CPStringRegexSpecialCharacters.join("|\\") + ")", 'g'),
    CPStringRegexTrimWhitespace = new RegExp("(^\\s+|\\s+$)", 'g');

/*!
    @class CPString
    @ingroup foundation
    @brief An immutable string (collection of characters).

    CPString is an object that allows management of strings. Because CPString is
    based on the JavaScript \c String object, CPStrings are immutable, although the
    class does have methods that create new CPStrings generated from modifications to the
    receiving instance.

    A handy feature of CPString instances is that they can be used wherever a JavaScript is
    required, and vice versa.
*/
@implementation CPString : CPObject

/*
    @ignore
*/
+ (id)alloc
{
    if ([self class] !== CPString)
       return [super alloc];

    return new String;
}

/*!
    Returns a new string
*/
+ (id)string
{
    return [[self alloc] init];
}

/*!
    Returns a CPString containing the specified hash.
    @param aHash the hash to represent as a string
*/
+ (id)stringWithHash:(unsigned)aHash
{
    var hashString = parseInt(aHash, 10).toString(16);
    return "000000".substring(0, MAX(6 - hashString.length, 0)) + hashString;
}

/*!
    Returns a copy of the specified string.
    @param aString a non-\c nil string to copy
    @throws CPInvalidArgumentException if \c aString is \c nil
    @return the new CPString
*/
+ (id)stringWithString:(CPString)aString
{
    if (!aString)
        [CPException raise:CPInvalidArgumentException
                    reason:"stringWithString: the string can't be 'nil'"];

    return [[self alloc] initWithString:aString];
}

/*!
    Initializes the string with data from the specified string.
    @param aString the string to copy data from
    @return the initialized CPString
*/
- (id)initWithString:(CPString)aString
{
    if ([self class] === CPString)
        return String(aString);

    var result = new String(aString);

    result.isa = [self class];

    return result;
}

/*!
    Initializes a string using C printf-style formatting. First argument should be a constant format string, like ' "float val = %f" ', remaining arguments should be the variables to print the values of, comma-separated.
    @param format the format to be used, printf-style
    @return the initialized CPString
*/
- (id)initWithFormat:(CPString)format, ...
{
    if (!format)
        [CPException raise:CPInvalidArgumentException
                    reason:"initWithFormat: the format can't be 'nil'"];

    self = ObjectiveJ.sprintf.apply(this, Array.prototype.slice.call(arguments, 2));
    return self;
}

/*!
    Creates a new string using C printf-style formatting. First argument should be a constant format string,
    like ' "float val = %f" ', remaining arguments should be the variables to print the values of, comma-separated.
    @param format the format to be used, printf-style
    @return the initialized CPString
*/
+ (id)stringWithFormat:(CPString)format, ...
{
    if (!format)
        [CPException raise:CPInvalidArgumentException
                    reason:"initWithFormat: the format can't be 'nil'"];

    return ObjectiveJ.sprintf.apply(this, Array.prototype.slice.call(arguments, 2));
}

/*!
    Returns a description of this CPString object.
*/
- (CPString)description
{
    return self;
}

/*!
    Returns the number of UTF-8 characters in the string.
*/
- (int)length
{
    return self.length;
}

/*!
    Returns the character at the specified index.
    @param anIndex the index of the desired character
*/
- (CPString)characterAtIndex:(unsigned)anIndex
{
    return self.charAt(anIndex);
}

// Combining strings

/*!
    Returns a string made by appending to the receiver a string constructed from a given format
    string and the following arguments
    @param format the format string in printf-style.
    @return the initialized CPString
*/
- (CPString)stringByAppendingFormat:(CPString)format, ...
{
    if (!format)
        [CPException raise:CPInvalidArgumentException reason:"initWithFormat: the format can't be 'nil'"];

    return self + ObjectiveJ.sprintf.apply(this, Array.prototype.slice.call(arguments, 2));
}

/*!
    Creates a new CPString from the concatenation of the receiver and the specified string.
    @param aString the string to append to the receiver
    @return the new string
*/
- (CPString)stringByAppendingString:(CPString)aString
{
    return self + aString;
}

/*!
    Returns a new string formed by padding characters or removing them.
    If the padding length is shorter than the receiver's length, the
    new string will be trimmed down to the padding length size.
    If the padding length is longer than the receiver's length, then the
    new string is repeatedly padded with the characters from the
    specified string starting at the specified index.
    @param aLength the desired length of the new CPString
    @param aString the padding string to use (if necessary)
    @param anIndex the index of the padding string to start from (if necessary to use)
    @return the new padded string
*/
- (CPString)stringByPaddingToLength:(unsigned)aLength withString:(CPString)aString startingAtIndex:(unsigned)anIndex
{
    if (self.length == aLength)
        return self;

    if (aLength < self.length)
        return self.substr(0, aLength);

    var string = self,
        substring = aString.substring(anIndex),
        difference = aLength - self.length;

    while ((difference -= substring.length) >= 0)
        string += substring;

    if (-difference < substring.length)
        string += substring.substring(0, -difference);

    return string;
}

//Dividing Strings
/*!
    Tokenizes the receiver string using the specified
    delimiter. For example, if the receiver is:
    \c "arash.francisco.ross.tom"
    and the delimiter is:
    \c "."
    the returned array would contain:
    <pre> ["arash", "francisco", "ross", "tom"] </pre>
    @param the delimiter
    @return the array of tokens
*/
- (CPArray)componentsSeparatedByString:(CPString)aString
{
    return self.split(aString);
}

/*!
    Returns a substring starting from the specified index to the end of the receiver.
    @param anIndex the starting string (inclusive)
    @return the substring
*/
- (CPString)substringFromIndex:(unsigned)anIndex
{
    return self.substr(anIndex);
}

/*!
    Returns a substring starting from the specified range \c location to the range \c length.
    @param the range of the substring
    @return the substring
*/
- (CPString)substringWithRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:"aRange out of bounds"];

    return self.substr(aRange.location, aRange.length);
}

/*!
    Creates a substring of characters from the receiver, starting at the beginning and up to
    the given index.

    @param anIndex the index of the receiver where the substring should end (non inclusive)
    @return the substring
*/
- (CPString)substringToIndex:(unsigned)anIndex
{
    if (anIndex > self.length)
        [CPException raise:CPRangeException reason:"index out of bounds"];

    return self.substring(0, anIndex);
}

// Finding characters and substrings

/*!
    Finds the range of characters in the receiver where the specified string exists. If the string
    does not exist in the receiver, the range \c length will be 0.
    @param aString the string to search for in the receiver
    @return the range of characters in the receiver
*/
- (CPRange)rangeOfString:(CPString)aString
{
   return [self rangeOfString:aString options:0];
}

/*!
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
    the \c length of the range will be 0.
*/
- (CPRange)rangeOfString:(CPString)aString options:(int)aMask
{
    return [self rangeOfString:aString options:aMask range:nil];
}

/*!
    Finds the range of characters in the receiver where the specified string
    exists in the given range of the receiver.The search is subject to the
    options specified in the specified mask which can be a combination of:
    <pre>
    CPCaseInsensitiveSearch
    CPLiteralSearch
    CPBackwardsSearch
    CPAnchoredSearch
    CPNumericSearch
    </pre>
    @param aString the string to search for
    @param aMask the options to use in the search
    @param aRange the range of the receiver in which to search for
    @return the range of characters in the receiver. The range is relative to
        the start of the full string and not the passed-in range. If the
        string was not found, or if it was @"", the range will be
        {CPNotFound, 0}.
*/
- (CPRange)rangeOfString:(CPString)aString options:(int)aMask range:(CPrange)aRange
{
    // Searching for @"" always returns CPNotFound.
    if (!aString)
        return CPMakeRange(CPNotFound, 0);

    var string = (aRange == nil) ? self : [self substringWithRange:aRange],
        location = CPNotFound;

    if (aMask & CPCaseInsensitiveSearch)
    {
        string = string.toLowerCase();
        aString = aString.toLowerCase();
    }

    if (aMask & CPBackwardsSearch)
    {
        location = string.lastIndexOf(aString);
        if (aMask & CPAnchoredSearch && location + aString.length != string.length)
            location = CPNotFound;
    }
    else if (aMask & CPAnchoredSearch)
        location = string.substr(0, aString.length).indexOf(aString) != CPNotFound ? 0 : CPNotFound;
    else
        location = string.indexOf(aString);

    if (location == CPNotFound)
        return CPMakeRange(CPNotFound, 0);

    return CPMakeRange(location + (aRange ? aRange.location : 0), aString.length);
}

//Replacing Substrings

- (CPString)stringByEscapingRegexControlCharacters
{
    return self.replace(CPStringRegexEscapeExpression, "\\$1");
}

/*!
    Returns a new string in which all occurrences of a target string in the receiver are replaced by
    another given string.
    @param target The string to replace.
    @param replacement the string with which to replace the \c target
*/

- (CPString)stringByReplacingOccurrencesOfString:(CPString)target withString:(CPString)replacement
{
    return self.replace(new RegExp([target stringByEscapingRegexControlCharacters], "g"), replacement);
}

/*
    Returns a new string in which all occurrences of a target string in a specified range of the receiver
    are replaced by another given string.
    @param target The string to replace
    @param replacement the string with which to replace the \c target.
    @param options A mask of options to use when comparing \c target with the receiver. Pass 0 to specify no options
    @param searchRange The range in the receiver in which to search for \c target.
*/

- (CPString)stringByReplacingOccurrencesOfString:(CPString)target withString:(CPString)replacement options:(int)options range:(CPRange)searchRange
{
    var start = self.substring(0, searchRange.location),
        stringSegmentToSearch = self.substr(searchRange.location, searchRange.length),
        end = self.substring(searchRange.location + searchRange.length, self.length),
        target = [target stringByEscapingRegexControlCharacters],
        regExp;

    if (options & CPCaseInsensitiveSearch)
        regExp = new RegExp(target, "gi");
    else
        regExp = new RegExp(target, "g");

    return start + '' + stringSegmentToSearch.replace(regExp, replacement) + '' + end;
}

/*
   Returns a new string in which the characters in a specified range of the receiver
   are replaced by a given string.
   @param range A range of characters in the receiver.
   @param replacement The string with which to replace the characters in \c range.
*/

- (CPString)stringByReplacingCharactersInRange:(CPRange)range withString:(CPString)replacement
{
    return '' + self.substring(0, range.location) + replacement + self.substring(range.location + range.length, self.length);
}

/*!
    Returns a new string with leading and trailing whitespace trimmed
*/
- (CPString)stringByTrimmingWhitespace
{
    return self.replace(CPStringRegexTrimWhitespace, "");
}

// Identifying and comparing strings

/*!
    Compares the receiver to the specified string.
    @param aString the string with which to compare
    @return the result of the comparison
*/
- (CPComparisonResult)compare:(CPString)aString
{
    return [self compare:aString options:nil];
}

/*
    Compares the receiver to the specified string.
    @param aString the string with which to compare
    @return the result of the comparison
*/
- (CPComparisonResult)caseInsensitiveCompare:(CPString)aString
{
    return [self compare:aString options:CPCaseInsensitiveSearch];
}

/*!
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

    if (aMask & CPDiacriticInsensitiveSearch)
    {
        lhs = lhs.stripDiacritics();
        rhs = rhs.stripDiacritics();
    }

    if (lhs < rhs)
        return CPOrderedAscending;

    if (lhs > rhs)
        return CPOrderedDescending;

    return CPOrderedSame;
}

/*!
    Compares the receiver to the specified string, using options in range.
    @param aString the string with which to compare the range of the receiver specified by range.
    @param aMask the options to use for the comparison
    @param range the range of the receiver over which to perform the comparison. The range must not exceed the bounds of the receiver.
    @return the result of the comparison
*/
- (CPComparisonResult)compare:(CPString)aString options:(int)aMask range:(CPRange)range
{
    var lhs = [self substringWithRange:range],
        rhs = aString;

    return [lhs compare:rhs options:aMask];
}

/*!
    Returns \c YES if the receiver starts
    with the specified string. If \c aString
    is empty, the method will return \c NO.
*/
- (BOOL)hasPrefix:(CPString)aString
{
    return aString && aString != "" && self.indexOf(aString) == 0;
}

/*!
    Returns \c YES if the receiver ends
    with the specified string. If \c aString
    is empty, the method will return \c NO.
*/
- (BOOL)hasSuffix:(CPString)aString
{
    return aString && aString != "" && self.length >= aString.length && self.lastIndexOf(aString) == (self.length - aString.length);
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (!anObject || ![anObject isKindOfClass:[CPString class]])
        return NO;

    return [self isEqualToString:anObject];
}


/*!
    Returns \c YES if the specified string contains the same characters as the receiver.
*/
- (BOOL)isEqualToString:(CPString)aString
{
    return self == String(aString);
}

/*!
    Returns a hash of the string instance.
*/
- (unsigned)UID
{
    var UID = CPStringUIDs.valueForKey(self);

    if (!UID)
    {
        UID = objj_generateObjectUID();
        CPStringUIDs.setValueForKey(self, UID);
    }

    return UID + "";
}

/*!
    Returns a string containing characters the receiver and a given string have in common, starting from
    the beginning of each up to the first characters that aren't equivalent.
    @param aString the string with which to compare the receiver
*/
- (CPString)commonPrefixWithString:(CPString)aString
{
    return [self commonPrefixWithString: aString options: 0];
}

/*!
    Returns a string containing characters the receiver and a given string have in common, starting from
    the beginning of each up to the first characters that aren't equivalent.
    @param aString the string with which to compare the receiver
    @param aMask options for comparison
*/
- (CPString)commonPrefixWithString:(CPString)aString options:(int)aMask
{
    var len = 0, // length of common prefix
        lhs = self,
        rhs = aString,
        min = MIN([lhs length], [rhs length]);

    if (aMask & CPCaseInsensitiveSearch)
    {
        lhs = [lhs lowercaseString];
        rhs = [rhs lowercaseString];
    }

    for (; len < min; len++)
    {
        if ([lhs characterAtIndex:len] !== [rhs characterAtIndex:len])
            break;
    }

    return [self substringToIndex:len];
}

/*!
    Returns a copy of the receiver with all the first letters of words capitalized.
*/
- (CPString)capitalizedString
{
    var parts = self.split(/\b/g), // split on word boundaries
        i = 0,
        count = parts.length;

    for (; i < count; i++)
    {
        if (i == 0 || (/\s$/).test(parts[i - 1])) // only capitalize if previous token was whitespace
            parts[i] = parts[i].substring(0, 1).toUpperCase() + parts[i].substring(1).toLowerCase();
        else
            parts[i] = parts[i].toLowerCase();
    }
    return parts.join("");
}

/*!
    Returns a copy of the string with all its characters made lower case.
*/
- (CPString)lowercaseString
{
    return self.toLowerCase();
}

/*!
    Returns a copy of the string with all its characters made upper case.
*/
- (CPString)uppercaseString
{
    return self.toUpperCase();
}

/*!
    Returns the text as a floating point value.
*/
- (double)doubleValue
{
    return parseFloat(self, 10);
}
/*!
    Returns \c YES on encountering one of "Y", "y", "T", "t", or
    a digit 1-9. Returns \c NO otherwise. This method skips the initial
    whitespace characters, +,- followed by Zeroes.
*/
- (BOOL)boolValue
{
    var replaceRegExp = new RegExp("^\\s*[\\+,\\-]?0*");
    return RegExp("^[Y,y,t,T,1-9]").test(self.replace(replaceRegExp, ''));
}

/*!
    Returns the text as a float point value.
*/
- (float)floatValue
{
    return parseFloat(self, 10);
}

/*!
    Returns the text as an integer
*/
- (int)intValue
{
    return parseInt(self, 10);
}

/*!
    Returns an the path components of this string. This
    method assumes that the string's content is a '/'
    separated file system path.
    Multiple '/' separators between components are truncated to a single one.
*/
- (CPArray)pathComponents
{
    if (self.length === 0)
        return [""];

    if (self === "/")
        return ["/"];

    var result = self.split('/');

    if (result[0] === "")
        result[0] = "/";

    var index = result.length - 1;

    if (index > 0)
    {
        if (result[index] === "")
            result[index] = "/";

        while (index--)
        {
            while (result[index] === "")
                result.splice(index--, 1);
        }
    }

    return result;
}

/*!
    Returns a string built from the strings in a given array by
    concatenating them with a path separator between each pair.
    This method assumes that the string's content is a '/'
    separated file system path.
    Multiple '/' separators between components are truncated to a single one.
*/
+ (CPString)pathWithComponents:(CPArray)components
{
    var size = components.length,
        result = "",
        i = -1,
        firstRound = true,
        firstIsSlash = false;

    while (++i < size)
    {
        var component = components[i],
            lenMinusOne = component.length - 1;

        if (lenMinusOne >= 0 && (component !== "/" || firstRound))  // Skip "" and "/" (not first time)
        {
            if (lenMinusOne > 0 && component.indexOf("/",lenMinusOne) === lenMinusOne) // Ends with "/"
                component = component.substring(0, lenMinusOne);

            if (firstRound)
            {
                if (component === "/")
                    firstIsSlash = true;
                firstRound = false;
            }
            else if (!firstIsSlash)
                result += "/";
            else
                firstIsSlash = false;

            result += component;
        }
    }
    return result;
}

/*!
    Returns the extension of the file denoted by this string.
    The '.' is not a part of the extension. This method assumes
    that the string's contents is the path to a file or just a filename.
*/
- (CPString)pathExtension
{
    if (self.lastIndexOf('.') === CPNotFound)
        return "";

    return self.substr(self.lastIndexOf('.') + 1);
}

/*!
    Returns the last component of this string.
    This method assumes that the string's content is a '/'
    separated file system path.
*/
- (CPString)lastPathComponent
{
    var components = [self pathComponents],
        lastIndex = components.length - 1,
        lastComponent = components[lastIndex];

    return lastIndex > 0 && lastComponent === "/" ? components[lastIndex - 1] : lastComponent;
}

/*!
    Returns a new string made by appending to the receiver a given string
    This method assumes that the string's content is a '/'
    separated file system path.
    Multiple '/' separators between components are truncated to a single one.
*/
- (CPString)stringByAppendingPathComponent:(CPString)aString
{
    var components = [self pathComponents],
        addComponents = aString && aString !== "/" ? [aString pathComponents] : [];

    return [CPString pathWithComponents:components.concat(addComponents)];
}

/*!
    Returns a new string made by appending to the receiver an extension separator followed by a given extension
    This method assumes that the extension separator is a '.'
    Extension can't include a '/' character, receiver can't be empty or be just a '/'. If so the
    result will be the receiver itself.
    Multiple '/' separators between components are truncated to a single one.
*/
- (CPString)stringByAppendingPathExtension:(CPString)ext
{
    if (ext.indexOf('/') >= 0 || self.length === 0 || self === "/")  // Can't handle these
        return self;

    var components = [self pathComponents],
        last = components.length - 1;

    if (last > 0 && components[last] === "/")
        components.splice(last--, 1);

    components[last] = components[last] + "." + ext;

    return [CPString pathWithComponents:components];
}

/*!
    Deletes the last path component of a string.
    This method assumes that the string's content is a '/'
    separated file system path.
    Multiple '/' separators between components are truncated to a single one.
*/
- (CPString)stringByDeletingLastPathComponent
{
    if (self.length === 0)
        return "";
    else if (self === "/")
        return "/";

    var components = [self pathComponents],
        last = components.length - 1;

    if (components[last] === "/")
        last--;

    components.splice(last, components.length - last);

    return [CPString pathWithComponents:components];
}

/*!
    Deletes the extension of a string.
    This method assumes that the string's content is a '/'
    separated file system path.
    Multiple '/' separators between components are truncated to a single one.
*/
- (CPString)stringByDeletingPathExtension
{
    var extension = [self pathExtension];

    if (extension === "")
        return self;
    else if (self.lastIndexOf('.') < 1)
        return self;

    return self.substr(0, [self length] - (extension.length + 1));
}

- (CPString)stringByStandardizingPath
{
    // FIXME: Expand tildes etc. in CommonJS?
    return [[CPURL URLWithString:self] absoluteString];
}

@end


@implementation CPString (JSON)

/*!
    Returns a string representing the supplied JavaScript object encoded as JSON.
*/
+ (CPString)JSONFromObject:(JSObject)anObject
{
    return JSON.stringify(anObject);
}

/*!
    Returns a JavaScript object decoded from the string's JSON representation.
*/
- (JSObject)objectFromJSON
{
    return JSON.parse(self);
}

@end


@implementation CPString (UUID)

/*!
    Returns a randomly generated Universally Unique Identifier.
*/
+ (CPString)UUID
{
    var g = @"",
        i = 0;

    for (; i < 32; i++)
        g += FLOOR(RAND() * 0xF).toString(0xF);

    return g;
}

@end


var diacritics = [[192,198],[224,230],[231,231],[232,235],[236,239],[242,246],[249,252]], // Basic Latin ; Latin-1 Supplement.
    normalized = [65,97,99,101,105,111,117];

String.prototype.stripDiacritics = function()
{
    var output = "";

    for (var indexSource = 0; indexSource < this.length; indexSource++)
    {
        var code = this.charCodeAt(indexSource);

        for (var i = 0; i < diacritics.length; i++)
        {
            var drange = diacritics[i];

            if (code >= drange[0] && code <= drange[drange.length - 1])
            {
                code = normalized[i];
                break;
            }
        }

        output += String.fromCharCode(code);
    }

    return output;
};

String.prototype.isa = CPString;
