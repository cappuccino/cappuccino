/*
 * _CPLocalizableString.j
 * AppKit
 *
 * Created by Alexandre Wilhelm.
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

@import <Foundation/CPString.j>
@import <Foundation/CPCharacterSet.j>

@implementation _CPLocalizableString : CPObject
{
    CPString _dev   @accessors(property=dev);
    CPString _key   @accessors(property=key);
    CPString _value @accessors(property=value);
}

@end


var CPLocalizableStringDev = @"CPLocalizableStringDev",
    CPLocalizableStringKey = @"CPLocalizableStringKey",
    CPLocalizableStringValue = @"CPLocalizableStringValue";

@implementation _CPLocalizableString (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    [self init];

    _dev = [aCoder decodeObjectForKey:CPLocalizableStringDev];
    _key = [aCoder decodeObjectForKey:CPLocalizableStringKey];
    _value = [aCoder decodeObjectForKey:CPLocalizableStringValue];

    var tableName = [[aCoder cibName] stringByTrimmingCharactersInSet:[CPCharacterSet characterSetWithCharactersInString:@".cib"]];

    return [[aCoder bundle] localizedStringForKey:_key value:_value table:tableName];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_dev forKey:CPLocalizableStringDev];
    [aCoder encodeObject:_key forKey:CPLocalizableStringKey];
    [aCoder encodeObject:_value forKey:CPLocalizableStringValue];
}

@end