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

@class _CPJavaScriptArray
@class CPIndexSet

CPEnumerationNormal             = 0;
CPEnumerationConcurrent         = 1 << 0;
CPEnumerationReverse            = 1 << 1;

CPBinarySearchingFirstEqual     = 1 << 8;
CPBinarySearchingLastEqual      = 1 << 9;
CPBinarySearchingInsertionIndex = 1 << 10;

var concat = Array.prototype.concat,
    join = Array.prototype.join,
    push = Array.prototype.push;

#define FORWARD_TO_CONCRETE_CLASS()\
    if (self === _CPSharedPlaceholderArray)\
    {\
        arguments[0] = [_CPJavaScriptArray alloc];\
        return objj_msgSend.apply(this, arguments);\
    }\
    return [super init];

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
    if (self === CPArray || self === CPMutableArray)
        return [_CPPlaceholderArray alloc];

    return [super alloc];
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
    arguments[0] = [self alloc];
    arguments[1] = @selector(initWithObjects:);

    return objj_msgSend.apply(this, arguments);
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
    FORWARD_TO_CONCRETE_CLASS();
}

// Creating an Array
/*!
    Creates a new CPArray from \c anArray.
    @param anArray objects in this array will be added to the new array
    @return a new CPArray containing the objects of \c anArray
*/
- (id)initWithArray:(CPArray)anArray
{
    FORWARD_TO_CONCRETE_CLASS();
}

/*!
    Initializes a the array with the contents of \c anArray
    and optionally performs a deep copy of the objects based on \c copyItems.
    @param anArray the array to copy the data from
    @param shouldCopyItems if \c YES, each object will be copied by having a \c -copy message
    sent to it, and the returned object will be added to the receiver. Otherwise, no copying will be performed.
    @return the initialized array of objects
*/
- (id)initWithArray:(CPArray)anArray copyItems:(BOOL)shouldCopyItems
{
    FORWARD_TO_CONCRETE_CLASS();
}

/*!
    initializes an array with the contents of anArray
*/
- (id)initWithObjects:(id)anObject, ...
{
    FORWARD_TO_CONCRETE_CLASS();
}

/*!
    Initializes the array with a JavaScript array of objects.
    @param objects the array of objects to add to the receiver
    @param aCount the number of objects in \c objects
    @return the initialized CPArray
*/
- (id)initWithObjects:(id)objects count:(unsigned)aCount
{
    FORWARD_TO_CONCRETE_CLASS();
}

// FIXME: This should be defined in CPMutableArray, not here.
- (id)initWithCapacity:(unsigned)aCapacity
{
    FORWARD_TO_CONCRETE_CLASS();
}

// Querying an array
/*!
    Returns \c YES if the array contains \c anObject. Otherwise, it returns \c NO.
    @param anObject the method checks if this object is already in the array
*/
- (BOOL)containsObject:(id)anObject
{
    return [self indexOfObject:anObject] !== CPNotFound;
}

- (BOOL)containsObjectIdenticalTo:(id)anObject
{
    return [self indexOfObjectIdenticalTo:anObject] !== CPNotFound;
}

/*!
    Returns the number of elements in the array
*/
- (int)count
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns the first object in the array. If the array is empty, returns \c nil
*/
- (id)firstObject
{
    var count = [self count];

    if (count > 0)
        return [self objectAtIndex:0];

    return nil;
}

/*!
    Returns the last object in the array. If the array is empty, returns \c nil
*/
- (id)lastObject
{
    var count = [self count];

    if (count <= 0)
        return nil;

    return [self objectAtIndex:count - 1];
}

/*!
    Returns the object at index \c anIndex.
    @throws CPRangeException if \c anIndex is out of bounds
*/
- (id)objectAtIndex:(int)anIndex
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
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
        objects.push([self objectAtIndex:index]);

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

/*!
    Returns the index of \c anObject in this array.
    If the object is not in the array,
    returns \c CPNotFound. It first attempts to find
    a match using \c -isEqual:, then \c ===.
    @param anObject the object to search for
*/
- (CPUInteger)indexOfObject:(id)anObject
{
    return [self indexOfObject:anObject inRange:nil];
}

