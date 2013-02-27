/*
 * CPAttributedString.j
 * Foundation
 *
 * Created by Ross Boucher.
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

@import "CPArray.j"
@import "CPDictionary.j"
@import "CPException.j"
@import "CPObject.j"
@import "CPRange.j"
@import "CPString.j"

/*!
    @class CPAttributedString
    @ingroup foundation
    @brief A mutable character string with attributes.

    A character string with sets of attributes that apply to single or ranges of
    characters. The attributes are contained within a CPDictionary class.
    Attributes can be any name/value pair. The data type of the value is not
    restricted.
    This class is mutable.

    @note Cocoa developers: in Cappuccino CPAttributedString is mutable. It
    implements functionality from both NSAttributedString and
    NSMutableAttributedString. However, to ease converting of existing
    Objective-C code a CPMutableAttributedString alias to this class exists.
*/
@implementation CPAttributedString : CPObject
{
    CPString    _string;
    CPArray     _rangeEntries;
}

// Creating a CPAttributedString Object
/*!
    Creates an empty attributed string.
    @return a new empty CPAttributedString.
*/
- (id)init
{
    return [self initWithString:@"" attributes:nil];
}

/*!
    Creates a new attributed string from a character string.
    @param aString is the string to initialise from.
    @return a new CPAttributedString containing the string \c aString.
*/
- (id)initWithString:(CPString)aString
{
    return [self initWithString:aString attributes:nil];
}

/*!
    Creates a new attributed string from an existing attributed string.
    @param aString is the attributed string to initialise from.
    @return a new CPAttributedString containing the string \c aString.
*/
- (id)initWithAttributedString:(CPAttributedString)aString
{
    var string = [self initWithString:@"" attributes:nil];

    [string setAttributedString:aString];

    return string;
}

/*!
    Creates a new attributed string from a character string and the specified
    dictionary of attributes.
    @param aString is the attributed string to initialise from.
    @param attributes is a dictionary of string attributes.
    @return a new CPAttributedString containing the string \c aString
    with associated attributes, \c attributes.
*/
- (id)initWithString:(CPString)aString attributes:(CPDictionary)attributes
{
    self = [super init];

    if (self)
    {
        if (!attributes)
            attributes = @{};

        _string = "" + aString;
        _rangeEntries = [makeRangeEntry(CPMakeRange(0, _string.length), attributes)];
    }

    return self;
}

//Retrieving Character Information
/*!
    Returns a string containing the receiver's character data without
    attributes.
    @return a string of type CPString.
*/
- (CPString)string
{
    return _string;
}

/*!
    Returns a string containing the receiver's character data without
    attributes.
    @return a string of type CPString.
*/
- (CPString)mutableString
{
    return [self string];
}

/*!
    Get the length of the string.
    @return an unsigned integer equivalent to the number of characters in the
    string.
*/
- (unsigned)length
{
    return _string.length;
}

// private method
- (unsigned)_indexOfEntryWithIndex:(unsigned)anIndex
{
    if (anIndex < 0 || anIndex > _string.length || anIndex === undefined)
        return CPNotFound;

    // find the range entry that contains anIndex.
    var sortFunction = function(index, entry)
    {
        // index is the character index we're searching for,
        // while range is the actual range entry we're comparing against
        if (CPLocationInRange(index, entry.range))
            return CPOrderedSame;
        else if (CPMaxRange(entry.range) <= index)
            return CPOrderedDescending;
        else
            return CPOrderedAscending;
    };

    return [_rangeEntries indexOfObject:anIndex inSortedRange:nil options:0 usingComparator:sortFunction];
}

//Retrieving Attribute Information
/*!
    Returns a dictionary of attributes for the character at a given index. The
    range in which this character resides in which the attributes are the
    same, can be returned if desired.
    @note there is no guarantee that the range returned is in fact the complete
    range of the particular attributes. To ensure this use
    \c attributesAtIndex:longestEffectiveRange:inRange: instead. Note
    however that it may take significantly longer to execute.
    @param anIndex is an unsigned integer index. It must lie within the bounds
    of the string.
    @param aRange is a reference to a CPRange object
    that is set (upon return) to the range over which the attributes are the
    same as those at index, \c anIndex. If not required pass
    \c nil.
    @return a CPDictionary containing the attributes associated with the
    character at index \c anIndex. Returns an empty dictionary if index
    is out of bounds.
*/
- (CPDictionary)attributesAtIndex:(unsigned)anIndex effectiveRange:(CPRangePointer)aRange
{
    // find the range entry that contains anIndex.
    var entryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (entryIndex === CPNotFound)
        return @{};

    var matchingRange = _rangeEntries[entryIndex];

    if (aRange)
    {
        aRange.location = matchingRange.range.location;
        aRange.length = matchingRange.range.length;
    }

    return matchingRange.attributes;
}

