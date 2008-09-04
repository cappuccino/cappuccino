/*
 * CPArray.j
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
import "CPRange.j"
import "CPEnumerator.j"
import "CPSortDescriptor.j"

@implementation _CPArrayEnumerator : CPEnumerator
{
    CPArray _array;
    int     _index;
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];
    
    if (self)
    {
        _array = anArray;
        _index = -1;
    }

    return self;
}

- (id)nextObject
{
    if (++_index >= [_array count])
        return nil;

    return _array[_index];
}

@end

@implementation _CPReverseArrayEnumerator : CPEnumerator
{
    CPArray _array;
    int     _index;
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];
    
    if (self)
    {
        _array = anArray;
        _index = [_array count];
    }
    
    return self;
}

- (id)nextObject
{
    if (--_index < 0)
        return nil;

    return _array[_index];
}

@end

@implementation CPArray : CPObject

+ (id)alloc
{
    return [];
}

+ (id)array
{
    return [[self alloc] init];
}

+ (id)arrayWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

+ (id)arrayWithObject:(id)anObject
{
    return [[self alloc] initWithObjects:anObject];
}

+ (id)arrayWithObjects:(id)anObject, ...
{
    var i = 2,
        array = [[self alloc] init],
        argument;

    for(; i < arguments.length && (argument = arguments[i]) != nil; ++i)
        array.push(argument);

    return array;
}

+ (id)arrayWithObjects:(id)objects count:(unsigned)aCount
{
    return [[self alloc] initWithObjects:objects count:aCount];
}

- (id)init
{
    return self;
}

// Creating an Array

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];
    
    if (self)
        [self setArray:anArray];
    
    return self;
}

- (id)initWithArray:(CPArray)anArray copyItems:(BOOL)copyItems
{
    if (!copyItems)
        return [self initWithArray:anArray];

    self = [super init];
    
    if (self)
    {
        var index = 0,
            count = [anArray count];
            
        for(; index < count; ++i)
        {
            if (anArray[i].isa)
                self[i] = [anArray copy];
            // Do a deep/shallow copy?
            else
                self[i] = anArray;
        }
    }
    
    return self;
}

- (id)initWithObjects:(Array)anObject, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var i = 2,
        argument;
    
    for(; i < arguments.length && (argument = arguments[i]) != nil; ++i)
        push(argument);

    return self; 
}

- (id)initWithObjects:(id)objects count:(unsigned)aCount
{
    self = [super init];
    
    if (self)
    {
        var index = 0;
    
        for(; index < aCount; ++index)
            push(objects[index]);
    }

    return self;
}

- (unsigned)hash
{
    if (self.__address == nil)
        self.__address = _objj_generateObjectHash();
        
    return self.__address;
}

// Querying an array

- (BOOL)containsObject:(id)anObject
{
    return [self indexOfObject:anObject] != CPNotFound;
}

- (int)count
{
    return length;
}

- (int)indexOfObject:(id)anObject
{
    if (anObject === nil)
        return CPNotFound;
    
    var i = 0, 
        count = length;

    // Only use isEqual: if our object is a CPObject.
    if (anObject.isa)
    {
        for(; i < count; ++i)
            if([self[i] isEqual:anObject])
                return i;
    }
    // If indexOf exists, use it since it's probably 
    // faster than anything we can implement.
    else if (self.indexOf)
        return indexOf(anObject);
    // Last resort, do a straight forward linear O(N) search.
    else
        for(; i < count; ++i)
            if(self[i] == anObject)
                return i;
    
    return CPNotFound;
}

- (int)indexOfObject:(id)anObject inRange:(CPRange)aRange
{
    if (anObject === nil)
        return CPNotFound;
    
    var i = aRange.location, 
        count = MIN(CPMaxRange(aRange), length);
    
    // Only use isEqual: if our object is a CPObject.
    if (anObject.isa)
    {
        for(; i < count; ++i)
            if([self[i] isEqual:anObject])
                return i;
    }
    // Last resort, do a straight forward linear O(N) search.
    else
        for(; i < count; ++i)
            if(self[i] == anObject)
                return i;
    
    return CPNotFound;
}

- (int)indexOfObjectIdenticalTo:(id)anObject
{
    if (anObject === nil)
        return CPNotFound;
    
    // If indexOf exists, use it since it's probably 
    // faster than anything we can implement.
    if (self.indexOf)
        return indexOf(anObject);
    
    // Last resort, do a straight forward linear O(N) search.
    else
    {
        var index = 0, 
            count = length;
        
        for(; index < count; ++index)
            if(self[index] == anObject)
                return index;
    }
    
    return CPNotFound;
}

- (int)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (anObject === nil)
        return CPNotFound;
    
    // If indexOf exists, use it since it's probably 
    // faster than anything we can implement.
    if (self.indexOf)
    {
        var index = indexOf(anObject, aRange.location);
        
        if (CPLocationInRange(index, aRange))
            return index;
    }
    
    // Last resort, do a straight forward linear O(N) search.
    else
    {
        var index = aRange.location, 
            count = MIN(CPMaxRange(aRange), length);
        
        for(; index < count; ++index)
            if(self[index] == anObject)
                return index;
    }
    
    return CPNotFound;
}

- (id)lastObject
{
    var count = [self count];
    
    if (!count) return nil;
    
    return self[count - 1];
}

- (id)objectAtIndex:(int)anIndex
{
    return self[anIndex];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    var index = [indexes firstIndex],
        objects = [];

    while(index != CPNotFound)
    {
        [objects addObject:self[index]];
        index = [indexes indexGreaterThanIndex:index];
    }

    return objects;
}

- (CPEnumerator)objectEnumerator
{
    return [[_CPArrayEnumerator alloc] initWithArray:self];
}

- (CPEnumerator)reverseObjectEnumerator
{
    return [[_CPReverseArrayEnumerator alloc] initWithArray:self];
}

// Sending messages to elements

- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    var index = 0, 
        count = length;
        
    for(; index < count; ++index)
        objj_msgSend(self[index], aSelector);
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    var index = 0, 
        count = length;
        
    for(; index < count; ++index) 
        objj_msgSend(self[index], aSelector, anObject);
}

// Comparing arrays

- (id)firstObjectCommonWithArray:(CPArray)anArray
{
    if (![anArray count] || ![self count])
        return nil;
    
    var i = 0,
        count = [self count];

    for(; i < count; ++i)
        if([anArray containsObject:self[i]])
            return self[i];

    return nil;
}

- (BOOL)isEqualToArray:(id)anArray
{
    if(length != anArray.length)
        return NO;
    
    var index = 0,
        count = [self count];
    
    for(; index < count; ++index)
        if(self[index] != anObject && (!self[index].isa || !anObject.isa || ![self[index] isEqual:anObject]))
            return NO;
    
    return YES;
}

// Deriving new arrays

- (CPArray)arrayByAddingObject:(id)anObject
{
    var array = [self copy];
    
    array.push(anObject);
    
    return array;
}

- (CPArray)arrayByAddingObjectsFromArray:(CPArray)anArray
{
    return slice(0).concat(anArray);
}

/*  
- (CPArray)filteredArrayUsingPredicate:(CPPredicate)aPredicate
{
    var i= 0, 
        count = [self count],
        array = [CPArray array];
    
    for(; i<count; ++i)
        if(aPredicate.evaluateWithObject(self[i]))
            array.push(self[i]);
    
    return array;
}
*/

