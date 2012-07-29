/*
 * CPCibRuntimeAttributesConnector.j
 * AppKit
 *
 * Created by Aparajita Fishman.
 * Copyright 2012, The Cappuccino Project.
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

@import "CPCibConnector.j"

var CPCibRuntimeAttributesConnectorObjectKey   = @"CPCibRuntimeAttributesConnectorObjectKey",
    CPCibRuntimeAttributesConnectorKeyPathsKey = @"CPCibRuntimeAttributesConnectorKeyPathsKey",
    CPCibRuntimeAttributesConnectorValuesKey   = @"CPCibRuntimeAttributesConnectorValuesKey";

@implementation CPCibRuntimeAttributesConnector : CPCibConnector
{
    id _keyPaths;
    id _values;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _source = [aCoder decodeObjectForKey:CPCibRuntimeAttributesConnectorObjectKey];
        _keyPaths = [aCoder decodeObjectForKey:CPCibRuntimeAttributesConnectorKeyPathsKey];
        _values = [aCoder decodeObjectForKey:CPCibRuntimeAttributesConnectorValuesKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_source forKey:CPCibRuntimeAttributesConnectorObjectKey];
    [aCoder encodeObject:_keyPaths forKey:CPCibRuntimeAttributesConnectorKeyPathsKey];
    [aCoder encodeObject:_values forKey:CPCibRuntimeAttributesConnectorValuesKey];
}

- (void)establishConnection
{
    var count = [_keyPaths count];

    while (count--)
        [_source setValue:_values[count] forKeyPath:_keyPaths[count]];
}

@end
