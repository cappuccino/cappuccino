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

@import "CPTableView.j"

/*!
    @ignore 
    This class is a subclass of CPTableView which provides the user with a way to display 
    tree structured data in an outline format. It is particularly useful for displaying hierarchical data 
    such as a class inheritance tree or any other set of relationships.
*/

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

/*!
    @ignore
    Sets the outline's data source. The data source must implement the following methods:
<pre>
- (id)outlineView:(CPOutlineView)outlineView child:(int)index ofItem:(id)item
- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item
- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item
- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
</pre>
    @param aDataSource the outline's data source
    @throws CPInternalInconsistencyException if the data source does not implement all the required methods
*/
- (void)setDataSource:(id)aDataSource
{
    if (![aDataSource respondsToSelector:@selector(outlineView:child:ofItem)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:child:ofItem'"];
    if (![aDataSource respondsToSelector:@selector(outlineView:isItemExpandable)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:isItemExpandable'"];
    if (![aDataSource respondsToSelector:@selector(outlineView:numberOfChildrenOfItem)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:numberOfChildrenOfItem'"];
    if (![aDataSource respondsToSelector:@selector(outlineView:objectValueForTableColumn:byItem)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:objectValueForTableColumn:byItem'"];

    _outlineDataSource = aDataSource;

    [self reloadData];
}
/* @ignore */
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

/* @ignore */
@implementation CPOutlineView (CPTableDataSource)

/*
    FIXME 
*/
/* @ignore */
- (void)numberOfRowsInTableView:(CPTableView)aTableView
{
    return _numberOfVisibleItems;
}

/* @ignore */
- (void)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRowIndex
{
    return [_outlineDataSource outlineView:self objectValueForTableColumn:aTableColumn byItem:_itemsByRow[aRowIndex]];
}

@end