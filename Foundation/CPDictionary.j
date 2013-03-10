/*
 * CPDictionary.j
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
@import "CPEnumerator.j"
@import "CPException.j"
@import "CPNull.j"
@import "CPObject.j"

//FIXME: After release of 0.9.7 remove below variable
var CPDictionaryShowNilDeprecationMessage = YES;

/* @ignore */
@implementation _CPDictionaryValueEnumerator : CPEnumerator
{
    CPEnumerator    _keyEnumerator;
    CPDictionary    _dictionary;
}

- (id)initWithDictionary:(CPDictionary)aDictionary
{
    self = [super init];

    if (self)
    {
        _keyEnumerator = [aDictionary keyEnumerator];
        _dictionary = aDictionary;
    }

    return self;
}

- (id)nextObject
{
    var key = [_keyEnumerator nextObject];

    if (key === nil)
        return nil;

    return [_dictionary objectForKey:key];
}

@end

/*!
    @class CPDictionary
    @ingroup foundation
    @brief A mutable key-value pair collection.

    A dictionary is the standard way of passing around key-value pairs in
    the Cappuccino framework. It is similar to the
    <a href="http://java.sun.com/javase/6/docs/api/index.html">Java map interface</a>,
    except all keys are CPStrings and values can be any
    Cappuccino or JavaScript object.

    If you are familiar with dictionaries in Cocoa, you'll notice that
    there is no CPMutableDictionary class. The regular CPDictionary
    has \c -setObject:forKey: and \c -removeObjectForKey: methods.
    In Cappuccino there is no distinction between immutable and mutable classes.
    They are all mutable.
*/
@implementation CPDictionary : CPObject
{
}

/*
    @ignore
*/
+ (id)alloc
{
    var result = new CFMutableDictionary();
    result.isa = [self class];
    return result;
}

/*!
    Returns a new empty CPDictionary.
*/
+ (id)dictionary
{
    return [[self alloc] init];
}

/*!
    Returns a new dictionary, initialized with the contents of \c aDictionary.
    @param aDictionary the dictionary to copy key-value pairs from
    @return the new CPDictionary
*/
+ (id)dictionaryWithDictionary:(CPDictionary)aDictionary
{
    return [[self alloc] initWithDictionary:aDictionary];
}

/*!
    Creates a new dictionary with single key-value pair.
    @param anObject the object for the paring
    @param aKey the key for the pairing
    @return the new CPDictionary
*/
+ (id)dictionaryWithObject:(id)anObject forKey:(id)aKey
{
    return [[self alloc] initWithObjects:[anObject] forKeys:[aKey]];
}

/*!
    Creates a dictionary with multiple key-value pairs.
    @param objects the objects to place in the dictionary
    @param keys the keys for each of the objects
    @throws CPInvalidArgumentException if the number of objects and keys is different
    @return the new CPDictionary
*/
+ (id)dictionaryWithObjects:(CPArray)objects forKeys:(CPArray)keys
{
    return [[self alloc] initWithObjects:objects forKeys:keys];
}

/*!
    Creates a dictionary with multiple key-value pairs.
    @param JavaScript object
    @return the new CPDictionary
*/
+ (id)dictionaryWithJSObject:(JSObject)object
{
    return [self dictionaryWithJSObject:object recursively:NO];
}

