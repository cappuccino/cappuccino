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
        lastPart = aKeyPath.substring(dotIndex+1);

    return [[self valueForKeyPath:firstPart] valueForKeyPath:lastPart];
}

@end

@implementation _CPKVCArray : CPArray
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
    
    SEL         _countSEL;
    Function    _count;
    
    SEL         _accessSEL;
    Function    _access;
    
    SEL         _setSEL;
    Function    _set;
}

+ (id)alloc
{
    var a = [];
    a.isa = self;
    
    var ivars = class_copyIvarList(self),
        count = ivars.length;

    while (count--)
        a[ivar_getName(ivars[count])] = nil;

    return a;
}

-(id)initWithKey:(id)aKey forProxyObject:(id)anObject
{
    self = [super init];

    _key = aKey;
    _proxyObject = anObject;
    
    var capitalizedKey = _key.charAt(0).toUpperCase() + _key.substring(1);
    
    _insertSEL = sel_getName(@"insertObject:in"+capitalizedKey+"AtIndex:");
    if ([_proxyObject respondsToSelector:_insertSEL])
        _insert = [_proxyObject methodForSelector:_insertSEL];

    _removeSEL = sel_getName(@"removeObjectFrom"+capitalizedKey+"AtIndex:");
    if ([_proxyObject respondsToSelector:_removeSEL])
        _remove = [_proxyObject methodForSelector:_removeSEL];
        
    _replaceSEL = sel_getName(@"replaceObjectFrom"+capitalizedKey+"AtIndex:withObject:");
    if ([_proxyObject respondsToSelector:_replaceSEL])
        _replace = [_proxyObject methodForSelector:_replaceSEL];

    _insertManySEL = sel_getName(@"insertObjects:in"+capitalizedKey+"AtIndexes:");
    if ([_proxyObject respondsToSelector:_insertManySEL])
        _insert = [_proxyObject methodForSelector:_insertManySEL];

    _removeManySEL = sel_getName(@"removeObjectsFrom"+capitalizedKey+"AtIndexes:");
    if ([_proxyObject respondsToSelector:_removeManySEL])
        _remove = [_proxyObject methodForSelector:_removeManySEL];
        
    _replaceManySEL = sel_getName(@"replaceObjectsFrom"+capitalizedKey+"AtIndexes:withObjects:");
    if ([_proxyObject respondsToSelector:_replaceManySEL])
        _replace = [_proxyObject methodForSelector:_replaceManySEL];
        
    _objectAtIndexSEL = sel_getName(@"objectIn"+capitalizedKey+"AtIndex:");
    if ([_proxyObject respondsToSelector:_objectAtIndexSEL])
        _objectAtIndex = [_proxyObject methodForSelector:_objectAtIndexSEL];

    _countSEL = sel_getName(@"countOf"+capitalizedKey);
    if ([_proxyObject respondsToSelector:_countSEL])
        _count = [_proxyObject methodForSelector:_countSEL];

    _accessSEL = sel_getName(_key);
    if ([_proxyObject respondsToSelector:_accessSEL])
        _access = [_proxyObject methodForSelector:_accessSEL];

    _setSEL = sel_getName(@"set"+capitalizedKey+":");
    if ([_proxyObject respondsToSelector:_setSEL])
        _set = [_proxyObject methodForSelector:_setSEL];

    return self;
}

- (id)copy
{
    var theCopy = [],
        count = [self count];

    for (var i=0; i<count; i++)
        [theCopy addObject:[self objectAtIndex:i]];

    return theCopy;
}

-(id)_representedObject
{
    if (_access)
        return _access(_proxyObject, _accessSEL);

    return [_proxyObject valueForKey:_key];
}

-(void)_setRepresentedObject:(id)anObject
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

- (id)objectAtIndex:(unsigned)anIndex
{
    if(_objectAtIndex)
        return _objectAtIndex(_proxyObject, _objectAtIndexSEL, anIndex);

    return [[self _representedObject] objectAtIndex:anIndex];
}

- (void)addObject:(id)anObject
{
    if (_insert)
        return _insert(_proxyObject, _insertSEL, anObject, [self count]);

    var target = [[self _representedObject] copy];
    
    [target addObject:anObject];
    [self _setRepresentedObject:target];
}

