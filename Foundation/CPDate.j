/*
 * CPObject.j
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

- (id)initWithString:(CPString)description
{
    self = new Date(description); // FIXME: not same format as NSString
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

- (CPString)description
{
    return self.toString(); // FIXME: not same format as NSDate
}

@end

Date.prototype.isa = CPDate;
