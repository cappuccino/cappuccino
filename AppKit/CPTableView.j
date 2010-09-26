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
@import <AppKit/CGGradient.j>

@import "CPControl.j"
@import "CPTableColumn.j"
@import "_CPCornerView.j"
@import "CPScroller.j"

CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";

#include "CoreGraphics/CGGeometry.h"

var CPTableViewDataSource_numberOfRowsInTableView_                                                      = 1 << 0,
    CPTableViewDataSource_tableView_objectValueForTableColumn_row_                                      = 1 << 1,
    CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2,
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

//CPTableViewDraggingDestinationFeedbackStyles
CPTableViewDraggingDestinationFeedbackStyleNone = -1;
CPTableViewDraggingDestinationFeedbackStyleRegular = 0;
CPTableViewDraggingDestinationFeedbackStyleSourceList = 1;

//CPTableViewDropOperations
CPTableViewDropOn = 0;
CPTableViewDropAbove = 1;

CPSourceListGradient = "CPSourceListGradient";
CPSourceListTopLineColor = "CPSourceListTopLineColor";
CPSourceListBottomLineColor = "CPSourceListBottomLineColor";

// TODO: add docs

CPTableViewSelectionHighlightStyleNone = -1;
CPTableViewSelectionHighlightStyleRegular = 0;
CPTableViewSelectionHighlightStyleSourceList = 1;

CPTableViewGridNone                    = 0;
CPTableViewSolidVerticalGridLineMask   = 1 << 0;
CPTableViewSolidHorizontalGridLineMask = 1 << 1;

CPTableViewNoColumnAutoresizing = 0;
CPTableViewUniformColumnAutoresizingStyle = 1; // FIX ME: This is FUBAR
CPTableViewSequentialColumnAutoresizingStyle = 2;
CPTableViewReverseSequentialColumnAutoresizingStyle = 3;
CPTableViewLastColumnOnlyAutoresizingStyle = 4;
CPTableViewFirstColumnOnlyAutoresizingStyle = 5;


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

/*!
    @ingroup appkit
    @class CPTableView

    CPTableView object displays record-oriented data in a table and
    allows the user to edit values and resize and rearrange columns.
    A CPTableView requires you to set a dataSource which implements numberOfRowsInTableView:
    and tableView:objectValueForTableColumn:row:
*/
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
    CPIndexSet  _exposedRows;
    CPIndexSet  _exposedColumns;

    Object      _dataViewsForTableColumns;
    Object      _cachedDataViews;

    //Configuring Behavior
    BOOL        _allowsColumnReordering;
    BOOL        _allowsColumnResizing;
    BOOL        _allowsColumnSelection;
    BOOL        _allowsMultipleSelection;
    BOOL        _allowsEmptySelection;

    CPArray     _sortDescriptors;

    //Setting Display Attributes
    CGSize      _intercellSpacing;
    float       _rowHeight;

    BOOL        _usesAlternatingRowBackgroundColors;
    CPArray     _alternatingRowBackgroundColors;

    unsigned    _selectionHighlightStyle;
    CPTableColumn _currentHighlightedTableColumn;
    unsigned    _gridStyleMask;

    unsigned    _numberOfRows;


    CPTableHeaderView _headerView;
    _CPCornerView     _cornerView;

    CPIndexSet  _selectedColumnIndexes;
    CPIndexSet  _selectedRowIndexes;
    CPInteger   _selectionAnchorRow;
    CPInteger   _lastSelectedRow;
    CPIndexSet  _previouslySelectedRowIndexes;
    CGPoint     _startTrackingPoint;
    CPDate      _startTrackingTimestamp;
    BOOL        _trackingPointMovedOutOfClickSlop;
    CGPoint     _editingCellIndex;

    _CPTableDrawView _tableDrawView;

    SEL         _doubleAction;
    CPInteger   _clickedRow;
    unsigned    _columnAutoResizingStyle;

    int         _lastTrackedRowIndex;
    CGPoint     _originalMouseDownPoint;
    BOOL        _verticalMotionCanDrag;
    unsigned    _destinationDragStyle;
    BOOL        _isSelectingSession;
    CPIndexSet  _draggedRowIndexes;

    _CPDropOperationDrawingView _dropOperationFeedbackView;
    CPDragOperation             _dragOperationDefaultMask;
    int                         _retargetedDropRow;
    CPDragOperation             _retargetedDropOperation;

    BOOL        _disableAutomaticResizing @accessors(property=disableAutomaticResizing);
    BOOL        _lastColumnShouldSnap;
    BOOL        _implementsCustomDrawRow;

    CPTableColumn _draggedColumn;
    CPArray     _differedColumnDataToRemove;
}

+ (CPString)themeClass
{
    return @"tableview";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:["alternating-row-colors", "grid-color", "highlighted-grid-color", "selection-color", "sourcelist-selection-color", "sort-image", "sort-image-reversed"]];
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
        _disableAutomaticResizing = NO;

        //Setting Display Attributes
        _selectionHighlightStyle = CPTableViewSelectionHighlightStyleRegular;

        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setAlternatingRowBackgroundColors:
            [[CPColor whiteColor], [CPColor colorWithRed:245.0 / 255.0 green:249.0 / 255.0 blue:252.0 / 255.0 alpha:1.0]]];

        _tableColumns = [];
        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = CPNotFound;
        _numberOfHiddenColumns = 0;

        _intercellSpacing = _CGSizeMake(3.0, 2.0);
        _rowHeight = 23.0;

        [self setGridColor:[CPColor colorWithHexString:@"dce0e2"]];
        [self setGridStyleMask:CPTableViewGridNone];

        _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        _cornerView = nil; //[[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];

        _lastSelectedRow = -1;
        _currentHighlightedTableColumn = nil;

        _sortDescriptors = [CPArray array];

        _draggedRowIndexes = [CPIndexSet indexSet];
        _verticalMotionCanDrag = YES;
        _isSelectingSession = NO;
        _retargetedDropRow = nil;
        _retargetedDropOperation = nil;
        _dragOperationDefaultMask = nil;
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;

        [self setBackgroundColor:[CPColor whiteColor]];
        [self _init];
    }

    return self;
}

// FIX ME: we have a lot of redundent init stuff in initWithFrame: and initWithCoder: we should move it all into here.
- (void)_init
{
        _tableViewFlags = 0;

        _selectedColumnIndexes = [CPIndexSet indexSet];
        _selectedRowIndexes = [CPIndexSet indexSet];

        _dropOperationFeedbackView = [[_CPDropOperationDrawingView alloc] initWithFrame:_CGRectMakeZero()];
        [_dropOperationFeedbackView setTableView:self];

        _lastColumnShouldSnap = NO;

        if (!_alternatingRowBackgroundColors)
            _alternatingRowBackgroundColors = [[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]];

        _selectionHighlightColor = [CPColor colorWithHexString:@"5f83b9"];

        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = 0;
        _numberOfHiddenColumns = 0;

        _objectValues = { };
        _dataViewsForTableColumns = { };
        _dataViews=  [];
        _numberOfRows = 0;
        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];
        _cachedDataViews = { };

        _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
        [_tableDrawView setBackgroundColor:[CPColor clearColor]];
        [self addSubview:_tableDrawView];

        if (!_headerView)
            _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        if (!_cornerView)
            _cornerView = [[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];

        _draggedColumn = nil;

/*      //gradients for the source list when CPTableView is NOT first responder or the window is NOT key
        // FIX ME: we need to actually implement this.
        _sourceListInactiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [168.0/255.0,183.0/255.0,205.0/255.0,1.0,157.0/255.0,174.0/255.0,199.0/255.0,1.0], [0,1], 2);
        _sourceListInactiveTopLineColor = [CPColor colorWithCalibratedRed:(173.0/255.0) green:(187.0/255.0) blue:(209.0/255.0) alpha:1.0];
        _sourceListInactiveBottomLineColor = [CPColor colorWithCalibratedRed:(150.0/255.0) green:(161.0/255.0) blue:(183.0/255.0) alpha:1.0];*/
        _differedColumnDataToRemove = [ ];
        _implementsCustomDrawRow = [self implementsSelector:@selector(drawRow:clipRect:)];
}

