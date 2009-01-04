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

@import "CPControl.j"
@import "CPTableColumn.j"

//objj_backtrace_set_enable(true);

#define ROW_HEIGHT(aRow) (_hasVariableHeightRows ? _rowHeights[aRow] : _rowHeight);

/*
    CPTableView is located within the AppKit framework and is used to display tables. It uses a delegate model for getting its data i.e. you give it an object that provides it with the data it should display.
    
    @ignore
*/
@implementation CPTableView : CPControl
{
    id                  _dataSource;
    
    CPScrollView        _scrollView;
    CPTableHeaderView   _headerView;
    
    CPArray             _tableColumns;
    
    // 
    unsigned            _numberOfRows;
    unsigned            _numberOfColumns;
    
    // Heights
    float               _rowHeight;
    float               _columnHeight; // calculated
    
    CPArray             _rowMinYs;
    CPArray             _rowHeights;
    
    BOOL                _hasVariableHeightRows;
    
    CPArray             _tableCells;
    CPArray             _tableColumnViews;
    
    CGSize		        _intercellSpacing;
    
    // Caching
    Object              _dataViewCache;
    CPArray             _objectValueCache;
    
    CPRange             _visibleRows;
    CPRange             _visibleColumns;
    
    CPRange             _populatedRows;
    CPRange             _populatedColumns;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {   
        _rowHeight = 17.0;
        
        _tableCells = [];
        _tableColumns = [];
        _tableColumnViews = [];
        
        _dataViewCache = {};
        _objectValueCache = {};
                
        _intercellSpacing = CPSizeMake(3.0, 2.0);
        
        _visibleRows = CPMakeRange(0, 0);
        _visibleColumns = CPMakeRange(0, 0);
    }
    
    return self;
}

/*
    Returns the table's column height
*/
- (float)_columnHeight
{
    return _numberOfRows * (_rowHeight + _intercellSpacing.height);
}

- (void)newCellForRow:(unsigned)aRowIndex column:(unsigned)aColumnIndex avoidingRows:(CPRange)rows
{//console.warn("new cell please.");
    var dataView = [_tableColumns[aColumnIndex] _newDataViewForRow:aRowIndex avoidingRows:rows];
                
    [dataView setFrame:CGRectMake(0.0, aRowIndex * (_rowHeight + _intercellSpacing.height), [_tableColumns[aColumnIndex] width], _rowHeight)];
    [dataView setBackgroundColor:[CPColor greenColor]];
    
    if (!_objectValueCache[aColumnIndex])
        _objectValueCache[aColumnIndex] = [];

    // We may be storing 0 after all!
    if (typeof _objectValueCache[aColumnIndex][aRowIndex] === "undefined")
        _objectValueCache[aColumnIndex][aRowIndex] = [_dataSource tableView:self objectValueForTableColumn:_tableColumns[aColumnIndex] row:aRowIndex];        
    
    [dataView setObjectValue:_objectValueCache[aColumnIndex][aRowIndex]];
    
    return dataView;
}

