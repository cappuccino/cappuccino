/*
 * CPSplitView+ResizeNotifications.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
 *
 * Adapted by Didier Korthoudt
 * Copyright 2019, Cappuccino Project.
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

@import "CPSplitViewCore.j"

var ShouldSuppressResizeNotifications   = 1,
    DidPostWillResizeNotification       = 1 << 1,
    DidSuppressResizeNotification       = 1 << 2;

@implementation CPSplitView (ResizeNotifications)

- (void)_postNotificationWillResize
{
    [self _sendDelegateSplitViewWillResizeSubviews];
}

- (void)_postNotificationDidResize
{
    [self _sendDelegateSplitViewDidResizeSubviews];

    // TODO Cocoa always autosaves on "viewDidEndLiveResize". If Cappuccino adds support for this we
    // should do the same.
    [self _autosave];
}

- (void)_maybePostWillResizeNotification
{
    if ((_suppressResizeNotificationsMask & DidPostWillResizeNotification) === 0)
    {
        [self _postNotificationWillResize];
        _suppressResizeNotificationsMask |= DidPostWillResizeNotification;
    }
}

- (void)_maybePostDidResizeNotification
{
    if ((_suppressResizeNotificationsMask & ShouldSuppressResizeNotifications) !== 0)
        _suppressResizeNotificationsMask |= DidSuppressResizeNotification;
    else
        [self _postNotificationDidResize];
}

- (BOOL)_didSuppressResizeNotifications
{
    return ((_suppressResizeNotificationsMask & DidSuppressResizeNotification) !== 0);
}

- (void)_setResizeNotificationsSuppressed:(BOOL)shouldSuppress
{
    if (shouldSuppress)
        _suppressResizeNotificationsMask |= ShouldSuppressResizeNotifications;
    else
        _suppressResizeNotificationsMask = 0;
}

@end