/*!
    Sets the receiver's data source to a given object.
    @param anObject The data source for the receiver. The object must implement the appropriate methods.
*/
- (void)setDataSource:(id)aDataSource
{
    if (_dataSource === aDataSource)
        return;

    _dataSource = aDataSource;
    _implementedDataSourceMethods = 0;

    if (!_dataSource)
        return;

    var hasContentBinding = !![self infoForBinding:@"content"];

    if ([_dataSource respondsToSelector:@selector(numberOfRowsInTableView:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_numberOfRowsInTableView_;
    else if (!hasContentBinding)
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement numberOfRowsInTableView:."];

    if ([_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_objectValueForTableColumn_row_;
    else if (!hasContentBinding)
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement tableView:objectValueForTableColumn:row:"];

    if ([_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_;

    if ([_dataSource respondsToSelector:@selector(tableView:acceptDrop:row:dropOperation:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:namesOfPromisedFilesDroppedAtDestination:forDraggedRowsWithIndexes:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_;

    if ([_dataSource respondsToSelector:@selector(tableView:validateDrop:proposedRow:proposedDropOperation:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:writeRowsWithIndexes:toPasteboard:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_;

    if ([_dataSource respondsToSelector:@selector(tableView:sortDescriptorsDidChange:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_sortDescriptorsDidChange_;

    [self reloadData];
}

/*!
    Returns the object that provides the data displayed by the receiver.
*/
- (id)dataSource
{
    return _dataSource;
}

//Loading Data

/*!
    Reloads the data for only the specified rows and columns.
    @param rowIndexes The indexes of the rows to update.
    @param columnIndexes The indexes of the columns to update.
*/
- (void)reloadDataForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self reloadData];
//    [_previouslyExposedRows removeIndexes:rowIndexes];
//    [_previouslyExposedColumns removeIndexes:columnIndexes];
}

/*!
    Reloads the data for all rows and columns.

*/
- (void)reloadData
{
    //if (!_dataSource)
    //    return;

    _reloadAllRows = YES;
    _objectValues = { };

    // This updates the size too.
    [self noteNumberOfRowsChanged];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

//Target-action Behavior
/*!
    Sets the message sent to the target when the user double-clicks an
    uneditable cell or a column header to a given selector.
    @param aSelector The message the receiver sends to its target when the user
    double-clicks an uneditable cell or a column header.
*/
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
*/

/*!
    Returns the index of the the row the user clicked to trigger an action, or -1 if no row was clicked.
*/
- (CPInteger)clickedRow
{
    return _clickedRow;
}

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

/*!
    Controls whether the user can select more than one row or column at a time.
    @param aFlag YES to allow the user to select multiple rows or columns, otherwise NO.
*/
- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    _allowsMultipleSelection = !!shouldAllowMultipleSelection;
}

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

/*!
    Controls whether the receiver allows zero rows or columns to be selected.
    @param aFlag YES if an empty selection is allowed, otherwise NO.
*/
- (void)setAllowsEmptySelection:(BOOL)shouldAllowEmptySelection
{
    _allowsEmptySelection = !!shouldAllowEmptySelection;
}

- (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

/*!
    Controls whether the user can select an entire column by clicking its header.
    @param aFlag YES to allow the user to select columns, otherwise NO.
*/

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

    _dirtyTableColumnRangeIndex = 0; // so that _recalculateTableColumnRanges will work
    [self _recalculateTableColumnRanges];

    [self setNeedsLayout];
    [_headerView setNeedsDisplay:YES];
    [_headerView setNeedsLayout];
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

/*!
    Sets whether the receiver uses the standard alternating row colors for its background.
    @param aFlag YES to specify standard alternating row colors for the background, NO to specify a solid color.
*/
- (void)setUsesAlternatingRowBackgroundColors:(BOOL)shouldUseAlternatingRowBackgroundColors
{
    _usesAlternatingRowBackgroundColors = shouldUseAlternatingRowBackgroundColors;
}

- (BOOL)usesAlternatingRowBackgroundColors
{
    return _usesAlternatingRowBackgroundColors;
}

/*!
    Sets the colors for the rows as they alternate. The number of colors can be arbitrary. By deafult these colors are white and light blue.
    @param anArray an array of CPColors
*/

- (void)setAlternatingRowBackgroundColors:(CPArray)alternatingRowBackgroundColors
{
    [self setValue:alternatingRowBackgroundColors forThemeAttribute:"alternating-row-colors"];

    [self setNeedsDisplay:YES];
}

- (CPArray)alternatingRowBackgroundColors
{
    return [self currentValueForThemeAttribute:@"alternating-row-colors"];
}

- (unsigned)selectionHighlightStyle
{
    return _selectionHighlightStyle;
}

- (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    //early return for IE.
    if (aSelectionHighlightStyle == CPTableViewSelectionHighlightStyleSourceList && !CPFeatureIsCompatible(CPHTMLCanvasFeature))
        return;

    _selectionHighlightStyle = aSelectionHighlightStyle;
    [self setNeedsDisplay:YES];

    if (aSelectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList)
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleSourceList;
    else
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;
}

/*!
    Sets the highlight color for a row or column selection
    @param aColor a CPColor
*/
- (void)setSelectionHighlightColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:"selection-color"];

    [self setNeedsDisplay:YES];
}

/*!
    Returns the highlight color for a row or column selection.
*/
- (CPColor)selectionHighlightColor
{
    return [self currentValueForThemeAttribute:@"selection-color"];
}

/*!
    Sets the highlight gradient for a row or column selection
    This is specific to the
    @param aDictionary a CPDictionary expects three keys to be set:
        CPSourceListGradient which is a CGGradient
        CPSourceListTopLineColor which is a CPColor
        CPSourceListBottomLineColor which is a CPColor
*/
- (void)setSelectionGradientColors:(CPDictionary)aDictionary
{
    [self setValue:aDictionary forThemeAttribute:"sourcelist-selection-color"];

    [self setNeedsDisplay:YES];
}

/*!
    Returns a dictionary of containing the keys:
    CPSourceListGradient
    CPSourceListTopLineColor
    CPSourceListBottomLineColor
*/
- (CPDictionary)selectionGradientColors
{
    return [self currentValueForThemeAttribute:@"sourcelist-selection-color"];
}

/*!
    Sets the grid color in the non highlighted state.
    @param aColor a CPColor
*/
- (void)setGridColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:"grid-color"];

    [self setNeedsDisplay:YES];
}

- (CPColor)gridColor
{
    return [self currentValueForThemeAttribute:@"grid-color"];;
}

/*!
    Sets the grid style mask to specify if no grid lines, vertical grid lines, or horizontal grid lines should be displayed.
    @param gridType The grid style mask. CPTableViewGridNone, CPTableViewSolidVerticalGridLineMask, CPTableViewSolidHorizontalGridLineMask
*/

- (void)setGridStyleMask:(unsigned)aGrideStyleMask
{
    if (_gridStyleMask === aGrideStyleMask)
        return;

    _gridStyleMask = aGrideStyleMask;

    [self setNeedsDisplay:YES];
}

- (unsigned)gridStyleMask
{
    return _gridStyleMask;
}

//Column Management

/*!
    Adds a given column as the last column of the receiver.
    @param aColumn The column to add to the receiver.
*/
- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    [_tableColumns addObject:aTableColumn];
    [aTableColumn setTableView:self];

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = NUMBER_OF_COLUMNS() - 1;
    else
        _dirtyTableColumnRangeIndex = MIN(NUMBER_OF_COLUMNS() - 1, _dirtyTableColumnRangeIndex);

    [self tile];
    [self setNeedsLayout];
}

/*!
    Removes a given column from the receiver.
    @param aTableColumn The column to remove from the receiver.
*/
- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    if ([aTableColumn tableView] !== self)
        return;

    var index = [_tableColumns indexOfObjectIdenticalTo:aTableColumn];

    if (index === CPNotFound)
        return;

    // we differ the actual removal until the end of the runloop in order to keep a reference to the column.
    [_differedColumnDataToRemove addObject:{"column":aTableColumn, "shouldBeHidden": [aTableColumn isHidden]}];

    [aTableColumn setHidden:YES];
    [aTableColumn setTableView:nil];

    var tableColumnUID = [aTableColumn UID];

    if (_objectValues[tableColumnUID])
        _objectValues[tableColumnUID] = nil;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = index;
    else
        _dirtyTableColumnRangeIndex = MIN(index, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)_setDraggedColumn:(CPTableColumn)aColumn
{
    if (_draggedColumn === aColumn)
        return;

    _draggedColumn = aColumn;

    [self reloadDataForRowIndexes:_exposedRows columnIndexes:[CPIndexSet indexSetWithIndex:[_tableColumns indexOfObject:aColumn]]];
}

/*!
    Moves the column and heading at a given index to a new given index.
    @param columnIndex The current index of the column to move.
    @param newIndex The new index for the moved column.
*/
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

    var tableColumn = _tableColumns[fromIndex];

    [_tableColumns removeObjectAtIndex:fromIndex];
    [_tableColumns insertObject:tableColumn atIndex:toIndex];

    [[self headerView] setNeedsLayout];
    [[self headerView] setNeedsDisplay:YES];

    var rowIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])],
        columnIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(fromIndex, toIndex)];

    [self reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
}

/*!
    @ignore
*/
- (void)_tableColumnVisibilityDidChange:(CPTableColumn)aColumn
{
    var columnIndex = [[self tableColumns] indexOfObjectIdenticalTo:aColumn];

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = columnIndex;
    else
        _dirtyTableColumnRangeIndex = MIN(columnIndex, _dirtyTableColumnRangeIndex);

    [[self headerView] setNeedsLayout];
    [[self headerView] setNeedsDisplay:YES];

    var rowIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])];
    [self reloadDataForRowIndexes:rowIndexes columnIndexes:[CPIndexSet indexSetWithIndex:columnIndex]];
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
        if ([_tableColumns[index] identifier] === anIdentifier)
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

/*!
    Sets the column selection using indexes.
    @param columns a CPIndexSet of columns to select
    @param aFlag should extend the selection thereby retaining the previous selection
*/
- (void)selectColumnIndexes:(CPIndexSet)columns byExtendingSelection:(BOOL)shouldExtendSelection
{
    // If we're out of range, just return
    if (([columns firstIndex] != CPNotFound && [columns firstIndex] < 0) || [columns lastIndex] >= [self numberOfColumns])
        return;

    // We deselect all rows when selecting columns.
    if ([_selectedRowIndexes count] > 0)
    {
        [self _updateHighlightWithOldRows:_selectedRowIndexes newRows:[CPIndexSet indexSet]];
        _selectedRowIndexes = [CPIndexSet indexSet];
    }

    var previousSelectedIndexes = [_selectedColumnIndexes copy];

    if (shouldExtendSelection)
        [_selectedColumnIndexes addIndexes:columns];
    else
        _selectedColumnIndexes = [columns copy];

    [self _updateHighlightWithOldColumns:previousSelectedIndexes newColumns:_selectedColumnIndexes];
    [self setNeedsDisplay:YES]; // FIXME: should be setNeedsDisplayInRect:enclosing rect of new (de)selected columns
                              // but currently -drawRect: is not implemented here
    if (_headerView)
        [_headerView setNeedsDisplay:YES];

    [self _noteSelectionDidChange];
}

- (void)_setSelectedRowIndexes:(CPIndexSet)rows
{
    if ([_selectedRowIndexes isEqualToIndexSet:rows])
        return;

    var previousSelectedIndexes = _selectedRowIndexes;

    _lastSelectedRow = ([rows count] > 0) ? [rows lastIndex] : -1;
    _selectedRowIndexes = [rows copy];

    [self _updateHighlightWithOldRows:previousSelectedIndexes newRows:_selectedRowIndexes];
    [self setNeedsDisplay:YES]; // FIXME: should be setNeedsDisplayInRect:enclosing rect of new (de)selected rows
                              // but currently -drawRect: is not implemented here

    [[CPKeyValueBinding getBinding:@"selectionIndexes" forObject:self] reverseSetValueFor:@"selectedRowIndexes"];

    [self _noteSelectionDidChange];
}

/*!
    Sets the row selection using indexes.
    @param rows a CPIndexSet of rows to select
    @param aFlag should extend the selection thereby retaining the previous selection
*/
- (void)selectRowIndexes:(CPIndexSet)rows byExtendingSelection:(BOOL)shouldExtendSelection
{
    if ([rows isEqualToIndexSet:_selectedRowIndexes] ||
        (([rows firstIndex] != CPNotFound && [rows firstIndex] < 0) || [rows lastIndex] >= [self numberOfRows]))
        return;

    // We deselect all columns when selecting rows.
    if ([_selectedColumnIndexes count] > 0)
    {
        [self _updateHighlightWithOldColumns:_selectedColumnIndexes newColumns:[CPIndexSet indexSet]];
        _selectedColumnIndexes = [CPIndexSet indexSet];
        if (_headerView)
            [_headerView setNeedsDisplay:YES];
    }

    var newSelectedIndexes;
    if (shouldExtendSelection)
    {
        newSelectedIndexes = [_selectedRowIndexes copy];
        [newSelectedIndexes addIndexes:rows];
    }
    else
        newSelectedIndexes = [rows copy];

    [self _setSelectedRowIndexes:newSelectedIndexes];
}

- (void)_updateHighlightWithOldRows:(CPIndexSet)oldRows newRows:(CPIndexSet)newRows
{
    var firstExposedRow = [_exposedRows firstIndex],
        exposedLength = [_exposedRows lastIndex] - firstExposedRow + 1,
        deselectRows = [],
        selectRows = [],
        deselectRowIndexes = [oldRows copy],
        selectRowIndexes = [newRows copy];

    [deselectRowIndexes removeMatches:selectRowIndexes];
    [deselectRowIndexes getIndexes:deselectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];
    [selectRowIndexes getIndexes:selectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];

    for (var identifier in _dataViewsForTableColumns)
    {
        var dataViewsInTableColumn = _dataViewsForTableColumns[identifier],
            count = deselectRows.length;
        while (count--)
            [self _performSelection:NO forRow:deselectRows[count] context:dataViewsInTableColumn];

        count = selectRows.length;
        while (count--)
            [self _performSelection:YES forRow:selectRows[count] context:dataViewsInTableColumn];
    }
}

- (void)_performSelection:(BOOL)select forRow:(CPInteger)rowIndex context:(id)context
{
    var view = context[rowIndex],
        selector = select ? @"setThemeState:" : @"unsetThemeState:";

    [view performSelector:CPSelectorFromString(selector) withObject:CPThemeStateSelectedDataView];
}

- (void)_updateHighlightWithOldColumns:(CPIndexSet)oldColumns newColumns:(CPIndexSet)newColumns
{
    var firstExposedColumn = [_exposedColumns firstIndex],
        exposedLength = [_exposedColumns lastIndex] - firstExposedColumn  +1,
        deselectColumns  = [],
        selectColumns  = [],
        deselectColumnIndexes = [oldColumns copy],
        selectColumnIndexes = [newColumns copy],
        selectRows = [];

    [deselectColumnIndexes removeMatches:selectColumnIndexes];
    [deselectColumnIndexes getIndexes:deselectColumns maxCount:-1 inIndexRange:CPMakeRange(firstExposedColumn, exposedLength)];
    [selectColumnIndexes getIndexes:selectColumns maxCount:-1 inIndexRange:CPMakeRange(firstExposedColumn, exposedLength)];
    [_exposedRows getIndexes:selectRows maxCount:-1 inIndexRange:nil];

    var rowsCount = selectRows.length,
        count = deselectColumns.length;
    while (count--)
    {
        var columnIndex = deselectColumns[count],
            identifier = [_tableColumns[columnIndex] UID],
            dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        for (var i = 0; i < rowsCount; i++)
        {
            var rowIndex = selectRows[i],
                dataView = dataViewsInTableColumn[rowIndex];
            [dataView unsetThemeState:CPThemeStateSelectedDataView];
        }

        if (_headerView)
        {
            var headerView = [_tableColumns[columnIndex] headerView];
            [headerView unsetThemeState:CPThemeStateSelected];
        }
    }

    count = selectColumns.length;
    while (count--)
    {
        var columnIndex = selectColumns[count],
            identifier = [_tableColumns[columnIndex] UID],
            dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        for (var i = 0; i < rowsCount; i++)
        {
            var rowIndex = selectRows[i],
                dataView = dataViewsInTableColumn[rowIndex];
            [dataView setThemeState:CPThemeStateSelectedDataView];
        }
        if (_headerView)
        {
            var headerView = [_tableColumns[columnIndex] headerView];
            [headerView setThemeState:CPThemeStateSelected];
        }
    }
}

- (int)selectedColumn
{
    [_selectedColumnIndexes lastIndex];
}

- (CPIndexSet)selectedColumnIndexes
{
    return _selectedColumnIndexes;
}

- (int)selectedRow
{
    return _lastSelectedRow;
}

- (CPIndexSet)selectedRowIndexes
{
    return [_selectedRowIndexes copy];
}

- (void)deselectColumn:(CPInteger)aColumn
{
    var selectedColumnIndexes = [_selectedColumnIndexes copy];
    [selectedColumnIndexes removeIndex:aColumn];
    [self selectColumnIndexes:selectedColumnIndexes byExtendingSelection:NO];
    [self _noteSelectionDidChange];
}

- (void)deselectRow:(CPInteger)aRow
{
    var selectedRowIndexes = [_selectedRowIndexes copy];
    [selectedRowIndexes removeIndex:aRow];
    [self selectRowIndexes:selectedRowIndexes byExtendingSelection:NO];
    [self _noteSelectionDidChange];
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

/*!
    Deselects all rows
*/
- (void)deselectAll
{
    [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
    [self selectColumnIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
}

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
    if (_numberOfRows)
        return _numberOfRows;

    var contentBindingInfo = [self infoForBinding:@"content"];

    if (contentBindingInfo)
    {
        var destination = [contentBindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [contentBindingInfo objectForKey:CPObservedKeyPathKey];

        return [[destination valueForKeyPath:keyPath] count];
    }

    else if (_dataSource)
        return [_dataSource numberOfRowsInTableView:self];

    return 0;
}

//Displaying Cell
/*
    * - preparedCellAtColumn:row:
*/

//Editing Cells

/*!
    Edits the indicated row.
*/
- (void)editColumn:(CPInteger)columnIndex row:(CPInteger)rowIndex withEvent:(CPEvent)theEvent select:(BOOL)flag
{
    if (![self isRowSelected:rowIndex])
        [[CPException exceptionWithName:@"Error" reason:@"Attempt to edit row="+rowIndex+" when not selected." userInfo:nil] raise];

    // TODO Do something with flag.

    _editingCellIndex = CGPointMake(columnIndex, rowIndex);
    [self reloadDataForRowIndexes:[CPIndexSet indexSetWithIndex:rowIndex]
        columnIndexes:[CPIndexSet indexSetWithIndex:columnIndex]];
}

/*!
    Returns the column of the currently edited cell, or CPNotFound if none.
*/
- (CPInteger)editedColumn
{
    if (!_editingCellIndex)
        return CPNotFound;
    return _editingCellIndex.x;
}

/*!
    Returns the row of the currently edited cell, or CPNotFound if none.
*/
- (CPInteger)editedRow
{
    if (!_editingCellIndex)
        return CPNotFound;
    return _editingCellIndex.y;
}

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

    _numberOfHiddenColumns = 0;

    var index = _dirtyTableColumnRangeIndex,
        count = NUMBER_OF_COLUMNS(),
        x = index === 0 ? 0.0 : CPMaxRange(_tableColumnRanges[index - 1]);

    for (; index < count; ++index)
    {
        var tableColumn = _tableColumns[index];

        if ([tableColumn isHidden])
        {
            _numberOfHiddenColumns += 1;
            _tableColumnRanges[index] = CPMakeRange(x, 0.0);
        }

        else
        {
            var width = [_tableColumns[index] width] + _intercellSpacing.width;

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

    var column = [[self tableColumns] objectAtIndex:aColumnIndex];

    if ([column isHidden] || aColumnIndex < 0 || aColumnIndex >= NUMBER_OF_COLUMNS())
        return _CGRectMakeZero();

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var range = _tableColumnRanges[aColumnIndex];

    return _CGRectMake(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}

- (CGRect)rectOfRow:(CPInteger)aRowIndex
{
    var height = _rowHeight + _intercellSpacing.height;

    return _CGRectMake(0.0, aRowIndex * height, _CGRectGetWidth([self bounds]), height);
}

// Complexity:
// O(1)
/*!
    Returns a range of indices for the rows that lie wholly or partially within the vertical boundaries of a given rectangle.
    @param aRect A rectangle in the coordinate system of the receiver.
*/

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

/*!
    Returns the indexes of the receiver's columns that intersect the specified rectangle.
    @param aRect A rectangle in the coordinate system of the receiver.
*/
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
    var y = aPoint.y,
        row = FLOOR(y / (_rowHeight + _intercellSpacing.height));

    if (row >= _numberOfRows)
        return -1;

    return row;
}

- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var tableColumnRange = _tableColumnRanges[aColumn],
        rectOfRow = [self rectOfRow:aRow],
        leftInset = FLOOR(_intercellSpacing.width / 2.0),
        topInset = FLOOR(_intercellSpacing.height / 2.0);

    return _CGRectMake(tableColumnRange.location + leftInset,
                       _CGRectGetMinY(rectOfRow) + topInset,
                       tableColumnRange.length - _intercellSpacing.width,
                       _CGRectGetHeight(rectOfRow) - _intercellSpacing.height);
}

- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    [super resizeWithOldSuperviewSize:aSize];

    if (_disableAutomaticResizing)
        return;

    var mask = _columnAutoResizingStyle;

    if (mask === CPTableViewUniformColumnAutoresizingStyle)
       [self _resizeAllColumnUniformlyWithOldSize:aSize];
    else if (mask === CPTableViewLastColumnOnlyAutoresizingStyle)
        [self sizeLastColumnToFit];
    else if (mask === CPTableViewFirstColumnOnlyAutoresizingStyle)
        [self _autoResizeFirstColumn];
}

- (void)_autoResizeFirstColumn
{
    var superview = [self superview];

    if (!superview)
        return;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS(),
        columnToResize = nil,
        totalWidth = 0,
        i = 0;

    for (; i < count; i++)
    {
        var column = _tableColumns[i];

        if (![column isHidden])
        {
            if (!columnToResize)
                columnToResize = column;
            totalWidth += [column width] + _intercellSpacing.width;
        }
    }

    // If there is a visible column
    if (columnToResize)
    {
        var superviewSize = [superview bounds].size,
            newWidth = superviewSize.width - totalWidth;

        newWidth += [columnToResize width];
        newWidth = MAX([columnToResize minWidth], newWidth);
        newWidth = MIN([columnToResize maxWidth], newWidth);

        [columnToResize setWidth:FLOOR(newWidth)];
    }

    [self setNeedsLayout];
}

- (void)_resizeAllColumnUniformlyWithOldSize:(CGSize)oldSize
{
    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS(),
        visColumns = [[CPArray alloc] init],
        buffer = 0.0;

    // Fixme: cache resizable columns because they won't changes betwwen two calls to this method.
    for (var i = 0; i < count; i++)
    {
        var tableColumn = _tableColumns[i];
        if (![tableColumn isHidden] && ([tableColumn resizingMask] & CPTableColumnAutoresizingMask))
            [visColumns addObject:i];
    }

    // redefine count
    count = [visColumns count];

    //if there are columns
    if (count > 0)
    {
        var maxXofColumns = CGRectGetMaxX([self rectOfColumn:visColumns[count - 1]]);

        // If the x value of the end of the last column is between the current bounds and the previous bounds we should snap.
        if (!_lastColumnShouldSnap && (maxXofColumns >= superviewSize.width && maxXofColumns <= oldSize.width || maxXofColumns <= superviewSize.width && maxXofColumns >= oldSize.width))
        {
            //set the snap mask
            _lastColumnShouldSnap = YES;
            //then we need to make sure everything is set correctly.
            [self _resizeAllColumnUniformlyWithOldSize:CGSizeMake(maxXofColumns, 0)];
        }

        if (!_lastColumnShouldSnap)
            return;

        // FIX ME: This is wrong because this should continue to resize all columns
        // If the last column reaches it's max/min it will simply stop resizing,
        // correct behavior is to resize all columns until they reach their min/max

        for (var i = 0; i < count; i++)
        {
            var column = visColumns[i],
                columnToResize = _tableColumns[column],
                currentBuffer = buffer / (count - i),
                realNewWidth = ([columnToResize width] / oldSize.width * [superview bounds].size.width) + currentBuffer,
                newWidth = realNewWidth;
            newWidth = MAX([columnToResize minWidth], newWidth);
            newWidth = MIN([columnToResize maxWidth], newWidth);
            buffer -= currentBuffer;

            // the buffer takes into account the min/max width of the column
            buffer += realNewWidth - newWidth;

            [columnToResize setWidth:newWidth];
        }

        // if there is space left over that means column resize was too long or too short
        if (buffer !== 0)
            _lastColumnShouldSnap = NO;
    }

    [self setNeedsLayout];
}

/*!
    Sets the column autoresizing style of the receiver to a given style.
    @param aStyle The column autoresizing style for the receiver.
    CPTableViewNoColumnAutoresizing, CPTableViewUniformColumnAutoresizingStyle,
    CPTableViewLastColumnOnlyAutoresizingStyle, CPTableViewFirstColumnOnlyAutoresizingStyle
*/
- (void)setColumnAutoresizingStyle:(unsigned)style
{
    //FIX ME: CPTableViewSequentialColumnAutoresizingStyle and CPTableViewReverseSequentialColumnAutoresizingStyle are not yet implemented
    _columnAutoResizingStyle = style;
}

- (unsigned)columnAutoresizingStyle
{
    return _columnAutoResizingStyle;
}

/*!
   Resizes the last column if there's room so the receiver fits exactly within its enclosing clip view.
*/
- (void)sizeLastColumnToFit
{
    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS();

    //decrement the counter until we get to the last row that's not hidden
    while (count-- && [_tableColumns[count] isHidden]) ;

    //if the last row exists
    if (count >= 0)
    {
        var columnToResize = _tableColumns[count],
            newSize = MAX(0.0, superviewSize.width - CGRectGetMinX([self rectOfColumn:count]) - _intercellSpacing.width);

        if (newSize > 0)
        {
            newSize = MAX([columnToResize minWidth], newSize);
            newSize = MIN([columnToResize maxWidth], newSize);
            [columnToResize setWidth:newSize];
        }
    }

    [self setNeedsLayout];
}

- (void)noteNumberOfRowsChanged
{
    var oldNumberOfRows = _numberOfRows;

    _numberOfRows = nil;
    _numberOfRows = [self numberOfRows];

    // remove row indexes from the selection if they no longer exist
    var hangingSelections = oldNumberOfRows - _numberOfRows;

    if (hangingSelections > 0)
    {
        [_selectedRowIndexes removeIndexesInRange:CPMakeRange(_numberOfRows, hangingSelections)];
        [self _noteSelectionDidChange];
    }

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

/*!
    Scrolls the receiver vertically in an enclosing NSClipView so the row specified by rowIndex is visible.
    @param aRowIndex the index of the row to scroll to.
*/
- (void)scrollRowToVisible:(int)rowIndex
{
    [self scrollRectToVisible:[self rectOfRow:rowIndex]];
}

/*!
    Scrolls the receiver and header view horizontally in an enclosing NSClipView so the column specified by columnIndex is visible.
    @param aColumnIndex the index of the column to scroll to.
*/
- (void)scrollColumnToVisible:(int)columnIndex
{
    [self scrollRectToVisible:[self rectOfColumn:columnIndex]];
    /*FIX ME: tableview header isn't rendered until you click the horizontal scroller (or scroll)*/
}

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
            selector:@selector(tableViewColumnDidResize:)
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

- (void)_sendDelegateDidClickColumn:(int)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_didClickTableColumn_)
            [_delegate tableView:self didClickTableColumn:_tableColumns[column]];
}

- (void)_sendDelegateDidDragColumn:(int)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_didDragTableColumn_)
            [_delegate tableView:self didDragTableColumn:_tableColumns[column]];
}

- (void)_sendDelegateDidMouseDownInHeader:(int)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_)
            [_delegate tableView:self mouseDownInHeaderOfTableColumn:_tableColumns[column]];
}

- (void)_sendDataSourceSortDescriptorsDidChange:(CPArray)oldDescriptors
{
    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_sortDescriptorsDidChange_)
            [_dataSource tableView:self sortDescriptorsDidChange:oldDescriptors];
}

