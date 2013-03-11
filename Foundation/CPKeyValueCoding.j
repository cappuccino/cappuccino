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

@import "CPArray.j"
@import "CPDictionary.j"
@import "CPException.j"
@import "CPIndexSet.j"
@import "CPNull.j"
@import "CPObject.j"
@import "CPSet.j"


CPUndefinedKeyException     = @"CPUndefinedKeyException";
CPTargetObjectUserInfoKey   = @"CPTargetObjectUserInfoKey";
CPUnknownUserInfoKey        = @"CPUnknownUserInfoKey";

var CPObjectAccessorsForClassKey = @"$CPObjectAccessorsForClassKey",
    CPObjectModifiersForClassKey = @"$CPObjectModifiersForClassKey";

@implementation CPObject (CPKeyValueCoding)

+ (BOOL)accessInstanceVariablesDirectly
{
    return YES;
}

- (id)valueForKey:(CPString)aKey
{
    var theClass = [self class],
        accessor = nil,
        accessors = theClass[CPObjectAccessorsForClassKey];

    if (!accessors)
        accessors = theClass[CPObjectAccessorsForClassKey] = { };

    if (accessors.hasOwnProperty(aKey))
        accessor = accessors[aKey];

    else
    {
        var string = nil,
            capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1),
            underscoreKey = nil,
            isKey = nil;

        // First search for accessor methods of the form -get<Key>, -<key>, -is<Key>
        // (the underscore versions are deprecated)
        if ([theClass instancesRespondToSelector:string = sel_getUid("get" + capitalizedKey)] ||
            [theClass instancesRespondToSelector:string = sel_getUid(aKey)] ||
            [theClass instancesRespondToSelector:string = sel_getUid((isKey = "is" + capitalizedKey))] ||
            //FIXME: is deprecated in Cocoa 10.3
            [theClass instancesRespondToSelector:string = sel_getUid("_get" + capitalizedKey)] ||
            //FIXME: is deprecated in Cocoa 10.3
            [theClass instancesRespondToSelector:string = sel_getUid((underscoreKey = "_" + aKey))] ||
            //FIXME: was NEVER supported by Cocoa
            [theClass instancesRespondToSelector:string = sel_getUid("_" + isKey)])
            accessor = accessors[aKey] = [0, string];

        else if ([theClass instancesRespondToSelector:sel_getUid("countOf" + capitalizedKey)])
        {
            // Otherwise, search for ordered to-many relationships:
            // -countOf<Key> and either of -objectIn<Key>atIndex: or -<key>AtIndexes:.
            if ([theClass instancesRespondToSelector:sel_getUid("objectIn" + capitalizedKey + "AtIndex:")] ||
                [theClass instancesRespondToSelector:sel_getUid(aKey + "AtIndexes:")])
                accessor = accessors[aKey] = [1];

            // Otherwise, search for unordered to-many relationships
            // -countOf<Key>, -enumeratorOf<Key>, and -memberOf<Key>:.
            else if ([theClass instancesRespondToSelector:sel_getUid("enumeratorOf" + capitalizedKey)] &&
                    [theClass instancesRespondToSelector:sel_getUid("memberOf" + capitalizedKey + ":")])
                accessor = accessors[aKey] = [2];
        }

        if (!accessor)
        {
            // Otherwise search for instance variable: _<key>, _is<Key>, key, is<Key>
            if (class_getInstanceVariable(theClass, string = underscoreKey) ||
                class_getInstanceVariable(theClass, string = "_" + isKey) ||
                class_getInstanceVariable(theClass, string = aKey) ||
                class_getInstanceVariable(theClass, string = isKey))
                accessor = accessors[aKey] = [3, string];

            // Otherwise return valueForUndefinedKey:
            else
                accessor = accessors[aKey] = [];
        }
    }

    switch (accessor[0])
    {
        case 0:
            return objj_msgSend(self, accessor[1]);

        case 1:
            // FIXME: We shouldn't be creating a new one every time.
            return [[_CPKeyValueCodingArray alloc] initWithTarget:self key:aKey];

        case 2:
            // FIXME: We shouldn't be creating a new one every time.
            return [[_CPKeyValueCodingSet alloc] initWithTarget:self key:aKey];

        case 3:
            if ([theClass accessInstanceVariablesDirectly])
                return self[accessor[1]];
    }

    return [self valueForUndefinedKey:aKey];
}

