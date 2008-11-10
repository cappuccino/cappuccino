/*
 * NSNibConnector.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
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

@import <AppKit/_CPCibConnector.j>


@implementation _CPCibConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _source = [aCoder decodeObjectForKey:@"NSSource"];
        _destination = [aCoder decodeObjectForKey:@"NSDestination"];
        _label = [aCoder decodeObjectForKey:@"NSLabel"];
        
        CPLog.debug(@"Connection: " + [_source description] + " " + [_destination description] + " " + _label);
    }
    
    return self;
}

@end

@implementation NSNibConnector : _CPCibConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibConnector class];
}

@end

@implementation NSNibControlConnector : _CPCibControlConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibControlConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibControlConnector class];
}

@end

@implementation NSNibOutletConnector : _CPCibOutletConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibOutletConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibOutletConnector class];
}

@end