- (void)_didClickTableColumn:(int)clickedColumn modifierFlags:(unsigned)modifierFlags
{
    [self _sendDelegateDidClickColumn:clickedColumn];

    if (_allowsColumnSelection)
    {
        [self _noteSelectionIsChanging];
        if (modifierFlags & CPCommandKeyMask)
        {
            if ([self isColumnSelected:clickedColumn])
                [self deselectColumn:clickedColumn];
            else if ([self allowsMultipleSelection] == YES)
                [self selectColumnIndexes:[CPIndexSet indexSetWithIndex:clickedColumn] byExtendingSelection:YES];

            return;
        }
        else if (modifierFlags & CPShiftKeyMask)
        {
        // should be from clickedColumn to lastClickedColum with extending:(direction == previous selection)
            var startColumn = MIN(clickedColumn, [_selectedColumnIndexes lastIndex]),
                endColumn = MAX(clickedColumn, [_selectedColumnIndexes firstIndex]);

            [self selectColumnIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(startColumn, endColumn - startColumn + 1)]
                 byExtendingSelection:YES];

            return;
        }
        else
            [self selectColumnIndexes:[CPIndexSet indexSetWithIndex:clickedColumn] byExtendingSelection:NO];
    }

    [self _changeSortDescriptorsForClickOnColumn:clickedColumn];
}

