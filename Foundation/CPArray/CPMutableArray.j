
@import "CPArray.j"


/*!
    @class CPMutableArray
    @ingroup compatability

    This class is just an empty subclass of CPArray.
    CPArray already implements mutable methods and
    this class only exists for source compatability.
*/
@implementation CPMutableArray : CPArray
{
}

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
/*- (id)initWithCapacity:(unsigned)aCapacity
{
    return self;
}*/

// Adding and replacing objects
/*!
    Adds \c anObject to the end of the array.
    @param anObject the object to add to the array
*/
- (void)addObject:(id)anObject
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Adds the objects in \c anArray to the receiver array.
    @param anArray the array of objects to add to the end of the receiver
*/
- (void)addObjectsFromArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    for (; index < count; ++index)
        [self addObject:[anArray objectAtIndex:index]];
}

/*!
    Inserts an object into the receiver at the specified location.
    @param anObject the object to insert into the array
    @param anIndex the location to insert \c anObject at
*/
- (void)insertObject:(id)anObject atIndex:(int)anIndex
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
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
        [self insertObject:[objects objectAtIndex:index] atIndex:currentIndex];
}

- (unsigned)insertObject:(id)anObject inArraySortedByDescriptors:(CPArray)descriptors
{
    var index,
        count = [descriptors count];

    if (count)
        index = [self indexOfObject:anObject
                      inSortedRange:nil
                            options:CPBinarySearchingInsertionIndex
                    usingComparator:function(lhs, rhs)
        {
            var index = 0,
                result = CPOrderedSame;

            while (index < count && ((result = [[descriptors objectAtIndex:index] compareObject:lhs withObject:rhs]) === CPOrderedSame))
                ++index;

            return result;
        }];

    else
        index = [self count];

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
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Replace the elements at the indices specified by \c anIndexSet with
    the objects in \c objects.
    @param anIndexSet the set of indices to array positions that will be replaced
    @param objects the array of objects to place in the specified indices
*/
- (void)replaceObjectsAtIndexes:(CPIndexSet)indexes withObjects:(CPArray)objects
{
    var i = 0,
        index = [indexes firstIndex];

    while (index !== CPNotFound)
    {
        [self replaceObjectAtIndex:index withObject:[objects objectAtIndex:i++]];
        index = [indexes indexGreaterThanIndex:index];
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
    [self removeObjectsInRange:aRange];

    if (otherRange && (otherRange.location !== 0 || otherRange.length !== [anArray count]))
        anArray = [anArray subarrayWithRange:otherRange];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(aRange.location, [anArray count])];

    [self insertObjects:anArray atIndexes:indexes];
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
    [self replaceObjectsInRange:aRange withObjectsFromArray:anArray range:nil];
}

/*!
    Sets the contents of the receiver to be identical to the contents of \c anArray.
    @param anArray the array of objects used to replace the receiver's objects
*/
- (void)setArray:(CPArray)anArray
{
    if (self === anArray)
        return;

    [self removeAllObjects];
    [self addObjectsFromArray:anArray];
}

// Removing Objects
/*!
    Removes all objects from this array.
*/
- (void)removeAllObjects
{
    while ([self count])
        [self removeLastObject];
}

/*!
    Removes the last object from the array.
*/
- (void)removeLastObject
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
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
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Removes the objects at the indices specified by \c CPIndexSet.
    @param anIndexSet the indices of the elements to be removed from the array
*/
- (void)removeObjectsAtIndexes:(CPIndexSet)anIndexSet
{
    var index = [anIndexSet lastIndex];

    while (index !== CPNotFound)
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
        [self removeObject:[anArray objectAtIndex:index]];
}

/*!
    Removes all the objects in the specified range from the receiver.
    @param aRange the range of objects to remove
*/
- (void)removeObjectsInRange:(CPRange)aRange
{
    var index = aRange.location,
        count = CPMaxRange(aRange);

    while (count-- > index)
        [self removeObjectAtIndex:index];
}

// Rearranging objects
/*!
    Swaps the elements at the two specified indices.
    @param anIndex the first index to swap from
    @param otherIndex the second index to swap from
*/
- (void)exchangeObjectAtIndex:(unsigned)anIndex withObjectAtIndex:(unsigned)otherIndex
{
    if (anIndex === otherIndex)
        return;

    var temporary = [self objectAtIndex:anIndex];

    [self replaceObjectAtIndex:anIndex withObject:[self objectAtIndex:otherIndex]];
    [self replaceObjectAtIndex:otherIndex withObject:temporary];
}

- (void)sortUsingDescriptors:(CPArray)descriptors
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
    var h,
        i,
        j,
        k,
        l,
        m,
        n = [self count],
        o;

    var A,
        B = [];

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
