/*
 * CPKeyValueCoding.j
 * Foundation
 *
 * Created by Ross Boucher.
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
@import "CPNull.j"
@import "CPObject.j"
@import "CPSet.j"


@implementation CPObject (KeyValueObserving)

- (void)willChangeValueForKey:(CPString)aKey
{
}

- (void)didChangeValueForKey:(CPString)aKey
{
}

- (void)willChange:(CPKeyValueChange)change valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)key
{
}

- (void)didChange:(CPKeyValueChange)change valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)key
{
}

- (void)addObserver:(id)anObserver forKeyPath:(CPString)aPath options:(unsigned)options context:(id)aContext
{
    if (!anObserver || !aPath)
        return;
    //CPLog.warn(anObserver+" is adding itself as an observer to object: "+self+" forKeyPath: "+aPath+" context: "+aContext);
    [[_CPKVOProxy proxyForObject:self] _addObserver:anObserver forKeyPath:aPath options:options context:aContext];
}

- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aPath
{
    if (!anObserver || !aPath)
        return;

    [self[KVOProxyKey] _removeObserver:anObserver forKeyPath:aPath];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    return YES;
}

+ (CPSet)keyPathsForValuesAffectingValueForKey:(CPString)aKey
{
    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substring(1);
        selector = "keyPathsForValuesAffecting" + capitalizedKey;

    if ([[self class] respondsToSelector:selector])
        return objj_msgSend([self class], selector);

    return [CPSet set];
}

- (void)applyChange:(CPDictionary)aChange toKeyPath:(CPString)aKeyPath
{
    var changeKind = [aChange objectForKey:CPKeyValueChangeKindKey];

    if (changeKind === CPKeyValueChangeSetting)
    {
        var value = [aChange objectForKey:CPKeyValueChangeNewKey];

        [self setValue:value === [CPNull null] ? nil : value forKeyPath:aKeyPath];
    }

    else if (changeKind === CPKeyValueChangeInsertion)
        [[self mutableArrayValueForKeyPath:aKeyPath]
            insertObjects:[aChange objectForKey:CPKeyValueChangeNewKey]
                atIndexes:[aChange objectForKey:CPKeyValueChangeIndexesKey]];

    else if (changeKind === CPKeyValueChangeRemoval)
        [[self mutableArrayValueForKeyPath:aKeyPath]
            removeObjectsAtIndexes:[aChange objectForKey:CPKeyValueChangeIndexesKey]];

    else if (changeKind === CPKeyValueChangeReplacement)
        [[self mutableArrayValueForKeyPath:aKeyPath]
            replaceObjectAtIndexes:[aChange objectForKey:CPKeyValueChangeIndexesKey]
                       withObjects:[aChange objectForKey:CPKeyValueChangeNewKey]];
}

@end

@implementation CPDictionary (KeyValueObserving)

- (CPDictionary)inverseChangeDictionary
{
    var inverseChangeDictionary = [self mutableCopy],
        changeKind = [self objectForKey:CPKeyValueChangeKindKey];

    if (changeKind === CPKeyValueChangeSetting || changeKind === CPKeyValueChangeReplacement)
    {
        [inverseChangeDictionary
            setObject:[self objectForKey:CPKeyValueChangeOldKey]
               forKey:CPKeyValueChangeNewKey];

        [inverseChangeDictionary
            setObject:[self objectForKey:CPKeyValueChangeNewKey]
               forKey:CPKeyValueChangeOldKey];
    }

    else if (changeKind === CPKeyValueChangeInsertion)
    {
        [inverseChangeDictionary
            setObject:CPKeyValueChangeRemoval
               forKey:CPKeyValueChangeKindKey];

        [inverseChangeDictionary
            setObject:[self objectForKey:CPKeyValueChangeNewKey]
               forKey:CPKeyValueChangeOldKey];

        [inverseChangeDictionary removeObjectForKey:CPKeyValueChangeNewKey];
    }

    else if (changeKind === CPKeyValueChangeRemoval)
    {
        [inverseChangeDictionary
            setObject:CPKeyValueChangeInsertion
               forKey:CPKeyValueChangeKindKey];

        [inverseChangeDictionary
            setObject:[self objectForKey:CPKeyValueChangeOldKey]
               forKey:CPKeyValueChangeNewKey];

        [inverseChangeDictionary removeObjectForKey:CPKeyValueChangeOldKey];
    }

    return inverseChangeDictionary;
}

@end

// KVO Options
CPKeyValueObservingOptionNew        = 1 << 0;
CPKeyValueObservingOptionOld        = 1 << 1;
CPKeyValueObservingOptionInitial    = 1 << 2;
CPKeyValueObservingOptionPrior      = 1 << 3;

// KVO Change Dictionary Keys
CPKeyValueChangeKindKey                 = @"CPKeyValueChangeKindKey";
CPKeyValueChangeNewKey                  = @"CPKeyValueChangeNewKey";
CPKeyValueChangeOldKey                  = @"CPKeyValueChangeOldKey";
CPKeyValueChangeIndexesKey              = @"CPKeyValueChangeIndexesKey";
CPKeyValueChangeNotificationIsPriorKey  = @"CPKeyValueChangeNotificationIsPriorKey";

// KVO Change Types
CPKeyValueChangeSetting     = 1;
CPKeyValueChangeInsertion   = 2;
CPKeyValueChangeRemoval     = 3;
CPKeyValueChangeReplacement = 4;

var kvoNewAndOld = CPKeyValueObservingOptionNew|CPKeyValueObservingOptionOld,
    DependentKeysKey = "$KVODEPENDENT",
    KVOProxyKey = "$KVOPROXY";

//rule of thumb: _ methods are called on the real proxy object, others are called on the "fake" proxy object (aka the real object)

/* @ignore */
@implementation _CPKVOProxy : CPObject
{
    id              _targetObject;
    Class           _nativeClass;
    CPDictionary    _changesForKey;
    Object          _observersForKey;
    int             _observersForKeyLength;
    CPSet           _replacedKeys;
}

