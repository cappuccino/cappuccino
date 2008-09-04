/*
 * CPTableView.j
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

import "CPControl.j"
import "CPTableColumn.j"


var CPTableViewCellPlaceholder = nil;

@implementation CPTableView : CPControl
{
    id _dataSource;
    
    CPScrollView        _scrollView;
    CPTableHeaderView   _headerView;
    
    CPArray         _tableColumns;
    
    unsigned            _numberOfRows;
    unsigned            _numberOfColumns;
    
    CPArray             _tableCells;
    CPArray             _tableColumnViews;
    
    CPSize		_intercellSpacing;
}

+ (void)initialize
{
    if (self != [CPTableView class])
        return;
    
    CPTableViewCellPlaceholder = [[CPObject alloc] init];
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        /*_scrollView = [[CPView alloc] initWithFrame:CPRectMakeZero()];
        _headerView = [[CPView alloc] initWithFrame:CPRectMakeZero()];
        
        [_scrollView setBackgroundColor:[CPColor redColor]];
        [_headerView setBackgroundColor:[CPColor blueColor]];
        
        [self addSubview:_scrollView];
        [self addSubview:_headerView];
    
        [self tile];*/
        
        //[self setBackgroundColor:[CPColor redColor]];
        
        _rowHeight = 17.0;
        
        _tableCells = [[CPArray alloc] init];
        _tableColumns = [[CPArray alloc] init];
        _tableColumnViews = [[CPArray alloc] init];
        
        _intercellSpacing = CPSizeMake(3.0, 2.0);
    }
    
    return self;
}

- (float)columnHeight
{
    var bounds = [self bounds],
        height = _numberOfRows * (_rowHeight + _intercellSpacing.height);
    
    return CPRectGetHeight(bounds) > height ? CPRectGetHeight(bounds) : height;
}

- (void)loadTableCellsInRect:(CPRect)aRect
{
   if (!_dataSource)
        return;
        
    // Use a ambitious estimate for our starting row.
    var rows = CPMakeRange(MAX(Math.floor((CPRectGetMinY(aRect) + _intercellSpacing.height) / (_rowHeight + _intercellSpacing.height)), 0), 1);
    
    // Use a conservative estimate for the final row.
    rows.length = MIN(_numberOfRows, Math.ceil(CPRectGetMaxY(aRect) / (_rowHeight + _intercellSpacing.height))) - rows.location;

    var columns = CPMakeRange(0, 1);

    // Iterate through all our columns until we find one that intersects the rect.
    while (columns.location < _numberOfColumns && !CPRectIntersectsRect([_tableColumnViews[columns.location] frame], aRect)) 
        ++columns.location;
    
    // Now iterate through our columns until we find one that doesn't intersect our rect.
    while (CPMaxRange(columns) < _numberOfColumns && CPRectIntersectsRect([_tableColumnViews[CPMaxRange(columns)] frame], aRect)) 
        ++columns.length;

    var row = rows.location,
        column = 0;

    for (; row < CPMaxRange(rows); ++row)
        for (column = columns.location; column < CPMaxRange(columns); ++column)
        {
            if (!_tableCells[column][row] || _tableCells[column][row] == CPTableViewCellPlaceholder)
            {
                _tableCells[column][row] = [[_tableColumns[column] dataCellForRow:row] copy];
                
                [_tableCells[column][row] setFrame:CPRectMake(0.0, row * (_rowHeight + _intercellSpacing.height), [_tableColumns[column] width], _rowHeight)];
                //[_tableCells[column][row] setBackgroundColor:[CPColor blueColor]];
                [_tableColumnViews[column] addSubview:_tableCells[column][row]];
            }
            
            [_tableCells[column][row] setObjectValue:[_dataSource tableView:self objectValueForTableColumn:_tableColumns[column] row:row]];
        }
}

// Setting display attributes

- (void)setIntercellSpacing:(CPSize)aSize
{
    if (_intercellSpacing.width != aSize.width)
    {
        var i = 1,
            delta = aSize.width - _intercellSpacing.width;
            total = delta;
        
        for (; i < _numberOfColumns; ++i, total += delta)
        {
            var origin = [_tableColumnViews[i] frame].origin;
            [_tableColumnViews[i] setFrameOrigin:CPPointMake(origin.x + total, origin.y)];
        }
    }

    if (_intercellSpacing.height != aSize.height)
    {
        var i = 0;
        
        for (; i < _numberOfColumns; ++i, total += delta)
        {
            [_tableColumnViews[i] setFrameSize:CPSizeMake([_tableColumnViews[i] width], _numberOfRows * (_rowHeight + _intercellSpacing.height))];
            
            var j = 1,
                y = _rowHeight + _intercellSpacing.height;
            
            for (; j < _numberOfRows; ++i, y += _rowHeight + _intercellSpacing.height)
            {
                if (_tableCells[i][j] == CPTableViewCellPlaceholder)
                    continue;
                
                [_tableCells[i][j] setFrameOrigin:CPPointMake(0.0, y)];
            }
        }
    }

    _intercellSpacing = CPSizeCreateCopy(aSize);
}

