/*
 * CPNotificationCenter.j
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

@import "CPArray.j"
@import "CPDictionary.j"
@import "CPException.j"
@import "CPNotification.j"
@import "CPNull.j"
@import "CPOperationQueue.j"
@import "CPOperation.j"
@import "CPSet.j"

@class _CPNotificationRegistry

var CPNotificationDefaultCenter = nil;

/*!
    @class CPNotificationCenter
    @ingroup foundation
    @brief Sends messages (CPNotification) between objects.

    Cappuccino provides a framework for sending messages between objects within
    a process called notifications. Objects register with an
    CPNotificationCenter to be informed whenever other objects post
    CPNotifications to it matching certain criteria. The notification center
    processes notifications synchronously -- that is, control is only returned
    to the notification poster once every recipient of the notification has
    received it and processed it.
*/
@implementation CPNotificationCenter : CPObject
{
    CPMutableDictionary     _namedRegistries;
    _CPNotificationRegistry _unnamedRegistry;
}

/*!
    Returns the application's notification center
*/
+ (CPNotificationCenter)defaultCenter
{
    if (!CPNotificationDefaultCenter)
        CPNotificationDefaultCenter = [[CPNotificationCenter alloc] init];

    return CPNotificationDefaultCenter;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _namedRegistries = @{};
        _unnamedRegistry = [[_CPNotificationRegistry alloc] init];
    }

    return self;
}

/*!
    Adds an object as an observer. The observer will receive notifications with the specified name
    and/or containing the specified object (depending on if they are \c nil.
    @param anObserver the observing object
    @param aSelector the message sent to the observer when a notification occurs
    @param aNotificationName the name of the notification the observer wants to watch
    @param anObject the object in the notification the observer wants to watch
*/
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(CPString)aNotificationName object:(id)anObject
{
    var registry = [self _registryForNotificationName:aNotificationName],
        observer = [[_CPNotificationObserver alloc] initWithObserver:anObserver selector:aSelector];

    [registry addObserver:observer object:anObject];
}

/*!
    Adds an entry to the receiver’s dispatch table with a block, and optional criteria: notification name and sender.
    @param aNotificationName the name of the notification the observer wants to watch
    @param anObject the object in the notification the observer wants to watch
    @param The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
    @param block the block to be executed when the notification is received.
*/
- (id <CPObject>)addObserverForName:(CPString)aNotificationName object:(id)anObject queue:(CPOperationQueue)queue usingBlock:(Function)block
{
    var registry = [self _registryForNotificationName:aNotificationName],
        observer = [[_CPNotificationObserver alloc] initWithBlock:block queue:queue];

    [registry addObserver:observer object:anObject];

    return observer;
}

/*!
    @ignore
*/
- (_CPNotificationRegistry)_registryForNotificationName:(CPString)aNotificationName
{
    var registry;

    if (aNotificationName == nil)
        registry = _unnamedRegistry;
    else if (!(registry = [_namedRegistries objectForKey:aNotificationName]))
    {
        registry = [[_CPNotificationRegistry alloc] init];
        [_namedRegistries setObject:registry forKey:aNotificationName];
    }

    return registry;
}

/*!
    Unregisters the specified observer from all notifications.
    @param anObserver the observer to unregister
*/
- (void)removeObserver:(id)anObserver
{
    var name = nil,
        names = [_namedRegistries keyEnumerator];

    while ((name = [names nextObject]) !== nil)
        [[_namedRegistries objectForKey:name] removeObserver:anObserver object:nil];

    [_unnamedRegistry removeObserver:anObserver object:nil];
}

/*!
    Unregisters the specified observer from notifications matching the specified name and/or object.
    @param anObserver the observer to remove
    @param aNotificationName the name of notifications to no longer watch
    @param anObject notifications containing this object will no longer be watched
*/
- (void)removeObserver:(id)anObserver name:(CPString)aNotificationName object:(id)anObject
{
    if (aNotificationName == nil)
    {
        var name = nil,
            names = [_namedRegistries keyEnumerator];

        while ((name = [names nextObject]) !== nil)
            [[_namedRegistries objectForKey:name] removeObserver:anObserver object:anObject];

        [_unnamedRegistry removeObserver:anObserver object:anObject];
    }
    else
        [[_namedRegistries objectForKey:aNotificationName] removeObserver:anObserver object:anObject];
}

/*!
    Posts a notification to all observers that match the specified notification's name and object.
    @param aNotification the notification being posted
    @throws CPInvalidArgumentException if aNotification is nil
*/
- (void)postNotification:(CPNotification)aNotification
{
    if (!aNotification)
        [CPException raise:CPInvalidArgumentException reason:"postNotification: does not except 'nil' notifications"];

    _CPNotificationCenterPostNotification(self, aNotification);
}

/*!
    Posts a new notification with the specified name, object, and dictionary.
    @param aNotificationName the name of the notification name
    @param anObject the associated object
    @param aUserInfo the associated dictionary
*/
- (void)postNotificationName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
   _CPNotificationCenterPostNotification(self, [[CPNotification alloc] initWithName:aNotificationName object:anObject userInfo:aUserInfo]);
}

/*!
    Posts a new notification with the specified name and object.
    @param aNotificationName the name of the notification
    @param anObject the associated object
*/
- (void)postNotificationName:(CPString)aNotificationName object:(id)anObject
{
   _CPNotificationCenterPostNotification(self, [[CPNotification alloc] initWithName:aNotificationName object:anObject userInfo:nil]);
}

