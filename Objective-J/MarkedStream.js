/*
 * MarkedStream.js
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

function MarkedStream(/*String*/ aString)
{
    this._string = aString;

    var index = aString.indexOf(";");

    // Grab the magic number.
    this._magicNumber = aString.substr(0, index);

    this._location = aString.indexOf(";", ++index);

    // Grab the version number.
    this._version = aString.substring(index, this._location++);
}

MarkedStream.prototype.magicNumber = function()
{
    return this._magicNumber;
}

DISPLAY_NAME(MarkedStream.prototype.magicNumber);

MarkedStream.prototype.version = function()
{
    return this._version;
}

DISPLAY_NAME(MarkedStream.prototype.version);

MarkedStream.prototype.getMarker = function()
{
    var string = this._string,
        location = this._location;

    if (location >= string.length)
        return null;

    var next = string.indexOf(';', location);

    if (next < 0)
        return null;

    var marker = string.substring(location, next);

    if (marker === 'e')
        return null;

    this._location = next + 1;

    return marker;
}

DISPLAY_NAME(MarkedStream.prototype.getMarker);

MarkedStream.prototype.getString = function()
{
    var string = this._string,
        location = this._location;

    if (location >= string.length)
        return null;

    var next = string.indexOf(';', location);

    if (next < 0)
        return null;

    var size = parseInt(string.substring(location, next), 10),
        text = string.substr(next + 1, size);

    this._location = next + 1 + size;

    return text;
}

DISPLAY_NAME(MarkedStream.prototype.getString);
