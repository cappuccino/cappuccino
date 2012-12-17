/*!
    @class CPMutableSet
    @ingroup compatability

    This class is just an empty subclass of CPSet.
    CPSet already implements mutable methods and
    this class only exists for source compatability.
*/

@import "_CPSet.j"

@implementation CPMutableSet : CPSet

/*!
    Returns an initialized set with a given initial capacity.
    @param aCapacity, only present for compatability
*/
- (id)initWithCapacity:(unsigned)aCapacity
{
    return [self init];
}

/*!
    Creates and returns a set with a given initial capacity.
    @param aCapacity, only present for compatability
*/
+ (id)setWithCapacity:(CPUInteger)aCapacity
{
    return [[self alloc] initWithCapacity:aCapacity];
}

/*!
    Returns a set filtered using a given predicate.
    @prarm aPredicate a CPPredicate object used to filter the objects in the set.
*/- (void)filterUsingPredicate:(CPPredicate)aPredicate
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (![aPredicate evaluateWithObject:object])
            [self removeObject:object];
}

/*!
    Removes an object from the set.
    @param anObject the object to remove from the set. If the object is not in the set, the method will not modify the set.
*/
- (void)removeObject:(id)anObject
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Removes an array of objects from the set.
    @param anArray an array of object to remove from the set.
*/
- (void)removeObjectsInArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    for (; index < count; ++index)
        [self removeObject:[anArray objectAtIndex:index]];
}

/*!
    Removes all the objects from the set.
*/
- (void)removeAllObjects
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self removeObject:object];
}

/*!
    Adds to the receiver each object contained in a given array that is not already a member.
    @param array An array of objects to add to the receiver.
*/
- (void)addObjectsFromArray:(CPArray)objects
{
    var count = [objects count];

    while (count--)
        [self addObject:objects[count]];
}

/*!
    Adds to the receiver each object contained in another given set
    @param set The set of objects to add to the receiver.
*/
- (void)unionSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [aSet objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self addObject:object];
}

/*!
    Removes from the receiver each object contained in another given set that is present in the receiver.
    @param set The set of objects to remove from the receiver.
*/
- (void)minusSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [aSet objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self removeObject:object];
}

/*!
    Removes from the receiver each object that isn't a member of another given set.
    @param set The set with which to perform the intersection.
*/
- (void)intersectSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [self objectEnumerator],
        objectsToRemove = [];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (![aSet containsObject:object])
            objectsToRemove.push(object);

    var count = [objectsToRemove count];

    while (count--)
        [self removeObject:objectsToRemove[count]];
}

/*!
    Empties the receiver, then adds to the receiver each object contained in another given set.
    @param set The set whose members replace the receiver's content.
*/
- (void)setSet:(CPSet)aSet
{
    [self removeAllObjects];
    [self unionSet:aSet];
}

@end

//@import "_CPConcreteMutableSet.j"