/*!
    Returns the index of \c anObject in the array
    within \c aRange. It first attempts to find
    a match using \c -isEqual:, then \c ===.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (CPUInteger)indexOfObject:(id)anObject inRange:(CPRange)aRange
{
    // Only use isEqual: if our object is a CPObject.
    if (anObject && anObject.isa)
    {
        var index = aRange ? aRange.location : 0,
            count = aRange ? CPMaxRange(aRange) : [self count];

        for (; index < count; ++index)
            if ([[self objectAtIndex:index] isEqual:anObject])
                return index;

        return CPNotFound;
    }

    return [self indexOfObjectIdenticalTo:anObject inRange:aRange];
}

/*!
    Returns the index of \c anObject in the array. The test for equality is done using only \c ===.
    @param anObject the object to search for
    @return the index of the object in the array. \c CPNotFound if the object is not in the array.
*/
- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject
{
    return [self indexOfObjectIdenticalTo:anObject inRange:nil];
}

/*!
    Returns the index of \c anObject in the array
    within \c aRange. The test for equality is
    done using only \c ==.
    @param anObject the object to search for
    @param aRange the range to search within
    @return the index of the object, or \c CPNotFound if it was not found.
*/
- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    var index = aRange ? aRange.location : 0,
        count = aRange ? CPMaxRange(aRange) : [self count];

    for (; index < count; ++index)
        if ([self objectAtIndex:index] === anObject)
            return index;

    return CPNotFound;
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return \c CPNotFound to the sender.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectPassingTest:(Function /*(id anObject, int idx)*/)aPredicate
{
    return [self indexOfObjectWithOptions:CPEnumerationNormal passingTest:aPredicate context:undefined];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index, context) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return \c CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectPassingTest:(Function /*(id anObject, int idx, id context)*/)aPredicate context:(id)aContext
{
    return [self indexOfObjectWithOptions:CPEnumerationNormal passingTest:aPredicate context:aContext];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param options Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectWithOptions:(CPEnumerationOptions)options passingTest:(Function /*(id anObject, int idx)*/)aPredicate
{
    return [self indexOfObjectWithOptions:options passingTest:aPredicate context:undefined];
}

/*!
    Returns the index of the first object in the receiver that passes a test in a given Javascript function.
    @param options Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index, context) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return The index of the first matching object, or \c CPNotFound if there is no matching object.
*/
- (unsigned)indexOfObjectWithOptions:(CPEnumerationOptions)options passingTest:(Function /*(id anObject, int idx, id context)*/)aPredicate context:(id)aContext
{
    // We don't use an enumerator because they return nil to indicate end of enumeration,
    // but nil may actually be the value we are looking for, so we have to loop over the array.
    if (options & CPEnumerationReverse)
    {
        var index = [self count] - 1,
            stop = -1,
            increment = -1;
    }
    else
    {
        var index = 0,
            stop = [self count],
            increment = 1;
    }

    for (; index !== stop; index += increment)
        if (aPredicate([self objectAtIndex:index], index, aContext))
            return index;

    return CPNotFound;
}

- (CPUInteger)indexOfObject:(id)anObject
              inSortedRange:(CPRange)aRange
                    options:(CPBinarySearchingOptions)options
            usingComparator:(Function)aComparator
{
    // FIXME: comparator is not a function
    if (!aComparator)
        _CPRaiseInvalidArgumentException(self, _cmd, "comparator is nil");

    if ((options & CPBinarySearchingFirstEqual) && (options & CPBinarySearchingLastEqual))
        _CPRaiseInvalidArgumentException(self, _cmd,
            "both CPBinarySearchingFirstEqual and CPBinarySearchingLastEqual options cannot be specified");

    var count = [self count];

    if (count <= 0)
        return (options & CPBinarySearchingInsertionIndex) ? 0 : CPNotFound;

    var first = aRange ? aRange.location : 0,
        last = (aRange ? CPMaxRange(aRange) : [self count]) - 1;

    if (first < 0)
        _CPRaiseRangeException(self, _cmd, first, count);

    if (last >= count)
        _CPRaiseRangeException(self, _cmd, last, count);

    while (first <= last)
    {
        var middle = FLOOR((first + last) / 2),
            result = aComparator(anObject, [self objectAtIndex:middle]);

        if (result > 0)
            first = middle + 1;

        else if (result < 0)
            last = middle - 1;

        else
        {
            if (options & CPBinarySearchingFirstEqual)
                while (middle > first && aComparator(anObject, [self objectAtIndex:middle - 1]) === CPOrderedSame)
                    --middle;

            else if (options & CPBinarySearchingLastEqual)
            {
                while (middle < last && aComparator(anObject, [self objectAtIndex:middle + 1]) === CPOrderedSame)
                    ++middle;

                if (options & CPBinarySearchingInsertionIndex)
                    ++middle;
            }

            return middle;
        }
    }

    if (options & CPBinarySearchingInsertionIndex)
        return MAX(first, 0);

    return CPNotFound;
}

/*!
    Returns the indexes of the objects in the receiver that pass a test in a given Javascript function.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return \c CPNotFound to the sender.
    @return A CPIndexSet of the matching object indexes.
*/
- (CPIndexSet)indexesOfObjectsPassingTest:(Function /*(id anObject, int idx)*/)aPredicate
{
    return [self indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:aPredicate context:undefined];
}

/*!
    Returns the indexes of the objects in the receiver that pass a test in a given Javascript function.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index, context) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return \c CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return A CPIndexSet of the matching object indexes.
*/
- (CPIndexSet)indexesOfObjectsPassingTest:(Function /*(id anObject, int idx, id context)*/)aPredicate context:(id)aContext
{
    return [self indexesOfObjectsWithOptions:CPEnumerationNormal passingTest:aPredicate context:aContext];
}

/*!
    Returns the indexes of the objects in the receiver that pass a test in a given Javascript function.
    @param options Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @return A CPIndexSet of the matching object indexes.
*/
- (CPIndexSet)indexesOfObjectsWithOptions:(CPEnumerationOptions)options passingTest:(Function /*(id anObject, int idx)*/)aPredicate
{
    return [self indexesOfObjectsWithOptions:options passingTest:aPredicate context:undefined];
}

/*!
    Returns the indexes of the objects in the receiver that pass a test in a given Javascript function.
    @param options Specifies the direction in which the array is searched. Pass CPEnumerationNormal to search forwards
    or CPEnumerationReverse to search in reverse.
    @param predicate The function to apply to objects of the array. The function should have the signature:
    @code function(object, index, context) @endcode
    The predicate function should either return a Boolean value that indicates whether the object passed the test,
    or nil to stop the search, which will return CPNotFound to the sender.
    @param context An object that contains context information you want passed to the predicate function.
    @return A CPIndexSet of the matching object indexes.
*/
- (CPIndexSet)indexesOfObjectsWithOptions:(CPEnumerationOptions)options passingTest:(Function /*(id anObject, int idx, id context)*/)aPredicate context:(id)aContext
{
    // We don't use an enumerator because they return nil to indicate end of enumeration,
    // but nil may actually be the value we are looking for, so we have to loop over the array.
    if (options & CPEnumerationReverse)
    {
        var index = [self count] - 1,
            stop = -1,
            increment = -1;
    }
    else
    {
        var index = 0,
            stop = [self count],
            increment = 1;
    }

    var indexes = [CPIndexSet indexSet];

    for (; index !== stop; index += increment)
        if (aPredicate([self objectAtIndex:index], index, aContext))
            [indexes addIndex:index];

    return indexes;
}

// Sending messages to elements
/*!
    Sends each element in the array a message.
    @param aSelector the selector of the message to send
    @throws CPInvalidArgumentException if \c aSelector is \c nil
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    [self makeObjectsPerformSelector:aSelector withObjects:nil];
}

/*!
    Sends each element in the array a message with an argument.
    @param aSelector the selector of the message to send
    @param anObject the first argument of the message
    @throws CPInvalidArgumentException if \c aSelector is \c nil
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    return [self makeObjectsPerformSelector:aSelector withObjects:[anObject]];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException
                    reason:"makeObjectsPerformSelector:withObjects: 'aSelector' can't be nil"];

    var index = 0,
        count = [self count];

    if ([objects count])
    {
        var argumentsArray = [[nil, aSelector] arrayByAddingObjectsFromArray:objects];

        for (; index < count; ++index)
        {
            argumentsArray[0] = [self objectAtIndex:index];
            objj_msgSend.apply(this, argumentsArray);
        }
    }

    else
        for (; index < count; ++index)
            objj_msgSend([self objectAtIndex:index], aSelector);
}

- (void)enumerateObjectsUsingBlock:(Function /*(id anObject, int idx, @ref BOOL stop)*/)aFunction
{
    // This could have been [self enumerateObjectsWithOptions:CPEnumerationNormal usingBlock:aFunction]
    // but this method should be as fast as possible.
    var index = 0,
        count = [self count],
        shouldStop = NO,
        shouldStopRef = @ref(shouldStop);

    for (; index < count; ++index)
    {
        aFunction([self objectAtIndex:index], index, shouldStopRef);

        if (shouldStop)
            return;
    }
}