@end

var _CPNotificationCenterPostNotification = function(/* CPNotificationCenter */ self, /* CPNotification */ aNotification)
{
    [self._unnamedRegistry postNotification:aNotification];
    [[self._namedRegistries objectForKey:[aNotification name]] postNotification:aNotification];
};

/*
    Mapping of Notification Name to listening object/selector.
    @ignore
 */
@implementation _CPNotificationRegistry : CPObject
{
    CPDictionary    _objectObservers;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _objectObservers = @{};
    }

    return self;
}

- (void)addObserver:(_CPNotificationObserver)anObserver object:(id)anObject
{
    // If there's no object, then we're listening to this
    // notification regardless of whom sends it.
    if (!anObject)
        anObject = [CPNull null];

    // Grab all the listeners for this notification/object pair
    var observers = [_objectObservers objectForKey:[anObject UID]];

    if (!observers)
    {
        observers = [CPMutableSet set];
        [_objectObservers setObject:observers forKey:[anObject UID]];
    }

    // Add this observer.
    [observers addObject:anObserver];
}

- (void)removeObserver:(id)anObserver object:(id)anObject
{
    var removedKeys = [];

    // This means we're getting rid of EVERY instance of this observer.
    if (anObject == nil)
    {
        var key = nil,
            keys = [_objectObservers keyEnumerator];

        // Iterate through every set of observers
        while ((key = [keys nextObject]) !== nil)
        {
            var observers = [_objectObservers objectForKey:key],
                observer = nil,
                observersEnumerator = [observers objectEnumerator];

            while ((observer = [observersEnumerator nextObject]) !== nil)
                if ([observer observer] == anObserver ||
                    ([observer block] && [anObserver respondsToSelector:@selector(block)] && [observer block] == [anObserver block]))
                    [observers removeObject:observer];

            if (![observers count])
                removedKeys.push(key);
        }
    }
    else
    {
        var key = [anObject UID],
            observers = [_objectObservers objectForKey:key],
            observer = nil,
            observersEnumerator = [observers objectEnumerator];

        while ((observer = [observersEnumerator nextObject]) !== nil)
            if ([observer observer] == anObserver ||
                ([observer block] && [anObserver respondsToSelector:@selector(block)] && [observer block] == [anObserver block]))
                [observers removeObject:observer];

        if (![observers count])
            removedKeys.push(key);
    }

    var count = removedKeys.length;

    while (count--)
        [_objectObservers removeObjectForKey:removedKeys[count]];
}

- (void)postNotification:(CPNotification)aNotification
{
    // We don't want to erroneously send notifications to observers that get removed
    // during the posting of this notification, nor observers that get added.  The
    // best way to do this is to make a copy of the current observers (this avoids
    // new observers from being notified) and double checking every observer against
    // the current set (this avoids removed observers from receiving notifications).
    var object = [aNotification object],
        currentObservers = nil;

    if (object != nil && (currentObservers = [_objectObservers objectForKey:[object UID]]))
    {
        var observers = [currentObservers copy],
            observer = nil,
            observersEnumerator = [observers objectEnumerator];

        while ((observer = [observersEnumerator nextObject]) !== nil)
        {
            // CPSet containsObject is N(1) so this is a fast check.
            if ([currentObservers containsObject:observer])
                [observer postNotification:aNotification];
        }
    }

    // Now do the same for the nil object observers...
    currentObservers = [_objectObservers objectForKey:[[CPNull null] UID]];

    if (!currentObservers)
        return;

    var observers = [currentObservers copy],
        observersEnumerator = [observers objectEnumerator];

    while ((observer = [observersEnumerator nextObject]) !== nil)
    {
        // CPSet containsObject is N(1) so this is a fast check.
        if ([currentObservers containsObject:observer])
            [observer postNotification:aNotification];
    }
}

- (unsigned)count
{
    return [_objectObservers count];
}

@end

/* @ignore */
@implementation _CPNotificationObserver : CPObject
{
    CPOperationQueue    _operationQueue;
    id                  _observer;
    Function            _block;
    SEL                 _selector;
}

- (id)initWithObserver:(id)anObserver selector:(SEL)aSelector
{
    if (self)
    {
        _observer = anObserver;
        _selector = aSelector;
    }

   return self;
}

- (id)initWithBlock:(Function)aBlock queue:(CPOperationQueue)aQueue
{
    if (self)
    {
        _block = aBlock;
        _operationQueue = aQueue;
    }

    return self;
}

- (id)observer
{
    return _observer;
}

- (id)block
{
    return _block;
}

- (void)postNotification:(CPNotification)aNotification
{
    if (_block)
    {
        if (!_operationQueue)
            _block(aNotification);
        else
            [_operationQueue addOperation:[[_CPNotificationObserverOperation alloc] initWithBlock:_block notification:aNotification]];

        return;
    }

    [_observer performSelector:_selector withObject:aNotification];
}

@end

/* @ignore */
@implementation _CPNotificationObserverOperation : CPOperation
{
    CPNotification      _notification;
    Function            _block;
}

/* @ignore */
- (id)initWithBlock:(Function)aBlock notification:(CPNotification)aNotification
{
    self = [super init];

    if (self)
    {
        _block = aBlock;
        _notification = aNotification;
    }

    return self;
}

/* @ignore */
- (void)main
{
    _block(_notification);
}

/* @ignore */
- (BOOL)isReady
{
    return YES;
}

@end