+ (id)proxyForObject:(CPObject)anObject
{
    var proxy = anObject[KVOProxyKey];

    if (proxy)
        return proxy;

    proxy = [[self alloc] initWithTarget:anObject];

    [proxy _replaceClass];

    anObject[KVOProxyKey] = proxy;

    return proxy;
}

- (id)initWithTarget:(id)aTarget
{
    self = [super init];

    _targetObject       = aTarget;
    _nativeClass        = [aTarget class];
    _observersForKey    = {};
    _changesForKey      = {};
    _observersForKeyLength = 0;

    return self;
}

- (void)_replaceClass
{
    var currentClass = _nativeClass,
        kvoClassName = "$KVO_" + class_getName(_nativeClass),
        existingKVOClass = objj_lookUpClass(kvoClassName);

    if (existingKVOClass)
    {
        _targetObject.isa = existingKVOClass;
        _replacedKeys = existingKVOClass._replacedKeys;
        return;
    }

    var kvoClass = objj_allocateClassPair(currentClass, kvoClassName);

    objj_registerClassPair(kvoClass);

    _replacedKeys = [CPSet set];
    kvoClass._replacedKeys = _replacedKeys;

    //copy in the methods from our model subclass
    var methodList = _CPKVOModelSubclass.method_list,
        count = methodList.length,
        i = 0;

    for (; i < count; i++)
    {
        var method = methodList[i];
        class_addMethod(kvoClass, method_getName(method), method_getImplementation(method), "");
    }

    if ([_targetObject isKindOfClass:[CPDictionary class]])
    {
        var methodList = _CPKVOModelDictionarySubclass.method_list,
            count = methodList.length,
            i = 0;

        for (; i < count; i++)
        {
            var method = methodList[i];
            class_addMethod(kvoClass, method_getName(method), method_getImplementation(method), "");
        }
    }

    _targetObject.isa = kvoClass;
}

