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

import <Foundation/CPObject.j>
import <Foundation/CPString.j>

@implementation CPAttributedString : CPObject
{
    CPString    _string;
    CPArray     _rangeEntries;
}

//Creating an NSAttributedString Object
- (id)initWithString:(CPString)aString
{
    return [self initWithString:aString attributes:nil];
}
 
- (id)initWithAttributedString:(CPAttributedString)aString
{
    var string = [self initWithString:"" attributes:nil];
    
    [string setAttributedString:aString];
    
    return string;
}

- (id)initWithString:(CPString)aString attributes:(CPDictionary)attributes
{
    self = [super init];
    
    if (!attributes)
        attributes = [CPDictionary dictionary];

    _string = ""+aString;
    _rangeEntries = [makeRangeEntry(CPMakeRange(0, _string.length), attributes)];

    return self;
}

//Retrieving Character Information
- (CPString)string
{
    return _string;
}

- (CPString)mutableString
{
    return [self string];
}   

- (unsigned)length
{
    return _string.length;
}

- (unsigned)_indexOfEntryWithIndex:(unsigned)anIndex
{
    if (anIndex < 0 || anIndex > _string.length || anIndex === undefined)
        return CPNotFound;

    //find the range entry that contains anIndex.
    var sortFunction = function(index, entry)
    {
        //index is the character index we're searching for, while range is the actual range entry we're comparing against
        if (CPLocationInRange(index, entry.range))
            return CPOrderedSame;
        else if (CPMaxRange(entry.range) <= index)
            return CPOrderedDescending;
        else
            return CPOrderedAscending;
    }

    return [_rangeEntries indexOfObject:anIndex sortedByFunction:sortFunction];
}

//Retrieving Attribute Information
- (CPDictionary)attributesAtIndex:(unsigned)anIndex effectiveRange:(CPRangePointer)aRange
{
    //find the range entry that contains anIndex.
    var entryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (entryIndex == CPNotFound)
        return nil;

    var matchingRange = _rangeEntries[entryIndex];
    if (aRange)
    {
        aRange.location = matchingRange.range.location;
        aRange.length = matchingRange.range.length;
    }
    
    return matchingRange.attributes;
}

- (CPDictionary)attributesAtIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{    
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (startingEntryIndex == CPNotFound)
        return nil;
    
    if (!aRange)
        return _rangeEntries[startingEntryIndex].attributes;

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;
        
        return _rangeEntries[startingEntryIndex].attributes;
    }

    //scan backwards
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

    //scan forwards
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

- (id)attribute:(CPString)attribute atIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{
    //find the range entry that contains anIndex.
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];
    
    if (startingEntryIndex == CPNotFound || !attribute)
        return nil;

    if (!aRange)
        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;
        
        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];
    }

    //scan backwards
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

    //scan forwards
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
- (BOOL)isEqualToAttributedString:(CPAttributedString)aString
{
	if(!aString)
		return NO;

	if(_string != [aString string])
		return NO;

    var myRange = CPMakeRange(),
        comparisonRange = CPMakeRange(),
        myAttributes = [self attributesAtIndex:0 effectiveRange:myRange],
        comparisonAttributes = [aString attributesAtIndex:0 effectiveRange:comparisonRange],
        length = _string.length;

    while (CPMaxRange(CPUnionRange(myRange, comparisonRange)) < length)
    {
        if (CPIntersectionRange(myRange, comparisonRange).length > 0 && ![myAttributes isEqualToDictionary:comparisonAttributes])
            return NO;
        if (CPMaxRange(myRange) < CPMaxRange(comparisonRange))
            myAttributes = [self attributesAtIndex:CPMaxRange(myRange) effectiveRange:myRange];
        else
            comparisonAttributes = [aString attributesAtIndex:CPMaxRange(comparisonRange) effectiveRange:comparisonRange];
    }
    
    return YES;
}

- (BOOL)isEqual:(id)anObject
{
	if (anObject == self)
		return YES;
		
	if ([anObject isKindOfClass:[self class]])
		return [self isEqualToAttributedString:anObject];
		
	return NO;
}

//Extracting a Substring
- (CPAttributedString)attributedSubstringFromRange:(CPRange)aRange
{
    if (!aRange || CPMaxRange(aRange) > _string.length || aRange.location < 0)
        [CPException raise:CPRangeException 
                    reason:"tried to get attributedSubstring for an invalid range: "+(aRange?CPStringFromRange(aRange):"nil")];

    var newString = [[CPAttributedString alloc] initWithString:_string.substring(aRange.location, CPMaxRange(aRange))],
        entryIndex = [self _indexOfEntryWithIndex:aRange.location],
        currentRangeEntry = _rangeEntries[entryIndex],
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
- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [self beginEditing];

    if (!aString)
        aString = "";
        
    var startingIndex = [self _indexOfEntryWithIndex:aRange.location],
        startingRangeEntry = _rangeEntries[startingIndex],
        endingIndex = [self _indexOfEntryWithIndex:CPMaxRange(aRange)-1],
        endingRangeEntry = _rangeEntries[endingIndex],
        additionalLength = aString.length - aRange.length;

    _string = _string.substring(0, aRange.location) + aString + _string.substring(CPMaxRange(aRange));

    if (startingIndex == endingIndex)
        startingRangeEntry.range.length += additionalLength;
    else
    {
        endingRangeEntry.range.length = CPMaxRange(endingRangeEntry.range) - CPMaxRange(aRange);
        endingRangeEntry.range.location = CPMaxRange(aRange);

        startingRangeEntry.range.length = CPMaxRange(aRange) - startingRangeEntry.range.location;

        _rangeEntries.splice(startingIndex, endingIndex - startingIndex);
    }

    endingIndex = startingIndex + 1;
    
    while(endingIndex < _rangeEntries.length)
        _rangeEntries[endingIndex++].range.location+=additionalLength;
    
    [self endEditing];
}

