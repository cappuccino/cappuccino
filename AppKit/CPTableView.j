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

@import "CPColor.j"
@import "CPTextField.j"

#define ROW_HEIGHT(aRow) (_hasVariableHeightRows ? _rowHeights[aRow] : _rowHeight)
#define ROW_MIN_Y(aRow) (_hasVariableHeightRows ? _rowMinYs[aRow] : (aRow * (_rowHeight + _intercellSpacing.height)))

CPTableViewColumnDidMoveNotification        = "CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = "CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = "CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = "CPTableViewSelectionIsChangingNotification";

var _CPTableViewWillDisplayCellSelector                         = 1 << 0,
    _CPTableViewShouldSelectRowSelector                         = 1 << 1,
    _CPTableViewShouldSelectTableColumnSelector                 = 1 << 2,
    _CPTableViewSelectionShouldChangeSelector                   = 1 << 3,
    _CPTableViewShouldEditTableColumnSelector                   = 1 << 4,
    _CPTableViewSelectionIndexesForProposedSelectionSelector    = 1 << 5,
    _CPTableViewHeightOfRowSelector                             = 1 << 6;
    
/*
    CPTableView is located within the AppKit framework and is used to display tables. It uses a delegate model for getting its data i.e. you give it an object that provides it with the data it should display.
    
    @ignore
*/
@implementation CPTableView : CPControl
{
    // Archived:
    
    id                  _dataSource;
    id                  _delegate;
    
    //CPTableHeaderView   _headerView;
    //CPView              _cornerView;
    
    CPArray             _tableColumns;
    
    CPIndexSet          _selectedRowIndexes;
    //CPArray             _selectedColumns;
    
    float               _rowHeight;
    CGSize		        _intercellSpacing;
    
    BOOL                _allowsMultipleSelection;
    BOOL                _allowsEmptySelection;
    //BOOL                _allowsColumnReordering;
    //BOOL                _allowsColumnResizing;
    //BOOL                _allowsColumnSelection;
    //BOOL                _autoresizesAllColumnsToFit;
    
    //CPColor             _gridColor;
    //BOOL                _drawsGrid;
    
    
    // Not archived:
    
    int                 _delegateSelectorsCache;
    
    //CPScrollView        _scrollView;
    
    unsigned            _numberOfRows;
    unsigned            _numberOfColumns;
    
    BOOL                _hasVariableHeightRows;
    
    // Heights
    float               _columnHeight; // calculated
    
    CPArray             _rowHeights;
    CPArray             _rowMinYs;
    
    CPArray             _tableCells;
    CPArray             _tableColumnViews;
    
    // Caching
    Object              _dataViewCache;
    CPArray             _objectValueCache;
    
    CPRange             _visibleRows;
    CPRange             _visibleColumns;
    
    CPRange             _populatedRows;
    CPRange             _populatedColumns;
    
    // Selection
    CPIndexSet          _previousSelectedRowIndexes;
    int                 _selectionStartRow;
    int                 _selectionModifier;
    
    CPIndexSet          _currentlySelected;
    CPArray             _selectionViews;
    CPArray             _selectionViewsPool;
}

+ (void)initialize
{
    
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        [self _init];
    }
    
    return self;
}

- (void)_init
{
    _tableColumns = [];
    _numberOfColumns = 0;

    _selectedRowIndexes = [CPIndexSet indexSet];

    _rowHeight = 17.0;
    _intercellSpacing = CPSizeMake(3.0, 2.0);

    _allowsMultipleSelection = YES;
    _allowsEmptySelection = YES;
    

    _tableCells = [];
    _tableColumnViews = [];
    
    _dataViewCache = {};
    _objectValueCache = [];
    
    _visibleRows = CPMakeRange(0, 0);
    _visibleColumns = CPMakeRange(0, 0);
    
    _rowHeights = [];
    _rowMinYs = [];
}

/*
    Returns the table's column height
*/
- (float)_columnHeight
{
    return _columnHeight;//_numberOfRows * (_rowHeight + _intercellSpacing.height);
}

