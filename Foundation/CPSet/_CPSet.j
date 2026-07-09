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
 */

@import "CPArray.j"
@import "CPEnumerator.j"
@import "CPException.j"
@import "CPNull.j"
@import "CPNumber.j"
@import "CPObject.j"
@import "_CPCollectionKVCOperators.j"

@class _CPConcreteMutableSet

/*!
 @class CPSet
 @ingroup Foundation
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

+ (id)set
{
	return [[self alloc] init];
}

+ (id)setWithArray:(CPArray)anArray
{
	return [[self alloc] initWithArray:anArray];
}

+ (id)setWithObject:(id)anObject
{
	return [[self alloc] initWithObjects:anObject];
}

+ (id)setWithObjects:(id)objects count:(CPUInteger)count
{
	return [[self alloc] initWithObjects:objects count:count];
}

+ (id)setWithObjects:(id)anObject, ...
{
	var argumentsArray = Array.prototype.slice.apply(arguments);

	argumentsArray[0] = [self alloc];
	argumentsArray[1] = @selector(initWithObjects:);

	return objj_msgSend.apply(this, argumentsArray);
}

+ (id)setWithSet:(CPSet)set
{
	return [[self alloc] initWithSet:set];
}

- (id)setByAddingObject:(id)anObject
{
	return [[self class] setWithArray:[[self allObjects] arrayByAddingObject:anObject]];
}

- (id)setByAddingObjectsFromSet:(CPSet)aSet
{
	return [self setByAddingObjectsFromArray:[aSet allObjects]];
}

- (id)setByAddingObjectsFromArray:(CPArray)anArray
{
	return [[self class] setWithArray:[[self allObjects] arrayByAddingObjectsFromArray:anArray]];
}

- (id)init
{
	return [self initWithObjects:nil count:0];
}

- (id)initWithArray:(CPArray)anArray
{
	return [self initWithObjects:anArray count:[anArray count]];
}

- (id)initWithObjects:(id)anObject, ...
{
	var index = 2,
	count = arguments.length;

	for (; index < count; ++index)
		if (arguments[index] === nil)
			break;

	return [self initWithObjects:Array.prototype.slice.call(arguments, 2, index) count:index - 2];
}

- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
	if (self === _CPSharedPlaceholderSet)
		return [[_CPConcreteMutableSet alloc] initWithObjects:objects count:aCount];

	return [super init];
}

- (id)initWithSet:(CPSet)aSet
{
	return [self initWithArray:[aSet allObjects]];
}

- (id)initWithSet:(CPSet)aSet copyItems:(BOOL)shouldCopyItems
{
	if (shouldCopyItems)
		return [aSet valueForKey:@"copy"];

	return [self initWithSet:aSet];
}

- (CPUInteger)count
{
	_CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPArray)allObjects
{
	var objects = [],
	object,
	objectEnumerator = [self objectEnumerator];

	while ((object = [objectEnumerator nextObject]) != nil)
		objects.push(object);

	return objects;
}

- (id)anyObject
{
	return [[self objectEnumerator] nextObject];
}

- (BOOL)containsObject:(id)anObject
{
	return [self member:anObject] != nil;
}

- (CPSet)filteredSetUsingPredicate:(CPPredicate)aPredicate
{
	var objects = [],
	object,
	objectEnumerator = [self objectEnumerator];

	while ((object = [objectEnumerator nextObject]) != nil)
		if ([aPredicate evaluateWithObject:object])
			objects.push(object);

	return [[[self class] alloc] initWithArray:objects];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector
{
	[self makeObjectsPerformSelector:aSelector withObjects:nil];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
	[self makeObjectsPerformSelector:aSelector withObjects:[anObject]];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
	var object,
	objectEnumerator = [self objectEnumerator],
	argumentsArray = [nil, aSelector].concat(objects || []);

	while ((object = [objectEnumerator nextObject]) != nil)
	{
		argumentsArray[0] = object;
		objj_msgSend.apply(this, argumentsArray);
	}
}

- (id)member:(id)anObject
{
	_CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPEnumerator)objectEnumerator
{
	_CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)enumerateObjectsUsingBlock:(Function)aFunction
{
	var object,
	objectEnumerator = [self objectEnumerator],
	shouldStop = NO;

	while (!shouldStop && (object = [objectEnumerator nextObject]) != nil) {
		if (aFunction(object, @ref(shouldStop)) !== undefined) {
			throw "DEPRECATED: The method enumerateObjectsUsingBlock: does not support returning a value in the block to stop the iteration.";
		}
	}
}

- (CPSet)objectsPassingTest:(Function)aFunction
{
	var objects = [],
	object = nil,
	objectEnumerator = [self objectEnumerator];

	while ((object = [objectEnumerator nextObject]) != nil)
		if (aFunction(object))
			objects.push(object);

	return [[[self class] alloc] initWithArray:objects];
}

- (BOOL)isSubsetOfSet:(CPSet)aSet
{
	var object = nil,
	objectEnumerator = [self objectEnumerator];

	while ((object = [objectEnumerator nextObject]) != nil)
		if (![aSet containsObject:object])
			return NO;

	return YES;
}

- (BOOL)intersectsSet:(CPSet)aSet
{
	if (self === aSet)
		return [self count] > 0;

	var object = nil,
	objectEnumerator = [self objectEnumerator];

	while ((object = [objectEnumerator nextObject]) != nil)
		if ([aSet containsObject:object])
			return YES;

	return NO;
}

- (CPArray)sortedArrayUsingDescriptors:(CPArray)someSortDescriptors
{
	return [[self allObjects] sortedArrayUsingDescriptors:someSortDescriptors];
}

- (BOOL)isEqualToSet:(CPSet)aSet
{
	return [self isEqual:aSet];
}

- (BOOL)isEqual:(CPSet)aSet
{
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

#pragma mark -
#pragma mark Category: CPCopying

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

#pragma mark -
#pragma mark Category: CPCoding

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

#pragma mark -
#pragma mark Private Allocation Placeholder

var _CPSharedPlaceholderSet = nil;

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