- (void)_replaceSetterForKey:(CPString)aKey
{
    if ([_replacedKeys containsObject:aKey] || ![_nativeClass automaticallyNotifiesObserversForKey:aKey])
        return;

    var currentClass = _nativeClass,
        capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substring(1),
        found = false,
        replacementMethods = [
            "set" + capitalizedKey + ":", _kvoMethodForMethod,
            "_set" + capitalizedKey + ":", _kvoMethodForMethod,
            "insertObject:in" + capitalizedKey + "AtIndex:", _kvoInsertMethodForMethod,
            "replaceObjectIn" + capitalizedKey + "AtIndex:withObject:", _kvoReplaceMethodForMethod,
            "removeObjectFrom" + capitalizedKey + "AtIndex:", _kvoRemoveMethodForMethod
        ];

    var i = 0,
        count = replacementMethods.length;

    for (; i < count; i += 2)
    {
        var theSelector = sel_getName(replacementMethods[i]),
            theReplacementMethod = replacementMethods[i + 1];

        if ([_nativeClass instancesRespondToSelector:theSelector])
        {
            var theMethod = class_getInstanceMethod(_nativeClass, theSelector);

            class_addMethod(_targetObject.isa, theSelector, theReplacementMethod(aKey, theMethod), "");
            [_replacedKeys addObject:aKey];
        }
    }

    var affectingKeys = [[_nativeClass keyPathsForValuesAffectingValueForKey:aKey] allObjects],
        affectingKeysCount = affectingKeys ? affectingKeys.length : 0;

    if (!affectingKeysCount)
        return;

    var dependentKeysForClass = _nativeClass[DependentKeysKey];

    if (!dependentKeysForClass)
    {
        dependentKeysForClass = {};
        _nativeClass[DependentKeysKey] = dependentKeysForClass;
    }

    while (affectingKeysCount--)
    {
        var affectingKey = affectingKeys[affectingKeysCount],
            affectedKeys = dependentKeysForClass[affectingKey];

        if (!affectedKeys)
        {
            affectedKeys = [CPSet new];
            dependentKeysForClass[affectingKey] = affectedKeys;
        }

        [affectedKeys addObject:aKey];
        [self _replaceSetterForKey:affectingKey];
    }
}

- (void)_addObserver:(id)anObserver forKeyPath:(CPString)aPath options:(unsigned)options context:(id)aContext
{
    if (!anObserver)
        return;

    var forwarder = nil;

    if (aPath.indexOf('.') != CPNotFound)
        forwarder = [[_CPKVOForwardingObserver alloc] initWithKeyPath:aPath object:_targetObject observer:anObserver options:options context:aContext];
    else
        [self _replaceSetterForKey:aPath];

    var observers = _observersForKey[aPath];

    if (!observers)
    {
        observers = [CPDictionary dictionary];
        _observersForKey[aPath] = observers;
        _observersForKeyLength++;
    }

    [observers setObject:_CPKVOInfoMake(anObserver, options, aContext, forwarder) forKey:[anObserver UID]];

    if (options & CPKeyValueObservingOptionInitial)
    {
        var newValue = [_targetObject valueForKeyPath:aPath];

        if (newValue === nil || newValue === undefined)
            newValue = [CPNull null];

        var changes = [CPDictionary dictionaryWithObject:newValue forKey:CPKeyValueChangeNewKey];
        [anObserver observeValueForKeyPath:aPath ofObject:self change:changes context:aContext];
    }
}

- (void)_removeObserver:(id)anObserver forKeyPath:(CPString)aPath
{
    var observers = _observersForKey[aPath];

    if (aPath.indexOf('.') != CPNotFound)
    {
        var forwarder = [observers objectForKey:[anObserver UID]].forwarder;
        [forwarder finalize];
    }

    [observers removeObjectForKey:[anObserver UID]];

    if (![observers count])
    {
        _observersForKeyLength--;
        delete _observersForKey[aPath];
    }

    if (!_observersForKeyLength)
    {
        _targetObject.isa = _nativeClass; //restore the original class
        delete _targetObject[KVOProxyKey];
    }
}

