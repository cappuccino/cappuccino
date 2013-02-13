/*
 * CPCibConnector.j
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
@import <Foundation/CPKeyValueCoding.j>


var _CPCibConnectorSourceKey        = @"_CPCibConnectorSourceKey",
    _CPCibConnectorDestinationKey   = @"_CPCibConnectorDestinationKey",
    _CPCibConnectorLabelKey         = @"_CPCibConnectorLabelKey";

@implementation CPCibConnector : CPObject
{
    id          _source @accessors(property=source);
    id          _destination @accessors(property=destination);
    CPString    _label @accessors(property=label);
}

- (void)replaceObject:(id)anObject withObject:(id)anotherObject
{
    if (_source === anObject)
        _source = anotherObject;

    if (_destination === anObject)
        _destination = anotherObject;
}

- (void)replaceObjects:(Object)replacementObjects
{
    var replacement = replacementObjects[[_source UID]];

    if (replacement !== undefined)
        _source = replacement;

    replacement = replacementObjects[[_destination UID]];

    if (replacement !== undefined)
        _destination = replacement;
}

@end

@implementation CPCibConnector (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _source = [aCoder decodeObjectForKey:_CPCibConnectorSourceKey];
        _destination = [aCoder decodeObjectForKey:_CPCibConnectorDestinationKey];
        _label = [aCoder decodeObjectForKey:_CPCibConnectorLabelKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_source forKey:_CPCibConnectorSourceKey];
    [aCoder encodeObject:_destination forKey:_CPCibConnectorDestinationKey];
    [aCoder encodeObject:_label forKey:_CPCibConnectorLabelKey];
}

@end

// For backwards compatibility.
@implementation _CPCibConnector : CPCibConnector
@end
