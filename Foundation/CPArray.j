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

@import "CPEnumerator.j"
@import "CPException.j"
@import "CPObject.j"
@import "CPRange.j"
@import "CPSortDescriptor.j"

CPEnumerationNormal     = 0;
CPEnumerationConcurrent = 1 << 0;
CPEnumerationReverse    = 1 << 1;

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

/*!
    @class CPArray
    @brief A mutable array backed by a JavaScript Array.
    @ingroup foundation

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
    Creates a new array containing the objects in \c anArray.
    @param anArray Objects in this array will be added to the new array
    @return a new CPArray of the provided objects
*/
+ (id)arrayWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

/*!
    Creates a new array with \c anObject in it.
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
        count = arguments.length;

    for (; i < count; ++i)
        array.push(arguments[i]);

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
    Creates a new CPArray from \c anArray.
    @param anArray objects in this array will be added to the new array
    @return a new CPArray containing the objects of \c anArray
*/
- (id)initWithArray:(CPArray)anArray
{
    self = [super init];

    if (self)
        [self setArray:anArray];

    return self;
}

/*!
    Initializes a the array with the contents of \c anArray
    and optionally performs a deep copy of the objects based on \c copyItems.
    @param anArray the array to copy the data from
    @param copyItems if \c YES, each object will be copied by having a \c -copy message sent to it, and the
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

        for (; index < count; ++index)
        {
            if (anArray[index].isa)
                self[index] = [anArray[index] copy];
            // Do a deep/shallow copy?
            else
                self[index] = anArray[index];
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
        count = arguments.length;

    for (; i < count; ++i)
        push(arguments[i]);

    return self;
}

/*!
    Initializes the array with a JavaScript array of objects.
    @param objects the array of objects to add to the receiver
    @param aCount the number of objects in \c objects
    @return the initialized CPArray
*/
- (id)initWithObjects:(id)objects count:(unsigned)aCount
{
    self = [super init];

    if (self)
    {
        var index = 0;

        for (; index < aCount; ++index)
            push(objects[index]);
    }

    return self;
}

// Querying an array
/*!
    Returns \c YES if the array contains \c anObject. Otherwise, it returns \c NO.
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
    Returns the index of \c anObject in this array.
    If the object is not in the array,
    returns \c CPNotFound. It first attempts to find
    a match using \c -isEqual:, then \c ===.
    @param anObject the object to search for
*/
- (int)indexOfObject:(id)anObject
{
    var i = 0,
        count = length;

    // Only use -isEqual: if our object is a CPObject.
    if (anObject && anObject.isa)
    {
        for (; i < count; ++i)
            if ([self[i] isEqual:anObject])
                return i;
    }
    // If indexOf exists, use it since it's probably
    // faster than anything we can implement.
    else if (self.indexOf)
        return indexOf(anObject);
    // Last resort, do a straight forward linear O(N) search.
    else
        for (; i < count; ++i)
            if (self[i] === anObject)
                return i;

    return CPNotFound;
}

/*!
    Returns the index of \c anObject in the array
    within \c aRange. It first attempts to find
    a match using \c -isEqual:, then \c ===.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (int)indexOfObject:(id)anObject inRange:(CPRange)aRange
{
    var i = aRange.location,
        count = MIN(CPMaxRange(aRange), length);

    // Only use isEqual: if our object is a CPObject.
    if (anObject && anObject.isa)
    {
        for (; i < count; ++i)
            if ([self[i] isEqual:anObject])
                return i;
    }
    // Last resort, do a straight forward linear O(N) search.
    else
        for (; i < count; ++i)
            if (self[i] === anObject)
                return i;

    return CPNotFound;
}

/*!
    Returns the index of \c anObject in the array. The test for equality is done using only \c ===.
    @param anObject the object to search for
    @return the index of the object in the array. \c CPNotFound if the object is not in the array.
*/
- (int)indexOfObjectIdenticalTo:(id)anObject
{
    // If indexOf exists, use it since it's probably
    // faster than anything we can implement.
    if (self.indexOf)
        return indexOf(anObject);

    // Last resort, do a straight forward linear O(N) search.
    else
    {
        var index = 0,
            count = length;

        for (; index < count; ++index)
            if (self[index] === anObject)
                return index;
    }

    return CPNotFound;
}

