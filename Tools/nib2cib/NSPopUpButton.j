/*
 * NSPopUpButton.j
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

@import <AppKit/CPPopUpButton.j>

@import "NSMenu.j"


@implementation CPPopUpButton (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];

        _menu = [cell menu];

         // make sure it's not null/undefined
        //FIXME push this check to CPPopUpButton?
        _selectedIndex  = [cell selectedIndex] || 0;

        [self setPullsDown:[cell pullsDown]];
        _preferredEdge  = [cell preferredEdge];
    }

    return self;
}

@end

@implementation NSPopUpButton : CPPopUpButton
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPPopUpButton class];
}

@end


@implementation NSPopUpButtonCell : NSMenuItemCell
{
    BOOL    pullsDown      @accessors(readonly);
    int     selectedIndex  @accessors(readonly);
    int     preferredEdge  @accessors(readonly);
    CPMenu  menu           @accessors(readonly);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        pullsDown      = [aCoder decodeBoolForKey:@"NSPullDown"];
        selectedIndex  = [aCoder decodeIntForKey:@"NSSelectedIndex"];
        preferredEdge  = [aCoder decodeIntForKey:@"NSPreferredEdge"];
        menu           = [aCoder decodeObjectForKey:@"NSMenu"];
    }

    return self;
}

@end