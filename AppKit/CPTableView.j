/*
 * CPTableView.j
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

@import <Foundation/CPArray.j>

@import "CPControl.j"
@import "CPTableColumn.j"
@import "_CPCornerView.j"
@import "CPScroller.j"


CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";

#include "CoreGraphics/CGGeometry.h"

var CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2,

    CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_                                       = 1 << 3,
    CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_ = 1 << 4,
    CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_                     = 1 << 5,
    CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_                                  = 1 << 6,

    CPTableViewDataSource_tableView_sortDescriptorsDidChange_                                           = 1 << 7;

var CPTableViewDelegate_selectionShouldChangeInTableView_                                               = 1 << 0,
    CPTableViewDelegate_tableView_dataViewForTableColumn_row_                                           = 1 << 1,
    CPTableViewDelegate_tableView_didClickTableColumn_                                                  = 1 << 2,
    CPTableViewDelegate_tableView_didDragTableColumn_                                                   = 1 << 3,
    CPTableViewDelegate_tableView_heightOfRow_                                                          = 1 << 4,
    CPTableViewDelegate_tableView_isGroupRow_                                                           = 1 << 5,
    CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_                                       = 1 << 6,
    CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_                           = 1 << 7,
    CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_                                 = 1 << 8,
    CPTableViewDelegate_tableView_shouldEditTableColumn_row_                                            = 1 << 9,
    CPTableViewDelegate_tableView_shouldSelectRow_                                                      = 1 << 10,
    CPTableViewDelegate_tableView_shouldSelectTableColumn_                                              = 1 << 11,
    CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_                            = 1 << 12,
    CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_                                   = 1 << 13,
    CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_                     = 1 << 14,
    CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_                    = 1 << 15,
    CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_                                   = 1 << 16,
    CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_                                   = 1 << 17,
    CPTableViewDelegate_tableViewSelectionDidChange_                                                    = 1 << 18,
    CPTableViewDelegate_tableViewSelectionIsChanging_                                                   = 1 << 19;

// TODO: add docs

CPTableViewSelectionHighlightStyleRegular = 0;
CPTableViewSelectionHighlightStyleSourceList = 1;

CPTableViewGridNone                    = 0;
CPTableViewSolidVerticalGridLineMask   = 1 << 0;
CPTableViewSolidHorizontalGridLineMask = 1 << 1;


#define NUMBER_OF_COLUMNS() (_tableColumns.length)
#define UPDATE_COLUMN_RANGES_IF_NECESSARY() if (_dirtyTableColumnRangeIndex !== CPNotFound) [self _recalculateTableColumnRanges];

@implementation _CPTableDrawView : CPView
{
    CPTableView _tableView;
}

- (id)initWithTableView:(CPTableView)aTableView
{
    self = [super init];

    if (self)
        _tableView = aTableView;

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var frame = [self frame],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextTranslateCTM(context, -_CGRectGetMinX(frame), -_CGRectGetMinY(frame));

    [_tableView _drawRect:aRect];
}

@end

@implementation CPTableView : CPControl
{
    id          _dataSource;
    CPInteger   _implementedDataSourceMethods;

    id          _delegate;
    CPInteger   _implementedDelegateMethods;

    CPArray     _tableColumns;
    CPArray     _tableColumnRanges;
    CPInteger   _dirtyTableColumnRangeIndex;
    CPInteger   _numberOfHiddenColumns;

    BOOL        _reloadAllRows;
    Object      _objectValues;
    CPRange     _exposedRows;
    CPIndexSet  _exposedColumns;

    Object      _dataViewsForTableColumns;
    Object      _cachedDataViews;

    //Configuring Behavior
    BOOL        _allowsColumnReordering;
    BOOL        _allowsColumnResizing;
    BOOL        _allowsMultipleSelection;
    BOOL        _allowsEmptySelection;

    //Setting Display Attributes
    CGSize		_intercellSpacing;
    float       _rowHeight;

    BOOL        _usesAlternatingRowBackgroundColors;
    CPArray     _alternatingRowBackgroundColors;

    unsigned    _selectionHighlightMask;
    unsigned    _currentHighlightedTableColumn;
    unsigned    _gridStyleMask;
    CPColor     _gridColor;

    unsigned    _numberOfRows;


    CPTableHeaderView _headerView;
    _CPCornerView     _cornerView;

    CPIndexSet  _selectedColumnIndexes;
    CPIndexSet  _selectedRowIndexes;
    CPInteger   _selectionAnchorRow;

    _CPTableDrawView _tableDrawView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        //Configuring Behavior
        _allowsColumnReordering = YES;
        _allowsColumnResizing = YES;
        _allowsMultipleSelection = NO;
        _allowsEmptySelection = YES;
        _allowsColumnSelection = NO;

        _tableViewFlags = 0;

        //Setting Display Attributes
        _selectionHighlightMask = CPTableViewSelectionHighlightStyleRegular;

        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setAlternatingRowBackgroundColors:[[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]]];

        _tableColumns = [];
        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = CPNotFound;
        _numberOfHiddenColumns = 0;

        _objectValues = { };
        _dataViewsForTableColumns = { };
        _dataViews=  [];
        _numberOfRows = 0;
        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];
        _cachedDataViews = { };
        _intercellSpacing = _CGSizeMake(0.0, 0.0);
        _rowHeight = 19.0;

        [self setGridColor:[CPColor grayColor]];
        [self setGridStyleMask:CPTableViewGridNone];

        _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        _cornerView = [[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];

        _selectedColumnIndexes = [CPIndexSet indexSet];
        _selectedRowIndexes = [CPIndexSet indexSet];

        _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
        [_tableDrawView setBackgroundColor:[CPColor clearColor]];
        [self addSubview:_tableDrawView];

    }

    return self;
}

- (void)setDataSource:(id)aDataSource
{
    if (_dataSource === aDataSource)
        return;

    _dataSource = aDataSource;
    _implementedDataSourceMethods = 0;

    if (!_dataSource)
        return;

    if (![_dataSource respondsToSelector:@selector(numberOfRowsInTableView:)])
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement numberOfRowsInTableView:."];

    if (![_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement tableView:objectValueForTableColumn:row:"];

    if ([_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_;

    if ([_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:namesOfPromisedFilesDroppedAtDestination:forDraggedRowsWithIndexes:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_;

    if ([_dataSource respondsToSelector:@selector(tableView:validateDrop:proposedRow:proposedDropOperation:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:writeRowsWithIndexes:toPasteboard:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_;

    [self reloadData];
}

- (id)dataSource
{
    return _dataSource;
}

//Loading Data

- (void)reloadDataForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self reloadData];
//    [_previouslyExposedRows removeIndexes:rowIndexes];
//    [_previouslyExposedColumns removeIndexes:columnIndexes];
}


- (void)reloadData
{
    if (!_dataSource)
        return;

    _reloadAllRows = YES;
    _objectValues = { };

    // This updates the size too.
    [self noteNumberOfRowsChanged];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

//Target-action Behavior

- (void)setDoubleAction:(SEL)anAction
{
    _doubleAction = anAction;
}

- (SEL)doubleAction
{
    return _doubleAction;
}

/*
    * - clickedColumn
    * - clickedRow
*/
//Configuring Behavior