/*!
    Returns a dictionary of all attributes for the character at a given index
    and, by reference, the range over which the attributes apply. This is the
    maximum range both forwards and backwards in the string over which the
    attributes apply, bounded in both directions by the range limit parameter,
    \c rangeLimit.
    @note this method performs a search to find this range which may be
    computationally intensive. Use the \c rangeLimit to limit the
    search space or use \c -attributesAtIndex:effectiveRange: but
    note that it is not guaranteed to return the full range of the current
    character's attributes.
    @param anIndex is the unsigned integer index. It must lie within the bounds
    of the string.
    @param aRange is a reference to a CPRange object that is set (upon return)
    to the range over which the attributes apply.
    @param rangeLimit a range limiting the search for the attributes' applicable
    range.
    @return a CPDictionary containing the attributes associated with the
    character at index \c anIndex. Returns an empty dictionary if index
    is out of bounds.
*/
- (CPDictionary)attributesAtIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (startingEntryIndex === CPNotFound)
        return @{};

    if (!aRange)
        return _rangeEntries[startingEntryIndex].attributes;

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;

        return _rangeEntries[startingEntryIndex].attributes;
    }

    // scan backwards
    var nextRangeIndex = startingEntryIndex - 1,
        currentEntry = _rangeEntries[startingEntryIndex],
        comparisonDict = currentEntry.attributes;

    while (nextRangeIndex >= 0)
    {
        var nextEntry = _rangeEntries[nextRangeIndex];

        if (CPMaxRange(nextEntry.range) > rangeLimit.location && [nextEntry.attributes isEqualToDictionary:comparisonDict])
        {
            currentEntry = nextEntry;
            nextRangeIndex--;
        }
        else
            break;
    }

    aRange.location = MAX(currentEntry.range.location, rangeLimit.location);

    // scan forwards
    currentEntry = _rangeEntries[startingEntryIndex];
    nextRangeIndex = startingEntryIndex + 1;

    while (nextRangeIndex < _rangeEntries.length)
    {
        var nextEntry = _rangeEntries[nextRangeIndex];

        if (nextEntry.range.location < CPMaxRange(rangeLimit) && [nextEntry.attributes isEqualToDictionary:comparisonDict])
        {
            currentEntry = nextEntry;
            nextRangeIndex++;
        }
        else
            break;
    }

    aRange.length = MIN(CPMaxRange(currentEntry.range), CPMaxRange(rangeLimit)) - aRange.location;

    return comparisonDict;
}

/*!
    Returns the specified named attribute for the given character index and, if
    required, the range over which the attribute applies.
    @note there is no guarantee that the range returned is in fact the complete
    range of a particular attribute. To ensure this use
    \c -attribute:atIndex:longestEffectiveRange:inRange: instead but
    note that it may take significantly longer to execute.
    @param attribute the name of the desired attribute.
    @param anIndex is an unsigned integer character index from which to retrieve
    the attribute. It must lie within the bounds of the string.
    @param aRange is a reference to a CPRange object, that is set upon return
    to the range over which the named attribute applies.  If not required pass
    \c nil.
    @return the named attribute or \c nil is the attribute does not
    exist.
*/
- (id)attribute:(CPString)attribute atIndex:(unsigned)index effectiveRange:(CPRangePointer)aRange
{
    if (!attribute)
    {
        if (aRange)
        {
            aRange.location = 0;
            aRange.length = _string.length;
        }

        return nil;
    }

    return [[self attributesAtIndex:index effectiveRange:aRange] valueForKey:attribute];
}

