/*
 * CPPanel.j
 * AppKit
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

@import "CPWindow.j"


CPOKButton      = 1;
CPCancelButton  = 0;

/*!
    @ingroup appkit
    @class CPPanel

    The CPPanel class defines objects that manage the panels of the Cappuccino user interface. A panel is a window that serves an auxiliary function within an application. It generally displays controls that the user can act on to give instructions to the application or to modify the contents of a standard window.</p>

<p>Panels behave differently from standard windows in only a small number of ways, but the ways are important to the user interface:</p>

<ul>
    <li>Panels can assume key window status but not main window status. (The key window receives keyboard events. The main window is the primary focus of user actions; it might contain the document the user is working on, for example.)</li>
</ul>

<p>To aid in their auxiliary role, panels can be assigned special behaviors:</p>

<ul>
    <li>A panel can be precluded from becoming the key window until the user makes a selection (makes some view in the panel the first responder) indicating an intention to begin typing. This prevents key window status from shifting to the panel unnecessarily.</li>
    <li>Palettes and similar panels can be made to float above standard windows and other panels. This prevents them from being covered and keeps them readily available to the user.</li>
    <li>A panel can be made to work even when there's an attention panel on-screen. This permits actions within the panel to affect the attention panel.</li>
</ul>
*/

/*
    @global
    @class CPWindow
*/
CPDocModalWindowMask    = 1 << 6;

@implementation CPPanel : CPWindow
{
    BOOL    _becomesKeyOnlyIfNeeded;
    BOOL    _worksWhenModal;
}

/*!
    Returns \c YES if the receiver is a floating panel (like a palette).
*/
- (BOOL)isFloatingPanel
{
    return [self level] == CPFloatingWindowLevel;
}

/*!
    Sets the receiver to be a floating panel. \c YES
    makes the window a floating panel. \c NO makes it a normal window.
    @param isFloatingPanel specifies whether to make it floating
*/
- (void)setFloatingPanel:(BOOL)isFloatingPanel
{
    [self setLevel:isFloatingPanel ? CPFloatingWindowLevel : CPNormalWindowLevel];
}

/*!
    Returns \c YES if the window only becomes key
    if needed. \c NO means it behaves just like other windows.
*/
- (BOOL)becomesKeyOnlyIfNeeded
{
    return _becomesKeyOnlyIfNeeded;
}

/*!
    Sets whether the the window becomes key only if needed.
    @param shouldBecomeKeyOnlyIfNeeded \c YES makes the window become key only if needed
*/
- (void)setBecomesKeyOnlyIfNeeded:(BOOL)shouldBecomeKeyOnlyIfNeeded
{
    _becomesKeyOnlyIfNeeded = shouldBecomeKeyOnlyIfNeeded
}

- (BOOL)worksWhenModal
{
    return _worksWhenModal;
}

/*!
    Sets whether this window can receive input while another window is running modally.
    @param shouldWorkWhenModal whether to receive input while another window is modal
*/
- (void)setWorksWhenModal:(BOOL)shouldWorkWhenModal
{
    _worksWhenModal = shouldWorkWhenModal;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end
