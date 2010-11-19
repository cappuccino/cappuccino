/*
 * CPCibBindingConnector.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2010, 280 North, Inc.
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

var CPCibBindingConnectorBindingKey = @"CPCibBindingConnectorBindingKey",
    CPCibBindingConnectorKeyPathKey = @"CPCibBindingConnectorKeyPathKey",
    CPCibBindingConnectorOptionsKey = @"CPCibBindingConnectorOptionsKey";

@implementation CPCibBindingConnector : CPCibConnector
{
    id _binding;
    id _keyPath;
    id _options;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _binding = [aCoder decodeObjectForKey:CPCibBindingConnectorBindingKey];
        _keyPath = [aCoder decodeObjectForKey:CPCibBindingConnectorKeyPathKey];
        _options = [aCoder decodeObjectForKey:CPCibBindingConnectorOptionsKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_binding forKey:CPCibBindingConnectorBindingKey];
    [aCoder encodeObject:_keyPath forKey:CPCibBindingConnectorKeyPathKey];
    [aCoder encodeObject:_options forKey:CPCibBindingConnectorOptionsKey];
}

- (void)establishConnection
{
    [_source bind:_binding toObject:_destination withKeyPath:_keyPath options:_options];
}

@end