// From GNUSTEP
- (void)_changeSortDescriptorsForClickOnColumn:(int)column
{
    var tableColumn = [_tableColumns objectAtIndex:column],
        newMainSortDescriptor = [tableColumn sortDescriptorPrototype];

    if (!newMainSortDescriptor)
       return;

    var oldMainSortDescriptor = nil,
        oldSortDescriptors = [self sortDescriptors],
        newSortDescriptors = [CPArray arrayWithArray:oldSortDescriptors],

        e = [newSortDescriptors objectEnumerator],
        descriptor = nil,
        outdatedDescriptors = [CPArray array];

    if ([_sortDescriptors count] > 0)
        oldMainSortDescriptor = [[self sortDescriptors] objectAtIndex: 0];

    // Remove every main descriptor equivalents (normally only one)
    while ((descriptor = [e nextObject]) != nil)
    {
        if ([[descriptor key] isEqual: [newMainSortDescriptor key]])
            [outdatedDescriptors addObject:descriptor];
    }

    // Invert the sort direction when the same column header is clicked twice
    if ([[newMainSortDescriptor key] isEqual:[oldMainSortDescriptor key]])
        newMainSortDescriptor = [oldMainSortDescriptor reversedSortDescriptor];

    [newSortDescriptors removeObjectsInArray:outdatedDescriptors];
    [newSortDescriptors insertObject:newMainSortDescriptor atIndex:0];

    // Update indicator image & highlighted column before
    var image = [newMainSortDescriptor ascending] ? [self _tableHeaderSortImage] : [self _tableHeaderReverseSortImage];

    [self setIndicatorImage:nil inTableColumn:_currentHighlightedTableColumn];
    [self setIndicatorImage:image inTableColumn:tableColumn];
    [self setHighlightedTableColumn:tableColumn];

    [self setSortDescriptors:newSortDescriptors];
}

- (void)setIndicatorImage:(CPImage)anImage inTableColumn:(CPTableColumn)aTableColumn
{
    if (aTableColumn)
    {
        var headerView = [aTableColumn headerView];
        if ([headerView respondsToSelector:@selector(_setIndicatorImage:)])
            [headerView _setIndicatorImage:anImage];
    }
}

- (CPImage)_tableHeaderSortImage
{
    return [self currentValueForThemeAttribute:"sort-image"];
}

- (CPImage)_tableHeaderReverseSortImage
{
    return [self currentValueForThemeAttribute:"sort-image-reversed"];
}

//Highlightable Column Headers

- (CPTableColumn)highlightedTableColumn
{
    return _currentHighlightedTableColumn;
}

