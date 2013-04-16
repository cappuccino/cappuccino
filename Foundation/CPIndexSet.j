/*
 * CPIndexSet.j
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

#include "Foundation.h"

@import "CPArray.j"
@import "CPObject.j"
@import "CPRange.j"

/*!
    @class CPIndexSet
    @ingroup foundation
    @brief A collection of unique integers.

    Instances of this class are collections of numbers. Each integer can appear
    in a collection only once.
*/
@implementation CPIndexSet : CPObject
{
    unsigned    _count;
    CPArray     _ranges;
}

// Creating an Index Set
/*!
    Returns a new empty index set.
*/
+ (id)indexSet
{
    return [[self alloc] init];
}

/*!
    Returns a new index set with just one index.
*/
+ (id)indexSetWithIndex:(int)anIndex
{
    return [[self alloc] initWithIndex:anIndex];
}

/*!
    Returns a new index set with all the numbers in the specified range.
    @param aRange the range of numbers to add to the index set.
*/
+ (id)indexSetWithIndexesInRange:(CPRange)aRange
{
    return [[self alloc] initWithIndexesInRange:aRange];
}

// Initializing and Index Set

- (id)init
{
    return [self initWithIndexesInRange:CPMakeRange(0, 0)];
}

/*!
    Initializes the index set with a single index.
    @return the initialized index set
*/
- (id)initWithIndex:(CPInteger)anIndex
{
    if (!_IS_NUMERIC(anIndex))
        [CPException raise:CPInvalidArgumentException
                    reason:"Invalid index"];

    return [self initWithIndexesInRange:CPMakeRange(anIndex, 1)];
}

/*!
    Initializes the index set with numbers from the specified range.
    @param aRange the range of numbers to add to the index set
    @return the initialized index set
*/
- (id)initWithIndexesInRange:(CPRange)aRange
{
    if (aRange.location < 0)
        [CPException raise:CPInvalidArgumentException reason:"Range " + CPStringFromRange(aRange) + " is out of bounds."];

    self = [super init];

    if (self)
    {
        _count = MAX(0, aRange.length);

        if (_count > 0)
            _ranges = [aRange];
        else
            _ranges = [];
    }

    return self;
}

/*!
    Initializes the index set with another index set.
    @param anIndexSet the index set from which to read the initial index set
    @return the initialized index set
*/
- (id)initWithIndexSet:(CPIndexSet)anIndexSet
{
    self = [super init];

    if (self)
    {
        _count = [anIndexSet count];
        _ranges = [];

        var otherRanges = anIndexSet._ranges,
            otherRangesCount = otherRanges.length;

        while (otherRangesCount--)
            _ranges[otherRangesCount] = CPMakeRangeCopy(otherRanges[otherRangesCount]);
    }

    return self;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (!anObject || ![anObject isKindOfClass:[CPIndexSet class]])
        return NO;

    return [self isEqualToIndexSet:anObject];
}

// Querying an Index Set
/*!
    Compares the receiver with the provided index set.
    @param anIndexSet the index set to compare to
    @return \c YES if the receiver and the index set are functionally equivalent
*/
- (BOOL)isEqualToIndexSet:(CPIndexSet)anIndexSet
{
    if (!anIndexSet)
        return NO;

    // Comparisons to ourself are always return YES.
    if (self === anIndexSet)
       return YES;

    var rangesCount = _ranges.length,
        otherRanges = anIndexSet._ranges;

    // If we have a discrepancy in the number of ranges or the number of indexes,
    // simply return NO.
    if (rangesCount !== otherRanges.length || _count !== anIndexSet._count)
        return NO;

    while (rangesCount--)
        if (!CPEqualRanges(_ranges[rangesCount], otherRanges[rangesCount]))
            return NO;

    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    return  self === anObject ||
            [anObject isKindOfClass:[self class]] &&
            [self isEqualToIndexSet:anObject];
}