- (void)newCellForRow:(unsigned)aRowIndex column:(unsigned)aColumnIndex avoidingRows:(CPRange)rows
{
    var dataView = [_tableColumns[aColumnIndex] _newDataViewForRow:aRowIndex avoidingRows:rows];
    
    [dataView setFrame:CGRectMake(0.0, ROW_MIN_Y(aRowIndex), [_tableColumns[aColumnIndex] width], ROW_HEIGHT(aRowIndex))];
    
    if ([dataView respondsToSelector:@selector(highlight:)])
        [dataView highlight:[_selectedRowIndexes containsIndex:aRowIndex]];
    
    if (!_objectValueCache[aColumnIndex])
        _objectValueCache[aColumnIndex] = [];

    // We may be storing 0 after all!
    if (_objectValueCache[aColumnIndex][aRowIndex] === undefined)
        _objectValueCache[aColumnIndex][aRowIndex] = [_dataSource tableView:self objectValueForTableColumn:_tableColumns[aColumnIndex] row:aRowIndex];        
    
    [dataView setObjectValue:_objectValueCache[aColumnIndex][aRowIndex]];
    
    return dataView;
}

- (void)clearCells
{
    var columnEnd = CPMaxRange(_visibleColumns),
        rowEnd = CPMaxRange(_visibleRows);
        
    for (var column = _visibleColumns.location; column < columnEnd; column++)
    {
        var tableColumn = _tableColumns[column],
            tableColumnCells = _tableCells[column];
            
        for (var row = _visibleRows.location; row < rowEnd; row++)
        {
            var cell = tableColumnCells[row];
            if (cell)
            {
                tableColumnCells[row] = nil;
                [tableColumn _markView:cell inRow:row asPurgable:YES];
            }
            else
            {
                CPLog.warn("Missing cell? " + row + "," + column);
            }
        }
    }
    
    _visibleColumns = CPMakeRange(0,0);
    _visibleRows = CPMakeRange(0,0);
}

- (void)loadTableCellsInRect:(CGRect)aRect
{
   if (!_dataSource)
        return;

    // Determine new visible rows and columns.

    var rowStart = MAX(0, [self _rowAtY:CGRectGetMinY(aRect)] - 1),
        rowEnd = MIN(_numberOfRows, [self _rowAtY:CGRectGetMaxY(aRect)] + 1),
        
        visibleRows = CPMakeRange(rowStart, rowEnd - rowStart),
    
        columnStart = MAX(0, [self _columnAtX:CGRectGetMinX(aRect)]),
        columnEnd   = MIN(_numberOfColumns, [self _columnAtX:CGRectGetMaxX(aRect)] + 1),
        
        visibleColumns = CPMakeRange(columnStart, columnEnd - columnStart);

    if (CPEqualRanges(_visibleRows, visibleRows) && CPEqualRanges(_visibleColumns, visibleColumns))
        return;
    
    var unionVisibleRows = CPUnionRange(_visibleRows, visibleRows),
        unionVisibleColumns = CPUnionRange(_visibleColumns, visibleColumns);
    
    // Determine whether to use 2 sweeps or one.  If we have lots of overlap of cells, use just one.
    //if (unionVisibleRows.length * unionVisibleColumns.length <= 
    //    (_visibleRows.length * _visibleColumns.length) + (visibleRows.length * visibleColumns.length))
    //{
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
                        tableColumnCells[row] = nil;
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
            
            [tableColumn _purge];
        }
    //}
    //else
    //    CPLog.error("CPTable double sweep not implemented");

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
        
        // FIXME: variable height rows
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
    
    // don't perform adjustments if we're using variable height rows
    if (_hasVariableHeightRows)
        return;
    
    for (var row = 0; row < _numberOfRows; ++row)
        for (var column = 0; column < _numberOfColumns; ++column)
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

    // TODO: do we really need to initialize this, or is undefined good enough?
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

