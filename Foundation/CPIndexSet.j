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

import "CPRange.j"
import "CPObject.j"

@implementation CPIndexSet : CPObject
{
    unsigned    _count;
    unsigned    _cachedRangeIndex;
    CPArray     _ranges;
}

// Creating an Index Set

+ (id)indexSet
{
	return [[self alloc] init];
}

+ (id)indexSetWithIndex:(int)anIndex
{
	return [[self alloc] initWithIndex:anIndex];
}

+ (id)indexSetWithIndexesInRange:(CPRange)aRange
{
	return [[self alloc] initWithIndexesInRange:aRange];
}

// Initializing and Index Set

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _count = 0;
        _ranges = [];
        _cachedRangeIndex = 0;
    }
    
    return self;
}

- (id)initWithIndex:(int)anIndex
{
    self = [super init];
    
    if (self)
    {
        _count = 1;
        _ranges = [CPArray arrayWithObject:CPMakeRange(anIndex, 1)];
        _cachedRangeIndex = 0;
    }
    
    return self;
}

- (id)initWithIndexesInRange:(CPRange)aRange
{
    self = [super init];
    
    if (self)
    {
        _count = aRange.length;
        _ranges = [CPArray arrayWithObject:aRange];
        _cachedRangeIndex = 0;
    }
    
    return self;
}

- (id)initWithIndexSet:(CPIndexSet)anIndexSet
{
    self = [super init];
    
    if (self)
    {
        _count = [anIndexSet count];
        _ranges = [];
        _cachedRangeIndex = 0;
        
        var index = 0,
            count = anIndexSet._ranges.length;
        
        for (; index < count; ++index)
            _ranges.push(CPCopyRange(anIndexSet._ranges[index]));
    }
    
    return self;
}

// Querying an Index Set

- (BOOL)isEqualToIndexSet:(CPIndexSet)anIndexSet
{
    // Comparisons to ourself are always return YES.
	if (self == anIndexSet)
	   return YES;
	
    var i = 0,
        count = _ranges.length;
        otherRanges = anIndexSet._ranges;
	
	// If we have a discrepency in the number of ranges or the number of indexes,
	// simply return NO.
	if (count != otherRanges.length || _count != [anIndexSet count])
	   return NO;
	
	for (; i < count; ++i)
		if (!CPEqualRanges(_ranges[i], otherRanges[i]))
			return NO;
			
	return YES;
}

- (BOOL)containsIndex:(unsigned)anIndex
{
    return [self containsIndexesInRange:CPMakeRange(anIndex, 1)];
}

- (BOOL)containsIndexesInRange:(CPRange)aRange
{
    if(!_count)
        return NO;

    var i = SOERangeIndex(self, aRange.location),
    	lower = aRange.location,
    	upper = CPMaxRange(aRange),
    	count = _ranges.length;

    // Stop if the location is ever bigger than or equal to our 
    // non-inclusive upper bound    
    for(;i < count && _ranges[i].location < upper; ++i)
        // The range must be a subset of one our ranges.
    	if (_ranges[i].location <= lower && CPMaxRange(_ranges[i]) >= upper)
    	{
            _cachedRangeIndex = i;
            return YES;
        }
    
    // The value isn't here, but values greater than anIndex should 
    // start from here regardless.
    _cachedRangeIndex = i;
    
    return NO;
}

- (BOOL)containsIndexes:(CPIndexSet)anIndexSet
{
    // Return YES if anIndexSet has no indexes
    if(![anIndexSet count])
        return YES; 
    
    // Return NO if we have no indexes.
    if(!_count)
        return NO;

    var i = 0,
        count = _ranges.length;
    
    // This is fast thanks to the _cachedIndexRange.
    for(; i < count; ++i)
        if (![anIndexSet containsIndexesInRange:_ranges[i]])
            return NO;
    
    return YES;
}

