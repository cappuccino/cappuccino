/*
 * CPSet.j
 * Foundation
 *
 * Created by Bailey Carlson
 * Extended by Ross Boucher
 * Extended by Nabil Elisa
 * Rewritten by Francisco Tolmasky
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
 *
 */

@import "CPArray.j"
@import "CPEnumerator.j"
@import "CPNumber.j"
@import "CPObject.j"

@class _CPConcreteMutableSet

/*!
     @class CPMutableSet
     @ingroup Foundation

     CPSet is a data structure for storing an an unordered collection of unique objects.
     Sets have O(1) insertion/lookup/deletion time complexity.
*/

@implementation CPSet : CPObject
{
}

+ (id)alloc
{
    if (self === [CPSet class] || self === [CPMutableSet class])
        return [_CPPlaceholderSet alloc];

    return [super alloc];
}

/*!
    Creates and returns an empty set.
*/
+ (id)set
{
    return [[self alloc] init];
}

/*!
    Creates and returns a set containing a uniqued collection of those objects contained in a given array.
    @param anArray array containing the objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
*/
+ (id)setWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

/*!
    Creates and returns a set that contains a single given object.
    @param anObject The object to add to the new set.
*/
+ (id)setWithObject:(id)anObject
{
    return [[self alloc] initWithObjects:anObject];
}

/*!
    Creates and returns a set containing a specified number of objects from a given array of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
    @param count The number of objects from objects to add to the new set.
*/
+ (id)setWithObjects:(id)objects count:(CPUInteger)count
{
    return [[self alloc] initWithObjects:objects count:count];
}

/*!
    Creates and returns a set containing the objects in a given argument list.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
*/
+ (id)setWithObjects:(id)anObject, ...
{
    var argumentsArray = Array.prototype.slice.apply(arguments);

    argumentsArray[0] = [self alloc];
    argumentsArray[1] = @selector(initWithObjects:);

    return objj_msgSend.apply(this, argumentsArray);
}

/*!
    Creates and returns a set containing the objects from another set.
    @param aSet A set containing the objects to add to the new set.
*/
+ (id)setWithSet:(CPSet)set
{
    return [[self alloc] initWithSet:set];
}

/*!
    Creates and returns a set by adding anObject.
    @param anObject to add to the new set.
*/
- (id)setByAddingObject:(id)anObject
{
    return [[self class] setWithArray:[[self allObjects] arrayByAddingObject:anObject]];
}

/*!
    Creates and returns a set by adding the objects from another set.
    @param aSet to add objects to add to the new set.
*/
- (id)setByAddingObjectsFromSet:(CPSet)aSet
{
    return [self setByAddingObjectsFromArray:[aSet allObjects]];
}

/*!
    Creates and returns a set by adding the objects from an array.
    @param anArray with objects to add to a new set.
*/
- (id)setByAddingObjectsFromArray:(CPArray)anArray
{
    return [[self class] setWithArray:[[self allObjects] arrayByAddingObjectsFromArray:anArray]];
}

/*!
    Basic initializer, returns an empty set.
*/
- (id)init
{
    return [self initWithObjects:nil count:0];
}

/*!
    Initializes a newly allocated set with the objects that are contained in a given array.
    @param array An array of objects to add to the new set. If the same object appears more than once in array, it is represented only once in the returned set.
*/
- (id)initWithArray:(CPArray)anArray
{
    return [self initWithObjects:anArray count:[anArray count]];
}

/*!
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once in the list, it is represented only once in the returned set.
*/
- (id)initWithObjects:(id)anObject, ...
{
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    return [self initWithObjects:Array.prototype.slice.call(arguments, 2, index) count:index - 2];
}

/*!
    Creates and returns a set containing the objects from an array.
    @param anArray An array containing the objects to add to the new set.
    @param aCount the number of objects in anArray.
*/
- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    if (self === _CPSharedPlaceholderSet)
        return [[_CPConcreteMutableSet alloc] initWithObjects:objects count:aCount];

    return [super init];
}

/*!
    Initializes a newly allocated set and adds to it objects from another given set.
    @param aSet a set containing objects to add to the new set.
*/
- (id)initWithSet:(CPSet)aSet
{
    return [self initWithArray:[aSet allObjects]];
}

/*!
    Initializes a newly allocated set and adds to it members of another given set. Only included for compatability.
    @param aSet a set of objects to add to the new set.
    @param shouldCopyItems a boolean value. If YES the objects would be copied, if NO the objects will not be copied.
*/
- (id)initWithSet:(CPSet)aSet copyItems:(BOOL)shouldCopyItems
{
    if (shouldCopyItems)
        return [aSet valueForKey:@"copy"];

    return [self initWithSet:aSet];
}

/*!
    Returns the number of members in the receiver.
*/
- (CPUInteger)count
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns an array containing the receiver’s members, or an empty array if the receiver has no members.
*/
- (CPArray)allObjects
{
    var objects = [],
        object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        objects.push(object);

    return objects;
}

/*!
    Returns one of the objects in the receiver, or nil if the receiver contains no objects.
*/
- (id)anyObject
{
    return [[self objectEnumerator] nextObject];
}

