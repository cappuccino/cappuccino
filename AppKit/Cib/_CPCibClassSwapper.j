/*
 * _CPCibClassSwapper.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


var _CPCibClassSwapperClassNameKey          = @"_CPCibClassSwapperClassNameKey",
    _CPCibClassSwapperOriginalClassNameKey  = @"_CPCibClassSwapperOriginalClassNameKey";

@implementation _CPCibClassSwapper : CPObject
{
}

+ (id)allocWithCoder:(CPCoder)aCoder
{
    var theClassName = [aCoder decodeObjectForKey:_CPCibClassSwapperClassNameKey],
        theClass = objj_lookUpClass(theClassName);

    if (!theClass)
    {
        CPLog.error("Unable to find class " + theClassName + " in cib file.");
        
        theClassName = [aCoder decodeObjectForKey:_CPCibClassSwapperOriginalClassNameKey];
        theClass = objj_lookUpClass(theClassName);
        
        if (!theClass)
            [CPException raise:CPInvalidArgumentException reason:@"Unable to find class " + theClassName + " in cib file."];
    }

    return [theClass alloc];
}

@end