//FIXME: We do not compute and cache if CPKeyValueObservingOptionOld is needed, so we may do unnecessary work

- (void)_sendNotificationsForKey:(CPString)aKey changeOptions:(CPDictionary)changeOptions isBefore:(BOOL)isBefore
{
    var changes = _changesForKey[aKey];

    if (isBefore)
    {
        changes = changeOptions;

        var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey];

        if (indexes)
        {
            var type = [changes objectForKey:CPKeyValueChangeKindKey];

            // for to-many relationships, oldvalue is only sensible for replace and remove
            if (type === CPKeyValueChangeReplacement || type === CPKeyValueChangeRemoval)
            {
                //FIXME: do we need to go through and replace "" with CPNull?
                var newValues = [[_targetObject mutableArrayValueForKeyPath:aKey] objectsAtIndexes:indexes];
                [changes setValue:newValues forKey:CPKeyValueChangeOldKey];
            }
        }
        else
        {
            var oldValue = [_targetObject valueForKey:aKey];

            if (oldValue === nil || oldValue === undefined)
                oldValue = [CPNull null];

            [changes setObject:oldValue forKey:CPKeyValueChangeOldKey];
        }

        [changes setObject:1 forKey:CPKeyValueChangeNotificationIsPriorKey];

        _changesForKey[aKey] = changes;
    }
    else
    {
        // The isBefore path may not have been called as would happen if didChangeX
        // was called alone.
        if (!changes)
            changes = [CPDictionary new];

        [changes removeObjectForKey:CPKeyValueChangeNotificationIsPriorKey];

        var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey];

        if (indexes)
        {
            var type = [changes objectForKey:CPKeyValueChangeKindKey];

            // for to-many relationships, oldvalue is only sensible for replace and remove
            if (type == CPKeyValueChangeReplacement || type == CPKeyValueChangeInsertion)
            {
                //FIXME: do we need to go through and replace "" with CPNull?
                var newValues = [[_targetObject mutableArrayValueForKeyPath:aKey] objectsAtIndexes:indexes];
                [changes setValue:newValues forKey:CPKeyValueChangeNewKey];
            }
        }
        else
        {
            var newValue = [_targetObject valueForKey:aKey];

            if (newValue === nil || newValue === undefined)
                newValue = [CPNull null];

            [changes setObject:newValue forKey:CPKeyValueChangeNewKey];
        }
    }

    var observers = [_observersForKey[aKey] allValues],
        count = observers ? observers.length : 0;

    while (count--)
    {
        var observerInfo = observers[count];

        if (isBefore && (observerInfo.options & CPKeyValueObservingOptionPrior))
            [observerInfo.observer observeValueForKeyPath:aKey ofObject:_targetObject change:changes context:observerInfo.context];
        else if (!isBefore)
            [observerInfo.observer observeValueForKeyPath:aKey ofObject:_targetObject change:changes context:observerInfo.context];
    }

    var dependentKeysMap = _nativeClass[DependentKeysKey];

    if (!dependentKeysMap)
        return;

    var dependentKeyPaths = [dependentKeysMap[aKey] allObjects];

    if (!dependentKeyPaths)
        return;

    var index = 0,
        count = [dependentKeyPaths count];

    for (; index < count; ++index)
    {
        var keyPath = dependentKeyPaths[index];

        [self _sendNotificationsForKey:keyPath
                         changeOptions:isBefore ? [changeOptions copy] : _changesForKey[keyPath]
                              isBefore:isBefore];
    }
}

@end

@implementation _CPKVOModelSubclass
{
}

- (void)willChangeValueForKey:(CPString)aKey
{
    var superClass = [self class],
        methodSelector = @selector(willChangeValueForKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, aKey);

    if (!aKey)
        return;

    var changeOptions = [CPDictionary dictionaryWithObject:CPKeyValueChangeSetting forKey:CPKeyValueChangeKindKey];

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey changeOptions:changeOptions isBefore:YES];
}

