/*
 * CPKeyValueCoding.j
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

import "CPArray.j"
import "CPDictionary.j"
import "CPException.j"
import "CPObject.j"

@implementation CPObject (KeyValueObserving)

- (void)willChangeValueForKey:(CPString)aKey
{

}

- (void)didChangeValueForKey:(CPString)aKey
{

}

- (void)addObserver:(id)anObserver forKeyPath:(CPString)aPath options:(unsigned)options context:(id)aContext
{
    if (!anObserver || !aPath)
        return;

    [[_CPKVOProxy proxyForObject:self] _addObserver:anObserver forKeyPath:aPath options:options context:aContext];
}

- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aPath
{
    if (!anObserver || !aPath)
        return;

    [[KVOProxyMap objectForKey:[self hash]] _removeObserver:anObserver forKeyPath:aPath];
}

- (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    return YES;
}

@end

// KVO Options
CPKeyValueObservingOptionNew        = 1 << 0;
CPKeyValueObservingOptionOld        = 1 << 1;
CPKeyValueObservingOptionInitial    = 1 << 2;
CPKeyValueObservingOptionPrior      = 1 << 3;

//convenience
var kvoNewAndOld = CPKeyValueObservingOptionNew|CPKeyValueObservingOptionOld;

// KVO Change Dictionary Keys
CPKeyValueChangeKindKey                 = @"CPKeyValueChangeKindKey";
CPKeyValueChangeNewKey                  = @"CPKeyValueChangeNewKey";
CPKeyValueChangeOldKey                  = @"CPKeyValueChangeOldKey";
CPKeyValueChangeIndexesKey              = @"CPKeyValueChangeIndexesKey";
CPKeyValueChangeNotificationIsPriorKey  = @"CPKeyValueChangeNotificationIsPriorKey";

// Map of real objects to their KVO proxy
var KVOProxyMap = [CPDictionary dictionary];

//rule of thumb: _ methods are called on the real proxy object, others are called on the "fake" proxy object (aka the real object)

/* @ignore */
@implementation _CPKVOProxy : CPObject
{
    id              _targetObject;
    Class           _nativeClass;
    CPDictionary    _changesForKey;
    CPDictionary    _observersForKey;
    CPDictionary    _replacementMethods;
}

+ (id)proxyForObject:(CPObject)anObject
{
    var proxy = [KVOProxyMap objectForKey:[anObject hash]];

    if (proxy)
        return proxy;

    proxy = [[self alloc] initWithTarget:anObject];

    //[proxy _replaceSetters];
    
    //anObject.isa = proxy.isa;

    [proxy _replaceClass];

    [KVOProxyMap setObject:proxy forKey:[anObject hash]];

    return proxy;
}

- (id)initWithTarget:(id)aTarget
{
    self = [super init];

    _targetObject       = aTarget;
    _nativeClass        = [aTarget class];
    _replacementMethods = [CPDictionary dictionary];
    _observersForKey    = [CPDictionary dictionary];
    _changesForKey      = [CPDictionary dictionary];

    return self;
}

- (void)_replaceSetters
{
    var currentClass = [_targetObject class];

    while (currentClass && currentClass != currentClass.super_class)
    {
        var methodList = currentClass.method_list,
            count = methodList.length;

        for (var i=0; i<count; i++)
        {
            var newMethod = _kvoMethodForMethod(_targetObject, methodList[i]);

            if (newMethod)
                [_replacementMethods setObject:newMethod forKey:methodList[i].name];
        }

        currentClass = currentClass.super_class;
    }
}

- (void)_replaceSetters
{
    var currentClass = [_targetObject class];

    while (currentClass && currentClass != currentClass.super_class)
    {
        var methodList = currentClass.method_list,
            count = methodList.length;

        for (var i=0; i<count; i++)
        {
            var newMethod = _kvoMethodForMethod(_targetObject, methodList[i]);

            if (newMethod)
                [_replacementMethods setObject:newMethod forKey:methodList[i].name];
        }

        currentClass = currentClass.super_class;
    }
}

