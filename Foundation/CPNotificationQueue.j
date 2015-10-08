/*
 * CPNotificationQueue.j
 * Foundation
 *
 * Created by Alexandre Wilhelm.
 * Copyright 2015 <alexandre.wilhelmfr@gmail.com>
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
@import "CPNotification.j"
@import "CPNotificationCenter.j"

@typedef CPPostingStyle

/*
    @global
    @group CPViewAutoresizingMasks
    The default resizingMask, the view will not resize or reposition itself.
*/
CPPostWhenIdle = 1;
/*
    @global
    @group CPPostingStyle
    The notification is posted at the end of the current notification callout or timer.
*/
CPPostASAP = 2;
/*
    @global
    @group CPPostingStyle
    The notification is posted immediately after coalescing.
*/
CPPostNow = 3;


@typedef CPNotificationCoalescing

/*
    @global
    @group CPNotificationCoalescing
    Do not coalesce notifications in the queue.
*/
CPNotificationNoCoalescing = 1 << 0;
/*
    @global
    @group CPNotificationCoalescing
    Coalesce notifications with the same name.
*/
CPNotificationCoalescingOnName = 1 << 1;
/*
    @global
    @group CPNotificationCoalescing
    Coalesce notifications with the same object.
*/
CPNotificationCoalescingOnSender = 1 << 2;


var CPNotificationDefaultQueue;

var runLoop = [CPRunLoop mainRunLoop];

/*!
    @class CPPostingStyle
    @ingroup foundation
    @brief CPNotificationQueue objects act as buffers for notification centers (instances of CPNotificationCenter).

    Cappuccino provides a framework for sending messages between objects within
    a process called notifications. CPNotificationQueue objects (or simply notification queues)
    act as buffers for notification centers (instances of CPNotificationCenter).
    Whereas a notification center distributes notifications when posted,
    notifications placed into the queue can be delayed until the end of the current pass through the run loop
    or until the run loop is idle. Duplicate notifications can also be coalesced so that only one notification
    is sent although multiple notifications are posted. A notification queue maintains notifications
    (instances of C¨Notification) generally in a first in first out (FIFO) order.
    When a notification rises to the front of the queue, the queue posts it to the notification center,
    which in turn dispatches the notification to all objects registered as observers.
*/
@implementation CPNotificationQueue : CPObject
{
    BOOL                 _runLoopLaunched;
    CPMutableArray       _postNowNotifications;
    CPMutableArray       _postIdleNotifications;
    CPMutableArray       _postASAPNotifications;
    CPNotificationCenter _notificationCenter;
}


#pragma mark -
#pragma mark Class methods

/*!
    Returns the application's notification queue. This notification queue uses the default notification center
*/
+ (id)defaultQueue
{
    if (!CPNotificationDefaultQueue)
        CPNotificationDefaultQueue = [[CPNotificationQueue alloc] initWithNotificationCenter:[CPNotificationCenter defaultCenter]];

    return CPNotificationDefaultQueue;
}


#pragma mark -
#pragma mark Init methods

/*!
    Initializes and returns a notification queue for the specified notification center.
    @param anObserver the specified notification center
    @return a new CPNotificationQueue
*/
- (id)initWithNotificationCenter:(CPNotificationCenter)aNotificationCenter
{
    if (self = [super init])
    {
        _notificationCenter     = aNotificationCenter;
        _postNowNotifications   = [CPMutableArray new];
        _postIdleNotifications  = [CPMutableArray new];
        _postASAPNotifications  = [CPMutableArray new];
    }

    return self;
}


#pragma mark -
#pragma mark Enqueue methods

/*!
    Adds a notification to the notification queue with a specified posting style.
    @param notification the notification to add to the queue
    @param postingStyle the posting style for the notification
*/
- (void)enqueueNotification:(CPNotification)notification postingStyle:(CPPostingStyle)postingStyle
{
    [self enqueueNotification:notification postingStyle:postingStyle coalesceMask:CPNotificationCoalescingOnName|CPNotificationCoalescingOnSender forModes:[CPDefaultRunLoopMode]];
}

