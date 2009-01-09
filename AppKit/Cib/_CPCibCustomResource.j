/*
 * _CPCibCustomResource.j
 * AppKit
 *
 * Portions based on NSCustomResource.m (01/08/2009) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


var _CPCibCustomResourceClassNameKey    = @"_CPCibCustomResourceClassNameKey",
    _CPCibCustomResourceResourceNameKey = @"_CPCibCustomResourceResourceNameKey";

@implementation _CPCibCustomResource : CPObject
{
    CPString    _className;
    CPString    _resourceName;
}

- (CPString)filename
{
    return "";
}

- (CGSize)size
{
    return CGSizeMakeZero();
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _className = [aCoder decodeObjectForKey:_CPCibCustomResourceClassNameKey];
        _resourceName = [aCoder decodeObjectForKey:_CPCibCustomResourceResourceNameKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_className forKey:_CPCibCustomResourceClassNameKey];
    [aCoder encodeObject:_resourceName forKey:_CPCibCustomResourceResourceNameKey];
}

- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    if ([aCoder isKindOfClass:[_CPCibKeyedUnarchiver class]])
        if (_className === @"CPImage")
            return [[CPImage alloc] initWithContentsOfFile:[[aCoder bundle] pathForResource:_resourceName]];
    
    return self;
}

@end
