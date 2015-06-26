/*
 * CPUserNotification.j
 * Foundation
 *
 * Created by Alexandre Wilhelm.
 * Copyright 2015, 280 North, Inc.
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

@import "CPAttributedString.j"
@import "CPArray.j"
@import "CPDate.j"
@import "CPDictionary.j"
@import "CPObject.j"
@import "CPTimeZone.j"

// We need something from the AppKit in Foundation ???
@class CPImage

@typedef CPUserNotificationAction
@typedef CPUserNotificationActivationType

/*!
    @global CPUserNotificationActivationType
    @group CPUserNotificationActivationType
    The user did not interact with the notification alert.
*/
CPUserNotificationActivationTypeNone = 0;

/*!
    @global CPUserNotificationActivationType
    @group CPUserNotificationActivationType
    The user clicked on the contents of the notification alert.
*/
CPUserNotificationActivationTypeContentsClicked = 1;

/*!
    @global CPUserNotificationActivationType
    @group CPUserNotificationActivationType
    The user clicked on the action button of the notification alert.
*/
CPUserNotificationActivationTypeActionButtonClicked = 2;

/*!
    @global CPUserNotificationActivationType
    @group CPUserNotificationActivationType
    The user replied to the notification.
*/
CPUserNotificationActivationTypeReplied = 3,

/*!
    @global CPUserNotificationActivationType
    @group CPUserNotificationActivationType
    The user clicked on the additional action button of the notification alert.
*/
CPUserNotificationActivationTypeAdditionalActionClicked = 4;

/*!
    @class CPUserNotification
    @ingroup foundation

    @brief The CPUserNotification class is used to configure a notification that is scheduled for display by the UserNotificationCenter class.
*/
@implementation CPUserNotification : CPObject
{
    BOOL                                _presented                  @accessors(getter=isPresented);
    BOOL                                _remote                     @accessors(getter=isRemote);
    CPDate                              _actualDeliveryDate         @accessors(getter=actualDeliveryDate);
    CPDate                              _deliveryDate               @accessors(property=deliveryDate);
    CPDictionary                        _userInfo                   @accessors(property=userInfo);
    CPImage                             _contentImage               @accessors(property=contentImage);
    CPString                            _identifier                 @accessors(property=identifier);
    CPString                            _informativeText            @accessors(property=informativeText);
    CPString                            _title                      @accessors(property=title);
    CPTimeInterval                      _deliveryRepeatInterval     @accessors(property=deliveryRepeatInterval);
    CPTimeZone                          _deliveryTimeZone           @accessors(property=deliveryTimeZone);
    CPUserNotificationActivationType    _activationType             @accessors(getter=activationType);
}


#pragma mark -
#pragma mark Creating an user notification

- (id)init
{
    self = [super init];

    if (self)
    {
        _identifier = [self UID];
    }

    return self
}

@end