- (void)didChangeValueForKey:(CPString)aKey
{
    var superClass = [self class],
        methodSelector = @selector(didChangeValueForKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, aKey);

    if (!aKey)
        return;

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey changeOptions:nil isBefore:NO];
}

- (void)willChange:(CPKeyValueChange)change valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)aKey
{
    var superClass = [self class],
        methodSelector = @selector(willChange:valuesAtIndexes:forKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, change, indexes, aKey);

    if (!aKey)
        return;

    var changeOptions = [CPDictionary dictionaryWithObjects:[change, indexes] forKeys:[CPKeyValueChangeKindKey, CPKeyValueChangeIndexesKey]];

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey changeOptions:changeOptions isBefore:YES];
}

- (void)didChange:(CPKeyValueChange)change valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)aKey
{
    var superClass = [self class],
        methodSelector = @selector(didChange:valuesAtIndexes:forKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, change, indexes, aKey);

    if (!aKey)
        return;

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey changeOptions:nil isBefore:NO];
}

- (Class)class
{
    return self[KVOProxyKey]._nativeClass;
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

@implementation _CPKVOModelDictionarySubclass
{
}

- (void)removeAllObjects
{
    var keys = [self allKeys],
        count = [keys count],
        i = 0;

    for (; i < count; i++)
        [self willChangeValueForKey:keys[i]];

    var superClass = [self class],
        methodSelector = @selector(removeAllObjects),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector);

    for (i = 0; i < count; i++)
        [self didChangeValueForKey:keys[i]];
}

- (void)removeObjectForKey:(id)aKey
{
    [self willChangeValueForKey:aKey];

    var superClass = [self class],
        methodSelector = @selector(removeObjectForKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, aKey);

    [self didChangeValueForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    [self willChangeValueForKey:aKey];

    var superClass = [self class],
        methodSelector = @selector(setObject:forKey:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, anObject, aKey);

    [self didChangeValueForKey:aKey];
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
    _secondPart = aKeyPath.substring(dotIndex + 1);

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
    if (aKeyPath === _firstPart)
    {
        [_observer observeValueForKeyPath:_firstPart ofObject:_object change:changes context:_context];

        //since a has changed, we should remove ourselves as an observer of the old a, and observe the new one
        if (_value)
            [_value removeObserver:self forKeyPath:_secondPart];

        _value = [_object valueForKey:_firstPart];

        if (_value)
            [_value addObserver:self forKeyPath:_secondPart options:kvoNewAndOld context:nil];
    }
    else
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

var _kvoMethodForMethod = function _kvoMethodForMethod(theKey, theMethod)
{
    return function(self, _cmd, object)
    {
        [self willChangeValueForKey:theKey];
        theMethod.method_imp(self, _cmd, object);
        [self didChangeValueForKey:theKey];
    }
}

var _kvoInsertMethodForMethod = function _kvoInsertMethodForMethod(theKey, theMethod)
{
    return function(self, _cmd, object, index)
    {
        [self willChange:CPKeyValueChangeInsertion valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
        theMethod.method_imp(self, _cmd, object, index);
        [self didChange:CPKeyValueChangeInsertion valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
    }
}

var _kvoReplaceMethodForMethod = function _kvoReplaceMethodForMethod(theKey, theMethod)
{
    return function(self, _cmd, index, object)
    {
        [self willChange:CPKeyValueChangeReplacement valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
        theMethod.method_imp(self, _cmd, index, object);
        [self didChange:CPKeyValueChangeReplacement valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
    }
}

var _kvoRemoveMethodForMethod = function _kvoRemoveMethodForMethod(theKey, theMethod)
{
    return function(self, _cmd, index)
    {
        [self willChange:CPKeyValueChangeRemoval valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
        theMethod.method_imp(self, _cmd, index);
        [self didChange:CPKeyValueChangeRemoval valuesAtIndexes:[CPIndexSet indexSetWithIndex:index] forKey:theKey];
    }
}

@import "CPArray+KVO.j"
