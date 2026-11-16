/*
 * CPTableView+Coding.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPTableViewCore.j"


@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView



var CPTableViewDataSourceKey                = @"CPTableViewDataSourceKey",
    CPTableViewDelegateKey                  = @"CPTableViewDelegateKey",
    CPTableViewHeaderViewKey                = @"CPTableViewHeaderViewKey",
    CPTableViewTableColumnsKey              = @"CPTableViewTableColumnsKey",
    CPTableViewRowHeightKey                 = @"CPTableViewRowHeightKey",
    CPTableViewIntercellSpacingKey          = @"CPTableViewIntercellSpacingKey",
    CPTableViewSelectionHighlightStyleKey   = @"CPTableViewSelectionHighlightStyleKey",
    CPTableViewMultipleSelectionKey         = @"CPTableViewMultipleSelectionKey",
    CPTableViewEmptySelectionKey            = @"CPTableViewEmptySelectionKey",
    CPTableViewColumnReorderingKey          = @"CPTableViewColumnReorderingKey",
    CPTableViewColumnResizingKey            = @"CPTableViewColumnResizingKey",
    CPTableViewColumnSelectionKey           = @"CPTableViewColumnSelectionKey",
    CPTableViewColumnAutoresizingStyleKey   = @"CPTableViewColumnAutoresizingStyleKey",
    CPTableViewGridColorKey                 = @"CPTableViewGridColorKey",
    CPTableViewGridStyleMaskKey             = @"CPTableViewGridStyleMaskKey",
    CPTableViewUsesAlternatingBackgroundKey = @"CPTableViewUsesAlternatingBackgroundKey",
    CPTableViewAlternatingRowColorsKey      = @"CPTableViewAlternatingRowColorsKey",
    CPTableViewCornerViewKey                = @"CPTableViewCornerViewKey",
    CPTableViewAutosaveNameKey              = @"CPTableViewAutosaveNameKey",
    CPTableViewArchivedReusableViewsKey     = @"CPTableViewArchivedReusableViewsKey";

@implementation CPTableView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        //Configuring Behavior
        _allowsColumnReordering = [aCoder decodeBoolForKey:CPTableViewColumnReorderingKey];
        _allowsColumnResizing = [aCoder decodeBoolForKey:CPTableViewColumnResizingKey];
        _allowsMultipleSelection = [aCoder decodeBoolForKey:CPTableViewMultipleSelectionKey];
        _allowsEmptySelection = [aCoder decodeBoolForKey:CPTableViewEmptySelectionKey];
        _allowsColumnSelection = [aCoder decodeBoolForKey:CPTableViewColumnSelectionKey];

        //Setting Display Attributes
        _selectionHighlightStyle = [aCoder decodeIntForKey:CPTableViewSelectionHighlightStyleKey];
        _columnAutoResizingStyle = [aCoder decodeIntForKey:CPTableViewColumnAutoresizingStyleKey];

        _tableColumns = [aCoder decodeObjectForKey:CPTableViewTableColumnsKey] || [];
        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];

        _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey] || [self valueForThemeAttribute:@"default-row-height"];
        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey];

        if (CGSizeEqualToSize(_intercellSpacing, CGSizeMakeZero()))
            _intercellSpacing = CGSizeMake(3.0, 2.0);

        [self setGridColor:[aCoder decodeObjectForKey:CPTableViewGridColorKey]];
        _gridStyleMask = [aCoder decodeIntForKey:CPTableViewGridStyleMaskKey];

        _usesAlternatingRowBackgroundColors = [aCoder decodeObjectForKey:CPTableViewUsesAlternatingBackgroundKey];
        [self setAlternatingRowBackgroundColors:[aCoder decodeObjectForKey:CPTableViewAlternatingRowColorsKey]];

        _headerView = [aCoder decodeObjectForKey:CPTableViewHeaderViewKey];
        _cornerView = [aCoder decodeObjectForKey:CPTableViewCornerViewKey];

        [self _init];

        if ([aCoder containsValueForKey:CPTableViewArchivedReusableViewsKey])
            _archivedDataViews = [aCoder decodeObjectForKey:CPTableViewArchivedReusableViewsKey];

        // Setting the data source reloads the table, which needs the state set by _init.
        [self setDataSource:[aCoder decodeObjectForKey:CPTableViewDataSourceKey]];
        [self setDelegate:[aCoder decodeObjectForKey:CPTableViewDelegateKey]];

        [self _updateIsViewBased];

        [self viewWillMoveToSuperview:[self superview]];

        // Do this as late as possible to make sure the tableview is fully configured
        [self setAutosaveName:[aCoder decodeObjectForKey:CPTableViewAutosaveNameKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_dataSource forKey:CPTableViewDataSourceKey];
    [aCoder encodeObject:_delegate forKey:CPTableViewDelegateKey];

    [aCoder encodeFloat:_rowHeight forKey:CPTableViewRowHeightKey];
    [aCoder encodeSize:_intercellSpacing forKey:CPTableViewIntercellSpacingKey];

    [aCoder encodeInt:_selectionHighlightStyle forKey:CPTableViewSelectionHighlightStyleKey];
    [aCoder encodeInt:_columnAutoResizingStyle forKey:CPTableViewColumnAutoresizingStyleKey];

    [aCoder encodeBool:_allowsMultipleSelection forKey:CPTableViewMultipleSelectionKey];
    [aCoder encodeBool:_allowsEmptySelection forKey:CPTableViewEmptySelectionKey];
    [aCoder encodeBool:_allowsColumnReordering forKey:CPTableViewColumnReorderingKey];
    [aCoder encodeBool:_allowsColumnResizing forKey:CPTableViewColumnResizingKey];
    [aCoder encodeBool:_allowsColumnSelection forKey:CPTableViewColumnSelectionKey];

    [aCoder encodeObject:_tableColumns forKey:CPTableViewTableColumnsKey];

    [aCoder encodeObject:[self gridColor] forKey:CPTableViewGridColorKey];
    [aCoder encodeInt:_gridStyleMask forKey:CPTableViewGridStyleMaskKey];

    [aCoder encodeBool:_usesAlternatingRowBackgroundColors forKey:CPTableViewUsesAlternatingBackgroundKey];
    [aCoder encodeObject:[self alternatingRowBackgroundColors] forKey:CPTableViewAlternatingRowColorsKey];

    [aCoder encodeObject:_cornerView forKey:CPTableViewCornerViewKey];
    [aCoder encodeObject:_headerView forKey:CPTableViewHeaderViewKey];

    [aCoder encodeObject:_autosaveName forKey:CPTableViewAutosaveNameKey];

    if (_archivedDataViews)
        [aCoder encodeObject:_archivedDataViews forKey:CPTableViewArchivedReusableViewsKey];
}

@end
