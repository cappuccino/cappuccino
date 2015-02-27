/*
 * CPCache.j
 * Foundation
 *
 * Created by William Mura.
 * Copyright 2015, William Mura.
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

/*
 * Class _CPCacheItem
 * Represent an item of CPCache
 * This class allow to associate a cost and a position to an object
 *
 * Attributes:
 * - object: the stored object
 * - cost: represent the cost (of memory) of the object
 * - position: represent the insertion order to determine the oldest object
 */
@implementation _CPCacheItem : CPObject
{
    CPObject    _object      @accessors(property=object);
    int         _cost        @accessors(property=cost);
    int         _position    @accessors(property=position);
}

+ (id)cacheItemWithObject:(CPObject)anObject cost:(int)aCost position:(int)aPosition
{
    var cacheItem = [[super alloc] init];

    if (cacheItem)
    {
        cacheItem._object = anObject;
        cacheItem._cost = aCost;
        cacheItem._position = aPosition;
    }

    return cacheItem;
}

@end


/*
 * Delegate CPCacheDelegate
 *
 * - cache:willEvictObject: is called when a object is going to be removed
 * When the total cost or the count exceeds the total cost limit or the count limit
 * And also when removeObjectForKey or removeAllObjects are called
 */
@protocol CPCacheDelegate <CPObject>

@optional
- (void)cache:(CPCache)cache willEvictObject:(id)obj;

@end


var CPCacheDelegate_cache_WillEvictObject = 1 << 1;

/*!
    @class CPCache
    @ingroup foundation
    @brief A collection-like container with discardable objects

    https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSCache_Class/index.html#//apple_ref/occ/instp/NSCache/delegate

    A CPCache object is a collection-like container, or cache, that stores key-value pairs,
    similar to the CPDictionary class. Developers often incorporate caches to temporarily
    store objects with transient data that are expensive to create.

    Reusing these objects can provide performance benefits, because their values do not have to be recalculated.
    However, the objects are not critical to the application and can be discarded if memory is tight.
    If discarded, their values will have to be recomputed again when needed.
 */
@implementation CPCache : CPObject
{
    CPDictionary            _items              @accessors(readonly);  // TOFIX: delete accessors which is only needed for test
    int                     _currentPosition;
    int                     _countLimit;
    int                     _totalCostLimit;
    id <CPCacheDelegate>    _delegate;

    // Set of bit to determine which delegate has to respond
    unsigned                _implementedDelegateMethods;
}


#pragma mark Initialization

/*!
    Initializes the cache with default values
    @return the initialized cache
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _items = [[CPDictionary alloc] init];
        _currentPosition = 0;
        _countLimit = 0;
        _totalCostLimit = 0;
        _delegate = nil;
    }

    return self;
}


#pragma mark Managing cache

/*!
    Returns the object which correspond to the given key
    @param aKey the key for the object's entry
    @return the object for the entry
*/
- (id)objectForKey:(id)aKey
{
    return [[_items objectForKey:aKey] object];
}

/*!
    Adds an object with default cost into the cache.
    @param anObject the object to add in the cache
    @param aKey the object's key
*/
- (void)setObject:(id)anObject forKey:(id)aKey
{
    [self setObject:anObject forKey:aKey cost:0];
}

/*!
    Adds an object with a cost into the cache.
    @param anObject the object to add in the cache
    @param aKey the object's key
    @param aCost the object's cost
*/
- (void)setObject:(id)anObject forKey:(id)aKey cost:(int)aCost
{
    // Check if the key already exist
    if ([_items objectForKey:aKey])
        [self removeObjectForKey:aKey];

    // Add object
    [_items setObject:[_CPCacheItem cacheItemWithObject:anObject cost:aCost position:++_currentPosition] forKey:aKey];

    // Clean cache to satisfy condition (< totalCostLimit & < countLimit) if necessary
    [self _cleanCache];
}

/*!
    Removes the object from the cache for the given key.
    @param aKey the key of the object to be removed
*/
- (void)removeObjectForKey:(id)aKey
{
    // Call delegate method to warn that the object is going to be removed
    if (_implementedDelegateMethods & CPCacheDelegate_cache_WillEvictObject)
        [_delegate cache:self willEvictObject:[[_items objectForKey:aKey] object]];

    [_items removeObjectForKey:aKey];
}

