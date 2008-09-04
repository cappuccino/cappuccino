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

import "CPObject.j"

@implementation CPObject(CPKeyValueCoding)

+ (BOOL)accessInstanceVariablesDirectly
{
    return YES;
}

+ (SEL)_accessorForKey:(CPString)aKey
{
    var capitalizedKey = aKey.charAt(0).toUpperCase() + aKey.substr(1),
        selector = CPSelectorFromString("get" + capitalizedKey);
    
    if ([self instancesRespondToSelector:selector] || 
        [self instancesRespondToSelector:selector = CPSelectorFromString(aKey)] || 
        [self instancesRespondToSelector:selector = CPSelectorFromString("is" + capitalizedKey)])
        return selector;
    
    return nil;
}

+ (SEL)_modifierForKey:(CPString)aKey
{
    var selector = CPSelectorFromString("set" + aKey.charAt(0).toUpperCase() + aKey.substr(1) + ':');

    if ([self instancesRespondToSelector:selector])
        return selector;

    return nil;
}

- (CPString)_ivarForKey:(CPString)aKey
{
    var ivar,
        isKey = "is" + aKey.charAt(0).toUpperCase() + aKey.substr(1);

    if (self[ivar = "_" + aKey] != undefined || self[ivar = "_" + isKey] != undefined || 
        self[ivar = aKey] != undefined || self[ivar = isKey] != undefined) ;
        return ivar;

    return nil;
}
    
- (id)valueForKey:(CPString)aKey
{
    var ivar,
        theClass = [self class],
        selector = [theClass _accessorForKey:aKey]

    if (selector)
        return [self performSelector:selector];
    else if([theClass accessInstanceVariablesDirectly] && (ivar = [self _ivarForKey:aKey]))
        return self[ivar];
    else 
        return [self valueForUndefinedKey:aKey];
}
    
- (id)valueForKeyPath:(CPString)aKeyPath
{
    var i = 0,
        keys = aKeyPath.split("."),
        count = keys.length,
        value = self;

    for(; i<count; ++i)
        value = [value valueForKey:keys[i]];

    return value;
}

- (id)valueForUndefinedKey:(CPString)aKey
{
    alert("IMPLEMENT EXCEPTIONS, also, valueForKey died.");
//    CPException.raise(CPUndefinedKeyException, "[<"+this.classObject().name()+" "+this+"> valueForKey()]: this class is not key value coding-compliant for the key "+aKey+".]");
}
    
- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    if (!aKeyPath) aKeyPath = "self";

    var i = 0,
        keys = aKeyPath.split("."),
        count = keys.length - 1,
        owner = self;

    for(; i < count; ++i) 
        owner = [owner valueForKey:keys[i]];
    
    [owner setValue:aValue forKey:keys[i]];
}
    
- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var ivar,
        theClass = [self class],
        selector = [theClass _modifierForKey:aKey];

    if (selector)
        [self performSelector:selector withObject:aValue];
    else if([theClass accessInstanceVariablesDirectly] && (ivar = [self _ivarForKey:aKey]))
        self[ivar] = aValue;
    else
        [self setValue:aValue forUndefinedKey:aKey];
}
    
- (void)setValue:(id)aValue forUndefinedKey:(CPString)aKey
{
    alert("IMPLEMENT EXCEPTIONS, also, setValueForKey died.");
//    CPException.raise(CPUndefinedKeyException, "[<"+this.className()+" "+this+"> setValueForKey()]: this class is not key value coding-compliant for the key "+aKey+".]");
}

@end