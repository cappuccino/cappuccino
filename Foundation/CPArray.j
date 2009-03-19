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

@import "CPObject.j"
@import "CPRange.j"
@import "CPEnumerator.j"
@import "CPSortDescriptor.j"
@import "CPException.j"

/* @ignore */
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

    return [_array objectAtIndex:_index];
}

@end

/* @ignore */
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

    return [_array objectAtIndex:_index];
}

@end

/*! @class CPArray
    A mutable array class backed by a JavaScript Array.
    There is also a CPMutableArray class,
    but it is just a child class of this class with an
    empty implementation. All mutable functionality is
    implemented directly in CPArray.
*/
@implementation CPArray : CPObject

/*!
    Returns a new uninitialized CPArray.
*/
+ (id)alloc
{
    return [];
}

/*!
    Returns a new initialized CPArray.
*/
+ (id)array
{
    return [[self alloc] init];
}

/*!
    Creates a new array containing the objects in <code>anArray</code>.
    @param anArray Objects in this array will be added to the new array
    @return a new CPArray of the provided objects
*/
+ (id)arrayWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

/*!
    Creates a new array with <code>anObject</code> in it.
    @param anObject the object to be added to the array
    @return a new CPArray containing a single object
*/
+ (id)arrayWithObject:(id)anObject
{
    return [[self alloc] initWithObjects:anObject];
}

/*!
    Creates a new CPArray containing all the objects passed as arguments to the method.
    @param anObject the objects that will be added to the new array
    @return a new CPArray containing the argument objects
*/
+ (id)arrayWithObjects:(id)anObject, ...
{
    var i = 2,
        array = [[self alloc] init],
        argument;

    for(; i < arguments.length && (argument = arguments[i]) != nil; ++i)
        array.push(argument);

    return array;
}

/*!
    Creates a CPArray from a JavaScript array of objects.
    @param objects the JavaScript Array
    @param aCount the number of objects in the JS Array
    @return a new CPArray containing the specified objects
*/
+ (id)arrayWithObjects:(id)objects count:(unsigned)aCount
{
    return [[self alloc] initWithObjects:objects count:aCount];
}

/*!
    Initializes the CPArray.
    @return the initialized array
*/
- (id)init
{
    return self;
}

// Creating an Array
/*!
    Creates a new CPArray from <code>anArray</code>.
    @param anArray objects in this array will be added to the new array
    @return a new CPArray containing the objects of <code>anArray</code>
*/
- (id)initWithArray:(CPArray)anArray
{
    self = [super init];
    
    if (self)
        [self setArray:anArray];
    
    return self;
}

/*!
    Initializes a the array with the contents of <code>anArray</code>
    and optionally performs a deep copy of the objects based on <code>copyItems</code>.
    @param anArray the array to copy the data from
    @param copyItems if <code>YES</code>, each object will be copied by having a <code>copy</code> message sent to it, and the
    returned object will be added to the receiver. Otherwise, no copying will be performed.
    @return the initialized array of objects
*/
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

/*!
    initializes an array with the contents of anArray
*/
- (id)initWithObjects:(Array)anArray, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var i = 2,
        argument;
    
    for(; i < arguments.length && (argument = arguments[i]) != nil; ++i)
        push(argument);

    return self; 
}

/*!
    Initializes the array with a JavaScript array of objects.
    @param objects the array of objects to add to the receiver
    @param aCount the number of objects in <code>objects</code>
    @return the initialized CPArray
*/
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

/*!
    Returns a hash of the CPArray.
    @return an unsigned integer hash
*/
- (unsigned)hash
{
    if (self.__address == nil)
        self.__address = _objj_generateObjectHash();

    return self.__address;
}

// Querying an array
/*!
    Returns <code>YES</code> if the array contains <code>anObject</code>. Otherwise, it returns <code>NO</code>.
    @param anObject the method checks if this object is already in the array
*/
- (BOOL)containsObject:(id)anObject
{
    return [self indexOfObject:anObject] != CPNotFound;
}

/*!
    Returns the number of elements in the array
*/
- (int)count
{
    return length;
}

/*!
    Returns the index of <code>anObject</code> in this array.
    If the object is <code>nil</code> or not in the array,
    returns <code>CPNotFound</code>. It first attempts to find
    a match using <code>isEqual:</code>, then <code>==</code>.
    @param anObject the object to search for
*/
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

/*!
    Returns the index of <code>anObject</code> in the array
    within <code>aRange</code>. It first attempts to find
    a match using <code>isEqual:</code>, then <code>==</code>.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
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

/*!
    Returns the index of <code>anObject</code> in the array. The test for equality is done using only <code>==</code>.
    @param anObject the object to search for
    @return the index of the object in the array. <code>CPNotFound</code> if the object is not in the array.
*/
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