/*!
    Returns \c YES if the index set contains the specified index.
    @param anIndex the index to check for in the set
    @return \c YES if \c anIndex is in the receiver index set
*/
- (BOOL)containsIndex:(CPInteger)anIndex
{
    return positionOfIndex(_ranges, anIndex) !== CPNotFound;
}

/*!
    Returns \c YES if the index set contains all the numbers in the specified range.
    @param aRange the range of numbers to check for in the index set
*/
- (BOOL)containsIndexesInRange:(CPRange)aRange
{
    if (aRange.length <= 0)
        return NO;

    // If we have less total indexes than aRange, we can't possibly contain aRange.
    if (_count < aRange.length)
        return NO;

    // Search for first location
    var rangeIndex = positionOfIndex(_ranges, aRange.location);

    // If we don't have the first location, then we don't contain aRange.
    if (rangeIndex === CPNotFound)
        return NO;

    var range = _ranges[rangeIndex];

    // The intersection must contain all the indexes from the original range.
    return CPIntersectionRange(range, aRange).length === aRange.length;
}

/*!
    Returns \c YES if the receiving index set contains all the indices in the argument.
    @param anIndexSet the set of indices to check for in the receiving index set
*/
- (BOOL)containsIndexes:(CPIndexSet)anIndexSet
{
    var otherCount = anIndexSet._count;

    if (otherCount <= 0)
        return YES;

    // If we have less total indexes than anIndexSet, we can't possibly contain aRange.
    if (_count < otherCount)
        return NO;

    var otherRanges = anIndexSet._ranges,
        otherRangesCount = otherRanges.length;

    while (otherRangesCount--)
        if (![self containsIndexesInRange:otherRanges[otherRangesCount]])
            return NO;

    return YES;
}

/*!
    Checks if the receiver contains at least one number in \c aRange.
    @param aRange the range of numbers to check.
    @return \c YES if the receiving index set contains at least one number in the provided range
*/
- (BOOL)intersectsIndexesInRange:(CPRange)aRange
{
    if (_count <= 0)
        return NO;

    var lhsRangeIndex = assumedPositionOfIndex(_ranges, aRange.location);

    if (FLOOR(lhsRangeIndex) === lhsRangeIndex)
        return YES;

    var rhsRangeIndex = assumedPositionOfIndex(_ranges, CPMaxRange(aRange) - 1);

    if (FLOOR(rhsRangeIndex) === rhsRangeIndex)
        return YES;

    return lhsRangeIndex !== rhsRangeIndex;
}

/*!
    The number of indices in the set
*/
- (int)count
{
    return _count;
}

// Accessing Indexes
/*!
    Return the first index in the set
*/
- (CPInteger)firstIndex
{
    if (_count > 0)
        return _ranges[0].location;

    return CPNotFound;
}

/*!
    Returns the last index in the set
*/
- (CPInteger)lastIndex
{
    if (_count > 0)
        return CPMaxRange(_ranges[_ranges.length - 1]) - 1;

    return CPNotFound;
}

/*!
    Returns the first index value in the receiver which is greater than \c anIndex.
    @return the closest index or CPNotFound if no match was found
*/
- (CPInteger)indexGreaterThanIndex:(CPInteger)anIndex
{
    // The first possible index that would satisfy this requirement.
    ++anIndex;

    // Attempt to find it or something bigger.
    var rangeIndex = assumedPositionOfIndex(_ranges, anIndex);

    // Nothing at all found?
    if (rangeIndex === CPNotFound)
        return CPNotFound;

    rangeIndex = CEIL(rangeIndex);

    if (rangeIndex >= _ranges.length)
        return CPNotFound;

    var range = _ranges[rangeIndex];

    // Check if it's actually in this range.
    if (CPLocationInRange(anIndex, range))
        return anIndex;

    // If not, it must be the first element of this range.
    return range.location;
}

