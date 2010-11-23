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
@import "CPNull.j"
@import "CPObject.j"


var CPObjectAccessorsForClass   = nil,
    CPObjectModifiersForClass   = nil;

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

/* @ignore */
+ (SEL)_accessorForKey:(CPString)aKey
{
    var selector = nil,
        accessors = isa[CPObjectAccessorsForClassKey];

    if (accessors)
    {
        selector = accessors[aKey];

        if (selector)
            return selector === [CPNull null] ? nil : selector;
    }
    else
        accessors = isa[CPObjectAccessorsForClassKey] = {};

    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1);

    if ([self instancesRespondToSelector:selector = CPSelectorFromString("get" + capitalizedKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString(aKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString("is" + capitalizedKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString("_get" + capitalizedKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString("_" + aKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString("_is" + capitalizedKey)])
    {
        accessors[aKey] = selector;

        return selector;
    }

    accessors[aKey] = [CPNull null];

    return nil;
}

/* @ignore */
+ (SEL)_modifierForKey:(CPString)aKey
{
    if (!CPObjectModifiersForClass)
        CPObjectModifiersForClass = [CPDictionary dictionary];

    var UID = [isa UID],
        selector = nil,
        modifiers = [CPObjectModifiersForClass objectForKey:UID];

    if (modifiers)
    {
        selector = [modifiers objectForKey:aKey];

        if (selector)
            return selector === [CPNull null] ? nil : selector;
    }
    else
    {
        modifiers = [CPDictionary dictionary];

        [CPObjectModifiersForClass setObject:modifiers forKey:UID];
    }

    if (selector)
        return selector === [CPNull null] ? nil : selector;

    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1) + ':';

    if ([self instancesRespondToSelector:selector = CPSelectorFromString("set" + capitalizedKey)] ||
        [self instancesRespondToSelector:selector = CPSelectorFromString("_set" + capitalizedKey)])
    {
        [modifiers setObject:selector forKey:aKey];

        return selector;
    }

    [modifiers setObject:[CPNull null] forKey:aKey];

    return nil;
}

/* @ignore */
- (CPString)_ivarForKey:(CPString)aKey
{
    var ivar = '_' + aKey;

    if (typeof self[ivar] != "undefined")
        return ivar;

    var isKey = "is" + aKey.charAt(0).toUpperCase() + aKey.substr(1);

    ivar = '_' + isKey;

    if (typeof self[ivar] != "undefined")
        return ivar;

    ivar = aKey;

    if (typeof self[ivar] != "undefined")
        return ivar;

    ivar = isKey;

    if (typeof self[ivar] != "undefined")
        return ivar;

    return nil;
}

- (id)valueForKey:(CPString)aKey
{
    var theClass = [self class],
        selector = _accessorForKey(theClass, aKey);

    if (selector)
        return objj_msgSend(self, selector);

    if ([theClass accessInstanceVariablesDirectly])
    {
        var ivar = [self _ivarForKey:aKey];

        if (ivar)
            return self[ivar];
    }

    return [self valueForUndefinedKey:aKey];
}

- (id)valueForKeyPath:(CPString)aKeyPath
{
    var firstDotIndex = aKeyPath.indexOf(".");

    if (firstDotIndex === -1)
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
        dictionary = [CPDictionary dictionary];

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
                            reason:[self description] + " is not key value coding-compliant for the key " + aKey
                          userInfo:[CPDictionary dictionaryWithObjects:[self, aKey] forKeys:[CPTargetObjectUserInfoKey, CPUnknownUserInfoKey]]] raise];
}

- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    if (!aKeyPath) aKeyPath = @"self";

    var firstDotIndex = aKeyPath.indexOf(".");

    if (firstDotIndex === -1)
        return [self setValue:aValue forKey:aKeyPath];

    var firstKeyComponent = aKeyPath.substring(0, firstDotIndex),
        remainingKeyPath = aKeyPath.substring(firstDotIndex + 1),
        value = [self valueForKey:firstKeyComponent];

    return [value setValue:aValue forKeyPath:remainingKeyPath];
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var theClass = [self class],
        selector = [theClass _modifierForKey:aKey];

    if (selector)
        return objj_msgSend(self, selector, aValue);

    if ([theClass accessInstanceVariablesDirectly])
    {
        var ivar = [self _ivarForKey:aKey];

        if (ivar)
        {
            [self willChangeValueForKey:aKey];

            self[ivar] = aValue;

            [self didChangeValueForKey:aKey];

            return;
        }
    }

    [self setValue:aValue forUndefinedKey:aKey];
}

- (void)setValue:(id)aValue forUndefinedKey:(CPString)aKey
{
    [[CPException exceptionWithName:CPUndefinedKeyException
                            reason:[self description] + " is not key value coding-compliant for the key " + aKey
                          userInfo:[CPDictionary dictionaryWithObjects:[self, aKey] forKeys:[CPTargetObjectUserInfoKey, CPUnknownUserInfoKey]]] raise];
}

@end

var Null = [CPNull null];
var _accessorForKey = function(theClass, aKey)
{
    var selector = nil,
        accessors = theClass.isa[CPObjectAccessorsForClassKey];

    if (accessors)
    {
        selector = accessors[aKey];

        if (selector)
            return selector === Null ? nil : selector;
    }
    else
        accessors = theClass.isa[CPObjectAccessorsForClassKey] = {};

    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1);

    if ([theClass instancesRespondToSelector:selector = CPSelectorFromString("get" + capitalizedKey)] ||
        [theClass instancesRespondToSelector:selector = CPSelectorFromString(aKey)] ||
        [theClass instancesRespondToSelector:selector = CPSelectorFromString("is" + capitalizedKey)] ||
        [theClass instancesRespondToSelector:selector = CPSelectorFromString("_get" + capitalizedKey)] ||
        [theClass instancesRespondToSelector:selector = CPSelectorFromString("_" + aKey)] ||
        [theClass instancesRespondToSelector:selector = CPSelectorFromString("_is" + capitalizedKey)])
    {
        accessors[aKey] = selector;

        return selector;
    }

    accessors[aKey] = Null;

    return nil;
}

@implementation CPDictionary (KeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if ([aKey hasPrefix:@"@"])
        return [super valueForKey:aKey.substr(1)];

    return [self objectForKey:aKey];
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

@end

@implementation CPNull (KeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    return self;
}

@end

@import "CPKeyValueObserving.j"
@import "CPArray+KVO.j"