/*!
    Returns the index of <code>anObject</code> in the array
    within <code>aRange</code>. The test for equality is
    done using only <code>==</code>.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
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

/*!
    Returns the index of <code>anObject</code> in the array, which must be sorted in the same order as
    calling sortUsingSelector: with the selector passed to this method would result in. 
    @param anObject the object to search for
    @param aSelector the comparison selector to call on each item in the list, the same
    selector should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedBySelector:(SEL)aSelector
{
    return [self indexOfObject:anObject sortedByFunction: function(lhs, rhs) { objj_msgSend(lhs, aSelector, rhs); }];
}

/*!
    Returns the index of <code>anObject</code> in the array, which must be sorted in the same order as
    calling sortUsingFunction: with the selector passed to this method would result in. 
    The function will be called like so:
    <pre>
    aFunction(anObject, currentObjectInArrayForComparison)
    </pre>
    @param anObject the object to search for
    @param aFunction the comparison function to call on each item in the array that we search. the same
    selector should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByFunction:(Function)aFunction
{
    return [self indexOfObject:anObject sortedByFunction:aFunction context:nil];
}

/*!
    Returns the index of <code>anObject</code> in the array, which must be sorted in the same order as
    calling sortUsingFunction: with the selector passed to this method would result in. 
    The function will be called like so:
    <pre>
    aFunction(anObject, currentObjectInArrayForComparison, context)
    </pre>
    @param anObject the object to search for
    @param aFunction the comparison function to call on each item in the array that we search. the same
    function should have been used to sort the array (or to maintain its sorted order).
    @param aContext a context object that will be passed to the sort function
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByFunction:(Function)aFunction context:(id)aContext
{
    if (!aFunction || anObject === undefined)
        return CPNotFound;

    var mid, c, first = 0, last = length - 1;
    while (first <= last)
    {
        mid = FLOOR((first + last) / 2);
          c = aFunction(anObject, self[mid], aContext);

        if (c > 0)
            first = mid + 1;
        else if (c < 0)
            last = mid - 1;
        else
        {
            while (mid < length - 1 && aFunction(anObject, self[mid+1], aContext) == CPOrderedSame)
                mid++;

            return mid;
        }
    }

    return CPNotFound;
}

/*!
    Returns the index of <code>anObject</code> in the array, which must be sorted in the same order as
    calling sortUsingDescriptors: with the descriptors passed to this method would result in. 
    @param anObject the object to search for
    @param descriptors the array of descriptors to use to compare each item in the array that we search. the same
    descriptors should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or <code>CPNotFound</code> if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByDescriptors:(CPArray)descriptors
{
    [self indexOfObject:anObject sortedByFunction:function(lhs, rhs)
    {
        var i = 0,
            count = [descriptors count],
            result = CPOrderedSame;

        while (i < count)
            if((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;

        return result;
    }];
}

/*!
    Returns the last object in the array. If the array is empty, returns <code>nil</code>/
*/
- (id)lastObject
{
    var count = [self count];
    
    if (!count) return nil;
    
    return self[count - 1];
}

/*!
    Returns the object at index <code>anIndex</code>.
    @throws CPRangeException if <code>anIndex</code> is out of bounds
*/
- (id)objectAtIndex:(int)anIndex
{
    return self[anIndex];
}

/*!
    Returns the objects at <code>indexes</code> in a new CPArray.
    @param indexes the set of indices
    @throws CPRangeException if any of the indices is greater than or equal to the length of the array
*/
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

/*!
    Returns an enumerator describing the array sequentially
    from the first to the last element. You should not modify
    the array during enumeration.
*/
- (CPEnumerator)objectEnumerator
{
    return [[_CPArrayEnumerator alloc] initWithArray:self];
}

/*!
    Returns an enumerator describing the array sequentially
    from the last to the first element. You should not modify
    the array during enumeration.
*/
- (CPEnumerator)reverseObjectEnumerator
{
    return [[_CPReverseArrayEnumerator alloc] initWithArray:self];
}

