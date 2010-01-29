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
}

+ (id)alloc
{
    return new MutableData();
}

+ (CPData)data
{
    return [[self alloc] init];
}

+ (CPData)dataWithEncodedString:(CPString)aString
{
    return [[self alloc] initWithEncodedString:aString];
}

+ (CPData)dataWithSerializedPlistObject:(id)aPlistObject
{
    return [[self alloc] initWithSerializedPlistObject:aPlistObject];
}

+ (CPData)dataWithSerializedPlistObject:(id)aPlistObject format:(CPPropertyListFormat)aFormat
{
    return [[self alloc] initWithSerializedPlistObject:aPlistObject format:aFormat];
}

- (id)initWithEncodedString:(CPString)aString
{
    self = [super init];

    if (self)
        [self setEncodedString:aString];

    return self;
}

- (id)initWithSerializedPlistObject:(id)aPlistObject
{
    self = [super init];

    if (self)
        [self setSerializedPlistObject:aPlistObject];

    return self;
}

- (id)initWithSerializedPlistObject:(id)aPlistObject format:aFormat
{
    self = [super init];

    if (self)
        [self setSerializedPlistObject:aPlistObject format:aFormat];

    return self;
}

- (int)length
{
    return [[self encodedString] length];
}

- (CPString)description
{
    return self.toString();
}

- (CPString)encodedString
{
    return self.encodedString();
}

- (void)setEncodedString:(CPString)aString
{
    self.setEncodedString(aString);
}

- (id)serializedPlistObject
{
    return self.serializedPropertyList();
}

- (void)setSerializedPlistObject:(id)aPlistObject
{
    self.setSerializedPropertyList(aPlistObject);
}

- (void)setSerializedPlistObject:(id)aPlistObject format:(CPPropertyListFormat)aFormat
{
    self.setSerializedPropertyList(aPlistObject, aFormat);
}

@end

Data.prototype.isa = CPData;
MutableData.prototype.isa = CPData;
