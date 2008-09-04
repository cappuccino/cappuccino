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

import "CPWindow.j"


CPOKButton      = 1;
CPCancelButton  = 0;

@implementation CPPanel : CPWindow
{
    BOOL    _becomesKeyOnlyIfNeeded;
    BOOL    _worksWhenModal;
}

- (BOOL)isFloatingPanel
{
    return [self level] == CPFloatingWindowLevel;
}

- (void)setFloatingPanel:(BOOL)isFloatingPanel
{
    [self setLevel:isFloatingPanel ? CPFloatingWindowLevel : CPNormalWindowLevel];
}

- (BOOL)becomesKeyOnlyIfNeeded
{
    return _becomesKeyOnlyIfNeeded;
}

- (void)setBecomesKeyOnlyIfNeeded:(BOOL)shouldBecomeKeyOnlyIfNeeded
{
    _becomesKeyOnlyIfNeeded = shouldBecomeKeyOnlyIfNeeded
}

- (BOOL)worksWhenModal
{
    return _worksWhenModal;
}

- (void)setWorksWhenModal:(BOOL)shouldWorkWhenModal
{
    _worksWhenModal = shouldWorkWhenModal;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

@end