- (void)setHighlightedTableColumn:(CPTableColumn)aTableColumn
{
    if (_currentHighlightedTableColumn == aTableColumn)
        return;

    if (_headerView)
    {
        if (_currentHighlightedTableColumn != nil)
            [[_currentHighlightedTableColumn headerView] unsetThemeState:CPThemeStateSelected];

        if (aTableColumn != nil)
            [[aTableColumn headerView] setThemeState:CPThemeStateSelected];
    }

    _currentHighlightedTableColumn = aTableColumn;
}

/*!
    Returns whether the receiver allows dragging the rows at rowIndexes with a drag initiated at mousedDownPoint.
    @param rowIndexes an index set of rows to be dragged
    @param aPoint the point at which the mouse was clicked.
*/
- (BOOL)canDragRowsWithIndexes:(CPIndexSet)rowIndexes atPoint:(CGPoint)mouseDownPoint
{
    return YES;
}

- (CPImage)dragImageForRowsWithIndexes:(CPIndexSet)dragRows tableColumns:(CPArray)theTableColumns event:(CPEvent)dragEvent offset:(CPPointPointer)dragImageOffset
{
    return [[CPImage alloc] initWithContentsOfFile:@"Frameworks/AppKit/Resources/GenericFile.png" size:CGSizeMake(32,32)];
}

- (CPView)dragViewForRowsWithIndexes:(CPIndexSet)theDraggedRows tableColumns:(CPArray)theTableColumns event:(CPEvent)theDragEvent offset:(CPPointPointer)dragViewOffset
{
    var bounds = [self bounds],
        view = [[CPView alloc] initWithFrame:bounds];

    [view setAlphaValue:0.7];

    // We have to fetch all the data views for the selected rows and columns
    // After that we can copy these add them to a transparent drag view and use that drag view
    // to make it appear we are dragging images of those rows (as you would do in regular Cocoa)
    var columnIndex = [theTableColumns count];
    while (columnIndex--)
    {
        var tableColumn = [theTableColumns objectAtIndex:columnIndex],
            row = [theDraggedRows firstIndex];

        while (row !== CPNotFound)
        {
            var dataView = [self _newDataViewForRow:row tableColumn:tableColumn];

            [dataView setFrame:[self frameOfDataViewAtColumn:columnIndex row:row]];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];

            // If the column uses content bindings, allow them to override the objectValueForTableColumn.
            [tableColumn prepareDataView:dataView forRow:row];

            [view addSubview:dataView];

            row = [theDraggedRows indexGreaterThanIndex:row];
        }
    }

    var dragPoint = [self convertPoint:[theDragEvent locationInWindow] fromView:nil];
    dragViewOffset.x = CGRectGetWidth(bounds) / 2 - dragPoint.x;
    dragViewOffset.y = CGRectGetHeight(bounds) / 2 - dragPoint.y;

    return view;
}

/*!
    @ignore
    // Fetches all the data views (from the datasource) for the column and it's visible rows
    // Copy the dataviews add them to a transparent drag view and use that drag view
    // to make it appear we are dragging images of those rows (as you would do in regular Cocoa)
*/
- (CPView)_dragViewForColumn:(int)theColumnIndex event:(CPEvent)theDragEvent offset:(CPPointPointer)theDragViewOffset
{
    var dragView = [[_CPColumnDragView alloc] initWithLineColor:[self gridColor]],
        tableColumn = [[self tableColumns] objectAtIndex:theColumnIndex],
        bounds = CPRectMake(0.0, 0.0, [tableColumn width], _CGRectGetHeight([self visibleRect]) + 23.0),
        columnRect = [self rectOfColumn:theColumnIndex],
        headerView = [tableColumn headerView],
        row = [_exposedRows firstIndex];

    while (row !== CPNotFound)
    {
        var dataView = [self _newDataViewForRow:row tableColumn:tableColumn],
            dataViewFrame = [self frameOfDataViewAtColumn:theColumnIndex row:row];

        // Only one column is ever dragged so we just place the view at
        dataViewFrame.origin.x = 0.0;

        // Offset by table header height - scroll position
        dataViewFrame.origin.y = ( _CGRectGetMinY(dataViewFrame) - _CGRectGetMinY([self visibleRect]) ) + 23.0;
        [dataView setFrame:dataViewFrame];

        [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];
        [dragView addSubview:dataView];

        row = [_exposedRows indexGreaterThanIndex:row];
    }

    // Add the column header view
    var headerFrame = [headerView frame];
    headerFrame.origin = _CGPointMakeZero();

    var columnHeaderView = [[_CPTableColumnHeaderView alloc] initWithFrame:headerFrame];
    [columnHeaderView setStringValue:[headerView stringValue]];
    [columnHeaderView setThemeState:[headerView themeState]];
    [dragView addSubview:columnHeaderView];

    [dragView setBackgroundColor:[CPColor whiteColor]];
    [dragView setAlphaValue:0.7];
    [dragView setFrame:bounds];

    return dragView;
}

- (void)setDraggingSourceOperationMask:(CPDragOperation)mask forLocal:(BOOL)isLocal
{
    //ignoral local for the time being since only one capp app can run at a time...
    _dragOperationDefaultMask = mask;
}

/*!
    This should be called inside tableView:validateDrop:... method
    either drop on or above,
    specify the row as -1 to select the whole table for drop on
*/
- (void)setDropRow:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation
{
    if (row > [self numberOfRows] && operation === CPTableViewDropOn)
    {
        var numberOfRows = [self numberOfRows] + 1,
            reason = @"Attempt to set dropRow=" + row +
                     " dropOperation=CPTableViewDropOn when [0 - " + numberOfRows + "] is valid range of rows.";

        [[CPException exceptionWithName:@"Error" reason:reason userInfo:nil] raise];
    }


    _retargetedDropRow = row;
    _retargetedDropOperation = operation;
}

/*!
    sets the feedback style for when the table is the destination of a drag operation
    Can be:
    None
    Regular
    Source List
*/
- (void)setDraggingDestinationFeedbackStyle:(CPTableViewDraggingDestinationFeedbackStyle)aStyle
{
    //FIX ME: this should vary up the highlight color, currently nothing is being done with it
    _destinationDragStyle = aStyle;
}

- (CPTableViewDraggingDestinationFeedbackStyle)draggingDestinationFeedbackStyle
{
    return _destinationDragStyle;
}

/*!
    Sets whether vertical motion is treated as a drag or selection change to flag.
    @param aFlag If flag is NO then vertical motion will not start a drag. The default is YES.
*/
- (void)setVerticalMotionCanBeginDrag:(BOOL)aFlag
{
    _verticalMotionCanDrag = aFlag;
}

- (BOOL)verticalMotionCanBeginDrag
{
    return _verticalMotionCanDrag;
}


- (void)setSortDescriptors:(CPArray)sortDescriptors
{
    var oldSortDescriptors = [self sortDescriptors],
        newSortDescriptors = nil;

    if (sortDescriptors == nil)
        newSortDescriptors = [CPArray array];
    else
        newSortDescriptors = [CPArray arrayWithArray:sortDescriptors];

    if ([newSortDescriptors isEqual:oldSortDescriptors])
        return;

    _sortDescriptors = newSortDescriptors;

    [self _sendDataSourceSortDescriptorsDidChange:oldSortDescriptors];
}

- (CPArray)sortDescriptors
{
    return _sortDescriptors;
}

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

    // tableView:objectValueForTableColumn:row: is optional if content bindings are in place.
    if (objectValue === undefined && (_implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_))
    {
        objectValue = [_dataSource tableView:self objectValueForTableColumn:aTableColumn row:aRowIndex];
        tableColumnObjectValues[aRowIndex] = objectValue;
    }

    return objectValue;
}

- (void)load
{
    if (_reloadAllRows)
    {
        [self _unloadDataViewsInRows:_exposedRows columns:_exposedColumns];

        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];

        _reloadAllRows = NO;
    }

    var exposedRect = [self visibleRect],
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

    [self _unloadDataViewsInRows:previouslyExposedRows columns:obscuredColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:previouslyExposedColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:obscuredColumns];
    [self _unloadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];

    [self _loadDataViewsInRows:previouslyExposedRows columns:newlyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:previouslyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];

    _exposedRows = exposedRows;
    _exposedColumns = exposedColumns;

    [_tableDrawView setFrame:exposedRect];

    [self setNeedsDisplay:YES];

    // Now clear all the leftovers
    // FIXME: this could be faster!
    for (var identifier in _cachedDataViews)
    {
        var dataViews = _cachedDataViews[identifier],
            count = dataViews.length;

        while (count--)
            [dataViews[count] removeFromSuperview];
    }

    // if we have any columns to remove do that here
    if ([_differedColumnDataToRemove count])
    {
        for (var i = 0; i < _differedColumnDataToRemove.length; i++)
        {
            var data = _differedColumnDataToRemove[i],
                column = data.column;

            [column setHidden:data.shouldBeHidden];
            [_tableColumns removeObject:column];
        }
        [_differedColumnDataToRemove removeAllObjects];
    }

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
            tableColumnUID = [tableColumn UID],
            rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataViews = _dataViewsForTableColumns[tableColumnUID];

            if (!dataViews || row >= dataViews.length)
                continue;

            var dataView = [dataViews objectAtIndex:row];

            [dataViews replaceObjectAtIndex:row withObject:nil];

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
            tableColumn = _tableColumns[column];

        if ([tableColumn isHidden] || tableColumn === _draggedColumn)
            continue;

        var tableColumnUID = [tableColumn UID];

        if (!_dataViewsForTableColumns[tableColumnUID])
            _dataViewsForTableColumns[tableColumnUID] = [];

        var rowIndex = 0,
            rowsCount = rowArray.length,
            isColumnSelected = [_selectedColumnIndexes containsIndex:column];

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = [self _newDataViewForRow:row tableColumn:tableColumn],
                isButton = [dataView isKindOfClass:[CPButton class]],
                isTextField = [dataView isKindOfClass:[CPTextField class]];

            [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];

            //This gives the table column an opportunity to apply the bindings.
            //It will override the value set in the data source, if there is a data source.
            //It will do nothing if there is no value binding set.
            [tableColumn prepareDataView:dataView forRow:row];

            if (isColumnSelected || [self isRowSelected:row])
                [dataView setThemeState:CPThemeStateSelectedDataView];
            else
                [dataView unsetThemeState:CPThemeStateSelectedDataView];

            if (_implementedDelegateMethods & CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_)
                [_delegate tableView:self willDisplayView:dataView forTableColumn:tableColumn row:row];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            _dataViewsForTableColumns[tableColumnUID][row] = dataView;

            if (isButton || (_editingCellIndex && _editingCellIndex.x === column && _editingCellIndex.y === row))
            {
                if (!isButton)
                    _editingCellIndex = undefined;

                if (isTextField)
                {
                    [dataView setEditable:YES];
                    [dataView setSendsActionOnEndEditing:YES];
                    [dataView setSelectable:YES];
                    [dataView selectText:nil]; // Doesn't seem to actually work (yet?).
                }

                [dataView setTarget:self];
                [dataView setAction:@selector(_commitDataViewObjectValue:)];
                dataView.tableViewEditedColumnObj = tableColumn;
                dataView.tableViewEditedRowIndex = row;
            }
            else if (isTextField)
            {
                [dataView setEditable:NO];
                [dataView setSelectable:NO];
            }
        }
    }
}

