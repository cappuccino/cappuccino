/*
 * NSAppearance.j
 * nib2cib
 *
 * Created by Antoine Mercadal.
 * Copyright 2015, Cappuccino Project
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

@import <AppKit/CPAppearance.j>


@implementation CPAppearance (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _name = [aCoder decodeObjectForKey:@"NSAppearanceName"].replace(/^NS/, "CP");
    }

    return self;
}

@end

@implementation NSAppearance : CPAppearance

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPAppearance class];
}

@end
