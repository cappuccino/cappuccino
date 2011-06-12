/*
 * NSImage.j
 * nib2cib
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
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

@import <AppKit/CPImage.j>

@implementation CPImage (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];

    if (self)
    {
        var imageFlags = [aCoder decodeIntForKey:@"NSImageFlags"];

        // TODO Do something with this serialised image data.
        // var imageContentReps = [aCoder decodeObjectForKey:@"NSReps"];

        _size = [aCoder decodeSizeForKey:@"NSSize"];
    }

    return self;
}

@end

@implementation NSImage : CPImage
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPImage class];
}

@end