/*
    Returns the first CPTableColumn equal to the given object (as determined by the "isEqual:" selector), or nil if none exists.
    @param anObject the object to look for
*/
- (CPTableColumn)tableColumnWithIdentifier:(id)anObject
{
    for (var i = 0; i < _tableColumns.length; i++)
        if ([_tableColumns[i] isEqual:anObject])
            return _tableColumns[i];
    return nil;
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


- (id)delegate
{
    return _delegate;
}


/*!
    Sets the delegate for the tableview.
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;
    
    var notificationCenter = [CPNotificationCenter defaultCenter];
    
    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        [notificationCenter removeObserver:_delegate name:CPTableViewColumnDidMoveNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        [notificationCenter removeObserver:_delegate name:CPTableViewColumnDidResizeNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        [notificationCenter removeObserver:_delegate name:CPTableViewSelectionDidChangeNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        [notificationCenter removeObserver:_delegate name:CPTableViewSelectionIsChangingNotification object:self];
    
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        [notificationCenter addObserver:_delegate selector:@selector(tableViewColumnDidMove:) name:CPTableViewColumnDidMoveNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        [notificationCenter addObserver:_delegate selector:@selector(tableViewColumnDidResize:) name:CPTableViewColumnDidResizeNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        [notificationCenter addObserver:_delegate selector:@selector(tableViewSelectionDidChange:) name:CPTableViewSelectionDidChangeNotification object:self];
    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        [notificationCenter addObserver:_delegate selector:@selector(tableViewSelectionIsChanging:) name:CPTableViewSelectionIsChangingNotification object:self];

    _delegateSelectorsCache = 0;

    if ([_delegate respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)])
        _delegateSelectorsCache |= _CPTableViewWillDisplayCellSelector;
    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)])
        _delegateSelectorsCache |= _CPTableViewShouldSelectRowSelector;
    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectTableColumn:)])
        _delegateSelectorsCache |= _CPTableViewShouldSelectTableColumnSelector;
    if ([_delegate respondsToSelector:@selector(selectionShouldChangeInTableView:)])
        _delegateSelectorsCache |= _CPTableViewSelectionShouldChangeSelector;
    if ([_delegate respondsToSelector:@selector(tableView:shouldEditTableColumn:row:)])
        _delegateSelectorsCache |= _CPTableViewShouldEditTableColumnSelector;
    if ([_delegate respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)])
        _delegateSelectorsCache |= _CPTableViewSelectionIndexesForProposedSelectionSelector;
    if ([_delegate respondsToSelector:@selector(tableView:heightOfRow:)])
    {
        _delegateSelectorsCache |= _CPTableViewHeightOfRowSelector;
        _hasVariableHeightRows = YES;
    }
    else
        _hasVariableHeightRows = NO;
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

- (void)noteHeightOfRowsWithIndexesChanged:(CPIndexSet)indexSet
{
    // FIXME: more efficient version is possible since we know which indexes changes
    [self _recalculateColumnHeight];
}

/*
    Returns the rectangle bounding the specified row.
    @param aRowIndex the row to obtain a rectangle for
    @return the bounding rectangle
*/
- (CGRect)rectOfRow:(int)aRowIndex
{
    return CPRectMake(0.0, ROW_MIN_Y(aRowIndex), CPRectGetWidth([self bounds]), ROW_HEIGHT(aRowIndex));
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
        _rowMinYs[0] = 0;
        for (var row = 0; row < _numberOfRows; row++)
        {
            _rowHeights[row] = [_delegate tableView:self heightOfRow:row];
            _rowMinYs[row+1] = _rowMinYs[row] + _rowHeights[row] + _intercellSpacing.height;
        }
        _columnHeight = _rowMinYs[_numberOfRows]; // last index is one more than last row, and is the total column height
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
    
    _objectValueCache = [];
    
    [self clearCells];
    
    [self setNeedsDisplay:YES];
}

- (void)viewWillDraw
{
    [self loadTableCellsInRect:[self visibleRectInParent]];
}

- (void)drawRect:(CGRect)aRect
{
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
}

- (void)viewBoundsChanged:(CPNotification)aNotification
{
    //console.warn(_cmd + CPStringFromRect([[[self enclosingScrollView] contentView] bounds]));
    //objj_debug_print_backtrace();
    [self setNeedsDisplay:YES];
}

/*
- (void)setAllowsColumnReordering:(BOOL)allowsColumnReordering
{
    if (_allowsColumnReordering === _allowsColumnReordering)
        return;
        
    _allowsColumnReordering = allowsColumnReordering;
}
- (void)allowsColumnReordering
{
    return _allowsColumnReordering;
}

- (void)setAllowsColumnResizing:(BOOL)allowsColumnResizing
{
    if (_allowsColumnResizing === allowsColumnResizing)
        return;
        
    _allowsColumnResizing = allowsColumnResizing;
}
- (void)allowsColumnResizing
{
    return _allowsColumnResizing;
}

- (void)setAllowsColumnSelection:(BOOL)allowsColumnSelection
{
    if (_allowsColumnSelection === allowsColumnSelection)
        return;

    _allowsColumnSelection = allowsColumnSelection;
}
- (void)allowsColumnSelection
{
    return _allowsColumnSelection;
}
*/

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if (_allowsMultipleSelection === allowsMultipleSelection)
        return;
        
    _allowsMultipleSelection = allowsMultipleSelection;
    
    // TODO: more stuff?
}
- (void)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setAllowsEmptySelection:(BOOL)allowsEmptySelection
{
    if (_allowsEmptySelection === allowsEmptySelection)
        return;
    
    _allowsEmptySelection = allowsEmptySelection;
}
- (void)allowsEmptySelection
{
    return _allowsEmptySelection;
}


