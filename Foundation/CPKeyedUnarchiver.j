/*
 * CPKeyedUnarchiver.j
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

import "CPNull.j"
import "CPCoder.j"


var _CPKeyedUnarchiverCannotDecodeObjectOfClassNameOriginalClassSelector    = 1,
    _CPKeyedUnarchiverDidDecodeObjectSelector                               = 1 << 1,
    _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector                   = 1 << 2,
    _CPKeyedUnarchiverWillFinishSelector                                    = 1 << 3,
    _CPKeyedUnarchiverDidFinishSelector                                     = 1 << 4;

var _CPKeyedArchiverNullString                                              = "$null"
    
    _CPKeyedArchiverUIDKey                                                  = "CP$UID",
    
    _CPKeyedArchiverTopKey                                                  = "$top",
    _CPKeyedArchiverObjectsKey                                              = "$objects",
    _CPKeyedArchiverArchiverKey                                             = "$archiver",
    _CPKeyedArchiverVersionKey                                              = "$version",
    
    _CPKeyedArchiverClassNameKey                                            = "$classname",
    _CPKeyedArchiverClassesKey                                              = "$classes",
    _CPKeyedArchiverClassKey                                                = "$class";
    
var _CPKeyedUnarchiverArrayClass                                            = Nil,
    _CPKeyedUnarchiverStringClass                                           = Nil,
    _CPKeyedUnarchiverDictionaryClass                                       = Nil,
    _CPKeyedUnarchiverArchiverValueClass                                    = Nil;

@implementation CPKeyedUnarchiver : CPCoder
{
    id              _delegate;
    unsigned        _delegateSelectors;
    
    CPData          _data;

    // FIXME: We need to support this!
    CPDictionary    _replacementClassNames;
    
    CPDictionary    _objects;
    CPDictionary    _archive;
    
    CPDictionary    _plistObject;
    CPArray         _plistObjects;
}

+ (void)initialize
{
    if (self != [CPKeyedUnarchiver class])
        return;
    
    _CPKeyedUnarchiverArrayClass = [CPArray class];
    _CPKeyedUnarchiverStringClass = [CPString class];
    _CPKeyedUnarchiverDictionaryClass = [CPDictionary class];
    _CPKeyedUnarchiverArchiverValueClass = [_CPKeyedArchiverValue class];
}

- (id)initForReadingWithData:(CPData)data
{
    self = [super init];

    if (self)
    {
        _archive = [data plistObject];
        _objects = [CPArray arrayWithObject:[CPNull null]];
        
        _plistObject = [_archive objectForKey:_CPKeyedArchiverTopKey];
        _plistObjects = [_archive objectForKey:_CPKeyedArchiverObjectsKey];
    }
    
    return self;
}

+ (id)unarchiveObjectWithData:(CPData)data
{
    var unarchiver = [[self alloc] initForReadingWithData:data],
        object = [unarchiver decodeObjectForKey:@"root"];
         
    [unarchiver finishDecoding];
    
    return object;
}

+ (id)unarchiveObjectWithFile:(CPString)aFilePath
{
}

+ (id)unarchiveObjectWithFile:(CPString)aFilePath asynchronously:(BOOL)aFlag
{
}

- (BOOL)containsValueForKey:(CPString)aKey
{
    return [_plistObject objectForKey:aKey] != nil;
}

- (id)_decodeArrayOfObjectsForKey:(CPString)aKey
{
    var object = [_plistObject objectForKey:aKey];
    
    if ([object isKindOfClass:_CPKeyedUnarchiverArrayClass])
    {
        var index = 0,
            count = object.length,
            array = [];

        for (; index < count; ++index)
            array[index] = _CPKeyedUnarchiverDecodeObjectAtIndex(self, [object[index] objectForKey:_CPKeyedArchiverUIDKey]);
            
        return array;
    }
    
    return nil;
}

- (void)_decodeDictionaryOfObjectsForKey:(CPString)aKey
{
    var object = [_plistObject objectForKey:aKey];
    
    if ([object isKindOfClass:_CPKeyedUnarchiverDictionaryClass])
    {
        var key,
            keys = [object keyEnumerator],
            dictionary = [CPDictionary dictionary];
        
        while (key = [keys nextObject])
            [dictionary setObject:_CPKeyedUnarchiverDecodeObjectAtIndex(self, [[object objectForKey:key] objectForKey:_CPKeyedArchiverUIDKey]) forKey:key];

        return dictionary;
    }
    
    return nil;
}

- (BOOL)decodeBoolForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

- (float)decodeFloatForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

- (double)decodeDoubleForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

- (int)decodeIntForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

- (CPPoint)decodePointForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPPointFromString(object);
    else
        return CPPointMake(0.0, 0.0);
}

- (CPRect)decodeRectForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPRectFromString(object);
    else
        return CPRectMakeZero();
}

- (CPSize)decodeSizeForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPSizeFromString(object);
    else
        return CPSizeMake(0.0, 0.0);
}

- (id)decodeObjectForKey:(CPString)aKey
{
    var object = [_plistObject objectForKey:aKey];

    if ([object isKindOfClass:_CPKeyedUnarchiverDictionaryClass])
        return _CPKeyedUnarchiverDecodeObjectAtIndex(self, [object objectForKey:_CPKeyedArchiverUIDKey]);
    else if ([object isKindOfClass:[CPNumber class]])
        return object;
/*    else
        alert([object className] + " " + object + " " + aKey + " " + [_plistObject description]);*/

    return nil;
}

