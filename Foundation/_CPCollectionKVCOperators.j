/*
 * _CPCollectionKVCOperators.j
 * Foundation
 *
 * Created by Aparajita Fishman.
 * Copyright 2012 Cappuccino Foundation.
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

@import "CPObject.j"

var _CPCollectionKVCOperatorSimpleRE = new RegExp("^@(avg|count|m(ax|in)|sum|unionOfObjects|distinctUnionOfObjects|unionOfArrays|distinctUnionOfArrays|distinctUnionOfSets)(\\.|$)");


@implementation _CPCollectionKVCOperator : CPObject

+ (BOOL)isSimpleCollectionOperator:(CPString)operator
{
    return _CPCollectionKVCOperatorSimpleRE.test(operator);
}

+ (id)performOperation:(CPString)operator withCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    var selector = CPSelectorFromString(operator + @"ForCollection:propertyPath:");

    if (![self respondsToSelector:selector])
        return [aCollection valueForUndefinedKey:@"@" + operator];

    return [self performSelector:selector withObject:aCollection withObject:propertyPath];
}

+ (double)avgForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@avg"];

    var objects = [aCollection valueForKeyPath:propertyPath],
        average = 0.0,
        enumerator = [objects objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) != nil)
        average += [object doubleValue];

    return average / [objects count];
}

+ (double)minForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@min"];

    var objects = [aCollection valueForKeyPath:propertyPath];

    if ([objects count] === 0)
        return nil;

    var enumerator = [objects objectEnumerator],
        min = [enumerator nextObject],
        object;

    while ((object = [enumerator nextObject]) != nil)
    {
        if ([min compare:object] > 0)
            min = object;
    }

    return min;
}

+ (double)maxForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@max"];

    var objects = [aCollection valueForKeyPath:propertyPath];

    if ([objects count] === 0)
        return nil;

    var enumerator = [objects objectEnumerator],
        max = [enumerator nextObject],
        object;

    while ((object = [enumerator nextObject]) != nil)
    {
        if ([max compare:object] < 0)
            max = object;
    }

    return max;
}

+ (double)sumForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@sum"];

    var objects = [aCollection valueForKeyPath:propertyPath],
        sum = 0.0,
        enumerator = [objects objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) != nil)
        sum += [object doubleValue];

    return sum;
}

+ (int)countForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    return [aCollection count];
}

+ (CPArray)unionOfObjectsForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@unionOfObjects"];

    var objects = [aCollection valueForKeyPath:propertyPath];

    if ([objects isKindOfClass:[CPSet class]])
        return [objects allObjects];

    return objects;
}

+ (CPArray)distinctUnionOfObjectsForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@distinctUnionOfObjects"];

    var objects = [aCollection valueForKeyPath:propertyPath],
        distinctObjects = [CPMutableArray new],
        enumerator = [objects objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) != nil)
    {
        if ([distinctObjects indexOfObject:object] == CPNotFound)
            [distinctObjects addObject:object];
    }

    return distinctObjects;
}

+ (CPArray)unionOfArraysForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@unionOfArrays"];

    var objects = [],
        number = [aCollection count];

    for (var i = 0; i < number; i++)
        [objects addObjectsFromArray:[aCollection[i] valueForKeyPath:propertyPath]];

    return objects;
}

+ (CPArray)distinctUnionOfArraysForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@distinctUnionOfArrays"];

    var objects = [],
        number = [aCollection count];

    for (var i = 0; i < number; i++)
        [objects addObjectsFromArray:[aCollection[i] valueForKeyPath:propertyPath]];

    var distinctObjects = [CPMutableArray new],
        enumerator = [objects objectEnumerator],
        object;

    while ((object = [enumerator nextObject]) != nil)
    {
        if ([distinctObjects indexOfObject:object] == CPNotFound)
            [distinctObjects addObject:object];
    }

    return distinctObjects;
}

+ (CPArray)distinctUnionOfSetsForCollection:(id)aCollection propertyPath:(CPString)propertyPath
{
    if (!propertyPath)
        return [aCollection valueForUndefinedKey:@"@distinctUnionOfSets"];

    var objects = [CPMutableSet new],
        number = [aCollection count],
        sets = [aCollection allObjects];

    for (var i = 0; i < number; i++)
        [objects addObjectsFromArray:[[sets[i] valueForKeyPath:propertyPath] allObjects]];

    return objects;
}

@end
