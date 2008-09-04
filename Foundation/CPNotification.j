/*
 * CPNotification.j
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

import "CPObject.j"

@implementation CPNotification : CPObject
{
    CPString        _name;
    id              _object;
    CPDictionary    _userInfo;
}

+ (CPNotification)notificationWithName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
    return [[self alloc] initWithName:aNotificationName object:anObject userInfo:aUserInfo];
}

+ (CPNotification)notificationWithName:(CPString)aNotificationName object:(id)anObject
{
    return [[self alloc] initWithName:aNotificationName object:anObject userInfo:nil];
}

- (id)initWithName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
    self = [super init];
    
    if (self)
    {
        _name = aNotificationName;
        _object = anObject;
        _userInfo = aUserInfo;
    }
    
    return self;
}

- (CPString)name
{
    return _name;
}

- (id)object
{
    return _object;
}

- (CPDictionary)userInfo
{
    return _userInfo;
}

@end
