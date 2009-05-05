/*
 * CPValue.j
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

@import "CPObject.j"
@import "CPCoder.j"


/*! @class CPValue
    The class can be subclassed to hold different types of scalar values.
*/
@implementation CPValue : CPObject
{
    JSObject    _JSObject;
}

/*!
    Creates a value from the specified JavaScript object
    @param aJSObject a JavaScript object containing a value
    @return the converted CPValue
*/
+ (id)valueWithJSObject:(JSObject)aJSObject
{
    return [[self alloc] initWithJSObject:aJSObject];
}

/*!
    Initializes the value from a JavaScript object
    @param aJSObject the object to get data from
    @return the initialized CPValue
*/
- (id)initWithJSObject:(JSObject)aJSObject
{
    self = [super init];
    
    if (self)
        _JSObject = aJSObject;
    
    return self;
}

/*!
    Returns the JavaScript object backing this value.
*/
- (JSObject)JSObject
{
    return _JSObject;
}

@end

var CPValueValueKey = @"CPValueValueKey";

@implementation CPValue (CPCoding)

/*!
    Initializes the value from a coder.
    @param aCoder the coder from which to initialize
    @return the initialized CPValue
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
        _JSObject = CPJSObjectCreateWithJSON([aCoder decodeObjectForKey:CPValueValueKey]);

    return self;
}

/*!
    Encodes the data into the specified coder.
    @param the coder into which the data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:CPJSObjectCreateJSON(_JSObject) forKey:CPValueValueKey];
}

@end

var _JSONCharacterEncodings   = {};

_JSONCharacterEncodings['\b']    = "\\b";
_JSONCharacterEncodings['\t']    = "\\t";
_JSONCharacterEncodings['\n']    = "\\n";
_JSONCharacterEncodings['\f']    = "\\f";
_JSONCharacterEncodings['\r']    = "\\r";
_JSONCharacterEncodings['"']     = "\\\"";
_JSONCharacterEncodings['\\']    = "\\\\";

// FIXME: Workaround for https://trac.280north.com/ticket/16
var _JSONEncodedCharacters  = new RegExp("[\\\"\\\\\\x00-\\x1f\\x7f-\\x9f]", 'g');

function CPJSObjectCreateJSON(aJSObject)
{
    // typeof new Number() and new String() gives you "object", 
    // so valueof in those cases.
    var type = typeof aJSObject,
        valueOf = aJSObject ? aJSObject.valueOf() : null,
        typeValueOf = typeof valueOf;
    
    if (type != typeValueOf)
    {
        type = typeValueOf;
        aJSObject = valueOf;
    }
    
    switch (type)
    {
        case "string":  // If the string contains no control characters, no quote characters, and no
                        // backslash characters, then we can safely slap some quotes around it.
                        // Otherwise we must also replace the offending characters with safe sequences.

                        if (!_JSONEncodedCharacters.test(aJSObject))
                            return '"' + aJSObject + '"';
                        
                        return '"' + aJSObject.replace(_JSONEncodedCharacters, _CPJSObjectEncodeCharacter) + '"';
            

        case "number":  // JSON numbers must be finite. Encode non-finite numbers as null.
                        return isFinite(aJSObject) ? String(aJSObject) : "null";

        case "boolean": 
        case "null":    return String(aJSObject);

        case "object":  // Due to a specification blunder in ECMAScript,
                        // typeof null is 'object', so watch out for that case.
                        
                        if (!aJSObject)
                            return "null";
    
                        // If the object has a toJSON method, call it, and stringify the result.
    
                        if (typeof aJSObject.toJSON === "function")
                            return CPJSObjectCreateJSON(aJSObject.toJSON());
                        
                        var array = [];
                        
                        // If the object is an array. Stringify every element. Use null as a placeholder
                        // for non-JSON values.
                        if (aJSObject.slice)
                        {
                            var index = 0,
                                count = aJSObject.length;
                                
                            for (; index < count; ++index)
                                array.push(CPJSObjectCreateJSON(aJSObject[index]) || "null");
                                                
                            // Join all of the elements together and wrap them in brackets.
                            return '[' + array.join(',') + ']';
                        }
                        
                        
                        // Otherwise, iterate through all of the keys in the object.
                        var key = NULL;
                        
                        for (key in aJSObject)
                        {
                            if (!(typeof key === "string"))
                                continue;
                            
                            var value = CPJSObjectCreateJSON(aJSObject[key]);
                            
                            if (value)
                                array.push(CPJSObjectCreateJSON(key) + ':' + value);
                        }
                        
                        // Join all of the member texts together and wrap them in braces.
                        return '{' + array.join(',') + '}';
    }       
}

var _CPJSObjectEncodeCharacter = function(aCharacter)
{
    var encoding = _JSONCharacterEncodings[aCharacter];
                            
    if (encoding)
        return encoding;
    
    encoding = aCharacter.charCodeAt(0);
                            
    return '\\u00' + FLOOR(encoding / 16).toString(16) + (encoding % 16).toString(16);
}

var _JSONBackslashCharacters    = new RegExp("\\\\.", 'g'),
    _JSONSimpleValueTokens      = new RegExp("\"[^\"\\\\\\n\\r]*\"|true|false|null|-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?", 'g'),
    _JSONValidOpenBrackets      = new RegExp("(?:^|:|,)(?:\\s*\\[)+", 'g'),
    _JSONValidExpression        = new RegExp("^[\\],:{}\\s]*$");

function CPJSObjectCreateWithJSON(aString)
{
    if (_JSONValidExpression.test(aString.replace(_JSONBackslashCharacters, '@').replace(_JSONSimpleValueTokens, ']').replace(_JSONValidOpenBrackets, '')))
        return eval('(' + aString + ')');

    return nil;
}

/*
var _JSONBackslashCharacters    = /\\./g,
    _JSONSimpleValueTokens      = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,
    _JSONValidOpenBrackets      = /(?:^|:|,)(?:\s*\[)+/g,
    _JSONValidExpression        = /^[\],:{}\s]*$/;
*/
