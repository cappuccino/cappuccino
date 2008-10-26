/*
 * CPPropertyListSerialization.j
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


CPPropertyListOpenStepFormat        = kCFPropertyListOpenStepFormat;
CPPropertyListXMLFormat_v1_0        = kCFPropertyListXMLFormat_v1_0;
CPPropertyListBinaryFormat_v1_0     = kCFPropertyListBinaryFormat_v1_0;
CPPropertyList280NorthFormat_v1_0   = kCFPropertyList280NorthFormat_v1_0;

@implementation CPPropertyListSerialization : CPObject
{
}

+ (CPData)dataFromPropertyList:(id)aPlist format:(CPPropertyListFormat)aFormat errorDescription:({CPString})anErrorString
{
    return CPPropertyListCreateData(aPlist, aFormat);
}

+ (id)propertyListFromData:(CPData)data format:(CSPropertyListFormat)aFormat errorDescription:({CPString})errorString
{
    return CPPropertyListCreateFromData(data, aFormat);
}

@end