- (void)_layoutDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
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
            tableColumnUID = [tableColumn UID],
            dataViewsForTableColumn = _dataViewsForTableColumns[tableColumnUID],
            columnRange = _tableColumnRanges[column],
            rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = dataViewsForTableColumn[row];

            [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];
        }
    }
}

- (void)_commitDataViewObjectValue:(id)sender
{
    [_dataSource tableView:self setObjectValue:[sender objectValue] forTableColumn:sender.tableViewEditedColumnObj row:sender.tableViewEditedRowIndex];

    if ([sender respondsToSelector:@selector(setEditable:)])
        [sender setEditable:NO];
}

- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    if ((_implementedDelegateMethods & CPTableViewDelegate_tableView_dataViewForTableColumn_row_))
    {
        var dataView = [_delegate tableView:self dataViewForTableColumn:aTableColumn row:aRow];
        [aTableColumn setDataView:dataView];
    }


    return [aTableColumn _newDataViewForRow:aRow];
}

- (void)_enqueueReusableDataView:(CPView)aDataView
{
    if (!aDataView)
        return;

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

- (void)setNeedsDisplay:(BOOL)aFlag
{
    [super setNeedsDisplay:aFlag];
    [_tableDrawView setNeedsDisplay:aFlag];
}

- (void)_drawRect:(CGRect)aRect
{
    // FIX ME: All three of these methods will likely need to be rewritten for 1.0
    // We've got grid drawing in highlightSelection and crap everywhere.

    var exposedRect = [self visibleRect];

    [self drawBackgroundInClipRect:exposedRect];
    [self drawGridInClipRect:exposedRect];
    [self highlightSelectionInClipRect:exposedRect];

    if (_implementsCustomDrawRow)
        [self _drawRows:_exposedRows clipRect:exposedRect];
}

- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    if (!_usesAlternatingRowBackgroundColors)
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
        var row = firstRow - firstRow % colorCount + colorIndex,
            fillRect = nil;

        CGContextBeginPath(context);

        for (; row <= lastRow; row += colorCount)
            if (row >= firstRow)
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
        var exposedRows = [self rowsInRect:aRect],
            row = exposedRows.location,
            lastRow = CPMaxRange(exposedRows) - 1,
            rowY = -0.5,
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
            var columnRect = [self rectOfColumn:columnsArray[columnArrayIndex]],
                columnX = _CGRectGetMaxX(columnRect) + 0.5;

            CGContextMoveToPoint(context, columnX, minY);
            CGContextAddLineToPoint(context, columnX, maxY);
        }
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, [self gridColor]);
    CGContextStrokePath(context);
}


- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    if (_selectionHighlightStyle === CPTableViewSelectionHighlightStyleNone)
        return;

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

    var count = count2 = [indexes count];

    if (!count)
        return;

    var drawGradient = (_selectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList && [_selectedRowIndexes count] >= 1),
        deltaHeight = 0.5 * (_gridStyleMask & CPTableViewSolidHorizontalGridLineMask);

    CGContextBeginPath(context);

    var gradientCache = [self selectionGradientColors],
        topLineColor = [gradientCache objectForKey:CPSourceListTopLineColor],
        bottomLineColor = [gradientCache objectForKey:CPSourceListBottomLineColor],
        gradientColor = [gradientCache objectForKey:CPSourceListGradient];

    while (count--)
    {
        var rowRect = CGRectIntersection(objj_msgSend(self, rectSelector, indexes[count]), aRect);
        CGContextAddRect(context, rowRect);

        if (drawGradient)
        {
            var minX = _CGRectGetMinX(rowRect),
                minY = _CGRectGetMinY(rowRect),
                maxX = _CGRectGetMaxX(rowRect),
                maxY = _CGRectGetMaxY(rowRect) - deltaHeight;

            CGContextDrawLinearGradient(context, gradientColor, rowRect.origin, CGPointMake(minX, maxY), 0);
            CGContextClosePath(context);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, minY);
            CGContextAddLineToPoint(context, maxX, minY);
            CGContextClosePath(context);
            CGContextSetStrokeColor(context, topLineColor);
            CGContextStrokePath(context);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, maxY);
            CGContextAddLineToPoint(context, maxX, maxY - 1);
            CGContextClosePath(context);
            CGContextSetStrokeColor(context, bottomLineColor);
            CGContextStrokePath(context);
        }
    }

    CGContextClosePath(context);

    if (!drawGradient)
    {
        [[self selectionHighlightColor] setFill];
        CGContextFillPath(context);
    }

    CGContextBeginPath(context);
    var gridStyleMask = [self gridStyleMask];
    for(var i = 0; i < count2; i++)
    {
         var rect = objj_msgSend(self, rectSelector, indexes[i]),
             minX = CGRectGetMinX(rect) - 0.5,
             maxX = CGRectGetMaxX(rect) - 0.5,
             minY = CGRectGetMinY(rect) - 0.5,
             maxY = CGRectGetMaxY(rect) - 0.5;

        if ([_selectedRowIndexes count] >= 1 && gridStyleMask & CPTableViewSolidVerticalGridLineMask)
        {
            var exposedColumns = [self columnIndexesInRect:aRect],
                exposedColumnIndexes = [],
                firstExposedColumn = [exposedColumns firstIndex],
                exposedRange = CPMakeRange(firstExposedColumn, [exposedColumns lastIndex] - firstExposedColumn + 1);
            [exposedColumns getIndexes:exposedColumnIndexes maxCount:-1 inIndexRange:exposedRange];
            var exposedColumnCount = [exposedColumnIndexes count];

            for (var c = firstExposedColumn; c < exposedColumnCount; c++)
            {
                var colRect = [self rectOfColumn:exposedColumnIndexes[c]],
                    colX = CGRectGetMaxX(colRect) + 0.5;

                CGContextMoveToPoint(context, colX, minY);
                CGContextAddLineToPoint(context, colX, maxY);
            }
        }

        //if the row after the current row is not selected then there is no need to draw the bottom grid line white.
        if ([indexes containsObject:indexes[i] + 1])
        {
            CGContextMoveToPoint(context, minX, maxY);
            CGContextAddLineToPoint(context, maxX, maxY);
        }
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:"highlighted-grid-color"]);
    CGContextStrokePath(context);
}

- (void)_drawRows:(CPIndexSet)rowsIndexes clipRect:(CGRect)clipRect
{
    var row = [rowsIndexes firstIndex];

    while (row !== CPNotFound)
    {
        [self drawRow:row clipRect:CGRectIntersection(clipRect, [self rectOfRow:row])];
        row = [rowsIndexes indexGreaterThanIndex:row];
    }
}

- (void)drawRow:(CPInteger)row clipRect:(CGRect)rect
{
    // This method does currently nothing in cappuccino. Can be overriden by subclasses.
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

/*
    @ignore
*/
- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

/*
    @ignore
*/
- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    //if the user clicks outside a row then deslect everything
    if (row < 0 && _allowsEmptySelection)
        [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];

    [self _noteSelectionIsChanging];

    if ([self mouseDownFlags] & CPShiftKeyMask)
        _selectionAnchorRow = (ABS([_selectedRowIndexes firstIndex] - row) < ABS([_selectedRowIndexes lastIndex] - row)) ?
            [_selectedRowIndexes firstIndex] : [_selectedRowIndexes lastIndex];
    else
        _selectionAnchorRow = row;


    //set ivars for startTrackingPoint and time...
    _startTrackingPoint = aPoint;
    _startTrackingTimestamp = new Date();

    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        _trackingPointMovedOutOfClickSlop = NO;

    // if the table has drag support then we use mouseUp to select a single row.
    // otherwise it uses mouse down.
    if (row >= 0 && !(_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_))
        [self _updateSelectionWithMouseAtRow:row];

    [[self window] makeFirstResponder:self];
    return YES;
}

/*
    @ignore
*/
- (void)trackMouse:(CPEvent)anEvent
{
    // Prevent CPControl from eating the mouse events when we are in a drag session
    if (![_draggedRowIndexes count])
    {
        [self autoscroll:anEvent];
        [super trackMouse:anEvent];
    }
    else
        [CPApp sendEvent:anEvent];
}

