/*
 * NSToolbarItem.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

@import <AppKit/CPToolbarItem.j>


@implementation CPToolbarItem (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _itemIdentifier = [aCoder decodeObjectForKey:@"NSToolbarItemIdentifier"];

        [self setLabel:[aCoder decodeObjectForKey:@"NSToolbarItemLabel"]];
        [self setPaletteLabel:[aCoder decodeObjectForKey:@"NSToolbarItemPaletteLabel"]];
        [self setToolTip:[aCoder decodeObjectForKey:@"NSToolbarItemToolTip"]];

        [self setTag:[aCoder decodeObjectForKey:@"NSToolbarItemTag"]];
        [self setTarget:[aCoder decodeObjectForKey:@"NSToolbarItemTarget"]];
        [self setAction:CPSelectorFromString([aCoder decodeObjectForKey:@"NSToolbarItemAction"])];

        [self setEnabled:[aCoder decodeBoolForKey:@"NSToolbarItemEnabled"]];

        [self setImage:[aCoder decodeBoolForKey:@"NSToolbarItemImage"]];

        [self setView:[aCoder decodeObjectForKey:@"NSToolbarItemView"]];

        _minSize = [aCoder decodeSizeForKey:@"NSToolbarItemMinSize"];
        _maxSize = [aCoder decodeSizeForKey:@"NSToolbarItemMaxSize"];

        [self setVisibilityPriority:[aCoder decodeIntForKey:@"NSToolbarItemVisibilityPriority"]];
    }

    return self;
}

@end

@implementation NSToolbarItem : CPToolbarItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPToolbarItem class];
}

@end

@implementation NSToolbarSpaceItem : NSToolbarItem
@end

@implementation NSToolbarFlexibleSpaceItem : NSToolbarItem
@end

@implementation NSToolbarSeparatorItem : NSToolbarItem
@end