/*!
    Returns the first index value in the receiver which is less than \c anIndex.
    @return the closest index or CPNotFound if no match was found
*/
- (CPInteger)indexLessThanIndex:(CPInteger)anIndex
{
    // The first possible index that would satisfy this requirement.
    --anIndex;

    // Attempt to find it or something smaller.
    var rangeIndex = assumedPositionOfIndex(_ranges, anIndex);

    // Nothing at all found?
    if (rangeIndex === CPNotFound)
        return CPNotFound;

    rangeIndex = FLOOR(rangeIndex);

    if (rangeIndex < 0)
        return CPNotFound;

    var range = _ranges[rangeIndex];

    // Check if it's actually in this range.
    if (CPLocationInRange(anIndex, range))
        return anIndex;

    // If not, it must be the first element of this range.
    return CPMaxRange(range) - 1;
}

/*!
    Returns the first index value in the receiver which is greater than or equal to \c anIndex.
    @return the matching index or CPNotFound if no match was found
*/
- (CPInteger)indexGreaterThanOrEqualToIndex:(CPInteger)anIndex
{
    return [self indexGreaterThanIndex:anIndex - 1];
}

/*!
    Returns the first index value in the receiver which is less than or equal to \c anIndex.
    @return the matching index or CPNotFound if no match was found
*/
- (CPInteger)indexLessThanOrEqualToIndex:(CPInteger)anIndex
{
    return [self indexLessThanIndex:anIndex + 1];
}

/*!
    Fills up the specified array with numbers from the index set within
    the specified range. The method stops filling up the array until the
    \c aMaxCount number have been added or the range maximum is reached.
    @param anArray the array to fill up
    @param aMaxCount the maximum number of numbers to adds
    @param aRangePointer the range of indices to add
    @return the number of elements added to the array
*/
- (CPInteger)getIndexes:(CPArray)anArray maxCount:(CPInteger)aMaxCount inIndexRange:(CPRange)aRange
{
    if (!_count || aMaxCount === 0 || aRange && !aRange.length)
    {
        if (aRange)
            aRange.length = 0;

        return 0;
    }

    var total = 0;

    if (aRange)
    {
        var firstIndex = aRange.location,
            lastIndex = CPMaxRange(aRange) - 1,
            rangeIndex = CEIL(assumedPositionOfIndex(_ranges, firstIndex)),
            lastRangeIndex = FLOOR(assumedPositionOfIndex(_ranges, lastIndex));
    }
    else
    {
        var firstIndex = [self firstIndex],
            lastIndex = [self lastIndex],
            rangeIndex = 0,
            lastRangeIndex = _ranges.length - 1;
    }

    while (rangeIndex <= lastRangeIndex)
    {
        var range = _ranges[rangeIndex],
            index = MAX(firstIndex, range.location),
            maxRange = MIN(lastIndex + 1, CPMaxRange(range));

        for (; index < maxRange; ++index)
        {
            anArray[total++] = index;

            if (total === aMaxCount)
            {
                // Update aRange if it exists...
                if (aRange)
                {
                    aRange.location = index + 1;
                    aRange.length = lastIndex + 1 - index - 1;
                }

                return aMaxCount;
            }
        }

        ++rangeIndex;
    }

    // Update aRange if it exists...
    if (aRange)
    {
        aRange.location = CPNotFound;
        aRange.length = 0;
    }

    return total;
}

- (CPString)description
{
    var description = [super description];

    if (_count)
    {
        var index = 0,
            count = _ranges.length;

        description += "[number of indexes: " + _count + " (in " + count;

        if (count === 1)
            description += " range), indexes: (";
        else
            description += " ranges), indexes: (";

        for (; index < count; ++index)
        {
            var range = _ranges[index];

            description += range.location;

            if (range.length > 1)
                description += "-" + (CPMaxRange(range) - 1);

            if (index + 1 < count)
                description += " ";
        }

        description += ")]";
    }

    else
        description += "(no indexes)";

    return description;
}

- (void)enumerateIndexesUsingBlock:(Function /*(int idx, @ref BOOL stop) */)aFunction
{
    [self enumerateIndexesWithOptions:CPEnumerationNormal usingBlock:aFunction];
}

