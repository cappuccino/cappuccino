/*
 * CPSplitView.j
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

/*
    CPSplitView is divided by responsibility. CPSplitViewCore.j holds the class, its instance
    variables, initialization, properties and subview management; each other file holds
    categories and imports CPSplitViewCore.j. This file imports them all, so an import of
    CPSplitView.j brings the complete class.
*/

@import "CPSplitViewCore.j"
@import "CPSplitView+Layout.j"
@import "CPSplitView+Dividers.j"
@import "CPSplitView+ResizeNotifications.j"
@import "CPSplitView+Autosave.j"
@import "CPSplitView+Delegate.j"
@import "CPSplitView+Coding.j"
@import "CPSplitView+Animation.j"
