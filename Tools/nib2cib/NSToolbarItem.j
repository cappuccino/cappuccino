/*
 * NSToolbarItem.j
 * nib2cib
 *
 * Created by Francisco Tolmasky and Dimitris Tsitses.
 * Copyright 2010, 280 North, Inc.
 * Copyright 2010, Blueberry Associates LLC.
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

@class CPSearchField


NS_CPToolbarItemIdentifierMap =
{
    @"NSToolbarSeparatorItem"           : CPToolbarSeparatorItemIdentifier,
    @"NSToolbarSpaceItem"               : CPToolbarSpaceItemIdentifier,
    @"NSToolbarFlexibleSpaceItem"       : CPToolbarFlexibleSpaceItemIdentifier,
    @"NSToolbarShowColorsItem"          : CPToolbarShowColorsItemIdentifier,
    @"NSToolbarShowFontsItem"           : CPToolbarShowFontsItemIdentifier,
    @"NSToolbarCustomizeToolbarItem"    : CPToolbarCustomizeToolbarItemIdentifier,
    @"NSToolbarPrintItem"               : CPToolbarPrintItemIdentifier
};

@implementation CPToolbarItem (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        var NS_itemIdentifier = [aCoder decodeObjectForKey:@"NSToolbarItemIdentifier"];

        _itemIdentifier = NS_CPToolbarItemIdentifierMap[NS_itemIdentifier] || NS_itemIdentifier;

        _minSize = [aCoder decodeSizeForKey:@"NSToolbarItemMinSize"];
        _maxSize = [aCoder decodeSizeForKey:@"NSToolbarItemMaxSize"];

        [self setLabel:[aCoder decodeObjectForKey:@"NSToolbarItemLabel"]];
        [self setPaletteLabel:[aCoder decodeObjectForKey:@"NSToolbarItemPaletteLabel"]];
        [self setToolTip:[aCoder decodeObjectForKey:@"NSToolbarItemToolTip"]];

        [self setTag:[aCoder decodeObjectForKey:@"NSToolbarItemTag"]];
        [self setTarget:[aCoder decodeObjectForKey:@"NSToolbarItemTarget"]];
        [self setAction:CPSelectorFromString([aCoder decodeObjectForKey:@"NSToolbarItemAction"])];
        [self setEnabled:[aCoder decodeBoolForKey:@"NSToolbarItemEnabled"]];

        [self setImage:[aCoder decodeObjectForKey:@"NSToolbarItemImage"]];

        //FIXME: we shouldn't let toolbars have images which are too big at all
        if (_maxSize.height > 0)
            _maxSize.height = MIN(_maxSize.height, 32.0);
        if (_minSize.height > 0)
            _minSize.height = MIN(_minSize.height, 32.0);

        [self setView:[aCoder decodeObjectForKey:@"NSToolbarItemView"]];

        // A Cappuccino search field is 30 px normally while a Cocoa one is 22.
        if ([_view isKindOfClass:CPSearchField] && _maxSize.height == 22.0)
        {
            _maxSize.height = [_view frameSize].height;
            _minSize.height = _maxSize.height;
        }

        [self setVisibilityPriority:[aCoder decodeIntForKey:@"NSToolbarItemVisibilityPriority"]];
        [self setAutovalidates:[aCoder decodeBoolForKey:"NSToolbarItemAutovalidates"]];
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