- (void)enumerateIndexesWithOptions:(CPEnumerationOptions)options usingBlock:(Function /*(int idx, @ref BOOL stop)*/)aFunction
{
    if (!_count)
        return;
    [self enumerateIndexesInRange:CPMakeRange(0, CPMaxRange(_ranges[_ranges.length - 1])) options:options usingBlock:aFunction];
}

- (void)enumerateIndexesInRange:(CPRange)enumerationRange options:(CPEnumerationOptions)options usingBlock:(Function /*(int idx, @ref BOOL stop)*/)aFunction
{
    if (!_count || CPEmptyRange(enumerationRange))
        return;

    var shouldStop = NO,
        index,
        stop,
        increment;

    if (options & CPEnumerationReverse)
    {
        index = _ranges.length - 1,
        stop = -1,
        increment = -1;
    }
    else
    {
        index = 0;
        stop = _ranges.length;
        increment = 1;
    }

    for (; index !== stop; index += increment)
    {
        var range = _ranges[index],
            rangeIndex,
            rangeStop,
            rangeIncrement;

        if (options & CPEnumerationReverse)
        {
            rangeIndex = CPMaxRange(range) - 1;
            rangeStop = range.location - 1;
            rangeIncrement = -1;
        }
        else
        {
            rangeIndex = range.location;
            rangeStop = CPMaxRange(range);
            rangeIncrement = 1;
        }

        for (; rangeIndex !== rangeStop; rangeIndex += rangeIncrement)
        {
            if (CPLocationInRange(rangeIndex, enumerationRange))
            {
                aFunction(rangeIndex, @ref(shouldStop));
                if (shouldStop)
                    return;
            }
        }
    }
}

- (unsigned)indexPassingTest:(Function /*(int anIndex)*/)aPredicate
{
    return [self indexWithOptions:CPEnumerationNormal passingTest:aPredicate];
}

- (CPIndexSet)indexesPassingTest:(Function /*(int anIndex)*/)aPredicate
{
    return [self indexesWithOptions:CPEnumerationNormal passingTest:aPredicate];
}

- (unsigned)indexWithOptions:(CPEnumerationOptions)anOptions passingTest:(Function /*(int anIndex)*/)aPredicate
{
    if (!_count)
        return CPNotFound;

    return [self indexInRange:CPMakeRange(0, CPMaxRange(_ranges[_ranges.length - 1])) options:anOptions passingTest:aPredicate];
}

- (CPIndexSet)indexesWithOptions:(CPEnumerationOptions)anOptions passingTest:(Function /*(int anIndex)*/)aPredicate
{
    if (!_count)
        return [CPIndexSet indexSet];

    return [self indexesInRange:CPMakeRange(0, CPMaxRange(_ranges[_ranges.length - 1])) options:anOptions passingTest:aPredicate];
}

- (unsigned)indexInRange:(CPRange)aRange options:(CPEnumerationOptions)anOptions passingTest:(Function /*(int anIndex)*/)aPredicate
{
    if (!_count || CPEmptyRange(aRange))
        return CPNotFound;

    var shouldStop = NO,
        index,
        stop,
        increment;

    if (anOptions & CPEnumerationReverse)
    {
        index = _ranges.length - 1,
        stop = -1,
        increment = -1;
    }
    else
    {
        index = 0;
        stop = _ranges.length;
        increment = 1;
    }

    for (; index !== stop; index += increment)
    {
        var range = _ranges[index],
            rangeIndex,
            rangeStop,
            rangeIncrement;

        if (anOptions & CPEnumerationReverse)
        {
            rangeIndex = CPMaxRange(range) - 1;
            rangeStop = range.location - 1;
            rangeIncrement = -1;
        }
        else
        {
            rangeIndex = range.location;
            rangeStop = CPMaxRange(range);
            rangeIncrement = 1;
        }

        for (; rangeIndex !== rangeStop; rangeIndex += rangeIncrement)
        {
            if (CPLocationInRange(rangeIndex, aRange))
            {
                if (aPredicate(rangeIndex, @ref(shouldStop)))
                    return rangeIndex;

                if (shouldStop)
                    return CPNotFound;
            }
        }
    }

    return CPNotFound;
}

