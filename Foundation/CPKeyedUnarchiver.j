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

@import "CPArray.j"
@import "CPCoder.j"
@import "CPData.j"
@import "CPDictionary.j"
@import "CPException.j"
@import "CPKeyedArchiver.j"
@import "CPNull.j"
@import "CPNumber.j"
@import "CPString.j"

CPInvalidUnarchiveOperationException    = @"CPInvalidUnarchiveOperationException";

var _CPKeyedUnarchiverCannotDecodeObjectOfClassNameOriginalClassesSelector              = 1 << 0,
    _CPKeyedUnarchiverDidDecodeObjectSelector                                           = 1 << 1,
    _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector                               = 1 << 2,
    _CPKeyedUnarchiverWillFinishSelector                                                = 1 << 3,
    _CPKeyedUnarchiverDidFinishSelector                                                 = 1 << 4,
    CPKeyedUnarchiverDelegate_unarchiver_cannotDecodeObjectOfClassName_originalClasses_ = 1 << 5;

var _CPKeyedArchiverNullString                                              = "$null",

    _CPKeyedArchiverUIDKey                                                  = "CP$UID",

    _CPKeyedArchiverTopKey                                                  = "$top",
    _CPKeyedArchiverObjectsKey                                              = "$objects",
    _CPKeyedArchiverArchiverKey                                             = "$archiver",
    _CPKeyedArchiverVersionKey                                              = "$version",

    _CPKeyedArchiverClassNameKey                                            = "$classname",
    _CPKeyedArchiverClassesKey                                              = "$classes",
    _CPKeyedArchiverClassKey                                                = "$class";

var CPArrayClass                                                            = Nil,
    CPMutableArrayClass                                                     = Nil,
    CPStringClass                                                           = Nil,
    CPDictionaryClass                                                       = Nil,
    CPMutableDictionaryClass                                                = Nil,
    CPNumberClass                                                           = Nil,
    CPDataClass                                                             = Nil,
    _CPKeyedArchiverValueClass                                              = Nil;

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
    @return the Class to use instead or \c nil
    to abort the unarchiving operation

    @delegate -(id)unarchiver:(CPKeyedUnarchiver)unarchiver didDecodeObject:(id)object;
    Called when the unarchiver decodes an object.
    @param unarchiver the unarchiver doing the decoding
    @param object the decoded object
    @return a substitute to use for the decoded object. This can be the same object argument provide,
    another object or \c nil.

    @delegate -(void)unarchiver:(CPKeyedUnarchiver)unarchiver willReplaceObject:(id)object withObject:(id)newObject;
    Called when a decoded object has been substituted with another. (for example, from \c -unarchiver:didDecodeObject:.
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

    CPArray         _objects;
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

    CPArrayClass = [CPArray class];
    CPMutableArrayClass = [CPMutableArray class];
    CPStringClass = [CPString class];
    CPDictionaryClass = [CPDictionary class];
    CPMutableDictionaryClass = [CPMutableDictionary class];
    CPNumberClass = [CPNumber class];
    CPDataClass = [CPData class];
    _CPKeyedArchiverValueClass = [_CPKeyedArchiverValue class];
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
        _objects = [[CPNull null]];

        _plistObject = [_archive objectForKey:_CPKeyedArchiverTopKey];
        _plistObjects = [_archive objectForKey:_CPKeyedArchiverObjectsKey];

        _replacementClasses = new CFMutableDictionary();
    }

    return self;
}

/*
    Unarchives the object graph in the provided data object.
    @param data the data from which to read the graph
    @return the unarchived object
*/
+ (id)unarchiveObjectWithData:(CPData)aData
{
    if (!aData)
    {
        CPLog.error("Null data passed to -[CPKeyedUnarchiver unarchiveObjectWithData:].");
        return nil;
    }

    var unarchiver = [[self alloc] initForReadingWithData:aData],
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
    Returns \c YES if an object exists for \c aKey.
    @param aKey the object's associated key
*/
- (BOOL)containsValueForKey:(CPString)aKey
{
    return _plistObject.valueForKey(aKey) != nil;
}

/* @ignore */
- (CPDictionary)_decodeDictionaryOfObjectsForKey:(CPString)aKey
{
    var object = _plistObject.valueForKey(aKey),
        objectClass = (object != nil) && object.isa;

    if (objectClass === CPDictionaryClass || objectClass === CPMutableDictionaryClass)
    {
        var keys = object.keys(),
            index = 0,
            count = keys.length,
            dictionary = new CFMutableDictionary();

        for (; index < count; ++index)
        {
            var key = keys[index];

            dictionary.setValueForKey(key, _CPKeyedUnarchiverDecodeObjectAtIndex(self, object.valueForKey(key).valueForKey(_CPKeyedArchiverUIDKey)));
        }

        return dictionary;
    }

    return nil;
}

/*
    Decodes a \c BOOL from the archive
    @param aKey the \c BOOL's associated key
    @return the decoded \c BOOL
*/
- (BOOL)decodeBoolForKey:(CPString)aKey
{
    return !![self decodeObjectForKey:aKey];
}

/*
    Decodes a \c float from the archive
    @param aKey the \c float's associated key
    @return the decoded \c float
*/
- (float)decodeFloatForKey:(CPString)aKey
{
    var f = [self decodeObjectForKey:aKey];

    return f === nil ? 0.0 : f;
}

/*
    Decodes a \c double from the archive.
    @param aKey the \c double's associated key
    @return the decoded \c double
*/
- (double)decodeDoubleForKey:(CPString)aKey
{
    var d = [self decodeObjectForKey:aKey];

    return d === nil ? 0.0 : d;
}

/*
    Decodes an \c int from the archive.
    @param aKey the \c int's associated key
    @return the decoded \c int
*/
- (int)decodeIntForKey:(CPString)aKey
{
    var i = [self decodeObjectForKey:aKey];

    return i === nil ? 0 : i;
}

/*
    Decodes a CGPoint from the archive.
    @param aKey the point's associated key
    @return the decoded point
*/
- (CGPoint)decodePointForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];

    if (object)
        return CGPointFromString(object);
    else
        return CGPointMakeZero();
}