- (void)setAllowsColumnReordering:(BOOL)shouldAllowColumnReordering
{
    _allowsColumnReordering = !!shouldAllowColumnReordering;
}

- (BOOL)allowsColumnReordering
{
    return _allowsColumnReordering;
}

- (void)setAllowsColumnResizing:(BOOL)shouldAllowColumnResizing
{
    _allowsColumnResizing = !!shouldAllowColumnResizing;
}

- (BOOL)allowsColumnResizing
{
    return _allowsColumnResizing;
}

- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    _allowsMultipleSelection = !!shouldAllowMultipleSelection;
}

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setAllowsEmptySelection:(BOOL)shouldAllowEmptySelection
{
    _allowsEmptySelection = !!shouldAllowEmptySelection;
}

- (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

- (void)setAllowsColumnSelection:(BOOL)shouldAllowColumnSelection
{
    _allowsColumnSelection = !!shouldAllowColumnSelection;
}

- (BOOL)allowsColumnSelection
{
    return _allowsColumnSelection;
}

//Setting Display Attributes

- (void)setIntercellSpacing:(CGSize)aSize
{
    if (_CGSizeEqualToSize(_intercellSpacing, aSize))
        return;

    _intercellSpacing = _CGSizeMakeCopy(aSize);

    [self setNeedsLayout];
}

- (void)setThemeState:(int)astae
{
}

- (CGSize)intercellSpacing
{
    return _CGSizeMakeCopy(_intercellSpacing);
}

- (void)setRowHeight:(unsigned)aRowHeight
{
    aRowHeight = +aRowHeight;

    if (_rowHeight === aRowHeight)
        return;

    _rowHeight = MAX(0.0, aRowHeight);

    [self setNeedsLayout];
}

- (unsigned)rowHeight
{
    return _rowHeight;
}

- (void)setUsesAlternatingRowBackgroundColors:(BOOL)shouldUseAlternatingRowBackgroundColors
{
    // TODO:need to look at how one actually sets the alternating row, a tip at: 
    // http://forums.macnn.com/79/developer-center/228347/nstableview-alternating-row-colors/
    // otherwise this may not be feasible or may introduce an additional change req'd in CP
    // we'd probably need to iterate through rowId % 2 == 0 and setBackgroundColor with 
    // whatever the alternating row color is.
    _usesAlternatingRowBackgroundColors = shouldUseAlternatingRowBackgroundColors;
}

- (BOOL)usesAlternatingRowBackgroundColors
{
    return _usesAlternatingRowBackgroundColors;
}

- (void)setAlternatingRowBackgroundColors:(CPArray)alternatingRowBackgroundColors
{
    if ([_alternatingRowBackgroundColors isEqual:alternatingRowBackgroundColors])
        return;

    _alternatingRowBackgroundColors = alternatingRowBackgroundColors;

    [self setNeedsDisplay:YES];
}

- (CPArray)alternatingRowBackgroundColors
{
    return _alternatingRowBackgroundColors;
}

- (unsigned)selectionHighlightStyle
{
    return _selectionHighlightMask;
}

- (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    _selectionHighlightMask = aSelectionHighlightStyle;
}

/*
    * - indicatorImageInTableColumn:
    * - setIndicatorImage:inTableColumn:
*/

- (void)setGridColor:(CPColor)aColor
{
    if (_gridColor === aColor)
        return;

    _gridColor = aColor;

    [self setNeedsDisplay:YES];
}

- (CPColor)gridColor
{
    return _gridColor;
}

- (void)setGridStyleMask:(unsigned)aGrideStyleMask
{
    if (_gridStyleMask === aGrideStyleMask)
        return;

    _gridStyleMask = aGrideStyleMask

    [self setNeedsDisplay:YES];
}

- (unsigned)gridStyleMask
{
    return _gridStyleMask;
}

//Column Management

- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    [_tableColumns addObject:aTableColumn];
    [aTableColumn setTableView:self];

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = NUMBER_OF_COLUMNS() - 1;
    else
        _dirtyTableColumnRangeIndex = MIN(NUMBER_OF_COLUMNS() - 1, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    if ([aTableColumn tableView] !== self)
        return;

    var index = [_tableColumns indexOfObjectIdenticalTo:aTableColumn];

    if (index === CPNotFound)
        return;

    [aTableColumn setTableView:nil];
    [_tableColumns removeObjectAtIndex:index];

    var tableColumnUID = [aTableColumn UID];

    if (_objectValues[tableColumnUID])
        _objectValues[tableColumnUID] = nil;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = index;
    else
        _dirtyTableColumnRangeIndex = MIN(index, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)moveColumn:(unsigned)fromIndex toColumn:(unsigned)toIndex
{
    fromIndex = +fromIndex;
    toIndex = +toIndex;

    if (fromIndex === toIndex)
        return;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex);
    else
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex, _dirtyTableColumnRangeIndex);

    if (toIndex > fromIndex)
        --toIndex;

    var tableColumn = _tableColumns[fromIndex];

    [_tableColumns removeObjectAtIndex:fromIndex];
    [_tableColumns insertObject:tableColumn atIndex:toIndex];

    [self setNeedsLayout];
}

