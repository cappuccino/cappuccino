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

@import "CPRange.j"
@import "CPObject.j"


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
    return [self initWithIndexesInRange:CPMakeRange(anIndex, 1)];
}

/*!
    Initializes the index set with numbers from the specified range.
    @param aRange the range of numbers to add to the index set
    @return the initialized index set
*/
- (id)initWithIndexesInRange:(CPRange)aRange
{
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
            _ranges[otherRangesCount] = CPCopyRange(otherRanges[otherRangesCount]);
    }

    return self;
}

// Querying an Index Set
/*!
    Compares the receiver with the provided index set.
    @param anIndexSet the index set to compare to
    @return <code>YES</code> if the receiver and the index set are functionally equivalent
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

    // If we have a discrepency in the number of ranges or the number of indexes,
    // simply return NO.
    if (rangesCount !== otherRanges.length || _count !== anIndexSet._count)
        return NO;

    while (count--)
        if (!CPEqualRanges(_ranges[count], otherRanges[count]))
            return NO;

    return YES;
}

/*!
    Returns <code>YES</code> if the index set contains the specified index.
    @param anIndex the index to check for in the set
    @return <code>YES</code> if <code>anIndex</code> is in the receiver index set
*/
- (BOOL)containsIndex:(CPInteger)anIndex
{
    return positionOfIndex(_ranges, anIndex) !== CPNotFound;
}

