/*
 * CPKeyValueObserving.j
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
@import "CPIndexSet.j"
@import "CPNull.j"
@import "CPObject.j"
@import "CPSet.j"

@implementation CPObject (KeyValueObserving)

- (void)willChangeValueForKey:(CPString)aKey
{
    if (!aKey)
        return;

    if (!self[KVOProxyKey])
    {
        if (!self._willChangeMessageCounter)
            self._willChangeMessageCounter = new Object();

        if (!self._willChangeMessageCounter[aKey])
            self._willChangeMessageCounter[aKey] = 1;
        else
            self._willChangeMessageCounter[aKey] += 1;
    }
}

- (void)didChangeValueForKey:(CPString)aKey
{
    if (!aKey)
        return;

    if (!self[KVOProxyKey])
    {
        if (self._willChangeMessageCounter && self._willChangeMessageCounter[aKey])
        {
            self._willChangeMessageCounter[aKey] -= 1;

            if (!self._willChangeMessageCounter[aKey])
                delete self._willChangeMessageCounter[aKey];
        }
        else
            [CPException raise:@"CPKeyValueObservingException" reason:@"'didChange...' message called without prior call of 'willChange...'"];
    }
}

- (void)willChange:(CPKeyValueChange)aChange valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)aKey
{
    if (!aKey)
        return;

    if (!self[KVOProxyKey])
    {
        if (!self._willChangeMessageCounter)
            self._willChangeMessageCounter = new Object();

        if (!self._willChangeMessageCounter[aKey])
            self._willChangeMessageCounter[aKey] = 1;
        else
            self._willChangeMessageCounter[aKey] += 1;
    }
}

- (void)didChange:(CPKeyValueChange)aChange valuesAtIndexes:(CPIndexSet)indexes forKey:(CPString)aKey
{
    if (!aKey)
        return;

    if (!self[KVOProxyKey])
    {
        if (self._willChangeMessageCounter && self._willChangeMessageCounter[aKey])
        {
            self._willChangeMessageCounter[aKey] -= 1;

            if (!self._willChangeMessageCounter[aKey])
                delete self._willChangeMessageCounter[aKey];
        }
        else
            [CPException raise:@"CPKeyValueObservingException" reason:@"'didChange...' message called without prior call of 'willChange...'"];
    }
}

- (void)willChangeValueForKey:(CPString)aKey withSetMutation:(CPKeyValueSetMutationKind)aMutationKind usingObjects:(CPSet)objects
{
    if (!aKey)
        return;

    if (!self[KVOProxyKey])
    {
        if (!self._willChangeMessageCounter)
            self._willChangeMessageCounter = new Object();

        if (!self._willChangeMessageCounter[aKey])
            self._willChangeMessageCounter[aKey] = 1;
        else
            self._willChangeMessageCounter[aKey] += 1;
    }
}

- (void)didChangeValueForKey:(CPString)aKey withSetMutation:(CPKeyValueSetMutationKind)aMutationKind usingObjects:(CPSet)objects
{
    if (!self[KVOProxyKey])
    {
        if (self._willChangeMessageCounter && self._willChangeMessageCounter[aKey])
        {
            self._willChangeMessageCounter[aKey] -= 1;

            if (!self._willChangeMessageCounter[aKey])
                delete self._willChangeMessageCounter[aKey];
        }
        else
            [CPException raise:@"CPKeyValueObservingException" reason:@"'didChange...' message called without prior call of 'willChange...'"];
    }
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

    [self[KVOProxyKey] _removeObserver:anObserver forKeyPath:aPath];
}

/*!
    Whether -willChangeValueForKey/-didChangeValueForKey should automatically be invoked when the
    setter of the given key is used. The default is YES. If you override this method to return NO
    for some key, you will need to call -willChangeValueForKey/-didChangeValueForKey manually to
    be KVO compliant.

    The default implementation of this method will check if the receiving class implements
    `+ (BOOL)automaticallyNotifiesObserversOf<aKey>` and return the response of that method if it
    exists.
*/
+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substring(1),
        selector = "automaticallyNotifiesObserversOf" + capitalizedKey;

    if ([[self class] respondsToSelector:selector])
        return objj_msgSend([self class], selector);

    return YES;
}