- (void)finishDecoding
{
    if (_delegateSelectors & _CPKeyedUnarchiverWillFinishSelector)
        [_delegate unarchiverWillFinish:self];

    if (_delegateSelectors & _CPKeyedUnarchiverDidFinishSelector)
        [_delegate unarchiverDidFinish:self];
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(unarchiver:CannotDecodeObjectOfClassName:originalClass:)])
        _delegateSelectors |= _CPKeyedUnarchiverCannotDecodeObjectOfClassNameOriginalClassSelector;
        
    if ([_delegate respondsToSelector:@selector(unarchiver:didDecodeObject:)])
        _delegateSelectors |= _CPKeyedUnarchiverDidDecodeObjectSelector;
    
    if ([_delegate respondsToSelector:@selector(unarchiver:willReplaceObject:withObject:)])
        _delegateSelectors |= _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector;

    if ([_delegate respondsToSelector:@selector(unarchiverWillFinish:)])
        _delegateSelectors |= _CPKeyedUnarchiverWilFinishSelector;
        
    if ([_delegate respondsToSelector:@selector(unarchiverDidFinish:)])
        _delegateSelectors |= _CPKeyedUnarchiverDidFinishSelector;
}

- (BOOL)allowsKeyedCoding
{
    return YES;
}

@end

var _CPKeyedUnarchiverDecodeObjectAtIndex = function(self, anIndex)
{
    var object = self._objects[anIndex];

    if (object)
        if (object == self._objects[0])
            return nil;
        else
            return object;
            
    var object,
        plistObject = self._plistObjects[anIndex];

    if ([plistObject isKindOfClass:_CPKeyedUnarchiverDictionaryClass])
    {
        var plistClass = self._plistObjects[[[plistObject objectForKey:_CPKeyedArchiverClassKey] objectForKey:_CPKeyedArchiverUIDKey]],
            className = [plistClass objectForKey:_CPKeyedArchiverClassNameKey],
            classes = [plistClass objectForKey:_CPKeyedArchiverClassesKey],
            theClass = CPClassFromString(className);

        object = [theClass alloc];

        // It is important to do this before calling initWithCoder so that decoding can be self referential (something = self).    
        self._objects[anIndex] = object;
        
        var savedPlistObject = self._plistObject;
        
        self._plistObject = plistObject;
        
        var processedObject = [object initWithCoder:self];

        self._plistObject = savedPlistObject;
        
        if (processedObject != object)
        {
            if (self._delegateSelectors & _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector)
                [self._delegate unarchiver:self willReplaceObject:object withObject:processedObject];
    
            object = processedObject;
            self._objects[anIndex] = processedObject;
        }
        
        processedObject = [object awakeAfterUsingCoder:self]; 
        
        if (processedObject == object)
        {
            if (self._delegateSelectors & _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector)
                [self._delegate unarchiver:self willReplaceObject:object withObject:processedObject];
            
            object = processedObject;
            self._objects[anIndex] = processedObject;
        }
        
        if (self._delegate)
        {
            if (self._delegateSelectors & _CPKeyedUnarchiverDidDecodeObjectSelector)
                processedObject = [self._delegate unarchiver:self didDecodeObject:object];
            
            if (processedObject != object)
            {
                if (self._delegateSelectors & _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector)
                    [self._delegate unarchiver:self willReplaceObject:object withObject:processedObject];
    
                object = processedObject;
                self._objects[anIndex] = processedObject;
            }
        }
    }
    else
    {
        self._objects[anIndex] = object = plistObject;

        if ([object class] == _CPKeyedUnarchiverStringClass)
        {
            if (object == _CPKeyedArchiverNullString)
            {
                self._objects[anIndex] = self._objects[0];
            
                return nil;
            }
            else
                self._objects[anIndex] = object = plistObject;
        }
    }
    
    // If this object is a member of _CPKeyedArchiverValue, then we know 
    // that it is a wrapper for a primitive JavaScript object.
    if ([object isMemberOfClass:_CPKeyedUnarchiverArchiverValueClass])
        object = [object JSObject];
    
    return object;
}