- (CPArray)tableColumns
{
    return _tableColumns;
}

- (CPInteger)columnWithIdentifier:(CPString)anIdentifier
{
    var index = 0,
        count = NUMBER_OF_COLUMNS();

    for (; index < count; ++index)
        if ([_tableColumns identifier] === anIdentifier)
            return index;

    return CPNotFound;
}

- (CPTableColumn)tableColumnWithIdentifier:(CPString)anIdentifier
{
    var index = [self columnWithIdentifier:anIdentifier];

    if (index === CPNotFound)
        return nil;

    return _tableColumns[index];
}

//Selecting Columns and Rows
- (void)selectColumnIndexes:(CPIndexSet)columns byExtendingSelection:(BOOL)shouldExtendSelection
{
    // We deselect all columns when selecting rows.
    _selectedRowIndexes = [CPIndexSet indexSet];

    if (shouldExtendSelection)
        [_selectedColumnIndexes addIndexes:columns];
    else
        _selectedColumnIndexes = [columns copy];

    [self setNeedsLayout];
}

- (void)selectRowIndexes:(CPIndexSet)rows byExtendingSelection:(BOOL)shouldExtendSelection
{
    // We deselect all rows when selecting columns.
    _selectedColumnIndexes = [CPIndexSet indexSet];

    if (shouldExtendSelection)
        [_selectedRowIndexes addIndexes:rows];
    else
        _selectedRowIndexes = [rows copy];

    [self setNeedsLayout];
}

- (CPIndexSet)selectedColumnIndexes
{
    return _selectedColumnIndexes;
}

- (void)selectedRowIndexes
{
    return _selectedRowIndexes;
}

- (void)deselectColumn:(CPInteger)aColumn
{
    [_selectedColumnIndexes removeIndex:aColumn];
}

- (void)deselectRow:(CPInteger)aRow
{
    [_selectedRowIndexes removeIndex:aRow];
}

- (CPInteger)numberOfSelectedColumns
{
    return [_selectedColumnIndexes count];
}

- (CPInteger)numberOfSelectedRows
{
    return [_selectedRowIndexes count];
}

/*
- (CPInteger)selectedColumn
    * - selectedRow
*/

- (BOOL)isColumnSelected:(CPInteger)aColumn
{
    return [_selectedColumnIndexes containsIndex:aColumn];
}

- (BOOL)isRowSelected:(CPInteger)aRow
{
    return [_selectedRowIndexes containsIndex:aRow];
}
/*
- (void)selectAll:
    * - deselectAll:
    * - allowsTypeSelect
    * - setAllowsTypeSelect:
*/
//Table Dimensions

- (int)numberOfColumns
{
    return NUMBER_OF_COLUMNS();
}

/*
    Returns the number of rows in the receiver.
*/
- (int)numberOfRows
{
    if (!_dataSource)
        return 0;

    return [_dataSource numberOfRowsInTableView:self];
}

