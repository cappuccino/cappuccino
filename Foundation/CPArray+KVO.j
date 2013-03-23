/*
 * CPArray+KVO.j
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
@import "CPNull.j"
@import "_CPCollectionKVCOperators.j"

@class CPIndexSet

@implementation CPObject (CPArrayKVO)

- (id)mutableArrayValueForKey:(id)aKey
{
    return [[_CPKVCArray alloc] initWithKey:aKey forProxyObject:self];
}

- (id)mutableArrayValueForKeyPath:(id)aKeyPath
{
    var dotIndex = aKeyPath.indexOf(".");

    if (dotIndex < 0)
        return [self mutableArrayValueForKey:aKeyPath];

    var firstPart = aKeyPath.substring(0, dotIndex),
        lastPart = aKeyPath.substring(dotIndex + 1);

    return [[self valueForKeyPath:firstPart] mutableArrayValueForKeyPath:lastPart];
}

@end

@implementation _CPKVCArray : CPMutableArray
{
    id _proxyObject;
    id _key;

    SEL         _insertSEL;
    Function    _insert;

    SEL         _removeSEL;
    Function    _remove;

    SEL         _replaceSEL;
    Function    _replace;

    SEL         _insertManySEL;
    Function    _insertMany;

    SEL         _removeManySEL;
    Function    _removeMany;

    SEL         _replaceManySEL;
    Function    _replaceMany;

    SEL         _objectAtIndexSEL;
    Function    _objectAtIndex;

    SEL         _objectsAtIndexesSEL;
    Function    _objectsAtIndexes;

    SEL         _countSEL;
    Function    _count;

    SEL         _accessSEL;
    Function    _access;

    SEL         _setSEL;
    Function    _set;
}

+ (id)alloc
{
    var array = [];

    array.isa = self;

    var ivars = class_copyIvarList(self),
        count = ivars.length;

    while (count--)
        array[ivar_getName(ivars[count])] = nil;

    return array;
}

- (id)initWithKey:(id)aKey forProxyObject:(id)anObject
{
    self = [super init];

    _key = aKey;
    _proxyObject = anObject;

    var capitalizedKey = _key.charAt(0).toUpperCase() + _key.substring(1);

    _insertSEL = sel_getName(@"insertObject:in" + capitalizedKey + "AtIndex:");

    if ([_proxyObject respondsToSelector:_insertSEL])
        _insert = [_proxyObject methodForSelector:_insertSEL];

    _removeSEL = sel_getName(@"removeObjectFrom" + capitalizedKey + "AtIndex:");

    if ([_proxyObject respondsToSelector:_removeSEL])
        _remove = [_proxyObject methodForSelector:_removeSEL];

    _replaceSEL = sel_getName(@"replaceObjectIn" + capitalizedKey + "AtIndex:withObject:");

    if ([_proxyObject respondsToSelector:_replaceSEL])
        _replace = [_proxyObject methodForSelector:_replaceSEL];

    _insertManySEL = sel_getName(@"insert" + capitalizedKey + ":atIndexes:");

    if ([_proxyObject respondsToSelector:_insertManySEL])
        _insertMany = [_proxyObject methodForSelector:_insertManySEL];

    _removeManySEL = sel_getName(@"remove" + capitalizedKey + "AtIndexes:");

    if ([_proxyObject respondsToSelector:_removeManySEL])
        _removeMany = [_proxyObject methodForSelector:_removeManySEL];

    _replaceManySEL = sel_getName(@"replace" + capitalizedKey + "AtIndexes:with" + capitalizedKey + ":");

    if ([_proxyObject respondsToSelector:_replaceManySEL])
        _replaceMany = [_proxyObject methodForSelector:_replaceManySEL];

    _objectAtIndexSEL = sel_getName(@"objectIn" + capitalizedKey + "AtIndex:");

    if ([_proxyObject respondsToSelector:_objectAtIndexSEL])
        _objectAtIndex = [_proxyObject methodForSelector:_objectAtIndexSEL];

    _objectsAtIndexesSEL = sel_getName(_key + "AtIndexes:");

    if ([_proxyObject respondsToSelector:_objectsAtIndexesSEL])
        _objectsAtIndexes = [_proxyObject methodForSelector:_objectsAtIndexesSEL];

    _countSEL = sel_getName(@"countOf" + capitalizedKey);

    if ([_proxyObject respondsToSelector:_countSEL])
        _count = [_proxyObject methodForSelector:_countSEL];

    _accessSEL = sel_getName(_key);

    if ([_proxyObject respondsToSelector:_accessSEL])
        _access = [_proxyObject methodForSelector:_accessSEL];

    _setSEL = sel_getName(@"set" + capitalizedKey + ":");

    if ([_proxyObject respondsToSelector:_setSEL])
        _set = [_proxyObject methodForSelector:_setSEL];

    return self;
}

- (id)copy
{
    var i = 0,
        theCopy = [],
        count = [self count];

    for (; i < count; i++)
        [theCopy addObject:[self objectAtIndex:i]];

    return theCopy;
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

- (int)indexOfObject:(CPObject)anObject inRange:(CPRange)aRange
{
    var index = aRange.location,
        count = aRange.length,
        shouldIsEqual = !!anObject.isa;

    for (; index < count; ++index)
    {
        var object = [self objectAtIndex:index];

        if (anObject === object || shouldIsEqual && !!object.isa && [anObject isEqual:object])
            return index;
    }

    return CPNotFound;
}

- (int)indexOfObject:(CPObject)anObject
{
    return [self indexOfObject:anObject inRange:CPMakeRange(0, [self count])];
}

- (int)indexOfObjectIdenticalTo:(CPObject)anObject inRange:(CPRange)aRange
{
    var index = aRange.location,
        count = aRange.length;

    for (; index < count; ++index)
        if (anObject === [self objectAtIndex:index])
            return index;

    return CPNotFound;
}

- (int)indexOfObjectIdenticalTo:(CPObject)anObject
{
    return [self indexOfObjectIdenticalTo:anObject inRange:CPMakeRange(0, [self count])];
}

- (id)objectAtIndex:(unsigned)anIndex
{
    return [[self objectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]] firstObject];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)theIndexes
{
    if (_objectsAtIndexes)
        return _objectsAtIndexes(_proxyObject, _objectsAtIndexesSEL, theIndexes);

    if (_objectAtIndex)
    {
        var index = CPNotFound,
            objects = [];

        while ((index = [theIndexes indexGreaterThanIndex:index]) !== CPNotFound)
            objects.push(_objectAtIndex(_proxyObject, _objectAtIndexSEL, index));

        return objects;
    }

    return [[self _representedObject] objectsAtIndexes:theIndexes];
}

- (void)addObject:(id)anObject
{
    [self insertObject:anObject atIndex:[self count]];
}

- (void)addObjectsFromArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    [self insertObjects:anArray atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange([self count], count)]];
}

- (void)insertObject:(id)anObject atIndex:(unsigned)anIndex
{
    [self insertObjects:[anObject] atIndexes:[CPIndexSet indexSetWithIndex:anIndex]];
}

- (void)insertObjects:(CPArray)theObjects atIndexes:(CPIndexSet)theIndexes
{
    if (_insertMany)
        _insertMany(_proxyObject, _insertManySEL, theObjects, theIndexes);
    else if (_insert)
    {
        var indexesArray = [];
        [theIndexes getIndexes:indexesArray maxCount:-1 inIndexRange:nil];

        for (var index = 0; index < [indexesArray count]; index++)
        {
            var objectIndex = [indexesArray objectAtIndex:index],
                object = [theObjects objectAtIndex:index];

            _insert(_proxyObject, _insertSEL, object, objectIndex);
        }
    }
    else
    {
        var target = [[self _representedObject] copy];

        [target insertObjects:theObjects atIndexes:theIndexes];
        [self _setRepresentedObject:target];
    }
}

- (void)removeObject:(id)anObject
{
    [self removeObject:anObject inRange:CPMakeRange(0, [self count])];
}

- (void)removeObjectsInArray:(CPArray)theObjects
{
    if (_removeMany)
    {
        var indexes = [CPIndexSet indexSet],
            index = [theObjects count],
            position = 0,
            count = [self count];

        while (index--)
        {
            while ((position = [self indexOfObject:[theObjects objectAtIndex:index] inRange:CPMakeRange(position + 1, count)]) !== CPNotFound)
                [indexes addIndex:position];
        }

        _removeMany(_proxyObject, _removeManySEL, indexes);
    }
    else if (_remove)
    {
        var index = [theObjects count],
            position;
        while (index--)
        {
            while ((position = [self indexOfObject:[theObjects objectAtIndex:index]]) !== CPNotFound)
                _remove(_proxyObject, _removeSEL, position);
        }
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target removeObjectsInArray:theObjects];
        [self _setRepresentedObject:target];
    }
}

- (void)removeObject:(id)theObject inRange:(CPRange)theRange
{
    if (_remove)
        _remove(_proxyObject, _removeSEL, [self indexOfObject:theObject inRange:theRange]);
    else if (_removeMany)
    {
        var index = [self indexOfObject:theObject inRange:theRange];
        _removeMany(_proxyObject, _removeManySEL, [CPIndexSet indexSetWithIndex:index]);
    }
    else
    {
        var index;

        while ((index = [self indexOfObject:theObject inRange:theRange]) !== CPNotFound)
        {
            [self removeObjectAtIndex:index];
            theRange = CPIntersectionRange(CPMakeRange(index, self.length - index), theRange);
        }
    }
}

- (void)removeLastObject
{
    [self removeObjectsAtIndexes:[CPIndexSet indexSetWithIndex:[self count] - 1]];
}

- (void)removeObjectAtIndex:(unsigned)anIndex
{
    [self removeObjectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex]];
}

- (void)removeObjectsAtIndexes:(CPIndexSet)theIndexes
{
    if (_removeMany)
        _removeMany(_proxyObject, _removeManySEL, theIndexes);
    else if (_remove)
    {
        var index = [theIndexes lastIndex];

        while (index !== CPNotFound)
        {
            _remove(_proxyObject, _removeSEL, index)
            index = [theIndexes indexLessThanIndex:index];
        }
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target removeObjectsAtIndexes:theIndexes];
        [self _setRepresentedObject:target];
    }
}

- (void)replaceObjectAtIndex:(unsigned)anIndex withObject:(id)anObject
{
    [self replaceObjectsAtIndexes:[CPIndexSet indexSetWithIndex:anIndex] withObjects:[anObject]]
}

- (void)replaceObjectsAtIndexes:(CPIndexSet)theIndexes withObjects:(CPArray)theObjects
{
    if (_replaceMany)
        return _replaceMany(_proxyObject, _replaceManySEL, theIndexes, theObjects);
    else if (_replace)
    {
        var i = 0,
            index = [theIndexes firstIndex];

        while (index !== CPNotFound)
        {
            _replace(_proxyObject, _replaceSEL, index, [theObjects objectAtIndex:i++]);
            index = [theIndexes indexGreaterThanIndex:index];
        }
    }
    else
    {
        var target = [[self _representedObject] copy];
        [target replaceObjectsAtIndexes:theIndexes withObjects:theObjects];
        [self _setRepresentedObject:target];
    }
}

@end


// KVC on CPArray objects act on each item of the array, rather than on the array itself

@implementation CPArray (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if (aKey.charAt(0) === "@")
    {
        if (aKey.indexOf(".") !== -1)
            [CPException raise:CPInvalidArgumentException reason:"called valueForKey: on an array with a complex key (" + aKey + "). use valueForKeyPath:"];

        if (aKey === "@count")
            return self.length;

        return [self valueForUndefinedKey:aKey];
    }
    else
    {
        var newArray = [],
            enumerator = [self objectEnumerator],
            object;

        while ((object = [enumerator nextObject]) !== nil)
        {
            var value = [object valueForKey:aKey];

            if (value === nil || value === undefined)
                value = [CPNull null];

            newArray.push(value);
        }

        return newArray;
    }
}

- (id)valueForKeyPath:(CPString)aKeyPath
{
    if (!aKeyPath)
        [self valueForUndefinedKey:@"<empty path>"];

    if (aKeyPath.charAt(0) === "@")
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

        return [_CPCollectionKVCOperator performOperation:operator withCollection:self propertyPath:parameter];
    }
    else
    {
        var newArray = [],
            enumerator = [self objectEnumerator],
            object;

        while ((object = [enumerator nextObject]) !== nil)
        {
            var value = [object valueForKeyPath:aKeyPath];

            if (value === nil || value === undefined)
                value = [CPNull null];

            newArray.push(value);
        }

        return newArray;
    }
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var enumerator = [self objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) !== nil)
        [object setValue:aValue forKey:aKey];
}

- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    var enumerator = [self objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) !== nil)
        [object setValue:aValue forKeyPath:aKeyPath];
}

@end

@implementation CPArray (KeyValueObserving)

/*!
    Raises an exception for any key path other than "@count".

    CPArray objects are not observable (except for @count), so this method raises an exception
    when invoked on an CPArray object. Instead of observing an array, observe the ordered
    to-many relationship for which the array is the collection of related objects.
*/
- (void)addObserver:(id)anObserver forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)anOptions context:(id)aContext
{
    if (aKeyPath !== @"@count")
        [CPException raise:CPInvalidArgumentException reason:"[CPArray " + CPStringFromSelector(_cmd) + "] is not supported. Key path: " + aKeyPath];
}

