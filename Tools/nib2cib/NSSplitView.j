/*
 * NSSplitView.j
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

@import <AppKit/CPSplitView.j>

var NSThinDividerStyle = 2;

@implementation CPSplitView (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        self._isVertical = [aCoder decodeBoolForKey:@"NSIsVertical"];

        // The possible values appear to be: no value (thick divider), 2 (thin divider) and 3 (pane splitter). For
        // Cappuccino's purposes we treat thick divider and pane splitter as the same thing since the only difference
        // seems to be graphical.
        self._isPaneSplitter = [aCoder decodeIntForKey:@"NSDividerStyle"] != NSThinDividerStyle;

        self._autosaveName = [aCoder decodeObjectForKey:@"NSAutosaveName"];
    }

    return self;
}

@end

@implementation NSSplitView : CPSplitView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSplitView class];
}

@end