- (CPArray)subarrayWithRange:(CPRange)aRange
{
    return slice(aRange.location, CPMaxRange(aRange));
}

// Sorting arrays

- (CPArray)sortedArrayUsingDescriptors:(CPArray)descriptors
{
    var sorted = [self copy];
    
    [sorted sortUsingDescriptors:descriptors];
    
    return sorted;
}

- (CPArray)sortedArrayUsingFunction:(Function)aFunction context:(id)aContext
{
    var sorted = [self copy];
    
    [sorted sortUsingFunction:aFunction context:aContext];
    
    return sorted;
}

- (CPArray)sortedArrayUsingSelector:(SEL)aSelector
{
    var sorted = [self copy]
    
    [sorted sortUsingSelector:aSelector];

    return sorted;
}

// Working with string elements

- (CPString)componentsJoinedByString:(CPString)aString
{
    var index = 0,
        count = [self count],
        string = @"";
        
    for(; index < count; ++i)
        string += self[index].isa ? [self[index] description] : self[index];
        
    return string;
}

// Creating a description of the array

- (CPString)description
{
    var i = 0,
        count = [self count],
        description = '(';
    
    for(; i < count; ++i)
    {
        if (self[i].isa) description += [self[i] description];
        else description += self[i];
        
        if (i != count - 1) description += ", ";
    }
        
    return description + ')';
}

// Collecting paths

- (CPArray)pathsMatchingExtensions:(CPArray)filterTypes
{
    var index = 0,
        count = [self count],
        array = [];
    
    for(; index < count; ++index)
        if (self[index].isa && [self[index] isKindOfClass:[CPString class]] && [filterTypes containsObject:[self[index] pathExtensions]])
            array.push(self[index]);
    
    return array;
}

// Key value coding

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var i = 0,
        count = [self count];
    
    for(; i < count; ++i)
        [self[i] setValue:aValue forKey:aKey];
}

