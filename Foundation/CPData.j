/*
 * CPData.j
 * Foundation
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

@import "CPObject.j"
@import "CPString.j"

/*! 
    @class CPData
    @ingroup foundation
    @brief A Cappuccino wrapper for any data type.


*/

@implementation CPData : CPObject
{
    id  _plistObject;
}

+ (id)alloc
{
    return new objj_data();
}

+ (CPData)data
{
    return [[self alloc] initWithPlistObject:nil];
}

+ (CPData)dataWithString:(CPString)aString
{
    return [[self alloc] initWithString:aString];
}

+ (CPData)dataWithPlistObject:(id)aPlistObject
{
    return [[self alloc] initWithPlistObject:aPlistObject];
}

- (id)initWithString:(CPString)aString
{
    self = [super init];

    if (self)
        string = aString;
  
    return self;
}

- (id)initWithPlistObject:(id)aPlistObject
{
    self = [super init];
    
    if (self)
        _plistObject = aPlistObject;
        
    return self;
}

- (int)length
{
    return [[self string] length];
}

- (CPString)description
{
    return string;
}

- (CPString)string
{
    if (!string && _plistObject)
        string = [[CPPropertyListSerialization dataFromPropertyList:_plistObject format:CPPropertyList280NorthFormat_v1_0 errorDescription:NULL] string];

    return string;
}

- (void)setString:(CPString)aString
{
    string = aString;
    _plistObject = nil;
}

- (id)plistObject
{
    if (string && !_plistObject)
        // Attempt to autodetect the format.
        _plistObject = [CPPropertyListSerialization propertyListFromData:self format:0 errorDescription:NULL];
    
    return _plistObject;
}

- (void)setPlistObject:(id)aPlistObject
{
    string = nil;
    _plistObject = aPlistObject;
}

@end

objj_data.prototype.isa = CPData;
