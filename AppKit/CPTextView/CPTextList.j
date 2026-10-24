/*
 *  CPTextList.j
 *  AppKit
 *
 *  Created by David Richardson on 24/10/2026.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPAttributedString.j>

@import "CPParagraphStyle.j"

/*
    CPTextListOptions
*/
CPTextListPrependEnclosingMarker = 1 << 0;

/*
    CPTextListMarkerFormat
*/
CPTextListMarkerBox                     = @"{box}";
CPTextListMarkerCheck                   = @"{check}";
CPTextListMarkerCircle                  = @"{circle}";
CPTextListMarkerDiamond                 = @"{diamond}";
CPTextListMarkerDisc                    = @"{disc}";
CPTextListMarkerHyphen                  = @"{hyphen}";
CPTextListMarkerSquare                  = @"{square}";
CPTextListMarkerLowercaseHexadecimal    = @"{lower-hexadecimal}";
CPTextListMarkerUppercaseHexadecimal    = @"{upper-hexadecimal}";
CPTextListMarkerOctal                   = @"{octal}";
CPTextListMarkerLowercaseAlpha          = @"{lower-alpha}";
CPTextListMarkerUppercaseAlpha          = @"{upper-alpha}";
CPTextListMarkerLowercaseLatin          = @"{lower-latin}";
CPTextListMarkerUppercaseLatin          = @"{upper-latin}";
CPTextListMarkerLowercaseRoman          = @"{lower-roman}";
CPTextListMarkerUppercaseRoman          = @"{upper-roman}";
CPTextListMarkerDecimal                 = @"{decimal}";

/*
    The characters that the unordered marker formats stand for.
*/
var CPTextListBulletCharacters = {
        "box":      "□",
        "check":    "✓",
        "circle":   "◦",
        "diamond":  "◆",
        "disc":     "•",
        "hyphen":   "⁃",
        "square":   "▪"
    },
    CPTextListPlaceholderPattern = /\{([a-z-]+)\}/;

/*
    Returns anItemNumber as a letter sequence: 1 is "a", 26 is "z", 27 is "aa".
*/
var _CPTextListAlphaString = function(anItemNumber)
{
    var result = "";

    while (anItemNumber > 0)
    {
        anItemNumber--;
        result = String.fromCharCode(97 + anItemNumber % 26) + result;
        anItemNumber = Math.floor(anItemNumber / 26);
    }

    return result;
};

/*
    Returns anItemNumber as a lowercase Roman numeral.
*/
var _CPTextListRomanString = function(anItemNumber)
{
    var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1],
        numerals = ["m", "cm", "d", "cd", "c", "xc", "l", "xl", "x", "ix", "v", "iv", "i"],
        result = "";

    for (var i = 0; i < values.length; i++)
    {
        while (anItemNumber >= values[i])
        {
            result += numerals[i];
            anItemNumber -= values[i];
        }
    }

    return result;
};

/*!
    @ingroup appkit
    @class CPTextList

    A CPTextList describes one list in rich text: the format of its markers, its options and the
    number of its first item. A paragraph belongs to the lists in its paragraph style's
    \c textLists, outermost first. As in Cocoa, the markers are ordinary text at the start of
    each item: a tab, the marker and another tab, placed by the paragraph style's indents and
    tab stops. A list is identified by the object itself, so the paragraphs of one list share
    the same CPTextList.
*/
@implementation CPTextList : CPObject
{
    CPString    _markerFormat;
    unsigned    _listOptions;
    int         _startingItemNumber;
}

/*!
    Initialises a list.
    @param aFormat the marker format: one of the CPTextListMarker constants, optionally with
    text around it, such as \c @"({decimal})"
    @param aMask the list options, such as CPTextListPrependEnclosingMarker
*/
- (id)initWithMarkerFormat:(CPString)aFormat options:(unsigned)aMask
{
    return [self initWithMarkerFormat:aFormat options:aMask startingItemNumber:1];
}

