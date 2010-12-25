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


CPUndefinedKeyException     = @"CPUndefinedKeyException";
CPTargetObjectUserInfoKey   = @"CPTargetObjectUserInfoKey";
CPUnknownUserInfoKey        = @"CPUnknownUserInfoKey";

var CPObjectAccessorsForClassKey            = @"$CPObjectAccessorsForClassKey",
    CPObjectModifiersForClassKey            = @"$CPObjectModifiersForClassKey";

@implementation CPObject (CPKeyValueCoding)

+ (BOOL)accessInstanceVariablesDirectly
{
    return YES;
}

- (id)_arrayValueForKey:(CPString)aKey
{
    return [[_CPKVCArray alloc] initWithKey:aKey forProxyObject:self];
}

- (id)_setValueForKey:(CPString)aKey
{
    return [[_CPKVCSet alloc] initWithKey:aKey forProxyObject:self];
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

        // countOf means this might be an ordered to-many or unordered to-many
        else if ([theClass instancesRespondToSelector:sel_getUid("countOf" + capitalizedKey)])
        {
            // Ordered to-many
            if ([theClass instancesRespondToSelector:sel_getUid("objectIn" + capitalizedKey + "atIndex:")] ||
                [theClass instancesRespondToSelector:sel_getUid(aKey + "AtIndexes:")])
                accessor = accessors[aKey] = [1, @selector(_arrayValueForKey:)];

            // Unordered to-many
            else if ([theClass instancesRespondToSelector:sel_getUid("enumeratorOf" + capitalizedKey)] ||
                    [theClass instancesRespondToSelector:sel_getUid("memberOf" + capitalizedKey + ":")])
                accessor = accessors[aKey] = [1, @selector(_setValueForKey:)];
        }

        if (!accessor)
        {
            if (class_getInstanceVariable(theClass, string = underscoreKey) ||
                class_getInstanceVariable(theClass, string = "_" + isKey) ||
                class_getInstanceVariable(theClass, string = aKey) ||
                class_getInstanceVariable(theClass, string = isKey))
                accessor = accessors[aKey] = [2, string];

            else
                accessor = accessors[aKey] = [];
        }
    }

    switch (accessor[0])
    {
        case 0:     return objj_msgSend(self, accessor[1]);
        case 1:     return objj_msgSend(self, accessor[1], aKey);
        case 2:     if ([theClass accessInstanceVariablesDirectly])
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

    while (key = [keyEnumerator nextObject])
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
                            reason:[self description] + " is not key value coding-compliant for the key " + aKey
                          userInfo:[CPDictionary dictionaryWithObjects:[self, aKey] forKeys:[CPTargetObjectUserInfoKey, CPUnknownUserInfoKey]]] raise];
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

@import "CPKeyValueObserving.j"