/*
    Returns the index of the row at the given point, or CPNotFound (-1) if it is out of range.
    @param aPoint the point
    @return the index of the row at aPoint
*/
- (int)rowAtPoint:(CGPoint)aPoint
{
    var index = [self _rowAtY:aPoint.y]
    
    if (index >= 0 && index < _numberOfRows)
        return index;
    else
        return CPNotFound;
}

- (int)columnAtPoint:(CGPoint)aPoint
{
    var index = [self _columnAtX:aPoint.x]
    
    if (index >= 0 && index < _numberOfColumns)
        return index;
    else
        return CPNotFound;
}

/*
    @ignore
    
    Internal version takes a Y value, returns an index, or -1 if its beyond the min, or numberOfRows if it's beyond the max
*/
- (int)_rowAtY:(float)y
{
    if (_hasVariableHeightRows)
    {
        var a = 0,
            b = _numberOfRows;
            
        if (y < _rowMinYs[0])
            return -1;
        if (y >= _rowMinYs[_rowMinYs.length-1])
            return _numberOfRows;

        // binary search
        while (true)
        {
            var half = a + Math.floor((b - a) / 2);
            
            if (half === _numberOfRows - 1)
                return _numberOfRows - 1;
            
            if (y >= _rowMinYs[half+1])
                a = half;
            else if (y < _rowMinYs[half])
                b = half;
            else
                return half;
        }
    }
    else
        return FLOOR(y / (_rowHeight + _intercellSpacing.height));
}

/*
    @ignore
    
    Internal version takes a X value, returns an index, or -1 if its beyond the min, or numberOfColumns if it's beyond the max
*/
- (int)_columnAtX:(float)y
{
    var a = 0,
        b = _numberOfColumns;
        
    var last = [_tableColumnViews[_numberOfColumns-1] frame];
    if (y < [_tableColumnViews[0] frame].origin.x)
        return -1;
    if (y >= last.origin.x + last.size.width)
        return _numberOfColumns;

    // binary search
    while (true)
    {
        var half = a + Math.floor((b - a) / 2);

        if (half === _numberOfColumns - 1)
            return _numberOfColumns - 1;
            
        if (y >= [_tableColumnViews[half+1] frame].origin.x)
            a = half;
        else if (y < [_tableColumnViews[half] frame].origin.x)
            b = half;
        else
            return half;
    }
}