- (void)insertObject:(id)anObject atIndex:(unsigned)anIndex
{
    if (_insert)
        return _insert(_proxyObject, _insertSEL, anObject, anIndex);

    var target = [[self _representedObject] copy];
    
    [target insertObject:anObject atIndex:anIndex];
    [self _setRepresentedObject:target];
}

- (void)removeLastObject
{
    if(_remove)
        return _remove(_proxyObject, _removeSEL, [self count]-1); 

    var target = [[self _representedObject] copy];
    
    [target removeLastObject];
    [self _setRepresentedObject:target];
}

- (void)removeObjectAtIndex:(unsigned)anIndex
{
    if(_remove)
        return _remove(_proxyObject, _removeSEL, anIndex); 

    var target = [[self _representedObject] copy];
    
    [target removeObjectAtIndex:anIndex];
    [self _setRepresentedObject:target];
}

- (void)replaceObjectAtIndex:(unsigned)anIndex withObject:(id)anObject
{
    if(_replace)
        return _replace(_proxyObject, _replaceSEL, anIndex, anObject);

    var target = [[self _representedObject] copy];
    
    [target replaceObjectAtIndex:anIndex withObject:anObject];
    [self _setRepresentedObject:target];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    var index = [indexes firstIndex],
        objects = [];

    while(index != CPNotFound)
    { 
        [objects addObject:[self objectAtIndex:index]];
        index = [indexes indexGreaterThanIndex:index];
    }
    
    return objects;
}

@end


//KVC on CPArray objects act on each item of the array, rather than on the array itself

@implementation CPArray (KeyValueCoding)

- (id)valueForKey:(CPString)aKey
{

    if (aKey.indexOf("@") === 0)
    {
        if (aKey.indexOf(".") !== -1)
            [CPException raise:CPInvalidArgumentException reason:"called valueForKey: on an array with a complex key ("+aKey+"). use valueForKeyPath:"];

        if (aKey == "@count")
            return length;
            
        return nil;
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
    if (aKeyPath.indexOf("@") === 0)
    {            
        var dotIndex = aKeyPath.indexOf("."),
            operator = aKeyPath.substring(1, dotIndex),
            parameter = aKeyPath.substring(dotIndex+1);
        
        if (kvoOperators[operator])
            return kvoOperators[operator](self, _cmd, parameter);
            
        return nil;
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
    
    while (object = [enumerator nextObject])
        [object setValue:aValue forKey:aKey];
}

- (void)setValue:(id)aValue forKeyPath:(CPString)aKeyPath
{
    var enumerator = [self objectEnumerator],
        object;
    
    while (object = [enumerator nextObject])
        [object setValue:aValue forKeyPath:aKeyPath];
}


@end

var kvoOperators = [];

kvoOperators["avg"] = function avgOperator(self, _cmd, param)
{
    var objects = [self valueForKeyPath:param],
        length = [objects count],
        index = length;
        average = 0.0;

    if (!length)
        return 0;
        
    while(index--)
        average += [objects[index] doubleValue];

    return average / length;
}

kvoOperators["max"] = function maxOperator(self, _cmd, param)
{
    var objects = [self valueForKeyPath:param],
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
    var objects = [self valueForKeyPath:param],
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
    var objects = [self valueForKeyPath:param],
        index = [objects count],
        sum = 0.0;

    while(index--)
        sum += [objects[index] doubleValue];

    return sum;
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
    if ([isa instanceMethodForSelector:_cmd]==[NSArray instanceMethodForSelector:_cmd])
        [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPArray"];
    else
        [super addObserver:observer forKeyPath:aKeyPath options:options context:context];
}

-(void)removeObserver:(id)observer forKeyPath:(CPString)aKeyPath
{
    if ([isa instanceMethodForSelector:_cmd]==[NSArray instanceMethodForSelector:_cmd])
        [CPException raise:CPInvalidArgumentException reason:"Unsupported method on CPArray"];
    else
        [super removeObserver:observer forKeyPath:aKeyPath];
}

@end