- (void)enumerateObjectsWithOptions:(CPEnumerationOptions)options usingBlock:(Function /*(id anObject, int idx, @ref BOOL stop)*/)aFunction
{
    if (options & CPEnumerationReverse)
    {
        var index = [self count] - 1,
            stop = -1,
            increment = -1;
    }
    else
    {
        var index = 0,
            stop = [self count],
            increment = 1;
    }

    var shouldStop = NO,
        shouldStopRef = @ref(shouldStop);

    for (; index !== stop; index += increment)
    {
        aFunction([self objectAtIndex:index], index, shouldStopRef);

        if (shouldStop)
            return;
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
    var count = [self count];

    if (![anArray count] || !count)
        return nil;

    var index = 0;

    for (; index < count; ++index)
    {
        var object = [self objectAtIndex:index];

        if ([anArray containsObject:object])
            return object;
    }

    return nil;
}

/*!
    Returns true if anArray contains exactly the same objects as the receiver.
*/
- (BOOL)isEqualToArray:(id)anArray
{
    if (self === anArray)
        return YES;

    if (![anArray isKindOfClass:CPArray])
        return NO;

    var count = [self count],
        otherCount = [anArray count];

    if (anArray === nil || count !== otherCount)
        return NO;

    var index = 0;

    for (; index < count; ++index)
    {
        var lhs = [self objectAtIndex:index],
            rhs = [anArray objectAtIndex:index];

        // If they're not equal, and either doesn't have an isa, or they're !isEqual (not isEqual)
        if (lhs !== rhs && (lhs && !lhs.isa || rhs && !rhs.isa || ![lhs isEqual:rhs]))
            return NO;
    }

    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    return (self === anObject) || [self isEqualToArray:anObject];
}

- (Array)_javaScriptArrayCopy
{
    var index = 0,
        count = [self count],
        copy = [];

    for (; index < count; ++index)
        push.call(copy, [self objectAtIndex:index]);

    return copy;
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
    var argumentArray = [self _javaScriptArrayCopy];

    // We push instead of concat,because concat flattens arrays, so if the object
    // passed in is an array, we end up with its contents added instead of itself.
    push.call(argumentArray, anObject);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
}

/*!
    Returns a new array which is the concatenation of \c self and otherArray (in this precise order).
    @param anArray the array that will be concatenated to the receiver's copy
*/
- (CPArray)arrayByAddingObjectsFromArray:(CPArray)anArray
{
    if (!anArray)
        return [self copy];

    var anArray = anArray.isa === _CPJavaScriptArray ? anArray : [anArray _javaScriptArrayCopy],
        argumentArray = concat.call([self _javaScriptArrayCopy], anArray);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
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
    if (!aRange)
        return [self copy];

    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:"subarrayWithRange: aRange out of bounds"];

    var index = aRange.location,
        count = CPMaxRange(aRange),
        argumentArray = [];

    for (; index < count; ++index)
        push.call(argumentArray, [self objectAtIndex:index]);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
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
    return join.call([self _javaScriptArrayCopy], aString);
}

// Creating a description of the array

/*!
    Returns a human readable description of this array and it's elements.
*/
- (CPString)description
{
    var index = 0,
        count = [self count],
        description = "@[";

    for (; index < count; ++index)
    {
        if (index === 0)
            description += "\n";

        var object = [self objectAtIndex:index];

        // NOTE: replace(/^/mg, "    ") inserts 4 spaces at the beginning of every line
        description += CPDescriptionOfObject(object).replace(/^/mg, "    ");

        if (index < count - 1)
            description += ",\n";
        else
            description += "\n";
    }

    return description + "]";
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

// Copying arrays

/*!
    Makes a copy of the receiver.
    @return a new CPArray copy
*/
- (id)copy
{
    return [[self class] arrayWithArray:self];
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

var _CPSharedPlaceholderArray   = nil;

@implementation _CPPlaceholderArray : CPArray
{
}

+ (id)alloc
{
    if (!_CPSharedPlaceholderArray)
        _CPSharedPlaceholderArray = [super alloc];

    return _CPSharedPlaceholderArray;
}

@end

//@import "_CPJavaScriptArray.j"
