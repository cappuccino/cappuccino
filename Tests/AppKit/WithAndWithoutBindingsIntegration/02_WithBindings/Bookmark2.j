/*
 * Bookmark.j
 * AppKit Tests
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
 *
 * Adapted from Bookmark.m in WithAndWithoutBindings by Apple Inc.
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

@import <Foundation/CPCoder.j>
@import <Foundation/CPDate.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURL.j>

@implementation Bookmark2 : CPObject
{
    CPString    title @accessors;
    CPDate      creationDate @accessors;
    CPURL       URL @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        title = @"new title";
        creationDate = [CPDate date];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[self title] forKey:@"title"];
    [coder encodeObject:[self creationDate] forKey:@"creationDate"];
    [coder encodeObject:[self URL] forKey:@"URL"];
}

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super initWithCoder:coder])
    {
        title = [coder decodeObjectForKey:@"title"];
        creationDate = [coder decodeObjectForKey:@"creationDate"];
        URL = [coder decodeObjectForKey:@"URL"];
    }

    return self;
}

@end
