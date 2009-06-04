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

@import "CPNull.j"
@import "CPCoder.j"


var _CPKeyedUnarchiverCannotDecodeObjectOfClassNameOriginalClassesSelector  = 1,
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
    _CPKeyedUnarchiverNumberClass                                           = Nil,
    _CPKeyedUnarchiverDataClass                                             = Nil,
    _CPKeyedUnarchiverArchiverValueClass                                    = Nil;

/*!
    @class CPKeyedUnarchiver
    @ingroup foundation
    @brief Unarchives objects created using CPKeyedArchiver.

    CPKeyedUnarchiver is used for creating objects out of
    coded files or CPData objects that were created by
    CPKeyedArchiver. More specifically, this class unarchives
    objects from a data stream or file and brings them back into
    memory for programmatic usage.

    @delegate  -(Class)unarchiver:(CPKeyedUnarchiver)unarchiver
                    cannotDecodeObjectOfClassName:(CPString)name
                    originalClasses:(CPArray)classNames;
    Called when the specified class is not available during decoding.
    The delegate may load the class, or return a substitute class
    to use instead.
    @param unarchiver the unarchiver performing the decode
    @param name the name of the class that can't be found
    @param an array of class names describing the encoded object's
    class hierarchy. The first index is the encoded class name, and
    each superclass is after that.
    @return the Class to use instead or <code>nil</code>
    to abort the unarchiving operation

    @delegate -(id)unarchiver:(CPKeyedUnarchiver)unarchiver didDecodeObject:(id)object;
    Called when the unarchiver decodes an object.
    @param unarchiver the unarchiver doing the decoding
    @param object the decoded objec
    @return a substitute to use for the decoded object. This can be the same object argument provide,
    another object or <code>nil</code>.

    @delegate -(void)unarchiver:(CPKeyedUnarchiver)unarchiver willReplaceObject:(id)object withObject:(id)newObject;
    Called when a decoded object has been substituted with another. (for example, from <code>unarchiver:didDecodeObject:</code>.
    @param unarchiver the unarchiver that decoded the object
    @param object the original decoded object
    @param newObject the replacement object

    @delegate -(void)unarchiverWillFinish:(CPKeyedUnarchiver)unarchiver;
    Called when the unarchiver is about to finish decoding.
    @param unarchiver the unarchiver that's about to finish

    @delegate -(void)unarchiverDidFinish:(CPKeyedUnarchiver)unarchiver;
    Called when the unarchiver has finished decoding.
    @param unarchiver the unarchiver that finished decoding
*/
@implementation CPKeyedUnarchiver : CPCoder
{
    id              _delegate;
    unsigned        _delegateSelectors;
    
    CPData          _data;

    CPDictionary    _replacementClasses;
    
    CPDictionary    _objects;
    CPDictionary    _archive;
    
    CPDictionary    _plistObject;
    CPArray         _plistObjects;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self !== [CPKeyedUnarchiver class])
        return;
    
    _CPKeyedUnarchiverArrayClass = [CPArray class];
    _CPKeyedUnarchiverStringClass = [CPString class];
    _CPKeyedUnarchiverDictionaryClass = [CPDictionary class];
    _CPKeyedUnarchiverNumberClass = [CPNumber class];
    _CPKeyedUnarchiverDataClass = [CPData class];
    _CPKeyedUnarchiverArchiverValueClass = [_CPKeyedArchiverValue class];
}

/*
    Initializes the receiver to unarchive objects from the specified data object.
    @param data the data stream from which to read objects
    @return the initialized unarchiver
*/
- (id)initForReadingWithData:(CPData)data
{
    self = [super init];

    if (self)
    {
        _archive = [data plistObject];
        _objects = [CPArray arrayWithObject:[CPNull null]];
        
        _plistObject = [_archive objectForKey:_CPKeyedArchiverTopKey];
        _plistObjects = [_archive objectForKey:_CPKeyedArchiverObjectsKey];

        _replacementClasses = [CPDictionary dictionary];
    }
    
    return self;
}

/*
    Unarchives the object graph in the provided data object.
    @param data the data from which to read the graph
    @return the unarchived object
*/
+ (id)unarchiveObjectWithData:(CPData)data
{
    var unarchiver = [[self alloc] initForReadingWithData:data],
        object = [unarchiver decodeObjectForKey:@"root"];
         
    [unarchiver finishDecoding];
    
    return object;
}

/*
    Not implemented
*/
+ (id)unarchiveObjectWithFile:(CPString)aFilePath
{
}

/*
    Not implemented
*/
+ (id)unarchiveObjectWithFile:(CPString)aFilePath asynchronously:(BOOL)aFlag
{
}

/*
    Returns <code>YES</code> if an object exists for <code>aKey</code>.
    @param aKey the object's associated key
*/
- (BOOL)containsValueForKey:(CPString)aKey
{
    return [_plistObject objectForKey:aKey] != nil;
}

/* @ignore */
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

/*
    Decodes a <code>BOOL</code> from the archive
    @param aKey the <code>BOOL</code>'s associated key
    @return the decoded <code>BOOL</code>
*/
- (BOOL)decodeBoolForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