//Displaying Cell
/*
    * - preparedCellAtColumn:row:
*/
//Editing Cells
/*
    * - editColumn:row:withEvent:select:
    * - editedColumn
    * - editedRow
*/
//Setting Auxiliary Views
/*
    * - setHeaderView:
    * - headerView
    * - setCornerView:
    * - cornerView
*/

- (CPView)cornerView
{
    return _cornerView;
}

- (void)setCornerView:(CPView)aView
{
    if (_cornerView === aView)
        return;

    _cornerView = aView;

    var scrollView = [[self superview] superview];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

- (CPView)headerView
{
    return _headerView;
}

- (void)setHeaderView:(CPView)aHeaderView
{
    if (_headerView === aHeaderView)
        return;

    [_headerView setTableView:nil];

    _headerView = aHeaderView;

    if (_headerView)
    {
        [_headerView setTableView:self];
        [_headerView setFrameSize:_CGSizeMake(_CGRectGetWidth([self frame]), _CGRectGetHeight([_headerView frame]))];
    }

    var scrollView = [[self superview] superview];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

//Layout Support

// Complexity:
// O(Columns)
- (void)_recalculateTableColumnRanges
{
    if (_dirtyTableColumnRangeIndex < 0)
        return;

    var index = _dirtyTableColumnRangeIndex,
        count = NUMBER_OF_COLUMNS(),
        x = index === 0 ? 0.0 : CPMaxRange(_tableColumnRanges[index - 1]);

    for (; index < count; ++index)
    {
        var tableColumn = _tableColumns[index];

        if ([tableColumn isHidden])
            _tableColumnRanges[index] = CPMakeRange(x, 0.0);

        else
        {
            var width = [_tableColumns[index] width];

            _tableColumnRanges[index] = CPMakeRange(x, width);

            x += width;
        }
    }

    _tableColumnRanges.length = count;
    _dirtyTableColumnRangeIndex = CPNotFound;
}

// Complexity:
// O(1)
- (CGRect)rectOfColumn:(CPInteger)aColumnIndex
{
    aColumnIndex = +aColumnIndex;

    if (aColumnIndex < 0 || aColumnIndex >= NUMBER_OF_COLUMNS())
        return _CGRectMakeZero();

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var range = _tableColumnRanges[aColumnIndex];

    return _CGRectMake(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}

- (CGRect)rectOfRow:(CPInteger)aRowIndex
{
    if (NO)
        return NULL;

    // FIXME: WRONG: ASK TABLE COLUMN RANGE
    return _CGRectMake(0.0, (aRowIndex * (_rowHeight + _intercellSpacing.height)), _CGRectGetWidth([self bounds]), _rowHeight);
}

// Complexity:
// O(1)
- (CPRange)rowsInRect:(CGRect)aRect
{
    // If we have no rows, then we won't intersect anything.
    if (_numberOfRows <= 0)
        return CPMakeRange(0, 0);

    var bounds = [self bounds];

    // No rows if the rect doesn't even intersect us.
    if (!CGRectIntersectsRect(aRect, bounds))
        return CPMakeRange(0, 0);

    var firstRow = [self rowAtPoint:aRect.origin];

    // first row has to be undershot, because if not we wouldn't be intersecting.
    if (firstRow < 0)
        firstRow = 0;

    var lastRow = [self rowAtPoint:_CGPointMake(0.0, _CGRectGetMaxY(aRect))];

    // last row has to be overshot, because if not we wouldn't be intersecting.
    if (lastRow < 0)
        lastRow = _numberOfRows - 1;

    return CPMakeRange(firstRow, lastRow - firstRow + 1);
}

// Complexity:
// O(lg Columns) if table view contains no hidden columns
// O(Columns) if table view contains hidden columns
- (CPIndexSet)columnIndexesInRect:(CGRect)aRect
{
    var column = MAX(0, [self columnAtPoint:_CGPointMake(aRect.origin.x, 0.0)]),
        lastColumn = [self columnAtPoint:_CGPointMake(_CGRectGetMaxX(aRect), 0.0)];

    if (lastColumn === CPNotFound)
        lastColumn = NUMBER_OF_COLUMNS() - 1;

    // Don't bother doing the expensive removal of hidden indexes if we have no hidden columns.
    if (_numberOfHiddenColumns <= 0)
        return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(column, lastColumn - column + 1)];

    // 
    var indexSet = [CPIndexSet indexSet];

    for (; column <= lastColumn; ++column)
    {
        var tableColumn = _tableColumns[column];

        if (![tableColumn isHidden])
            [indexSet addIndex:column];
    }

    return indexSet;
}

// Complexity:
// O(lg Columns) if table view contains now hidden columns
// O(Columns) if table view contains hidden columns
- (CPInteger)columnAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds];

    if (!_CGRectContainsPoint(bounds, aPoint))
        return CPNotFound;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var x = aPoint.x,
        low = 0,
        high = _tableColumnRanges.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            range = _tableColumnRanges[middle];

        if (x < range.location)
            high = middle - 1;

        else if (x >= CPMaxRange(range))
            low = middle + 1;

        else
        {
            var numberOfColumns = _tableColumnRanges.length;

            while (middle < numberOfColumns && [_tableColumns[middle] isHidden])
                ++middle;

            if (middle < numberOfColumns)
                return middle;

            return CPNotFound;
        }
   }

   return CPNotFound;
}