/*
    @ignore
*/
- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    // begin the drag is the datasource lets us, we've move at least +-3px vertical or horizontal,
    // or we're dragging from selected rows and we haven't begun a drag session
    if (!_isSelectingSession && _implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_)
    {
        if (row >= 0 && (ABS(_startTrackingPoint.x - aPoint.x) > 3 || (_verticalMotionCanDrag && ABS(_startTrackingPoint.y - aPoint.y) > 3)) ||
            ([_selectedRowIndexes containsIndex:row]))
        {
            if ([_selectedRowIndexes containsIndex:row])
                _draggedRowIndexes = [[CPIndexSet alloc] initWithIndexSet:_selectedRowIndexes];
            else
                _draggedRowIndexes = [CPIndexSet indexSetWithIndex:row];


            //ask the datasource for the data
            var pboard = [CPPasteboard pasteboardWithName:CPDragPboard];

            if ([self canDragRowsWithIndexes:_draggedRowIndexes atPoint:aPoint] && [_dataSource tableView:self writeRowsWithIndexes:_draggedRowIndexes toPasteboard:pboard])
            {
                var currentEvent = [CPApp currentEvent],
                    offset = CPPointMakeZero(),
                    tableColumns = [_tableColumns objectsAtIndexes:_exposedColumns];

                // We deviate from the default Cocoa implementation here by asking for a view in stead of an image
                // We support both, but the view prefered over the image because we can mimic the rows we are dragging
                // by re-creating the data views for the dragged rows
                var view = [self dragViewForRowsWithIndexes:_draggedRowIndexes
                                               tableColumns:tableColumns
                                                      event:currentEvent
                                                     offset:offset];

                if (!view)
                {
                    var image = [self dragImageForRowsWithIndexes:_draggedRowIndexes
                                                     tableColumns:tableColumns
                                                            event:currentEvent
                                                           offset:offset];
                    view = [[CPImageView alloc] initWithFrame:CPMakeRect(0, 0, [image size].width, [image size].height)];
                    [view setImage:image];
                }

                var bounds = [view bounds],
                    viewLocation = CPPointMake(aPoint.x - CGRectGetWidth(bounds) / 2 + offset.x, aPoint.y - CGRectGetHeight(bounds) / 2 + offset.y);
                [self dragView:view at:viewLocation offset:CPPointMakeZero() event:[CPApp currentEvent] pasteboard:pboard source:self slideBack:YES];
                _startTrackingPoint = nil;

                return NO;
            }

            // The delegate disallowed the drag so clear the dragged row indexes
            _draggedRowIndexes = [CPIndexSet indexSet];
        }
        else if (ABS(_startTrackingPoint.x - aPoint.x) < 5 && ABS(_startTrackingPoint.y - aPoint.y) < 5)
            return YES;
    }

    _isSelectingSession = YES;
    if (row >= 0 && row !== _lastTrackedRowIndex)
    {
        _lastTrackedRowIndex = row;
        [self _updateSelectionWithMouseAtRow:row];
    }

    if ((_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        && !_trackingPointMovedOutOfClickSlop)
    {
        var CLICK_SPACE_DELTA = 5.0; // Stolen from AppKit/Platform/DOM/CPPlatformWindow+DOM.j
        if (ABS(aPoint.x - _startTrackingPoint.x) > CLICK_SPACE_DELTA
            || ABS(aPoint.y - _startTrackingPoint.y) > CLICK_SPACE_DELTA)
        {
            _trackingPointMovedOutOfClickSlop = YES;
        }
    }

    return YES;
}

/*!
    @ignore
*/
- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _isSelectingSession = NO;

    var CLICK_TIME_DELTA = 1000,
        columnIndex,
        column,
        rowIndex,
        shouldEdit = YES;

    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_)
    {
        rowIndex = [self rowAtPoint:aPoint];
        if (rowIndex !== -1)
        {
            if ([_draggedRowIndexes count] > 0)
            {
                _draggedRowIndexes = [CPIndexSet indexSet];
                return;
            }
            // if the table has drag support then we use mouseUp to select a single row.
             _previouslySelectedRowIndexes = [_selectedRowIndexes copy];
            [self _updateSelectionWithMouseAtRow:rowIndex];
        }
    }

    if (mouseIsUp
        && (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        && !_trackingPointMovedOutOfClickSlop
        && ([[CPApp currentEvent] clickCount] > 1))
    {
        columnIndex = [self columnAtPoint:lastPoint];
        if (columnIndex !== -1)
        {
            column = _tableColumns[columnIndex];
            if ([column isEditable])
            {
                rowIndex = [self rowAtPoint:aPoint];
                if (rowIndex !== -1)
                {
                    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldEditTableColumn_row_)
                        shouldEdit = [_delegate tableView:self shouldEditTableColumn:column row:rowIndex];
                    if (shouldEdit)
                    {
                        [self editColumn:columnIndex row:rowIndex withEvent:nil select:YES];
                        return;
                    }
                }
            }
        }

    } //end of editing conditional

    //double click actions
    if ([[CPApp currentEvent] clickCount] === 2 && _doubleAction)
    {
        _clickedRow = [self rowAtPoint:aPoint];
        [self sendAction:_doubleAction to:_target];
    }
}

/*
    @ignore
*/
- (CPDragOperation)draggingEntered:(id)sender
{
    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        dropOperation = [self _proposedDropOperationAtPoint:location],
        row = [self _proposedRowAtPoint:location];

    if (_retargetedDropRow !== nil)
        row = _retargetedDropRow;

    var draggedTypes = [self registeredDraggedTypes],
        count = [draggedTypes count],
        i = 0;

    for (; i < count; i++)
    {
        if ([[[sender draggingPasteboard] types] containsObject:[draggedTypes objectAtIndex: i]])
            return [self _validateDrop:sender proposedRow:row proposedDropOperation:dropOperation];
    }

    return CPDragOperationNone;
}

/*
    @ignore
*/
- (void)draggingExited:(id)sender
{
    [_dropOperationFeedbackView removeFromSuperview];
}

/*
    @ignore
*/
- (void)draggingEnded:(id)sender
{
    [self _draggingEnded];
}

- (void)_draggingEnded
{
    _retargetedDropOperation = nil;
    _retargetedDropRow = nil;
    _draggedRowIndexes = [CPIndexSet indexSet];
    [_dropOperationFeedbackView removeFromSuperview];
}
/*
    @ignore
*/
- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

/*
    @ignore
*/
- (CPTableViewDropOperation)_proposedDropOperationAtPoint:(CGPoint)theDragPoint
{
    if (_retargetedDropOperation !== nil)
        return _retargetedDropOperation;

    var row = [self _proposedRowAtPoint:theDragPoint],
        rowRect = [self rectOfRow:row];

    // If there is no (the default) or to little inter cell spacing we create some room for the CPTableViewDropAbove indicator
    // This probably doesn't work if the row height is smaller than or around 5.0
    if ([self intercellSpacing].height < 5.0)
        rowRect = CPRectInset(rowRect, 0.0, 5.0 - [self intercellSpacing].height);

    // If the altered row rect contains the drag point we show the drop on
    // We don't show the drop on indicator if we are dragging below the last row
    // in that case we always want to show the drop above indicator
    if (CGRectContainsPoint(rowRect, theDragPoint) && row < _numberOfRows)
        return CPTableViewDropOn;

    return CPTableViewDropAbove;
}

/*
    @ignore
*/
- (CPInteger)_proposedRowAtPoint:(CGPoint)dragPoint
{
    // We don't use rowAtPoint here because the drag indicator can appear below the last row
    // and rowAtPoint doesn't return rows that are larger than numberOfRows
    // FIX ME: this is going to break when we implement variable row heights...
    var row = FLOOR(dragPoint.y / ( _rowHeight + _intercellSpacing.height )),
    // Determine if the mouse is currently closer to this row or the row below it
        lowerRow = row + 1,
        rect = [self rectOfRow:row],
        bottomPoint = CGRectGetMaxY(rect),
        bottomThirty = bottomPoint - ((bottomPoint - CGRectGetMinY(rect)) * 0.3);

    if (dragPoint.y > MAX(bottomThirty, bottomPoint - 6))
        row = lowerRow;

    if (row >= [self numberOfRows])
        row = [self numberOfRows];

    return row;
}

- (void)_validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)dropOperation
{
    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_)
        return [_dataSource tableView:self validateDrop:info proposedRow:row proposedDropOperation:dropOperation];

    return CPDragOperationNone;
}

- (CPRect)_rectForDropHighlightViewOnRow:(int)theRowIndex
{
    if (theRowIndex >= [self numberOfRows])
        theRowIndex = [self numberOfRows] - 1;

    return [self rectOfRow:theRowIndex];
}

- (CPRect)_rectForDropHighlightViewBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex offset:(CPPoint)theOffset
{
    if (theLowerRowIndex > [self numberOfRows])
        theLowerRowIndex = [self numberOfRows];

    return [self rectOfRow:theLowerRowIndex];
}

- (CPDragOperation)draggingUpdated:(id)sender
{
    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        dropOperation = [self _proposedDropOperationAtPoint:location],
        numberOfRows = [self numberOfRows],
        row = [self _proposedRowAtPoint:location],
        dragOperation = [self _validateDrop:sender proposedRow:row proposedDropOperation:dropOperation],
        exposedClipRect = [self visibleRect];

    if (_retargetedDropRow !== nil)
        row = _retargetedDropRow;


    if (dropOperation === CPTableViewDropOn && row >= [self numberOfRows])
        row = [self numberOfRows] - 1;

    var rect = _CGRectMakeZero();

    if (row === -1)
        rect = exposedClipRect;

    else if (dropOperation === CPTableViewDropAbove)
        rect = [self _rectForDropHighlightViewBetweenUpperRow:row - 1 andLowerRow:row offset:location];

    else
        rect = [self _rectForDropHighlightViewOnRow:row];

    [_dropOperationFeedbackView setDropOperation:row !== -1 ? dropOperation : CPDragOperationNone];
    [_dropOperationFeedbackView setHidden:(dragOperation == CPDragOperationNone)];
    [_dropOperationFeedbackView setFrame:rect];
    [_dropOperationFeedbackView setCurrentRow:row];
    [self addSubview:_dropOperationFeedbackView];

    return dragOperation;
}

/*
    @ignore
*/
- (BOOL)prepareForDragOperation:(id)sender
{
    // FIX ME: is there anything else that needs to happen here?
    // actual validation is called in dragginUpdated:
    [_dropOperationFeedbackView removeFromSuperview];

    return (_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_);
}

/*
    @ignore
*/
- (BOOL)performDragOperation:(id)sender
{
    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        operation = [self _proposedDropOperationAtPoint:location],
        row = _retargetedDropRow;

    if (row === nil)
        var row = [self _proposedRowAtPoint:location];

    return [_dataSource tableView:self acceptDrop:sender row:row dropOperation:operation];
}

/*
    @ignore
*/
- (void)concludeDragOperation:(id)sender
{
    [self reloadData];
}

/*
    //this method is sent to the data source for conviences...
*/
- (void)draggedImage:(CPImage)anImage endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    if([_dataSource respondsToSelector:@selector(tableView:didEndDraggedImage:atPosition:operation:)])
        [_dataSource tableView:self didEndDraggedImage:anImage atPosition:aLocation operation:anOperation];
}

/*
    @ignore
    we're using this because we drag views instead of images so we can get the rows themselves to actually drag
*/
- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    [self _draggingEnded];
    [self draggedImage:aView endedAt:aLocation operation:anOperation];
}