/*!
    Raises an exception for any key path other than "@count".

    CPArray objects are not observable (except for @count), so this method raises an exception
    when invoked on an CPArray object. Instead of observing an array, observe the ordered
    to-many relationship for which the array is the collection of related objects.
*/
- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aKeyPath
{
    if (aKeyPath !== @"@count")
        [CPException raise:CPInvalidArgumentException reason:"[CPArray " + CPStringFromSelector(_cmd) + "] is not supported. Key path: " + aKeyPath];
}

/*!
    Registers an observer to receive key value observer notifications for the specified key-path relative to the objects at the indexes.
*/
- (void)addObserver:(id)anObserver toObjectsAtIndexes:(CPIndexSet)indexes forKeyPath:(CPString)aKeyPath options:(unsigned)options context:(id)context
{
    var index = [indexes firstIndex];

    while (index >= 0)
    {
        [self[index] addObserver:anObserver forKeyPath:aKeyPath options:options context:context];

        index = [indexes indexGreaterThanIndex:index];
    }
}

/*!
    Removes anObserver from all key value observer notifications associated with the specified keyPath relative to the array’s objects at indexes.
*/
- (void)removeObserver:(id)anObserver fromObjectsAtIndexes:(CPIndexSet)indexes forKeyPath:(CPString)aKeyPath
{
    var index = [indexes firstIndex];

    while (index >= 0)
    {
        [self[index] removeObserver:anObserver forKeyPath:aKeyPath];

        index = [indexes indexGreaterThanIndex:index];
    }
}

@end
