/*
 * NSTabView.j
 * nib2cib
 *
 * Created by Thomas Robinson.
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

@import <AppKit/CPTabView.j>

@import "NSTabViewItem.j"


@implementation CPTabView (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        var flags = [aCoder decodeObjectForKey:@"NSTvFlags"];

        type = flags & 0x7;

        items           = [aCoder decodeObjectForKey:@"NSTabViewItems"];
        selectedIndex   = [items indexOfObject:[aCoder decodeObjectForKey:@"NSSelectedTabViewItem"]];

        //_delegate               = [aCoder decodeObjectForKey:@""];

        // not yet supported:
        //_allowsTruncatedLabels    = [aCoder decodeBoolForKey:@"NSAllowTruncatedLabels"];
        //_drawsBackground          = [aCoder decodeBoolForKey:@"NSDrawsBackground"];
    }

    return self;
}

@end

@implementation NSTabView : CPTabView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTabView class];
}

@end
