
@import <Foundation/CPArray.j>

@import "CPControl.j"
@import "CPTableColumn.j"
@import "_CPCornerView.j"
@import "CPScroller.j"

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
/*
CPTableViewSelectionHighlightStyleRegular = 0;
CPTableViewSelectionHighlightStyleSourceList = 1;
*/

#define NUMBER_OF_COLUMNS() (_tableColumns.length)

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

@implementation NEWCPTableView : CPControl
{
    id          _dataSource;
    CPInteger   _implementedDataSourceMethods;

    id          _delegate;
    CPInteger   _implementedDelegateMethods;

    CPArray     _tableColumns;
    CPArray     _tableColumnRanges;
    CPInteger   _dirtyTableColumnRangeIndex;
    CPInteger   _numberOfHiddenColumns;

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
    unsigned    _selectionHighlightMask;
    unsigned    _currentHighlightedTableColumn;

    unsigned    _numberOfRows;


    CPTableHeaderView _headerView;
    _CPCornerView     _cornerView;

    CPIndexSet  _selectedColumnIndexes;
    CPIndexSet  _selectedRowIndexes;
    CPInteger   _selectionStartRow;

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
//        _selectionHighlightMask = CPTableViewSelectionHighlightStyleRegular;

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
        _rowHeight = 24.0;

        _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        _cornerView = [[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];

        _selectedColumnIndexes = [CPIndexSet indexSet];
        _selectedRowIndexes = [CPIndexSet indexSet];

        _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
        [_tableDrawView setBackgroundColor:[CPColor yellowColor]];
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

- (void)reloadData
{
    if (!_dataSource)
        return;

    _objectValues = { };
    [self noteNumberOfRowsChanged];
[self _sizeToParent];
    [self layoutSubviews];
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

    _rowHeight = aRowHeight;

    [self setNeedsLayout];
}

- (unsigned)rowHeight
{
    return _rowHeight;
}
/*
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

- (unsigned)selectionHighlightStyle
{
    return _selectionHighlightMask;
}

- (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    _selectionHighlightMask = aSelectionHighlightStyle;
}

- setGridColor:


    * - gridColor
    * - setGridStyleMask:
    * - gridStyleMask
    * - indicatorImageInTableColumn:
    * - setIndicatorImage:inTableColumn:
*/
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

    var index = [_tableColumns indeOfObjectIdenticalTo:aTableColumn];

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
    _cornerView = aView;
}

- (CPView)headerView
{
    return _headerView;
}

- (void)setHeaderView:(CPView)aHeaderView
{
    _headerView = aHeaderView;
    [_headerView setTableView:self];
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

    if (_dirtyTableColumnRangeIndex !== CPNotFound)
        [self _recalculateTableColumnRanges];

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
    var bounds = nil,
        firstRow = [self rowAtPoint:aRect.origin],
        lastRow = [self rowAtPoint:_CGPointMake(0.0, _CGRectGetMaxY(aRect))];

    if (firstRow < 0)
    {
        bounds = [self bounds];

        if (_CGRectGetMinY(aRect) < _CGRectGetMinY(bounds))
            firstRow = 0;
        else
            firstRow = _numberOfRows - 1;
    }

    if (lastRow < 0)
    {
        if (!bounds)
            bounds = [self bounds];

        if (_CGRectGetMaxY(aRect) < _CGRectGetMinY(bounds))
            lastRow = 0;
        else
            lastRow = _numberOfRows - 1;
    }

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

    if (_dirtyTableColumnRangeIndex !== CPNotFound)
        [self _recalculateTableColumnRanges];

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

    return FLOOR(y / (_rowHeight + _intercellSpacing.height));
}

- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumnIndex row:(CPInteger)aRowIndex
{
    var tableColumnRange = _tableColumns[aColumnIndex],
        rectOfRow = [self rectOfRow:aRowIndex];

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

    if (_dirtyTableColumnRangeIndex !== CPNotFound)
        [self _recalculateTableColumnRanges];

    var count = NUMBER_OF_COLUMNS();

    while (count-- && [_tableColumns[count] isHidden]) ;

    if (count >= 0)
    {
        var difference = superviewSize.width - CPMaxRange(_tableColumnRanges[count]),
            tableColumn = _tableColumns[count];

        [tableColumn setWidth:MAX(0.0, [tableColumn width] + difference)];
    }

    [self setNeedsLayout];
}

- (void)noteNumberOfRowsChanged
{
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    [self setNeedsLayout];
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

- (void)_sizeToParent
{
    var superviewSize = [[self superview] bounds].size;

    if (_dirtyTableColumnRangeIndex !== CPNotFound)
        [self _recalculateTableColumnRanges];

    if (_tableColumnRanges.length > 0)
        var naturalWidth = CPMaxRange([_tableColumnRanges lastObject]);

    else
        var naturalWidth = 0.0;

    [self setFrameSize:_CGSizeMake( MAX(superviewSize.width, naturalWidth),
                                    MAX(superviewSize.height, (_rowHeight + _intercellSpacing.height) * _numberOfRows))];
}

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
    if (!_dataSource)
    {
        // remove?
        return;
    }

//    if (!window.blah)
//        return window.setTimeout(function() { window.blah = true; [self load]; window.blah = false}, 0.0);

    if (window.console && window.console.profile)
        console.profile("cell-load");

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

    if (window.console && window.console.profile)
        console.profileEnd("cell-load");
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
if (!_cachedDataViews[dataView.identifier])
_cachedDataViews[dataView.identifier] = [dataView];
else
_cachedDataViews[dataView.identifier].push(dataView);
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

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID],
            tableColumnRange = _tableColumnRanges[column];

    if (!_dataViewsForTableColumns[tableColumnUID])
        _dataViewsForTableColumns[tableColumnUID] = [];

        var rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = [tableColumn _newDataViewForRow:row],
                rectOfRow = rowRects[row];

            if (!rectOfRow)
                rectOfRow = rowRects[row] = [self rectOfRow:row];

            [dataView setFrame:_CGRectMake(tableColumnRange.location, _CGRectGetMinY(rectOfRow), tableColumnRange.length, _CGRectGetHeight(rectOfRow))];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            _dataViewsForTableColumns[tableColumnUID][row] = dataView;
        }
    }
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [_headerView setFrameSize:CGSizeMake(aSize.width, [_headerView frame].size.height)];
}