- (BOOL)intersectsIndexesInRange:(CPRange)aRange
{
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

- (int)count
{
    return _count;
}

// Accessing Indexes

- (int)firstIndex
{
    return _count ? _ranges[0].location : CPNotFound;
}

- (int)lastIndex
{
    return _count ? CPMaxRange(_ranges[_ranges.length - 1]) - 1 : CPNotFound;
}

- (unsigned)indexGreaterThanIndex:(unsigned)anIndex
{
    if(!_count)
        return CPNotFound;
    
    var i = SOERangeIndex(self, anIndex++),
        count = _ranges.length;
    
    for(; i < count && anIndex >= CPMaxRange(_ranges[i]); ++i) ;

    if (i == count)
        return CPNotFound;
    
    _cachedRangeIndex = i;
    
    if (anIndex < _ranges[i].location)
        return _ranges[i].location;

    return anIndex;
}

- (unsigned)indexLessThanIndex:(unsigned)anIndex
{
    if (!_count)
        return CPNotFound;
    
    var i = GOERangeIndex(self, anIndex--);
    
    for (; i >= 0 && anIndex < _ranges[i].location; --i) ;

    if(i < 0)
        return CPNotFound;
    
    _cachedRangeIndex = i;

   if (CPLocationInRange(anIndex, _ranges[i]))
        return anIndex;
    
    if (CPMaxRange(_ranges[i]) - 1 < anIndex)
        return CPMaxRange(_ranges[i]) - 1;

    return CPNotFound;
}

- (unsigned int)indexGreaterThanOrEqualToIndex:(unsigned)anIndex
{
	return [self indexGreaterThanIndex:anIndex - 1];
}

- (unsigned int)indexLessThanOrEqualToIndex:(unsigned)anIndex
{
	return [self indexLessThanIndex:anIndex + 1];
}

- (unsigned)getIndexes:(CPArray)anArray maxCount:(unsigned)aMaxCount inIndexRange:(CPRangePointer)aRangePointer
{
    if (!_count || aMacCount <= 0 || aRangePointer && !aRangePointer.length)
        return 0;
    
    var i = SOERangeIndex(self, aRangePointer.location),
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
			if (_ranges[i].length > 1) desc += "-" + (CPMaxRange(_ranges[i])-1) + ":"+_ranges[i].length+":";
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

- (void)addIndex:(unsigned)anIndex
{
    [self addIndexesInRange:CPMakeRange(anIndex, 1)];
}

- (void)addIndexes:(CPIndexSet)anIndexSet
{
    var i = 0,
        ranges = anIndexSet._ranges,
        count = ranges.length;
    
    // Simply add each range within anIndexSet.
    for(; i < count; ++i)
        [self addIndexesInRange:ranges[i]];
}

- (void)addIndexesInRange:(CPRange)aRange
{
    if (_ranges.length == 0)
    {
        _count = aRange.length;
        
        return [_ranges addObject:CPCopyRange(aRange)];
    }
    
    // FIXME: Should we really use SOERangeIndex here? There is no real 
    // reason the cached index would be a better guess than 0, and it 
    // would avoid a function call.
    var i = SOERangeIndex(self, aRange.location),
        count = _ranges.length,
        padded = CPMakeRange(aRange.location - 1, aRange.length + 2),
        maximum = CPMaxRange(aRange);

    // If our range won't intersect with the last range, just append it to the end.
    if (count && CPMaxRange(_ranges[count - 1]) < aRange.location)
        [_ranges addObject:CPCopyRange(aRange)];
    else
        for (; i < count; ++i)
        {
            // This range is completely independent of existing ranges,
            // simply add it to the array.
            if (maximum < _ranges[i].location)
            {
                _count += aRange.length;
                
                // Keep _cachedRangeIndex relevant.
                if (i < _cachedRangeIndex) ++_cachedRangeIndex;
                
                return [_ranges insertObject:CPCopyRange(aRange) atIndex:i];
            }
    
            if (CPIntersectionRange(_ranges[i], padded).length)
            {
                var union = CPUnionRange(_ranges[i], aRange);
    
                // We already contain all the indexes in this range.
                if (union.length == _ranges[i].length)
                    return;
    
                 // Pad the length to collapse with later ranges.
                 ++union.length;
                
                // We only need to check if we now intersect with any following 
                // ranges since if we now intersected with the previous range, 
                // it would have already been handled.  We start at i and not i + 1
                // to make sure we subtract i's length.
                var j = i;
                
                for(; j < count; ++j)
                    // Bail as soon as we don't find an intersection.
                    if(CPIntersectionRange(union, _ranges[j]).length)
                        _count -= _ranges[j].length;
                    else
                        break;
                
                // Remove the padding now that we are done.
                // NOTE: We could have set _ranges[i] = CPCopyRange(union), 
                // and then not had to bother decerementing here, but this avoids
                // a lookup above during unioning, and a function call (CPCopyRange).
                --union.length;
                _ranges[i] = union;
                
                // Now remove indexes [i + 1, j - 1]
                if (j - i - 1 > 0)
                {
                    var remove = CPMakeRange(i + 1, j - i - 1);
                    
                    _ranges[i] = CPUnionRange(_ranges[i], _ranges[j - 1]);
                    [_ranges removeObjectsInRange:remove];
                    
                    // Keep _cachedRangeIndex relevant.
                    if (_cachedRangeIndex >= CPMaxRange(remove)) _cachedRangedIndex -= remove.length;
                    else if (CPLocationInRange(_cachedRangeIndex, remove)) _cachedRangeIndex = i;
                }
    
                // Update count.
                _count += _ranges[i].length;
                
                return;
            }
        }
    
    _count += aRange.length;
}

// Removing Indexes

- (void)removeIndex:(unsigned int)anIndex
{
    [self removeIndexesInRange:CPMakeRange(anIndex, 1)];
}

- (void)removeIndexes:(CPIndexSet)anIndexSet
{
    var i = 0,
        ranges = anIndexSet._ranges,
        count = ranges.length;
    
    // Simply remove each index from anIndexSet
    for(; i < count; ++i)
        [self removeIndexesInRange:ranges[i]];
}

- (void)removeAllIndexes
{
    _ranges = [];
	_count = 0;
    _cachedRangeIndex = 0;
}

- (void)removeIndexesInRange:(CPRange)aRange
{
    // FIXME: Should we really use SOERangeIndex here? There is no real 
    // reason the cached index would be a better guess than 0, and it 
    // would avoid a function call.
    var i = SOERangeIndex(self, aRange.location),
        count = _ranges.length,
        maximum = CPMaxRange(aRange),
        removal = CPMakeRange(CPNotFound, 0);
        
    for (; i < count; ++i)
    {
        var range = _ranges[i];
        
        // Our range will not intersect with any coming ranges.
        if (maximum < range.location)
            break;

        var intersection = CPIntersectionRange(range, aRange);
        
        // If we don't have an intersection, then just continue iterating.
        if (!intersection.length)
            continue;
        
        // If the intersection consists of the entirety of this range, 
        // then remove it completely.
        else if (intersection.length == range.length)
        {
            if (removal.location == CPNotFound)
                removal = CPMakeRange(i, 1);
            else
                ++removal.length;
        }
        // If the intersection is contained entirely within this range, 
        // then split it into two and return.
        else if (intersection.location > range.location && CPMaxRange(intersection) < CPMaxRange(range))
        {
            var insert = CPMakeRange(CPMaxRange(intersection), CPMaxRange(range) - CPMaxRange(intersection));
            
            range.length = intersection.location - range.location;
            
            _count -= intersection.length;
            
            return [_ranges insertObject:insert atIndex:i + 1];
        }
        // Else if we at least have an intersection, then trim the existing range.
        else 
        {
            range.length -= intersection.length;
            
            if (intersection.location <= range.location)
                range.location += intersection.length;
        }
        
        _count -= intersection.length;
    }
    
    if (removal.length)
        [_ranges removeObjectsInRange:removal];
}

// Shifting Index Groups

- (void)shiftIndexesStartingAtIndex:(unsigned)anIndex by:(int)aDelta   
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
    CPIndexSetCachedRangeIndexKey   = @"CPIndexSetCachedRangeIndexKey",
    CPIndexSetRangeStringsKey       = @"CPIndexSetRangeStringsKey";

@implementation CPIndexSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _count = [aCoder decodeIntForKey:CPIndexSetCountKey];
        _cachedRangeIndex = [aCoder decodeIntForKey:CPIndexSetCachedRangeIndexKey];
        _ranges = [];
        
        var rangeStrings = [aCoder decodeObjectForKey:CPIndexSetRangeStringsKey],
            index = 0,
            count = rangeStrings.length;
        
        for (; index < count; ++index)
            _ranges.push(CPRangeFromString(rangeStrings[index]));
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:_count forKey:CPIndexSetCountKey];
    [aCoder encodeInt:_cachedRangeIndex forKey:CPIndexSetCachedRangeIndexKey];
    
    var index = 0,
        count = _ranges.length,
        rangeStrings = [];
        
    for (; index < count; ++index)
        rangeStrings[index] = CPStringFromRange(_ranges[index]);

    [aCoder encodeObject:rangeStrings forKey:CPIndexSetRangeStringsKey];
}