- (void)loadTableCellsInRect:(CGRect)aRect
{
   if (!_dataSource)
        return;

    // Determine new visible rows and columns.

        // Use a ambitious estimate for our starting row.
    var rowStart = MAX(FLOOR((CGRectGetMinY(aRect) + _intercellSpacing.height) / (_rowHeight + _intercellSpacing.height)), 0),
        
        // Use a conservative estimate for the final row.
        rowEnd = MIN(_numberOfRows, CEIL(CGRectGetMaxY(aRect) / (_rowHeight + _intercellSpacing.height))),
        
        visibleRows = CPMakeRange(rowStart, rowEnd - rowStart);

    var columnStart = 0;

    // Iterate through all our columns until we find the first one that intersects the rect.
    while (columnStart < _numberOfColumns && !CGRectIntersectsRect([_tableColumnViews[columnStart] frame], aRect)) 
        ++columnStart;
        
    // Now use a binary search to find the last visible column
    // O (lg n) < O (n), but O(n) (above), so O (n + lg n) = O (n) ? 
    var first = columnStart + 1,
        last = _numberOfColumns - 1;
        columnEnd = columnStart;
    
    while (first <= last)
    {
        // Assume this is the one.
        var columnEnd = FLOOR((first + last) / 2),
            columnIsVisible = CGRectIntersectsRect([_tableColumnViews[columnEnd] frame], aRect);
            
        // If the column isn't visible, look left!
        if (!columnIsVisible)
            last = columnEnd - 1;
        
        // Visible, nothing to the right, found it...
        if (columnEnd + 1 >= _numberOfColumns)
            break;
        
        // Visible, column to the right is NOT visible, found it! (the good way)
        if (!CGRectIntersectsRect([_tableColumnViews[columnEnd + 1] frame], aRect))
            break;
        
        // If not, look right! (2 since we checked the dude to the right already)
        first = columnEnd + 2;
    }
    
    // columnEnd is our "count" in loops.
    ++columnEnd;
    
    var visibleColumns = CPMakeRange(columnStart, columnEnd - columnStart);

    if (CPEqualRanges(_visibleRows, visibleRows) && CPEqualRanges(_visibleColumns, visibleColumns))
        return;
    
    var unionVisibleRows = CPUnionRange(_visibleRows, visibleRows),
        unionVisibleColumns = CPUnionRange(_visibleColumns, visibleColumns);
    
    // Determine whether to use 2 sweeps or one.  If we have lots of overlap of cells, use just one.
    if (unionVisibleRows.length * unionVisibleColumns.length <= 
        (_visibleRows.length + visibleRows.length) * (_visibleColumns.length + visibleColumns.length))
    {
        var column = unionVisibleColumns.location,
            columnEnd = CPMaxRange(unionVisibleColumns),
            
            rowStart = unionVisibleRows.location,
            rowEnd = CPMaxRange(unionVisibleRows);
            
        for (; column < columnEnd; ++column)
        {
            var row = rowStart,
                tableColumn = _tableColumns[column],
                tableColumnCells = _tableCells[column],
                columnIsVisible = CPLocationInRange(column, visibleColumns);
            
            for (; row < rowEnd; ++row)
            {
                var cell = tableColumnCells[row];
                
                if (cell)
                {
                    if (columnIsVisible && CPLocationInRange(row, visibleRows))
                        [tableColumn _markView:cell inRow:row asPurgable:NO];
                    else {
                    //!!!
                    _tableCells[column][row] = nil;
                        [tableColumn _markView:cell inRow:row asPurgable:YES];
                    }
                }
                
                else
                {
//                    ASSERT(CPLocationInRange(row, visibleRows) && CPLocationInRange(column, visibleColumns))
                    tableColumnCells[row] = [self newCellForRow:row column:column avoidingRows:visibleRows];
                    
                    [_tableColumnViews[column] addSubview:tableColumnCells[row]];
                }
            }
        }
    }
    else
    {
    
    }

    _visibleRows = visibleRows;
    _visibleColumns = visibleColumns;
    
    /*
    var column = columnStart;
    
    for (; column < _numberOfColumns && CGRectIntersectsRect([_tableColumnViews[column] frame], aRect); ++column)
    {
        var row = rowStart,
            tableColumn = _tableColumns[column];
                    
        for (; row < rowEnd; ++row)
        {
            //if (CPLocationInRange(row, _visibleRows))
            //    continue;
            
            var cell = _tableCells[column][row];
            
            if (cell)
                [tableColumn _markView:cell inRow:row asPurgable:NO];
                
            else
                _tableCells[column][row] = [self newCellForRow:row column:column avoidingRows:visibleRows];
        }
    }
    
    var visibleRows = visibleRowsCPMakeRange(rowStart, rowEnd - rowStart),
        visibleColumns = CPMakeRange(columnStart, rememberColumn - columnStart);
    
    var columnEnd = CPMaxRange(_visibelColumns);
    
    
    for (column = _visibleColumns.location; column < columnEnd; ++column)
    {
        var tableColumn = _tableColumns[tableColumn],
            tableColumnCells = _tableCells[column];
        
        for (row = _visibleRows.location, rowEnd = CPMaxRange(_visibleRows); row < rowEnd; ++row)
            if (!CPLocationInRange(row, visibleRows) || !CPLocationInRange(column, visibleColumns))
            {
                var view = tableColumnCells[row];
                
                if (view)
                    [tableColumn _markView:view inRow:row asPurgable:YES];
            }
    }        
    
    _visibleRows = visibleRows;
    _visibleColumns = visibleColumns;*/
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
            [_tableColumnViews[i] setFrameOrigin:CGPointMake(origin.x + total, origin.y)];
        }
    }

    if (_intercellSpacing.height != aSize.height)
    {
        var i = 0;
        
        for (; i < _numberOfColumns; ++i, total += delta)
        {
            [_tableColumnViews[i] setFrameSize:CGSizeMake([_tableColumnViews[i] width], _numberOfRows * (_rowHeight + _intercellSpacing.height))];
            
            var j = 1,
                y = _rowHeight + _intercellSpacing.height;
            
            for (; j < _numberOfRows; ++i, y += _rowHeight + _intercellSpacing.height)
            {
                if (!_tableCells[i][j])
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
        tableColumnView = [[CPView alloc] initWithFrame:CPRectMake(x, 0.0, [aTableColumn width], [self _columnHeight])],
        tableColumnCells = [];

    [_tableColumns addObject:aTableColumn];
    [_tableColumnViews addObject:tableColumnView];

//    [tableColumnView setBackgroundColor:[CPColor greenColor]];

    [self addSubview:tableColumnView];

    [_tableCells addObject:tableColumnCells];

    for (; i < _numberOfRows; ++i)
        _tableCells[_numberOfColumns][i] = nil;
        
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
    
//    [_headerView setFrame:CPRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), HEIGHT)];
//    [_scrollView setFrame:CPRectMake(0.0, HEIGHT, CPRectGetWidth([self bounds]), CPRectGetHeight([self bounds]) - HEIGHT)];
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
        
        [self _recalculateColumnHeight];
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
    return [_tableColumnViews[aColumnIndex] frame];
}

/*
    Adjusts column widths to make them all visible at once. Same as <code>tile</code>.
*/
- (void)sizeToFit
{   
//    [self tile];
}

- (void)_recalculateColumnHeight
{
    var oldColumnHeight = _columnHeight;
    
    if (_hasVariableHeightRows)
    {
    }
    else
        _columnHeight = _numberOfRows * (_rowHeight + _intercellSpacing.height);
    
    var count = _tableColumnViews.length;

    while (count--)
        [_tableColumnViews[count] setFrameSize:CGSizeMake([_tableColumns[count] width], _columnHeight)];
    
    [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), _columnHeight)];
}