- (id)valueForKeyPath:(CPString)aKeyPath
{
    var firstDotIndex = aKeyPath.indexOf(".");

    if (firstDotIndex === CPNotFound)
        return [self valueForKey:aKeyPath];

    var firstKeyComponent = aKeyPath.substring(0, firstDotIndex),
        remainingKeyPath = aKeyPath.substring(firstDotIndex + 1),
        value = [self valueForKey:firstKeyComponent];

    return [value valueForKeyPath:remainingKeyPath];
}

- (CPDictionary)dictionaryWithValuesForKeys:(CPArray)keys
{
    var index = 0,
        count = keys.length,
        dictionary = @{};

    for (; index < count; ++index)
    {
        var key = keys[index],
            value = [self valueForKey:key];

        if (value === nil)
            [dictionary setObject:[CPNull null] forKey:key];

        else
            [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

- (id)valueForUndefinedKey:(CPString)aKey
{
    [[CPException exceptionWithName:CPUndefinedKeyException
                            reason:[self _objectDescription] + " is not key value coding-compliant for the key " + aKey
                          userInfo:@{ CPTargetObjectUserInfoKey: self, CPUnknownUserInfoKey: aKey }] raise];
}

- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    if (!aKeyPath)
        aKeyPath = @"self";

    var firstDotIndex = aKeyPath.indexOf(".");

    if (firstDotIndex === CPNotFound)
        return [self setValue:aValue forKey:aKeyPath];

    var firstKeyComponent = aKeyPath.substring(0, firstDotIndex),
        remainingKeyPath = aKeyPath.substring(firstDotIndex + 1),
        value = [self valueForKey:firstKeyComponent];

    return [value setValue:aValue forKeyPath:remainingKeyPath];
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var theClass = [self class],
        modifier = nil,
        modifiers = theClass[CPObjectModifiersForClassKey];

    if (!modifiers)
        modifiers = theClass[CPObjectModifiersForClassKey] = { };

    if (modifiers.hasOwnProperty(aKey))
        modifier = modifiers[aKey];

    else
    {
        var string = nil,
            capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1),
            isKey = nil;

        if ([theClass instancesRespondToSelector:string = sel_getUid("set" + capitalizedKey + ":")] ||
            //FIXME: deprecated in Cocoa 10.3
            [theClass instancesRespondToSelector:string = sel_getUid("_set" + capitalizedKey + ":")])
            modifier = modifiers[aKey] = [0, string];

        else if (class_getInstanceVariable(theClass, string = "_" + aKey) ||
            class_getInstanceVariable(theClass, string = "_" + (isKey = "is" + capitalizedKey)) ||
            class_getInstanceVariable(theClass, string = aKey) ||
            class_getInstanceVariable(theClass, string = isKey))
            modifier = modifiers[aKey] = [1, string];

        else
            modifier = modifiers[aKey] = [];
    }

    switch (modifier[0])
    {
        case 0:     return objj_msgSend(self, modifier[1], aValue);

        case 1:     if ([theClass accessInstanceVariablesDirectly])
                    {
                        [self willChangeValueForKey:aKey];

                        self[modifier[1]] = aValue;

                        return [self didChangeValueForKey:aKey];
                    }
    }

    return [self setValue:aValue forUndefinedKey:aKey];

}

- (void)setValuesForKeysWithDictionary:(CPDictionary)keyedValues
{
    var value,
        key,
        keyEnumerator = [keyedValues keyEnumerator];

    while ((key = [keyEnumerator nextObject]) !== nil)
    {
        value = [keyedValues objectForKey: key];

        if (value === [CPNull null])
            [self setValue: nil forKey: key];

        else
            [self setValue: value forKey: key];
    }
}

- (void)setValue:(id)aValue forUndefinedKey:(CPString)aKey
{
    [[CPException exceptionWithName:CPUndefinedKeyException
                            reason:[self _objectDescription] + " is not key value coding-compliant for the key " + aKey
                          userInfo:@{ CPTargetObjectUserInfoKey: self, CPUnknownUserInfoKey: aKey }] raise];
}

- (CPString)_objectDescription
{
    return "<" + [self className] + " 0x" + [CPString stringWithHash:[self UID]] + ">";
}

@end

@implementation CPDictionary (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if ([aKey hasPrefix:@"@"])
        return [super valueForKey:aKey.substr(1)];

    return [self objectForKey:aKey];
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    if (aValue !== nil)
        [self setObject:aValue forKey:aKey];

    else
        [self removeObjectForKey:aKey];
}

@end

@implementation CPNull (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    return self;
}

@end

@implementation _CPKeyValueCodingArray : CPArray
{
    id  _target;

    SEL _countOfSelector;
    SEL _objectInAtIndexSelector;
    SEL _atIndexesSelector;
}

- (id)initWithTarget:(id)aTarget key:(CPString)aKey
{
    self = [super init];

    if (self)
    {
        var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1);

        _target = aTarget;

        _countOfSelector = CPSelectorFromString("countOf" + capitalizedKey);

        _objectInAtIndexSelector = CPSelectorFromString("objectIn" + capitalizedKey + "AtIndex:");

        if (![_target respondsToSelector:_objectInAtIndexSelector])
            _objectInAtIndexSelector = nil;

        _atIndexesSelector = CPSelectorFromString(aKey + "AtIndexes:");

        if (![_target respondsToSelector:_atIndexesSelector])
            _atIndexesSelector = nil;
    }

    return self;
}