/*!
    Returns the index of \c anObject in the array
    within \c aRange. The test for equality is
    done using only \c ==.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (int)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
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

        for (; index < count; ++index)
            if (self[index] == anObject)
                return index;
    }

    return CPNotFound;
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param predicate The function to apply to elements of the array. The function receives two arguments:
                     object The element in the array.
                     index  The index of the element in the array.
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectPassingTest:(Function)predicate
{
    return [self indexOfObjectWithOptions:CPEnumerationNormal passingTest:predicate context:undefined];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param predicate The function to apply to elements of the array. The function receives two arguments:
                     object  The element in the array.
                     index   The index of the element in the array.
                     context The object passed to the receiver in the aContext parameter.
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectPassingTest:(Function)predicate context:(id)aContext
{
    return [self indexOfObjectWithOptions:CPEnumerationNormal passingTest:predicate context:aContext];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param opts Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to elements of the array. The function receives two arguments:
                     object The element in the array.
                     index  The index of the element in the array.
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectWithOptions:(CPEnumerationOptions)opts passingTest:(Function)predicate
{
    return [self indexOfObjectWithOptions:opts passingTest:predicate context:undefined];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param opts Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to elements of the array. The function receives two arguments:
                     object  The element in the array.
                     index   The index of the element in the array.
                     context The object passed to the receiver in the aContext parameter.
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectWithOptions:(CPEnumerationOptions)opts passingTest:(Function)predicate context:(id)aContext
{
    // We don't use an enumerator because they return nil to indicate end of enumeration,
    // but nil may actually be the value we are looking for, so we have to loop over the array.

    var start, stop, increment;

    if (opts & CPEnumerationReverse)
    {
        start = [self count] - 1;
        stop = -1;
        increment = -1;
    }
    else
    {
        start = 0;
        stop = [self count];
        increment = 1;
    }

    for (var i = start; i != stop; i += increment)
    {
        var result = predicate([self objectAtIndex:i], i, aContext);

        if (typeof result === 'boolean' && result)
            return i;
        else if (typeof result === 'object' && result == nil)
            return CPNotFound;
    }

    return CPNotFound;
}

/*!
    Returns the index of \c anObject in the array, which must be sorted in the same order as
    calling sortUsingSelector: with the selector passed to this method would result in.
    @param anObject the object to search for
    @param aSelector the comparison selector to call on each item in the list, the same
    selector should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedBySelector:(SEL)aSelector
{
    return [self indexOfObject:anObject sortedByFunction:function(lhs, rhs) { objj_msgSend(lhs, aSelector, rhs); }];
}

/*!
    Returns the index of \c anObject in the array, which must be sorted in the same order as
    calling sortUsingFunction: with the selector passed to this method would result in.
    The function will be called like so:
    <pre>
    aFunction(anObject, currentObjectInArrayForComparison)
    </pre>
    @param anObject the object to search for
    @param aFunction the comparison function to call on each item in the array that we search. the same
    selector should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByFunction:(Function)aFunction
{
    return [self indexOfObject:anObject sortedByFunction:aFunction context:nil];
}

/*!
    Returns the index of \c anObject in the array, which must be sorted in the same order as
    calling sortUsingFunction: with the selector passed to this method would result in.
    The function will be called like so:
    <pre>
    aFunction(anObject, currentObjectInArrayForComparison, context)
    </pre>
    @param anObject the object to search for
    @param aFunction the comparison function to call on each item in the array that we search. the same
    function should have been used to sort the array (or to maintain its sorted order).
    @param aContext a context object that will be passed to the sort function
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByFunction:(Function)aFunction context:(id)aContext
{
    var result = [self _indexOfObject:anObject sortedByFunction:aFunction context:aContext];
    return result >= 0 ? result : CPNotFound;
}

- (unsigned)_indexOfObject:(id)anObject sortedByFunction:(Function)aFunction context:(id)aContext
{
    if (!aFunction)
        return CPNotFound;

    if (length === 0)
        return -1;

    var mid,
        c,
        first = 0,
        last = length - 1;

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
            while (mid < length - 1 && aFunction(anObject, self[mid + 1], aContext) == CPOrderedSame)
                mid++;

            return mid;
        }
    }

    return -first - 1;
}

/*!
    Returns the index of \c anObject in the array, which must be sorted in the same order as
    calling sortUsingDescriptors: with the descriptors passed to this method would result in.
    @param anObject the object to search for
    @param descriptors the array of descriptors to use to compare each item in the array that we search. the same
    descriptors should have been used to sort the array (or to maintain its sorted order).
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (unsigned)indexOfObject:(id)anObject sortedByDescriptors:(CPArray)descriptors
{
    var count = [descriptors count];

    return [self indexOfObject:anObject sortedByFunction:function(lhs, rhs)
    {
        var i = 0,
            result = CPOrderedSame;

        while (i < count)
            if ((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;

        return result;
    }];
}

- (unsigned)insertObject:(id)anObject inArraySortedByDescriptors:(CPArray)descriptors
{
    if (!descriptors || ![descriptors count])
    {
        [self addObject:anObject];
        return [self count] - 1;
    }

    var index = [self _insertObject:anObject sortedByFunction:function(lhs, rhs)
    {
        var i = 0,
            count = [descriptors count],
            result = CPOrderedSame;

        while (i < count)
            if ((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;

        return result;
    } context:nil];

    if (index < 0)
        index = -result-1;

    [self insertObject:anObject atIndex:index];
    return index;
}

/*!
    Returns the last object in the array. If the array is empty, returns \c nil/
*/
- (id)lastObject
{
    var count = [self count];

    if (!count)
        return nil;

    return self[count - 1];
}