/*
    Decodes a <code>float</code> from the archive
    @param aKey the <code>float</code>'s associated key
    @return the decoded <code>float</code>
*/
- (float)decodeFloatForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

/*
    Decodes a <code>double</code> from the archive.
    @param aKey the <code>double</code>'s associated key
    @return the decoded <code>double</code>
*/
- (double)decodeDoubleForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

/*
    Decodes an <code>int</code> from the archive.
    @param aKey the <code>int</code>'s associated key
    @return the decoded <code>int</code>
*/
- (int)decodeIntForKey:(CPString)aKey
{
    return [self decodeObjectForKey:aKey];
}

/*
    Decodes a CGPoint from the archive.
    @param aKey the point's associated key
    @return the decoded point
*/
- (CGPoint)decodePointForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPPointFromString(object);
    else
        return CPPointMake(0.0, 0.0);
}

/*
    Decodes a CGRect from the archive.
    @param aKey the rectangle's associated key
    @return the decoded rectangle
*/
- (CGRect)decodeRectForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPRectFromString(object);
    else
        return CPRectMakeZero();
}

/*
    Decodes a CGSize from the archive.
    @param aKey the size's associated key
    @return the decoded size
*/
- (CGSize)decodeSizeForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];
    
    if(object)
        return CPSizeFromString(object);
    else
        return CPSizeMake(0.0, 0.0);
}

/*
    Decodes an object from the archive.
    @param aKey the object's associated key
    @return the decoded object
*/
- (id)decodeObjectForKey:(CPString)aKey
{
    var object = [_plistObject objectForKey:aKey];
    
    if ([object isKindOfClass:_CPKeyedUnarchiverDictionaryClass])
        return _CPKeyedUnarchiverDecodeObjectAtIndex(self, [object objectForKey:_CPKeyedArchiverUIDKey]);

    else if ([object isKindOfClass:_CPKeyedUnarchiverNumberClass] || [object isKindOfClass:_CPKeyedUnarchiverDataClass])
        return object;

    else if ([object isKindOfClass:_CPKeyedUnarchiverArrayClass])
    {
        var index = 0,
            count = object.length,
            array = [];

        for (; index < count; ++index)
            array[index] = _CPKeyedUnarchiverDecodeObjectAtIndex(self, [object[index] objectForKey:_CPKeyedArchiverUIDKey]);
        
        return array;
    }
/*    else
        CPLog([object className] + " " + object + " " + aKey + " " + [_plistObject description]);*/

    return nil;
}

/*
    Decodes bytes from the archive.
    @param aKey the object's associated key
    @return array of bytes
*/
- (id)decodeBytesForKey:(CPString)aKey
{
    // We get the CPData wrapper, then extract the bytes array
    var data = [self decodeObjectForKey:aKey];
    
    if ([data isKindOfClass:[CPData class]])
        return data.bytes;
    
    return nil;
}

/*
    Notifies the delegates that decoding has finished.
*/
- (void)finishDecoding
{
    if (_delegateSelectors & _CPKeyedUnarchiverWillFinishSelector)
        [_delegate unarchiverWillFinish:self];

    if (_delegateSelectors & _CPKeyedUnarchiverDidFinishSelector)
        [_delegate unarchiverDidFinish:self];
}

/*
    Returns the keyed unarchiver's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*
    Sets the unarchiver's delegate
    @param the new delegate
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(unarchiver:cannotDecodeObjectOfClassName:originalClasses:)])
        _delegateSelectors |= _CPKeyedUnarchiverCannotDecodeObjectOfClassNameOriginalClassesSelector;
        
    if ([_delegate respondsToSelector:@selector(unarchiver:didDecodeObject:)])
        _delegateSelectors |= _CPKeyedUnarchiverDidDecodeObjectSelector;
    
    if ([_delegate respondsToSelector:@selector(unarchiver:willReplaceObject:withObject:)])
        _delegateSelectors |= _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector;

    if ([_delegate respondsToSelector:@selector(unarchiverWillFinish:)])
        _delegateSelectors |= _CPKeyedUnarchiverWilFinishSelector;
        
    if ([_delegate respondsToSelector:@selector(unarchiverDidFinish:)])
        _delegateSelectors |= _CPKeyedUnarchiverDidFinishSelector;
}

- (void)setClass:(Class)aClass forClassName:(CPString)aClassName
{
    [_replacementClasses setObject:aClass forKey:aClassName];
}

- (Class)classForClassName:(CPString)aClassName
{
    return [_replacementClasses objectForKey:aClassName];
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
            theClass = [self classForClassName:className];

        if (!theClass)
            theClass = CPClassFromString(className);

        var savedPlistObject = self._plistObject;
        
        self._plistObject = plistObject;

        // Should we only call this on _CPCibClassSwapper? (currently the only class that makes use of this).
        object = [theClass allocWithCoder:self];

        // It is important to do this before calling initWithCoder so that decoding can be self referential (something = self).
        self._objects[anIndex] = object;

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
        
        if (processedObject != object)
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

