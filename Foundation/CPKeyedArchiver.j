/*
 * CPKeyedArchiver.j
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

import "CPData.j"
import "CPCoder.j"
import "CPArray.j"
import "CPString.j"
import "CPNumber.j"
import "CPDictionary.j"
import "CPValue.j"

var CPArchiverReplacementClassNames                     = nil;

var _CPKeyedArchiverDidEncodeObjectSelector             = 1,
    _CPKeyedArchiverWillEncodeObjectSelector            = 2,
    _CPKeyedArchiverWillReplaceObjectWithObjectSelector = 4,
    _CPKeyedArchiverDidFinishSelector                   = 8,
    _CPKeyedArchiverWillFinishSelector                  = 16;
    
var _CPKeyedArchiverNullString                          = "$null",
    _CPKeyedArchiverNullReference                       = nil,
    
    _CPKeyedArchiverUIDKey                              = "CP$UID",
    
    _CPKeyedArchiverTopKey                              = "$top",
    _CPKeyedArchiverObjectsKey                          = "$objects",
    _CPKeyedArchiverArchiverKey                         = "$archiver",
    _CPKeyedArchiverVersionKey                          = "$version",
    
    _CPKeyedArchiverClassNameKey                        = "$classname",
    _CPKeyedArchiverClassesKey                          = "$classes",
    _CPKeyedArchiverClassKey                            = "$class";                     

var _CPKeyedArchiverStringClass                         = Nil,
    _CPKeyedArchiverNumberClass                         = Nil;

@implementation _CPKeyedArchiverValue : CPValue
{
}
@end

@implementation CPKeyedArchiver : CPCoder
{
    id                      _delegate;
    unsigned                _delegateSelectors;
    
    CPData                  _data;
    
    CPArray                 _objects;

    CPDictionary            _UIDs;
    CPDictionary            _conditionalUIDs;
    
    CPDictionary            _replacementObjects;
    CPDictionary            _replacementClassNames;
    
    id                      _plistObject;
    CPMutableArray          _plistObjects;
    
    CPPropertyListFormat    _outputFormat;
    
}

+ (void)initialize
{
    if (self != [CPKeyedArchiver class])
        return;
    
    _CPKeyedArchiverStringClass = [CPString class];
    _CPKeyedArchiverNumberClass = [CPNumber class];
    
    _CPKeyedArchiverNullReference = [CPDictionary dictionaryWithObject:0 forKey:_CPKeyedArchiverUIDKey];
}

+ (BOOL)allowsKeyedCoding
{
    return YES;
}

+ (CPData)archivedDataWithRootObject:(id)anObject
{
    var data = [CPData dataWithPlistObject:nil],
        archiver = [[self alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:anObject forKey:@"root"];
    [archiver finishEncoding];

    return data;
}

// Initializing an NSKeyedArchiver object

- (id)initForWritingWithMutableData:(CPMutableData)data
{
    self = [super init];
    
    if (self)
    {
        _data = data;
        
        _objects = [];
        
        _UIDs = [CPDictionary dictionary];
        _conditionalUIDs = [CPDictionary dictionary];
        
        _replacementObjects = [CPDictionary dictionary];
        
        _data = data;
        
        _plistObject = [CPDictionary dictionary];
        _plistObjects = [CPArray arrayWithObject:_CPKeyedArchiverNullString];
    }
    
    return self;
}

// Archiving Data
- (void)finishEncoding
{
    if (_delegate && _delegateSelectors & _CPKeyedArchiverWillFinishSelector)
        [_delegate archiverWillFinish:self];
    
    var i = 0,
        topObject = _plistObject,
        classes = [];
    
    for (; i < _objects.length; ++i)
    {
        var object = _objects[i],
            theClass = [object classForKeyedArchiver];
        
        // Do whatever with the class, yo.
        // We call willEncodeObject previously.
        
        _plistObject = _plistObjects[[_UIDs objectForKey:[object hash]]];
        [object encodeWithCoder:self];        
        
        if (_delegate && _delegateSelectors & _CPKeyedArchiverDidEncodeObjectSelector)
            [_delegate archiver:self didEncodeObject:object];
    }
    
    _plistObject = [CPDictionary dictionary];
    
    [_plistObject setObject:topObject forKey:_CPKeyedArchiverTopKey];
    [_plistObject setObject:_plistObjects forKey:_CPKeyedArchiverObjectsKey];
    [_plistObject setObject:[self className] forKey:_CPKeyedArchiverArchiverKey];
    [_plistObject setObject:@"100000" forKey:_CPKeyedArchiverVersionKey];
    
    [_data setPlistObject:_plistObject];

    if (_delegate && _delegateSelectors & _CPKeyedArchiverDidFinishSelector)
        [_delegate archiverDidFinish:self];
}

- (void)outputFormat
{
    return _outputFormat;
}

- (void)setOutputFormat:(CPPropertyListFormat)aPropertyListFormat
{
    _outputFormat = aPropertyListFormat;
}

- (void)encodeBool:(BOOL)aBOOL forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, aBOOL, NO) forKey:aKey];
}

- (void)encodeDouble:(double)aDouble forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, aDouble, NO) forKey:aKey];
}

- (void)encodeFloat:(float)aFloat forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, aFloat, NO) forKey:aKey];
}

- (void)encodeInt:(float)anInt forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, anInt, NO) forKey:aKey];
}

// Managing Delegates

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(archiver:didEncodeObject:)])
        _delegateSelectors |= _CPKeyedArchiverDidEncodeObjectSelector;
        
    if ([_delegate respondsToSelector:@selector(archiver:willEncodeObject:)])
        _delegateSelectors |= _CPKeyedArchiverWillEncodeObjectSelector;
    
    if ([_delegate respondsToSelector:@selector(archiver:willReplaceObject:withObject:)])
        _delegateSelectors |= _CPKeyedArchiverWillReplaceObjectWithObjectSelector;

    if ([_delegate respondsToSelector:@selector(archiver:didFinishEncoding:)])
        _delegateSelectors |= _CPKeyedArchiverDidFinishEncodingSelector;
        
    if ([_delegate respondsToSelector:@selector(archiver:willFinishEncoding:)])
        _delegateSelectors |= _CPKeyedArchiverWillFinishEncodingSelector;
    
}

- (id)delegate
{
    return _delegate;
}

- (void)encodePoint:(CPPoint)aPoint forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, CPStringFromPoint(aPoint), NO) forKey:aKey];
}

- (void)encodeRect:(CPRect)aRect forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, CPStringFromRect(aRect), NO) forKey:aKey];
}

- (void)encodeSize:(CPSize)aSize forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, CPStringFromSize(aSize), NO) forKey:aKey];
}

- (void)encodeConditionalObject:(id)anObject forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, anObject, YES) forKey:aKey];
}

- (void)encodeNumber:(CPNumber)aNumber forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, aNuumber, NO) forKey:aKey];
}

- (void)encodeObject:(id)anObject forKey:(CPString)aKey
{
    [_plistObject setObject:_CPKeyedArchiverEncodeObject(self, anObject, NO) forKey:aKey]; 
}

- (void)_encodeArrayOfObjects:(CPArray)objects forKey:(CPString)aKey
{
    var i = 0,
        count = objects.length,
        references = [CPArray arrayWithCapacity:count];
        
    for (; i < count; ++i)
        [references addObject:_CPKeyedArchiverEncodeObject(self, objects[i], NO)];
        
    [_plistObject setObject:references forKey:aKey];
}

- (void)_encodeDictionaryOfObjects:(CPDictionary)aDictionary forKey:(CPString)aKey
{
    var key,
        keys = [aDictionary keyEnumerator],
        references = [CPDictionary dictionary];
    
    while (key = [keys nextObject])
        [references setObject:_CPKeyedArchiverEncodeObject(self, [aDictionary objectForKey:key], NO) forKey:key];
    
    [_plistObject setObject:references forKey:aKey];
}

// Managing classes and class names

+ (void)setClassName:(CPString)aClassName forClass:(Class)aClass
{
    if (!CPArchiverReplacementClassNames)
        CPArchiverReplacementClassNames = [CPDictionary dictionary];
    
    [CPArchiverReplacementClassNames setObject:aClassName forKey:CPStringFromClass(aClass)];
}

+ (CPString)classNameForClass:(Class)aClass
{
    if (!CPArchiverReplacementClassNames)
        return aClass.name;

    var className = [CPArchiverReplacementClassNames objectForKey:CPStringFromClass(aClassName)];
    
    return className ? className : aClass.name;
}

- (void)setClassName:(CPString)aClassName forClass:(Class)aClass
{
    if (!_replacementClassNames)
        _replacementClassNames = [CPDictionary dictionary];
    
    [_replacementClassNames setObject:aClassName forKey:CPStringFromClass(aClass)];
}

- (CPString)classNameForClass:(Class)aClass
{
    if (!_replacementClassNames)
        return aClass.name;

    var className = [_replacementClassNames objectForKey:CPStringFromClass(aClassName)];
    
    return className ? className : aClass.name;
}

@end

var _CPKeyedArchiverEncodeObject = function(self, anObject, isConditional)
{
    // We wrap primitive JavaScript objects in a unique subclass of CPValue.
    // This way, when we unarchive, we know to unwrap it, since 
    // _CPKeyedArchiverValue should not be used anywhere else.
    if (anObject != nil && !anObject.isa)
        anObject = [_CPKeyedArchiverValue valueWithJSObject:anObject];
    
    // Get the proper replacement object
    var hash = [anObject hash],
        object = [self._replacementObjects objectForKey:hash];

    // If a replacement object doesn't exist, then actually ask for one.
    // Explicitly compare to nil because object could be === 0.
    if (object == nil)
    {
        object = [anObject replacementObjectForKeyedArchiver:self];
        
        // Notify our delegate of this replacement.
        if (self._delegate)
        {
            if (object != anObject && self._delegateSelectors & _CPKeyedArchiverWillReplaceObjectWithObjectSelector)
                [self._delegate archiver:self willReplaceObject:anObject withObject:object];
            
            if (self._delegateSelectors & _CPKeyedArchiverWillEncodeObjectSelector)
            {
                anObject = [self._delegate archiver:self willEncodeObject:object];
                
                if (anObject != object && self._delegateSelectors & _CPKeyedArchiverWillReplaceObjectWithObjectSelector)
                    [self._delegate archiver:self willReplaceObject:object withObject:anObject];
                    
                object = anObject;
            }
        }
        
        [self._replacementObjects setObject:object forKey:hash];
    }
    
    // If we still don't have an object by this point, then return a 
    // reference to the null object.
    // Explicitly compare to nil because object could be === 0.
    if (object == nil)
        return _CPKeyedArchiverNullReference;
    
    // If not, then grab the object's UID
    var UID = [self._UIDs objectForKey:hash = [object hash]];
    
    // If this object doesn't have a unique index in the object table yet, 
    // then it also hasn't been properly encoded.  We explicitly compare 
    // index to nil since it could be 0, which would also evaluate to false.
    if (UID == nil)
    {
        // If it is being conditionally encoded, then 
        if (isConditional)
        {
            // If we haven't already noted this conditional object...
            if ((UID = [self._conditionalUIDs objectForKey:hash]) == nil)
            {
                // Use the null object as a placeholder.
                [self._conditionalUIDs setObject:UID = [self._plistObjects count] forKey:hash];
                [self._plistObjects addObject:_CPKeyedArchiverNullString];
            }
        }
        else
        {
            var theClass = [anObject classForKeyedArchiver],
                plistObject = nil,
                shouldEncodeObject = NO;
            
            if (theClass == _CPKeyedArchiverStringClass || theClass == _CPKeyedArchiverNumberClass)// || theClass == _CPKeyedArchiverBooleanClass)
                plistObject = object;
            else
            {
                shouldEncodeObject = YES;
                plistObject = [CPDictionary dictionary];
            }
            
            // If this object was previously encoded conditionally...
            if ((UID = [self._conditionalUIDs objectForKey:hash]) == nil)
            {
                [self._UIDs setObject:UID = [self._plistObjects count] forKey:hash];
                [self._plistObjects addObject:plistObject];
                
                // Only encode the object if it is not the same as the plist object.
                if (shouldEncodeObject)
                {
                    [self._objects addObject:object];
                    
                    var className = [self classNameForClass:theClass];
        
                    if (!className)
                        className = [[self class] classNameForClass:theClass];
                    
                    if (!className)
                        className = theClass.name;
                    else
                        theClass = window[className];

                    var classUID = [self._UIDs objectForKey:className];
                    
                    if (!classUID)
                    {
                        var plistClass = [CPDictionary dictionary],
                            hierarchy = [];
                        
                        [plistClass setObject:className forKey:_CPKeyedArchiverClassNameKey];
                        
                        do
                        {
                            [hierarchy addObject:CPStringFromClass(theClass)];
                        } while (theClass = [theClass superclass]);
                        
                        [plistClass setObject:hierarchy forKey:_CPKeyedArchiverClassesKey];
                        
                        classUID = [self._plistObjects count];
                        [self._plistObjects addObject:plistClass];
                        [self._UIDs setObject:classUID forKey:className];
                    }

                    [plistObject setObject:[CPDictionary dictionaryWithObject:classUID forKey:_CPKeyedArchiverUIDKey] forKey:_CPKeyedArchiverClassKey];
                }
            }
            else
            {
                [self._UIDs setObject:object forKey:UID];
                [self._plistObjects replaceObjectAtIndex:UID withObject:plistObject];
            }
        }
    }

    return [CPDictionary dictionaryWithObject:UID forKey:_CPKeyedArchiverUIDKey];
}