/*!
    Removes all the objects from the cache.
*/
- (void)removeAllObjects
{
    _currentPosition = 0;

    // Call delegate method to warn that the objects are going to be removed
    if (_implementedDelegateMethods & CPCacheDelegate_cache_WillEvictObject)
    {
        var enumerator = [_items keyEnumerator],
            value;

        while (value = [enumerator nextObject])
            [_delegate cache:self willEvictObject:[[_items objectForKey:value] object]];
    }

    [_items removeAllObjects];
}


#pragma mark Accessors

/*!
    Returns the count limit of the cache
*/
- (int)countLimit
{
    return _countLimit;
}

/*!
    Sets the count limit of the cache.
    Remove objects if not enough place to keep all of them
    @param aCountLimit the new count limit
*/
- (void)setCountLimit:(int)aCountLimit
{
    _countLimit = aCountLimit;
    [self _cleanCache];
}

/*!
    Returns the total cost limit of the cache
*/
- (int)totalCostLimit
{
    return _totalCostLimit;
}

/*!
    Sets the total cost limit of the cache.
    Remove objects if not enough place to keep all of them
    @param aTotalCostLimit the new total cost limit
*/
- (void)setTotalCostLimit:(int)aTotalCostLimit
{
    _totalCostLimit = aTotalCostLimit;
    [self _cleanCache];
}

/*!
    Returns the cache's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the cache's delegate.
    @param aDelegate the new delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(cache:willEvictObject:)])
        _implementedDelegateMethods |= CPCacheDelegate_cache_WillEvictObject
}


#pragma mark Privates

/*
 * This method return the number of objects in the cache
 */
- (int)_count
{
    return [_items count];
}

/*
 * This method return the total cost (addition of all object's cost in the cache)
 */
- (int)_totalCost
{
    var enumerator = [_items objectEnumerator],
        cost = 0,
        value;

    while (value = [enumerator nextObject])
        cost += [value cost];

    return cost;
}

/*
 * This method resequence the position of objects
 * Otherwise the position value could rise until to cause problem
 */
- (void)_resequencePosition
{
    _currentPosition = 1;

    // Sort keys by position
    var sortedKeys = [[_items allKeys] sortedArrayUsingFunction:function(k1, k2, context)
    {
        var o1 = [_items objectForKey:k1],
            o2 = [_items objectForKey:k2];
        return ([o1 position] < [o2 position] ? CPOrderedAscending : ([o1 position] > [o2 position] ? CPOrderedDescending : CPOrderedSame));
    } context:nil];

    // Affect new positions
    for (var i = 0; i < sortedKeys.length; ++i)
        [[_items objectForKey:sortedKeys[i]] setPosition:_currentPosition++];
}

/*
 * This method clean the cache if the totalCost or the count exceeds the totalCostLimit or the countLimit
 * until to satisfy conditions (totalCost < totalCostLimit and count < countLimit)
 */
- (void)_cleanCache
{
    // Check if the condition is satisfied (totalCost < totalCostLimit and count < countLimit)
    if (([self _totalCost] > _totalCostLimit && _totalCostLimit > 0) || ([self _count] > _countLimit && _countLimit > 0))
    {
        // Sort keys by position
        var sortedKeys = [[_items allKeys] sortedArrayUsingFunction:function(k1, k2, context)
        {
            var o1 = [_items objectForKey:k1],
                o2 = [_items objectForKey:k2];
            return ([o1 position] < [o2 position] ? CPOrderedAscending : ([o1 position] > [o2 position] ? CPOrderedDescending : CPOrderedSame));
        } context:nil];

        // Remove oldest objects until to satisfy condition (totalCost < totalCostLimit and count < countLimit)
        for (var i = 0; i < sortedKeys.length; ++i)
        {
            if (!(([self _totalCost] > _totalCostLimit && _totalCostLimit > 0) || ([self _count] > _countLimit && _countLimit > 0)))
                break;

            // Call delegate method to warn that the object is going to be removed
            if (_implementedDelegateMethods & CPCacheDelegate_cache_WillEvictObject)
                [_delegate cache:self willEvictObject:[[_items objectForKey:sortedKeys[i]] object]];

            // Remove object
            [_items removeObjectForKey: sortedKeys[i]];
        }

        // Resequence position of all objects
        [self _resequencePosition];
    }
}

@end