- (CPIndexSet)indexesInRange:(CPRange)aRange options:(CPEnumerationOptions)anOptions passingTest:(Function /*(int anIndex)*/)aPredicate
{
    if (!_count || CPEmptyRange(aRange))
        return [CPIndexSet indexSet];

    var shouldStop = NO,
        index,
        stop,
        increment;

    if (anOptions & CPEnumerationReverse)
    {
        index = _ranges.length - 1,
        stop = -1,
        increment = -1;
    }
    else
    {
        index = 0;
        stop = _ranges.length;
        increment = 1;
    }

    var indexesPassingTest = [CPMutableIndexSet indexSet];

    for (; index !== stop; index += increment)
    {
        var range = _ranges[index],
            rangeIndex,
            rangeStop,
            rangeIncrement;

        if (anOptions & CPEnumerationReverse)
        {
            rangeIndex = CPMaxRange(range) - 1;
            rangeStop = range.location - 1;
            rangeIncrement = -1;
        }
        else
        {
            rangeIndex = range.location;
            rangeStop = CPMaxRange(range);
            rangeIncrement = 1;
        }

        for (; rangeIndex !== rangeStop; rangeIndex += rangeIncrement)
        {
            if (CPLocationInRange(rangeIndex, aRange))
            {
                if (aPredicate(rangeIndex, @ref(shouldStop)))
                    [indexesPassingTest addIndex:rangeIndex];

                if (shouldStop)
                    return indexesPassingTest;
            }
        }
    }

    return indexesPassingTest;
}

@end

@implementation CPIndexSet(CPMutableIndexSet)

// Adding indexes.
/*!
    Adds an index to the set.
    @param anIndex the index to add
*/
- (void)addIndex:(CPInteger)anIndex
{
    [self addIndexesInRange:CPMakeRange(anIndex, 1)];
}

/*!
    Adds indices to the set
    @param anIndexSet a set of indices to add to the receiver
*/
- (void)addIndexes:(CPIndexSet)anIndexSet
{
    var otherRanges = anIndexSet._ranges,
        otherRangesCount = otherRanges.length;

    // Simply add each range within anIndexSet.
    while (otherRangesCount--)
        [self addIndexesInRange:otherRanges[otherRangesCount]];
}

/*!
    Adds the range of indices to the set
    @param aRange the range of numbers to add as indices to the set
*/
- (void)addIndexesInRange:(CPRange)aRange
{
    if (aRange.location < 0)
        [CPException raise:CPInvalidArgumentException reason:"Range " + CPStringFromRange(aRange) + " is out of bounds."];

    // If empty range, bail.
    if (aRange.length <= 0)
        return;

    // If we currently don't have any indexes, this represents our entire set.
    if (_count <= 0)
    {
        _count = aRange.length;
        _ranges = [aRange];

        return;
    }

    var rangeCount = _ranges.length,
        lhsRangeIndex = assumedPositionOfIndex(_ranges, aRange.location - 1),
        lhsRangeIndexCEIL = CEIL(lhsRangeIndex);

    if (lhsRangeIndexCEIL === lhsRangeIndex && lhsRangeIndexCEIL < rangeCount)
        aRange = CPUnionRange(aRange, _ranges[lhsRangeIndexCEIL]);

    var rhsRangeIndex = assumedPositionOfIndex(_ranges, CPMaxRange(aRange)),
        rhsRangeIndexFLOOR = FLOOR(rhsRangeIndex);

    if (rhsRangeIndexFLOOR === rhsRangeIndex && rhsRangeIndexFLOOR >= 0)
        aRange = CPUnionRange(aRange, _ranges[rhsRangeIndexFLOOR]);

    var removalCount = rhsRangeIndexFLOOR - lhsRangeIndexCEIL + 1;

    if (removalCount === _ranges.length)
    {
        _ranges = [aRange];
        _count = aRange.length;
    }

    else if (removalCount === 1)
    {
        if (lhsRangeIndexCEIL < _ranges.length)
            _count -= _ranges[lhsRangeIndexCEIL].length;

        _count += aRange.length;
        _ranges[lhsRangeIndexCEIL] = aRange;
    }

    else
    {
        if (removalCount > 0)
        {
            var removal = lhsRangeIndexCEIL,
                lastRemoval = lhsRangeIndexCEIL + removalCount - 1;

            for (; removal <= lastRemoval; ++removal)
                _count -= _ranges[removal].length;

            [_ranges removeObjectsInRange:CPMakeRange(lhsRangeIndexCEIL, removalCount)];
        }

        [_ranges insertObject:aRange atIndex:lhsRangeIndexCEIL];

        _count += aRange.length;
    }
}

