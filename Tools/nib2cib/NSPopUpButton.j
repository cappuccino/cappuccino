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
@import "NSMenuItem.j"


@implementation CPPopUpButton (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    _menu = [cell menu];
    [self setPullsDown:[cell pullsDown]];
    _preferredEdge  = [cell preferredEdge];

    // adjust the frame
    _frame.origin.x -= 4;
    _frame.origin.y -= 4;
    _frame.size.width += 7;
    _bounds.size.width += 7;
}

@end

@implementation NSPopUpButton : CPPopUpButton
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
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


// - [NSPopUpButton objectValue] is overridden to return the selected index.
- (CPUInteger)objectValue
{
    return selectedIndex;
}

@end
