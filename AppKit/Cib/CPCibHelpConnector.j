/*
 * CPCibHelpConnector.j
 * AppKit
 *
 * Created by Antoine Mercadal.
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

@implementation CPCibHelpConnector : CPCibConnector
{
    id _destination;
    id _file;
    id _marker;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _destination = [aCoder decodeObjectForKey:@"_destination"];
        _file = [aCoder decodeObjectForKey:@"_file"];
        _marker = [aCoder decodeObjectForKey:@"_marker"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_destination forKey:@"_destination"];
    [aCoder encodeObject:_file forKey:@"_file"];
    [aCoder encodeObject:_marker forKey:@"_marker"];
}

- (void)establishConnection
{
    [_destination setToolTip:_marker];
}

@end

