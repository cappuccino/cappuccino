
@import <Foundation/CPArray.j>

@import "CPControl.j"
@import "CPTableColumn.j"

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
        _numberOfRows = 0;

        _intercellSpacing = _CGSizeMake(0.0, 0.0);
        _rowHeight = 24.0;
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
    * Ð clickedColumn
    * Ð clickedRow
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
Ð (void)setUsesAlternatingRowBackgroundColors:(BOOL)shouldUseAlternatingRowBackgroundColors
{
    // TODO:need to look at how one actually sets the alternating row, a tip at: 
    // http://forums.macnn.com/79/developer-center/228347/nstableview-alternating-row-colors/
    // otherwise this may not be feasible or may introduce an additional change req'd in CP
    // we'd probably need to iterate through rowId % 2 == 0 and setBackgroundColor with 
    // whatever the alternating row color is.
    _usesAlternatingRowBackgroundColors = shouldUseAlternatingRowBackgroundColors;
}

Ð (BOOL)usesAlternatingRowBackgroundColors
{
    return _usesAlternatingRowBackgroundColors;
}

Ð (unsigned)selectionHighlightStyle
{
    return _selectionHighlightMask;
}

Ð (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    _selectionHighlightMask = aSelectionHighlightStyle;
}

Ð setGridColor:


    * Ð gridColor
    * Ð setGridStyleMask:
    * Ð gridStyleMask
    * Ð indicatorImageInTableColumn:
    * Ð setIndicatorImage:inTableColumn:
*/
//Column Management

- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    [_tableColumns addObject:aTableColumn];

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = NUMBER_OF_COLUMNS() - 1;
    else
        _dirtyTableColumnRangeIndex = MIN(NUMBER_OF_COLUMNS() - 1, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    var index = [_tableColumns indeOfObjectIdenticalTo:aTableColumn];

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

    if (index < 0)
        return nil;

    return _tableColumns[index];
}

//Selecting Columns and Rows
/*
    * Ð selectColumnIndexes:byExtendingSelection:
    * Ð selectRowIndexes:byExtendingSelection:
    * Ð selectedColumnIndexes
    * Ð selectedRowIndexes
    * Ð deselectColumn:
    * Ð deselectRow:
    * Ð numberOfSelectedColumns
    * Ð numberOfSelectedRows
    * Ð selectedColumn
    * Ð selectedRow
    * Ð isColumnSelected:
    * Ð isRowSelected:
    * Ð selectAll:
    * Ð deselectAll:
    * Ð allowsTypeSelect
    * Ð setAllowsTypeSelect:
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
    * Ð preparedCellAtColumn:row:
*/
//Editing Cells
/*
    * Ð editColumn:row:withEvent:select:
    * Ð editedColumn
    * Ð editedRow
*/
//Setting Auxiliary Views
/*
    * Ð setHeaderView:
    * Ð headerView
    * Ð setCornerView:
    * Ð cornerView
*/
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
    if (_numberOfHiddenColumns < 0)
        return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(column, lastColumn - column)];

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
    if (!CGRectContainsPoint([self bounds], aPoint))
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

        else if (x > CPMaxRange(range))
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

/*
    * Ð frameOfCellAtColumn:row:
    * Ð columnAutoresizingStyle
    * Ð setColumnAutoresizingStyle:
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
    * Ð tile
    * Ð sizeToFit
    * Ð noteHeightOfRowsWithIndexesChanged:
*/
//Scrolling
/*
    * Ð scrollRowToVisible:
    * Ð scrollColumnToVisible:
*/
//Persistence
/*
    * Ð autosaveName
    * Ð autosaveTableColumns
    * Ð setAutosaveName:
    * Ð setAutosaveTableColumns:
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
Ð (CPTableColumn)highlightedTableColumn
{

}

    * Ð setHighlightedTableColumn:
*/
//Dragging
/*
    * Ð dragImageForRowsWithIndexes:tableColumns:event:offset:
    * Ð canDragRowsWithIndexes:atPoint:
    * Ð setDraggingSourceOperationMask:forLocal:
    * Ð setDropRow:dropOperation:
    * Ð setVerticalMotionCanBeginDrag:
    * Ð verticalMotionCanBeginDrag
*/
//Sorting
/*
    * Ð setSortDescriptors:
    * Ð sortDescriptors
*/

//Text Delegate Methods
/*
    * Ð textShouldBeginEditing:
    * Ð textDidBeginEditing:
    * Ð textDidChange:
    * Ð textShouldEndEditing:
    * Ð textDidEndEditing:
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
{//console.log("logging.");
    if (!_dataSource)
    {
        // remove?
        return;
    }

     // SLOWMO
    var subviews = [self subviews],
        count = [subviews count];

    while (count--)
        [subviews[count] removeFromSuperview];

    var exposedRect = [self _exposedRect],
        exposedRows = [self rowsInRect:exposedRect],
        exposedColumns = [self columnIndexesInRect:exposedRect],
        columnIndex = [exposedColumns firstIndex];

    while (columnIndex !== CPNotFound)
    {
        var tableColumn = _tableColumns[columnIndex],
            tableColumnRange = _tableColumnRanges[columnIndex];

        var rowIndex = exposedRows.location,
            lastRowIndex = CPMaxRange(exposedRows);

        for (; rowIndex < lastRowIndex; ++rowIndex)
        {
            var dataView = [tableColumn _newDataViewForRow:rowIndex],
                rectOfRow = [self rectOfRow:rowIndex];

            [dataView setBackgroundColor:[CPColor redColor]];
            [dataView setFrame:_CGRectMake(tableColumnRange.location, _CGRectGetMinY(rectOfRow), tableColumnRange.length, _CGRectGetHeight(rectOfRow))];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:rowIndex]];

            [self addSubview:dataView];
        }

        columnIndex = [exposedColumns indexGreaterThanIndex:columnIndex];
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

@end