/*
    Selects the specified row indexes, optionally adding to existing selection
    @param indexes the indexes to select
    @param extend whether or not to add to the existing selection
*/
- (void)selectRowIndexes:(CPIndexSet)indexes byExtendingSelection:(BOOL)extend
{
    // FIXME: should this be subject to the delegate filters, etc? 
    
    if (extend)
        _selectedRowIndexes = [[_selectedRowIndexes copy] addIndexes:indexes];
    else if ([indexes count] > 0 || _allowsEmptySelection)
        _selectedRowIndexes = [indexes copy];
    
    [self _drawSelection];
}

/*
    Returns a CPIndexSet of the selected rows
    @return indexes of the selected rows
*/
- (CPIndexSet)selectedRowIndexes
{
    return _selectedRowIndexes;
}

/*
    Returns the number of selected rows
    @return number of selected rows
*/
- (int)numberOfSelectedRows
{
    return [_selectedRowIndexes count];
}


/*
    Deselects all rows if allowsEmptySelection is true. If delegate responds to "selectionShouldChangeInTableView:", asks if it should chnage.
    Sends the CPTableViewSelectionDidChangeNotification on deselection.
    @param the sender in a target/action
*/
- (void)deselectAll:(id)sender
{
    if (!_allowsEmptySelection || [_selectedRowIndexes count] === 0 ||
            ((_delegateSelectorsCache & _CPTableViewSelectionShouldChangeSelector) && ![_delegate selectionShouldChangeInTableView:self]))
        return;
    
    [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewSelectionDidChangeNotification object:self userInfo:nil];
}

- (void)editColumn:(int)columnIndex row:(int)rowIndex withEvent:(CPEvent)theEvent select:(BOOL)flag
{
    
}

/*
    @ignore
*/
- (void)_updateSelectionWithMouseAtRow:(int)aRow
{
    // Make a preliminary new selection
    var newSelection;
    if (_allowsMultipleSelection)
        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionStartRow), ABS(aRow-_selectionStartRow)+1)];
    else if (aRow >= 0 && aRow < _numberOfRows)
        newSelection = [CPIndexSet indexSetWithIndex:aRow];
    else
        newSelection = [CPIndexSet indexSet];
        
    // If cmd/ctrl was held down XOR the old selection with the proposed selection
    if (_allowsMultipleSelection && _selectionModifier & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        // A = newSelection, B = _previousSelectedRowIndexes    
        // (A intersection B) = (A - (A - B))
        var intersection = [newSelection copy],
            difference = [newSelection copy];
        [difference removeIndexes:_previousSelectedRowIndexes];
        [intersection removeIndexes:difference]
        
        // (A xor B) = (A + B) - (A intersection B)
        [newSelection addIndexes:_previousSelectedRowIndexes];
        [newSelection removeIndexes:intersection];
        
        // FIXME: if multiple selection is off, and we cmd/ctrl click the previously selected row, then deselect it.
    }
    
    // if the new selection is different than the old selection
    if (![newSelection isEqualToIndexSet:_selectedRowIndexes])
    {
        // ask the delegate if we should change the selection
        if ((_delegateSelectorsCache & _CPTableViewSelectionShouldChangeSelector) && ![_delegate selectionShouldChangeInTableView:self])
            return;
        
        // ask the delegate which indexes can be selected. selectionIndexesForProposedSelection is faster than shouldSelectRow
        if (_delegateSelectorsCache & _CPTableViewSelectionIndexesForProposedSelectionSelector)
            newSelection = [_delegate tableView:self selectionIndexesForProposedSelection:newSelection];
        else if (_delegateSelectorsCache & _CPTableViewShouldSelectRowSelector)
        {
            var indexes = [];
            [newSelection getIndexes:indexes maxCount:Number.MAX_VALUE inIndexRange:nil];
            for (var i = 0; i < indexes.length; i++)
                if (![_delegate tableView:self shouldSelectRow:indexes[i]])
                    [newSelection removeIndex:indexes[i]];
        }
    }
    
    // if empty selection is not allowed and the new selection has nothing selected, abort
    if (!_allowsEmptySelection && [newSelection count] === 0)
        return;
    
    // if the new selection is *still* different, and update the selection and send a notification
    if (![newSelection isEqualToIndexSet:_selectedRowIndexes])
    {
        [self selectRowIndexes:newSelection byExtendingSelection:NO];
        [[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewSelectionIsChangingNotification object:self userInfo:nil];
    }
}

