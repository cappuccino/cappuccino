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

//import "CPRange.j"
import "CPObject.j"
import "CPEnumerator.j"

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
    
    if (!key)
        return nil;

    return [_dictionary objectForKey:key];
}

@end

@implementation CPDictionary : CPObject
{
}

+ (id)alloc
{
    return new objj_dictionary();
}

+ (id)dictionary
{
    return [[self alloc] init];
}

+ (id)dictionaryWithDictionary:(CPDictionary)aDictionary
{
    return [[self alloc] initWithDictionary:aDictionary];
}

+ (id)dictionaryWithObject:(id)anObject forKey:(id)aKey
{
    return [[self alloc] initWithObjects:[anObject] forKeys:[aKey]];
}

+ (id)dictionaryWithObjects:(CPArray)objects forKeys:(CPArray)keys
{
    return [[self alloc] initWithObjects:objects forKeys:keys];
}
    
- (id)initWithDictionary:(CPDictionary)aDictionary
{
    var key = "",
        dictionary = [[CPDictionary alloc] init];
    
    for (key in aDictionary.buckets)
        [dictionary setObject:[aDictionary objectForKey:key] forKey:key];
        
    return dictionary;
}
    
- (id)initWithObjects:(CPArray)objects forKeys:(CPArray)keyArray
{
    self = [super init];

    if (self)
    {
        var i = [keyArray count];
        
        while (i--)
            [self setObject:objects[i] forKey:keyArray[i]];
    }
    
    return self;
}

- (int)count
{
    return count;
}

- (CPArray)allKeys
{
    return keys;
}

- (CPArray)allValues
{
    var index = keys.length,
        values = [];
        
    while (index--)
        values.push(dictionary_getValue(self, [keys[index]]));

    return values;
}

- (CPEnumerator)keyEnumerator
{
    return [keys objectEnumerator];
}

- (CPEnumerator)objectEnumerator
{
    return [[_CPDictionaryValueEnumerator alloc] initWithDictionary:self];
}

/*
    Instance.isEqualToDictionary(aDictionary)
    {
        if(this.count()!=aDictionary.count()) return NO;
        
        var i= this._keys.count();
        while(i--) if(this.objectForKey(this._keys[i])!=aDictionary.objectForKey(this._keys[i])) return NO;
        
        return YES;
    }
    
    Instance.allKeys()
    {
        return this._keys;
    }
    
    Instance.allKeysForObject(anObject)
    {
        var i= 0,
            keys= CPArray.array(),
            count= this.count();
        
        while((i= this._objects.indexOfObjectInRage(0, count-i))!=CPNotFound) keys.addObject(this._keys[i]);
        
        return keys;
    }
    
    Instance.allValues()
    {
        return this._objects;
    }
    
    Instance.keyEnumerator()
    {
        return this._keys.objectEnumerator();
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
    
    Instance.objectEnumerator()
    {
        return this._objects.objectEnumerator();
    }
*/
- (id)objectForKey:(CPString)aKey
{
    // We should really do this with inlining or something of that nature.
    return buckets[aKey];
    //return dictionary_getValue(self, aKey);
}
/*
    Instance.objectsForKeys(keys, aNotFoundMarker)
    {
        var i= keys.length,
            objects= CPArray.array();
        
        while(i--)
        {
            var object= this.objectForKey(keys[i]);
            objects.addObject(object==nil?aNotFoundMarker:object);
        }
        
        return objects;
    }
    
    Instance.valueForKey(aKey)
    {
        if(aKey.length && aKey[0]=="@") return this.objectForKey(aKey.substr(1));
        
        return base.valueForKey(aKey);
    }
    
    //
    
    Instance.addEntriesFromDictionary(aDictionary)
    {
        var key,
            keyEnumerator= aDictionary.keyEnumerator();

        while(key= keyEnumerator.nextObject()) this.setObjectForKey(aDictionary.objectForKey(key), key);
    }
*/
- (void)removeAllObjects
{
    keys = [];
    count = 0;
    buckets = {};
}

- (void)removeObjectForKey:(id)aKey
{
    dictionary_removeValue(self, aKey);
}
/*
    Instance.removeObjectForKey(aKey)
    {
        var entry= this._dictionary[aKey];
        
        if(entry)
        {
            var range= CPMakeRange(entry.index, 1);
            
            this._keys.removeObjectsInRange(range);
            this._objects.removeObjectsInRange(range);
        
            delete this._dictionary[aKey];
        }
    }
    
    Instance.setDictionary(aDictionary)
    {
        this._keys= CPArray.arrayWithArray(aDictionary.allKeys());
        this._objects= CPArray.arrayWithArray(aDictionary.allValues());
        
        this._dictionary= { };
        
        var i= this._keys.count();
        while(i--) this._dictionary[this._keys[i]]= { object: this._objects[i], index: i };
    }
*/
- (void)setObject:(id)anObject forKey:(id)aKey
{
    dictionary_setValue(self, aKey, anObject);
}
/*
    Instance.setValueForKey(aValue, aKey)
    {
        if(!aValue) this.removeObjectForKey(aKey);
        else this.setObjectForKey(aValue, aKey);
    }
    
    Instance.copy()
    {
        return CPDictionary.alloc().dictionaryWithDictionary(this);
    }
*/

- (CPString)description
{
    var description = @"CPDictionary {\n";
    
    var i = keys.length;
    
    while (i--)
        description += keys[i] +":"+[buckets[keys[i]] description]+"\n";
        
    description += "}";
    
    return description;
}

@end

@implementation CPDictionary (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder _decodeDictionaryOfObjectsForKey:@"CP.objects"];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder _encodeDictionaryOfObjects:self forKey:@"CP.objects"];
}

@end

objj_dictionary.prototype.isa = CPDictionary;