@end

@implementation CPIndexSet (CPCopying)

- (id)copy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

- (id)mutableCopy
{
    return [[[self class] alloc] initWithIndexSet:self];
}

@end

@implementation CPMutableIndexSet : CPIndexSet

@end

var SOERangeIndex = function(anIndexSet, anIndex)
{
    var ranges = anIndexSet._ranges,
        cachedRangeIndex = 0;//anIndexSet._cachedRangeIndex;
    
    if(cachedRangeIndex < ranges.length && anIndex >= ranges[cachedRangeIndex].location)
        return cachedRangeIndex;

    return 0;
}

var GOERangeIndex = function(anIndexSet, anIndex)
{
    var ranges = anIndexSet._ranges,
        cachedRangeIndex = anIndexSet._ranges.length;//anIndexSet._cachedRangeIndex;
        
    if(cachedRangeIndex < ranges.length && anIndex <= ranges[cachedRangeIndex].location)
        return cachedRangeIndex;
        
    return ranges.length - 1;
}

/*
new old method
X		+ (id)indexSet;
X		+ (id)indexSetWithIndex:(unsigned int)value;
X		+ (id)indexSetWithIndexesInRange:(NSRange)range;
X	X	- (id)init;
X	X	- (id)initWithIndex:(unsigned int)value;
X	X	- (id)initWithIndexesInRange:(NSRange)range;   // designated initializer
X	X	- (id)initWithIndexSet:(NSIndexSet *)indexSet;   // designated initializer
X		- (BOOL)isEqualToIndexSet:(NSIndexSet *)indexSet;
X	X	- (unsigned int)count;
X	X	- (unsigned int)firstIndex;
X	X	- (unsigned int)lastIndex;
X	X	- (unsigned int)indexGreaterThanIndex:(unsigned int)value;
X	X	- (unsigned int)indexLessThanIndex:(unsigned int)value;
X	X	- (unsigned int)indexGreaterThanOrEqualToIndex:(unsigned int)value;
X	X	- (unsigned int)indexLessThanOrEqualToIndex:(unsigned int)value;
X		- (unsigned int)getIndexes:(unsigned int *)indexBuffer maxCount:(unsigned int)bufferSize inIndexRange:(NSRangePointer)range;
X	X	- (BOOL)containsIndex:(unsigned int)value;
X	X	- (BOOL)containsIndexesInRange:(NSRange)range;
X	X	- (BOOL)containsIndexes:(NSIndexSet *)indexSet;
X	X	- (BOOL)intersectsIndexesInRange:(NSRange)range;
X	X	- (void)addIndexes:(NSIndexSet *)indexSet;
X		- (void)removeIndexes:(NSIndexSet *)indexSet;
X	X	- (void)removeAllIndexes;
X		- (void)addIndex:(unsigned int)value;
X		- (void)removeIndex:(unsigned int)value;
X		- (void)addIndexesInRange:(NSRange)range;
X		- (void)removeIndexesInRange:(NSRange)range;
		- (void)shiftIndexesStartingAtIndex:(unsigned int)index by:(int)delta;
*/
