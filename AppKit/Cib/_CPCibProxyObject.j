/*
 * _CPCibProxyObject.j
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


@implementation _CPCibProxyObject : CPObject
{
    CPString _identifier;
}
@end

var _CPCibProxyObjectIdentifierKey  = @"CPIdentifier";

@implementation _CPCibProxyObject (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _identifier = [aCoder decodeObjectForKey:_CPCibProxyObjectIdentifierKey];

    if ([aCoder respondsToSelector:@selector(externalObjectForProxyIdentifier:)])
        return [aCoder externalObjectForProxyIdentifier:_identifier];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:_CPCibProxyObjectIdentifierKey];
}

@end
