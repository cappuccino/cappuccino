/*
 * CFDictionary.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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

GLOBAL(CFDictionary) = function(/*CFDictionary*/ aDictionary)
{
    this._keys = [];
    this._count = 0;
    this._buckets = { };
    this._UID = objj_generateObjectUID();
}

var indexOf = Array.prototype.indexOf,
    hasOwnProperty = Object.prototype.hasOwnProperty;

CFDictionary.prototype.copy = function()
{
    // Immutable, so no need to actually copy.
    return this;
}

CFDictionary.prototype.mutableCopy = function()
{
    var newDictionary = new CFMutableDictionary(),
        keys = this._keys,
        count = this._count;

    newDictionary._keys = keys.slice();
    newDictionary._count = count;

    var index = 0,
        buckets = this._buckets,
        newBuckets = newDictionary._buckets;

    for (; index < count; ++index)
    {
        var key = keys[index];

        newBuckets[key] = buckets[key];
    }

    return newDictionary;
}

CFDictionary.prototype.containsKey = function(/*String*/ aKey)
{
    return hasOwnProperty.apply(this._buckets, [aKey]);
}

DISPLAY_NAME(CFDictionary.prototype.containsKey);

CFDictionary.prototype.containsValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length;

    for (; index < count; ++index)
    {
        var thisKey = keys[index];
        if (buckets[thisKey] === anObject)
            return YES;
    }

    return NO;
}

DISPLAY_NAME(CFDictionary.prototype.containsValue);

CFDictionary.prototype.count = function()
{
    return this._count;
}

DISPLAY_NAME(CFDictionary.prototype.count);

CFDictionary.prototype.countOfKey = function(/*String*/ aKey)
{
    return this.containsKey(aKey) ? 1 : 0;
}

DISPLAY_NAME(CFDictionary.prototype.countOfKey);

CFDictionary.prototype.countOfValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length,
        countOfValue = 0;

    for (; index < count; ++index)
    {
        var thisKey = keys[index];
        if (buckets[thisKey] === anObject)
            ++countOfValue;
    }

    return countOfValue;
}

DISPLAY_NAME(CFDictionary.prototype.countOfValue);

CFDictionary.prototype.keys = function()
{
    return this._keys.slice();
}

DISPLAY_NAME(CFDictionary.prototype.keys);

CFDictionary.prototype.valueForKey = function(/*String*/ aKey)
{
    var buckets = this._buckets;

    if (!hasOwnProperty.apply(buckets, [aKey]))
        return nil;

    return buckets[aKey];
}

DISPLAY_NAME(CFDictionary.prototype.valueForKey);

CFDictionary.prototype.toString = function()
{
    var string = "{\n",
        keys = this._keys,
        index = 0,
        count = this._count;

    for (; index < count; ++index)
    {
        var key = keys[index];

        string += "\t" + key + " = \"" + String(this.valueForKey(key)).split('\n').join("\n\t") + "\"\n";
    }

    return string + "}";
}

DISPLAY_NAME(CFDictionary.prototype.toString);

GLOBAL(CFMutableDictionary) = function(/*CFDictionary*/ aDictionary)
{
    CFDictionary.apply(this, []);
}

CFMutableDictionary.prototype = new CFDictionary();

CFMutableDictionary.prototype.copy = function()
{
    return this.mutableCopy();
}

CFMutableDictionary.prototype.addValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (this.containsKey(aKey))
        return;

    ++this._count;

    this._keys.push(aKey);
    this._buckets[aKey] = aValue;
}

DISPLAY_NAME(CFMutableDictionary.prototype.addValueForKey);

CFMutableDictionary.prototype.removeValueForKey = function(/*String*/ aKey)
{
    var indexOfKey = -1;

    if (indexOf)
        indexOfKey = indexOf.call(this._keys, aKey);
    else
    {
        var keys = this._keys,
            index = 0,
            count = keys.length;
        
        for (; index < count; ++index)
            if (keys[index] === aKey)
            {
                indexOfKey = index;
                break;
            }
    }

    if (indexOfKey === -1)
        return;

    --this._count;

    this._keys.splice(indexOfKey, 1);
    delete this._buckets[aKey];
}

DISPLAY_NAME(CFMutableDictionary.prototype.removeValueForKey);

CFMutableDictionary.prototype.removeAllValues = function()
{
    this._count = 0;
    this._keys = [];
    this._buckets = { };
}

DISPLAY_NAME(CFMutableDictionary.prototype.removeAllValues);

CFMutableDictionary.prototype.replaceValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (!this.containsKey(aKey))
        return;

    this._buckets[aKey] = aValue;
}

DISPLAY_NAME(CFMutableDictionary.prototype.replaceValueForKey);

CFMutableDictionary.prototype.setValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (aValue === nil || aValue === undefined)
        this.removeValueForKey(aKey);

    else if (this.containsKey(aKey))
        this.replaceValueForKey(aKey, aValue);

    else
        this.addValueForKey(aKey, aValue);
}

DISPLAY_NAME(CFMutableDictionary.prototype.setValueForKey);
