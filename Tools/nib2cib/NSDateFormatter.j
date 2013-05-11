/*
 * NSDateFormatter.j
 * nib2cib
 *
 * Created by Alexander Ljungberg.
 * Copyright 2012, SlevenBits Ltd.
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

@import <Foundation/CPDateFormatter.j>

@global CPDateFormatterBehavior10_0
@global CPDateFormatterBehavior10_4
@global CPDateFormatterMediumStyle

@implementation CPDateFormatter (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        var attributes = [aCoder decodeObjectForKey:@"NS.attributes"];

        _dateStyle = [attributes valueForKey:@"dateStyle"];
        _timeStyle = [attributes valueForKey:@"timeStyle"];
        _formatterBehavior = [attributes valueForKey:@"formatterBehavior"];

        if ([attributes containsKey:@"doesRelativeDateFormatting"])
            _doesRelativeDateFormatting = [attributes valueForKey:@"doesRelativeDateFormatting"];

        _dateFormat = [aCoder decodeObjectForKey:@"NS.format"];
        _allowNaturalLanguage = [aCoder decodeBoolForKey:@"NS.natural"];

        if (_formatterBehavior == CPDateFormatterBehavior10_0)
        {
            _formatterBehavior = CPDateFormatterBehavior10_4;
            _timeStyle = CPDateFormatterMediumStyle;
            _dateStyle = CPDateFormatterMediumStyle;
        }
    }

    return self;
}

@end

@implementation NSDateFormatter : CPDateFormatter
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPDateFormatter class];
}

@end
