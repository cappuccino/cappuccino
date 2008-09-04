/*
 * CPOutlineView.j
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

import "CPTableView.j"


@implementation CPOutlineView : CPTableView
{
    id      _outlineDataSource;
    CPArray _itemsByRow;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        [super setDataSource:self];
        _itemsByRow = [[CPArray alloc] init];
    }
    
    return self;
}

- (void)setDataSource:(id)aDataSource
{
    _outlineDataSource = aDataSource;

    [self reloadData];
}

- (void)reloadData
{
    _numberOfVisibleItems = [_outlineDataSource outlineView:self numberOfChildrenOfItem:nil];
    _numberOfRows = _numberOfVisibleItems;
    
    var i = 0;
    
    for (; i < _numberOfVisibleItems; ++i)
        _itemsByRow[i] = [_outlineDataSource outlineView:self child:i ofItem:nil];
    
    [self loadTableCellsInRect:[self bounds]];
}

@end

@implementation CPOutlineView (CPTableDataSource)

- (void)numberOfRowsInTableView:(CPTableView)aTableView
{
    return _numberOfVisibleItems;
}

- (void)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRowIndex
{
    return [_outlineDataSource outlineView:self objectValueForTableColumn:aTableColumn byItem:_itemsByRow[aRowIndex]];
}

@end