/*!
    Returns the specified named attribute for the given character index and the
    range over which the attribute applies. This is the maximum range both
    forwards and backwards in the string over which the attribute applies,
    bounded in both directions by the range limit parameter,
    \c rangeLimit.
    @note this method performs a search to find this range which may be
    computationally intensive. Use the \c rangeLimit to limit the
    search space or use \c -attribute:atIndex:effectiveRange: but
    note that it is not guaranteed to return the full range of the current
    character's named attribute.
    @param attribute the name of the desired attribute.
    @param anIndex is an unsigned integer character index from which to retrieve
    the attribute. It must lie within the bounds of the string.
    @param aRange  is a reference to a CPRange object, that is set upon return
    to the range over which the named attribute applies.
    @param rangeLimit a range limiting the search for the attribute's applicable
    range.
    @return the named attribute or \c nil is the attribute does not
    exist.
*/
- (id)attribute:(CPString)attribute atIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (startingEntryIndex === CPNotFound || !attribute)
        return nil;

    if (!aRange)
        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;

        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];
    }

    // scan backwards
    var nextRangeIndex = startingEntryIndex - 1,
        currentEntry = _rangeEntries[startingEntryIndex],
        comparisonAttribute = [currentEntry.attributes objectForKey:attribute];

    while (nextRangeIndex >= 0)
    {
        var nextEntry = _rangeEntries[nextRangeIndex];

        if (CPMaxRange(nextEntry.range) > rangeLimit.location && isEqual(comparisonAttribute, [nextEntry.attributes objectForKey:attribute]))
        {
            currentEntry = nextEntry;
            nextRangeIndex--;
        }
        else
            break;
    }

    aRange.location = MAX(currentEntry.range.location, rangeLimit.location);

    // scan forwards
    currentEntry = _rangeEntries[startingEntryIndex];
    nextRangeIndex = startingEntryIndex + 1;

    while (nextRangeIndex < _rangeEntries.length)
    {
        var nextEntry = _rangeEntries[nextRangeIndex];

        if (nextEntry.range.location < CPMaxRange(rangeLimit) && isEqual(comparisonAttribute, [nextEntry.attributes objectForKey:attribute]))
        {
            currentEntry = nextEntry;
            nextRangeIndex++;
        }
        else
            break;
    }

    aRange.length = MIN(CPMaxRange(currentEntry.range), CPMaxRange(rangeLimit)) - aRange.location;

    return comparisonAttribute;
}

//Comparing Attributed Strings
/*!
    Compares the receiver's characters and attributes to the specified
    attributed string, \c aString, and tests for equality.
    @param aString the CPAttributedString to compare.
    @return a boolean indicating equality.
*/
- (BOOL)isEqualToAttributedString:(CPAttributedString)aString
{
    if (!aString)
        return NO;

    if (_string !== [aString string])
        return NO;

    var myRange = CPMakeRange(),
        comparisonRange = CPMakeRange(),
        myAttributes = [self attributesAtIndex:0 effectiveRange:myRange],
        comparisonAttributes = [aString attributesAtIndex:0 effectiveRange:comparisonRange],
        length = _string.length;

    while (CPMaxRange(CPUnionRange(myRange, comparisonRange)) < length)
    {
        if (CPIntersectionRange(myRange, comparisonRange).length > 0 &&
            ![myAttributes isEqualToDictionary:comparisonAttributes])
        {
            return NO;
        }
        else if (CPMaxRange(myRange) < CPMaxRange(comparisonRange))
            myAttributes = [self attributesAtIndex:CPMaxRange(myRange) effectiveRange:myRange];
        else
            comparisonAttributes = [aString attributesAtIndex:CPMaxRange(comparisonRange) effectiveRange:comparisonRange];
    }

    return YES;
}

/*!
    Determine whether the given object is the same as the receiver. If the
    specified object is an attributed string then an attributed string compare
    is performed.
    @param anObject an object to test for equality.
    @return a boolean indicating equality.
*/
- (BOOL)isEqual:(id)anObject
{
    if (anObject === self)
        return YES;

    if ([anObject isKindOfClass:[self class]])
        return [self isEqualToAttributedString:anObject];

    return NO;
}

