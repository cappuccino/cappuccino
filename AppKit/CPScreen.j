/*
 * CPScreen.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

/*!
    @ingroup appkit
    @class CPScreen

    A CPScreen object describes the attributes of a display device available
    to Cappuccino.
*/
@implementation CPScreen : CPObject
{
}

/*!
    Returns the position and size of the visible area of the receiving screen.
    This will normally be smaller than the full size of the screen to account
    for system UI elements. For example, on a Mac the top of the visible frame
    is placed below the bottom of the menu bar.

    @return the visible screen rectangle
*/
- (CGRect)visibleFrame
{
#if PLATFORM(DOM)
    return CGRectMake(window.screen.availLeft, window.screen.availTop, window.screen.availWidth, window.screen.availHeight);
#else
    return CGRectMakeZero();
#endif
}

@end
