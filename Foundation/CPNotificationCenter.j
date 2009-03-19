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
@import "CPNotification.j"
@import "CPException.j"


var CPNotificationDefaultCenter = nil;

/*! @class CPNotificationCenter

    Cappuccino provides a framework for sending messages between objects within a process called notifications. Objects register with an CPNotificationCenter to be informed whenever other objects post CPNotifications to it matching certain criteria. The notification center processes notifications synchronously -- that is, control is only returned to the notification poster once every recipient of the notification has received it and processed it.
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
        _namedRegistries = [CPDictionary dictionary];
        _unnamedRegistry = [[_CPNotificationRegistry alloc] init];
    }
   return self;
}

/*!
    Adds an object as an observer. The observer will receive notifications with the specified name
    and/or containing the specified object (depending on if they are <code>nil</code>.
    @param anObserver the observing object
    @param aSelector the message sent to the observer when a notification occurrs
    @param aNotificationName the name of the notification the observer wants to watch
    @param anObject the object in the notification the observer wants to watch
*/
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(CPString)aNotificationName object:(id)anObject
{
    var registry,
        observer = [[_CPNotificationObserver alloc] initWithObserver:anObserver selector:aSelector];
    
    if (aNotificationName == nil)
        registry = _unnamedRegistry;
    
    else if (!(registry = [_namedRegistries objectForKey:aNotificationName]))
    {
        registry = [[_CPNotificationRegistry alloc] init];
        [_namedRegistries setObject:registry forKey:aNotificationName];
    }
    
    [registry addObserver:observer object:anObject];
}

/*!
    Unregisters the specified observer from all notifications.
    @param anObserver the observer to unregister
*/
- (void)removeObserver:(id)anObserver
{
    var name = nil,
        names = [_namedRegistries keyEnumerator];
        
    while (name = [names nextObject])
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
        
        while (name = [names nextObject])
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
}

/* 
    Mapping of Notification Name to listening object/selector.
    @ignore
 */
@implementation _CPNotificationRegistry : CPObject
{
    CPDictionary    _objectObservers;
    BOOL            _observerRemoval;
    CPArray         _postingObservers;
}

- (id)init
{
    if (self)
        _objectObservers = [CPDictionary dictionary];

   return self;
}

-(void)addObserver:(_CPNotificationObserver)anObserver object:(id)anObject
{
    // If there's no object, then we're listening to this 
    // notification regardless of whom sends it.
    if (!anObject)
        anObject = [CPNull null];
    
    // Grab all the listeners for this notification/object pair
    var observers = [_objectObservers objectForKey:[anObject hash]];

    if (!observers)
    {
        observers = [];
        [_objectObservers setObject:observers forKey:[anObject hash]];
    }
    
    if (observers == _postingObservers)
        _postingObservers = [observers copy];

    // Add this observer.    
    observers.push(anObserver);
}

-(void)removeObserver:(id)anObserver object:(id)anObject
{
    var removedKeys = [];

    // This means we're getting rid of EVERY instance of this observer.
    if (anObject == nil)
    {
        var key = nil,
            keys = [_objectObservers keyEnumerator];
        
        // Iterate through every set of observers
        while (key = [keys nextObject])
        {
            var observers = [_objectObservers objectForKey:key],
                count = observers ? observers.length : 0;
            
            while (count--)
                if ([observers[count] observer] == anObserver)
                {
                    _observerRemoval = YES;
                    if (observers == _postingObservers)
                        _postingObservers = [observers copy];
                        
                    observers.splice(count, 1);
                }
                
            if (!observers || observers.length == 0)
                removedKeys.push(key);
        }
    }
    else
    {
        var key = [anObject hash],
            observers = [_objectObservers objectForKey:key];
            count = observers ? observers.length : 0;
        
        while (count--)
            if ([observers[count] observer] == anObserver)
            {
                _observerRemoval = YES;
                if (observers == _postingObservers)
                    _postingObservers = [observers copy];

                observers.splice(count, 1)
            }
            
        if (!observers || observers.length == 0)
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
    // the current array (this avoids removed observers from receiving notifications).
    // However, this is a very expensive operation (O(N) => O(N^2)), so to avoid it,
    // we keep track of whether observers are added or removed, and only do our 
    // rigorous testing in those cases.
    var object = [aNotification object];
    
    if (object != nil && (_postingObservers = [_objectObservers objectForKey:[object hash]]))
    {
        var observers = _postingObservers,
            count = observers.length;
        
        _observerRemoval = NO;
        while (count--)
        {
            var observer = _postingObservers[count];
        
            // if there wasn't removal of an observer during this posting, or there 
            // was but we are still in the observer list... 
            if (!_observerRemoval || [observers indexOfObjectIdenticalTo:observer] != CPNotFound)
                [observer postNotification:aNotification];
    
        }
    }
    
    // Now do the same for the nil object observers...
    _postingObservers = [_objectObservers objectForKey:[[CPNull null] hash]];
    
    if (!_postingObservers)
        return;
    
    var observers = _postingObservers,
        count = observers.length;
    
    _observerRemoval = NO;
    while (count--)
    {
        var observer = _postingObservers[count];
        
        // if there wasn't removal of an observer during this posting, or there 
        // was but we are still in the observer list... 
        if (!_observerRemoval || [observers indexOfObjectIdenticalTo:observer] != CPNotFound)
            [observer postNotification:aNotification];
    }
    
    _postingObservers = nil;
}

- (unsigned)count
{
    return [_objectObservers count];
}

@end

/* @ignore */
@implementation _CPNotificationObserver : CPObject
{
    id  _observer;
    SEL _selector;
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

- (id)observer
{
    return _observer;
}

-(void)postNotification:(CPNotification)aNotification
{
    [_observer performSelector:_selector withObject:aNotification];
}

@end