/*!
    Creates a dictionary with multiple key-value pairs, recursively.
    @param JavaScript object
    @return the new CPDictionary
*/
+ (id)dictionaryWithJSObject:(JSObject)object recursively:(BOOL)recursively
{
    var key = "",
        dictionary = [[self alloc] init];

    for (key in object)
    {
        if (!object.hasOwnProperty(key))
            continue;

        var value = object[key];

        if (value === null)
        {
            [dictionary setObject:[CPNull null] forKey:key];
            continue;
        }

        if (recursively)
        {
            if (value.constructor === Object)
                value = [CPDictionary dictionaryWithJSObject:value recursively:YES];
            else if ([value isKindOfClass:CPArray])
            {
                var newValue = [],
                    i = 0,
                    count = value.length;

                for (; i < count; i++)
                {
                    var thisValue = value[i];

                    if (thisValue === null)
                    {
                        newValue.push([CPNull null]);
                    }
                    else
                    {
                        if (thisValue.constructor === Object)
                            newValue.push([CPDictionary dictionaryWithJSObject:thisValue recursively:YES]);
                        else
                            newValue.push(thisValue);
                    }
                }

                value = newValue;
            }
        }

        [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

/*!
    Creates and returns a dictionary constructed by a given pairs of keys and values.
    @param firstObject first object value
    @param ... key for the first object and ongoing value-key pairs for more objects.
    @throws CPInvalidArgumentException if the number of objects and keys is different
    @return the new CPDictionary

    Assuming that there's no object retaining in Cappuccino, you can create
    dictionaries same way as with alloc and initWithObjectsAndKeys:
    var dict = [CPDictionary dictionaryWithObjectsAndKeys:
    @"value1", @"key1",
    @"value2", @"key2"];

    Note, that there's no final nil like in Objective-C/Cocoa.

    @see [CPDictionary initWithObjectsAndKeys:]
*/
+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ...
{
    arguments[0] = [self alloc];
    arguments[1] = @selector(initWithObjectsAndKeys:);

    return objj_msgSend.apply(this, arguments);
}

/*!
    Initializes the dictionary with the contents of another dictionary.
    @param aDictionary the dictionary to copy key-value pairs from
    @return the initialized dictionary
*/
- (id)initWithDictionary:(CPDictionary)aDictionary
{
    var key = "",
        dictionary = [[CPDictionary alloc] init];

    for (key in aDictionary._buckets)
        [dictionary setObject:[aDictionary objectForKey:key] forKey:key];

    return dictionary;
}

/*!
    Initializes the dictionary from the arrays of keys and objects.
    @param objects the objects to put in the dictionary
    @param keyArray the keys for the objects to put in the dictionary
    @throws CPInvalidArgumentException if the number of objects and keys is different
    @return the initialized dictionary
*/
- (id)initWithObjects:(CPArray)objects forKeys:(CPArray)keyArray
{
    self = [super init];

    if ([objects count] != [keyArray count])
        [CPException raise:CPInvalidArgumentException reason:[CPString stringWithFormat:@"Counts are different.(%d != %d)", [objects count], [keyArray count]]];

    if (self)
    {
        var i = [keyArray count];

        while (i--)
        {
            var value = objects[i],
                key = keyArray[i];

            if (value === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil object from objects[%d]", [self className], _cmd, i]);

                if (typeof(objj_backtrace_print) === "function")
                    objj_backtrace_print(CPLog.warn);

                // FIXME: After release of 0.9.7 change this block to:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil object from objects[" + i + @"]"];
            }

            if (key === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil key from keys[%d]", [self className], _cmd, i]);

                if (typeof(objj_backtrace_print) === "function")
                    objj_backtrace_print(CPLog.warn);

                // FIXME: After release of 0.9.7 change this block to:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil key from keys[" + i + @"]"];
            }

            [self setObject:value forKey:key];
        }
    }

    return self;
}

/*!
    Creates and returns a dictionary constructed by a given pairs of keys and values.
    @param firstObject first object value
    @param ... key for the first object and ongoing value-key pairs for more objects.
    @throws CPInvalidArgumentException if the number of objects and keys is different
    @return the new CPDictionary

    You can create dictionaries this way:
    var dict = [[CPDictionary alloc] initWithObjectsAndKeys:
    @"value1", @"key1",
    @"value2", @"key2"];

    Note, that there's no final nil like in Objective-C/Cocoa.
*/
- (id)initWithObjectsAndKeys:(id)firstObject, ...
{
    var argCount = arguments.length;

    if (argCount % 2 !== 0)
        [CPException raise:CPInvalidArgumentException reason:"Key-value count is mismatched. (" + argCount + " arguments passed)"];

    self = [super init];

    if (self)
    {
        // The arguments array contains self and _cmd, so the first object is at position 2.
        var index = 2;

        for (; index < argCount; index += 2)
        {
            var value = arguments[index],
                key = arguments[index + 1];

            if (value === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil object from objects[%d]", [self className], _cmd, (index / 2) - 1]);

                if (typeof(objj_backtrace_print) === "function")
                    objj_backtrace_print(CPLog.warn);

                // FIXME: After release of 0.9.7 change 3 lines above to this:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil object from objects[" + ((index / 2) - 1) + @"]"];
            }

            if (key === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil key from keys[%d]", [self className], _cmd, (index / 2) - 1]);

                if (typeof(objj_backtrace_print) === "function")
                    objj_backtrace_print(CPLog.warn);

                // FIXME: After release of 0.9.7 change 3 lines above to this:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil key from keys[" + ((index / 2) - 1) + @"]"];
            }

            [self setObject:value forKey:key];
        }
    }

    return self;
}

/*!
    return a copy of the receiver (does not deep copy the objects contained in the dictionary).
*/
- (CPDictionary)copy
{
    return [CPDictionary dictionaryWithDictionary:self];
}

/*!
    Returns the number of entries in the dictionary
*/
- (int)count
{
    return self._count;
}

/*!
    Returns an array of keys for all the entries in the dictionary.
*/
- (CPArray)allKeys
{
    return [self._keys copy];
}

/*!
    Returns an array of values for all the entries in the dictionary.
*/
- (CPArray)allValues
{
    var keys = self._keys,
        index = keys.length,
        values = [];

    while (index--)
        values.push(self.valueForKey(keys[index]));

    return values;
}

/*!
    Returns a new array containing the keys corresponding to all occurrences of a given object in the receiver.
    @param anObject The value to look for in the receiver.
    @return A new array containing the keys corresponding to all occurrences of anObject in the receiver. If no object matching anObject is found, returns an empty array.

    Each object in the receiver is sent an isEqual: message to determine if it's equal to anObject.
    If the check for isEqual fails a check is made to see if the two objects are the same object. This provides compatibility for JSObjects.
*/
- (CPArray)allKeysForObject:(id)anObject
{
    var keys = self._keys,
        count = keys.length,
        index = 0,
        matchingKeys = [],
        key = nil,
        value = nil;

    for (; index < count; ++index)
    {
        key = keys[index];
        value = self._buckets[key];

        if (value.isa && anObject && anObject.isa && [value respondsToSelector:@selector(isEqual:)] && [value isEqual:anObject])
            matchingKeys.push(key);
        else if (value === anObject)
            matchingKeys.push(key);
    }

    return matchingKeys;
}

- (CPArray)keysOfEntriesPassingTest:(Function /*(id key, id obj, @ref BOOL stop)*/)predicate
{
    return [self keysOfEntriesWithOptions:CPEnumerationNormal passingTest:predicate];
}

- (CPArray)keysOfEntriesWithOptions:(CPEnumerationOptions)options passingTest:(Function /*(id key, id obj, @ref BOOL stop)*/)predicate
{
    var keys = self._keys;

    if (options & CPEnumerationReverse)
    {
        var index = [keys count] - 1,
            stop = -1,
            increment = -1;
    }
    else
    {
        var index = 0,
            stop = [keys count],
            increment = 1;
    }

    var matchingKeys = [],
        key = nil,
        value = nil,
        shouldStop = NO,
        stopRef = @ref(shouldStop);

    for (; index !== stop; index += increment)
    {
        key = keys[index];
        value = self._buckets[key];

        if (predicate(key, value, stopRef))
            matchingKeys.push(key);

        if (shouldStop)
            break;
    }

    return matchingKeys;
}

- (CPArray)keysSortedByValueUsingComparator:(Function /*(id obj1, id obj2)*/)comparator
{
    return [[self allKeys] sortedArrayUsingFunction:function(a, b)
        {
            a = [self objectForKey:a];
            b = [self objectForKey:b];

            return comparator(a, b);
        }
    ];
}

- (CPArray)keysSortedByValueUsingSelector:(SEL)theSelector
{
    return [[self allKeys] sortedArrayUsingFunction:function(a, b)
        {
            a = [self objectForKey:a];
            b = [self objectForKey:b];

            return [a performSelector:theSelector withObject:b];
        }
    ];
}

/*!
    Returns an enumerator that enumerates over all the dictionary's keys.
*/
- (CPEnumerator)keyEnumerator
{
    return [self._keys objectEnumerator];
}

/*!
    Returns an enumerator that enumerates over all the dictionary's values.
*/
- (CPEnumerator)objectEnumerator
{
    return [[_CPDictionaryValueEnumerator alloc] initWithDictionary:self];
}

/*!
    Compare the receiver to this dictionary, and return whether or not they are equal.
*/
- (BOOL)isEqualToDictionary:(CPDictionary)aDictionary
{
    if (self === aDictionary)
        return YES;

    var count = [self count];

    if (count !== [aDictionary count])
        return NO;

    var index = count,
        keys = self._keys;

    while (index--)
    {
        var currentKey = keys[index],
            lhsObject = self._buckets[currentKey],
            rhsObject = aDictionary._buckets[currentKey];

        if (lhsObject === rhsObject)
            continue;

        if (lhsObject && lhsObject.isa && rhsObject && rhsObject.isa && [lhsObject respondsToSelector:@selector(isEqual:)] && [lhsObject isEqual:rhsObject])
            continue;

        return NO;
    }

    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (![anObject isKindOfClass:[CPDictionary class]])
        return NO;

    return [self isEqualToDictionary:anObject];
}

/*
    Instance.allKeysForObject(anObject)
    {
        var i= 0,
            keys= CPArray.array(),
            count= this.count();

        while ((i= this._objects.indexOfObjectInRage(0, count-i))!=CPNotFound) keys.addObject(this._keys[i]);

        return keys;
    }

    Instance.keysSortedByValueUsingSelector(aSelector)
    {
        var dictionary= this,
            objectSelector= function(rhs)
            {
                return aSelector.apply(dictionary.objectForKey(this), [dictionary.objectForKey(rhs)]);
            };

        return this._keys.sortedArrayUsingSelector(objectSelector);
    }
*/
/*!
    Returns the object for the entry with key \c aKey.
    @param aKey the key for the object's entry
    @return the object for the entry
*/
- (id)objectForKey:(id)aKey
{
    var object = self._buckets[aKey];

    return (object === undefined) ? nil : object;
}
/*
    Instance.objectsForKeys(keys, aNotFoundMarker)
    {
        var i= keys.length,
            objects= CPArray.array();

        while (i--)
        {
            var object= this.objectForKey(keys[i]);
            objects.addObject(object==nil?aNotFoundMarker:object);
        }

        return objects;
    }

    Instance.valueForKey(aKey)
    {
        if (aKey.length && aKey[0]=="@") return this.objectForKey(aKey.substr(1));

        return base.valueForKey(aKey);
    }
*/
/*!
    Removes all the entries from the dictionary.
*/
- (void)removeAllObjects
{
    self.removeAllValues();
}

/*!
    Removes the entry for the specified key.
    @param aKey the key of the entry to be removed
*/
- (void)removeObjectForKey:(id)aKey
{
    self.removeValueForKey(aKey);
}

/*!
    Removes each entry in allKeys from the receiver.
    @param allKeys an array of keys that will be removed from the dictionary
*/
- (void)removeObjectsForKeys:(CPArray)keysForRemoval
{
    var index = keysForRemoval.length;

    while (index--)
        [self removeObjectForKey:keysForRemoval[index]];
}

/*
    Instance.setDictionary(aDictionary)
    {
        this._keys= CPArray.arrayWithArray(aDictionary.allKeys());
        this._objects= CPArray.arrayWithArray(aDictionary.allValues());

        this._dictionary= { };

        var i= this._keys.count();
        while (i--) this._dictionary[this._keys[i]]= { object: this._objects[i], index: i };
    }
*/
/*!
    Adds an entry into the dictionary.
    @param anObject the object for the entry
    @param aKey the entry's key
*/
- (void)setObject:(id)anObject forKey:(id)aKey
{
    // FIXME: After release of 0.9.7, remove this test and leave the contents of its block
    if (CPDictionaryShowNilDeprecationMessage)
    {
        if (aKey === nil)
        {
            CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: key cannot be nil", [self className], _cmd]);

            if (typeof(objj_backtrace_print) === "function")
                objj_backtrace_print(CPLog.warn);

            // FIXME: After release of 0.9.7 change this block to:
            // [CPException raise:CPInvalidArgumentException reason:@"key cannot be nil"];
        }

        if (anObject === nil)
        {
            CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: object cannot be nil (key: %s)", [self className], _cmd, aKey]);

            if (typeof(objj_backtrace_print) === "function")
                objj_backtrace_print(CPLog.warn);

            // FIXME: After release of 0.9.7 change this block to:
            // [CPException raise:CPInvalidArgumentException reason:@"object cannot be nil (key: " + aKey + @")"];
        }
    }
    // FIXME: After release of 0.9.7 remove 2 lines below.
    else
        CPDictionaryShowNilDeprecationMessage = YES;

    self.setValueForKey(aKey, anObject);
}

/*!
    Take all the key/value pairs in aDictionary and apply them to this dictionary.
*/
- (void)addEntriesFromDictionary:(CPDictionary)aDictionary
{
    if (!aDictionary)
        return;

    var keys = [aDictionary allKeys],
        index = [keys count];

    while (index--)
    {
        var key = keys[index];

        [self setObject:[aDictionary objectForKey:key] forKey:key];
    }
}

/*!
    Returns a human readable description of the dictionary.
*/
- (CPString)description
{
    var string = "@{",
        keys = self._keys,
        index = 0,
        count = self._count;

    for (; index < count; ++index)
    {
        if (index === 0)
            string += "\n";

        var key = keys[index],
            value = self.valueForKey(key);

        string += "    @\"" + key + "\": " + CPDescriptionOfObject(value).split("\n").join("\n    ") + (index + 1 < count ? "," : "") + "\n";
    }

    return string + "}";
}

- (BOOL)containsKey:(id)aKey
{
    var value = [self objectForKey:aKey];
    return ((value !== nil) && (value !== undefined));
}

- (void)enumerateKeysAndObjectsUsingBlock:(Function /*(id aKey, id anObject, @ref BOOL stop)*/)aFunction
{
    var shouldStop = NO,
        shouldStopRef = @ref(shouldStop),
        keys = self._keys,
        count = self._count;

    for (var index = 0; index < count; index++)
    {
        var key = keys[index],
            value = self.valueForKey(key);

        aFunction(key, value, shouldStopRef);

        if (shouldStop)
            return;
    }
}

- (void)enumerateKeysAndObjectsWithOptions:(CPEnumerationOptions)opts usingBlock:(Function /*(id aKey, id anObject, @ref BOOL stop)*/)aFunction
{
    // Ignore the options because neither option has an effect.
    // CPEnumerationReverse has no effect on enumerating a CPDictionary because dictionary enumeration is not ordered.
    // CPEnumerationConcurrent is not possible in a single threaded environment.
    [self enumerateKeysAndObjectsUsingBlock:aFunction];
}

@end

@implementation CPDictionary (CPCoding)

/*
    Initializes the dictionary by unarchiving the data from a coder.
    @param aCoder the coder from which the data will be unarchived.
    @return the initialized dictionary
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder _decodeDictionaryOfObjectsForKey:@"CP.objects"];
}

/*!
    Archives the dictionary to a provided coder.
    @param aCoder the coder to which the dictionary data will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder _encodeDictionaryOfObjects:self forKey:@"CP.objects"];
}

@end

/*!
    @class CPMutableDictionary
    @ingroup compatibility

    This class is just an empty subclass of CPDictionary.
    CPDictionary already implements mutable methods and
    this class only exists for source compatibility.
*/
@implementation CPMutableDictionary : CPDictionary

@end

CFDictionary.prototype.isa = CPDictionary;
CFMutableDictionary.prototype.isa = CPMutableDictionary;