// Sending messages to elements
/*!
    Sends each element in the array a message.
    @param aSelector the selector of the message to send
    @throws CPInvalidArgumentException if <code>aSelector</code> is <code>nil</code>
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException reason:"makeObjectsPerformSelector: 'aSelector' can't be nil"];
    
    var index = 0, 
        count = length;
        
    for(; index < count; ++index)
        objj_msgSend(self[index], aSelector);
}

/*!
    Sends each element in the array a message with an argument.
    @param aSelector the selector of the message to send
    @param anObject the first argument of the message
    @throws CPInvalidArgumentException if <code>aSelector</code> is <code>nil</code>
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException reason:"makeObjectsPerformSelector:withObject 'aSelector' can't be nil"];

    var index = 0, 
        count = length;
        
    for(; index < count; ++index) 
        objj_msgSend(self[index], aSelector, anObject);
}

// Comparing arrays
/*!
    Returns the first object found in the receiver (starting at index 0) which is present in the
    <code>otherArray</code> as determined by using the <code>-containsObject:</code> method.
    @return the first object found, or <code>nil</code> if no common object was found.
*/
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

/*!
    Returns true if anArray contains exactly the same objects as the reciever.
*/
- (BOOL)isEqualToArray:(id)anArray
{
    if (self === anArray)
        return YES;
    
    if(length != anArray.length)
        return NO;
    
    var index = 0,
        count = [self count];
    
    for(; index < count; ++index)
    {
        var lhs = self[index],
            rhs = anArray[index];
        
        // If they're not equal, and either doesn't have an isa, or they're !isEqual (not isEqual)
        if (lhs !== rhs && (!lhs.isa || !rhs.isa || ![lhs isEqual:rhs]))
            return NO;
    }
        
    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;
    
    if(![anObject isKindOfClass:[CPArray class]])
        return NO;

    return [self isEqualToArray:anObject];
}

// Deriving new arrays
/*!
    Returns a copy of this array plus <code>anObject</code> inside the copy.
    @param anObject the object to be added to the array copy
    @throws CPInvalidArgumentException if <code>anObject</code> is <code>nil</code>
    @return a new array that should be n+1 in size compared to the receiver.
*/
- (CPArray)arrayByAddingObject:(id)anObject
{
    if (anObject === nil || anObject === undefined)
        [CPException raise:CPInvalidArgumentException
                    reason:"arrayByAddingObject: object can't be nil"];

    var array = [self copy];
    
    array.push(anObject);
    
    return array;
}

/*!
    Returns a new array which is the concatenation of <code>self</code> and otherArray (in this precise order).
    @param anArray the array that will be concatenated to the receiver's copy
*/
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

/*!
    Returns a subarray of the receiver containing the objects found in the specified range <code>aRange</code>.
    @param aRange the range of objects to be copied into the subarray
    @throws CPRangeException if the specified range exceeds the bounds of the array
*/
- (CPArray)subarrayWithRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > length)
        [CPException raise:CPRangeException reason:"subarrayWithRange: aRange out of bounds"];

    return slice(aRange.location, CPMaxRange(aRange));
}

// Sorting arrays
/*
    Not yet described.
*/
- (CPArray)sortedArrayUsingDescriptors:(CPArray)descriptors
{
    var sorted = [self copy];
    
    [sorted sortUsingDescriptors:descriptors];
    
    return sorted;
}

/*!
    Return a copy of the receiver sorted using the function passed into the first parameter.
*/
- (CPArray)sortedArrayUsingFunction:(Function)aFunction
{
    return [self sortedArrayUsingFunction:aFunction context:nil];
}

/*!
    Returns an array in which the objects are ordered according
    to a sort with <code>aFunction</code>. This invokes
    <code>-sortUsingFunction:context</code>.
    @param aFunction a JavaScript 'Function' type that compares objects
    @param aContext context information
    @return a new sorted array
*/
- (CPArray)sortedArrayUsingFunction:(Function)aFunction context:(id)aContext
{
    var sorted = [self copy];
    
    [sorted sortUsingFunction:aFunction context:aContext];
    
    return sorted;
}

/*!
    Returns a new array in which the objects are ordered according to a sort with <code>aSelector</code>.
    @param aSelector the selector that will perform object comparisons
*/
- (CPArray)sortedArrayUsingSelector:(SEL)aSelector
{
    var sorted = [self copy]
    
    [sorted sortUsingSelector:aSelector];

    return sorted;
}

// Working with string elements

/*!
    Returns a string formed by concatenating the objects in the
    receiver, with the specified separator string inserted between each part.
    If the element is a Objective-J object, then the <code>description</code>
    of that object will be used, otherwise the default JavaScript representation will be used.
    @param aString the separator that will separate each object string
    @return the string representation of the array
*/
- (CPString)componentsJoinedByString:(CPString)aString
{
    // Objective-J objects get "description" called on them automatically when coerced to strings
    // (see "objj_object.prototype.toString" at bottom of CPObject.j)
    return join(aString);
}

// Creating a description of the array

