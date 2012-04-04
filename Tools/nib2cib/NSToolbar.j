/*
 * NSToolbar.j
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

@import <AppKit/CPToolbar.j>

// NS_CPToolbarItemIdentifierMap
@import "NSToolbarItem.j"

@implementation CPToolbar (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        _identifier                 = [aCoder decodeObjectForKey:"NSToolbarIdentifier"];
        _displayMode                = [aCoder decodeIntForKey:"NSToolbarDisplayMode"];
        _showsBaselineSeparator     = [aCoder decodeBoolForKey:"NSToolbarShowsBaselineSeparator"];
        _allowsUserCustomization    = [aCoder decodeBoolForKey:"NSToolbarAllowsUserCustomization"];
        _isVisible                  = [aCoder decodeBoolForKey:"NSToolbarPrefersToBeShown"];

        _identifiedItems = [CPMutableDictionary dictionary];

        var nsIdentifiedItems = [aCoder decodeObjectForKey:"NSToolbarIBIdentifiedItems"],
            key = nil,
            keyEnumerator = [nsIdentifiedItems keyEnumerator];

        // Some of the item identifiers will be changed when loaded by NSToolbarItem, so we must change
        // the map to correspond.
        while ((key = [keyEnumerator nextObject]) !== nil)
        {
            var transformedKey = NS_CPToolbarItemIdentifierMap[key] || key;
            [_identifiedItems setObject:[nsIdentifiedItems objectForKey:key] forKey:transformedKey];
        }

        _defaultItems               = [aCoder decodeObjectForKey:"NSToolbarIBDefaultItems"];
        _allowedItems               = [aCoder decodeObjectForKey:"NSToolbarIBAllowedItems"];
        _selectableItems            = [aCoder decodeObjectForKey:"NSToolbarIBSelectableItems"];

        _sizeMode                   = [aCoder decodeObjectForKey:"NSToolbarSizeMode"] || CPToolbarSizeModeDefault;

        _delegate                   = [aCoder decodeObjectForKey:"NSToolbarDelegate"];
    }

    return self;
}

@end

@implementation NSToolbar : CPToolbar
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPToolbar class];
}

@end
