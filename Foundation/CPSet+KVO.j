/*
 * CPSet+KVO.j
 * Foundation
 *
 * Created by Daniel Stolzenberg.
 * Copyright 2010, University of Rostock
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

@import "CPSet.j"

@implementation CPObject (CPSetKVO)

- (id)mutableSetValueForKey:(id)aKey
{
    return [[_CPKVCSet alloc] initWithKey:aKey forProxyObject:self];
}

- (id)mutableSetValueForKeyPath:(id)aKeyPath
{
    var dotIndex = aKeyPath.indexOf(".");

    if (dotIndex < 0)
        return [self mutableSetValueForKey:aKeyPath];

    var firstPart = aKeyPath.substring(0, dotIndex),
        lastPart = aKeyPath.substring(dotIndex + 1);

    return [[self valueForKeyPath:firstPart] mutableSetValueForKeyPath:lastPart];
}

@end

@implementation _CPKVCSet : CPMutableSet
{
    id _proxyObject;
    id _key;


    SEL         _accessSEL;
    Function    _access;

    SEL         _setSEL;
    Function    _set;

    SEL         _countSEL;
    Function    _count;

    SEL         _enumeratorSEL;
    Function    _enumerator;
    
    SEL         _memberSEL;
    Function    _member;
    
    SEL         _addSEL;
    Function    _add;
    
    SEL         _addManySEL;
    Function    _addMany;
    
    SEL         _removeSEL;
    Function    _remove;
    
    SEL         _removeManySEL;
    Function    _removeMany;
    
    SEL         _intersectSEL;
    Function    _intersect;
}

+ (id)alloc
{
    var set = [CPMutableSet set];

    set.isa = self;

    var ivars = class_copyIvarList(self),
        count = ivars.length;

    while (count--)
        set[ivar_getName(ivars[count])] = nil;

    return set;
}

- (id)initWithKey:(id)aKey forProxyObject:(id)anObject
{
    self = [super init];

    _key = aKey;
    _proxyObject = anObject;

    var capitalizedKey = _key.charAt(0).toUpperCase() + _key.substring(1);

    _accessSEL = sel_getName(_key);
    if ([_proxyObject respondsToSelector:_accessSEL])
        _access = [_proxyObject methodForSelector:_accessSEL];

    _setSEL = sel_getName(@"set"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_setSEL])
        _set = [_proxyObject methodForSelector:_setSEL];

    _countSEL = sel_getName(@"countOf"+capitalizedKey);
    if ([_proxyObject respondsToSelector:_countSEL])
        _count = [_proxyObject methodForSelector:_countSEL];

    _enumeratorSEL = sel_getName(@"enumeratorOf"+capitalizedKey);
    if ([_proxyObject respondsToSelector:_enumeratorSEL])
        _enumerator = [_proxyObject methodForSelector:_enumeratorSEL];

    _memberSEL = sel_getName(@"memberOf"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_memberSEL])
        _member = [_proxyObject methodForSelector:_memberSEL];

    _addSEL = sel_getName(@"add"+capitalizedKey+"Object:");
    if ([_proxyObject respondsToSelector:_addSEL])
        _add = [_proxyObject methodForSelector:_addSEL];

    _addManySEL = sel_getName(@"add"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_addManySEL])
        _addMany = [_proxyObject methodForSelector:_addManySEL];

    _removeSEL = sel_getName(@"remove"+capitalizedKey+"Object:");
    if ([_proxyObject respondsToSelector:_removeSEL])
        _remove = [_proxyObject methodForSelector:_removeSEL];

    _removeManySEL = sel_getName(@"remove"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_removeManySEL])
        _removeMany = [_proxyObject methodForSelector:_removeManySEL];

    _intersectSEL = sel_getName(@"intersect"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_intersectSEL])
        _intersect = [_proxyObject methodForSelector:_intersectSEL];

    return self;
}

- (id)_representedObject
{
    if (_access)
        return _access(_proxyObject, _accessSEL);

    return [_proxyObject valueForKey:_key];
}

- (void)_setRepresentedObject:(id)anObject
{
    if (_set)
        return _set(_proxyObject, _setSEL, anObject);

    [_proxyObject setValue:anObject forKey:_key];
}

- (unsigned)count
{
    if (_count)
        return _count(_proxyObject, _countSEL);

    return [[self _representedObject] count];
}

- (CPEnumerator)objectEnumerator
{
    if (_enumerator)
        return _enumerator(_proxyObject, _enumeratorSEL);

    return [[self _representedObject] objectEnumerator];
}

- (id)member:(id)anObject
{
    if (_member)
        return _member(_proxyObject, _memberSEL, anObject);

    return [[self _representedObject] member:anObject];
}

- (void)addObject:(id)anObject
{
    if (_add)
        _add(_proxyObject, _addSEL, anObject);
    else if(_addMany)
    {
        var objectSet = [CPSet setWithObject: anObject];
        _addMany(_proxyObject, _addManySEL, objectSet);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target addObject:anObject];
        [self _setRepresentedObject:target];
    }
}

- (void)addObjectsFromArray:(CPArray)objects
{
    if(_addMany)
    {
        var objectSet = [CPSet setWithArray: objects];
        _addMany(_proxyObject, _addManySEL, objectSet);
    }
    else if(_add)
    {
        var object, objectEnumerator = [objects objectEnumerator];
        while(object = [objectEnumerator nextObject])
            _add(_proxyObject, _addSEL, object);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target addObjectsFromArray:objects];
        [self _setRepresentedObject:target];
    }
}

- (void)unionSet:(CPSet)aSet
{
    if (_addMany)
        _addMany(_proxyObject, _addManySEL, aSet);
    else if(_add)
    {
        var object, objectEnumerator = [aSet objectEnumerator];
        while(object = [objectEnumerator nextObject])
            _add(_proxyObject, _addSEL, object);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target unionSet:aSet];
        [self _setRepresentedObject:target];
    }
}

- (void)removeObject:(id)anObject
{
    if (_remove)
        _remove(_proxyObject, _removeSEL, anObject);
    else if(_removeMany)
    {
        var objectSet = [CPSet setWithObject: anObject];
        _removeMany(_proxyObject, _removeManySEL, objectSet);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target removeObject:anObject];
        [self _setRepresentedObject:target];
    }
}

- (void)minusSet:(CPSet)aSet
{
    if(_removeMany)
        _removeMany(_proxyObject, _removeManySEL, aSet);
    else if(_remove)
    {
        var object, objectEnumerator = [aSet objectEnumerator];
        while(object = [objectEnumerator nextObject])
            _remove(_proxyObject, _removeSEL, object);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target minusSet:aSet];
        [self _setRepresentedObject:target];
    }
}

- (void)removeObjectsInArray:(CPArray)objects
{
    if(_removeMany)
    {
        var objectSet = [CPSet setWithArray:objects];
        _removeMany(_proxyObject, _removeManySEL, objectSet);
    }
    else if(_remove)
    {
        var object, objectEnumerator = [objects objectEnumerator];
        while(object = [objectEnumerator nextObject])
            _remove(_proxyObject, _removeSEL, object);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target removeObjectsInArray:objects];
        [self _setRepresentedObject:target];
    }
}

- (void)removeAllObjects
{
    if(_removeMany)
    {
        var allObjectsSet = [[self _representedObject] copy];
        _removeMany(_proxyObject, _removeManySEL, allObjectsSet);
    }
    else if(_remove)
    {
        var object, objectEnumerator = [[[self _representedObject] copy] objectEnumerator];
        while(object = [objectEnumerator nextObject])
            _remove(_proxyObject, _removeSEL, object);
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target removeAllObjects];
        [self _setRepresentedObject:target];
    }
}

- (void)intersectSet:(CPSet)aSet
{
    if(_intersect)
        _intersect(_proxyObject, _intersectSEL, aSet);
    else
    {
        var target = [[self _representedObject] copy];
        [target intersectSet:aSet];
        [self _setRepresentedObject:target];
    }
}

- (void)setSet:(CPSet)set
{
    [self _setRepresentedObject: set];
}

- (CPArray)allObjects
{
    return [[self _representedObject] allObjects];
}

- (id)anyObject
{
    return [[self _representedObject] anyObject];
}

- (BOOL)containsObject:(id)anObject
{
    return [[self _representedObject] containsObject: anObject];
}

- (BOOL)intersectsSet:(CPSet)aSet
{
    return [[self _representedObject] intersectsSet: aSet];
}

- (BOOL)isEqualToSet:(CPSet)aSet
{
    return [[self _representedObject] isEqualToSet: aSet];
}

- (id)copy
{
    return [[self _representedObject] copy];
}

@end

@implementation CPSet (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if (aKey.indexOf("@") === 0)
    {
        if (aKey.indexOf(".") !== -1)
            [CPException raise:CPInvalidArgumentException reason:"called valueForKey: on a set with a complex key ("+aKey+"). use valueForKeyPath:"];

        if (aKey == "@count")
            return [self count];

        return nil;
    }
    else
    {
        var valuesForKeySet = [CPSet set];
        var containedObject, containedObjectValue, containedObjectEnumerator = [self objectEnumerator];
        while(containedObject = [containedObjectEnumerator nextObject])
        {
            containedObjectValue = [containedObject valueForKey:aKey];
            if(containedObjectValue)
                [valuesForKeySet addObject:containedObjectValue];
        }
        return valuesForKeySet;
    }
}

- (id)valueForKeyPath:(CPString)aKeyPath
{
    if (aKeyPath.indexOf("@") === 0)
    {
        var dotIndex = aKeyPath.indexOf("."),
            operator,
            parameter;

        if (dotIndex !== -1)
        {
            operator = aKeyPath.substring(1, dotIndex);
            parameter = aKeyPath.substring(dotIndex + 1);
        }
        else
            operator = aKeyPath.substring(1);

        if (kvoOperators[operator])
            return kvoOperators[operator](self, _cmd, parameter);

        return nil;
    }
    else
    {
        var valuesForKeySet = [CPSet set];
        var containedObject, containedObjectValue, containedObjectEnumerator = [self objectEnumerator];
        while(containedObject = [containedObjectEnumerator nextObject])
        {
            containedObjectValue = [containedObject valueForKeyPath:aKeyPath];
            if(containedObjectValue)
                [valuesForKeySet addObject:containedObjectValue];
        }
        return valuesForKeySet;
    }
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var containedObject, containedObjectEnumerator = [self objectEnumerator];
    while (containedObject = [containedObjectEnumerator nextObject])
        [containedObject setValue:aValue forKey:aKey];
}

- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    var containedObject, containedObjectEnumerator = [self objectEnumerator];
    while (containedObject = [containedObjectEnumerator nextObject])
        [containedObject setValue:aValue forKeyPath:aKeyPath];
}

@end

var kvoOperators = [];

// FIXME: this is not DRY because the implementation in CPArray+KVO is merely the same!
// HACK: prevent these from becoming globals. workaround for obj-j "function foo(){}" behavior
var avgOperator, maxOperator, minOperator, countOperator, sumOperator;

kvoOperators["avg"] = function avgOperator(self, _cmd, param)
{
    //CPSet returns a CPSet - to obtain an array call allObjects
    var objects = [[self valueForKeyPath:param] allObjects],
        length = [objects count],
        index = length;
        average = 0.0;

    if (!length)
        return 0;

    while (index--)
        average += [objects[index] doubleValue];

    return average / length;
}

kvoOperators["max"] = function maxOperator(self, _cmd, param)
{
    //CPSet returns a CPSet - to obtain an array call allObjects
    var objects = [[self valueForKeyPath:param] allObjects],
        index = [objects count] - 1,
        max = [objects lastObject];

    while (index--)
    {
        var item = objects[index];
        if ([max compare:item] < 0)
            max = item;
    }

    return max;
}

kvoOperators["min"] = function minOperator(self, _cmd, param)
{
    //CPSet returns a CPSet - to obtain an array call allObjects
    var objects = [[self valueForKeyPath:param] allObjects],
        index = [objects count] - 1,
        min = [objects lastObject];

    while (index--)
    {
        var item = objects[index];
        if ([min compare:item] > 0)
            min = item;
    }

    return min;
}

kvoOperators["count"] = function countOperator(self, _cmd, param)
{
    return [self count];
}

kvoOperators["sum"] = function sumOperator(self, _cmd, param)
{
    //CPSet returns a CPSet - to obtain an array call allObjects
    var objects = [[self valueForKeyPath:param] allObjects],
        index = [objects count],
        sum = 0.0;

    while (index--)
        sum += [objects[index] doubleValue];

    return sum;
}


@implementation CPSet (CPKeyValueObserving)

- (void)addObserver:(id)observer forKeyPath:(CPString)aKeyPath options:(unsigned)options context:(id)context
{
    if ([isa instanceMethodForSelector:_cmd] === [CPSet instanceMethodForSelector:_cmd])
        [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPSet"];
    else
        [super addObserver:observer forKeyPath:aKeyPath options:options context:context];
}

-(void)removeObserver:(id)observer forKeyPath:(CPString)aKeyPath
{
    if ([isa instanceMethodForSelector:_cmd] === [CPSet instanceMethodForSelector:_cmd])
        [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPSet"];
    else
        [super removeObserver:observer forKeyPath:aKeyPath];
}

@end