- (CPInteger)rowAtPoint:(CGPoint)aPoint
{
    var y = aPoint.y;

    if (NO)
    {
    }

    var row = FLOOR(y / (_rowHeight + _intercellSpacing.height));

    if (row >= _numberOfRows)
        return -1;

    return row;
}

- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var tableColumnRange = _tableColumnRanges[aColumn],
        rectOfRow = [self rectOfRow:aRow];

    return _CGRectMake(tableColumnRange.location, _CGRectGetMinY(rectOfRow), tableColumnRange.length, _CGRectGetHeight(rectOfRow));
}
/*
    * - columnAutoresizingStyle
    * - setColumnAutoresizingStyle:
*/
- (void)sizeLastColumnToFit
{
    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS();

    while (count-- && [_tableColumns[count] isHidden]) ;

    if (count >= 0)
        [_tableColumns[count] setWidth:MAX(0.0, superviewSize.width - _CGRectGetMinX([self rectOfColumn:count]))];

    [self setNeedsLayout];
}

- (void)noteNumberOfRowsChanged
{
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    [self tile];
}

- (void)tile
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    // FIXME: variable row heights.
    var width = _tableColumnRanges.length > 0 ? CPMaxRange([_tableColumnRanges lastObject]) : 0.0,
        height = (_rowHeight + _intercellSpacing.height) * _numberOfRows,
        superview = [self superview];

    if ([superview isKindOfClass:[CPClipView class]])
    {
        var superviewSize = [superview bounds].size;

        width = MAX(superviewSize.width, width);
        height = MAX(superviewSize.height, height);
    }

    [self setFrameSize:_CGSizeMake(width, height)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*
    * - tile
    * - sizeToFit
    * - noteHeightOfRowsWithIndexesChanged:
*/
//Scrolling
/*
    * - scrollRowToVisible:
    * - scrollColumnToVisible:
*/
//Persistence
/*
    * - autosaveName
    * - autosaveTableColumns
    * - setAutosaveName:
    * - setAutosaveTableColumns:
*/

//Setting the Delegate:(id)aDelegate

- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidMoveNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidResizeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionDidChangeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionIsChangingNotification
                        object:self];
    }

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(selectionShouldChangeInTableView:)])
        _implementedDelegateMethods |= CPTableViewDelegate_selectionShouldChangeInTableView_;

    if ([_delegate respondsToSelector:@selector(tableView:dataViewForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_dataViewForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:didClickTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_didClickTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:didDragTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_didDragTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:heightOfRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_heightOfRow_;

    if ([_delegate respondsToSelector:@selector(tableView:isGroupRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_isGroupRow_;

    if ([_delegate respondsToSelector:@selector(tableView:mouseDownInHeaderOfTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:nextTypeSelectMatchFromRow:toRow:forString:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_;

    if ([_delegate respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldEditTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldEditTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldSelectRow_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldSelectTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldShowViewExpansionForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldTrackView:forTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldTypeSelectForEvent:withCurrentSearchString:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_;

    if ([_delegate respondsToSelector:@selector(tableView:toolTipForView:rect:tableColumn:row:mouseLocation:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_;

    if ([_delegate respondsToSelector:@selector(tableView:typeSelectStringForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:willDisplayView:forTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidMove:)
            name:CPTableViewColumnDidMoveNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidMove:)
            name:CPTableViewColumnDidResizeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionDidChange:)
            name:CPTableViewSelectionDidChangeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionIsChanging:)
            name:CPTableViewSelectionIsChangingNotification
            object:self];
}

- (id)delegate
{
    return _delegate;
}

//Highlightable Column Headers
/*
- (CPTableColumn)highlightedTableColumn
{

}

    * - setHighlightedTableColumn:
*/
//Dragging
/*
    * - dragImageForRowsWithIndexes:tableColumns:event:offset:
    * - canDragRowsWithIndexes:atPoint:
    * - setDraggingSourceOperationMask:forLocal:
    * - setDropRow:dropOperation:
    * - setVerticalMotionCanBeginDrag:
    * - verticalMotionCanBeginDrag
*/
//Sorting
/*
    * - setSortDescriptors:
    * - sortDescriptors
*/

//Text Delegate Methods
/*
    * - textShouldBeginEditing:
    * - textDidBeginEditing:
    * - textDidChange:
    * - textShouldEndEditing:
    * - textDidEndEditing:
*/

- (id)_objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    var tableColumnUID = [aTableColumn UID],
        tableColumnObjectValues = _objectValues[tableColumnUID];

    if (!tableColumnObjectValues)
    {
        tableColumnObjectValues = [];
        _objectValues[tableColumnUID] = tableColumnObjectValues;
    }

    var objectValue = tableColumnObjectValues[aRowIndex];

    if (objectValue === undefined)
    {
        objectValue = [_dataSource tableView:self objectValueForTableColumn:aTableColumn row:aRowIndex];
        tableColumnObjectValues[aRowIndex] = objectValue;
    }

    return objectValue;
}

- (CGRect)_exposedRect
{
    var superview = [self superview];

    if (![superview isKindOfClass:[CPClipView class]])
        return [self bounds];

    return [self convertRect:CGRectIntersection([superview bounds], [self frame]) fromView:superview];
}

- (void)load
{
//    if (!window.blah)
//        return window.setTimeout(function() { window.blah = true; [self load]; window.blah = false}, 0.0);

 //   if (window.console && window.console.profile)
 //       console.profile("cell-load");

    if (_reloadAllRows)
    {
        [self _unloadDataViewsInRows:_exposedRows columns:_exposedColumns];

        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];

        _reloadAllRows = NO;
    }

    var exposedRect = [self _exposedRect],
        exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:exposedRect]],
        exposedColumns = [self columnIndexesInRect:exposedRect],
        obscuredRows = [_exposedRows copy],
        obscuredColumns = [_exposedColumns copy];

    [obscuredRows removeIndexes:exposedRows];
    [obscuredColumns removeIndexes:exposedColumns];

    var newlyExposedRows = [exposedRows copy],
        newlyExposedColumns = [exposedColumns copy];

    [newlyExposedRows removeIndexes:_exposedRows];
    [newlyExposedColumns removeIndexes:_exposedColumns];

    var previouslyExposedRows = [exposedRows copy],
        previouslyExposedColumns = [exposedColumns copy];

    [previouslyExposedRows removeIndexes:newlyExposedRows];
    [previouslyExposedColumns removeIndexes:newlyExposedColumns];

//    console.log("will remove:" + '\n\n' + 
//        previouslyExposedRows + "\n" + obscuredColumns + "\n\n" +
//        obscuredRows + "\n" + previouslyExposedColumns + "\n\n" +
//        obscuredRows + "\n" + obscuredColumns);
    [self _unloadDataViewsInRows:previouslyExposedRows columns:obscuredColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:previouslyExposedColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:obscuredColumns];

    [self _loadDataViewsInRows:previouslyExposedRows columns:newlyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:previouslyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];

//    console.log("newly exposed rows: " + newlyExposedRows + "\nnewly exposed columns: " + newlyExposedColumns);
    _exposedRows = exposedRows;
    _exposedColumns = exposedColumns;

    [_tableDrawView setFrame:exposedRect];

//    [_tableDrawView setBounds:exposedRect];
    [_tableDrawView display];

    // Now clear all the leftovers
    // FIXME: this could be faster!
    for (identifier in _cachedDataViews)
    {
        var dataViews = _cachedDataViews[identifier],
            count = dataViews.length;

        while (count--)
            [dataViews[count] removeFromSuperview];
    }

  //  if (window.console && window.console.profile)
//        console.profileEnd("cell-load");
}

- (void)_unloadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    if (![rows count] || ![columns count])
        return;

    var rowArray = [],
        columnArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID];

        var rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = _dataViewsForTableColumns[tableColumnUID][row];

            _dataViewsForTableColumns[tableColumnUID][row] = nil;

            [self _enqueueReusableDataView:dataView];
        }
    }
}

- (void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    if (![rows count] || ![columns count])
        return;

    var rowArray = [],
        rowRects = [],
        columnArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID];

    if (!_dataViewsForTableColumns[tableColumnUID])
        _dataViewsForTableColumns[tableColumnUID] = [];

        var rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = [self _newDataViewForRow:row tableColumn:tableColumn];

            [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            _dataViewsForTableColumns[tableColumnUID][row] = dataView;
        }
    }
}

- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    return [aTableColumn _newDataViewForRow:aRow];
}