- (void)_updateSelectionWithMouseAtRow:(CPInteger)aRow
{
    //check to make sure the row exists
    if(aRow < 0)
        return;

    var newSelection,
        shouldExtendSelection = NO;
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
    {
        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionAnchorRow), ABS(aRow - _selectionAnchorRow) + 1)];
        shouldExtendSelection = [self mouseDownFlags] & CPShiftKeyMask &&
                                ((_lastSelectedRow == [_selectedRowIndexes lastIndex] && aRow > _lastSelectedRow) ||
                                (_lastSelectedRow == [_selectedRowIndexes firstIndex] && aRow < _lastSelectedRow));
    }

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

        // as per cocoa
        if ([newSelection count] === 0)
            return;
    }

    // if empty selection is not allowed and the new selection has nothing selected, abort
    if (!_allowsEmptySelection && [newSelection count] === 0)
        return;

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    [self selectRowIndexes:newSelection byExtendingSelection:shouldExtendSelection];
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

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(CPEvent)anEvent
{
    [self interpretKeyEvents:[anEvent]];
}

- (void)moveDown:(id)sender
{
    if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ &&
        ![_delegate selectionShouldChangeInTableView:self])
        return;

    var anEvent = [CPApp currentEvent];
    if([[self selectedRowIndexes] count] > 0)
    {
        var extend = NO;

        if(([anEvent modifierFlags] & CPShiftKeyMask) && _allowsMultipleSelection)
            extend = YES;

        var i = [[self selectedRowIndexes] lastIndex];
        if(i<[self numberOfRows] - 1)
            i++; //set index to the next row after the last row selected
    }
    else
    {
        var extend = NO;
        //no rows are currently selected
        if([self numberOfRows] > 0)
            var i = 0; //select the first row
    }


    if(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
    {

        while((![_delegate tableView:self shouldSelectRow:i]) && i<[self numberOfRows])
        {
            //check to see if the row can be selected if it can't be then see if the next row can be selected
            i++;
        }

        //if the index still can be selected after the loop then just return
         if(![_delegate tableView:self shouldSelectRow:i])
             return;
    }

    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:i] byExtendingSelection:extend];

    if(i >= 0)
        [self scrollRowToVisible:i];
}

- (void)moveDownAndModifySelection:(id)sender
{
    [self moveDown:sender];
}

- (void)moveUp:(id)sender
{
    if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ &&
        ![_delegate selectionShouldChangeInTableView:self])
        return;

    var anEvent = [CPApp currentEvent];
    if([[self selectedRowIndexes] count] > 0)
    {
         var extend = NO;

         if(([anEvent modifierFlags] & CPShiftKeyMask) && _allowsMultipleSelection)
           extend = YES;

          var i = [[self selectedRowIndexes] firstIndex];
          if(i > 0)
              i--; //set index to the prev row before the first row selected
    }
    else
    {
      var extend = NO;
      //no rows are currently selected
        if([self numberOfRows] > 0)
            var i = [self numberOfRows] - 1; //select the first row
     }


     if(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
     {

          while((![_delegate tableView:self shouldSelectRow:i]) && i > 0)
          {
              //check to see if the row can be selected if it can't be then see if the prev row can be selected
              i--;
          }

          //if the index still can be selected after the loop then just return
           if(![_delegate tableView:self shouldSelectRow:i])
               return;
     }

     [self selectRowIndexes:[CPIndexSet indexSetWithIndex:i] byExtendingSelection:extend];

     if(i >= 0)
        [self scrollRowToVisible:i];
}

- (void)moveUpAndModifySelection:(id)sender
{
    [self moveUp:sender];
}

- (void)deleteBackward:(id)sender
{
    if([_delegate respondsToSelector: @selector(tableViewDeleteKeyPressed:)])
        [_delegate tableViewDeleteKeyPressed:self];
}

@end

@implementation CPTableView (Bindings)

- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding === @"selectionIndexes")
        return @"selectedRowIndexes";

    return [super _replacementKeyPathForBinding:aBinding];
}

- (void)_establishBindingsIfUnbound:(id)destination
{
    if ([[self infoForBinding:@"content"] objectForKey:CPObservedObjectKey] !== destination)
        [self bind:@"content" toObject:destination withKeyPath:@"arrangedObjects" options:nil];

    if ([[self infoForBinding:@"selectionIndexes"] objectForKey:CPObservedObjectKey] !== destination)
        [self bind:@"selectionIndexes" toObject:destination withKeyPath:@"selectionIndexes" options:nil];

    //[self bind:@"sortDescriptors" toObject:destination withKeyPath:@"sortDescriptors" options:nil];
}

- (void)setContent:(CPArray)content
{
    [self reloadData];
}

@end

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
    CPTableViewHeaderViewKey                = @"CPTableViewHeaderViewKey",
    CPTableViewCornerViewKey                = @"CPTableViewCornerViewKey";

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

        if ([aCoder containsValueForKey:CPTableViewRowHeightKey])
            _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey];
        else
            _rowHeight = 23.0;

        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey] || _CGSizeMake(3.0, 2.0);

        [self setGridColor:[aCoder decodeObjectForKey:CPTableViewGridColorKey]];
        _gridStyleMask = [aCoder decodeIntForKey:CPTableViewGridStyleMaskKey] || CPTableViewGridNone;

        _usesAlternatingRowBackgroundColors = [aCoder decodeObjectForKey:CPTableViewUsesAlternatingBackgroundKey];
        [self setAlternatingRowBackgroundColors:[aCoder decodeObjectForKey:CPTableViewAlternatingRowColorsKey]];

        _headerView = [aCoder decodeObjectForKey:CPTableViewHeaderViewKey];
        _cornerView = [aCoder decodeObjectForKey:CPTableViewCornerViewKey];

        // Make sure we unhide the cornerview because a corner view loaded from cib is always hidden
        // This might be a bug in IB, or the way we load the NSvFlags might be broken for _NSCornerView
        if (_cornerView)
            [_cornerView setHidden:NO];

        _dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        _delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];

        [self _init];

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
    [aCoder encodeObject:[self alternatingRowBackgroundColors] forKey:CPTableViewAlternatingRowColorsKey]

    [aCoder encodeObject:_cornerView forKey:CPTableViewCornerViewKey];
    [aCoder encodeObject:_headerView forKey:CPTableViewHeaderViewKey];
}

@end

@implementation CPIndexSet (tableview)

- (void)removeMatches:otherSet
{
    var firstindex = [self firstIndex];
    var index = MIN(firstindex,[otherSet firstIndex]);
    var switchFlag = (index == firstindex);
    while(index != CPNotFound)
    {
        var indexSet = (switchFlag) ? otherSet : self;
        otherIndex = [indexSet indexGreaterThanOrEqualToIndex:index];
        if (otherIndex == index)
        {
            [self removeIndex:index];
            [otherSet removeIndex:index];
        }
        index = otherIndex;
        switchFlag = !switchFlag;
    }
}

@end

@implementation _CPDropOperationDrawingView : CPView
{
    unsigned    dropOperation @accessors;
    CPTableView tableView @accessors;
    int         currentRow @accessors;
    BOOL        isBlinking @accessors;
}

- (void)drawRect:(CGRect)aRect
{
    if(tableView._destinationDragStyle === CPTableViewDraggingDestinationFeedbackStyleNone || isBlinking)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
    CGContextSetLineWidth(context, 3);

    if (currentRow === -1)
    {
        CGContextStrokeRect(context, [self bounds]);
    }

    else if (dropOperation === CPTableViewDropOn)
    {
        //if row is selected don't fill and stroke white
        var selectedRows = [tableView selectedRowIndexes],
            newRect = _CGRectMake(aRect.origin.x + 2, aRect.origin.y + 2, aRect.size.width - 4, aRect.size.height - 5);

        if([selectedRows containsIndex:currentRow])
        {
            CGContextSetLineWidth(context, 2);
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
        }
        else
        {
            CGContextSetFillColor(context, [CPColor colorWithRed:72/255 green:134/255 blue:202/255 alpha:0.25]);
            CGContextFillRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);
        }
        CGContextStrokeRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);

    }
    else if (dropOperation === CPTableViewDropAbove)
    {
        //reposition the view up a tad
        [self setFrameOrigin:CGPointMake(_frame.origin.x, _frame.origin.y - 8)];

        var selectedRows = [tableView selectedRowIndexes];

        if([selectedRows containsIndex:currentRow - 1] || [selectedRows containsIndex:currentRow])
        {
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
            CGContextSetLineWidth(context, 4);
            //draw the circle thing
            CGContextStrokeEllipseInRect(context, _CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
            //then draw the line
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
            CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
            CGContextClosePath(context);
            CGContextStrokePath(context);

            CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
            CGContextSetLineWidth(context, 3);
        }

        //draw the circle thing
        CGContextStrokeEllipseInRect(context, _CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
        //then draw the line
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
        CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
        CGContextClosePath(context);
        CGContextStrokePath(context);
        //CGContextStrokeLineSegments(context, [aRect.origin.x + 8,  aRect.origin.y + 8, 300 , aRect.origin.y + 8]);
    }
}

- (void)blink
{
    if (dropOperation !== CPTableViewDropOn)
        return;

    isBlinking = YES;

    var showCallback = function() {
        objj_msgSend(self, "setHidden:", NO)
        isBlinking = NO;
    }

    var hideCallback = function() {
        objj_msgSend(self, "setHidden:", YES)
        isBlinking = YES;
    }

    objj_msgSend(self, "setHidden:", YES);
    [CPTimer scheduledTimerWithTimeInterval:0.1 callback:showCallback repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.19 callback:hideCallback repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.27 callback:showCallback repeats:NO];
}
@end

@implementation _CPColumnDragView : CPView
{
    CPColor _lineColor;
}

- (id)initWithLineColor:(CPColor)aColor
{
    self = [super initWithFrame:_CGRectMakeZero()];

    if (self)
        _lineColor = aColor;

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, _lineColor);

    var points = [
                    _CGPointMake(0.5, 0),
                    _CGPointMake(0.5, aRect.size.height)
                 ];

    CGContextStrokeLineSegments(context, points, 2);

    points = [
                _CGPointMake(aRect.size.width - 0.5, 0),
                _CGPointMake(aRect.size.width - 0.5, aRect.size.height)
             ];

    CGContextStrokeLineSegments(context, points, 2);
}
@end
