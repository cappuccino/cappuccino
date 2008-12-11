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

/*
    CPTableView is located within the AppKit framework and is used to display tables. It uses a delegate model for getting its data i.e. you give it an object that provides it with the data it should display.
    
    @ignore
*/
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
    
    CGSize		_intercellSpacing;
}

+ (void)initialize
{
    if (self != [CPTableView class])
        return;
    
    CPTableViewCellPlaceholder = [[CPObject alloc] init];
}

- (id)initWithFrame:(CGRect)aFrame
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

/*
    Returns the table's column height
*/
- (float)columnHeight
{
    var bounds = [self bounds],
        height = _numberOfRows * (_rowHeight + _intercellSpacing.height);
    
    return CPRectGetHeight(bounds) > height ? CPRectGetHeight(bounds) : height;
}

- (void)loadTableCellsInRect:(CGRect)aRect
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
/*
    Sets the width and height between cell. The default is (3.0, 2.0) (width, height).
    @param the width and height spacing
*/
- (void)setIntercellSpacing:(CGSize)aSize
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

/*
    Returns the width and height of the space between
    cells.
*/
- (CGSize)intercellSpacing
{
    return _intercellSpacing;
}

/*
    Sets the height of table rows
    @param aRowHeight the new height of the table rows
*/
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

/*
    Returns the height of a table row
*/
- (unsigned)rowHeight
{
    return _rowHeight;
}

/*
    Adds a column to the table
    @param aTableColumn the column to be added
*/
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

/*
    Removes a column from the table
    @param aTableColumn the column to remove
*/
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

/*
    Not yet implemented. Changes the position of the column in
    the table.
    @param fromIndex the original index of the column
    @param toIndex the desired index of the column
*/
- (void)moveColumn:(unsigned)fromIndex toColumn:(unsinged)toIndex
{
    if (fromIndex == toIndex)
        return;
// FIXME: IMPLEMENT
}

/*
    Returns an array containing the table's CPTableColumns.
*/
- (CPArray)tableColumns
{
    return _tableColumns;
}

// Getting the dimensions of the table
/*
    Returns the number of columns in the table
*/
- (int)numberOfColumns
{
    return _numberOfColumns;
}

/*
    Returns the number of rows in the table
*/
- (int)numberOfRows
{
    return _numberOfRows;
}

/*
    Adjusts the size of the table and it's header view.
*/
- (void)tile
{
    var HEIGHT = 10.0;
    
    [_headerView setFrame:CPRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), HEIGHT)];
    [_scrollView setFrame:CPRectMake(0.0, HEIGHT, CPRectGetWidth([self bounds]), CPRectGetHeight([self bounds]) - HEIGHT)];
}

/*
    Sets the object that is used to obtain the table data. The data source must implement the following
    methods:
<pre>
- (int)numberOfRowsInTableView:(CPTableView)aTableView
- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
</pre>
    @param aDataSource the object with the table data
    @throws CPInternalInconsistencyException if <code>aDataSource</code> doesn't implement all the required methods
*/
- (void)setDataSource:(id)aDataSource
{
    if (![aDataSource respondsToSelector:@selector(numberOfRowsInTableView:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source doesn't support 'numberOfRowsInTableView:'"];
    if (![aDataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source doesn't support 'tableView:objectValueForTableColumn:row:'"];

    _dataSource = aDataSource;
    
    [self reloadData];
}

/*
    Returns the object that has access to the table data
*/
- (id)dataSource
{
    return _dataSource;
}

- (void)setFrameSize:(CGSize)aSize
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

/*
    Tells the table view that the number of rows in the table
    has changed.
*/
- (void)noteNumberOfRowsChanged
{
    var numberOfRows = [_dataSource numberOfRowsInTableView:self];

    if (_numberOfRows != numberOfRows)
    {
        _numberOfRows = numberOfRows;
        [self sizeToFit];
    }
}

/*
    Returns the rectangle bounding the specified row.
    @param aRowIndex the row to obtain a rectangle for
    @return the bounding rectangle
*/
- (CGRect)rectOfRow:(int)aRowIndex
{
    return CPRectMake(0.0, aRowIndex * (_rowHeight + _intercellSpacing.height), CPRectGetWidth([self bounds]), _rowHeight);
}

/*
    Returns the rectangle bounding the specified column
    @param aColumnIndex the column to obtain a rectangle for
    @return the bounding column
*/
- (CGRect)rectOfColumn:(int)aColumnIndex
{
    return CPRectCreateCopy([_tableColumnViews[aColumnIndex] frame]);
}

/*
    Adjusts column widths to make them all visible at once. Same as <code>tile</code>.
*/
- (void)sizeToFit
{   
    [self tile];
}

/*
    Reloads the data from the <code>dataSource</code>. This is an
    expensive method, so use it lightly.
*/
- (void)reloadData
{
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    [self loadTableCellsInRect:[self bounds]];
}

@end