/*!
    Adds a notification to the notification queue with a specified posting style, criteria for coalescing, and runloop mode.
    @param notification the notification to add to the queue
    @param postingStyle the posting style for the notification
    @param coalesceMask a mask indicating what criteria to use when matching attributes of notification to attributes notifications in the queue.
    @modes modes the list of modes the notification may be posted in.
*/
- (void)enqueueNotification:(CPNotification)notification postingStyle:(CPPostingStyle)postingStyle coalesceMask:(CPNotificationCoalescing)coalesceMask forModes:(CPArray)modes
{
    [self _removeNotification:notification coalesceMask:coalesceMask];

    switch (postingStyle)
    {
        case CPPostWhenIdle:
            [_postIdleNotifications addObject:notification];
            break;

        case CPPostASAP:
            [_postASAPNotifications addObject:notification];
            break;

        case CPPostNow:
            [_postNowNotifications addObject:notification];
            break;
    }

    if ([_postIdleNotifications count] || [_postASAPNotifications count] || [_postNowNotifications count])
        [self _runRunLoop];

    if (postingStyle == CPPostNow)
    {
        for (var i = [modes count] - 1; i >= 0; i--)
            [[CPRunLoop currentRunLoop] limitDateForMode:modes[i]];
    }
}


#pragma mark -
#pragma mark Dequeue methods

/*!
    Removes all notifications from the queue that match a provided notification using provided matching criteria.
    @param notification the notification to add to the queue
    @param coalesceMask mask indicating what criteria to use when matching attributes of notification to remove notifications in the queue.
*/
- (void)dequeueNotificationsMatching:(CPNotification)notification coalesceMask:(CPUInteger)coalesceMask
{
    [self _removeNotification:notification coalesceMask:coalesceMask];
}


#pragma mark -
#pragma mark RunLoop methods

/*!
    @ignore
*/
- (void)_runRunLoop
{
    if (!_runLoopLaunched)
    {
        [runLoop performSelector:@selector(_launchNotificationsInQueue) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
        _runLoopLaunched = YES;
    }
}

/*!
    @ignore
*/
- (void)_launchNotificationsInQueue
{
    _runLoopLaunched = NO;

    if ([_postNowNotifications count])
    {
        [self _launchNotificationsForArray:_postNowNotifications];
        [self _runRunLoop];
        return;
    }

    if ([_postASAPNotifications count])
    {
        [self _launchNotificationsForArray:_postASAPNotifications];
        [self _runRunLoop];
        return;
    }

    if ([_postIdleNotifications count])
    {
        [self _launchNotificationsForArray:_postIdleNotifications];
        [self _runRunLoop];
        return;
    }
}


#pragma mark -
#pragma mark Posting methods

/*!
    @ignore
*/
- (void)_launchNotificationsForArray:(CPArray)anArray
{
    for (var i = [anArray count] - 1; i >= 0; i--)
    {
        var notification = anArray[i];
        [_notificationCenter postNotification:notification];
    }

    [anArray removeAllObjects];
}


#pragma mark -
#pragma mark Remove methods

/*!
    @ignore
*/
- (void)_removeNotification:(CPNotification)notification coalesceMask:(CPUInteger)coalesceMask
{
    [self _removeNotification:notification coalesceMask:coalesceMask inNotifications:_postNowNotifications];
    [self _removeNotification:notification coalesceMask:coalesceMask inNotifications:_postASAPNotifications];
    [self _removeNotification:notification coalesceMask:coalesceMask inNotifications:_postIdleNotifications];
}

/*!
    @ignore
*/
- (void)_removeNotification:(CPNotification)aNotification coalesceMask:(CPUInteger)coalesceMask inNotifications:(CPArray)notifications
{
    var notificationsToRemove = [],
        name = [aNotification name],
        sender = [aNotification object];

    for (var i = [notifications count] - 1; i >= 0; i--)
    {
        var notification = notifications[i];

        if (notification == aNotification)
        {
            [notificationsToRemove addObject:notification];
            continue;
        }

        if (coalesceMask & CPNotificationNoCoalescing)
            continue;

        if (coalesceMask & CPNotificationCoalescingOnName && coalesceMask & CPNotificationCoalescingOnSender)
        {
            if ([notification object] == sender && [notification name] == name)
                [notificationsToRemove addObject:notification]

            continue;
        }

        if (coalesceMask & CPNotificationCoalescingOnName)
        {
            if ([notification name] == name)
                [notificationsToRemove addObject:notification]

            continue;
        }

        if (coalesceMask & CPNotificationCoalescingOnSender)
        {
            if ([notification object] == sender)
                [notificationsToRemove addObject:notification]

            continue;
        }
    }

    [notifications removeObjectsInArray:notificationsToRemove];
}

@end