+ (CPSet)keyPathsForValuesAffectingValueForKey:(CPString)aKey
{
    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substring(1),
        selector = "keyPathsForValuesAffecting" + capitalizedKey;

    if ([[self class] respondsToSelector:selector])
        return objj_msgSend([self class], selector);

    return [CPSet set];
}

- (void)applyChange:(CPDictionary)aChange toKeyPath:(CPString)aKeyPath
{
    var changeKind = [aChange objectForKey:CPKeyValueChangeKindKey],
        oldValue = [aChange objectForKey:CPKeyValueChangeOldKey],
        newValue = [aChange objectForKey:CPKeyValueChangeNewKey];

    if (newValue === [CPNull null])
        newValue = nil;

    if (changeKind === CPKeyValueChangeSetting)
        return [self setValue:newValue forKeyPath:aKeyPath];

    var indexes = [aChange objectForKey:CPKeyValueChangeIndexesKey];

    // If we have an indexes entry, then we have an ordered to-many relationship
    if (indexes)
    {
        if (changeKind === CPKeyValueChangeInsertion)
            [[self mutableArrayValueForKeyPath:aKeyPath] insertObjects:newValue atIndexes:indexes];

        else if (changeKind === CPKeyValueChangeRemoval)
            [[self mutableArrayValueForKeyPath:aKeyPath] removeObjectsAtIndexes:indexes];

        else if (changeKind === CPKeyValueChangeReplacement)
            [[self mutableArrayValueForKeyPath:aKeyPath] replaceObjectAtIndexes:indexes withObjects:newValue];
    }
    else
    {
        if (changeKind === CPKeyValueChangeInsertion)
            [[self mutableSetValueForKeyPath:aKeyPath] unionSet:newValue];

        else if (changeKind === CPKeyValueChangeRemoval)
            [[self mutableSetValueForKeyPath:aKeyPath] minusSet:oldValue];

        else if (changeKind === CPKeyValueChangeReplacement)
            [[self mutableSetValueForKeyPath:aKeyPath] setSet:newValue];
    }
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

// CPKeyValueSetMutationKind
CPKeyValueUnionSetMutation = 1;
CPKeyValueMinusSetMutation = 2;
CPKeyValueIntersectSetMutation = 3;
CPKeyValueSetSetMutation = 4;

//FIXME: "secret" dict ivar-keys are workaround to support unordered to-many relationships without too many modifications
_CPKeyValueChangeSetMutationObjectsKey  = @"_CPKeyValueChangeSetMutationObjectsKey";
_CPKeyValueChangeSetMutationKindKey     = @"_CPKeyValueChangeSetMutationKindKey";
_CPKeyValueChangeSetMutationNewValueKey = @"_CPKeyValueChangeSetMutationNewValueKey";

var _changeKindForSetMutationKind = function(mutationKind)
{
    switch (mutationKind)
    {
        case CPKeyValueUnionSetMutation:        return CPKeyValueChangeInsertion;
        case CPKeyValueMinusSetMutation:        return CPKeyValueChangeRemoval;
        case CPKeyValueIntersectSetMutation:    return CPKeyValueChangeRemoval;
        case CPKeyValueSetSetMutation:          return CPKeyValueChangeReplacement;
    }
};

var kvoNewAndOld        = CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld,
    DependentKeysKey    = "$KVODEPENDENT",
    KVOProxyKey         = "$KVOPROXY";

//rule of thumb: _ methods are called on the real proxy object, others are called on the "fake" proxy object (aka the real object)

/* @ignore */
@implementation _CPKVOProxy : CPObject
{
    id              _targetObject;
    Class           _nativeClass;
    CPDictionary    _changesForKey;
    CPDictionary    _nestingForKey;
    Object          _observersForKey;
    int             _observersForKeyLength;
    CPSet           _replacedKeys;

    // TODO: Remove this line when granular notifications are implemented
    BOOL            _adding @accessors(property=adding);
}

+ (id)proxyForObject:(CPObject)anObject
{
    var proxy = anObject[KVOProxyKey];

    if (proxy)
        return proxy;

    return [[self alloc] initWithTarget:anObject];
}

- (id)initWithTarget:(id)aTarget
{
    if (self = [super init])
    {
        _targetObject       = aTarget;
        _nativeClass        = [aTarget class];
        _observersForKey    = {};
        _changesForKey      = {};
        _nestingForKey      = {};
        _observersForKeyLength = 0;

        [self _replaceClass];
        aTarget[KVOProxyKey] = self;
    }
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
    var methods = class_copyMethodList(_CPKVOModelSubclass);

    if ([_targetObject isKindOfClass:[CPDictionary class]])
        methods = methods.concat(class_copyMethodList(_CPKVOModelDictionarySubclass));

    class_addMethods(kvoClass, methods);

    _targetObject.isa = kvoClass;
}

- (void)_replaceModifiersForKey:(CPString)aKey
{
    if ([_replacedKeys containsObject:aKey] || ![_nativeClass automaticallyNotifiesObserversForKey:aKey])
        return;

    [_replacedKeys addObject:aKey];

    var theClass = _nativeClass,
        KVOClass = _targetObject.isa,
        capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substring(1);

    // Attribute and To-One Relationships
    var setKey_selector = sel_getUid("set" + capitalizedKey + ":"),
        setKey_method = class_getInstanceMethod(theClass, setKey_selector);

    if (setKey_method)
    {
        var setKey_method_imp = setKey_method.method_imp;

        class_addMethod(KVOClass, setKey_selector, function(self, _cmd, anObject)
        {
            [self willChangeValueForKey:aKey];

            setKey_method_imp(self, _cmd, anObject);

            [self didChangeValueForKey:aKey];
        }, "");
    }

    // FIXME: Deprecated.
    var _setKey_selector = sel_getUid("_set" + capitalizedKey + ":"),
        _setKey_method = class_getInstanceMethod(theClass, _setKey_selector);

    if (_setKey_method)
    {
        var _setKey_method_imp = _setKey_method.method_imp;

        class_addMethod(KVOClass, _setKey_selector, function(self, _cmd, anObject)
        {
            [self willChangeValueForKey:aKey];

            _setKey_method_imp(self, _cmd, anObject);

            [self didChangeValueForKey:aKey];
        }, "");
    }

    // Ordered To-Many Relationships
    var insertObject_inKeyAtIndex_selector = sel_getUid("insertObject:in" + capitalizedKey + "AtIndex:"),
        insertObject_inKeyAtIndex_method =
            class_getInstanceMethod(theClass, insertObject_inKeyAtIndex_selector),

        insertKey_atIndexes_selector = sel_getUid("insert" + capitalizedKey + ":atIndexes:"),
        insertKey_atIndexes_method =
            class_getInstanceMethod(theClass, insertKey_atIndexes_selector),

        removeObjectFromKeyAtIndex_selector = sel_getUid("removeObjectFrom" + capitalizedKey + "AtIndex:"),
        removeObjectFromKeyAtIndex_method =
            class_getInstanceMethod(theClass, removeObjectFromKeyAtIndex_selector),

        removeKeyAtIndexes_selector = sel_getUid("remove" + capitalizedKey + "AtIndexes:"),
        removeKeyAtIndexes_method = class_getInstanceMethod(theClass, removeKeyAtIndexes_selector);

    if ((insertObject_inKeyAtIndex_method || insertKey_atIndexes_method) &&
        (removeObjectFromKeyAtIndex_method || removeKeyAtIndexes_method))
    {
        if (insertObject_inKeyAtIndex_method)
        {
            var insertObject_inKeyAtIndex_method_imp = insertObject_inKeyAtIndex_method.method_imp;

            class_addMethod(KVOClass, insertObject_inKeyAtIndex_selector, function(self, _cmd, anObject, anIndex)
            {
                [self willChange:CPKeyValueChangeInsertion
                 valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                          forKey:aKey];

                insertObject_inKeyAtIndex_method_imp(self, _cmd, anObject, anIndex);

                [self didChange:CPKeyValueChangeInsertion
                valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                         forKey:aKey];
            }, "");
        }

        if (insertKey_atIndexes_method)
        {
            var insertKey_atIndexes_method_imp = insertKey_atIndexes_method.method_imp;

            class_addMethod(KVOClass, insertKey_atIndexes_selector, function(self, _cmd, objects, indexes)
            {
                [self willChange:CPKeyValueChangeInsertion
                 valuesAtIndexes:[indexes copy]
                          forKey:aKey];

                insertKey_atIndexes_method_imp(self, _cmd, objects, indexes);

                [self didChange:CPKeyValueChangeInsertion
                valuesAtIndexes:[indexes copy]
                         forKey:aKey];
            }, "");
        }

        if (removeObjectFromKeyAtIndex_method)
        {
            var removeObjectFromKeyAtIndex_method_imp = removeObjectFromKeyAtIndex_method.method_imp;

            class_addMethod(KVOClass, removeObjectFromKeyAtIndex_selector, function(self, _cmd, anIndex)
            {
                [self willChange:CPKeyValueChangeRemoval
                 valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                          forKey:aKey];

                removeObjectFromKeyAtIndex_method_imp(self, _cmd, anIndex);

                [self didChange:CPKeyValueChangeRemoval
                valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                         forKey:aKey];
            }, "");
        }

        if (removeKeyAtIndexes_method)
        {
            var removeKeyAtIndexes_method_imp = removeKeyAtIndexes_method.method_imp;

            class_addMethod(KVOClass, removeKeyAtIndexes_selector, function(self, _cmd, indexes)
            {
                [self willChange:CPKeyValueChangeRemoval
                 valuesAtIndexes:[indexes copy]
                          forKey:aKey];

                removeKeyAtIndexes_method_imp(self, _cmd, indexes);

                [self didChange:CPKeyValueChangeRemoval
                valuesAtIndexes:[indexes copy]
                         forKey:aKey];
            }, "");
        }

        // These are optional.
        var replaceObjectInKeyAtIndex_withObject_selector =
                sel_getUid("replaceObjectIn" + capitalizedKey + "AtIndex:withObject:"),
            replaceObjectInKeyAtIndex_withObject_method =
                class_getInstanceMethod(theClass, replaceObjectInKeyAtIndex_withObject_selector);

        if (replaceObjectInKeyAtIndex_withObject_method)
        {
            var replaceObjectInKeyAtIndex_withObject_method_imp =
                    replaceObjectInKeyAtIndex_withObject_method.method_imp;

            class_addMethod(KVOClass, replaceObjectInKeyAtIndex_withObject_selector,
            function(self, _cmd, anIndex, anObject)
            {
                [self willChange:CPKeyValueChangeReplacement
                 valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                          forKey:aKey];

                replaceObjectInKeyAtIndex_withObject_method_imp(self, _cmd, anIndex, anObject);

                [self didChange:CPKeyValueChangeReplacement
                valuesAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]
                         forKey:aKey];
            }, "");
        }

        var replaceKeyAtIndexes_withKey_selector =
                sel_getUid("replace" + capitalizedKey + "AtIndexes:with" + capitalizedKey + ":"),
            replaceKeyAtIndexes_withKey_method =
                class_getInstanceMethod(theClass, replaceKeyAtIndexes_withKey_selector);

        if (replaceKeyAtIndexes_withKey_method)
        {
            var replaceKeyAtIndexes_withKey_method_imp = replaceKeyAtIndexes_withKey_method.method_imp;

            class_addMethod(KVOClass, replaceKeyAtIndexes_withKey_selector, function(self, _cmd, indexes, objects)
            {
                [self willChange:CPKeyValueChangeReplacement
                 valuesAtIndexes:[indexes copy]
                          forKey:aKey];

                replaceObjectInKeyAtIndex_withObject_method_imp(self, _cmd, indexes, objects);

                [self didChange:CPKeyValueChangeReplacement
                valuesAtIndexes:[indexes copy]
                         forKey:aKey];
            }, "");
        }
    }

    // Unordered To-Many Relationships
    var addKeyObject_selector = sel_getUid("add" + capitalizedKey + "Object:"),
        addKeyObject_method = class_getInstanceMethod(theClass, addKeyObject_selector),

        addKey_selector = sel_getUid("add" + capitalizedKey + ":"),
        addKey_method = class_getInstanceMethod(theClass, addKey_selector),

        removeKeyObject_selector = sel_getUid("remove" + capitalizedKey + "Object:"),
        removeKeyObject_method = class_getInstanceMethod(theClass, removeKeyObject_selector),

        removeKey_selector = sel_getUid("remove" + capitalizedKey + ":"),
        removeKey_method = class_getInstanceMethod(theClass, removeKey_selector);

    if ((addKeyObject_method || addKey_method) && (removeKeyObject_method || removeKey_method))
    {
        if (addKeyObject_method)
        {
            var addKeyObject_method_imp = addKeyObject_method.method_imp;

            class_addMethod(KVOClass, addKeyObject_selector, function(self, _cmd, anObject)
            {
                [self willChangeValueForKey:aKey
                            withSetMutation:CPKeyValueUnionSetMutation
                               usingObjects:[CPSet setWithObject:anObject]];

                addKeyObject_method_imp(self, _cmd, anObject);

                [self didChangeValueForKey:aKey
                           withSetMutation:CPKeyValueUnionSetMutation
                              usingObjects:[CPSet setWithObject:anObject]];
            }, "");
        }

        if (addKey_method)
        {
            var addKey_method_imp = addKey_method.method_imp;

            class_addMethod(KVOClass, addKey_selector, function(self, _cmd, objects)
            {
                [self willChangeValueForKey:aKey
                            withSetMutation:CPKeyValueUnionSetMutation
                               usingObjects:[objects copy]];

                addKey_method_imp(self, _cmd, objects);

                [self didChangeValueForKey:aKey
                           withSetMutation:CPKeyValueUnionSetMutation
                              usingObjects:[objects copy]];
            }, "");
        }

        if (removeKeyObject_method)
        {
            var removeKeyObject_method_imp = removeKeyObject_method.method_imp;

            class_addMethod(KVOClass, removeKeyObject_selector, function(self, _cmd, anObject)
            {
                [self willChangeValueForKey:aKey
                            withSetMutation:CPKeyValueMinusSetMutation
                               usingObjects:[CPSet setWithObject:anObject]];

                removeKeyObject_method_imp(self, _cmd, anObject);

                [self didChangeValueForKey:aKey
                           withSetMutation:CPKeyValueMinusSetMutation
                              usingObjects:[CPSet setWithObject:anObject]];
            }, "");
        }

        if (removeKey_method)
        {
            var removeKey_method_imp = removeKey_method.method_imp;

            class_addMethod(KVOClass, removeKey_selector, function(self, _cmd, objects)
            {
                [self willChangeValueForKey:aKey
                            withSetMutation:CPKeyValueMinusSetMutation
                               usingObjects:[objects copy]];

                removeKey_method_imp(self, _cmd, objects);

                [self didChangeValueForKey:aKey
                           withSetMutation:CPKeyValueMinusSetMutation
                              usingObjects:[objects copy]];
            }, "");
        }

        // intersect<Key>: is optional.
        var intersectKey_selector = sel_getUid("intersect" + capitalizedKey + ":"),
            intersectKey_method = class_getInstanceMethod(theClass, intersectKey_selector);

        if (intersectKey_method)
        {
            var intersectKey_method_imp = intersectKey_method.method_imp;

            class_addMethod(KVOClass, intersectKey_selector, function(self, _cmd, aSet)
            {
                [self willChangeValueForKey:aKey
                            withSetMutation:CPKeyValueIntersectSetMutation
                               usingObjects:[aSet copy]];

                intersectKey_method_imp(self, _cmd, aSet);

                [self didChangeValueForKey:aKey
                           withSetMutation:CPKeyValueIntersectSetMutation
                              usingObjects:[aSet copy]];
            }, "");
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

        //observe key paths of objects other then ourselves, so we are notified of the changes
        //use CPKeyValueObservingOptionPrior to ensure proper wrapping around changes
        //so CPKeyValueObservingOptionPrior and CPKeyValueObservingOptionOld can be fulfilled even for dependent keys
        if (affectingKey.indexOf(@".") !== -1)
            [_targetObject addObserver:self forKeyPath:affectingKey options:CPKeyValueObservingOptionPrior | kvoNewAndOld  context:nil];
        else
            [self _replaceModifiersForKey:affectingKey];
    }
}

- (void)observeValueForKeyPath:(CPString)theKeyPath ofObject:(id)theObject change:(CPDictionary)theChanges context:(id)theContext
{
    // Fire change events for the dependent keys
    var dependentKeysForClass = _nativeClass[DependentKeysKey],
        dependantKeys = [dependentKeysForClass[theKeyPath] allObjects],
        isBeforeFlag = !![theChanges objectForKey:CPKeyValueChangeNotificationIsPriorKey];

    for (var i = 0; i < [dependantKeys count]; i++)
    {
        var dependantKey = [dependantKeys objectAtIndex:i];
        [self _sendNotificationsForKey:dependantKey changeOptions:theChanges isBefore:isBeforeFlag];
    }
}

- (void)_addObserver:(id)anObserver forKeyPath:(CPString)aPath options:(unsigned)options context:(id)aContext
{
    if (!anObserver)
        return;

    var forwarder = nil;

    if (aPath.indexOf('.') !== CPNotFound && aPath.charAt(0) !== '@')
        forwarder = [[_CPKVOForwardingObserver alloc] initWithKeyPath:aPath object:_targetObject observer:anObserver options:options context:aContext];
    else
        [self _replaceModifiersForKey:aPath];

    var observers = _observersForKey[aPath];

    if (!observers)
    {
        observers = @{};
        _observersForKey[aPath] = observers;
        _observersForKeyLength++;
    }

    [observers setObject:_CPKVOInfoMake(anObserver, options, aContext, forwarder) forKey:[anObserver UID]];

    if (options & CPKeyValueObservingOptionInitial)
    {
        var newValue = [_targetObject valueForKeyPath:aPath];

        if (newValue === nil || newValue === undefined)
            newValue = [CPNull null];

        var changes = @{ CPKeyValueChangeNewKey: newValue };
        [anObserver observeValueForKeyPath:aPath ofObject:_targetObject change:changes context:aContext];
    }
}

- (void)_removeObserver:(id)anObserver forKeyPath:(CPString)aPath
{
    var observers = _observersForKey[aPath];

    if (!observers)
    {
        // TODO: Remove this line when granular notifications are implemented
        if (!_adding)
            CPLog.warn(@"Cannot remove an observer %@ for the key path \"%@\" from %@ because it is not registered as an observer.", _targetObject, aPath, anObserver);

        return;
    }

    if (aPath.indexOf('.') != CPNotFound)
    {
        // During cib instantiation, it is possible for the forwarder to not yet be available,
        // so we have to check for nil.
        var observer = [observers objectForKey:[anObserver UID]],
            forwarder = observer ? observer.forwarder : nil;

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
        if (changes)
        {
            // "willChange:X" nesting.
            var level = _nestingForKey[aKey];

            if (!level)
                [CPException raise:CPInternalInconsistencyException reason:@"_changesForKey without _nestingForKey"];

            _nestingForKey[aKey] = level + 1;
            // Only notify on the first willChange..., silently note any following nested calls.
            return;
        }

        _nestingForKey[aKey] = 1;

        changes = changeOptions;

        var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey],
            setMutationKind = changes[_CPKeyValueChangeSetMutationKindKey];

        if (setMutationKind)
        {
            var setMutationObjects = [changes[_CPKeyValueChangeSetMutationObjectsKey] copy],
                setExistingObjects = [[_targetObject valueForKey: aKey] copy];

            if (setMutationKind == CPKeyValueMinusSetMutation)
            {
                [setExistingObjects intersectSet: setMutationObjects];
                [changes setValue:setExistingObjects forKey:CPKeyValueChangeOldKey];
            }
            else if (setMutationKind === CPKeyValueIntersectSetMutation || setMutationKind === CPKeyValueSetSetMutation)
            {
                [setExistingObjects minusSet: setMutationObjects];
                [changes setValue:setExistingObjects forKey:CPKeyValueChangeOldKey];
            }

            //for unordered to-many relationships (CPSet) even new values can only be calculated before!!!
            if (setMutationKind === CPKeyValueUnionSetMutation || setMutationKind === CPKeyValueSetSetMutation)
            {
                [setMutationObjects minusSet: setExistingObjects];
                //hide new value (for CPKeyValueObservingOptionPrior messages)
                //as long as "didChangeValue..." is not yet called!
                changes[_CPKeyValueChangeSetMutationNewValueKey] = setMutationObjects;
            }
        }
        else if (indexes)
        {
            var type = [changes objectForKey:CPKeyValueChangeKindKey];

            // for ordered to-many relationships, oldvalue is only sensible for replace and remove
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
        var level = _nestingForKey[aKey];

        if (!changes || !level)
        {
            if (_targetObject._willChangeMessageCounter && _targetObject._willChangeMessageCounter[aKey])
            {
                // Close unobserved willChange for a given key.
                _targetObject._willChangeMessageCounter[aKey] -= 1;

                if (!_targetObject._willChangeMessageCounter[aKey])
                    delete _targetObject._willChangeMessageCounter[aKey];

                return;
            }
            else
                [CPException raise:@"CPKeyValueObservingException" reason:@"'didChange...' message called without prior call of 'willChange...'"];
        }

        _nestingForKey[aKey] = level - 1;

        if (level - 1 > 0)
        {
            // willChange... was called multiple times. Only fire observation notifications when
            // didChange... has been called an equal number of times.
            return;
        }

        delete _nestingForKey[aKey];

        [changes removeObjectForKey:CPKeyValueChangeNotificationIsPriorKey];

        var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey],
            setMutationKind = changes[_CPKeyValueChangeSetMutationKindKey];

        if (setMutationKind)
        {
            //old and new values for unordered to-many relationships can only be calculated before
            //set recalculated hidden new value as soon as "didChangeValue..." is called!
            var newValue = changes[_CPKeyValueChangeSetMutationNewValueKey];
            [changes setValue:newValue forKey:CPKeyValueChangeNewKey];

            //delete hidden values
            delete changes[_CPKeyValueChangeSetMutationNewValueKey];
            delete changes[_CPKeyValueChangeSetMutationObjectsKey];
            delete changes[_CPKeyValueChangeSetMutationKindKey];
        }
        else if (indexes)
        {
            var type = [changes objectForKey:CPKeyValueChangeKindKey];

            // for ordered to-many relationships, newvalue is only sensible for replace and insert
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

        delete _changesForKey[aKey];
    }

    var observers = [_observersForKey[aKey] allValues],
        count = observers ? observers.length : 0;

    while (count--)
    {
        var observerInfo = observers[count];

        if (!isBefore || (observerInfo.options & CPKeyValueObservingOptionPrior))
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

    var changeOptions = @{ CPKeyValueChangeKindKey: CPKeyValueChangeSetting };

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

    var changeOptions = @{ CPKeyValueChangeKindKey: change, CPKeyValueChangeIndexesKey: indexes };

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

- (void)willChangeValueForKey:(CPString)aKey withSetMutation:(CPKeyValueSetMutationKind)mutationKind usingObjects:(CPSet)objects
{
    var superClass = [self class],
        methodSelector = @selector(willChangeValueForKey:withSetMutation:usingObjects:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, aKey, mutationKind, objects);

    if (!aKey)
        return;

    var changeKind = _changeKindForSetMutationKind(mutationKind),
        changeOptions = @{ CPKeyValueChangeKindKey: changeKind };

    //set hidden change-dict ivars to support unordered to-many relationships
    changeOptions[_CPKeyValueChangeSetMutationObjectsKey] = objects;
    changeOptions[_CPKeyValueChangeSetMutationKindKey] = mutationKind;

    [[_CPKVOProxy proxyForObject:self] _sendNotificationsForKey:aKey changeOptions:changeOptions isBefore:YES];
}

- (void)didChangeValueForKey:(CPString)aKey withSetMutation:(CPKeyValueSetMutationKind)mutationKind usingObjects:(CPSet)objects
{
    var superClass = [self class],
        methodSelector = @selector(didChangeValueForKey:withSetMutation:usingObjects:),
        methodImp = class_getMethodImplementation(superClass, methodSelector);

    methodImp(self, methodSelector, aKey, mutationKind, objects);

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
    unsigned    _options;
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
    _options = options;

    var dotIndex = aKeyPath.indexOf('.');

    if (dotIndex === CPNotFound)
        [CPException raise:CPInvalidArgumentException reason:"Created _CPKVOForwardingObserver without compound key path: " + aKeyPath];

    _firstPart = aKeyPath.substring(0, dotIndex);
    _secondPart = aKeyPath.substring(dotIndex + 1);

    //become an observer of the first part of our key (a)
    [_object addObserver:self forKeyPath:_firstPart options:_options context:nil];

    //the current value of a (not the value of a.b)
    _value = [_object valueForKey:_firstPart];

    if (_value)
        [_value addObserver:self forKeyPath:_secondPart options:_options context:nil]; //we're observing b on current a

    return self;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    if (aKeyPath === _firstPart)
    {
        var oldValue = [_value valueForKeyPath:_secondPart],
            newValue = [_object valueForKeyPath:_firstPart + "." + _secondPart],
            pathChanges = @{
                    CPKeyValueChangeNewKey: newValue ? newValue : [CPNull null],
                    CPKeyValueChangeOldKey: oldValue ? oldValue : [CPNull null],
                    CPKeyValueChangeKindKey: CPKeyValueChangeSetting,
                };

        [_observer observeValueForKeyPath:_firstPart + "." + _secondPart ofObject:_object change:pathChanges context:_context];

        //since a has changed, we should remove ourselves as an observer of the old a, and observe the new one
        if (_value)
            [_value removeObserver:self forKeyPath:_secondPart];

        _value = [_object valueForKey:_firstPart];

        if (_value)
            [_value addObserver:self forKeyPath:_secondPart options:_options context:nil];
    }
    else
    {
        //a is the same, but a.b has changed -- nothing to do but forward this message along
        [_observer observeValueForKeyPath:_firstPart + "." + aKeyPath ofObject:_object change:changes context:_context];
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

var _CPKVOInfoMake = function(anObserver, theOptions, aContext, aForwarder)
{
    return {
        observer: anObserver,
        options: theOptions,
        context: aContext,
        forwarder: aForwarder
    };
};

@import "CPArray+KVO.j"
@import "CPSet+KVO.j"