/*!
    Returns the object at index \c anIndex.
    @throws CPRangeException if \c anIndex is out of bounds
*/
- (id)objectAtIndex:(int)anIndex
{
    if (anIndex >= length || anIndex < 0)
        [CPException raise:CPRangeException reason:@"index (" + anIndex + @") beyond bounds (" + length + @")"];

    return self[anIndex];
}

/*!
    Returns the objects at \c indexes in a new CPArray.
    @param indexes the set of indices
    @throws CPRangeException if any of the indices is greater than or equal to the length of the array
*/
- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    var index = CPNotFound,
        objects = [];

    while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound)
        [objects addObject:[self objectAtIndex:index]];

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
    @throws CPInvalidArgumentException if \c aSelector is \c nil
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException reason:"makeObjectsPerformSelector: 'aSelector' can't be nil"];

    var index = 0,
        count = length;

    for (; index < count; ++index)
        objj_msgSend(self[index], aSelector);
}

/*!
    Sends each element in the array a message with an argument.
    @param aSelector the selector of the message to send
    @param anObject the first argument of the message
    @throws CPInvalidArgumentException if \c aSelector is \c nil
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException reason:"makeObjectsPerformSelector:withObject 'aSelector' can't be nil"];

    var index = 0,
        count = length;

    for (; index < count; ++index)
        objj_msgSend(self[index], aSelector, anObject);
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException reason:"makeObjectsPerformSelector:withObjects: 'aSelector' can't be nil"];

    var index = 0,
        count = length,
        argumentsArray = [nil, aSelector].concat(objects || []);

    for (; index < count; ++index)
    {
        argumentsArray[0] = self[index];
        objj_msgSend.apply(this, argumentsArray);
    }
}


// Comparing arrays
/*!
    Returns the first object found in the receiver (starting at index 0) which is present in the
    \c otherArray as determined by using the \c -containsObject: method.
    @return the first object found, or \c nil if no common object was found.
*/
- (id)firstObjectCommonWithArray:(CPArray)anArray
{
    if (![anArray count] || ![self count])
        return nil;

    var i = 0,
        count = [self count];

    for (; i < count; ++i)
        if ([anArray containsObject:self[i]])
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

    if (anArray === nil || length !== anArray.length)
        return NO;

    var index = 0,
        count = [self count];

    for (; index < count; ++index)
    {
        var lhs = self[index],
            rhs = anArray[index];

        // If they're not equal, and either doesn't have an isa, or they're !isEqual (not isEqual)
        if (lhs !== rhs && (lhs && !lhs.isa || rhs && !rhs.isa || ![lhs isEqual:rhs]))
            return NO;
    }

    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (![anObject isKindOfClass:[CPArray class]])
        return NO;

    return [self isEqualToArray:anObject];
}

// Deriving new arrays
/*!
    Returns a copy of this array plus \c anObject inside the copy.
    @param anObject the object to be added to the array copy
    @throws CPInvalidArgumentException if \c anObject is \c nil
    @return a new array that should be n+1 in size compared to the receiver.
*/
- (CPArray)arrayByAddingObject:(id)anObject
{
    var array = [self copy];
    array.push(anObject);

    return array;
}

/*!
    Returns a new array which is the concatenation of \c self and otherArray (in this precise order).
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

    for (; i<count; ++i)
        if (aPredicate.evaluateWithObject(self[i]))
            array.push(self[i]);

    return array;
}
*/

/*!
    Returns a subarray of the receiver containing the objects found in the specified range \c aRange.
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
    to a sort with \c aFunction. This invokes
    \c -sortUsingFunction:context.
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
    Returns a new array in which the objects are ordered according to a sort with \c aSelector.
    @param aSelector the selector that will perform object comparisons
*/
- (CPArray)sortedArrayUsingSelector:(SEL)aSelector
{
    var sorted = [self copy];

    [sorted sortUsingSelector:aSelector];

    return sorted;
}