//Extracting a Substring
/*!
    Extracts a substring from the receiver, both characters and attributes,
    within the range given by \c aRange.
    @param aRange the range of the substring to extract.
    @return a CPAttributedString containing the desired substring.
    @exception CPRangeException if the range lies outside the receiver's bounds.
*/
- (CPAttributedString)attributedSubstringFromRange:(CPRange)aRange
{
    if (!aRange || CPMaxRange(aRange) > _string.length || aRange.location < 0)
        [CPException raise:CPRangeException
                    reason:"tried to get attributedSubstring for an invalid range: "+(aRange?CPStringFromRange(aRange):"nil")];

    var newString = [[CPAttributedString alloc] initWithString:_string.substring(aRange.location, CPMaxRange(aRange))],
        entryIndex = [self _indexOfEntryWithIndex:aRange.location];

    if (entryIndex === CPNotFound)
        _CPRaiseRangeException(self, _cmd, aRange.location, _string.length);

    var currentRangeEntry = _rangeEntries[entryIndex],
        lastIndex = CPMaxRange(aRange);

    newString._rangeEntries = [];

    while (currentRangeEntry && CPMaxRange(currentRangeEntry.range) < lastIndex)
    {
        var newEntry = copyRangeEntry(currentRangeEntry);
        newEntry.range.location -= aRange.location;

        if (newEntry.range.location < 0)
        {
            newEntry.range.length += newEntry.range.location;
            newEntry.range.location = 0;
        }

        newString._rangeEntries.push(newEntry);
        currentRangeEntry = _rangeEntries[++entryIndex];
    }

    if (currentRangeEntry)
    {
        var newRangeEntry = copyRangeEntry(currentRangeEntry);

        newRangeEntry.range.length = CPMaxRange(aRange) - newRangeEntry.range.location;
        newRangeEntry.range.location -= aRange.location;

        if (newRangeEntry.range.location < 0)
        {
            newRangeEntry.range.length += newRangeEntry.range.location;
            newRangeEntry.range.location = 0;
        }

        newString._rangeEntries.push(newRangeEntry);
    }

    return newString;
}

//Changing Characters
/*!
    Replaces the characters in the receiver with those of the specified string
    over the range, \c aRange. If the range has a length of 0 then
    the specified string is inserted at the range location. The new characters
    inherit the attributes of the first character in the range that they
    replace or in the case if a 0 range length, the first character before of
    after the insert (after if the insert is at location 0).
    @note the replacement string need not be the same length as the range
    being replaced. The full \c aString is inserted and thus the
    receiver's length changes to match this
    @param aRange the range of characters to replace.
    @param aString the string to replace the specified characters in the
    receiver.
*/
- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    if (!aString)
        aString = @"";

    var startingIndex = [self _indexOfEntryWithIndex:aRange.location];

    if (startingIndex === CPNotFound)
        _CPRaiseRangeException(self, _cmd, aRange.location, _string.length);

    var startingRangeEntry = _rangeEntries[startingIndex],
        endingIndex = [self _indexOfEntryWithIndex:MAX(CPMaxRange(aRange) - 1, 0)];

    if (endingIndex === CPNotFound)
        _CPRaiseRangeException(self, _cmd, MAX(CPMaxRange(aRange) - 1, 0), _string.length);

    var endingRangeEntry = _rangeEntries[endingIndex],
        additionalLength = aString.length - aRange.length;

    _string = _string.substring(0, aRange.location) + aString + _string.substring(CPMaxRange(aRange));

    if (startingIndex === endingIndex)
        startingRangeEntry.range.length += additionalLength;
    else
    {
        endingRangeEntry.range.length = CPMaxRange(endingRangeEntry.range) - CPMaxRange(aRange);
        endingRangeEntry.range.location = CPMaxRange(aRange);

        startingRangeEntry.range.length = CPMaxRange(aRange) - startingRangeEntry.range.location;

        _rangeEntries.splice(startingIndex, endingIndex - startingIndex);
    }

    endingIndex = startingIndex + 1;

    while (endingIndex < _rangeEntries.length)
        _rangeEntries[endingIndex++].range.location += additionalLength;
}

/*!
    Deletes a range of characters and their associated attributes.
    @param aRange a CPRange indicating the range of characters to delete.
*/
- (void)deleteCharactersInRange:(CPRange)aRange
{
    [self replaceCharactersInRange:aRange withString:nil];
}