/*!
    Initialises a list whose first item has the number anItemNumber.
*/
- (id)initWithMarkerFormat:(CPString)aFormat options:(unsigned)aMask startingItemNumber:(int)anItemNumber
{
    if (self = [super init])
    {
        _markerFormat = aFormat || CPTextListMarkerDisc;
        _listOptions = aMask;
        _startingItemNumber = anItemNumber;
    }

    return self;
}

/*!
    Returns the marker format.
*/
- (CPString)markerFormat
{
    return _markerFormat;
}

/*!
    Returns the list options.
*/
- (unsigned)listOptions
{
    return _listOptions;
}

/*!
    Returns the number of the list's first item. The default is 1.
*/
- (int)startingItemNumber
{
    return _startingItemNumber;
}

/*!
    Sets the number of the list's first item.
*/
- (void)setStartingItemNumber:(int)anItemNumber
{
    _startingItemNumber = anItemNumber;
}

/*!
    Returns \c YES if the markers are numbers or letters, and \c NO if they are bullets.
*/
- (BOOL)isOrdered
{
    var match = _markerFormat.match(CPTextListPlaceholderPattern);

    return !!match && !CPTextListBulletCharacters.hasOwnProperty(match[1]);
}

/*!
    Returns the marker for the item with the number anItemNumber, without the tabs around it.
    The marker format's placeholder is replaced by the bullet or the formatted number, and the
    text around the placeholder is kept.
*/
- (CPString)markerForItemNumber:(int)anItemNumber
{
    var match = _markerFormat.match(CPTextListPlaceholderPattern);

    if (!match)
        return _markerFormat;

    var name = match[1],
        marker;

    if (CPTextListBulletCharacters.hasOwnProperty(name))
        marker = CPTextListBulletCharacters[name];
    else
    {
        switch (name)
        {
            case "lower-hexadecimal":
                marker = anItemNumber.toString(16);
                break;

            case "upper-hexadecimal":
                marker = anItemNumber.toString(16).toUpperCase();
                break;

            case "octal":
                marker = anItemNumber.toString(8);
                break;

            case "lower-alpha":
            case "lower-latin":
                marker = anItemNumber > 0 ? _CPTextListAlphaString(anItemNumber) : String(anItemNumber);
                break;

            case "upper-alpha":
            case "upper-latin":
                marker = anItemNumber > 0 ? _CPTextListAlphaString(anItemNumber).toUpperCase() : String(anItemNumber);
                break;

            case "lower-roman":
                marker = anItemNumber > 0 ? _CPTextListRomanString(anItemNumber) : String(anItemNumber);
                break;

            case "upper-roman":
                marker = anItemNumber > 0 ? _CPTextListRomanString(anItemNumber).toUpperCase() : String(anItemNumber);
                break;

            default:
                marker = String(anItemNumber);
        }
    }

    return _markerFormat.replace(CPTextListPlaceholderPattern, marker);
}

- (CPString)description
{
    return [super description] + " markerFormat=" + _markerFormat + " startingItemNumber=" + _startingItemNumber;
}

@end

var CPTextListMarkerFormatKey       = @"CPTextListMarkerFormat",
    CPTextListOptionsKey            = @"CPTextListOptions",
    CPTextListStartingItemNumberKey = @"CPTextListStartingItemNumber";

@implementation CPTextList (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _markerFormat = [aCoder decodeObjectForKey:CPTextListMarkerFormatKey] || CPTextListMarkerDisc;
        _listOptions = [aCoder decodeIntForKey:CPTextListOptionsKey];
        _startingItemNumber = [aCoder containsValueForKey:CPTextListStartingItemNumberKey] ? [aCoder decodeIntForKey:CPTextListStartingItemNumberKey] : 1;
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_markerFormat forKey:CPTextListMarkerFormatKey];
    [aCoder encodeInt:_listOptions forKey:CPTextListOptionsKey];
    [aCoder encodeInt:_startingItemNumber forKey:CPTextListStartingItemNumberKey];
}