- (void)_drawRect:(CGRect)aRect
{
    [self highlightSelectionInClipRect:[self _exposedRect]];
}

- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    [[CPColor greenColor] set];

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    if ([_selectedRowIndexes count] >= 1)
    {
        var exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:aRect]],
            exposedRange = CPMakeRange([exposedRows firstIndex], [exposedRows lastIndex] - [exposedRows firstIndex] + 1),
            rowArray = [];

        [_selectedRowIndexes getIndexes:rowArray maxCount:-1 inIndexRange:exposedRange];

        var rowArrayIndex = 0,
            rowArrayCount = rowArray.length;

        for (; rowArrayIndex < rowArrayCount; ++rowArrayIndex)
            CGContextFillRect(context, [self rectOfRow:rowArray[rowArrayIndex]]);
    }
    else
    {

    }
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
    [self setNeedsLayout];
}

- (void)superviewFrameChanged:(CPNotification)aNotification
{
}

//

/*
    var type = [anEvent type],
        point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        currentRow = MAX(0, MIN(_numberOfRows-1, [self _rowAtY:point.y]));

*/

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    if ([self mouseDownFlags] & CPShiftKeyMask)
        _selectionAnchor = (ABS([_selectedRowIndexes firstIndex] - row) < ABS([_selectedRowIndexes lastIndex] - row)) ?
            [_selectedRowIndexes firstIndex] : [_selectedRowIndexes lastIndex];
    else
        _selectionAnchor = row;

    [self _updateSelectionWithMouseAtRow:row];

    return YES;
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self _updateSelectionWithMouseAtRow:[self rowAtPoint:aPoint]];

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{/*
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
*/
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
        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionStartRow), ABS(aRow - _selectionStartRow) + 1)];

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

    [self selectRowIndexes:newSelection byExtendingSelection:NO];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

@end
