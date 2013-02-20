/*
 * CPDictionaryController.j
 * AppKit
 *
 * Adapted from Cocotron, by Johannes Fortmann
 *
 * Created by Blair Duncan
 * Copyright 2013, SGL Studio, BBDO Toronto All rights reserved.
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

@import "CPArrayController.j"

@implementation CPDictionaryController : CPArrayController
{
    CPDictionary    _contentDictionary;

    CPArray         _includedKeys @accessors(property=includedKeys);
    CPArray         _excludedKeys @accessors(property=excludedKeys);

    CPString        _initialKey @accessors(property=initialKey);
    id              _initialValue @accessors(property=initialValue);
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _initialKey = @"key";
        _initialValue = @"value";
    }

    return self;
}

- (id)newObject
{
    var keys = [_contentDictionary allKeys],
        newKey = _initialKey,
        count = 0;

    if ([keys containsObject:newKey])
        while ([keys containsObject:newKey])
            newKey = [CPString stringWithFormat:@"%@%i", _initialKey, ++count];

    return [self _newObjectWithKey:newKey value:_initialValue];
}

- (id)_newObjectWithKey:(CPString)aKey value:(id)aValue
{
    var aNewObject = [_CPDictionaryControllerKeyValuePair new];

    aNewObject._dictionary = _contentDictionary;
    aNewObject._controller = self;
    aNewObject._key = aKey;

    if (aValue !== nil)
        [aNewObject setValue:aValue];

    return aNewObject;
}

- (CPDictionary)contentDictionary
{
    return _contentDictionary;
}

- (void)setContentDictionary:(CPDictionary)aDictionary
{
    if (aDictionary == _contentDictionary)
        return;

    if ([aDictionary isKindOfClass:[CPDictionary class]])
        _contentDictionary = aDictionary;
    else
        _contentDictionary = nil;

    var array = [CPArray array],
        allKeys = [_contentDictionary allKeys];

    [allKeys addObjectsFromArray:_includedKeys];

    var iter = [[CPSet setWithArray:allKeys] objectEnumerator],
        obj;

    while ((obj = [iter nextObject]) !== nil)
        if (![_excludedKeys containsObject:obj])
            [array addObject:[self _newObjectWithKey:obj value:nil]];

    [super setContent:array];
}


@end


var CPIncludedKeys  = @"CPIncludedKeys",
    CPExcludedKeys  = @"CPExcludedKeys";

@implementation CPDictionaryController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _includedKeys = [aCoder decodeObjectForKey:CPIncludedKeys];
        _excludedKeys = [aCoder decodeObjectForKey:CPExcludedKeys];
        _initialKey = @"key";
        _initialValue = @"value";
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_includedKeys forKey:CPIncludedKeys];
    [aCoder encodeObject:_excludedKeys forKey:CPExcludedKeys];
}

@end




@implementation _CPDictionaryControllerKeyValuePair : CPObject
{
    CPString                _key @accessors(property=key);
    CPDictionary            _dictionary @accessors(property=dictionary);
    CPDictionaryController  _controller @accessors(property=controller);
}

- (id)value
{
   return [_dictionary objectForKey:_key];
}

- (void)setValue:(id)aValue
{
   [_dictionary setObject:aValue forKey:_key];
}

- (BOOL)isExplicitlyIncluded
{
    return [[_controller _includedKeys] containsObject:_key];
}


@end