- (void)_replaceClass
{
    var currentClass = _nativeClass,
        kvoClassName = "$KVO_"+class_getName(_nativeClass),
        existingKVOClass = objj_lookUpClass(kvoClassName);
    
    if (existingKVOClass)
    {
        _targetObject.isa = existingKVOClass;
        return;
    }
    
    var kvoClass = objj_allocateClassPair(currentClass, kvoClassName);
        
    objj_registerClassPair(kvoClass);
    _class_initialize(kvoClass);
    
    while (currentClass && currentClass != currentClass.super_class)
    {
        var methodList = currentClass.method_list,
            count = methodList.length;

        for (var i=0; i<count; i++)
        {
            var newMethodImp = _kvoMethodForMethod(_targetObject, methodList[i]);

            if (newMethodImp)
                class_addMethod(kvoClass, method_getName(methodList[i]), newMethodImp, "");
        }

        currentClass = currentClass.super_class;
    }
    
    var methodList = _CPKVOModelSubclass.method_list,
        count = methodList.length;

    for (var i=0; i<count; i++)
    {
        var method = methodList[i];
        class_addMethod(kvoClass, method_getName(method), method_getImplementation(method), "");
    }

    _targetObject.isa = kvoClass;
}

- (void)_addObserver:(id)anObserver forKeyPath:(CPString)aPath options:(unsigned)options context:(id)aContext
{
    if (!anObserver)
        return;

    var forwarder = nil;
    
    if (aPath.indexOf('.') != CPNotFound)
        forwarder = [[_CPKVOForwardingObserver alloc] initWithKeyPath:aPath object:_targetObject observer:anObserver options:options context:aContext];

    var observers = [_observersForKey objectForKey:aPath];

    if (!observers)
    {
        observers = [CPDictionary dictionary];
        [_observersForKey setObject:observers forKey:aPath];
    }

    [observers setObject:_CPKVOInfoMake(anObserver, options, aContext, forwarder) forKey:[anObserver hash]];
    
    if (options & CPKeyValueObservingOptionInitial)
    {
        var newValue = [_targetObject valueForKeyPath:aPath];

        if (!newValue && newValue !== "")
            newValue = [CPNull null];

        var changes = [CPDictionary dictionaryWithObject:newValue forKey:CPKeyValueChangeNewKey];
        [anObserver observeValueForKeyPath:aPath ofObject:self change:changes context:aContext];
    }
}

- (void)_removeObserver:(id)anObserver forKeyPath:(CPString)aPath
{
    var observers = [_observersForKey objectForKey:aPath];

    if (aPath.indexOf('.') != CPNotFound)
    {
        var forwarder = [observers objectForKey:[anObserver hash]].forwarder;
        [forwarder finalize];
    }

    [observers removeObjectForKey:[anObserver hash]];

    if (![observers count])
        [_observersForKey removeObjectForKey:aPath];

    if (![_observersForKey count])
    {
        _targetObject.isa = _nativeClass; //restore the original class
        [KVOProxyMap removeObjectForKey:[_targetObject hash]];
    }
}

- (void)_sendNotificationsForKey:(CPString)aKey isBefore:(BOOL)isBefore
{
    var changes = [_changesForKey objectForKey:aKey];

    if (isBefore)
    {
        changes = [CPDictionary dictionary];

        var oldValue = [_targetObject valueForKey:aKey];

        if (!oldValue && oldValue !== "")
            oldValue = [CPNull null];

        [changes setObject:1 forKey:CPKeyValueChangeNotificationIsPriorKey];
        [changes setObject:oldValue forKey:CPKeyValueChangeOldKey];

        [_changesForKey setObject:changes forKey:aKey];
    }
    else
    {
        [changes removeObjectForKey:CPKeyValueChangeNotificationIsPriorKey];

        var newValue = [_targetObject valueForKey:aKey];

        if (!newValue && newValue !== "")
            newValue = [CPNull null];

        [changes setObject:newValue forKey:CPKeyValueChangeNewKey];
    }
    
    var observers = [[_observersForKey objectForKey:aKey] allValues],
        count = [observers count];

    while (count--)
    {
        var observerInfo = observers[count];

        if (isBefore && (observerInfo.options & CPKeyValueObservingOptionPrior))
            [observerInfo.observer observeValueForKeyPath:aKey ofObject:_targetObject change:changes context:observerInfo.context];
        else if (!isBefore)
            [observerInfo.observer observeValueForKeyPath:aKey ofObject:_targetObject change:changes context:observerInfo.context];
    }
}

@end

@implementation _CPKVOModelSubclass
{
}

- (void)willChangeValueForKey:(CPString)aKey
{
    if (!aKey)
        return;

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey isBefore:YES];
}

- (void)didChangeValueForKey:(CPString)aKey
{
    if (!aKey)
        return;

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey isBefore:NO];
}

- (Class)class
{
    return [KVOProxyMap objectForKey:[self hash]]._nativeClass;
}