/*!
    Returns <code>YES</code> if the index set contains all the numbers in the specified range.
    @param aRange the range of numbers to check for in the index set
*/
- (BOOL)containsIndexesInRange:(CPRange)aRange
{
    if (aRange.length <= 0)
        return NO;

    // If we have less total indexes than aRange, we can't possibly contain aRange.
    if(_count < aRange.length)
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
    Returns <code>YES</code> if the receving index set contains all the indices in the argument.
    @param anIndexSet the set of indices to check for in the receiving index set
*/
- (BOOL)containsIndexes:(CPIndexSet)anIndexSet
{
    var otherCount = anIndexSet._count;

    if(otherCount <= 0)
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
    Checks if the receiver contains at least one number in <code>aRange</code>.
    @param aRange the range of numbers to check.
    @return <code>YES</code> if the receiving index set contains at least one number in the provided range
*/
- (BOOL)intersectsIndexesInRange:(CPRange)aRange
{
    //FIXME: OLD
    // This is fast thanks to the _cachedIndexRange.
    if(!_count)
        return NO;

    var i = SOERangeIndex(self, aRange.location),
        count = _ranges.length,
        upper = CPMaxRange(aRange);

    // Stop if the location is ever bigger than or equal to our 
    // non-inclusive upper bound 
    for (; i < count && _ranges[i].location < upper; ++i)
        if(CPIntersectionRange(aRange, _ranges[i]).length)
            return YES;

    return NO;
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
    Returns the first index value in the receiver which is greater than <code>anIndex</code>.
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
    Returns the first index value in the receiver which is less than <code>anIndex</code>.
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
    Returns the first index value in the receiver which is greater than or equal to <code>anIndex</code>.
    @return the matching index or CPNotFound if no match was found
*/
- (CPInteger)indexGreaterThanOrEqualToIndex:(CPInteger)anIndex
{
    return [self indexGreaterThanIndex:anIndex - 1];
}

/*!
    Returns the first index value in the receiver which is less than or equal to <code>anIndex</code>.
    @return the matching index or CPNotFound if no match was found
*/
- (CPInteger)indexLessThanOrEqualToIndex:(CPInteger)anIndex
{
    return [self indexLessThanIndex:anIndex + 1];
}

/*!
    Fills up the specified array with numbers from the index set within
    the specified range. The method stops filling up the array until the
    <code>aMaxCount</code> number have been added or the range maximum is reached.
    @param anArray the array to fill up
    @param aMaxCount the maximum number of numbers to adds
    @param aRangePointer the range of indices to add
    @return the number of elements added to the array
*/
- (unsigned)getIndexes:(CPArray)anArray maxCount:(unsigned)aMaxCount inIndexRange:(CPRange)aRangePointer
{
    if (!_count || aMaxCount <= 0 || aRangePointer && !aRangePointer.length)
        return 0;

    var i = SOERangeIndex(self, aRangePointer? aRangePointer.location : 0),
        total = 0,
        count = _ranges.length;

    for (; i < count; ++i)
    {
        // If aRangePointer is nil, all indexes are acceptable.
        var intersection = aRangePointer ? CPIntersectionRange(_ranges[i], aRangePointer) : _ranges[i],
            index = intersection.location,
            maximum = CPMaxRange(intersection);

        for (; index < maximum; ++index)
        {
            anArray[total++] = index;

            if (total == aMaxCount)
            {
                // Update aRangePointer if it exists...
                if (aRangePointer)
                {
                    var upper = CPMaxRange(aRangePointer);

                    // Don't use CPMakeRange since the values need to persist.
                    aRangePointer.location = index + 1;
                    aRangePointer.length = upper - index - 1;
                }

                return aMaxCount;
            }
        }
    }

    // Update aRangePointer if it exists...
    if (aRangePointer)
    {
        aRangePointer.location = CPNotFound;
        aRangePointer.length = 0;
    }

    return total;
}

- (CPString)description
{
    var desc = [super description] + " ";

    if (_count)
    {
        desc += "[number of indexes: " + _count + " (in " + _ranges.length + " ranges), indexes: (";
        for (i = 0; i < _ranges.length; i++)
        {
            desc += _ranges[i].location;
            if (_ranges[i].length > 1) desc += "-" + (CPMaxRange(_ranges[i])-1) + "["+_ranges[i].length+"]";
            if (i+1 < _ranges.length)  desc += " ";
        }
        desc += ")]";
    }
    else
        desc += "(no indexes)";
    return desc;
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
var x = aRange.location - 1, y = CPMaxRange(aRange);
    var rangeCount = _ranges.length,
        lhsRangeIndex = assumedPositionOfIndex(_ranges, aRange.location - 1),
        lhsRangeIndexCEIL = CEIL(lhsRangeIndex);
try{
    if (lhsRangeIndexCEIL === lhsRangeIndex && lhsRangeIndexCEIL < rangeCount)
        aRange = CPUnionRange(aRange, _ranges[lhsRangeIndexCEIL]);
}catch(e) { alert("123456789 " + lhsRangeIndexCEIL + " " + rangeCount + " " + lhsRangeIndex);}
    var rhsRangeIndex = assumedPositionOfIndex(_ranges, CPMaxRange(aRange)),
        rhsRangeIndexFLOOR = FLOOR(rhsRangeIndex);

    if (rhsRangeIndexFLOOR === rhsRangeIndex && rhsRangeIndexFLOOR > 0)
        aRange = CPUnionRange(aRange, _ranges[rhsRangeIndexFLOOR]);
//print("the returned indxes were for searching for " + x + " to " + y + " are " + lhsRangeIndex + " and " + rhsRangeIndex);
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
    // FIXME: OLD
    // If empty range, bail.
    if (aRange.length <= 0)
        return;

    // If we currently don't have any indexes, there's nothing to remove.
    if (_count <= 0)
        return;

    var rangeCount = _ranges.length,
        lhsRangeIndex = assumedPositionOfIndex(_ranges, aRange.location - 1),
        lhsRangeIndexCEIL = CEIL(lhsRangeIndex);

    if (lhsRangeIndexCEIL === lhsRangeIndex && lhsRangeIndexCEIL < rangeCount)
        aRange = CPUnionRange(aRange, _ranges[lhsRangeIndexCEIL]);

    var rhsRangeIndex = assumedPositionOfIndex(_ranges, CPMaxRange(aRange)),
        rhsRangeIndexFLOOR = FLOOR(rhsRangeIndex);

    if (rhsRangeIndexFLOOR === rhsRangeIndex && rhsRangeIndexFLOOR > 0)
        aRange = CPUnionRange(aRange, _ranges[rhsRangeIndexFLOOR]);

    var removalCount = rhsRangeIndexFLOOR - lhsRangeIndexCEIL + 1;

    if (removalCount === 1)
    {
        if (lhsRangeIndexCEIL < _ranges.length)
            _count -= _ranges[lhsRangeIndexCEIL].length;

        _count += aRange.length;
        _ranges[lhsRangeIndexCEIL] = aRange;
    }

    else
    {
        if (removalCount > 0)
            [_ranges removeObjectsInRange:CPMakeRange(lhsRangeIndexCEIL, removalCount)];

        [_ranges insertObject:aRange atIndex:lhsRangeIndexCEIL];
    //FIXME COUNT!
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

    for(; i >= 0; --i)
    {
        var range = _ranges[i],
            maximum = CPMaxRange(range);

        if (anIndex > maximum)
            break;

        // If our index is within our range, but not the first index, 
        // then this range will be split.
        if (anIndex > range.location && anIndex < maximum)
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
            [shifts addObject:_ranges[j]];

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
    source compatability with GNUStep code.
    @return the index set copy
*/
- (id)copy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

/*!
    Creates a deep copy of the index set. The returned copy
    is mutable. The reason for the two copy methods is for
    source compatability with GNUStep code.
    @return the index set copy
*/
- (id)mutableCopy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

@end

/*!
    @class CPMutableIndexSet
    @ingroup compatability

    This class is an empty of subclass of CPIndexSet.
    CPIndexSet already implements mutable methods, and
    this class only exists for source compatability.
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
}

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
        {try{
            if (positionFLOOR - 1 >= 0 && anIndex < CPMaxRange(ranges[positionFLOOR - 1]))
                high = middle - 1;

            else if (positionFLOOR < count && anIndex >= ranges[positionFLOOR].location)
                low = middle + 1;

            else
                return positionFLOOR - 0.5;}catch(e) { alert("here!");}
        }
        else
        {try{
            var range = ranges[positionFLOOR];

            if (anIndex < range.location)
                high = middle - 1;

            else if (anIndex >= CPMaxRange(range))
                low = middle + 1;

            else
                return positionFLOOR;}catch(e){alert("yes!");}
        }
    }

   return CPNotFound;
}

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
