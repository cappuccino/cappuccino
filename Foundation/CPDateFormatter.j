/*
 * CPDateFormatter.j
 * Foundation
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

#import "Ref.h"

@import <Foundation/CPDate.j>
@import <Foundation/CPString.j>
@import <Foundation/CPFormatter.j>

CPDateFormatterNoStyle     = 0;
CPDateFormatterShortStyle  = 1;
CPDateFormatterMediumStyle = 2;
CPDateFormatterLongStyle   = 3;
CPDateFormatterFullStyle   = 4;

/*!
    @ingroup foundation
    @class CPDateFormatter

    * Not yet implemented. This is a stub class. *

    CPDateFormatter takes a CPDate value and formats it as text for
    display. It also supports the converse, taking text and interpreting it as a
    CPDate by configurable formatting rules.
*/
@implementation CPDateFormatter : CPFormatter
{
    CPDateFormatterStyle _dateStyle @accessors(property=dateStyle);
}

- (id)init
{
    if (self = [super init])
    {
        _dateStyle = CPDateFormatterShortStyle;
    }

    return self;
}

- (CPString)stringFromDate:(CPDate)aDate
{
    // TODO Add locale support.
    switch (_dateStyle)
    {
        case CPDateFormatterShortStyle:
            var format = "d/m/Y";
            return aDate.dateFormat(format);
        default:
            return [aDate description];
    }
}

- (CPDate)dateFromString:(CPString)aString
{
    if (!aString)
        return nil;
    switch (_dateStyle)
    {
        case CPDateFormatterShortStyle:
            var format = "d/m/Y";
            return Date.parseDate(string, format);
        default:
            return Date.parseDate(string);
    }
}

- (CPString)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[CPDate class]])
        return [self stringFromDate:anObject];
    else
        return [anObject description];
}

- (CPString)editingStringForObjectValue:(id)anObject
{
    return [self stringForObjectValue:anObject];
}

- (BOOL)getObjectValue:(id)anObject forString:(CPString)aString errorDescription:(CPString)anError
{
    // TODO Error handling.
    var value = [self dateFromString:aString];
    AT_DEREF(anObject, value);

    return YES;
}

@end

var CPDateFormatterStyleKey = "CPDateFormatterStyle";

@implementation CPDateFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _dateStyle = [aCoder decodeIntForKey:CPDateFormatterStyleKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_dateStyle forKey:CPDateFormatterStyleKey];
}

@end