- (Class)superclass
{
    return [[self class] superclass];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [[self class] isSubclassOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return [self class] == aClass;
}

- (CPString)className
{
    return [self class].name;
}

@end

@implementation _CPKVOForwardingObserver : CPObject
{
    id          _object;
    id          _observer;
    id          _context;
                             //a.b
    CPString    _firstPart;  //a
    CPString    _secondPart; //b

    id          _value;
}

- (id)initWithKeyPath:(CPString)aKeyPath object:(id)anObject observer:(id)anObserver options:(unsigned)options context:(id)aContext
{
    self = [super init];
        
    _context = aContext;
    _observer = anObserver;
    _object = anObject;
    
    //current ignoring options (FIXME?)
    
    var dotIndex = aKeyPath.indexOf('.');
    
    if (dotIndex == CPNotFound)
        [CPException raise:CPInvalidArgumentException reason:"Created _CPKVOForwardingObserver without compound key path: "+aKeyPath];
    
    _firstPart = aKeyPath.substring(0, dotIndex);
    _secondPart = aKeyPath.substring(dotIndex+1);
    
    //become an observer of the first part of our key (a)
    [_object addObserver:self forKeyPath:_firstPart options:kvoNewAndOld context:nil];
    
    //the current value of a (not the value of a.b)
    _value = [_object valueForKey:_firstPart];
    
    if (_value)
        [_value addObserver:self forKeyPath:_secondPart options:kvoNewAndOld context:nil]; //we're observing b on current a
    
    return self;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    if (anObject == _object)
    {
        [_observer observeValueForKeyPath:_firstPart ofObject:_object change:changes context:_context];
        
        //since a has changed, we should remove ourselves as an observer of the old a, and observe the new one
        if (_value)
            [_value removeObserver:self forKeyPath:_secondPart];
            
        _value = [_object valueForKey:_firstPart];
        
        if (_value)
            [_value addObserver:self forKeyPath:_secondPart options:kvoNewAndOld context:nil];
    }
    else /* if (anObject == _value || !_value) */
    {
        //a is the same, but a.b has changed -- nothing to do but forward this message along
        [_observer observeValueForKeyPath:_firstPart+"."+aKeyPath ofObject:_object change:changes context:_context];
    }
}

- (void)finalize
{
    if (_value)
        [_value removeObserver:self forKeyPath:_secondPart];
    
    [_object removeObserver:self forKeyPath:_firstPart];
    
    _object = nil;
    _observer = nil;
    _context = nil;
    _value = nil;
}

@end

var _CPKVOInfoMake = function _CPKVOInfoMake(anObserver, theOptions, aContext, aForwarder)
{
    return {
        observer: anObserver, 
        options: theOptions,
        context: aContext,
        forwarder: aForwarder
    };
}

var _kvoMethodForMethod = function _kvoMethodForMethod(theObject, theMethod)
{
    var methodName = theMethod.name,
        methodImplementation = theMethod.method_imp,
        setterKey = kvoKeyForSetter(methodName);
    
    if (setterKey && objj_msgSend(theObject, @selector(automaticallyNotifiesObserversForKey:), setterKey))
    {            
        var newMethodImp = function(self) 
        {
            [self willChangeValueForKey:setterKey];
            methodImplementation.apply(self, arguments);
            [self didChangeValueForKey:setterKey];
        }
        
        return newMethodImp;
    }

    return nil;
}

var kvoKeyForSetter = function kvoKeyForSetter(selector)
{
    if (selector.split(":").length > 2 || !([selector hasPrefix:@"set"] || [selector hasPrefix:@"_set"]))
        return nil;
        
    var keyIndex = selector.indexOf("set") + "set".length,
        colonIndex = selector.indexOf(":");
    
    return selector.charAt(keyIndex).toLowerCase() + selector.substring(keyIndex+1, colonIndex);
}

@implementation CPArray (KeyValueObserving)

- (void)addObserver:(id)anObserver toObjectsAtIndexes:(CPIndexSet)indexes forKeyPath:(CPString)aKeyPath options:(unsigned)options context:(id)context
{
    var index = [indexes firstIndex];
    
    while (index >= 0)
    {
        [self[index] addObserver:anObserver forKeyPath:aKeyPath options:options context:context];

		index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)removeObserver:(id)anObserver fromObjectsAtIndexes:(CPIndexSet)indexes forKeyPath:(CPString)aKeyPath
{
    var index = [indexes firstIndex];
    
    while (index >= 0)
    {
        [self[index] removeObserver:anObserver forKeyPath:aKeyPath];

		index = [indexes indexGreaterThanIndex:index];
    }
}

-(void)addObserver:(id)observer forKeyPath:(CPString)aKeyPath options:(unsigned)options context:(id)context
{
    [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPArray"];
}

-(void)removeObserver:(id)observer forKeyPath:(CPString)aKeyPath
{
    [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPArray"];
}

@end
