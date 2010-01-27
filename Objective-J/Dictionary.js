
function Dictionary(/*Dictionary*/ aDictionary)
{
    this._keys = [];
    this._count = 0;
    this._buckets = { };
    this._UID = generateObjectUID();
}

var indexOf = Array.prototype.indexOf,
    hasOwnProperty = Object.prototype.hasOwnProperty;

Dictionary.prototype.copy = function()
{
    // Immutable, so no need to actually copy.
    return this;
}

Dictionary.prototype.mutableCopy = function()
{
    var newDictionary = new MutableDictionary(),
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

Dictionary.prototype.containsKey = function(/*String*/ aKey)
{
    return hasOwnProperty.apply(this._buckets, [aKey]);
}

Dictionary.prototype.containsValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length;

    for (; index < count; ++index)
        if (buckets[keys] === anObject)
            return YES;

    return NO;
}

Dictionary.prototype.count = function()
{
    return this._count;
}

Dictionary.prototype.countOfKey = function(/*String*/ aKey)
{
    return this.containsKey(aKey) ? 1 : 0;
}

Dictionary.prototype.countOfValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length,
        countOfValue = 0;

    for (; index < count; ++index)
        if (buckets[keys] === anObject)
            return ++countOfValue;

    return countOfValue;
}

Dictionary.prototype.keys = function()
{
    return this._keys.slice();
}

Dictionary.prototype.valueForKey = function(/*String*/ aKey)
{
    var buckets = this._buckets;

    if (!hasOwnProperty.apply(buckets, [aKey]))
        return undefined;

    return buckets[aKey];
}

Dictionary.prototype.toString = function()
{
    var string = "{\n",
        keys = this._keys,
        index = 0,
        count = this._count;

    for (; index < count; ++index)
    {
        var key = keys[index];

        string += "\t" + key + " = \"" + this.valueForKey(key).toString().split('\n').join("\n\t") + "\"\n";
    }

    return string + "}";
}

MutableDictionary = function(/*Dictionary*/ aDictionary)
{
    Dictionary.apply(this, []);
}

MutableDictionary.prototype = new Dictionary();

MutableDictionary.prototype.copy = function()
{
    return this.mutableCopy();
}

MutableDictionary.prototype.addValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (this.containsKey(aKey))
        return;

    ++this._count;

    this._keys.push(aKey);
    this._buckets[aKey] = aValue;
}

MutableDictionary.prototype.removeValueForKey = function(/*String*/ aKey)
{
    var indexOfKey = -1;

    if (indexOf)
        indexOfKey = this._keys.indexOf(aKey);
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

MutableDictionary.prototype.removeAllValues = function()
{
    this._count = 0;
    this._keys = [];
    this._buckets = { };
}

MutableDictionary.prototype.replaceValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (!this.containsKey(aKey))
        return;

    this._buckets[aKey] = aValue;
}

MutableDictionary.prototype.setValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (this.containsKey(aKey))
        this.replaceValueForKey(aKey, aValue);

    else
        this.addValueForKey(aKey, aValue);
}

// Exports

exports.Dictionary = Dictionary;
exports.CFDictionary = Dictionary;

exports.MutableDictionary = MutableDictionary;
exports.CFMutableDictionary = MutableDictionary;