- (CGRect)visibleRectInParent
{
    var superview = [self superview];
    
    if (!superview)
        return [self bounds];
    
    return [self convertRect:CGRectIntersection([superview bounds], [self frame]) fromView:superview];
}

/*
    Reloads the data from the <code>dataSource</code>. This is an
    expensive method, so use it lightly.
*/
- (void)reloadData
{
    var oldNumberOfRows = _numberOfRows;
    
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    if (oldNumberOfRows != _numberOfRows)
    {
        [self _recalculateColumnHeight];
        [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), [self _columnHeight])];
    }   
    
    [self setNeedsDisplay:YES];
}

- (void)viewWillDraw
{
    [self loadTableCellsInRect:[self visibleRectInParent]];
    
    //alert("oh yes. " + CPStringFromRect([self visibleRect]));
    //[self reloadData];
}

- (void)drawRect:(CGRect)aRect
{
}

- (void)setFrameSize:(CGSize)aFrameSize
{
    [super setFrameSize:aFrameSize];

//    [self setNeedsDisplay:YES];
}

- (void)displaySoon
{
//    window.setTimeout();
}

- (void)viewDidMoveToSuperview
{
    [[[self enclosingScrollView] contentView] setPostsBoundsChangedNotifications:YES];
    
    [[CPNotificationCenter defaultCenter]
        addObserver:self
               selector:@selector(viewBoundsChanged:)
                   name:CPViewBoundsDidChangeNotification 
                 object:[[self enclosingScrollView] contentView]];
    //console.warn("cheese");
}

- (void)viewBoundsChanged:(CPNotification)aNotification
{
    //console.warn(_cmd + CPStringFromRect([[[self enclosingScrollView] contentView] bounds]));
    //objj_debug_print_backtrace();
    [self setNeedsDisplay:YES];
}

@end
