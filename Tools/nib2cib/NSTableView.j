/*
 * NSTableView.j
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

@import <AppKit/CPTableView.j>

@class Nib2Cib


@implementation CPTableView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var flags = [aCoder decodeIntForKey:@"NSTvFlags"];

        //_dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        //_delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];

        _rowHeight = [aCoder decodeFloatForKey:@"NSRowHeight"];

        // Convert xib default to cib default
        if (_rowHeight == 17)
        {
            var theme = [Nib2Cib defaultTheme],
                height = [theme valueForAttributeWithName:@"default-row-height" forClass:CPTableView];

            _rowHeight = height;
        }


        _headerView = [aCoder decodeObjectForKey:@"NSHeaderView"];

        // There will always be a corner view in nib, even if there isn't a headerview. Consider this a bug in IB.
        _cornerView = _headerView ? [aCoder decodeObjectForKey:@"NSCornerView"] : nil;

        // Make sure we unhide the cornerview because a corner view loaded from cib is always hidden
        // This might be a bug in IB, or the way we load the NSvFlags might be broken for _NSCornerView
        [_cornerView setHidden:NO];

        _autosaveName = [aCoder decodeObjectForKey:@"NSAutosaveName"];

        _tableColumns = [aCoder decodeObjectForKey:@"NSTableColumns"];
        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];

        _archivedDataViews = [aCoder decodeObjectForKey:@"NSTableViewArchivedReusableViewsKey"];

        _intercellSpacing = CGSizeMake([aCoder decodeFloatForKey:@"NSIntercellSpacingWidth"],
                                       [aCoder decodeFloatForKey:@"NSIntercellSpacingHeight"]);

        [self setValue:[aCoder decodeObjectForKey:@"NSGridColor"] forThemeAttribute:@"grid-color"];
        _gridStyleMask = [aCoder decodeIntForKey:@"NSGridStyleMask"];

        _usesAlternatingRowBackgroundColors = (flags & 0x00800000) ? YES : NO;
        _alternatingRowBackgroundColors = [[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]];

        _selectionHighlightStyle = [aCoder decodeIntForKey:@"NSTableViewSelectionHighlightStyle"];
        _columnAutoResizingStyle = [aCoder decodeIntForKey:@"NSColumnAutoresizingStyle"];

        _allowsMultipleSelection = (flags & 0x08000000) ? YES : NO;
        _allowsEmptySelection = (flags & 0x10000000) ? YES : NO;
        _allowsColumnSelection = (flags & 0x04000000) ? YES : NO;

        _allowsColumnResizing = (flags & 0x40000000) ? YES : NO;
        _allowsColumnReordering = (flags & 0x80000000) ? YES : NO;

        [self setBackgroundColor:[aCoder decodeObjectForKey:@"NSBackgroundColor"]];
    }

    return self;
}

@end

@implementation NSTableView : CPTableView
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
    return [CPTableView class];
}

@end