// Working with string elements

/*!
    Returns a string formed by concatenating the objects in the
    receiver, with the specified separator string inserted between each part.
    If the element is a Objective-J object, then the \c -description
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
    var index = 0,
        count = [self count],
        description = '(';

    for (; index < count; ++index)
    {
        if (index === 0)
            description += '\n';

        var object = [self objectAtIndex:index],
            objectDescription = object && object.isa ? [object description] : String(object);

        description += "\t" + objectDescription.split('\n').join("\n\t");

        if (index !== count - 1)
            description += ", ";

        description += '\n';
    }

    return description + ')';
}

// Collecting paths
/*!
    Returns a new array subset formed by selecting the elements that have
    filename extensions from \c filterTypes. Only elements
    that are of type CPString are candidates for inclusion in the returned array.
    @param filterTypes an array of CPString objects that contain file extensions (without the '.')
    @return a new array with matching paths
*/
- (CPArray)pathsMatchingExtensions:(CPArray)filterTypes
{
    var index = 0,
        count = [self count],
        array = [];

    for (; index < count; ++index)
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

    for (; i < count; ++i)
        [self[i] setValue:aValue forKey:aKey];
}

/*!
    Returns the value for \c aKey from each element in the array.
    @param aKey the key to return the value for
    @return an array of containing a value for each element in the array
*/
- (CPArray)valueForKey:(CPString)aKey
{
    var i = 0,
        count = [self count],
        array = [];

    for (; i < count; ++i)
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

@implementation CPArray (CPMutableArray)

// Creating arrays
/*!
    Creates an array able to store at least  \c aCapacity
    items. Because CPArray is backed by JavaScript arrays,
    this method ends up simply returning a regular array.
*/
+ (CPArray)arrayWithCapacity:(unsigned)aCapacity
{
    return [[self alloc] initWithCapacity:aCapacity];
}

/*!
    Initializes an array able to store at least \c aCapacity items. Because CPArray
    is backed by JavaScript arrays, this method ends up simply returning a regular array.
*/
- (id)initWithCapacity:(unsigned)aCapacity
{
    return self;
}

// Adding and replacing objects
/*!
    Adds \c anObject to the end of the array.
    @param anObject the object to add to the array
*/
- (void)addObject:(id)anObject
{
    push(anObject);
}

/*!
    Adds the objects in \c anArray to the receiver array.
    @param anArray the array of objects to add to the end of the receiver
*/
- (void)addObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [length, 0].concat(anArray));
}

/*!
    Inserts an object into the receiver at the specified location.
    @param anObject the object to insert into the array
    @param anIndex the location to insert \c anObject at
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

    if (indexesCount !== objectsCount)
        [CPException raise:CPRangeException reason:"the counts of the passed-in array (" + objectsCount + ") and index set (" + indexesCount + ") must be identical."];

    var lastIndex = [indexes lastIndex];

    if (lastIndex >= [self count] + indexesCount)
        [CPException raise:CPRangeException reason:"the last index (" + lastIndex + ") must be less than the sum of the original count (" + [self count] + ") and the insertion count (" + indexesCount + ")."];

    var index = 0,
        currentIndex = [indexes firstIndex];

    for (; index < objectsCount; ++index, currentIndex = [indexes indexGreaterThanIndex:currentIndex])
        [self insertObject:objects[index] atIndex:currentIndex];
}

- (unsigned)insertObject:(id)anObject inArraySortedByDescriptors:(CPArray)descriptors
{
    var count = [descriptors count];

    var index = [self _indexOfObject:anObject sortedByFunction:function(lhs, rhs)
    {
        var i = 0,
            result = CPOrderedSame;

        while (i < count)
            if ((result = [descriptors[i++] compareObject:lhs withObject:rhs]) != CPOrderedSame)
                return result;

        return result;
    } context:nil];

    if (index < 0)
        index = -index - 1;

    [self insertObject:anObject atIndex:index];
    return index;
}

/*!
    Replaces the element at \c anIndex with \c anObject.
    The current element at position \c anIndex will be removed from the array.
    @param anIndex the position in the array to place \c anObject
*/
- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    self[anIndex] = anObject;
}

