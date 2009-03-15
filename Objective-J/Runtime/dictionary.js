/*
 * dictionary.js
 * Objective-J
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

function objj_dictionary()
{
    this._keys       = [];
    this.count       = 0;
    this._buckets    = {};
    this.__address   = _objj_generateObjectHash();
}

function dictionary_containsKey(aDictionary, aKey)
{
    return aDictionary._buckets[aKey] != NULL;
}

#define dictionary_containsKey(aDictionary, aKey) ((aDictionary)._buckets[aKey] != NULL)

function dictionary_getCount(aDictionary)
{
    return aDictionary.count;
}

#define dictionary_getCount(aDictionary) ((aDictionary).count)

function dictionary_getValue(aDictionary, aKey)
{
    return aDictionary._buckets[aKey];
}

#define dictionary_getValue(aDictionary, aKey) ((aDictionary)._buckets[aKey])

function dictionary_setValue(aDictionary, aKey, aValue)
{
    if (aDictionary._buckets[aKey] == NULL)
    {
        aDictionary._keys.push(aKey);
        ++aDictionary.count;
    }
       
    if ((aDictionary._buckets[aKey] = aValue) == NULL)
        --aDictionary.count;
}

#define dictionary_setValue(aDictionary, aKey, aValue)\
{\
    if ((aDictionary)._buckets[aKey] == NULL)\
    {\
        (aDictionary)._keys.push(aKey);\
        ++(aDictionary).count;\
    }\
\
    if (((aDictionary)._buckets[aKey] = aValue) == NULL) \
        --(aDictionary).count;\
}


function dictionary_removeValue(aDictionary, aKey)
{
    if (aDictionary._buckets[aKey] == NULL)
        return;

    --aDictionary.count;
    if (aDictionary._keys.indexOf)
        aDictionary._keys.splice(aDictionary._keys.indexOf(aKey), 1);
    else
    {
        var keys = aDictionary._keys,
            index = 0,
            count = keys.length;
        
        for (; index < count; ++index)
            if (keys[index] == aKey)
            {
                keys.splice(index, 1);
                break;
            }
    }
    
    delete aDictionary._buckets[aKey];
}

function dictionary_replaceValue(aDictionary, aKey, aValue)
{
    if (aDictionary[aKey] == NULL)
        return;

// FIXME: Implement
//    aDictionary.keys.splice(aDictionary.keys.indexOf(aKey), 1);
}

function dictionary_description(aDictionary)
{
    str = "{ ";
    for ( x in aDictionary._buckets)
        str += x + ":" + aDictionary._buckets[x] + ",";
    str += " }";
    
    return str;
}