- (CPArray)valueForKey:(CPString)aKey
{
    var i = 0,
        count = [self count],
        array = [];
    
    for(; i < count; ++i)
        array.push([self[i] valueForKey:aKey]);
    
    return array;
}

// Copying arrays

- (id)copy
{
    return slice(0);
}
    
@end

@implementation CPArray(CPMutableArray)

// Creating arrays

+ (CPArray)arrayWithCapacity:(unsigned)aCapacity
{
    return [[self alloc] initWithCapacity:aCapacity];
}

- (id)initWithCapacity:(unsigned)aCapacity
{
    return self;
}

// Adding and replacing objects

- (void)addObject:(id)anObject
{
    push(anObject);
}
    
- (void)addObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [length, 0].concat(anArray));
}

- (void)insertObject:(id)anObject atIndex:(int)anIndex
{
    splice(anIndex, 0, anObject);
}

- (void)insertObjects:(CPArray)objects atIndexes:(CPIndexSet)anIndexSet
{
    var index = 0,
        position = CPNotFound;
    
    while ((position = [indexes indexGreaterThanIndex:position]) != CPNotFound)
        [self insertObject:objects[index++] atindex:position];
}
    
- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    self[anIndex] = anObject;
}

- (void)replaceObjectsAtIndexes:(CPIndexSet)anIndexSet withObjects:(CPArray)objects
{
    var i = 0, 
        index = [anIndexSet firstIndex];
   
    while(index != CPNotFound)
    {
        [self replaceObjectAtIndex:index withObject:objects[i++]];
        index = [anIndexSet indexGreaterThanIndex:index];
    }
}

- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray range:(CPRange)otherRange
{
    if (!otherRange.location && otherRange.length == [anArray count])
        [self replaceObjectsInRange:aRange withObjectsFromArray:anArray];
    else
        splice.apply(self, [aRange.location, aRange.length].concat([anArray subarrayWithRange:otherRange]));
}

- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [aRange.location, aRange.length].concat(anArray));
}

- (void)setArray:(CPArray)anArray
{
    if(self == anArray) return;
    
    splice.apply(self, [0, length].concat(anArray));
}

// Removing Objects

- (void)removeAllObjects
{
    splice(0, length);
}
    
- (void)removeLastObject
{
    pop();
}

- (void)removeObject:(id)anObject
{
    [self removeObject:anObject inRange:CPMakeRange(0, length)];
}

- (void)removeObject:(id)anObject inRange:(CPRange)aRange
{
    var index;
    
    while ((index = [self indexOfObject:anObject inRange:aRange]) != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, length - index), aRange);
    }
}

- (void)removeObjectAtIndex:(int)anIndex
{
    splice(anIndex, 1);
}

- (void)removeObjectsAtIndexes:(CPIndexSet)anIndexSet
{
    var index = [anIndexSet lastIndex];
   
    while (index != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        index = [anIndexSet indexSmallerThanIndex:index];
    }
}

- (void)removeObjectIdenticalTo:(id)anObject
{
    [self removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, length)];
}

- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    var index;
    
    while ((index = [self indexOfObjectIdenticalTo:anObject inRange:aRange]) != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, length - index), aRange);
    }
}

- (void)removeObjectsInArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];
        
    for (; index < count; ++index)
        [self removeObject:anArray[index]];
}

- (void)removeObjectsInRange:(CPRange)aRange
{
    splice(aRange.location, aRange.length);
}

// Rearranging objects

- (void)exchangeObjectAtIndex:(unsigned)anIndex withObjectAtIndex:(unsigned)otherIndex
{
    var temporary = self[anIndex];
    self[anIndex] = self[otherIndex];
    self[otherIndex] = temporary;
}

- (CPArray)sortUsingDescriptors:(CPArray)descriptors
{
    sort(function(lhs, rhs)
    {
        var i = 0,
            count = [descriptors count],
            result = CPOrderedSame;
        
        while(i < count)
            if((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;
        
        return result;
    });
}

- (void)sortUsingFunction:(Function)aFunction context:(id)aContext
{
    sort(function(lhs, rhs) { return aFunction(lhs, rhs, aContext); });
}

- (void)sortUsingSelector:(SEL)aSelector
{
    sort(function(lhs, rhs) { return objj_msgSend(lhs, aSelector, rhs); });
}

@end

@implementation CPArray (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder _decodeArrayOfObjectsForKey:@"CP.objects"];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder _encodeArrayOfObjects:self forKey:@"CP.objects"];
}

@end

@implementation CPMutableArray : CPArray

@end

Array.prototype.isa = CPArray;
[CPArray initialize];

