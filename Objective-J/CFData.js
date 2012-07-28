/*
 * CFData.js
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

GLOBAL(CFData) = function()
{
    this._rawString = NULL;

    this._propertyList = NULL;
    this._propertyListFormat = NULL;

    this._JSONObject = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
};

CFData.prototype.propertyList = function()
{
    if (!this._propertyList)
        this._propertyList = CFPropertyList.propertyListFromString(this.rawString());

    return this._propertyList;
};

CFData.prototype.JSONObject = function()
{
    if (!this._JSONObject)
    {
        try
        {
            this._JSONObject = JSON.parse(this.rawString());
        }
        catch (anException)
        {
        }
    }

    return this._JSONObject;
};

CFData.prototype.rawString = function()
{
    if (this._rawString === NULL)
    {
        if (this._propertyList)
            this._rawString = CFPropertyList.stringFromPropertyList(this._propertyList, this._propertyListFormat);

        else if (this._JSONObject)
            this._rawString = JSON.stringify(this._JSONObject);

        else if (this._bytes)
            this._rawString = CFData.bytesToString(this._bytes);

        else if (this._base64)
            this._rawString = CFData.decodeBase64ToString(this._base64, true);

        else
            throw new Error("Can't convert data to string.");
    }

    return this._rawString;
};

CFData.prototype.bytes = function()
{
    if (this._bytes === NULL)
    {
        var bytes = CFData.stringToBytes(this.rawString());
        this.setBytes(bytes);
    }

    return this._bytes;
};

CFData.prototype.base64 = function()
{
    if (this._base64 === NULL)
    {
        var base64;
        if (this._bytes)
            base64 = CFData.encodeBase64Array(this._bytes);
        else
            base64 = CFData.encodeBase64String(this.rawString());

        this.setBase64String(base64);
    }

    return this._base64;
};

GLOBAL(CFMutableData) = function()
{
    CFData.call(this);
};

CFMutableData.prototype = new CFData();

function clearMutableData(/*CFMutableData*/ aData)
{
    this._rawString = NULL;

    this._propertyList = NULL;
    this._propertyListFormat = NULL;

    this._JSONObject = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
}

CFMutableData.prototype.setPropertyList = function(/*PropertyList*/ aPropertyList, /*Format*/ aFormat)
{
    clearMutableData(this);

    this._propertyList = aPropertyList;
    this._propertyListFormat = aFormat;
};

CFMutableData.prototype.setJSONObject = function(/*Object*/ anObject)
{
    clearMutableData(this);

    this._JSONObject = anObject;
};

CFMutableData.prototype.setRawString = function(/*String*/ aString)
{
    clearMutableData(this);

    this._rawString = aString;
};

CFMutableData.prototype.setBytes = function(/*Array*/ bytes)
{
    clearMutableData(this);

    this._bytes = bytes;
};

CFMutableData.prototype.setBase64String = function(/*String*/ aBase64String)
{
    clearMutableData(this);

    this._base64 = aBase64String;
};

// Base64 encoding and decoding

var base64_map_to = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","+","/","="],
    base64_map_from = [];

for (var i = 0; i < base64_map_to.length; i++)
    base64_map_from[base64_map_to[i].charCodeAt(0)] = i;

CFData.decodeBase64ToArray = function(input, strip)
{
    if (strip)
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

    var pad = (input[input.length-1] == "=" ? 1 : 0) + (input[input.length-2] == "=" ? 1 : 0),
        length = input.length,
        output = [];

    var i = 0;
    while (i < length)
    {
        var bits =  (base64_map_from[input.charCodeAt(i++)] << 18) |
                    (base64_map_from[input.charCodeAt(i++)] << 12) |
                    (base64_map_from[input.charCodeAt(i++)] << 6) |
                    (base64_map_from[input.charCodeAt(i++)]);

        output.push((bits & 0xFF0000) >> 16);
        output.push((bits & 0xFF00) >> 8);
        output.push(bits & 0xFF);
    }

    // strip "=" padding from end
    if (pad > 0)
        return output.slice(0, -1 * pad);

    return output;
};

CFData.encodeBase64Array = function(input)
{
    var pad = (3 - (input.length % 3)) % 3,
        length = input.length + pad,
        output = [];

    // pad with nulls
    if (pad > 0) input.push(0);
    if (pad > 1) input.push(0);

    var i = 0;
    while (i < length)
    {
        var bits =  (input[i++] << 16) |
                    (input[i++] << 8)  |
                    (input[i++]);

        output.push(base64_map_to[(bits & 0xFC0000) >> 18]);
        output.push(base64_map_to[(bits & 0x3F000) >> 12]);
        output.push(base64_map_to[(bits & 0xFC0) >> 6]);
        output.push(base64_map_to[bits & 0x3F]);
    }

    // pad with "=" and revert array to previous state
    if (pad > 0)
    {
        output[output.length - 1] = "=";
        input.pop();
    }
    if (pad > 1)
    {
        output[output.length - 2] = "=";
        input.pop();
    }

    return output.join("");
};

CFData.decodeBase64ToString = function(input, strip)
{
    return CFData.bytesToString(CFData.decodeBase64ToArray(input, strip));
};

CFData.decodeBase64ToUtf16String = function(input, strip)
{
    return CFData.bytesToUtf16String(CFData.decodeBase64ToArray(input, strip));
};

CFData.bytesToString = function(bytes)
{
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(NULL, bytes);
};

CFData.stringToBytes = function(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return temp;
};

CFData.encodeBase64String = function(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return CFData.encodeBase64Array(temp);
};

CFData.bytesToUtf16String = function(bytes)
{
    // Strings are encoded with 16 bits per character.
    var temp = [];
    for (var i = 0; i < bytes.length; i += 2)
        temp.push(bytes[i + 1] << 8 | bytes[i]);
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(NULL, temp);
};

CFData.encodeBase64Utf16String = function(input)
{
    // charCodeAt returns UTF-16.
    var temp = [];
    for (var i = 0; i < input.length; i++)
    {
        var c = input.charCodeAt(i);
        temp.push(c & 0xFF);
        temp.push((c & 0xFF00) >> 8);
    }

    return CFData.encodeBase64Array(temp);
};