/*
    Decodes a CGRect from the archive.
    @param aKey the rectangle's associated key
    @return the decoded rectangle
*/
- (CGRect)decodeRectForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];

    if (object)
        return CGRectFromString(object);
    else
        return CGRectMakeZero();
}

/*
    Decodes a CGSize from the archive.
    @param aKey the size's associated key
    @return the decoded size
*/
- (CGSize)decodeSizeForKey:(CPString)aKey
{
    var object = [self decodeObjectForKey:aKey];

    if (object)
        return CGSizeFromString(object);
    else
        return CGSizeMakeZero();
}

/*
    Decodes an object from the archive.
    @param aKey the object's associated key
    @return the decoded object
*/
- (id)decodeObjectForKey:(CPString)aKey
{
    var object = _plistObject.valueForKey(aKey),
        objectClass = (object != nil) && object.isa;

    if (objectClass === CPDictionaryClass || objectClass === CPMutableDictionaryClass)
        return _CPKeyedUnarchiverDecodeObjectAtIndex(self, object.valueForKey(_CPKeyedArchiverUIDKey));

    else if (objectClass === CPNumberClass || objectClass === CPDataClass || objectClass === CPStringClass)
        return object;

    else if (objectClass === _CPJavaScriptArray)
    {
        var index = 0,
            count = object.length,
            array = [];

        for (; index < count; ++index)
            array[index] = _CPKeyedUnarchiverDecodeObjectAtIndex(self, object[index].valueForKey(_CPKeyedArchiverUIDKey));

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

    if (!data)
        return nil;

    var objectClass = data.isa;

    if (objectClass === CPDataClass)
        return data.bytes();

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
        _delegateSelectors |= _CPKeyedUnarchiverWillFinishSelector;

    if ([_delegate respondsToSelector:@selector(unarchiverDidFinish:)])
        _delegateSelectors |= _CPKeyedUnarchiverDidFinishSelector;

    if ([_delegate respondsToSelector:@selector(unarchiver:cannotDecodeObjectOfClassName:originalClasses:)])
        _delegateSelectors |= CPKeyedUnarchiverDelegate_unarchiver_cannotDecodeObjectOfClassName_originalClasses_;
}

- (void)setClass:(Class)aClass forClassName:(CPString)aClassName
{
    _replacementClasses.setValueForKey(aClassName, aClass);
}

- (Class)classForClassName:(CPString)aClassName
{
    return _replacementClasses.valueForKey(aClassName);
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
    {
        if (object === self._objects[0])
            return nil;
        // Don't return immediately here. The _CPKeyedArchiverValueClass unwrapper code
        // hasn't executed yet.
    }
    else
    {
        var plistObject = self._plistObjects[anIndex],
            plistObjectClass = plistObject.isa;

        if (plistObjectClass === CPDictionaryClass || plistObjectClass === CPMutableDictionaryClass)
        {
            var plistClass = self._plistObjects[plistObject.valueForKey(_CPKeyedArchiverClassKey).valueForKey(_CPKeyedArchiverUIDKey)],
                className = plistClass.valueForKey(_CPKeyedArchiverClassNameKey),
                classes = plistClass.valueForKey(_CPKeyedArchiverClassesKey),
                theClass = [self classForClassName:className];

            if (!theClass)
                theClass = CPClassFromString(className);

            if (!theClass &&
                (self._delegateSelectors & CPKeyedUnarchiverDelegate_unarchiver_cannotDecodeObjectOfClassName_originalClasses_))
            {
                theClass = [self._delegate unarchiver:self cannotDecodeObjectOfClassName:className originalClasses:classes];
            }

            if (!theClass)
                [CPException raise:CPInvalidUnarchiveOperationException format:@"-[CPKeyedUnarchiver decodeObjectForKey:]: cannot decode object of class (%@)", className];

            var savedPlistObject = self._plistObject;

            self._plistObject = plistObject;

            // Should we only call this on _CPCibClassSwapper? (currently the only class that makes use of this).
            object = [theClass allocWithCoder:self];

            // It is important to do this before calling initWithCoder so that decoding can be self referential (something = self).
            self._objects[anIndex] = object;

            var processedObject = [object initWithCoder:self];

            self._plistObject = savedPlistObject;

            if (processedObject !== object)
            {
                if (self._delegateSelectors & _CPKeyedUnarchiverWillReplaceObjectWithObjectSelector)
                    [self._delegate unarchiver:self willReplaceObject:object withObject:processedObject];

                object = processedObject;
                self._objects[anIndex] = processedObject;
            }

            processedObject = [object awakeAfterUsingCoder:self];

            if (processedObject !== object)
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

                if (processedObject && processedObject != object)
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

            if ([object class] === CPStringClass)
            {
                if (object === _CPKeyedArchiverNullString)
                {
                    self._objects[anIndex] = self._objects[0];

                    return nil;
                }
                else
                    self._objects[anIndex] = object = plistObject;
            }
        }
    }

    // If this object is a member of _CPKeyedArchiverValue, then we know
    // that it is a wrapper for a primitive JavaScript object.
    if ((object != nil) && (object.isa === _CPKeyedArchiverValueClass))
        object = [object JSObject];

    return object;
};