/*!
    Returns a human readable description of this array and it's elements.
*/
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
/*!
    Returns a new array subset formed by selecting the elements that have
    filename extensions from <code>filterTypes</code>. Only elements
    that are of type CPString are candidates for inclusion in the returned array.
    @param filterTypes an array of CPString objects that contain file extensions (without the '.')
    @return a new array with matching paths
*/
- (CPArray)pathsMatchingExtensions:(CPArray)filterTypes
{
    var index = 0,
        count = [self count],
        array = [];
    
    for(; index < count; ++index)
        if (self[index].isa && [self[index] isKindOfClass:[CPString class]] && [filterTypes containsObject:[self[index] pathExtension]])
            array.push(self[index]);
    
    return array;
}

// Key value coding
/*!
    Sets the key-value for each element in the array.
    @param aValue the value for the coding
    @param aKey the key for the coding
*/
- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var i = 0,
        count = [self count];
    
    for(; i < count; ++i)
        [self[i] setValue:aValue forKey:aKey];
}

/*!
    Returns the value for <code>aKey</code> from each element in the array.
    @param aKey the key to return the value for
    @return an array of containing a value for each element in the array
*/
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

/*!
    Makes a copy of the receiver.
    @return a new CPArray copy
*/
- (id)copy
{
    return slice(0);
}
    
@end

@implementation CPArray(CPMutableArray)

// Creating arrays
/*!
    Creates an array able to store at least  <code>aCapacity</code>
    items. Because CPArray is backed by JavaScript arrays,
    this method ends up simply returning a regular array.
*/
+ (CPArray)arrayWithCapacity:(unsigned)aCapacity
{
    return [[self alloc] initWithCapacity:aCapacity];
}

/*!
    Initializes an array able to store at least <code>aCapacity</code> items. Because CPArray
    is backed by JavaScript arrays, this method ends up simply returning a regular array.
*/
- (id)initWithCapacity:(unsigned)aCapacity
{
    return self;
}

// Adding and replacing objects
/*!
    Adds <code>anObject</code> to the end of the array.
    @param anObject the object to add to the array
*/
- (void)addObject:(id)anObject
{
    push(anObject);
}

/*!
    Adds the objects in <code>anArray</code> to the receiver array.
    @param anArray the array of objects to add to the end of the receiver
*/
- (void)addObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [length, 0].concat(anArray));
}

/*!
    Inserts an object into the receiver at the specified location.
    @param anObject the object to insert into the array
    @param anIndex the location to insert <code>anObject</code> at
*/
- (void)insertObject:(id)anObject atIndex:(int)anIndex
{
    splice(anIndex, 0, anObject);
}

/*!
    Inserts the objects in the provided array into the receiver at the indexes specified.
    @param objects the objects to add to this array
    @param anIndexSet the indices for the objects
*/
- (void)insertObjects:(CPArray)objects atIndexes:(CPIndexSet)indexes
{
    var indexesCount = [indexes count],
        objectsCount = [objects count];
    
    if(indexesCount !== objectsCount)
        [CPException raise:CPRangeException reason:"the counts of the passed-in array (" + objectsCount + ") and index set (" + indexesCount + ") must be identical."];
    
    var lastIndex = [indexes lastIndex];
    
    if(lastIndex >= [self count] + indexesCount)
        [CPException raise:CPRangeException reason:"the last index (" + lastIndex + ") must be less than the sum of the original count (" + [self count] + ") and the insertion count (" + indexesCount + ")."];    
    
    var index = 0,
        currentIndex = [indexes firstIndex];
 
    for (; index < objectsCount; ++index, currentIndex = [indexes indexGreaterThanIndex:currentIndex])
        [self insertObject:objects[index] atIndex:currentIndex];
}

/*!
    Replaces the element at <code>anIndex</code> with <code>anObject</code>.
    The current element at position <code>anIndex</code> will be removed from the array.
    @param anIndex the position in the array to place <code>anObject</code>
*/
- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    self[anIndex] = anObject;
}

/*!
    Replace the elements at the indices specified by <code>anIndexSet</code> with
    the objects in <code>objects</code>.
    @param anIndexSet the set of indices to array positions that will be replaced
    @param objects the array of objects to place in the specified indices
*/
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

/*!
    Replaces some of the receiver's objects with objects from <code>anArray</code>. Specifically, the elements of the
    receiver in the range specified by <code>aRange</code>,
    with the elements of <code>anArray</code> in the range specified by <code>otherRange</code>.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver
    @param otherRange the range of objects in <code>anArray</code> to pull from for placement into the receiver
*/
- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray range:(CPRange)otherRange
{
    if (!otherRange.location && otherRange.length == [anArray count])
        [self replaceObjectsInRange:aRange withObjectsFromArray:anArray];
    else
        splice.apply(self, [aRange.location, aRange.length].concat([anArray subarrayWithRange:otherRange]));
}

