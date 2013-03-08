/*
 * NSNumberFormatter.j
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

@import <Foundation/CPNumberFormatter.j>

@implementation CPNumberFormatter (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    // We use [self init] so we can a default-constructed CPNumberFormatter
    self = [self init];

    if (self)
    {
        var attributes = [aCoder decodeObjectForKey:@"NS.attributes"];

        [self setNumberStyle:[attributes valueForKey:@"numberStyle"] || CPNumberFormatterNoStyle];

        if ([attributes containsKey:@"minimum"])
            [self setMinimum:[attributes valueForKey:@"minimum"]];

        if ([attributes containsKey:@"maximum"])
            [self setMaximum:[attributes valueForKey:@"maximum"]];
    }

    return self;
}

@end

@implementation NSNumberFormatter : CPNumberFormatter
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPNumberFormatter class];
}

@end