- (CPSize)intercellSpacing
{
    return _intercellSpacing;
}

- (void)setRowHeight:(unsigned)aRowHeight
{
    if (_rowHeight == aRowHeight)
        return;
    
    _rowHeight = aRowHeight;
    
    var row = 0,
        column = 0;
        
    for (; row < _numberOfRows; ++row)
        for (column = 0; column < _numberOfColumns; ++column)
            [_tableCells[column][row] setFrameOrigin:CPPointMake(0.0, row * (_rowHeight + _intercellSpacing.height))];
}

- (unsigned)rowHeight
{
    return _rowHeight;
}

- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    var i = 0,
        x = _numberOfColumns ? CPRectGetMaxX([self rectOfColumn:_numberOfColumns - 1]) + _intercellSpacing.width : 0.0,
        tableColumnView = [[CPView alloc] initWithFrame:CPRectMake(x, 0.0, [aTableColumn width], [self columnHeight])],
        tableColumnCells = [[CPArray alloc] init];

    [_tableColumns addObject:aTableColumn];
    [_tableColumnViews addObject:tableColumnView];

//    [tableColumnView setBackgroundColor:[CPColor greenColor]];

    [self addSubview:tableColumnView];

    [_tableCells addObject:tableColumnCells];

    for (; i < _numberOfRows; ++i)
        _tableCells[_numberOfColumns][i] = CPTableViewCellPlaceholder;

    ++_numberOfColumns;
}

- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    var frame = [self frame],
        width = [aTableColumn width] + _intercellSpacing.width,
        index = [_tableColumns indexOfObjectIdenticalTo:aTableColumn];
    
    // Remove the column view and all the cell views from the view hierarchy.
    [_tableColumnViews[i] removeFromSuperview];

    [_tableCells removeObjectAtIndex:index];
    [_tableColumns removeObjectAtIndex:index];
    [_tabelColumnViews removeObjectAtIndex:index];

    // Shift remaining column views to the left.    
    for (; index < _numberOfColumns; ++ index)
        [_tableColumnViews[index] setFrameOrigin:CPPointMake(CPRectGetMinX([_tableColumnViews[index] frame]) - width, 0.0)]

    // Resize ourself.
    [self setFrameSize:CPSizeMake(CPRectGetWidth(frame) - width, CPRectGetHeight(frame))];
}

- (void)moveColumn:(unsigned)fromIndex toColumn:(unsinged)toIndex
{
    if (fromIndex == toIndex)
        return;
// FIXME: IMPLEMENT
}

- (CPArray)tableColumns
{
    return _tableColumns;
}

// Getting the dimensions of the table

- (int)numberOfColumns
{
    return _numberOfColumns;
}

- (int)numberOfRows
{
    return _numberOfRows;
}

- (void)tile
{
    var HEIGHT = 10.0;
    
    [_headerView setFrame:CPRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), HEIGHT)];
    [_scrollView setFrame:CPRectMake(0.0, HEIGHT, CPRectGetWidth([self bounds]), CPRectGetHeight([self bounds]) - HEIGHT)];
}

- (void)setDataSource:(id)aDataSource
{
    _dataSource = aDataSource;
    
    [self reloadData];
}

- (id)dataSource
{
    return _dataSource;
}

- (void)setFrameSize:(CPSize)aSize
{
    var oldColumnHeight = [self columnHeight];
    
    [super setFrameSize:aSize];
    
    var columnHeight = [self columnHeight];
    
    if (columnHeight != oldColumnHeight)
    {
        var i = 0;
        
        for (; i < _numberOfColumns; ++i)
            [_tableColumnViews[i] setFrameSize:CPSizeMake([_tableColumns[i] width], columnHeight)];
    }
    
    [self tile];
}

- (void)noteNumberOfRowsChanged
{
    var numberOfRows = [_dataSource numberOfRowsInTableView:self];

    if (_numberOfRows != numberOfRows)
    {
        _numberOfRows = numberOfRows;
        [self sizeToFit];
    }
}

- (CPRect)rectOfRow:(int)aRowIndex
{
    return CPRectMake(0.0, aRowIndex * (_rowHeight + _intercellSpacing.height), CPRectGetWidth([self bounds]), _rowHeight);
}

- (CPRect)rectOfColumn:(int)aColumnIndex
{
    return CPRectCreateCopy([_tableColumnViews[aColumnIndex] frame]);
}

- (void)sizeToFit
{   
    [self tile];
}

- (void)reloadData
{
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    [self loadTableCellsInRect:[self bounds]];
}

@end