// Removing Indexes
/*!
    Removes an index from the set
    @param anIndex the index to remove
*/
- (void)removeIndex:(CPInteger)anIndex
{
    [self removeIndexesInRange:CPMakeRange(anIndex, 1)];
}

/*!
    Removes the indices from the receiving set.
    @param anIndexSet the set of indices to remove
    from the receiver
*/
- (void)removeIndexes:(CPIndexSet)anIndexSet
{
    var otherRanges = anIndexSet._ranges,
        otherRangesCount = otherRanges.length;

    // Simply remove each index from anIndexSet
    while (otherRangesCount--)
        [self removeIndexesInRange:otherRanges[otherRangesCount]];
}

/*!
    Removes all indices from the set
*/
- (void)removeAllIndexes
{
    _ranges = [];
    _count = 0;
}

/*!
    Removes the indices in the range from the
    set.
    @param aRange the range of indices to remove
*/
- (void)removeIndexesInRange:(CPRange)aRange
{
    // If empty range, bail.
    if (aRange.length <= 0)
        return;

    // If we currently don't have any indexes, there's nothing to remove.
    if (_count <= 0)
        return;

    var rangeCount = _ranges.length,
        lhsRangeIndex = assumedPositionOfIndex(_ranges, aRange.location),
        lhsRangeIndexCEIL = CEIL(lhsRangeIndex);

    // Do we fall on an actual existing range?
    if (lhsRangeIndex === lhsRangeIndexCEIL && lhsRangeIndexCEIL < rangeCount)
    {
        var existingRange = _ranges[lhsRangeIndexCEIL];

        // If these ranges don't start in the same place, we have to cull it.
        if (aRange.location !== existingRange.location)
        {
            var maxRange = CPMaxRange(aRange),
                existingMaxRange = CPMaxRange(existingRange);

            existingRange.length = aRange.location - existingRange.location;

            // If this range is internal to the existing range, we have a unique splitting case.
            if (maxRange < existingMaxRange)
            {
                _count -= aRange.length;
                [_ranges insertObject:CPMakeRange(maxRange, existingMaxRange - maxRange) atIndex:lhsRangeIndexCEIL + 1];

                return;
            }
            else
            {
                _count -= existingMaxRange - aRange.location;
                lhsRangeIndexCEIL += 1;
            }
        }
    }

    var rhsRangeIndex = assumedPositionOfIndex(_ranges, CPMaxRange(aRange) - 1),
        rhsRangeIndexFLOOR = FLOOR(rhsRangeIndex);

    if (rhsRangeIndex === rhsRangeIndexFLOOR && rhsRangeIndexFLOOR >= 0)
    {
        var maxRange = CPMaxRange(aRange),
            existingRange = _ranges[rhsRangeIndexFLOOR],
            existingMaxRange = CPMaxRange(existingRange);

        if (maxRange !== existingMaxRange)
        {
            _count -= maxRange - existingRange.location;
            rhsRangeIndexFLOOR -= 1; // This is accounted for, and thus as if we got the previous spot.

            existingRange.location = maxRange;
            existingRange.length = existingMaxRange - maxRange;
        }
    }

    var removalCount = rhsRangeIndexFLOOR - lhsRangeIndexCEIL + 1;

    if (removalCount > 0)
    {
        var removal = lhsRangeIndexCEIL,
            lastRemoval = lhsRangeIndexCEIL + removalCount - 1;

        for (; removal <= lastRemoval; ++removal)
            _count -= _ranges[removal].length;

        [_ranges removeObjectsInRange:CPMakeRange(lhsRangeIndexCEIL, removalCount)];
    }
}