- (CPUInteger)count
{
    return objj_msgSend(_target, _countOfSelector);
}

- (id)objectAtIndex:(CPUInteger)anIndex
{
    if (_objectInAtIndexSelector)
        return objj_msgSend(_target, _objectInAtIndexSelector, anIndex);

    return objj_msgSend(_target, _atIndexesSelector, [CPIndexSet indexSetWithIndex:anIndex])[0];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    if (_atIndexesSelector)
        return objj_msgSend(_target, _atIndexesSelector, indexes);

    return [super objectsAtIndexes:indexes];
}

- (Class)classForCoder
{
    return [CPArray class];
}

- (id)copy
{
    // We do this to ensure we return a CPArray.
    return [CPArray arrayWithArray:self];
}

@end

@implementation _CPKeyValueCodingSet : CPSet
{
    id  _target;

    SEL _countOfSelector;
    SEL _enumeratorOfSelector;
    SEL _memberOfSelector;
}

// This allows things like setByAddingObject: to work (since they use [[self class] alloc] internally).
- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    return [[CPSet alloc] initWithObjects:objects count:aCount];
}

- (id)initWithTarget:(id)aTarget key:(CPString)aKey
{
    self = [super initWithObjects:nil count:0];

    if (self)
    {
        var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1);

        _target = aTarget;

        _countOfSelector = CPSelectorFromString("countOf" + capitalizedKey);
        _enumeratorOfSelector = CPSelectorFromString("enumeratorOf" + capitalizedKey);
        _memberOfSelector = CPSelectorFromString("memberOf" + capitalizedKey + ":");
    }

    return self;
}

- (CPUInteger)count
{
    return objj_msgSend(_target, _countOfSelector);
}

- (CPEnumerator)objectEnumerator
{
    return objj_msgSend(_target, _enumeratorOfSelector);
}

- (id)member:(id)anObject
{
    return objj_msgSend(_target, _memberOfSelector, anObject);
}

- (Class)classForCoder
{
    return [CPSet class];
}

- (id)copy
{
    // We do this to ensure we return a CPSet.
    return [CPSet setWithSet:self];
}

@end

@import "CPKeyValueObserving.j"
