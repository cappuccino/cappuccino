/*
 * CPDate.j
 * Foundation
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import "CPObject.j"
@import "CPString.j"


var CPDateReferenceDate = new Date(Date.UTC(2001,1,1,0,0,0,0));

/*!
    @class CPDate
    @ingroup foundation
    @brief A representation of a single point in time.


*/
@implementation CPDate : CPObject
{
}

+ (id)alloc
{
    return new Date;
}

+ (id)date
{
    return [[self alloc] init];
}

+ (id)dateWithTimeIntervalSinceNow:(CPTimeInterval)seconds
{
    return [[CPDate alloc] initWithTimeIntervalSinceNow:seconds];
}

+ (id)dateWithTimeIntervalSince1970:(CPTimeInterval)seconds
{
    return [[CPDate alloc] initWithTimeIntervalSince1970:seconds];
}

+ (id)dateWithTimeIntervalSinceReferenceDate:(CPTimeInterval)seconds
{
    return [[CPDate alloc] initWithTimeIntervalSinceReferenceDate:seconds];
}

+ (id)distantPast
{
    return new Date(-10000,1,1,0,0,0,0);
}

+ (id)distantFuture
{
    return new Date(10000,1,1,0,0,0,0);
}

- (id)initWithTimeIntervalSinceNow:(CPTimeInterval)seconds
{
    self = new Date((new Date()).getTime() + seconds * 1000);
    return self;
}

- (id)initWithTimeIntervalSince1970:(CPTimeInterval)seconds
{
    self = new Date(seconds * 1000);
    return self;
}

- (id)initWithTimeIntervalSinceReferenceDate:(CPTimeInterval)seconds
{
    self = [self initWithTimeInterval:seconds sinceDate:CPDateReferenceDate];
    return self;
}

- (id)initWithTimeInterval:(CPTimeInterval)seconds sinceDate:(CPDate)refDate
{
    self = new Date(refDate.getTime() + seconds * 1000);
    return self;
}

/*!
    Returns a CPDate initialized with a date and time specified by the given
    string in international date format YYYY-MM-DD HH:MM:SS ±HHMM (e.g.
    2009-11-17 17:52:04 +0000).
*/
- (id)initWithString:(CPString)description
{
    var format = /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([-+])(\d{2})(\d{2})/,
        d = description.match(new RegExp(format));

    if (!d || d.length != 10)
        [CPException raise:CPInvalidArgumentException
                    reason:"initWithString: the string must be of YYYY-MM-DD HH:MM:SS ±HHMM format"];

    var date = new Date(d[1], d[2]-1, d[3]),
        timeZoneOffset =  (Number(d[8]) * 60 + Number(d[9])) * (d[7] === '-' ? -1 : 1);

    date.setHours(d[4]);
    date.setMinutes(d[5]);
    date.setSeconds(d[6]);

    self = new Date(date.getTime() +  (timeZoneOffset - date.getTimezoneOffset()) * 60 * 1000);
    return self;
}

- (CPTimeInterval)timeIntervalSinceDate:(CPDate)anotherDate
{
    return (self.getTime() - anotherDate.getTime()) / 1000.0;
}

- (CPTimeInterval)timeIntervalSinceNow
{
    return [self timeIntervalSinceDate:[CPDate date]];
}

- (CPTimeInterval)timeIntervalSince1970
{
    return self.getTime() / 1000.0;
}

- (CPTimeInterval)timeIntervalSinceReferenceDate
{
    return (self.getTime() - CPDateReferenceDate.getTime()) / 1000.0;
}

+ (CPTimeInterval)timeIntervalSinceReferenceDate
{
    return [[CPDate date] timeIntervalSinceReferenceDate];
}

- (BOOL)isEqual:(CPDate)aDate
{
    return [self isEqualToDate:aDate];
}

- (BOOL)isEqualToDate:(CPDate)anotherDate
{
    return !(self < anotherDate || self > anotherDate);
}

- (CPComparisonResult)compare:(CPDate)anotherDate
{
    return (self > anotherDate) ?  CPOrderedDescending : ((self < anotherDate) ? CPOrderedAscending : CPOrderedSame);
}

- (CPDate)earlierDate:(CPDate)anotherDate
{
    return (self < anotherDate) ? self : anotherDate;
}

- (CPDate)laterDate:(CPDate)anotherDate
{
    return (self > anotherDate) ? self : anotherDate;
}

/*!
    Returns the date as a string in the international format
    YYYY-MM-DD HH:MM:SS ±HHMM.
*/
- (CPString)description
{
    var hours = Math.floor(self.getTimezoneOffset() / 60),
        minutes = self.getTimezoneOffset() - hours * 60;

    return [CPString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d +%02d%02d", self.getFullYear(), self.getMonth()+1, self.getDate(), self.getHours(), self.getMinutes(), self.getSeconds(), hours, minutes];
}

- (id)copy
{
    return new Date(self.getTime());
}

@end

var CPDateTimeKey = @"CPDateTimeKey";

@implementation CPDate (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        self.setTime([aCoder decodeIntForKey:CPDateTimeKey]);
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:self.getTime() forKey:CPDateTimeKey];
}

@end

Date.prototype.isa = CPDate;