/*!
    Replaces some of the receiver's objects with the objects from
    <code>anArray</code>. Specifically, the elements of the
    receiver in the range specified by <code>aRange</code>.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver
*/
- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [aRange.location, aRange.length].concat(anArray));
}

/*!
    Sets the contents of the receiver to be identical to the contents of <code>anArray</code>.
    @param anArray the array of objects used to replace the receiver's objects
*/
- (void)setArray:(CPArray)anArray
{
    if(self == anArray) return;
    
    splice.apply(self, [0, length].concat(anArray));
}

// Removing Objects
/*!
    Removes all objects from this array.
*/
- (void)removeAllObjects
{
    splice(0, length);
}

/*!
    Removes the last object from the array.
*/
- (void)removeLastObject
{
    pop();
}

/*!
    Removes all entries of <code>anObject</code> from the array.
    @param anObject the object whose entries are to be removed
*/
- (void)removeObject:(id)anObject
{
    [self removeObject:anObject inRange:CPMakeRange(0, length)];
}

/*!
    Removes all entries of <code>anObject</code> from the array, in the range specified by <code>aRange</code>.
    @param anObject the object to remove
    @param aRange the range to search in the receiver for the object
*/
- (void)removeObject:(id)anObject inRange:(CPRange)aRange
{
    var index;
    
    while ((index = [self indexOfObject:anObject inRange:aRange]) != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, length - index), aRange);
    }
}

/*!
    Removes the object at <code>anIndex</code>.
    @param anIndex the location of the element to be removed
*/
- (void)removeObjectAtIndex:(int)anIndex
{
    splice(anIndex, 1);
}

/*!
    Removes the objects at the indices specified by <code>CPIndexSet</code>.
    @param anIndexSet the indices of the elements to be removed from the array
*/
- (void)removeObjectsAtIndexes:(CPIndexSet)anIndexSet
{
    var index = [anIndexSet lastIndex];
   
    while (index != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        index = [anIndexSet indexLessThanIndex:index];
    }
}

/*!
    Remove the first instance of <code>anObject</code> from the array.
    The search for the object is done using <code>==</code>.
    @param anObject the object to remove
*/
- (void)removeObjectIdenticalTo:(id)anObject
{
    [self removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, length)];
}

/*!
    Remove the first instance of <code>anObject</code> from the array,
    within the range specified by <code>aRange</code>.
    The search for the object is done using <code>==</code>.
    @param anObject the object to remove
    @param aRange the range in the array to search for the object
*/
- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    var index;
    
    while ((index = [self indexOfObjectIdenticalTo:anObject inRange:aRange]) != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, length - index), aRange);
    }
}

/*!
    Remove the objects in <code>anArray</code> from the receiver array.
    @param anArray the array of objects to remove from the receiver
*/
- (void)removeObjectsInArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];
        
    for (; index < count; ++index)
        [self removeObject:anArray[index]];
}

/*!
    Removes all the objects in the specified range from the receiver.
    @param aRange the range of objects to remove
*/
- (void)removeObjectsInRange:(CPRange)aRange
{
    splice(aRange.location, aRange.length);
}

// Rearranging objects
/*!
    Swaps the elements at the two specified indices.
    @param anIndex the first index to swap from
    @param otherIndex the second index to swap from
*/
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

/*!
    Sorts the receiver array using a JavaScript function as a comparator, and a specified context.
    @param aFunction a JavaScript function that will be called to compare objects
    @param aContext an object that will be passed to <code>aFunction</code> with comparison
*/
- (void)sortUsingFunction:(Function)aFunction context:(id)aContext
{
    sort(function(lhs, rhs) { return aFunction(lhs, rhs, aContext); });
}

/*!
    Sorts the receiver array using an Objective-J method as a comparator.
    @param aSelector the selector for the method to call for comparison
*/
- (void)sortUsingSelector:(SEL)aSelector
{
    sort(function(lhs, rhs) { return objj_msgSend(lhs, aSelector, rhs); });
}

@end

@implementation CPArray (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder decodeObjectForKey:@"CP.objects"];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder _encodeArrayOfObjects:self forKey:@"CP.objects"];
}

@end

/*!
    This class is just an empty subclass of CPArray.
    CPArray already implements mutable methods and
    this class only exists for source compatability.
*/
@implementation CPMutableArray : CPArray

@end

Array.prototype.isa = CPArray;
[CPArray initialize];

