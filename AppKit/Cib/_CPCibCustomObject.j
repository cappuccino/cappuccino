/*
 * _CPCibCustomObject.j
 * AppKit
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

@import <Foundation/CPObject.j>
@import <Foundation/CPObjJRuntime.j>

@class CPApplication


var _CPCibCustomObjectClassName = @"_CPCibCustomObjectClassName";

@implementation _CPCibCustomObject : CPObject
{
    CPString _className;
}

- (CPString)customClassName
{
    return _className;
}

- (void)setCustomClassName:(CPString)aClassName
{
    _className = aClassName;
}

- (CPString)description
{
    return [super description] + " (" + [self customClassName] + ')';
}

@end

@implementation _CPCibCustomObject (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _className = [aCoder decodeObjectForKey:_CPCibCustomObjectClassName];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_className forKey:_CPCibCustomObjectClassName];
}

- (id)_cibInstantiate
{
    var theClass = CPClassFromString(_className);

    // Hey this is us!
    if (theClass === [self class])
    {
        _className = @"CPObject";

        return self;
    }

    if (!theClass)
    {
#if DEBUG
        CPLog("Unknown class \"" + _className + "\" in cib file");
#endif
        theClass = [CPObject class];
    }

    if (theClass === [CPApplication class])
        return [CPApplication sharedApplication];

    return [[theClass alloc] init];
}

@end