/*!
    Returns a Boolean value that indicates whether a given object is present in the receiver.
    @param anObject The object for which to test membership of the receiver.
*/
- (BOOL)containsObject:(id)anObject
{
    return [self member:anObject] !== nil;
}

/*!
    Returns a set filtered using a given predicate.
    @prarm aPredicate a CPPredicate object used to filter the objects in the set.
*/
- (CPSet)filteredSetUsingPredicate:(CPPredicate)aPredicate
{
    var objects = [],
        object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if ([aPredicate evaluateWithObject:object])
            objects.push(object);

    return [[[self class] alloc] initWithArray:objects];
}

/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the members of the receiver. The method must not take any arguments. It should not have the side effect of modifying the receiver. This value must not be NULL.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    [self makeObjectsPerformSelector:aSelector withObjects:nil];
}

/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the receiver's members. The method must take a single argument of type id. The method should not, as a side effect, modify the receiver. The value must not be NULL.
    @param anObject The object to pass as an argument to the method specified by aSelector.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    [self makeObjectsPerformSelector:aSelector withObjects:[anObject]];
}

/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the receiver's members. The method must take a single argument of type id. The method should not, as a side effect, modify the receiver. The value must not be NULL.
    @param objects The objects to pass as an argument to the method specified by aSelector.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    var object,
        objectEnumerator = [self objectEnumerator],
        argumentsArray = [nil, aSelector].concat(objects || []);

    while ((object = [objectEnumerator nextObject]) !== nil)
    {
        argumentsArray[0] = object;
        objj_msgSend.apply(this, argumentsArray);
    }
}

/*!
    Determines whether the receiver contains an object equal to a given object, and returns that object if it is present.
    @param anObject The object for which to test for membership of the receiver.
*/
- (id)member:(id)anObject
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns an object enumerator (CPEnumerator) for the receiver.
*/
- (CPEnumerator)objectEnumerator
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Enumberates over the objects in a set using a given function.
    @param aFunction a callback for each itteration, should be of the format: function(anObject).
*/
- (void)enumerateObjectsUsingBlock:(Function)aFunction
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (aFunction(object))
            break;
}

// FIXME: stop is broken.
- (CPSet)objectsPassingTest:(Function)aFunction
{
    var objects = [],
        object = nil,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (aFunction(object))
            objects.push(object);

    return [[[self class] alloc] initWithArray:objects];
}

/*!
    Returns a Boolean value that indicates whether every object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isSubsetOfSet:(CPSet)aSet
{
    var object = nil,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (![aSet containsObject:object])
            return NO;

    return YES;
}

/*!
    Returns a Boolean value that indicates whether at least one object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)intersectsSet:(CPSet)aSet
{
    if (self === aSet)
        // The empty set intersects nothing
        return [self count] > 0;

    var object = nil,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if ([aSet containsObject:object])
            return YES;

    return NO;
}

/*!
    Returns an array of the set's content sorted as specified by a given array of sort descriptors.

    @param sortDescriptors an array of CPSortDescriptor objects.
*/
- (CPArray)sortedArrayUsingDescriptors:(CPArray)someSortDescriptors
{
    return [[self allObjects] sortedArrayUsingDescriptors:someSortDescriptors];
}

/*!
    Compares the receiver to another set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isEqualToSet:(CPSet)aSet
{
    return [self isEqual:aSet];
}

/*!
    Returns YES if BOTH sets are a subset of the other.
    @param aSet a set of objects
*/
- (BOOL)isEqual:(CPSet)aSet
{
    // If both are subsets of each other, they are equal
    return  self === aSet ||
            [aSet isKindOfClass:[CPSet class]] &&
            ([self count] === [aSet count] &&
            [aSet isSubsetOfSet:self]);
}

- (CPString)description
{
    var string = "{(\n",
        objects = [self allObjects],
        index = 0,
        count = [objects count];

    for (; index < count; ++index)
    {
        var object = objects[index];

        string += "\t" + String(object).split('\n').join("\n\t") + "\n";
    }

    return string + ")}";
}

@end

@implementation CPSet (CPCopying)

- (id)copy
{
    return [[self class] setWithSet:self];
}

- (id)mutableCopy
{
    return [self copy];
}

@end

var CPSetObjectsKey = @"CPSetObjectsKey";

@implementation CPSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithArray:[aCoder decodeObjectForKey:CPSetObjectsKey]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:[self allObjects] forKey:CPSetObjectsKey];
}

@end

@implementation CPSet (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if (aKey === "@count")
        return [self count];

    var valueSet = [CPSet set],
        object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
    {
        var value = [object valueForKey:aKey];

        [valueSet addObject:value];
    }

    return valueSet;
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [object setValue:aValue forKey:aKey];
}

@end

var _CPSharedPlaceholderSet   = nil;

@implementation _CPPlaceholderSet : CPSet
{
}

+ (id)alloc
{
    if (!_CPSharedPlaceholderSet)
        _CPSharedPlaceholderSet = [super alloc];

    return _CPSharedPlaceholderSet;
}

@end

// We actually want _CPConcreteMutableSet, but this introduces the possibility of an invalid @import loop.
// This will be correctly solved when we move to true immutable/mutable pairs.
//@import "CPMutableSet.j"