//Changing Attributes
/*!
    Sets the attributes of the specified character range.

    @note This process removes the attributes already associated with the
    character range. If you wish to retain the current attributes use
    \c -addAttributes:range:.
    @param aDictionary a CPDictionary of attributes (names and values) to set
    to.
    @param aRange a CPRange indicating the range of characters to set their
    associated attributes to \c aDictionary.
*/
- (void)setAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitOnMaxIndex:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitOnMaxIndex:YES],
        current = startingEntryIndex;

    if (endingEntryIndex === CPNotFound)
        endingEntryIndex = _rangeEntries.length;

    while (current < endingEntryIndex)
        _rangeEntries[current++].attributes = [aDictionary copy];

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];
}

/*!
    Add a collection of attributes to the specified character range.

    @note Attributes currently associated with the characters in the range are
    untouched. To remove all previous attributes when adding use
    \c -setAttributes:range:.
    @param aDictionary a CPDictionary of attributes (names and values) to add.
    @param aRange a CPRange indicating the range of characters to add the
    attributes to.
*/
- (void)addAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitOnMaxIndex:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitOnMaxIndex:YES],
        current = startingEntryIndex;

    if (endingEntryIndex === CPNotFound)
        endingEntryIndex = _rangeEntries.length;

    while (current < endingEntryIndex)
    {
        var keys = [aDictionary allKeys],
            count = [keys count];

        while (count--)
            [_rangeEntries[current].attributes setObject:[aDictionary objectForKey:keys[count]] forKey:keys[count]];

        current++;
    }

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];
}

/*!
    Add an attribute with the given name and value to the specified character
    range.

    @note Attributes currently associated with the characters in the range are
    untouched. To remove all previous attributes when adding use
    \c -setAttributes:range:.
    @param anAttribute a CPString of the attribute name.
    @param aValue a value to assign to the attribute. Can be of any type.
    @param aRange a CPRange indicating the range of characters to add the
    attribute too.
*/
- (void)addAttribute:(CPString)anAttribute value:(id)aValue range:(CPRange)aRange
{
    [self addAttributes:@{ anAttribute: aValue } range:aRange];
}

/*!
    Remove a named attribute from a character range.
    @param anAttribute a CPString specifying the name of the attribute.
    @param aRange a CPRange indicating the range of character from which the
    attribute will be removed.
*/
- (void)removeAttribute:(CPString)anAttribute range:(CPRange)aRange
{
    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitOnMaxIndex:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitOnMaxIndex:YES],
        current = startingEntryIndex;

    if (endingEntryIndex === CPNotFound)
        endingEntryIndex = _rangeEntries.length;

    while (current < endingEntryIndex)
        [_rangeEntries[current++].attributes removeObjectForKey:anAttribute];

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];
}

//Changing Characters and Attributes
/*!
    Append an attributed string (characters and attributes) on to the end of
    the receiver.
    @param aString a CPAttributedString to append.
*/
- (void)appendAttributedString:(CPAttributedString)aString
{
    [self insertAttributedString:aString atIndex:_string.length];
}

/*!
    Inserts an attributed string (characters and attributes) at index,
    \c anIndex, into the receiver. The portion of the
    receiver's attributed string from the specified index to the end is shifted
    until after the inserted string.
    @param aString a CPAttributedString to insert.
    @param anIndex the index at which the insert is to occur.
    @exception CPRangeException If the index is out of bounds.
*/
- (void)insertAttributedString:(CPAttributedString)aString atIndex:(unsigned)anIndex
{
    if (anIndex < 0 || anIndex > [self length])
        [CPException raise:CPRangeException reason:"tried to insert attributed string at an invalid index: "+anIndex];

    var entryIndexOfNextEntry = [self _indexOfRangeEntryForIndex:anIndex splitOnMaxIndex:YES],
        otherRangeEntries = aString._rangeEntries,
        length = [aString length];

    if (entryIndexOfNextEntry === CPNotFound)
        entryIndexOfNextEntry = _rangeEntries.length;

    _string = _string.substring(0, anIndex) + aString._string + _string.substring(anIndex);

    var current = entryIndexOfNextEntry;
    while (current < _rangeEntries.length)
        _rangeEntries[current++].range.location += length;

    var newRangeEntryCount = otherRangeEntries.length,
        index = 0;

    while (index < newRangeEntryCount)
    {
        var entryCopy = copyRangeEntry(otherRangeEntries[index++]);
        entryCopy.range.location += anIndex;

        _rangeEntries.splice(entryIndexOfNextEntry - 1 + index, 0, entryCopy);
    }

    //necessary?
    //[self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:startingEntryIndex+rangeEntries.length];
}