/*!
    Replace the elements at the indices specified by \c anIndexSet with
    the objects in \c objects.
    @param anIndexSet the set of indices to array positions that will be replaced
    @param objects the array of objects to place in the specified indices
*/
- (void)replaceObjectsAtIndexes:(CPIndexSet)anIndexSet withObjects:(CPArray)objects
{
    var i = 0,
        index = [anIndexSet firstIndex];

    while (index != CPNotFound)
    {
        [self replaceObjectAtIndex:index withObject:objects[i++]];
        index = [anIndexSet indexGreaterThanIndex:index];
    }
}

/*!
    Replaces some of the receiver's objects with objects from \c anArray. Specifically, the elements of the
    receiver in the range specified by \c aRange,
    with the elements of \c anArray in the range specified by \c otherRange.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver
    @param otherRange the range of objects in \c anArray to pull from for placement into the receiver
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
    \c anArray. Specifically, the elements of the
    receiver in the range specified by \c aRange.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver
*/
- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray
{
    splice.apply(self, [aRange.location, aRange.length].concat(anArray));
}

/*!
    Sets the contents of the receiver to be identical to the contents of \c anArray.
    @param anArray the array of objects used to replace the receiver's objects
*/
- (void)setArray:(CPArray)anArray
{
    if (self == anArray)
        return;

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
    Removes all entries of \c anObject from the array.
    @param anObject the object whose entries are to be removed
*/
- (void)removeObject:(id)anObject
{
    [self removeObject:anObject inRange:CPMakeRange(0, length)];
}

/*!
    Removes all entries of \c anObject from the array, in the range specified by \c aRange.
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
    Removes the object at \c anIndex.
    @param anIndex the location of the element to be removed
*/
- (void)removeObjectAtIndex:(int)anIndex
{
    splice(anIndex, 1);
}

/*!
    Removes the objects at the indices specified by \c CPIndexSet.
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
    Remove the first instance of \c anObject from the array.
    The search for the object is done using \c ==.
    @param anObject the object to remove
*/
- (void)removeObjectIdenticalTo:(id)anObject
{
    [self removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, [self count])];
}

/*!
    Remove the first instance of \c anObject from the array,
    within the range specified by \c aRange.
    The search for the object is done using \c ==.
    @param anObject the object to remove
    @param aRange the range in the array to search for the object
*/
- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    var index,
        count = [self count];

    while ((index = [self indexOfObjectIdenticalTo:anObject inRange:aRange]) !== CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, (--count) - index), aRange);
    }
}

/*!
    Remove the objects in \c anArray from the receiver array.
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
    [self sortUsingFunction:compareObjectsUsingDescriptors context:descriptors];
}

/*!
    Sorts the receiver array using a JavaScript function as a comparator, and a specified context.
    @param aFunction a JavaScript function that will be called to compare objects
    @param aContext an object that will be passed to \c aFunction with comparison
*/
- (void)sortUsingFunction:(Function)aFunction context:(id)aContext
{
    var h, i, j, k, l, m, n = [self count], o;
    var A, B = [];

    for (h = 1; h < n; h += h)
    {
        for (m = n - 1 - h; m >= 0; m -= h + h)
        {
            l = m - h + 1;
            if (l < 0)
                l = 0;

            for (i = 0, j = l; j <= m; i++, j++)
                B[i] = self[j];

            for (i = 0, k = l; k < j && j <= m + h; k++)
            {
                A = self[j];
                o = aFunction(A, B[i], aContext);
                if (o >= 0)
                    self[k] = B[i++];
                else
                {
                    self[k] = A;
                    j++;
                }
            }

            while (k < j)
                self[k++] = B[i++];
        }
    }
}

/*!
    Sorts the receiver array using an Objective-J method as a comparator.
    @param aSelector the selector for the method to call for comparison
*/
- (void)sortUsingSelector:(SEL)aSelector
{
    [self sortUsingFunction:selectorCompare context:aSelector];
}

@end

var selectorCompare = function selectorCompare(object1, object2, selector)
{
    return [object1 performSelector:selector withObject:object2];
}

// sort using sort descriptors
var compareObjectsUsingDescriptors= function compareObjectsUsingDescriptors(lhs, rhs, descriptors)
{
    var result = CPOrderedSame,
        i = 0,
        n = [descriptors count];

    while (i < n && result === CPOrderedSame)
        result = [descriptors[i++] compareObject:lhs withObject:rhs];

    return result;
}

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
    @class CPMutableArray
    @ingroup compatability

    This class is just an empty subclass of CPArray.
    CPArray already implements mutable methods and
    this class only exists for source compatability.
*/
@implementation CPMutableArray : CPArray

@end

Array.prototype.isa = CPArray;
[CPArray initialize];

