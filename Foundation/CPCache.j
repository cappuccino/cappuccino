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
@import "CPDictionary.j"
@import "CPString.j"

@class _CPCacheItem;


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

var CPCacheDelegate_cache_willEvictObject_ = 1 << 1;


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
    CPDictionary            _items;
    int                     _currentPosition;
    BOOL                    _totalCostCache;
    unsigned                _implementedDelegateMethods;

    CPString                _name               @accessors(property=name);
    int                     _countLimit         @accessors(property=countLimit);
    int                     _totalCostLimit     @accessors(property=totalCostLimit);
    id <CPCacheDelegate>    _delegate           @accessors(property=delegate);
}


#pragma mark -
#pragma mark Initialization

/*!
    Initializes the cache with default values
    @return the initialized cache
*/
- (id)init
{
    if (self = [super init])
    {
        _items = [[CPDictionary alloc] init];
        _currentPosition = 0;
        _totalCostCache = -1;
        _implementedDelegateMethods = 0;

        _name = @"";
        _countLimit = 0;
        _totalCostLimit = 0;
        _delegate = nil;
    }

    return self;
}


#pragma mark -
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

    // Invalid cost cache
    _totalCostCache = -1;

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
    [self _sendDelegateWillEvictObjectForKey:aKey];

    // Remove object
    [_items removeObjectForKey:aKey];

    // Invalid cost cache
    _totalCostCache = -1;
}

/*!
    Removes all the objects from the cache.
*/
- (void)removeAllObjects
{
    // Call delegate method to warn that the objects are going to be removed
    var enumerator = [_items keyEnumerator],
        key;

    while (key = [enumerator nextObject])
        [self _sendDelegateWillEvictObjectForKey:key]

    // Remove all objects
    [_items removeAllObjects];

    // Invalid cost cache and reset position counter
    _totalCostCache = -1;
    _currentPosition = 0;
}


#pragma mark -
#pragma mark Setters

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
        _implementedDelegateMethods |= CPCacheDelegate_cache_willEvictObject_
}


#pragma mark -
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
    if (_totalCostCache >= 0)
        return _totalCostCache;

    var enumerator = [_items objectEnumerator],
        value;

    _totalCostCache = 0;

    while (value = [enumerator nextObject])
        _totalCostCache += [value cost];

    return _totalCostCache;
}

/*
 * This method resequence the position of objects
 * Otherwise the position value could rise until to cause problem
 */
- (void)_resequencePosition
{
    _currentPosition = 1;

    // Sort keys by position
    var sortedKeys = [[_items allKeys] sortedArrayUsingFunction:
            function(k1, k2)
            {
                return [[[_items objectForKey:k1] position] compare:[[_items objectForKey:k2] position]];
            }
        ];

    // Affect new positions
    for (var i = 0; i < sortedKeys.length; ++i)
        [[_items objectForKey:sortedKeys[i]] setPosition:_currentPosition++];
}

/*
 * Check if the totalCostLimit is exceeded
 */
- (BOOL)_isTotalCostLimitExceeded
{
    return ([self _totalCost] > _totalCostLimit && _totalCostLimit > 0);
}

/*
 * Check if the countLimit is exceeded
 */
- (BOOL)_isCountLimitExceeded
{
    return ([self _count] > _countLimit && _countLimit > 0);
}

/*
 * This method clean the cache if the totalCost or the count exceeds the totalCostLimit or the countLimit
 * until to satisfy condition (totalCost < totalCostLimit and count < countLimit)
 */
- (void)_cleanCache
{
    // Check if the condition is satisfied
    if (![self _isTotalCostLimitExceeded] && ![self _isCountLimitExceeded])
        return;

    // Sort keys by position
    var sortedKeys = [[_items allKeys] sortedArrayUsingFunction:
            function(k1, k2)
            {
                return [[[_items objectForKey:k1] position] compare:[[_items objectForKey:k2] position]];
            }
        ];

    // Remove oldest objects until to satisfy the break condition
    for (var i = 0; i < sortedKeys.length; ++i)
    {
        if (![self _isTotalCostLimitExceeded] && ![self _isCountLimitExceeded])
            break;

        // Call delegate method to warn that the object is going to be removed
        [self _sendDelegateWillEvictObjectForKey:sortedKeys[i]];

        // Remove object
        [_items removeObjectForKey:sortedKeys[i]];

        // Invalid cost cache
        _totalCostCache = -1;
    }

    // Resequence position of all objects
    [self _resequencePosition];
}

@end


@implementation CPCache (CPCacheDelegate)

- (void)_sendDelegateWillEvictObjectForKey:(id)aKey
{
    if (_implementedDelegateMethods & CPCacheDelegate_cache_willEvictObject_)
        [_delegate cache:self willEvictObject:[[_items objectForKey:aKey] object]];
}

@end


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
    var cacheItem = [[self alloc] init];

    if (cacheItem)
    {
        [cacheItem setObject:anObject];
        [cacheItem setCost:aCost];
        [cacheItem setPosition:aPosition];
    }

    return cacheItem;
}

@end