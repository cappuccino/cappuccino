/*
 * OldBrowserCompatibility.js
 * Objective-J
 *
 * Created by Martin Carlberg.
 * Copyright 2013, Martin Carlberg.
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

// This is for IE8 support. It doesn't have the Object.create function.
if (!Object.create)
{
    Object.create = function(o)
    {
        if (arguments.length > 1)
            throw new Error('Object.create implementation only accepts the first parameter.');

        function F() {}
        F.prototype = o;
        return new F();
    };
}

// This is for IE8 support. It doesn't have the Object.keys function.
if (!Object.keys)
{
    Object.keys = (function ()
    {
        var hasOwnProperty = Object.prototype.hasOwnProperty,
            hasDontEnumBug = !({toString: null}).propertyIsEnumerable('toString'),
            dontEnums = [
                'toString',
                'toLocaleString',
                'valueOf',
                'hasOwnProperty',
                'isPrototypeOf',
                'propertyIsEnumerable',
                'constructor'
            ],
            dontEnumsLength = dontEnums.length;

        return function (obj)
        {
            if (typeof obj !== 'object' && typeof obj !== 'function' || obj === null)
                throw new TypeError('Object.keys called on non-object');

            var result = [];

            for (var prop in obj)
            {
                if (hasOwnProperty.call(obj, prop))
                    result.push(prop);
            }

            if (hasDontEnumBug)
            {
                for (var i = 0; i < dontEnumsLength; i++)
                {
                    if (hasOwnProperty.call(obj, dontEnums[i]))
                        result.push(dontEnums[i]);
                }
            }
            return result;
        };
    })();
}

// This is for IE8 support. It doesn't have the Array.prototype.indexOf function.
if (!Array.prototype.indexOf)
{
    Array.prototype.indexOf = function(searchElement /*, fromIndex */ )
    {
        "use strict";
        if (this === null)
            throw new TypeError();

        var t = new Object(this),
            len = t.length >>> 0;

        if (len === 0)
            return -1;

        var n = 0;
        if (arguments.length > 1)
        {
            n = Number(arguments[1]);
            if (n != n) // shortcut for verifying if it's NaN
                n = 0;
            else if (n !== 0 && n != Infinity && n != -Infinity)
                n = (n > 0 || -1) * Math.floor(Math.abs(n));
        }

        if (n >= len)
            return -1;

        var k = n >= 0 ? n : Math.max(len - Math.abs(n), 0);
        for (; k < len; k++)
        {
            if (k in t && t[k] === searchElement)
                return k;
        }
        return -1;
    };
}