- (void)_enqueueReusableDataView:(CPView)aDataView
{
    // FIXME: yuck!
    var identifier = aDataView.identifier;

    if (!_cachedDataViews[identifier])
        _cachedDataViews[identifier] = [aDataView];
    else
        _cachedDataViews[identifier].push(aDataView);
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    if (_headerView)
        [_headerView setFrameSize:_CGSizeMake(_CGRectGetWidth([self frame]), _CGRectGetHeight([_headerView frame]))];
}

- (CGRect)exposedClipRect
{
    var superview = [self superview];

    if (![superview isKindOfClass:[CPClipView class]])
        return [self bounds];

    return [self convertRect:CGRectIntersection([superview bounds], [self frame]) fromView:superview];
}

- (void)_drawRect:(CGRect)aRect
{
    var exposedRect = [self _exposedRect];

    [self drawBackgroundInClipRect:exposedRect];
    [self highlightSelectionInClipRect:exposedRect];
    [self drawGridInClipRect:exposedRect];
}

- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    if (![self usesAlternatingRowBackgroundColors])
        return;

    var rowColors = [self alternatingRowBackgroundColors],
        colorCount = [rowColors count];

    if (colorCount === 0)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    if (colorCount === 1)
    {
        CGContextSetFillColor(context, rowColors[0]);
        CGContextFillRect(context, aRect);

	    return;
    }
    // CGContextFillRect(context, CGRectIntersection(aRect, fillRect));
    // console.profile("row-paint");
    var exposedRows = [self rowsInRect:aRect],
        firstRow = exposedRows.location,
        lastRow = CPMaxRange(exposedRows) - 1,
        colorIndex = MIN(exposedRows.length, colorCount),
        heightFilled = 0.0;

    while (colorIndex--)
    {
        var row = firstRow % colorCount + firstRow + colorIndex,
            fillRect = nil;

        CGContextBeginPath(context);

        for (; row <= lastRow; row += colorCount)
            CGContextAddRect(context, CGRectIntersection(aRect, fillRect = [self rectOfRow:row]));

        if (row - colorCount === lastRow)
            heightFilled = _CGRectGetMaxY(fillRect);

        CGContextClosePath(context);

        CGContextSetFillColor(context, rowColors[colorIndex]);
        CGContextFillPath(context);
    }
    // console.profileEnd("row-paint");

    var totalHeight = _CGRectGetMaxY(aRect);

    if (heightFilled >= totalHeight || _rowHeight <= 0.0)
        return;

    var rowHeight = _rowHeight + _intercellSpacing.height,
        fillRect = _CGRectMake(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect) + heightFilled, _CGRectGetWidth(aRect), rowHeight);

    for (row = lastRow + 1; heightFilled < totalHeight; ++row)
    {
        CGContextSetFillColor(context, rowColors[row % colorCount]);
        CGContextFillRect(context, fillRect);

        heightFilled += rowHeight;
        fillRect.origin.y += rowHeight;
    }
}