// Shifting Index Groups
/*!
    Shifts the values of indices left or right by a specified amount.
    @param anIndex the index to start the shifting operation from (inclusive)
    @param aDelta the amount and direction to shift. A positive value shifts to
    the right. A negative value shifts to the left.
*/
- (void)shiftIndexesStartingAtIndex:(CPInteger)anIndex by:(int)aDelta
{
    if (!_count || aDelta == 0)
       return;

    // Later indexes have a higher probability of being shifted
    // than lower ones, so start at the end and work backwards.
    var i = _ranges.length - 1,
        shifted = CPMakeRange(CPNotFound, 0);

    for (; i >= 0; --i)
    {
        var range = _ranges[i],
            maximum = CPMaxRange(range);

        if (anIndex >= maximum)
            break;

        // If our index is within our range, but not the first index,
        // then this range will be split.
        if (anIndex > range.location)
        {
            // Split the range into shift and unshifted.
            shifted = CPMakeRange(anIndex + aDelta, maximum - anIndex);
            range.length = anIndex - range.location;

            // If our delta is positive, then we can simply add the range
            // to the array.
            if (aDelta > 0)
                [_ranges insertObject:shifted atIndex:i + 1];
            // If it's negative, it needs to be added properly later.
            else if (shifted.location < 0)
            {
                shifted.length = CPMaxRange(shifted);
                shifted.location = 0;
            }

            // We don't need to continue.
            break;
        }

        // Shift the range, and normalize it if the result is negative.
        if ((range.location += aDelta) < 0)
        {
            _count -= range.length - CPMaxRange(range);
            range.length = CPMaxRange(range);
            range.location = 0;
        }
    }

    // We need to add the shifted ranges if the delta is negative.
    if (aDelta < 0)
    {
        var j = i + 1,
            count = _ranges.length,
            shifts = [];

        for (; j < count; ++j)
        {
            [shifts addObject:_ranges[j]];
            _count -= _ranges[j].length;
        }

        if ((j = i + 1) < count)
        {
            [_ranges removeObjectsInRange:CPMakeRange(j, count - j)];

            for (j = 0, count = shifts.length; j < count; ++j)
                [self addIndexesInRange:shifts[j]];
        }

        if (shifted.location != CPNotFound)
            [self addIndexesInRange:shifted];
    }
}

@end

var CPIndexSetCountKey              = @"CPIndexSetCountKey",
    CPIndexSetRangeStringsKey       = @"CPIndexSetRangeStringsKey";

@implementation CPIndexSet (CPCoding)

/*!
    Initializes the index set from a coder.
    @param aCoder the coder from which to read the
    index set data
    @return the initialized index set
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _count = [aCoder decodeIntForKey:CPIndexSetCountKey];
        _ranges = [];

        var rangeStrings = [aCoder decodeObjectForKey:CPIndexSetRangeStringsKey],
            index = 0,
            count = rangeStrings.length;

        for (; index < count; ++index)
            _ranges.push(CPRangeFromString(rangeStrings[index]));
    }

    return self;
}

/*!
    Writes out the index set to the specified coder.
    @param aCoder the coder to which the index set will
    be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:_count forKey:CPIndexSetCountKey];

    var index = 0,
        count = _ranges.length,
        rangeStrings = [];

    for (; index < count; ++index)
        rangeStrings[index] = CPStringFromRange(_ranges[index]);

    [aCoder encodeObject:rangeStrings forKey:CPIndexSetRangeStringsKey];
}

@end

@implementation CPIndexSet (CPCopying)

/*!
    Creates a deep copy of the index set. The returned copy
    is mutable. The reason for the two copy methods is for
    source compatibility with GNUStep code.
    @return the index set copy
*/
- (id)copy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