/*!
    Replaces characters and attributes in the range \c aRange with
    those of the given attributed string, \c aString.
    @param aRange a CPRange object specifying the range of characters and
    attributes in the object to replace.
    @param aString a CPAttributedString containing the data to be used for
    replacement.
*/
- (void)replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPAttributedString)aString
{
    [self deleteCharactersInRange:aRange];
    [self insertAttributedString:aString atIndex:aRange.location];
}

/*!
    Sets the objects characters and attributes to those of \c aString.
    @param aString is a CPAttributedString from which the contents will be
    copied.
*/
- (void)setAttributedString:(CPAttributedString)aString
{
    _string = aString._string;
    _rangeEntries = [];

    var i = 0,
        count = aString._rangeEntries.length;

    for (; i < count; i++)
        _rangeEntries.push(copyRangeEntry(aString._rangeEntries[i]));
}

//Private methods
- (Number)_indexOfRangeEntryForIndex:(unsigned)characterIndex splitOnMaxIndex:(BOOL)split
{
    var index = [self _indexOfEntryWithIndex:characterIndex];

    if (index === CPNotFound)
        return index;

    var rangeEntry = _rangeEntries[index];

    if (rangeEntry.range.location === characterIndex || (CPMaxRange(rangeEntry.range) - 1 === characterIndex && !split))
        return index;

    var newEntries = splitRangeEntryAtIndex(rangeEntry, characterIndex);
    _rangeEntries.splice(index, 1, newEntries[0], newEntries[1]);
    index++;

    return index;
}

- (void)_coalesceRangeEntriesFromIndex:(unsigned)start toIndex:(unsigned)end
{
    var current = start;

    if (end >= _rangeEntries.length)
        end = _rangeEntries.length - 1;

    while (current < end)
    {
        var a = _rangeEntries[current],
            b = _rangeEntries[current + 1];

        if ([a.attributes isEqualToDictionary:b.attributes])
        {
            a.range.length = CPMaxRange(b.range) - a.range.location;
            _rangeEntries.splice(current + 1, 1);
            end--;
        }
        else
            current++;
    }
}

//Grouping Changes
/*!
    This function is deliberately empty. It is provided to ease code converting
    from Cocoa.
*/
- (void)beginEditing
{
    //do nothing (says cocotron and gnustep)
}

/*!
    This function is deliberately empty. It is provided to ease code converting
    from Cocoa.
*/
- (void)endEditing
{
    //do nothing (says cocotron and gnustep)
}

@end

/*!
    @class CPMutableAttributedString
    @ingroup compatibility

    This class is just an empty subclass of CPAttributedString.
    CPAttributedString already implements mutable methods and
    this class only exists for source compatibility.
*/
@implementation CPMutableAttributedString : CPAttributedString

@end

var isEqual = function(a, b)
{
    if (a === b)
        return YES;

    if ([a respondsToSelector:@selector(isEqual:)] && [a isEqual:b])
        return YES;

    return NO;
};

var makeRangeEntry = function(/*CPRange*/aRange, /*CPDictionary*/attributes)
{
    return {range:aRange, attributes:[attributes copy]};
};

var copyRangeEntry = function(/*RangeEntry*/aRangeEntry)
{
    return makeRangeEntry(CPMakeRangeCopy(aRangeEntry.range), [aRangeEntry.attributes copy]);
};

var splitRangeEntryAtIndex = function(/*RangeEntry*/aRangeEntry, /*unsigned*/anIndex)
{
    var newRangeEntry = copyRangeEntry(aRangeEntry),
        cachedIndex = CPMaxRange(aRangeEntry.range);

    aRangeEntry.range.length = anIndex - aRangeEntry.range.location;
    newRangeEntry.range.location = anIndex;
    newRangeEntry.range.length = cachedIndex - anIndex;
    newRangeEntry.attributes = [newRangeEntry.attributes copy];

    return [aRangeEntry, newRangeEntry];
};