- (void)drawGridInClipRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        gridStyleMask = [self gridStyleMask];

    if (!(gridStyleMask & (CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask)))
        return;

    CGContextBeginPath(context);

    if (gridStyleMask & CPTableViewSolidHorizontalGridLineMask)
    {
        var exposedRows = [self rowsInRect:aRect];
            row = exposedRows.location,
            lastRow = CPMaxRange(exposedRows) - 1,
            rowY = 0.0,
            minX = _CGRectGetMinX(aRect),
            maxX = _CGRectGetMaxX(aRect);

        for (; row <= lastRow; ++row)
        {
            // grab each row rect and add the top and bottom lines
            var rowRect = [self rectOfRow:row],
                rowY = _CGRectGetMaxY(rowRect) - 0.5;

            CGContextMoveToPoint(context, minX, rowY);
            CGContextAddLineToPoint(context, maxX, rowY);
        }

        if (_rowHeight > 0.0)
        {
            var rowHeight = _rowHeight + _intercellSpacing.height,
                totalHeight = _CGRectGetMaxY(aRect);

            while (rowY < totalHeight)
            {
                rowY += rowHeight;

                CGContextMoveToPoint(context, minX, rowY);
                CGContextAddLineToPoint(context, maxX, rowY);
            }
        }
    }

    if (gridStyleMask & CPTableViewSolidVerticalGridLineMask)
    {
        var exposedColumnIndexes = [self columnIndexesInRect:aRect],
            columnsArray = [];

        [exposedColumnIndexes getIndexes:columnsArray maxCount:-1 inIndexRange:nil];

        var columnArrayIndex = 0,
            columnArrayCount = columnsArray.length,
            minY = _CGRectGetMinY(aRect),
            maxY = _CGRectGetMaxY(aRect);

        for (; columnArrayIndex < columnArrayCount; ++columnArrayIndex)
        {
            var columnRect = [self rectOfColumn:columnArrayIndex],
                columnX = _CGRectGetMaxX(columnRect) - 0.5;

            CGContextMoveToPoint(context, columnX, minY);
            CGContextAddLineToPoint(context, columnX, maxY);
        }
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, _gridColor);
    CGContextStrokePath(context);
}


- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    // FIXME: This color thingy is terrible probably.
    if ([self selectionHighlightStyle] === CPTableViewSelectionHighlightStyleSourceList)
        [[CPColor selectionColorSourceView] setFill];
	else
	   [[CPColor selectionColor] setFill];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        indexes = [],
        rectSelector = @selector(rectOfRow:);

    if ([_selectedRowIndexes count] >= 1)
    {
        var exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:aRect]],
            firstRow = [exposedRows firstIndex],
            exposedRange = CPMakeRange(firstRow, [exposedRows lastIndex] - firstRow + 1);

        [_selectedRowIndexes getIndexes:indexes maxCount:-1 inIndexRange:exposedRange];
    }

    else if ([_selectedColumnIndexes count] >= 1)
    {
        rectSelector = @selector(rectOfColumn:);

        var exposedColumns = [self columnIndexesInRect:aRect],
            firstColumn = [exposedColumns firstIndex],
            exposedRange = CPMakeRange(firstColumn, [exposedColumns lastIndex] - firstColumn + 1);

        [_selectedColumnIndexes getIndexes:indexes maxCount:-1 inIndexRange:exposedRange];
    }

    var count = [indexes count];

    if (!count)
        return;

    CGContextBeginPath(context);

    while (count--)
        CGContextAddRect(context, CGRectIntersection(objj_msgSend(self, rectSelector, indexes[count]), aRect));

    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)layoutSubviews
{
    [self load];
}