/*
    @ignore
*/
- (void)mouseDown:(CPEvent)anEvent
{
    [self trackSelection:anEvent];
}

/*
    Sets the message to be sent to the target when a cell is double clicked
    @param aSelector the selector to be performed
*/
- (void)setDoubleAction:(SEL)aSelector
{
    _doubleAction = aSelector;
}
- (SEL)doubleAction
{
    return _doubleAction;
}

- (int)clickedColumn
{
    return _clickedColumn;
}
- (int)clickedRow
{
    return _clickedRow;
}

/*
    @ignore
*/
- (void)trackSelection:(CPEvent)anEvent
{
    var type = [anEvent type],
        point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        currentRow = MAX(0, MIN(_numberOfRows-1, [self _rowAtY:point.y]));
    
    if (type == CPLeftMouseUp)
    {
        _clickedRow = [self rowAtPoint:point];
        _clickedColumn = [self columnAtPoint:point];
        
        if ([anEvent clickCount] === 2)
        {
            CPLog.warn("edit?!");
            
            [self sendAction:_doubleAction to:_target];
        }
        else
        {
            if (![_previousSelectedRowIndexes isEqualToIndexSet:_selectedRowIndexes])
            {
                [[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewSelectionDidChangeNotification object:self userInfo:nil];
            }
            
            [self sendAction:_action to:_target];
        }
        
        return;
    }
    
    if (type == CPLeftMouseDown)
    {
        _previousSelectedRowIndexes = _selectedRowIndexes;
        _selectionModifier = [anEvent modifierFlags];
        
        if (_selectionModifier & CPShiftKeyMask)
            _selectionStartRow = (ABS([_previousSelectedRowIndexes firstIndex] - currentRow) < ABS([_previousSelectedRowIndexes lastIndex] - currentRow)) ?
                [_previousSelectedRowIndexes firstIndex] : [_previousSelectedRowIndexes lastIndex];
        else
            _selectionStartRow = currentRow;
        
        [self _updateSelectionWithMouseAtRow:currentRow];
    }
    else if (type == CPLeftMouseDragged)
    {
        [self _updateSelectionWithMouseAtRow:currentRow];
    }
    
    [CPApp setTarget:self selector:@selector(trackSelection:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

/*
    @ignore
*/
- (void)_drawSelection
{
    if (!_currentlySelected) {
        _currentlySelected  = [CPIndexSet indexSet];
        _selectionViews     = [];
        _selectionViewsPool = [];
    }

    // TODO: we could also remove selections that aren't visible, but then we'll need to run this on every scroll/resize?
    
    // get array of indexes we can remove
    var removeSet = [_currentlySelected copy],
        indexesToRemove = [];
    [removeSet removeIndexes:_selectedRowIndexes];
    [removeSet getIndexes:indexesToRemove maxCount:Number.MAX_VALUE inIndexRange:nil];
    
    // get array of indexes we need to add
    var addSet = [_selectedRowIndexes copy],
        indexesToAdd = [];
    [addSet removeIndexes:_currentlySelected];
    [addSet getIndexes:indexesToAdd maxCount:Number.MAX_VALUE inIndexRange:nil];
    
    for (var i = 0; i < indexesToRemove.length; i++)
    {
        var row = indexesToRemove[i];
        for (var column = 0; column < _numberOfColumns; column++)
            if ([_tableCells[column][row] respondsToSelector:@selector(highlight:)])
                [_tableCells[column][row] highlight:NO];
    }
    for (var i = 0; i < indexesToAdd.length; i++)
    {
        var row = indexesToAdd[i];
        for (var column = 0; column < _numberOfColumns; column++)
            if ([_tableCells[column][row] respondsToSelector:@selector(highlight:)])
                [_tableCells[column][row] highlight:YES];
    }

    // add each one we need to add, taking the selection views from removed seelctions, the pool, or new
    for (var i = 0; i < indexesToAdd.length; i++)
    {
        var index = indexesToAdd[i],
            view;
            
        if (indexesToRemove.length > 0)
        {
            view = _selectionViews[indexesToRemove.pop()];
        }
        else if (_selectionViewsPool.length > 0)
        {
            view = _selectionViewsPool.pop();
            [self addSubview:view positioned:CPWindowBelow relativeTo:nil];
        }
        else
        {
            view = [[CPView alloc] init];
            [view setBackgroundColor:[CPColor alternateSelectedControlColor]];
            
            [self addSubview:view positioned:CPWindowBelow relativeTo:nil];
        }
        
        _selectionViews[index] = view;
        
        var frame = [self rectOfRow:index];
        frame.size.height += _intercellSpacing.height - 1;
        //frame.size.width += 500;
        
        [view setFrame:frame];
    }
    
    // remove any selections that weren't already reused
    for (var i = 0; i < indexesToRemove.length; i++)
    {
        var row = indexesToRemove[i],
            view = _selectionViews[row];
        
        [view removeFromSuperview];
        _selectionViewsPool.push(view);
    }
    
    // update the currently selected index set
    _currentlySelected = [_selectedRowIndexes copy];
}

@end


var CPTableViewDataSourceKey        = @"CPTableViewDataSourceKey",
    CPTableViewDelegateKey          = @"CPTableViewDelegateKey",
    CPTableViewHeaderViewKey        = @"CPTableViewHeaderViewKey",
    CPTableViewTableColumnsKey      = @"CPTableViewTableColumnsKey",
    CPTableViewRowHeightKey         = @"CPTableViewRowHeightKey",
    CPTableViewIntercellSpacingKey  = @"CPTableViewIntercellSpacingKey",
    CPTableViewMultipleSelectionKey = @"CPTableViewMultipleSelectionKey",
    CPTableViewEmptySelectionKey    = @"CPTableViewEmptySelectionKey";

@implementation CPTableView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        
        _dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        _delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];
        
        _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey];
        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey];
    
        _allowsMultipleSelection = [aCoder decodeBoolForKey:CPTableViewMultipleSelectionKey];
        _allowsEmptySelection = [aCoder decodeBoolForKey:CPTableViewEmptySelectionKey];
        
        var tableColumns = [aCoder decodeObjectForKey:CPTableViewTableColumnsKey];
        for (var i = 0; i < tableColumns.length; i++)
            [self addTableColumn:tableColumns[i]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_dataSource forKey:CPTableViewDataSourceKey];
    [aCoder encodeObject:_delegate forKey:CPTableViewDelegateKey];
    
    [aCoder encodeObject:_tableColumns forKey:CPTableViewTableColumnsKey];
    
    [aCoder encodeFloat:_rowHeight forKey:CPTableViewRowHeightKey];
    [aCoder encodeSize:_intercellSpacing forKey:CPTableViewIntercellSpacingKey];
    
    [aCoder encodeBool:_allowsMultipleSelection forKey:CPTableViewMultipleSelectionKey];
    [aCoder encodeBool:_allowsEmptySelection forKey:CPTableViewEmptySelectionKey];
}

@end



@implementation CPColor (TableView)

+ (CPColor)alternateSelectedControlColor
{
    return [[CPColor alloc] _initWithRGBA:[0.22, 0.46, 0.84, 1.0]];
}

+ (CPColor)secondarySelectedControlColor
{
    return [[CPColor alloc] _initWithRGBA:[0.83, 0.83, 0.83, 1.0]];
}

@end