/*!
    Creates a deep copy of the index set. The returned copy
    is mutable. The reason for the two copy methods is for
    source compatibility with GNUStep code.
    @return the index set copy
*/
- (id)mutableCopy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

@end

/*!
    @class CPMutableIndexSet
    @ingroup compatibility

    This class is an empty of subclass of CPIndexSet.
    CPIndexSet already implements mutable methods, and
    this class only exists for source compatibility.
*/
@implementation CPMutableIndexSet : CPIndexSet

@end

var positionOfIndex = function(ranges, anIndex)
{
    var low = 0,
        high = ranges.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            range = ranges[middle];

        if (anIndex < range.location)
            high = middle - 1;

        else if (anIndex >= CPMaxRange(range))
            low = middle + 1;

        else
            return middle;
   }

   return CPNotFound;
};

var assumedPositionOfIndex = function(ranges, anIndex)
{
    var count = ranges.length;

    if (count <= 0)
        return CPNotFound;

    var low = 0,
        high = count * 2;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            position = middle / 2,
            positionFLOOR = FLOOR(position);

        if (position === positionFLOOR)
        {
            if (positionFLOOR - 1 >= 0 && anIndex < CPMaxRange(ranges[positionFLOOR - 1]))
                high = middle - 1;

            else if (positionFLOOR < count && anIndex >= ranges[positionFLOOR].location)
                low = middle + 1;

            else
                return positionFLOOR - 0.5;
        }
        else
        {
            var range = ranges[positionFLOOR];

            if (anIndex < range.location)
                high = middle - 1;

            else if (anIndex >= CPMaxRange(range))
                low = middle + 1;

            else
                return positionFLOOR;
        }
    }

   return CPNotFound;
};

/*
new old method
X       + (id)indexSet;
X       + (id)indexSetWithIndex:(unsigned int)value;
X       + (id)indexSetWithIndexesInRange:(NSRange)range;
X   X   - (id)init;
X   X   - (id)initWithIndex:(unsigned int)value;
X   X   - (id)initWithIndexesInRange:(NSRange)range;   // designated initializer
X   X   - (id)initWithIndexSet:(NSIndexSet *)indexSet;   // designated initializer
X       - (BOOL)isEqualToIndexSet:(NSIndexSet *)indexSet;
X   X   - (unsigned int)count;
X   X   - (unsigned int)firstIndex;
X   X   - (unsigned int)lastIndex;
X   X   - (unsigned int)indexGreaterThanIndex:(unsigned int)value;
X   X   - (unsigned int)indexLessThanIndex:(unsigned int)value;
X   X   - (unsigned int)indexGreaterThanOrEqualToIndex:(unsigned int)value;
X   X   - (unsigned int)indexLessThanOrEqualToIndex:(unsigned int)value;
X       - (unsigned int)getIndexes:(unsigned int *)indexBuffer maxCount:(unsigned int)bufferSize inIndexRange:(NSRangePointer)range;
X   X   - (BOOL)containsIndex:(unsigned int)value;
X   X   - (BOOL)containsIndexesInRange:(NSRange)range;
X   X   - (BOOL)containsIndexes:(NSIndexSet *)indexSet;
X   X   - (BOOL)intersectsIndexesInRange:(NSRange)range;
X   X   - (void)addIndexes:(NSIndexSet *)indexSet;
X       - (void)removeIndexes:(NSIndexSet *)indexSet;
X   X   - (void)removeAllIndexes;
X       - (void)addIndex:(unsigned int)value;
X       - (void)removeIndex:(unsigned int)value;
X       - (void)addIndexesInRange:(NSRange)range;
X       - (void)removeIndexesInRange:(NSRange)range;
        - (void)shiftIndexesStartingAtIndex:(unsigned int)index by:(int)delta;
*/