- (void)viewWillMoveToSuperview:(CPView)aView
{
    var superview = [self superview],
        defaultCenter = [CPNotificationCenter defaultCenter];

    if (superview)
    {
        [defaultCenter
            removeObserver:self
                      name:CPViewFrameDidChangeNotification
                    object:superview];

        [defaultCenter
            removeObserver:self
                      name:CPViewBoundsDidChangeNotification
                    object:superview];
    }

    if (aView)
    {
        [aView setPostsFrameChangedNotifications:YES];
        [aView setPostsBoundsChangedNotifications:YES];

        [defaultCenter
            addObserver:self
               selector:@selector(superviewFrameChanged:)
                   name:CPViewFrameDidChangeNotification
                 object:aView];

        [defaultCenter
            addObserver:self
               selector:@selector(superviewBoundsChanged:)
                   name:CPViewBoundsDidChangeNotification
                 object:aView];
    }
}

- (void)superviewBoundsChanged:(CPNotification)aNotification
{
    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (void)superviewFrameChanged:(CPNotification)aNotification
{
    [self tile];
}

//

/*
    var type = [anEvent type],
        point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        currentRow = MAX(0, MIN(_numberOfRows-1, [self _rowAtY:point.y]));

*/

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    if ([self mouseDownFlags] & CPShiftKeyMask)
        _selectionAnchorRow = (ABS([_selectedRowIndexes firstIndex] - row) < ABS([_selectedRowIndexes lastIndex] - row)) ?
            [_selectedRowIndexes firstIndex] : [_selectedRowIndexes lastIndex];
    else
        _selectionAnchorRow = row;

    _previouslySelectedRowIndexes = nil;

    [self _updateSelectionWithMouseAtRow:row];

    return YES;
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self _updateSelectionWithMouseAtRow:[self rowAtPoint:aPoint]];

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    if (![_previouslySelectedRowIndexes isEqualToIndexSet:_selectedRowIndexes])
        [self _noteSelectionDidChange];
}

- (void)_updateSelectionWithMouseAtRow:(CPInteger)aRow
{
    // If cmd/ctrl was held down XOR the old selection with the proposed selection
    if ([self mouseDownFlags] & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        if ([_selectedRowIndexes containsIndex:aRow])
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection removeIndex:aRow];
        }

        else if (_allowsMultipleSelection)
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection addIndex:aRow];
        }

        else
            newSelection = [CPIndexSet indexSetWithIndex:aRow];
    }

    else if (_allowsMultipleSelection)
        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionAnchorRow), ABS(aRow - _selectionAnchorRow) + 1)];

    else if (aRow >= 0 && aRow < _numberOfRows)
        newSelection = [CPIndexSet indexSetWithIndex:aRow];

    else
        newSelection = [CPIndexSet indexSet];

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ && 
        ![_delegate selectionShouldChangeInTableView:self])
        return;

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_)
        newSelection = [_delegate tableView:self selectionIndexesForProposedSelection:newSelection];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
    {
        var indexArray = [];

        [newSelection getIndexes:indexArray maxCount:-1 inIndexRange:nil];

        var indexCount = indexArray.length;

        while (indexCount--)
        {
            var index = indexArray[indexCount];

            if (![_delegate tableView:self shouldSelectRow:index])
                [newSelection removeIndex:index];
        }
    }

    // if empty selection is not allowed and the new selection has nothing selected, abort
    if (!_allowsEmptySelection && [newSelection count] === 0)
        return;

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    if (!_previouslySelectedRowIndexes)
        _previouslySelectedRowIndexes = [_selectedRowIndexes copy];

    [self selectRowIndexes:newSelection byExtendingSelection:NO];

    [self _noteSelectionIsChanging];
}

- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
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
    //FIXME:!!!!
    [self init];
    
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        _delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];
        
        _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey];
        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey];
    
        _allowsMultipleSelection = [aCoder decodeBoolForKey:CPTableViewMultipleSelectionKey];
        _allowsEmptySelection = [aCoder decodeBoolForKey:CPTableViewEmptySelectionKey];
        
        _tableColumns = [aCoder decodeObjectForKey:CPTableViewTableColumnsKey];

        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];
        _dirtyTableColumnRangeIndex = 0;

        [self viewWillMoveToSuperview:[self superview]];
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
    
    [aCoder encodeBool:_allowsMultipleSelection forKey:CPTableViewMultipleSelectionKey];
    [aCoder encodeBool:_allowsEmptySelection forKey:CPTableViewEmptySelectionKey];

    [aCoder encodeObject:_tableColumns forKey:CPTableViewTableColumnsKey];
}

@end

@implementation CPColor (tableview)

+ (CPColor)selectionColor
{
	return [CPColor colorWithHexString:@"5f83b9"];
}

+ (CPColor)selectionColorSourceView
{
	return [CPColor colorWithPatternImage:[[CPImage alloc] initByReferencingFile:@"Resources/tableviewselection.png" size:CGSizeMake(6,22)]];
}


@end