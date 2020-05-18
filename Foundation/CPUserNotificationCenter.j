/*
 * CPUserNotificationCenter.j
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

@import "CPArray.j"
@import "CPObject.j"
@import "CPTimer.j"
@import "CPUserNotification.j"

@protocol CPUserNotificationCenterDelegate <CPObject>

@optional
- (BOOL)userNotificationCenter:(CPUserNotificationCenter)center shouldPresentNotification:(CPUserNotification)notification;
- (void)userNotificationCenter:(CPUserNotificationCenter)center didDeliverNotification:(CPUserNotification)notification;
- (void)userNotificationCenter:(CPUserNotificationCenter)center didActivateNotification:(CPUserNotification)notification;

@end

// Remove compiling warnings
@class Notification

@global CPApp

var CPUserNotificationCenterDelegate_userNotificationCenter_shouldPresentNotification_  = 1 << 0,
    CPUserNotificationCenterDelegate_userNotificationCenter_didDeliverNotification_     = 1 << 1,
    CPUserNotificationCenterDelegate_userNotificationCenter_didActivateNotification_    = 1 << 2;

var CPUserNotificationDefaultCenter = nil;

/*!
    @class CPUserNotificationCenter
    @ingroup foundation

    @brief The CPUserNotificationCenter class delivers user notifications to the user from applications or helper applications.
*/
@implementation CPUserNotificationCenter : CPObject
{
    CPArray                                 _deliveredNotifications @accessors(property=deliveredNotifications);
    CPArray                                 _scheduledNotifications @accessors(property=scheduledNotifications);
    id <CPUserNotificationCenterDelegate>   _delegate;

    CPInteger                               _implementedDelegateMethods;
    CPMutableDictionary                     _timersForUserNotification;
}


#pragma mark -
#pragma mark Creating Default User Notification Center

/*!
    Returns the user's notification center
*/
+ (CPNotificationCenter)defaultUserNotificationCenter
{
    if (!CPUserNotificationDefaultCenter)
        CPUserNotificationDefaultCenter = [[CPUserNotificationCenter alloc] init];

    return CPUserNotificationDefaultCenter;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _deliveredNotifications = [];
        _scheduledNotifications = [];
        _timersForUserNotification = @{};
    }

    return self;
}


#pragma mark -
#pragma mark Getting and Setting the Delegate

- (void)setDelegate:(id <CPUserNotificationCenterDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(userNotificationCenter:shouldPresentNotification:)])
        _implementedDelegateMethods |= CPUserNotificationCenterDelegate_userNotificationCenter_shouldPresentNotification_;

    if ([_delegate respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)])
        _implementedDelegateMethods |= CPUserNotificationCenterDelegate_userNotificationCenter_didDeliverNotification_;

    if ([_delegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)])
        _implementedDelegateMethods |= CPUserNotificationCenterDelegate_userNotificationCenter_didActivateNotification_;
}


#pragma mark -
#pragma mark Managing the Scheduled Notification Queue

/*!
    Schedules the given user notification
    @param anUserNotification the user notification
*/
- (void)scheduleNotification:(CPUserNotification)anUserNotification
{
    var scheduledDate = [[anUserNotification deliveryDate] copy];
    [scheduledDate _dateWithTimeZone:[anUserNotification deliveryTimeZone]];

    var timer = [[CPTimer alloc] initWithFireDate:scheduledDate
                                         interval:[anUserNotification deliveryRepeatInterval]
                                           target:self
                                         selector:@selector(_scheduledUserNotificationTimerDidFire:)
                                         userInfo:anUserNotification
                                          repeats:([anUserNotification deliveryRepeatInterval] ? YES : NO)];

    [_scheduledNotifications addObject:anUserNotification];
    _timersForUserNotification[[anUserNotification UID]] = timer;

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];
}

- (void)_scheduledUserNotificationTimerDidFire:(CPTimer)aTimer
{
    [self deliverNotification:[aTimer userInfo]];
}

