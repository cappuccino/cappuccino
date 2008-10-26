/*
 * CPUserSessionManager.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


CPUserSessionUndeterminedStatus = 0;
CPUserSessionLoggedInStatus     = 1;
CPUserSessionLoggedOutStatus    = 2;

CPUserSessionManagerStatusDidChangeNotification         = @"CPUserSessionManagerStatusDidChangeNotification";
CPUserSessionManagerUserIdentifierDidChangeNotification = @"CPUserSessionManagerUserIdentifierDidChangeNotification";

var CPDefaultUserSessionManager = nil;

@implementation CPUserSessionManager : CPObject
{
    CPUserSessionStatus _status;
    
    CPString            _userIdentifier;
}

+ (id)defaultManager
{
    if (!CPDefaultUserSessionManager)
        CPDefaultUserSessionManager = [[CPUserSessionManager alloc] init];

    return CPDefaultUserSessionManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
        _status = CPUserSessionUndeterminedStatus;
    
    return self;
}

- (CPUserSessionStatus)status
{
    return _status;
}

- (void)setStatus:(CPUserSessionStatus)aStatus
{
    if (_status == aStatus)
        return;
    
    _status = aStatus;
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPUserSessionManagerStatusDidChangeNotification
                      object:self];

    if (_status != CPUserSessionLoggedInStatus)
        [self setUserIdentifier:nil];
}

- (CPString)userIdentifier
{
    return _userIdentifier;
}

- (void)setUserIdentifier:(CPString)anIdentifier
{
    if (_userIdentifier == anIdentifier)
        return;
    
    _userIdentifier = anIdentifier;
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPUserSessionManagerUserIdentifierDidChangeNotification
                      object:self];
}

@end