@end

/*
    Returns YES if the character code separates paragraphs.
*/
var _CPTextListIsParagraphSeparator = function(aCharCode)
{
    return aCharCode === 10 || aCharCode === 13 || aCharCode === 0x2029;
};

@implementation CPAttributedString (CPTextListAdditions)

/* @ignore
    Returns the range of the paragraph containing anIndex, including its paragraph separator.
*/
- (CPRange)_paragraphRangeForIndex:(unsigned)anIndex
{
    var string = [self string],
        length = string.length,
        start = MIN(anIndex, length),
        end = start;

    while (start > 0 && !_CPTextListIsParagraphSeparator(string.charCodeAt(start - 1)))
        start--;

    while (end < length && !_CPTextListIsParagraphSeparator(string.charCodeAt(end)))
        end++;

    if (end < length)
        end++;

    return CPMakeRange(start, end - start);
}

/* @ignore
    Returns the text lists of the paragraph that starts at aParagraphStart, outermost first.
*/
- (CPArray)_textListsOfParagraphAtIndex:(unsigned)aParagraphStart
{
    if (aParagraphStart >= [self length])
        return [];

    var paragraphStyle = [self attribute:CPParagraphStyleAttributeName atIndex:aParagraphStart effectiveRange:nil];

    return [paragraphStyle textLists] || [];
}

/*!
    Returns the range of the paragraphs that belong to aList, around anIndex. The paragraphs
    are contiguous: the range ends at the first paragraph on either side that does not belong
    to the list, at any level. Returns a range with the location CPNotFound if the paragraph
    at anIndex does not belong to aList.
*/
- (CPRange)rangeOfTextList:(CPTextList)aList atIndex:(unsigned)anIndex
{
    var paragraphRange = [self _paragraphRangeForIndex:anIndex];

    if (![[self _textListsOfParagraphAtIndex:paragraphRange.location] containsObjectIdenticalTo:aList])
        return CPMakeRange(CPNotFound, 0);

    var start = paragraphRange.location,
        end = CPMaxRange(paragraphRange),
        length = [self length];

    while (start > 0)
    {
        var previousRange = [self _paragraphRangeForIndex:start - 1];

        if (![[self _textListsOfParagraphAtIndex:previousRange.location] containsObjectIdenticalTo:aList])
            break;

        start = previousRange.location;
    }

    while (end < length)
    {
        var nextRange = [self _paragraphRangeForIndex:end];

        if (![[self _textListsOfParagraphAtIndex:nextRange.location] containsObjectIdenticalTo:aList])
            break;

        end = CPMaxRange(nextRange);
    }

    return CPMakeRange(start, end - start);
}

/*!
    Returns the number of the item of aList at anIndex. The items of a list are the paragraphs
    whose innermost list it is; paragraphs of lists nested in it do not count. For a paragraph
    of a nested list, the result is the number of the enclosing item. Returns 0 if the
    paragraph at anIndex does not belong to aList.
*/
- (int)itemNumberInTextList:(CPTextList)aList atIndex:(unsigned)anIndex
{
    var listRange = [self rangeOfTextList:aList atIndex:anIndex];

    if (listRange.location === CPNotFound)
        return 0;

    var target = [self _paragraphRangeForIndex:anIndex].location,
        itemNumber = [aList startingItemNumber] - 1,
        location = listRange.location;

    while (location <= target)
    {
        var paragraphRange = [self _paragraphRangeForIndex:location];

        if ([[self _textListsOfParagraphAtIndex:location] lastObject] === aList)
            itemNumber++;

        if (!paragraphRange.length)
            break;

        location = CPMaxRange(paragraphRange);
    }

    return MAX(itemNumber, [aList startingItemNumber]);
}

@end