/*!
    Removes the given user notification for the scheduled notifications.
    @param anUserNotification the user notification
*/
- (void)removeScheduledNotification:(CPUserNotification)anUserNotification
{
    if ([_scheduledNotifications indexOfObject:anUserNotification] != CPNotFound)
    {
         [_scheduledNotifications removeObject:anUserNotification];
         [_timersForUserNotification[[anUserNotification UID]] invalidate];
         delete _timersForUserNotification[[anUserNotification UID]];
    }
}


#pragma mark -
#pragma mark Managing the Delivered Notifications

/*!
    Deliver the given user notification
    @param aNotification the user notification
*/
- (void)deliverNotification:(CPUserNotification)aNotification
{
    [self _launchUserNotification:aNotification];
}

/*!
    Remove a delivered user notification from the user notification center.
    @param aNotification the user notification
*/
- (void)removeDeliveredNotification:(CPUserNotification)aNotification
{
    [_deliveredNotifications removeObject:aNotification];
}

/*!
    Remove all delivered user notifications from the user notification center.
*/
- (void)removeAllDeliveredNotifications
{
    [_deliveredNotifications removeAllObjects];
}


#pragma mark -
#pragma mark Permission Utilities

- (void)_askPermissionForUserNotification:(CPUserNotification)anUserNotification
{
    Notification.requestPermission(function (permission) {
        if (permission == "granted")
            // We need to relaunch the notification if the permission are granted
            [self _launchUserNotification:anUserNotification];
    });
}


#pragma mark -
#pragma mark Notification Utilities

- (void)_launchUserNotification:(CPUserNotification)anUserNotification
{
    // If the browser version is unsupported, remain silent.
    if (!window || !'Notification' in window)
        return;

    if (Notification.permission === 'default')
        [self _askPermissionForUserNotification:anUserNotification];

    if (Notification.permission === 'granted')
    {
        if (([self _delegateRespondsToShouldPresentNotification] && [self _sendDelegateShouldPresentNotification:anUserNotification])
            || ![CPApp isActive])
        {
            var notification = new Notification(
                        [anUserNotification title],
                        {
                          'body': [anUserNotification informativeText],
                          'icon': [[anUserNotification contentImage] filename],
                          // ...prevent duplicate notifications
                          'tag' : [anUserNotification identifier]
                        }
                    );

            anUserNotification._presented = YES;

            notification.onclick = function () {
                anUserNotification._activationType = CPUserNotificationActivationTypeContentsClicked;
                [self _sendDelegateDidActivateNotification:anUserNotification];

                // Remove the notification from Notification Center when clicked.
                this.close();
            };

            // Callback function when the notification is closed.
            notification.onclose = function () {

            };
        }
        else
        {
            anUserNotification._presented = NO;
        }

        anUserNotification._activationType = CPUserNotificationActivationTypeNone;
        anUserNotification._actualDeliveryDate = [CPDate date];
        [_deliveredNotifications addObject:anUserNotification];

        if (![anUserNotification deliveryRepeatInterval])
            [self removeScheduledNotification:anUserNotification];

        [self _sendDelegateDidDeliverNotification:anUserNotification];
    }
}

@end


@implementation CPUserNotificationCenter (CPUserNotificationCenterDelegate)

- (BOOL)_delegateRespondsToShouldPresentNotification
{
    return _implementedDelegateMethods & CPUserNotificationCenterDelegate_userNotificationCenter_shouldPresentNotification_;
}

- (BOOL)_sendDelegateShouldPresentNotification:(CPUserNotification)aNotification
{
    return [_delegate userNotificationCenter:self shouldPresentNotification:aNotification];
}

- (void)_sendDelegateDidActivateNotification:(CPUserNotification)aNotification
{
    if (!(_implementedDelegateMethods & CPUserNotificationCenterDelegate_userNotificationCenter_didActivateNotification_))
        return;

    [_delegate userNotificationCenter:self didActivateNotification:aNotification];
}

- (void)_sendDelegateDidDeliverNotification:(CPUserNotification)aNotification
{
    if (!(_implementedDelegateMethods & CPUserNotificationCenterDelegate_userNotificationCenter_didDeliverNotification_))
        return;

    [_delegate userNotificationCenter:self didDeliverNotification:aNotification];
}

@end