- (void)deleteCharactersInRange:(CPRange)aRange
{
    [self replaceCharactersInRange:aRange withString:nil];
}

//Changing Attributes
- (void)setAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    [self beginEditing];

    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitOnMaxIndex:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitOnMaxIndex:YES],
        current = startingEntryIndex;

    if (endingEntryIndex == CPNotFound)
        endingEntryIndex = _rangeEntries.length;

    while (current < endingEntryIndex)
        _rangeEntries[current++].attributes = [aDictionary copy];

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];

    [self endEditing];
}

- (void)addAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    [self beginEditing];

    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitOnMaxIndex:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitOnMaxIndex:YES],
        current = startingEntryIndex;

    if (endingEntryIndex == CPNotFound)
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

    [self endEditing];
}

- (void)addAttribute:(CPString)anAttribute value:(id)aValue range:(CPRange)aRange
{
    [self addAttributes:[CPDictionary dictionaryWithObject:aValue forKey:anAttribute] range:aRange];
}

- (void)removeAttribute:(CPString)anAttribute range:(CPRange)aRange
{
    [self addAttribute:anAttribute value:nil range:aRange];
}

//Changing Characters and Attributes
- (void)appendAttributedString:(CPAttributedString)aString
{
    [self insertAttributedString:aString atIndex:_string.length];
}

- (void)insertAttributedString:(CPAttributedString)aString atIndex:(CPString)anIndex
{
    [self beginEditing];

    if (anIndex < 0 || anIndex > [self length])
        [CPException raise:CPRangeException reason:"tried to insert attributed string at an invalid index: "+anIndex];

    var entryIndexOfNextEntry = [self _indexOfRangeEntryForIndex:anIndex splitOnMaxIndex:YES],
        otherRangeEntries = aString._rangeEntries,
        length = [aString length];

    if (entryIndexOfNextEntry == CPNotFound)
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
        
        _rangeEntries.splice(entryIndexOfNextEntry-1+index, 0, entryCopy);
    }

    //necessary?
    //[self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:startingEntryIndex+rangeEntries.length];

    [self endEditing];
}

- (void)replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPAttributedString)aString
{
    [self beginEditing];
        
    [self deleteCharactersInRange:aRange];
    [self insertAttributedString:aString atIndex:aRange.location];
    
    [self endEditing];
}

- (void)setAttributedString:(CPAttributedString)aString
{
    [self beginEditing];
    
    _string = aString._string;
    _rangeEntries = [];
    
    for (var i=0, count = aString._rangeEntries.length; i<count; i++)
        _rangeEntries.push(copyRangeEntry(aString._rangeEntries[i]));

    [self endEditing];
}

//Private methods
- (void)_indexOfRangeEntryForIndex:(unsigned)characterIndex splitOnMaxIndex:(BOOL)split
{    
    var index = [self _indexOfEntryWithIndex:characterIndex];
    
    if (index < 0)
        return index;

    var rangeEntry = _rangeEntries[index];
    
    if (rangeEntry.range.location == characterIndex || (CPMaxRange(rangeEntry.range) - 1 == characterIndex && !split))
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
        end = _rangeEntries.length -1;

    while (current < end)
    {
        var a = _rangeEntries[current],
            b = _rangeEntries[current+1];

        if ([a.attributes isEqualToDictionary:b.attributes])
        {
            a.range.length = CPMaxRange(b.range) - a.range.location;
            _rangeEntries.splice(current+1, 1);
            end--;
        }
        else
            current++;
    }
}

//Grouping Changes
- (void)beginEditing
{
    //do nothing (says cocotron and gnustep)
}

- (void)endEditing
{
    //do nothing (says cocotron and gnustep)
}

@end

var isEqual = function isEqual(a, b)
{
    if (a == b)
        return YES;

    if ([a respondsToSelector:@selector(isEqual:)] && [a isEqual:b])
        return YES;

    return NO;
}

var makeRangeEntry = function makeRangeEntry(/*CPRange*/aRange, /*CPDictionary*/attributes)
{
    return {range:aRange, attributes:[attributes copy]};
}

var copyRangeEntry = function copyRangeEntry(/*RangeEntry*/aRangeEntry)
{
    return makeRangeEntry(CPCopyRange(aRangeEntry.range), [aRangeEntry.attributes copy]);
}

var splitRangeEntry = function splitRangeEntryAtIndex(/*RangeEntry*/aRangeEntry, /*unsigned*/anIndex)
{
    var newRangeEntry = copyRangeEntry(aRangeEntry),
        cachedIndex = CPMaxRange(aRangeEntry.range);
    
    aRangeEntry.range.length = anIndex - aRangeEntry.range.location;
    newRangeEntry.range.location = anIndex;
    newRangeEntry.range.length = cachedIndex - anIndex;
    newRangeEntry.attributes = [newRangeEntry.attributes copy];
    
    return [aRangeEntry, newRangeEntry];
}