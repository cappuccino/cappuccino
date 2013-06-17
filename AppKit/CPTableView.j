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
@import <Foundation/CPIndexSet.j>

@import "CPDragServer_Constants.j"
@import "CGGradient.j"
@import "CPCib.j"
@import "CPCompatibility.j"
@import "CPControl.j"
@import "CPImageView.j"
@import "CPScroller.j"
@import "CPScrollView.j"
@import "CPTableColumn.j"
@import "CPTableHeaderView.j"
@import "CPText.j"
@import "_CPCornerView.j"

@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPClipView
@class CPButton

@global CPApp


CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";

var CPTableViewDataSource_numberOfRowsInTableView_                                                      = 1 << 0,
    CPTableViewDataSource_tableView_objectValueForTableColumn_row_                                      = 1 << 1,
    CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2,
    CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_                                       = 1 << 3,
    CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_ = 1 << 4,
    CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_                     = 1 << 5,
    CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_                                  = 1 << 6,

    CPTableViewDataSource_tableView_sortDescriptorsDidChange_                                           = 1 << 7;

var CPTableViewDelegate_selectionShouldChangeInTableView_                                               = 1 << 0,
    CPTableViewDelegate_tableView_viewForTableColumn_row_                                               = 1 << 1,
    CPTableViewDelegate_tableView_dataViewForTableColumn_row_                                           = 1 << 21,
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
    CPTableViewDelegate_tableViewSelectionIsChanging_                                                   = 1 << 19,
    CPTableViewDelegate_tableViewMenuForTableColumn_Row_                                                = 1 << 20,
    CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_                                         = 1 << 21;

//CPTableViewDraggingDestinationFeedbackStyles
CPTableViewDraggingDestinationFeedbackStyleNone = -1;
CPTableViewDraggingDestinationFeedbackStyleRegular = 0;
CPTableViewDraggingDestinationFeedbackStyleSourceList = 1;

//CPTableViewDropOperations
CPTableViewDropOn = 0;
CPTableViewDropAbove = 1;

CPSourceListGradient = @"CPSourceListGradient";
CPSourceListTopLineColor = @"CPSourceListTopLineColor";
CPSourceListBottomLineColor = @"CPSourceListBottomLineColor";

// TODO: add docs

CPTableViewSelectionHighlightStyleNone = -1;
CPTableViewSelectionHighlightStyleRegular = 0;
CPTableViewSelectionHighlightStyleSourceList = 1;

CPTableViewGridNone                     = 0;
CPTableViewSolidVerticalGridLineMask    = 1 << 0;
CPTableViewSolidHorizontalGridLineMask  = 1 << 1;

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

    CGContextTranslateCTM(context, -CGRectGetMinX(frame), -CGRectGetMinY(frame));

    [_tableView _drawRect:aRect];
}

@end

/*!
    @ingroup appkit
    @class CPTableView

    CPTableView object displays record-oriented data in a table and
    allows the user to edit values and resize and rearrange columns.
    A CPTableView requires you to either set a data source which implements
    @ref numberofrows "numberOfRowsInTableView:" and @ref objectValueForTable "tableView:objectValueForTableColumn:row:",
    or alternatively to provide data through Key Value Bindings.

    To use a table view with Key Value Bindings, bind each column's
    \c CPValueBinding to an \c array.field path - typically this would be to a path
    in an array controller like \c arrangedObjects.X, where \c X is the name of a
    field. Optionally also bind the table's \c selectionIndexes and
    \c sortDescriptors to the array controller.

    All delegate and data source methods are documented in the @ref setdatasource "setDataSource:" and @ref setdelegate "setDelegate:" methods.

    If you want to display something other than just text in the table you should call @link CPTableColumn::setDataView: setDataView:@endlink on a CPTableColumn object. More documentation in that class including theme states.

    @note CPTableView does not contain its own scrollview. You should be sure you place the tableview in a CPScrollView on your own.

*/
@implementation CPTableView : CPControl
{
    id                  _dataSource;
    CPInteger           _implementedDataSourceMethods;

    id                  _delegate;
    CPInteger           _implementedDelegateMethods;

    CPArray             _tableColumns;
    CPArray             _tableColumnRanges;
    CPInteger           _dirtyTableColumnRangeIndex;
    CPInteger           _numberOfHiddenColumns;

    BOOL                _reloadAllRows;
    Object              _objectValues;

    CGRect              _exposedRect;
    CPIndexSet          _exposedRows;
    CPIndexSet          _exposedColumns;

    Object              _dataViewsForTableColumns;
    Object              _cachedDataViews;
    CPDictionary        _archivedDataViews;
    Object              _unavailable_custom_cibs;

    //Configuring Behavior
    BOOL                _allowsColumnReordering;
    BOOL                _allowsColumnResizing;
    BOOL                _allowsColumnSelection;
    BOOL                _allowsMultipleSelection;
    BOOL                _allowsEmptySelection;

    CPArray             _sortDescriptors;

    //Setting Display Attributes
    CGSize              _intercellSpacing;
    float               _rowHeight;

    BOOL                _usesAlternatingRowBackgroundColors;
    CPArray             _alternatingRowBackgroundColors;

    unsigned            _selectionHighlightStyle;
    CPColor             _unfocusedSelectionHighlightColor;
    CPDictionary        _unfocusedSourceListSelectionColor;
    CPTableColumn       _currentHighlightedTableColumn;
    unsigned            _gridStyleMask;

    unsigned            _numberOfRows;
    CPIndexSet          _groupRows;

    CPArray             _cachedRowHeights;

    // Persistence
    CPString            _autosaveName;
    BOOL                _autosaveTableColumns;

    CPTableHeaderView   _headerView;
    _CPCornerView       _cornerView;

    CPIndexSet          _selectedColumnIndexes;
    CPIndexSet          _selectedRowIndexes;
    CPInteger           _selectionAnchorRow;
    CPInteger           _lastSelectedRow;
    CPIndexSet          _previouslySelectedRowIndexes;
    CGPoint             _startTrackingPoint;
    CPDate              _startTrackingTimestamp;
    BOOL                _trackingPointMovedOutOfClickSlop;
    CGPoint             _editingCellIndex;
    CPInteger           _editingRow;
    CPInteger           _editingColumn;

    _CPTableDrawView    _tableDrawView;

    SEL                 _doubleAction;
    CPInteger           _clickedRow;
    CPInteger           _clickedColumn;
    unsigned            _columnAutoResizingStyle;

    int                 _lastTrackedRowIndex;
    CGPoint             _originalMouseDownPoint;
    BOOL                _verticalMotionCanDrag;
    unsigned            _destinationDragStyle;
    BOOL                _isSelectingSession;
    CPIndexSet          _draggedRowIndexes;
    BOOL                _wasSelectionBroken;

    _CPDropOperationDrawingView _dropOperationFeedbackView;
    CPDragOperation     _dragOperationDefaultMask;
    int                 _retargetedDropRow;
    CPDragOperation     _retargetedDropOperation;
    CPArray             _draggingViews;

    BOOL                _disableAutomaticResizing @accessors(property=disableAutomaticResizing);
    BOOL                _lastColumnShouldSnap;
    BOOL                _implementsCustomDrawRow;
    BOOL                _isViewBased;
    BOOL                _contentBindingExplicitlySet;

    SEL                 _viewForTableColumnRowSelector;

    CPTableColumn       _draggedColumn;
    CPArray             _differedColumnDataToRemove;
}

/*!
    @ignore
*/
+ (CPString)defaultThemeClass
{
    return @"tableview";
}

/*!
    @ignore
*/
+ (id)themeAttributes
{
    return @{
            @"alternating-row-colors": [CPNull null],
            @"grid-color": [CPNull null],
            @"highlighted-grid-color": [CPNull null],
            @"selection-color": [CPNull null],
            @"sourcelist-selection-color": [CPNull null],
            @"sort-image": [CPNull null],
            @"sort-image-reversed": [CPNull null],
            @"selection-radius": [CPNull null],
            @"image-generic-file": [CPNull null],
            @"default-row-height": 25.0,
        };
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

        _intercellSpacing = CGSizeMake(3.0, 2.0);
        _rowHeight = [self valueForThemeAttribute:@"default-row-height"];

        [self setGridColor:[CPColor colorWithHexString:@"dce0e2"]];
        [self setGridStyleMask:CPTableViewGridNone];

        [self setHeaderView:[[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)]];
        [self setCornerView:[[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))]];

        _currentHighlightedTableColumn = nil;

        _draggedRowIndexes = [CPIndexSet indexSet];
        _verticalMotionCanDrag = YES;
        _isSelectingSession = NO;
        _retargetedDropRow = nil;
        _retargetedDropOperation = nil;
        _dragOperationDefaultMask = nil;
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;
        _contentBindingExplicitlySet = NO;

        [self setBackgroundColor:[CPColor whiteColor]];
        [self _init];
    }

    return self;
}


/*!
    @ignore
    FIX ME: we have a lot of redundant init stuff in initWithFrame: and initWithCoder: we should move it all into here.
    we should do a full audit of all the initializers before 1.0
*/
- (void)_init
{
    _lastSelectedRow = _clickedColumn = _clickedRow = -1;

    _selectedColumnIndexes = [CPIndexSet indexSet];
    _selectedRowIndexes = [CPIndexSet indexSet];

    _dropOperationFeedbackView = [[_CPDropOperationDrawingView alloc] initWithFrame:CGRectMakeZero()];
    [_dropOperationFeedbackView setTableView:self];

    _lastColumnShouldSnap = NO;

    if (!_alternatingRowBackgroundColors)
        _alternatingRowBackgroundColors = [[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]];

    _tableColumnRanges = [];
    _dirtyTableColumnRangeIndex = 0;
    _numberOfHiddenColumns = 0;

    _objectValues = { };
    _dataViewsForTableColumns = { };
    _numberOfRows = 0;
    _exposedRows = [CPIndexSet indexSet];
    _exposedColumns = [CPIndexSet indexSet];
    _cachedDataViews = { };
    _archivedDataViews = nil;
    _viewForTableColumnRowSelector = nil;
    _unavailable_custom_cibs = { };
    _cachedRowHeights = [];

    _groupRows = [CPIndexSet indexSet];

    _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
    [_tableDrawView setBackgroundColor:[CPColor clearColor]];
    [self addSubview:_tableDrawView];

    _draggedColumn = nil;
    _draggingViews = [CPArray array];

    _editingRow = CPNotFound;
    _editingColumn = CPNotFound;

/*      //gradients for the source list when CPTableView is NOT first responder or the window is NOT key
    // FIX ME: we need to actually implement this.
    _sourceListInactiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [168.0/255.0,183.0/255.0,205.0/255.0,1.0,157.0/255.0,174.0/255.0,199.0/255.0,1.0], [0,1], 2);
    _sourceListInactiveTopLineColor = [CPColor colorWithCalibratedRed:(173.0/255.0) green:(187.0/255.0) blue:(209.0/255.0) alpha:1.0];
    _sourceListInactiveBottomLineColor = [CPColor colorWithCalibratedRed:(150.0/255.0) green:(161.0/255.0) blue:(183.0/255.0) alpha:1.0];*/
    _differedColumnDataToRemove = [];
    _implementsCustomDrawRow = [self implementsSelector:@selector(drawRow:clipRect:)];

    if (!_sortDescriptors)
        _sortDescriptors = [];

    [self _startObservingFirstResponder];
}

/*!
@anchor setdatasource
    Sets the receiver's data source to a given object.
    The data source implements various methods for handling the tableview's data when bindings are not used.
    @param anObject The data source for the receiver. This object must implement numberOfRowsInTableView: and tableView:objectValueForTableColumn:row:

    These methods are outlined below.


@section overview Overview
    CPTableView generally requires a datasource to run. This data source can be thought of just like a delegate, but specifically for the tableview data.
    Methods include:

@section required Required Methods
@anchor numberofrows
Returns the number of rows in the tableview
    @code
- (int)numberOfRowsInTableView:(CPTableView)aTableView;
    @endcode

Returns the object value for each dataview. Each dataview will be sent a setObjectValue: method which will contain the object you return from this datasource method.
@anchor objectValueForTable
    @code
- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRowIndex;
    @endcode


@section editing Editing:
Sets the data object for an item in a given row and column. This needs to be implemented if you want inline editing support
    @code
- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex;
    @endcode


@section sorting Sorting:
The tableview will call this method if you click the tableheader. You should sort the datasource based off of the new sort descriptors and reload the data
    @code
- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors;
    @endcode


@section draganddrop Drag and Drop:
@note In order for the tableview to receive drops don't forget to first register the tableview for drag types like you do with every other view.

Return the drag operation (move, copy, etc) that should be performed if a registered drag type is over the tableview
        The data source can retarget a drop if you want by calling <pre>-(void)setDropRow:(int)aRow dropOperation:(CPTableViewDropOperation)anOperation;</pre>
    @code
- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(CPDraggingInfo)info proposedRow:(int)row proposedDropOperation:(CPTableViewDropOperation)operation;
    @endcode

Returns YES if the drop operation is allowed otherwise NO. This method is invoked by the tableview after a drag should begin, but before it is started. If you don't want the drag to being return NO. If you want the drag to begin you should return YES and place the drag data on the pboard.
    @code
- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard;
    @endcode

Return YES if the operation was successful otherwise return NO. The data source should incorporate the data from the dragging pasteboard in this method implementation. To get this data use the draggingPasteboard method on the CPDraggingInfo object.
    @code
- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(CPDraggingInfo)info row:(int)row dropOperation:(CPTableViewDropOperation)operation;
    @endcode

NOT YET IMPLEMENTED
    @code
- (CPArray)tableView:(CPTableView)aTableView namesOfPromisedFilesDroppedAtDestination:(CPURL)dropDestination forDraggedRowsWithIndexes:(CPIndexSet)indexSet;
    @endcode
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

    if ([_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_objectValueForTableColumn_row_;

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
    _cachedRowHeights = [];

    // Otherwise, if we have a row marked as group with a
    // index greater than the new number or rows
    // it keeps the the graphical group style.
    [_groupRows removeAllIndexes];

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

/*!
    Returns the double click action selector.
*/
- (SEL)doubleAction
{
    return _doubleAction;
}

/*
    Returns the index of the the column the user clicked to trigger an action, or -1 if no column was clicked.
*/
- (CPInteger)clickedColumn
{
    return _clickedColumn;
}

/*!
    Returns the index of the the row the user clicked to trigger an action, or -1 if no row was clicked.
*/
- (CPInteger)clickedRow
{
    return _clickedRow;
}

//Configuring Behavior

/*!
    If you want to allow the user to reorder the columns pass YES, otherwise NO.
*/
- (void)setAllowsColumnReordering:(BOOL)shouldAllowColumnReordering
{
    _allowsColumnReordering = !!shouldAllowColumnReordering;
}

/*!
    Returns YES if the user is allowed to reorder the columns, otherwise NO.
*/
- (BOOL)allowsColumnReordering
{
    return _allowsColumnReordering;
}

/*!
    Passing YES will allow the user to resize columns. Passing NO will keep the table columns unmovable by the user.
    @note The this does not affect autoresizing behavior.
*/
- (void)setAllowsColumnResizing:(BOOL)shouldAllowColumnResizing
{
    _allowsColumnResizing = !!shouldAllowColumnResizing;
}

/*!
    Returns YES if the user is allowed to manually resize the columns, otherwise NO.
*/
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

/*!
    Returns YES if the tableview is allowed to have multiple selections, otherwise NO.

    @return BOOL - YES if the tableview is allowed to have multiple selections otherwise NO.
*/
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

/*!
    Returns YES if the tableview is allowed to have an unselected row or column, otherwise NO.
*/
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


/*!
    Returns YES if the user is allowed to select a column by clicking it, otherwise NO.
*/
- (BOOL)allowsColumnSelection
{
    return _allowsColumnSelection;
}

//Setting Display Attributes
/*!
    Sets the width and height between dataviews.
    This value is (3.0, 2.0) by default.

    @param aSize a CGSize object that defines the space between the cells
*/
- (void)setIntercellSpacing:(CGSize)aSize
{
    if (CGSizeEqualToSize(_intercellSpacing, aSize))
        return;

    _intercellSpacing = CGSizeMakeCopy(aSize);

    _dirtyTableColumnRangeIndex = 0; // so that _recalculateTableColumnRanges will work
    [self _recalculateTableColumnRanges];

    [self setNeedsLayout];
    [_headerView setNeedsDisplay:YES];
    [_headerView setNeedsLayout];

    [self reloadData];
}

/*!
    Returns the intercell spacing in a CGSize object.
*/
- (CGSize)intercellSpacing
{
    return CGSizeMakeCopy(_intercellSpacing);
}

/*!
    Sets the height of each row.
    @note This may still used even if variable row height is being used.

    @param aRowHeight the height of each row
*/
- (void)setRowHeight:(unsigned)aRowHeight
{
    // Accept row heights such as "0".
    aRowHeight = +aRowHeight;

    if (_rowHeight === aRowHeight)
        return;

    _rowHeight = MAX(0.0, aRowHeight);

    [self setNeedsLayout];
}

/*!
    Returns the height of each row.
*/
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

/*!
    Returns YES if the tableview uses alternating row background colors, otherwise NO.
*/
- (BOOL)usesAlternatingRowBackgroundColors
{
    return _usesAlternatingRowBackgroundColors;
}

/*!
    Sets the colors for the rows as they alternate. The number of colors can be arbitrary. By default these colors are white and light blue.
    @param anArray an array of CPColors
*/

- (void)setAlternatingRowBackgroundColors:(CPArray)alternatingRowBackgroundColors
{
    [self setValue:alternatingRowBackgroundColors forThemeAttribute:@"alternating-row-colors"];

    [self setNeedsDisplay:YES];
}

/*!
    Returns an array of the alternating background colors
*/
- (CPArray)alternatingRowBackgroundColors
{
    return [self currentValueForThemeAttribute:@"alternating-row-colors"];
}

/*!
    Returns an enumerated value for the selection highlight style.


    Valid values are:
<pre>
        CPTableViewSelectionHighlightStyleNone
        CPTableViewSelectionHighlightStyleRegular
        CPTableViewSelectionHighlightStyleSourceList
</pre>
*/
- (unsigned)selectionHighlightStyle
{
    return _selectionHighlightStyle;
}

/*!
    Sets the selection highlight style to an enumerated value.
    This value can also affect the way the tableview draws feedback when the user is dragging.

    Valid values are:
<pre>
        CPTableViewSelectionHighlightStyleNone
        CPTableViewSelectionHighlightStyleRegular
        CPTableViewSelectionHighlightStyleSourceList
</pre>
*/
- (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    _selectionHighlightStyle = aSelectionHighlightStyle;

    if (aSelectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList)
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleSourceList;
    else
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;

    [self _updateHighlightWithOldRows:[CPIndexSet indexSet] newRows:_selectedRowIndexes];
    [self _updateHighlightWithOldColumns:[CPIndexSet indexSet] newColumns:_selectedColumnIndexes];
    [self setNeedsDisplay:YES];
}

/*!
    Sets the highlight color for a row or column selection.

    @param aColor a CPColor
*/
- (void)setSelectionHighlightColor:(CPColor)aColor
{
    if ([[self selectionHighlightColor] isEqual:aColor])
        return;

    [self setValue:aColor forThemeAttribute:@"selection-color"];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the highlight color for a focused row or column selection.
*/
- (CPColor)selectionHighlightColor
{
    return [self currentValueForThemeAttribute:@"selection-color"];
}

/*!
    Returns the highlight color for an unfocused row or column selection.
*/
- (CPColor)unfocusedSelectionHighlightColor
{
    if (!_unfocusedSelectionHighlightColor)
        _unfocusedSelectionHighlightColor = [self _unfocusedSelectionColorFromColor:[self selectionHighlightColor] saturation:0];

    return _unfocusedSelectionHighlightColor;
}

/*!

    Sets the highlight gradient for a row or column selection
    This is specific to the
    @param aDictionary a CPDictionary expects three keys to be set:
<pre>
        CPSourceListGradient which is a CGGradient
        CPSourceListTopLineColor which is a CPColor
        CPSourceListBottomLineColor which is a CPColor
</pre>
*/
- (void)setSelectionGradientColors:(CPDictionary)aDictionary
{
    [self setValue:aDictionary forThemeAttribute:@"sourcelist-selection-color"];
    [self setNeedsDisplay:YES];
}

/*!
    Returns a dictionary of containing the keys:
<pre>
    CPSourceListGradient
    CPSourceListTopLineColor
    CPSourceListBottomLineColor
</pre>
*/
- (CPDictionary)selectionGradientColors
{
    return [self currentValueForThemeAttribute:@"sourcelist-selection-color"];
}

/*!
    Returns a dictionary of containing the keys:
<pre>
    CPSourceListGradient
    CPSourceListTopLineColor
    CPSourceListBottomLineColor
</pre>
*/

- (void)unfocusedSelectionGradientColors
{
    if (!_unfocusedSourceListSelectionColor)
    {
        var sourceListColors = [self selectionGradientColors];

        _unfocusedSourceListSelectionColor = @{
            CPSourceListGradient: [self _unfocusedGradientFromGradient:[sourceListColors objectForKey:CPSourceListGradient]],
            CPSourceListTopLineColor: [self _unfocusedSelectionColorFromColor:[sourceListColors objectForKey:CPSourceListTopLineColor] saturation:0.2],
            CPSourceListBottomLineColor: [self _unfocusedSelectionColorFromColor:[sourceListColors objectForKey:CPSourceListBottomLineColor] saturation:0.2]
        };
    }

    return _unfocusedSourceListSelectionColor;
}

- (CPColor)_unfocusedSelectionColorFromColor:(CPColor)aColor saturation:(float)saturation
{
    var hsb = [aColor hsbComponents];

    return [CPColor colorWithHue:hsb[0] saturation:hsb[1] * saturation brightness:hsb[2]];
}

- (CGGradient)_unfocusedGradientFromGradient:(CGGradient)aGradient
{
    var colors = [aGradient.colors copy],
        count = [colors count];

    while (count--)
    {
        var rgba = colors[count].components,
            hsb = [self _unfocusedSelectionColorFromColor:[CPColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:rgba[3]] saturation:0.2];

        colors[count] = CGColorCreate(aGradient.colorspace, [[hsb components] copy]);
    }

    return CGGradientCreateWithColors(aGradient.colorspace, colors, aGradient.locations);
}

/*!
    Sets the grid color in the non highlighted state.
    @param aColor a CPColor
*/
- (void)setGridColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"grid-color"];

    [self setNeedsDisplay:YES];
}

/*!
    Returns a CPColor object of set grid color
*/
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

/*!
    Returns a grid mask
*/
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

    if ([[self sortDescriptors] count] > 0)
    {
        var mainSortDescriptor = [[self sortDescriptors] objectAtIndex:0];

        if (aTableColumn === [self _tableColumnForSortDescriptor:mainSortDescriptor])
        {
            var image = [mainSortDescriptor ascending] ? [self _tableHeaderSortImage] : [self _tableHeaderReverseSortImage];
            [self setIndicatorImage:image inTableColumn:aTableColumn];
        }
    }

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

    // we defer the actual removal until the end of the runloop in order to keep a reference to the column.
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

    [_tableColumns removeObject:aTableColumn];

    [self setNeedsLayout];
}

/*!
    @ignore
    Internally used to set a column that will be dragged
*/
- (void)_setDraggedColumn:(CPTableColumn)aColumn
{
    if (_draggedColumn === aColumn)
        return;

    var previouslyDraggedColumn = _draggedColumn;
    _draggedColumn = aColumn;

    // if a column is currently being dragged, update that column (removing data views)
    if (aColumn)
        [self reloadDataForRowIndexes:_exposedRows columnIndexes:[CPIndexSet indexSetWithIndex:[_tableColumns indexOfObject:aColumn]]];

    // when the column is dropped, we should also update it.
    if (previouslyDraggedColumn)
        [self reloadDataForRowIndexes:_exposedRows columnIndexes:[CPIndexSet indexSetWithIndex:[_tableColumns indexOfObject:previouslyDraggedColumn]]];
}

/*
    @ignore
    Returns YES if the column at columnIndex can be reordered.
    It can be possible if column reordering is allowed and if the tableview
    delegate also accept the reordering
*/
- (BOOL)_shouldReorderColumn:(int)columnIndex toColumn:(int)newColumnIndex
{
    if ([self allowsColumnReordering] &&
        _implementedDelegateMethods & CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_)
    {
        return [_delegate tableView:self shouldReorderColumn:columnIndex toColumn:newColumnIndex];
    }

    return [self allowsColumnReordering];
}

/*
    @ignore
    Same as moveColumn:toColumn: but doesn't trigger an autosave
*/
- (void)_moveColumn:(unsigned)fromIndex toColumn:(unsigned)toIndex
{
    // Convert parameters such as "0" to 0.
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

    // Notify even if programmatically moving a column as in Cocoa.
    // TODO Only notify when a column drag operation ends, not each time a column reaches a new slot?
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewColumnDidMoveNotification
                                                        object:self
                                                      userInfo:@{  @"CPOldColumn": fromIndex, @"CPNewColumn": toIndex }];
}

/*!
    Moves the column and heading at a given index to a new given index.
    @param theColumnIndex The current index of the column to move.
    @param theToIndex The new index for the moved column.
*/
- (void)moveColumn:(int)theColumnIndex toColumn:(int)theToIndex
{
    [self _moveColumn:theColumnIndex toColumn:theToIndex];
    [self _autosave];
}

/*!
    @ignore
    Called when a table column changes visibility
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

/*!
    Returns an array of CPTableColumns of all the receiver's columns.
*/
- (CPArray)tableColumns
{
    return _tableColumns;
}

/*!
    Returns the index of the column with the specified identifier

    @param anIdentifier the string value of the tablecolumn identifier
    @return the index of the column
*/
- (CPInteger)columnWithIdentifier:(CPString)anIdentifier
{
    var index = 0,
        count = NUMBER_OF_COLUMNS();

    for (; index < count; ++index)
        if ([_tableColumns[index] identifier] === anIdentifier)
            return index;

    return CPNotFound;
}

/*!
    Returns the CPTableColumn object with the given identifier string.

    @param anIdentifier the string value of the identifier
    @return a CPTableColumn object with the given identifier
*/
- (CPTableColumn)tableColumnWithIdentifier:(CPString)anIdentifier
{
    var index = [self columnWithIdentifier:anIdentifier];

    if (index === CPNotFound)
        return nil;

    return _tableColumns[index];
}

/*!
    @ignore
*/
- (void)_didResizeTableColumn:(CPTableColumn)theColumn
{
    [self _autosave];
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

/*!
    @ignore
*/
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

    var binderClass = [[self class] _binderClassForBinding:@"selectionIndexes"];
    [[binderClass getBinding:@"selectionIndexes" forObject:self] reverseSetValueFor:@"selectedRowIndexes"];

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
        (([rows firstIndex] != CPNotFound && [rows firstIndex] < 0) || [rows lastIndex] >= [self numberOfRows]) ||
        [self numberOfColumns] <= 0)
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

/*!
    @ignore
*/
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

    var showsSelection = _selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone,
        selectors = [@selector(unsetThemeState:), @selector(setThemeState:)],
        selectInfo = [
            { rows:deselectRows, selectorIndex:0 },
            { rows:selectRows,   selectorIndex:showsSelection ? 1 : 0 }
        ];

    for (var identifier in _dataViewsForTableColumns)
    {
        var dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        for (var i = 0; i < selectInfo.length; ++i)
        {
            var info = selectInfo[i],
                count = info.rows.length;

            while (count--)
            {
                var view = dataViewsInTableColumn[info.rows[count]];
                [view performSelector:selectors[info.selectorIndex] withObject:CPThemeStateSelectedDataView];
            }
        }
    }
}

/*!
    @ignore
*/
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

    var showsSelection = _selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone,
        selectors = [@selector(unsetThemeState:), @selector(setThemeState:)],

        // Rows do not show selection with CPTableViewSelectionHighlightStyleNone, but headers do
        selectInfo = [
            {
                columns:deselectColumns,
                rowSelectorIndex:0,
                headerSelectorIndex:0
            },
            {
                columns:selectColumns,
                rowSelectorIndex:showsSelection ? 1 : 0,
                headerSelectorIndex:1
            }
        ],
        rowsCount = selectRows.length;

    for (var selectIndex = 0; selectIndex < selectInfo.length; ++selectIndex)
    {
        var info = selectInfo[selectIndex],
            count = info.columns.length,
            rowSelector = selectors[info.rowSelectorIndex],
            headerSelector = selectors[info.headerSelectorIndex];

        while (count--)
        {
            var columnIndex = info.columns[count],
                identifier = [_tableColumns[columnIndex] UID],
                dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

            for (var i = 0; i < rowsCount; i++)
            {
                var rowIndex = selectRows[i],
                    dataView = dataViewsInTableColumn[rowIndex];

                [dataView performSelector:rowSelector withObject:CPThemeStateSelectedDataView];
            }

            if (_headerView)
            {
                var headerView = [_tableColumns[columnIndex] headerView];
                [headerView performSelector:headerSelector withObject:CPThemeStateSelected];
            }
        }
    }
}

/*!
    Returns the index of the last selected column.
*/
- (int)selectedColumn
{
    return [_selectedColumnIndexes lastIndex];
}

/*!
    Returns an index set of all the selected columns.
*/
- (CPIndexSet)selectedColumnIndexes
{
    return _selectedColumnIndexes;
}

/*!
    Returns the index of the last selected row.
*/
- (int)selectedRow
{
    return _lastSelectedRow;
}

/*!
    Returns an index set with the indexes of all the selected rows.
*/
- (CPIndexSet)selectedRowIndexes
{
    return [_selectedRowIndexes copy];
}

/*!
    Deselects the column at a given index

    @param anIndex the index of the column to deselect
*/
- (void)deselectColumn:(CPInteger)anIndex
{
    var selectedColumnIndexes = [_selectedColumnIndexes copy];
    [selectedColumnIndexes removeIndex:anIndex];
    [self selectColumnIndexes:selectedColumnIndexes byExtendingSelection:NO];
    [self _noteSelectionDidChange];
}

/*!
    Deselects a row at a given index

    @param aRow the row to deselect
*/
- (void)deselectRow:(CPInteger)aRow
{
    var selectedRowIndexes = [_selectedRowIndexes copy];
    [selectedRowIndexes removeIndex:aRow];
    [self selectRowIndexes:selectedRowIndexes byExtendingSelection:NO];
    [self _noteSelectionDidChange];
}

/*!
    Returns the number of selected columns
*/
- (CPInteger)numberOfSelectedColumns
{
    return [_selectedColumnIndexes count];
}

/*!
    Returns the number of selected columns
*/
- (CPInteger)numberOfSelectedRows
{
    return [_selectedRowIndexes count];
}

/*!
    Returns YES if the column at a given index is selected, otherwise NO.

    @param anIndex the index of a column
    @return YES if the column is selected, otherwise NO.
*/
- (BOOL)isColumnSelected:(CPInteger)anIndex
{
    return [_selectedColumnIndexes containsIndex:anIndex];
}

/*!
    Returns YES if the row at a given index is selected, otherwise NO.

    @param aRow the index of a row
    @return YES if the row is selected, otherwise NO.
*/
- (BOOL)isRowSelected:(CPInteger)aRow
{
    return [_selectedRowIndexes containsIndex:aRow];
}


/*!
    @ignore
    Deselects all rows and columns
*/
- (void)deselectAll
{
    [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
    [self selectColumnIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
}

- (void)selectAll:(id)sender
{
    if (_allowsMultipleSelection)
    {
        if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ &&
            ![_delegate selectionShouldChangeInTableView:self])
            return;

        if ([[self selectedColumnIndexes] count])
            [self selectColumnIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfColumns])] byExtendingSelection:NO];
        else
            [self selectRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])] byExtendingSelection:NO];
    }
}

- (void)deselectAll:(id)sender
{
    if ([self allowsEmptySelection])
    {
        if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ &&
            ![_delegate selectionShouldChangeInTableView:self])
            return;

        [self deselectAll];
    }
}

/*!
    Returns the number of columns in the table
*/
- (int)numberOfColumns
{
    return NUMBER_OF_COLUMNS();
}

/*!
    Returns the number of rows in the receiver.
*/
- (int)numberOfRows
{
    if (_numberOfRows !== nil)
        return _numberOfRows;

    var contentBindingInfo = [self infoForBinding:@"content"];

    if (contentBindingInfo)
    {
        var destination = [contentBindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [contentBindingInfo objectForKey:CPObservedKeyPathKey];

        _numberOfRows = [[destination valueForKeyPath:keyPath] count];
    }
    else if (_dataSource && (_implementedDataSourceMethods & CPTableViewDataSource_numberOfRowsInTableView_))
        _numberOfRows = [_dataSource numberOfRowsInTableView:self] || 0;
    else
    {
        if (_dataSource)
            CPLog(@"no content binding established and data source " + [_dataSource description] + " does not implement numberOfRowsInTableView:");
        _numberOfRows = 0;
    }

    return _numberOfRows;
}

/*!
    Edits the dataview at a given row and column. This method is usually invoked automatically and should rarely be invoked directly
    The row at supplied rowIndex must be selected otherwise an exception is thrown.

    @param columnIndex the index of the column to edit
    @param rowIndex the index of the row to edit
    @param theEvent the mouse event which triggers the edit, you can pass nil
    @param flag YES if the dataview text should be selected, otherwise NO. (NOT YET IMPLEMENTED)
*/
- (void)editColumn:(CPInteger)columnIndex row:(CPInteger)rowIndex withEvent:(CPEvent)theEvent select:(BOOL)flag
{
    // FIX ME: Cocoa documentation says all this should be called in THIS method:
    // sets up the field editor, and sends selectWithFrame:inView:editor:delegate:start:length: and editWithFrame:inView:editor:delegate:event: to the field editor's NSCell object with the NSTableView as the text delegate.
    if (_isViewBased)
    {
        var identifier = [_tableColumns[columnIndex] UID],
            view = _dataViewsForTableColumns[identifier][rowIndex];

        [[self window] makeFirstResponder:view];
    }
    else
    {
        if (![self isRowSelected:rowIndex])
            [[CPException exceptionWithName:@"Error" reason:@"Attempt to edit row="+rowIndex+" when not selected." userInfo:nil] raise];

        [self scrollRowToVisible:rowIndex];
        [self scrollColumnToVisible:columnIndex];

        // TODO Do something with flag.

        _editingCellIndex = CGPointMake(columnIndex, rowIndex);
        _editingCellIndex._shouldSelect = flag;

        [self reloadDataForRowIndexes:[CPIndexSet indexSetWithIndex:rowIndex]
            columnIndexes:[CPIndexSet indexSetWithIndex:columnIndex]];
    }
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

/*!
    Returns the cornerview for the scrollview
*/
- (CPView)cornerView
{
    return _cornerView;
}

/*!
    Sets the cornerview for the scrollview
*/
- (void)setCornerView:(CPView)aView
{
    if (_cornerView === aView)
        return;

    _cornerView = aView;

    var scrollView = [self enclosingScrollView];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

/*!
    Returns the headerview for the receiver. The headerview contains column headerviews for each table column.
*/
- (CPView)headerView
{
    return _headerView;
}


/*!
    Sets the headerview for the tableview. This is the container view for the table column header views.
    This view also handles events for resizing and dragging.

    If you don't want your tableview to have a headerview you should pass nil. (also see setCornerView:)
    If you're looking to customize the header text of a column see CPTableColumn's -(CPView)headerView; method.
*/
- (void)setHeaderView:(CPView)aHeaderView
{
    if (_headerView === aHeaderView)
        return;

    [_headerView setTableView:nil];

    _headerView = aHeaderView;

    if (_headerView)
    {
        [_headerView setTableView:self];
        [_headerView setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), CGRectGetHeight([_headerView frame]))];
    }
    else
    {
        // If there is no header view, there should be no corner view
        [_cornerView removeFromSuperview];
        _cornerView = nil;
    }

    var scrollView = [self enclosingScrollView];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];

    [self setNeedsLayout];
}

// Complexity:
// O(Columns)
/*!
    @ignore
*/
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
/*!
    Returns a CGRect with the location and size of the column
    If aColumnIndex lies outside the range of the table columns a CGZeroRect is returned

    @param aColumnIndex the index of the column to return the rect of
*/
- (CGRect)rectOfColumn:(CPInteger)aColumnIndex
{
    // Convert e.g. "0" to 0.
    aColumnIndex = +aColumnIndex;

    if (aColumnIndex < 0 || aColumnIndex >= NUMBER_OF_COLUMNS())
        return CGRectMakeZero();

    var column = [[self tableColumns] objectAtIndex:aColumnIndex];

    if ([column isHidden])
        return CGRectMakeZero();

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var range = _tableColumnRanges[aColumnIndex];

    return CGRectMake(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}

// Complexity:
// O(1)
/*!
    @ignore
    Returns a CGRect with the location and size of the row

    @param aRowIndex the index of the row to return the rect of
    @param checkRange if YES this method will return a zero rect if the aRowIndex is outside of the range of valid indices
*/
- (CGRect)_rectOfRow:(CPInteger)aRowIndex checkRange:(BOOL)checkRange
{
    var lastIndex = [self numberOfRows] - 1;

    if (checkRange && (aRowIndex > lastIndex || aRowIndex < 0))
        return CGRectMakeZero();

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_)
    {
        var rowToLookUp = MIN(aRowIndex, lastIndex);

        // if the row doesn't exist
        if (rowToLookUp !== CPNotFound)
        {
            var y = _cachedRowHeights[rowToLookUp].heightAboveRow,
                height = _cachedRowHeights[rowToLookUp].height + _intercellSpacing.height,
                rowDelta = aRowIndex - rowToLookUp;
        }
        else
        {
            y = aRowIndex * (_rowHeight + _intercellSpacing.height);
            height = _rowHeight + _intercellSpacing.height;
        }

        // if we need the rect of a row past the last index
        if (rowDelta > 0)
        {
            y += rowDelta * (_rowHeight + _intercellSpacing.height);
            height = _rowHeight + _intercellSpacing.height;
        }
    }
    else
    {
        var y = aRowIndex * (_rowHeight + _intercellSpacing.height),
            height = _rowHeight + _intercellSpacing.height;
    }

    return CGRectMake(0.0, y, CGRectGetWidth([self bounds]), height);
}

/*!
    Returns a CGRect with the location and size of the row. CGRectZero is returned if aRowIndex doesn't exist.

    @param aRowIndex the index of the row you want the rect of
*/
- (CGRect)rectOfRow:(CPInteger)aRowIndex
{
    return [self _rectOfRow:aRowIndex checkRange:YES];
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

    var lastRow = [self rowAtPoint:CGPointMake(0.0, CGRectGetMaxY(aRect))];

    // last row has to be overshot, because if not we wouldn't be intersecting.
    if (lastRow < 0)
        lastRow = _numberOfRows - 1;

    return CPMakeRange(firstRow, lastRow - firstRow + 1);
}

/*!
    @ignore
    When we draw the row backgrounds we don't want an index bounding our range.
*/
- (CPRange)_unboundedRowsInRect:(CGRect)aRect
{
    var boundedRange = [self rowsInRect:aRect],
        lastRow = CPMaxRange(boundedRange),
        rectOfLastRow = [self _rectOfRow:lastRow checkRange:NO],
        bottom = CGRectGetMaxY(aRect),
        bottomOfBoundedRows = CGRectGetMaxY(rectOfLastRow);

    // we only have to worry about the rows below the last...
    if (bottom <= bottomOfBoundedRows)
        return boundedRange;

    var numberOfNewRows = CEIL(bottom -  bottomOfBoundedRows) / ([self rowHeight] + _intercellSpacing.height);

    boundedRange.length += numberOfNewRows + 1;

    return boundedRange;
}

// Complexity:
// O(lg Columns) if table view contains no hidden columns
// O(Columns) if table view contains hidden columns

/*!
    Returns the indexes of the receiver's columns that intersect the specified rectangle.

    @param aRect a rectangle in the coordinate system of the receiver.
*/
- (CPIndexSet)columnIndexesInRect:(CGRect)aRect
{
    var column = MAX(0, [self columnAtPoint:CGPointMake(aRect.origin.x, 0.0)]),
        lastColumn = [self columnAtPoint:CGPointMake(CGRectGetMaxX(aRect), 0.0)];

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
/*!
    Returns the index of a column at a given point. If no column is there CPNotFound is returned.

    @param aPoint a CGPoint
*/
- (CPInteger)columnAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds];

    if (!CGRectContainsPoint(bounds, aPoint))
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

//Complexity
// O(1) for static row height
// 0(lg Rows) for variable row heights
/*!
    Returns the index of a row at a particular point. If no row exists CPNotFound is returned.

    @param aPoint a CGPoint
*/
- (CPInteger)rowAtPoint:(CGPoint)aPoint
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_)
    {
            return [_cachedRowHeights indexOfObject:aPoint
                                            inSortedRange:nil
                                                  options:0
                                          usingComparator:function(aPoint, rowCache)
                    {
                          var upperBound = rowCache.heightAboveRow;

                          if (aPoint.y < upperBound)
                              return CPOrderedAscending;

                          if (aPoint.y > upperBound + rowCache.height + _intercellSpacing.height)
                              return CPOrderedDescending;

                          return CPOrderedSame;
                    }];
    }

    var y = aPoint.y,
        row = FLOOR(y / (_rowHeight + _intercellSpacing.height));

    if (row >= _numberOfRows)
        return CPNotFound;

    return row;
}

/*!
    Returns the index of the row for the specified view.

    @param view The view.
    @return The index of the row corresponding to the view. Returns -1 if the view is not a dataView, or a subview of a dataView.
    @discussion This is typically needed in the action method for a CPButton (or CPControl) to find out what row (and column) the action should be performed on.
                The implementation is O(rxc) where r is the number of visible rows, and c is the number of visible columns, so this method should generally not be called within a loop.
*/
- (CPInteger)rowForView:(CPView)aView
{
    return [self rowNotColumn:YES forView:aView];
}

/*!
    Returns the index of the column for the specified view.

    @param view The view.
    @return The index of the column corresponding to the view. Returns -1 if the view is not a dataView, or a subview of a dataView.
    @discussion This is typically needed in the action method for a CPButton (or CPControl) to find out what row (and column) the action should be performed on.
                The implementation is O(rxc) where r is the number of visible rows, and c is the number of visible columns, so this method should generally not be called within a loop.
*/
- (CPInteger)columnForView:(CPView)aView
{
    return [self rowNotColumn:NO forView:aView];
}

/*!
    @ignore
*/
- (CPInteger)rowNotColumn:(BOOL)isRow forView:(CPView)aView
{
    if (![aView isKindOfClass:[CPView class]])
        return -1;

    var cellView = aView,
        contentView = [[self window] contentView],
        max_rec = 100;

    while (max_rec--)
    {
        if (!cellView || cellView === contentView)
        {
            return -1;
        }
        else
        {
            var superview = [cellView superview];

            if ([superview isKindOfClass:[CPTableView class]])
            {
                break;
            }

            cellView = superview;
        }
    }

    var exposedRows = [],
        exposedColumns = [];

    [_exposedRows getIndexes:exposedRows maxCount:-1 inIndexRange:nil];
    [_exposedColumns getIndexes:exposedColumns maxCount:-1 inIndexRange:nil];

    var colcount = exposedColumns.length,
        countOfRows = exposedRows.length;

    while (colcount--)
    {
        var column = exposedColumns[colcount],
            tableColumnUID = [_tableColumns[column] UID],
            dataViewsInTableColumn = _dataViewsForTableColumns[tableColumnUID],
            rowcount = countOfRows;

        while (rowcount--)
        {
            var row = exposedRows[rowcount];

            if (cellView == dataViewsInTableColumn[row])
                return isRow ? row : column;
        }
    }

    return -1;
}

/*!
    Returns a rect for the dataview / cell at the column and row given.
    If the column or row index is greater than the number of columns or rows a CGZeroRect is returned

    @param aColumn index of the column
    @param aRow index of the row
*/
- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    if (aColumn > [self numberOfColumns] || aRow > [self numberOfRows])
        return CGRectMakeZero();

    var tableColumnRange = _tableColumnRanges[aColumn],
        rectOfRow = [self rectOfRow:aRow],
        leftInset = FLOOR(_intercellSpacing.width / 2.0),
        topInset = FLOOR(_intercellSpacing.height / 2.0);

    return CGRectMake(tableColumnRange.location + leftInset, CGRectGetMinY(rectOfRow) + topInset, tableColumnRange.length - _intercellSpacing.width, CGRectGetHeight(rectOfRow) - _intercellSpacing.height);
}

/*!
    @ignore
*/
- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    [super resizeWithOldSuperviewSize:aSize];

    if (_disableAutomaticResizing)
        return;

    var mask = _columnAutoResizingStyle;

    // should we actually do some resizing?
    if (!_lastColumnShouldSnap)
    {
        // did the clip view intersect the old tablesize?
        var superview = [self superview];

        if (!superview || ![superview isKindOfClass:[CPClipView class]])
            return;

        var superviewWidth = [superview bounds].size.width,
            lastColumnMaxX = CGRectGetMaxX([self rectOfColumn:[self numberOfColumns] -1]);

        // Fix me: this fires on the table setup at times
        if (lastColumnMaxX >= superviewWidth && lastColumnMaxX <= aSize.width || lastColumnMaxX <= superviewWidth && lastColumnMaxX >= aSize.width)
            _lastColumnShouldSnap = YES;
        else if (mask === CPTableViewUniformColumnAutoresizingStyle)
            return;
    }

    if (mask === CPTableViewUniformColumnAutoresizingStyle)
       [self _resizeAllColumnUniformlyWithOldSize:aSize];
    else if (mask === CPTableViewLastColumnOnlyAutoresizingStyle)
        [self sizeLastColumnToFit];
    else if (mask === CPTableViewFirstColumnOnlyAutoresizingStyle)
        [self _autoResizeFirstColumn];
}

/*!
    @ignore
*/
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
        [columnToResize _tryToResizeToWidth:newWidth];
    }

    [self setNeedsLayout];
}


/*!
    @ignore
    FIX ME: this can be a lot faster
*/
- (void)_resizeAllColumnUniformlyWithOldSize:(CGSize)oldSize
{
    // what we care about is the superview clip rect
    // FIX ME: if it's not in a scrollview this doesn't really work
    var superview = [self superview];

    if (!superview || ![superview isKindOfClass:[CPClipView class]])
        return;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var superviewWidth = [superview bounds].size.width,
        count = NUMBER_OF_COLUMNS(),
        resizableColumns = [CPIndexSet indexSet],
        remainingSpace = 0.0,
        i = 0;

    // find resizable columns
    // FIX ME: we could cache resizableColumns after this loop and reuse it during the resize
    for (; i < count; i++)
    {
        var tableColumn = _tableColumns[i];
        if (![tableColumn isHidden] && ([tableColumn resizingMask] & CPTableColumnAutoresizingMask))
            [resizableColumns addIndex:i];
    }

    var maxXofColumns = CGRectGetMaxX([self rectOfColumn:[resizableColumns lastIndex]]),
        remainingSpace = superviewWidth - maxXofColumns,
        resizeableColumnsCount = [resizableColumns count],
        proportionate = 0;

    while (remainingSpace && resizeableColumnsCount)
    {
        // Divy out the space.
        proportionate += remainingSpace / resizeableColumnsCount;

        // Reset the remaining space to 0
        remainingSpace = 0.0;

        var index = CPNotFound;

        while ((index = [resizableColumns indexGreaterThanIndex:index]) !== CPNotFound)
        {
            var item = _tableColumns[index],
                proposedWidth = [item width] + proportionate,
                resizeLeftovers = [item _tryToResizeToWidth:proposedWidth];

            if (resizeLeftovers)
            {
                [resizableColumns removeIndex:index];

                remainingSpace += resizeLeftovers;
            }
        }
    }

    // now that we've reached the end we know there are likely rounding errors
    // so we should size the last resized to fit

    // find the last visisble column
    while (count-- && [_tableColumns[count] isHidden]);

    // find the max x, but subtract a single pixel since the spacing isn't applicable here.
    var delta = superviewWidth - CGRectGetMaxX([self rectOfColumn:count]) - ([self intercellSpacing].width || 1),
        newSize = [item width] + delta;

    [item _tryToResizeToWidth:newSize];
}

/*!
    Sets the column autoresizing style of the receiver to a given style.

    @param aStyle the column autoresizing style for the receiver. Valid values are:
<pre>
        CPTableViewNoColumnAutoresizing
        CPTableViewUniformColumnAutoresizingStyle
        CPTableViewLastColumnOnlyAutoresizingStyle
        CPTableViewFirstColumnOnlyAutoresizingStyle
</pre>
*/
- (void)setColumnAutoresizingStyle:(unsigned)style
{
    //FIX ME: CPTableViewSequentialColumnAutoresizingStyle and CPTableViewReverseSequentialColumnAutoresizingStyle are not yet implemented
    _columnAutoResizingStyle = style;
}

/*!
    Returns the column auto resizing style of the receiver.
*/
- (unsigned)columnAutoresizingStyle
{
    return _columnAutoResizingStyle;
}

/*!
   Resizes the last column if there's room so the receiver fits exactly within its enclosing clip view.
*/
- (void)sizeLastColumnToFit
{
    _lastColumnShouldSnap = YES;

    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS();

    // Decrement the counter until we get to the last column that's not hidden
    while (count-- && [_tableColumns[count] isHidden]);

    // If the last column exists
    if (count >= 0)
    {
        var columnToResize = _tableColumns[count],
            newSize = MAX(0.0, superviewSize.width - CGRectGetMinX([self rectOfColumn:count]) - _intercellSpacing.width);

        [columnToResize _tryToResizeToWidth:newSize];
    }

    [self setNeedsLayout];
}

/*!
    Informs the receiver that the number of records in the datasource has changed.
*/
- (void)noteNumberOfRowsChanged
{
    var oldNumberOfRows = _numberOfRows;

    _numberOfRows = nil;
    _cachedRowHeights = [];

    // this line serves two purposes
    // 1. it updates the _numberOfRows cache with the -numberOfRows call
    // 2. it updates the row height cache if needed
    [self noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])]];

    // remove row indexes from the selection if they no longer exist
    var hangingSelections = oldNumberOfRows - _numberOfRows;

    if (hangingSelections > 0)
    {

        var previousSelectionCount = [_selectedRowIndexes count];
        [_selectedRowIndexes removeIndexesInRange:CPMakeRange(_numberOfRows, hangingSelections)];

        if (![_selectedRowIndexes containsIndex:[self selectedRow]])
            _lastSelectedRow = CPNotFound;

        // For optimal performance, only send a notification if indices were actually removed.
        if (previousSelectionCount > [_selectedRowIndexes count])
            [self _noteSelectionDidChange];
    }

    [self tile];
}


/*!
    Informs the receiver that the rows specified in indexSet have changed height.

    @param anIndexSet an index set containing the indexes of the rows which changed height
*/
- (void)noteHeightOfRowsWithIndexesChanged:(CPIndexSet)anIndexSet
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_))
        return;

    // this method will update the height of those rows, but since the cached array also contains
    // the height above the row it needs to recalculate for the rows below it too
    var i = [anIndexSet firstIndex],
        count = _numberOfRows - i,
        heightAbove = (i > 0) ? _cachedRowHeights[i - 1].height + _cachedRowHeights[i - 1].heightAboveRow + _intercellSpacing.height : 0;

    for (; i < count; i++)
    {
        // update the cache if the user told us to
        if ([anIndexSet containsIndex:i])
            var height = [_delegate tableView:self heightOfRow:i];

            _cachedRowHeights[i] = {"height":height, "heightAboveRow":heightAbove};

        heightAbove += height + _intercellSpacing.height;
    }
}

/*!
    Lays out the dataviews and resizes the tableview so that everything fits.
*/
- (void)tile
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var width = _tableColumnRanges.length > 0 ? CPMaxRange([_tableColumnRanges lastObject]) : 0.0,
        superview = [self superview];

    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_))
        var height =  (_rowHeight + _intercellSpacing.height) * _numberOfRows;
    else if ([self numberOfRows] === 0)
        var height = 0;
    else
    {
        // if this is the fist run we need to populate the cache
        if ([self numberOfRows] !== _cachedRowHeights.length)
            [self noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])]];

        var heightObject = _cachedRowHeights[_cachedRowHeights.length - 1],
            height = heightObject.heightAboveRow + heightObject.height + _intercellSpacing.height;
    }

    if ([superview isKindOfClass:[CPClipView class]])
    {
        var superviewSize = [superview bounds].size;

        width = MAX(superviewSize.width, width);
        height = MAX(superviewSize.height, height);
    }

    [self setFrameSize:CGSizeMake(width, height)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}


/*!
    Scrolls the receiver vertically in an enclosing CPClipView so the row specified by rowIndex is visible.

    @param aRowIndex the index of the row to scroll to.
*/
- (void)scrollRowToVisible:(int)rowIndex
{
    var visible = [self visibleRect],
        rowRect = [self rectOfRow:rowIndex];

    visible.origin.y = rowRect.origin.y;
    visible.size.height = rowRect.size.height;

    [self scrollRectToVisible:visible];
}

/*!
    Scrolls the receiver and header view horizontally in an enclosing CPClipView so the column specified by columnIndex is visible.

    @param aColumnIndex the index of the column to scroll to.
*/
- (void)scrollColumnToVisible:(int)columnIndex
{
    var visible = [self visibleRect],
        colRect = [self rectOfColumn:columnIndex];

    visible.origin.x = colRect.origin.x;
    visible.size.width = colRect.size.width;

    [self scrollRectToVisible:visible];
    [_headerView scrollRectToVisible:colRect];
}

/*!
    Set the name under which the table information is automatically saved to theAutosaveName.
    The table information is saved separately for each user and for each application that user uses.
    @note Even though a table view has an autosave name, it may not be saving table information automatically.
    To set whether table information is being saved automatically, use \c setAutosaveTableColumns:
*/
- (void)setAutosaveName:(CPString)theAutosaveName
{
    if (_autosaveName === theAutosaveName)
        return;

    _autosaveName = theAutosaveName;

    [self setAutosaveTableColumns:!!theAutosaveName];
    [self _restoreFromAutosave];
}

/*!
    Returns the autosave name of the tableview.
*/
- (CPString)autosaveName
{
    return _autosaveName;
}

/*!
    Sets whether the order and width of this table view's columns are automatically saved.

    The table information is saved separately for each user and for each application that user uses.
    @note that if autosaveName returns nil, this setting is ignored and table information isn't saved.
*/
- (void)setAutosaveTableColumns:(BOOL)shouldAutosave
{
    _autosaveTableColumns = shouldAutosave;
}

/*!
    Returns YES the table columns should autosave, otherwise NO.
*/
- (BOOL)autosaveTableColumns
{
    return _autosaveTableColumns;
}

/*!
    @ignore
*/
- (CPString)_columnsKeyForAutosaveName:(CPString)theAutosaveName
{
    return @"CPTableView Columns " + theAutosaveName;
}

/*!
    @ignore
*/
- (BOOL)_autosaveEnabled
{
    return [self autosaveName] && [self autosaveTableColumns];
}

/*!
    @ignore
    Stores the tablecolumn setup in user defaults.
    I believe Apple stores the entire encoded table column,
    in our case that seems overkill since we need to store everything in a cookie.
*/
- (void)_autosave
{
    if (![self _autosaveEnabled])
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self autosaveName];

    var columns = [self tableColumns],
        columnsSetup = [];

    for (var i = 0; i < [columns count]; i++)
    {
        var column = [columns objectAtIndex:i],
            metaData = @{
                @"identifier": [column identifier],
                @"width": [column width]
            };

        [columnsSetup addObject:metaData];
    }

    [userDefaults setObject:columnsSetup forKey:[self _columnsKeyForAutosaveName:autosaveName]];
}

/*!
    @ignore
*/
- (void)_restoreFromAutosave
{
    if (![self _autosaveEnabled])
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self autosaveName],
        tableColumns = [userDefaults objectForKey:[self _columnsKeyForAutosaveName:autosaveName]];

    if ([tableColumns count] != [[self tableColumns] count])
        return;

    for (var i = 0; i < [tableColumns count]; i++)
    {
        var metaData = [tableColumns objectAtIndex:i],
            columnIdentifier = [metaData objectForKey:@"identifier"],
            column = [self columnWithIdentifier:columnIdentifier],
            tableColumn = [self tableColumnWithIdentifier:columnIdentifier];

        if (tableColumn && column != CPNotFound)
        {
            [self _moveColumn:column toColumn:i];
            [tableColumn setWidth:[metaData objectForKey:@"width"]];
        }
    }
}

/*!
@anchor setdelegate
    Sets the delegate of the receiver.
    @param aDelegate the delegate object for the tableview.

    The delegate can provide notification for user interaction, display behaviour, contextual menus, and more.


@section Providing Views for Rows and Columns:

Returns the view used to display the specified row and column.
@code
- (CPView)tableView:(CPTableView)tableView viewForTableColumn:(CPTableColumn)tableColumn row:(CPInteger)row
@endcode

@param
The view to display the specified column and row. Returning nil is acceptable, and a view will not be shown at that location.

@discussion
This method is required if you wish to use a view-based table view in Interface builder or cell-based table views without using CPTableColumn's setDataView: method.

It is recommended that the implementation of this method first call the CPTableView method makeViewWithIdentifier:owner: passing, respectively, the tableColumn parameter’s identifier and self as the owner to attempt to reuse a view that is no longer visible. The frame of the view returned by this method is not important, and it will be automatically set by the table.

The view's properties should be properly set up before returning the result. The delegate do not need to implement tableview:objectValueforTableColumn:row:.

When using bindings, this method is optional if at least one identifier has been associated with the table view at design time. If this method is not implemented, the table will automatically call the CPTableView method makeViewWithIdentifier:owner: with the tableColumn parameter’s identifier and the table view’s delegate respectively as parameters, to attempt to reuse a previous view, or automatically unarchive a prototype associated with the table view.

The autoresizingMask of the returned view will automatically be set to CPViewNotSizable if the data view was created in Interface builder in a table column. Otherwise, for example if the view is created manually in code, this method expects the data view to have a CPViewNotSizable mask.


@section displayingcells Displaying Cells:

Called when the tableview is about to display a dataview
@code
- (void)tableView:(CPTableView)aTableView willDisplayView:(id)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex;
@endcode

Group rows are a way to separate a groups of data in a tableview. Return YES if the given row is a group row, otherwise NO.
@code
- (BOOL)tableView:(CPTableView)tableView isGroupRow:(int)row;
@endcode


@section editingcells Editing Cells:

Return YES if the dataview at a given index and column should be edited, otherwise NO.
@code
- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex;
@endcode


@section sizes Setting Row and Column Size:

Return the height of the row at a given index. Only implement this if you want variable row heights. Otherwise use setRowHeight: on the tableview.
@code
- (float)tableView:(CPTableView)tableView heightOfRow:(int)row;
@endcode


@section selection Selecting in the TableView:
@note These methods are only called when the user does something.@endnote

Return YES if the selection of the tableview should change, otherwise NO to keep the current selection.
@code
- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView;
@endcode

Return YES if the row at a given index should be selected, other NO to deny the selection.
@code
- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)rowIndex;
@endcode

Return YES if the table column given should be selected, otherwise NO to deny the selection.
@code
- (BOOL)tableView:(CPTableView)aTableView shouldSelectTableColumn:(CPTableColumn)aTableColumn;
@endcode

Informs the delegate that the tableview is in the process of changing the selection.
This usually happens when the user is dragging their mouse across rows.
@code
- (void)tableViewSelectionIsChanging:(CPNotification)aNotification
@endcode

Informs the delegate that the tableview selection has changed.
@code
- (void)tableViewSelectionDidChange:(CPNotification)aNotification;
@endcode


@section movingandresizingcolumns Moving and Resizing Columns:

Return YES if the column at a given index should move to a new column index, otherwise NO.
When a column is initially dragged by the user, the delegate is first called with a newColumnIndex value of -1

@code
- (BOOL)tableView:(CPTableView)tableView shouldReorderColumn:(int)columnIndex toColumn:(int)newColumnIndex;
@endcode


Notifies the delegate that the tableview drag occurred. This is sent on mouse up.
@code
- (void)tableView:(CPTableView)tableView didDragTableColumn:(CPTableColumn)tableColumn;
@endcode


Notifies the delegate that a table column was moved by the user.
@code
- (void)tableViewColumnDidMove:(CPNotification)aNotification;
@endcode

Notifies the delegate that the user resized the table column
@code
- (void)tableViewColumnDidResize:(CPNotification)aNotification;
@endcode


@section mousevents Responding to Mouse Events:

Sent when the user clicks a table column but doesn't drag.
@code
- (void)tableView:(CPTableView)tableView didClickTableColumn:(CPTableColumn)tableColumn;
@endcode


Notify the delegate that the user has clicked the table header of a column.
@code
- (void)tableView:(CPTableView)tableView mouseDownInHeaderOfTableColumn:(CPTableColumn)tableColumn;
@endcode


@section contextualmenus Contextual Menus:

Called when the user right-clicks on the tableview. -1 is passed for the row or column if the user doesn't right click on a real row or column
Return a CPMenu that should be displayed if the user right-clicks. If you do not implement this the tableview will call super on menuForEvent
@code
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow;
@endcode


@section deletekey Delete Key
Called when the user presses the delete key. Many times you will want to delete data (or prompt for deletion) when the user presses the delete key.
Your delegate can implement this method to avoid subclassing the tableview to add this behaviour.

@code
- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView;
@endcode
*/
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

    if ([_delegate respondsToSelector:@selector(tableView:viewForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_viewForTableColumn_row_;
    else if ([_delegate respondsToSelector:@selector(tableView:dataViewForTableColumn:row:)])
    {
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_dataViewForTableColumn_row_;
        CPLog.warn("tableView:dataViewForTableColumn: is deprecated. You should use -tableView:viewForTableColumn: where you can request the view with -makeViewWithIdentifier:owner:");
    }

    [self _updateIsViewBased];

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

    if ([_delegate respondsToSelector:@selector(tableView:menuForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewMenuForTableColumn_Row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldReorderColumn:toColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_;

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

/*!
    Returns the delegate object for the table view.
*/
- (id)delegate
{
    return _delegate;
}

/*!
    @ignore
*/
- (void)_sendDelegateDidClickColumn:(int)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_didClickTableColumn_)
            [_delegate tableView:self didClickTableColumn:_tableColumns[column]];
}

/*!
    @ignore
*/
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

/*
    @ignore
*/
- (BOOL)_sendDelegateDeleteKeyPressed
{
    if ([_delegate respondsToSelector: @selector(tableViewDeleteKeyPressed:)])
    {
        [_delegate tableViewDeleteKeyPressed:self];
        return YES;
    }

    return NO;
}


/*!
    @ignore
*/
- (void)_sendDataSourceSortDescriptorsDidChange:(CPArray)oldDescriptors
{
    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_sortDescriptorsDidChange_)
        [_dataSource tableView:self sortDescriptorsDidChange:oldDescriptors];
}


/*!
    @ignore
*/
- (void)_didClickTableColumn:(int)clickedColumn modifierFlags:(unsigned)modifierFlags
{
    [self _sendDelegateDidClickColumn:clickedColumn];

    [self _changeSortDescriptorsForClickOnColumn:clickedColumn];

    if (_allowsColumnSelection)
    {
        [self _noteSelectionIsChanging];
        if (modifierFlags & CPPlatformActionKeyMask)
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
}

// From GNUSTEP
/*!
    @ignore
*/
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
    while ((descriptor = [e nextObject]) !== nil)
    {
        if ([[descriptor key] isEqual: [newMainSortDescriptor key]])
            [outdatedDescriptors addObject:descriptor];
    }

    // Invert the sort direction when the same column header is clicked twice
    if ([[newMainSortDescriptor key] isEqual:[oldMainSortDescriptor key]])
        newMainSortDescriptor = [oldMainSortDescriptor reversedSortDescriptor];

    [newSortDescriptors removeObjectsInArray:outdatedDescriptors];
    [newSortDescriptors insertObject:newMainSortDescriptor atIndex:0];

    [self setHighlightedTableColumn:tableColumn];
    [self setSortDescriptors:newSortDescriptors];
}

/*!
    Sets the indicator image of aTableColumn to anImage.
    The tableview will set the sort indicator images automatically; if you want
    a different image you can supply it here.

    @param anImage the image for the column
    @param aTableColumn the table column object for which to set the image
*/
- (void)setIndicatorImage:(CPImage)anImage inTableColumn:(CPTableColumn)aTableColumn
{
    if (aTableColumn)
    {
        var headerView = [aTableColumn headerView];
        if ([headerView respondsToSelector:@selector(_setIndicatorImage:)])
            [headerView _setIndicatorImage:anImage];
    }
}

/*!
    @ignore
*/
- (CPImage)_tableHeaderSortImage
{
    return [self currentValueForThemeAttribute:@"sort-image"];
}

/*!
    @ignore
*/
- (CPImage)_tableHeaderReverseSortImage
{
    return [self currentValueForThemeAttribute:@"sort-image-reversed"];
}

/*!
    Returns the CPTableColumn object of the highlighted table column.
*/
- (CPTableColumn)highlightedTableColumn
{
    return _currentHighlightedTableColumn;
}

/*!
    Sets the table column for which the header should be highlighted.
*/
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
    return [rowIndexes count] > 0 && [self numberOfRows] > 0 && [self numberOfColumns] > 0;
}

/*!
    Computes and returns an image to use for dragging. This method is invoked ONLY IF dragViewForRowsWithIndexes:tableColumns:event:offset: returns nil.

    @param dragRows an index set with the dragged row indexes
    @param theTableColumns an array of the table columns which are being dragged
    @param dragEvent the event which initiated the drag
    @param offset a point at which to set the drag image to be offset from the cursor

    @return CPImage an image to use for the drag feedback
*/
- (CPImage)dragImageForRowsWithIndexes:(CPIndexSet)dragRows tableColumns:(CPArray)theTableColumns event:(CPEvent)dragEvent offset:(CGPoint)dragImageOffset
{
    return [self valueForThemeAttribute:@"image-generic-file"];
}

/*!
    Computes and returns a view to use for dragging. By default this is a slightly transparent copy of the dataviews which are being dragged.
    You can override this in a subclass to show different dragging feedback. Additionally you can return nil from this method and implement:
    - (CPImage)dragImageForRowsWithIndexes:tableColumns:event:offset: - if you want to return a simple image.

    @param dragRows an index set with the dragged row indexes
    @param theTableColumns an array of the table columns which are being dragged
    @param dragEvent the event which initiated the drag
    @param offset a point at which to set the drag image to be offset from the cursor

    @return CPView a view used as the dragging feedback
*/
- (CPView)dragViewForRowsWithIndexes:(CPIndexSet)theDraggedRows tableColumns:(CPArray)theTableColumns event:(CPEvent)theDragEvent offset:(CGPoint)dragViewOffset
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

            [self _setObjectValueForTableColumn:tableColumn row:row forView:dataView];
            [view addSubview:dataView];
            [_draggingViews addObject:dataView];

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
- (CPView)_dragViewForColumn:(int)theColumnIndex event:(CPEvent)theDragEvent offset:(CGPoint)theDragViewOffset
{
    var dragView = [[_CPColumnDragView alloc] initWithLineColor:[self gridColor]],
        tableColumn = [[self tableColumns] objectAtIndex:theColumnIndex],
        defaultRowHeight = [self valueForThemeAttribute:@"default-row-height"],
        bounds = CGRectMake(0.0, 0.0, [tableColumn width], CGRectGetHeight([self exposedRect]) + defaultRowHeight),
        columnRect = [self rectOfColumn:theColumnIndex],
        headerView = [tableColumn headerView],
        row = [_exposedRows firstIndex];

    [dragView setFrame:bounds];

    while (row !== CPNotFound)
    {
        var dataView = [self _newDataViewForRow:row tableColumn:tableColumn],
            dataViewFrame = [self frameOfDataViewAtColumn:theColumnIndex row:row];

        // Only one column is ever dragged so we just place the view at
        dataViewFrame.origin.x = 0.0;

        // Offset by table header height - scroll position
        dataViewFrame.origin.y = ( CGRectGetMinY(dataViewFrame) - CGRectGetMinY([self exposedRect]) ) + defaultRowHeight;
        [dataView setFrame:dataViewFrame];

        [self _setObjectValueForTableColumn:tableColumn row:row forView:dataView];
        [dragView addSubview:dataView];
        [_draggingViews addObject:dataView];

        row = [_exposedRows indexGreaterThanIndex:row];
    }

    // Add a copy of the header view.
    var columnHeaderView = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:headerView]];
    [dragView addSubview:columnHeaderView];

    [dragView setBackgroundColor:[CPColor whiteColor]];
    [dragView setAlphaValue:0.7];

    return dragView;
}

/*!
    Sets the default operation mask for the drag behavior of the table view.
    @note isLocal is not implemented.
*/
- (void)setDraggingSourceOperationMask:(CPDragOperation)mask forLocal:(BOOL)isLocal
{
    //ignore local for the time being since only one capp app can run at a time...
    _dragOperationDefaultMask = mask;
}

/*!
    This should be called inside tableView:validateDrop:... method
    either CPTableViewDropOn or CPTableViewDropAbove,
    Specify the row as -1 to select the whole table for drop on.
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
    Sets the feedback style for when the table is the destination of a drag operation.
    This style is used to determine how the tableview looks when it is the receiver of a drag and drop operation.

    Can be:
<pre>
        CPTableViewDraggingDestinationFeedbackStyleNone
        CPTableViewDraggingDestinationFeedbackStyleRegular
        CPTableViewDraggingDestinationFeedbackStyleSourceList
</pre>
*/
- (void)setDraggingDestinationFeedbackStyle:(CPTableViewDraggingDestinationFeedbackStyle)aStyle
{
    //FIX ME: this should vary up the highlight color, currently nothing is being done with it
    _destinationDragStyle = aStyle;
}

/*!
    Returns the tableview dragging destination feedback style.

    Can be:
<pre>
        CPTableViewDraggingDestinationFeedbackStyleNone
        CPTableViewDraggingDestinationFeedbackStyleRegular
        CPTableViewDraggingDestinationFeedbackStyleSourceList
</pre>
*/
- (CPTableViewDraggingDestinationFeedbackStyle)draggingDestinationFeedbackStyle
{
    return _destinationDragStyle;
}

/*!
    Sets whether vertical motion is treated as a drag or selection change to flag.

    @param aFlag if flag is NO then vertical motion will not start a drag. The default is YES.
*/
- (void)setVerticalMotionCanBeginDrag:(BOOL)aFlag
{
    _verticalMotionCanDrag = aFlag;
}

/*!
    Returns YES if vertical motion can begin a drag of the tableview, otherwise NO.
*/
- (BOOL)verticalMotionCanBeginDrag
{
    return _verticalMotionCanDrag;
}

- (CPTableColumn)_tableColumnForSortDescriptor:(CPSortDescriptor)theSortDescriptor
{
    var tableColumns = [self tableColumns];

    for (var i = 0; i < [tableColumns count]; i++)
    {
        var tableColumn = [tableColumns objectAtIndex:i],
            sortDescriptorPrototype = [tableColumn sortDescriptorPrototype];

        if (!sortDescriptorPrototype)
            continue;

        if ([sortDescriptorPrototype key] === [theSortDescriptor key]
            && [sortDescriptorPrototype selector] === [theSortDescriptor selector])
        {
            return tableColumn;
        }
    }

    return nil;
}

/*!
    Sets the table view's CPSortDescriptors objects in an array.

    @param sortDescriptors an array of sort descriptors.
*/
- (void)setSortDescriptors:(CPArray)sortDescriptors
{
    var oldSortDescriptors = [[self sortDescriptors] copy],
        newSortDescriptors = [CPArray array];

    if (sortDescriptors !== nil)
        [newSortDescriptors addObjectsFromArray:sortDescriptors];

    if ([newSortDescriptors isEqual:oldSortDescriptors])
        return;

    _sortDescriptors = newSortDescriptors;

    var oldColumn = nil,
        newColumn = nil;

    if ([newSortDescriptors count] > 0)
    {
        var newMainSortDescriptor = [newSortDescriptors objectAtIndex:0];
        newColumn = [self _tableColumnForSortDescriptor:newMainSortDescriptor];
    }

    if ([oldSortDescriptors count] > 0)
    {
        var oldMainSortDescriptor = [oldSortDescriptors objectAtIndex:0];
        oldColumn = [self _tableColumnForSortDescriptor:oldMainSortDescriptor];
    }

    var image = [newMainSortDescriptor ascending] ? [self _tableHeaderSortImage] : [self _tableHeaderReverseSortImage];
    [self setIndicatorImage:nil inTableColumn:oldColumn];
    [self setIndicatorImage:image inTableColumn:newColumn];

    [self _sendDataSourceSortDescriptorsDidChange:oldSortDescriptors];

    var binderClass = [[self class] _binderClassForBinding:@"sortDescriptors"];
    [[binderClass getBinding:@"sortDescriptors" forObject:self] reverseSetValueFor:@"sortDescriptors"];
}

/*!
    Returns an array of the current sort descriptors currently used by the table.
*/
- (CPArray)sortDescriptors
{
    return _sortDescriptors;
}

- (BOOL)_dataSourceRespondsToObjectValueForTableColumn
{
    return _implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_;
}

- (BOOL)_delegateRespondsToDataViewForTableColumn
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_dataViewForTableColumn_row_;
}

- (BOOL)_delegateRespondsToViewForTableColumn
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_viewForTableColumn_row_;
}

/*!
    @ignore
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
    if (objectValue === undefined)
    {
        if ([self _dataSourceRespondsToObjectValueForTableColumn])
        {
            objectValue = [_dataSource tableView:self objectValueForTableColumn:aTableColumn row:aRowIndex];
            tableColumnObjectValues[aRowIndex] = objectValue;
        }
        else if (!_isViewBased && ![self infoForBinding:@"content"])
        {
            CPLog.warn(@"no content binding established and data source " + [_dataSource description] + " does not implement tableView:objectValueForTableColumn:row:");
        }
    }

    return objectValue;
}


/*!
    Returns a CGRect of the exposed area of the tableview.
*/
- (CGRect)exposedRect
{
    if (!_exposedRect)
    {
        var superview = [self superview];

        // FIXME: Should we be rect intersecting in case
        // there are multiple views in the clip view?
        if ([superview isKindOfClass:[CPClipView class]])
            _exposedRect = [superview bounds];
        else
            _exposedRect = [self bounds];
    }

    return _exposedRect;
}

/*!
    Loads all the data and dataviews for the receiver.
*/
- (void)load
{
    if (_reloadAllRows)
    {
        [self _unloadDataViewsInRows:_exposedRows columns:_exposedColumns];

        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];

        _reloadAllRows = NO;
    }

    var exposedRect = [self exposedRect],
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

    // if we have any columns to remove do that here
    if ([_differedColumnDataToRemove count])
    {
        for (var i = 0; i < _differedColumnDataToRemove.length; i++)
        {
            var data = _differedColumnDataToRemove[i],
                column = data.column,
                tableColumnUID = [column UID],
                dataViews = _dataViewsForTableColumns[tableColumnUID];

            for (var j = 0; j < [dataViews count]; j++)
            {
                [self _enqueueReusableDataView:[dataViews objectAtIndex:j]];
            }
        }
        [_differedColumnDataToRemove removeAllObjects];
    }

    // Now clear all the leftovers
    // FIXME: this could be faster!
    for (var identifier in _cachedDataViews)
    {
        var dataViews = _cachedDataViews[identifier],
            count = dataViews.length;

        while (count--)
            [dataViews[count] removeFromSuperview];
    }
}

/*!
    @ignore
*/
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

            if (row === _editingRow && column === _editingColumn)
                [[self window] makeFirstResponder:self];

            var dataView = [dataViews objectAtIndex:row];

            [dataViews replaceObjectAtIndex:row withObject:nil];

            [self _enqueueReusableDataView:dataView];
        }
    }
}

/*!
    @ignore
*/
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

            [self _setObjectValueForTableColumn:tableColumn row:row forView:dataView];

            if ((_selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone) &&
                (isColumnSelected || [self isRowSelected:row]))
            {
                [dataView setThemeState:CPThemeStateSelectedDataView];
            }
            else
                [dataView unsetThemeState:CPThemeStateSelectedDataView];

            // FIX ME: for performance reasons we might consider diverging from cocoa and moving this to the reloadData method
            if (_implementedDelegateMethods & CPTableViewDelegate_tableView_isGroupRow_)
            {
                if ([_delegate tableView:self isGroupRow:row])
                {
                    [_groupRows addIndex:row];
                    [dataView setThemeState:CPThemeStateGroupRow];
                }
                else
                {
                    [_groupRows removeIndexesInRange:CPMakeRange(row, 1)];
                    [dataView unsetThemeState:CPThemeStateGroupRow];
                }

                [self setNeedsDisplay:YES];
            }

            if (_implementedDelegateMethods & CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_)
                [_delegate tableView:self willDisplayView:dataView forTableColumn:tableColumn row:row];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            _dataViewsForTableColumns[tableColumnUID][row] = dataView;

            if (_isViewBased)
                continue;

            if (isButton || (_editingCellIndex && _editingCellIndex.x === column && _editingCellIndex.y === row))
            {
                if (isTextField)
                {
                    [dataView setEditable:YES];
                    [dataView setSendsActionOnEndEditing:YES];
                    [dataView setSelectable:YES];
                    [dataView selectText:nil];
                    [dataView setBezeled:YES];
                    [dataView setDelegate:self];
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

- (void)_setObjectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow forView:(CPView)aDataView
{
    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_)
        [aDataView setObjectValue:[self _objectValueForTableColumn:aTableColumn row:aRow]];

    // This gives the table column an opportunity to apply its bindings.
    // It will override the value set above if there is a binding.

    if (_contentBindingExplicitlySet)
        [self _prepareContentBindedDataView:aDataView forRow:aRow];
    else
        // For both cell-based and view-based
        [aTableColumn _prepareDataView:aDataView forRow:aRow];
}

- (void)_prepareContentBindedDataView:(CPView)dataView forRow:(CPInteger)aRow
{
    var binder = [CPTableContentBinder getBinding:@"content" forObject:self],
        content = [binder content],
        rowContent = [content objectAtIndex:aRow];

    [dataView setObjectValue:rowContent];
}

/*!
    @ignore
*/
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
            rowIndex = 0,
            rowsCount = rowArray.length;

        if (dataViewsForTableColumn)
        {
            for (; rowIndex < rowsCount; ++rowIndex)
            {
                var row = rowArray[rowIndex],
                    dataView = dataViewsForTableColumn[row];

                [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];
            }
        }
    }
}

/*!
    @ignore
    The action for any dataview that supports editing. This will only be called when the value was changed.
    The table view becomes the first responder after user is done editing a dataview.
*/
- (void)_commitDataViewObjectValue:(id)sender
{
    /*
        makeFirstResponder at the end of this method causes the dataview to resign.
        If the dataview resigning triggers the action (as CPTextField does), we come right
        back here and start an infinite loop. So we have to check this flag first.
    */
    if ([sender respondsToSelector:@selector(sendsActionOnEndEditing)] && [sender sendsActionOnEndEditing] && _editingCellIndex === nil)
        return;

    _editingCellIndex = nil;

    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        [_dataSource tableView:self setObjectValue:[sender objectValue] forTableColumn:sender.tableViewEditedColumnObj row:sender.tableViewEditedRowIndex];

    // Allow the column binding to do a reverse set. Note that we do this even if the data source method above
    // is implemented.
    [sender.tableViewEditedColumnObj _reverseSetDataView:sender forRow:sender.tableViewEditedRowIndex];

    if ([sender respondsToSelector:@selector(setEditable:)])
        [sender setEditable:NO];

    if ([sender respondsToSelector:@selector(setSelectable:)])
        [sender setSelectable:NO];

    if ([sender isKindOfClass:[CPTextField class]])
        [sender setBezeled:NO];

    [self reloadDataForRowIndexes:[CPIndexSet indexSetWithIndex:sender.tableViewEditedRowIndex]
                    columnIndexes:[CPIndexSet indexSetWithIndex:[_tableColumns indexOfObject:sender.tableViewEditedColumnObj]]];

    [[self window] makeFirstResponder:self];

}

/*!
    @ignore
    Blur notification handler for editing textfields. This will always be called when a textfield loses focus.
    This method is responsible for restoring the dataview to its non editable state.
*/
- (void)controlTextDidBlur:(CPNotification)theNotification
{
    var dataView = [theNotification object];

    if ([dataView respondsToSelector:@selector(setEditable:)])
        [dataView setEditable:NO];

    if ([dataView respondsToSelector:@selector(setSelectable:)])
        [dataView setSelectable:NO];

    if ([dataView isKindOfClass:[CPTextField class]])
        [dataView setBezeled:NO];

    _editingCellIndex = nil;
}

/*!
    @ignore
*/
- (CPView)_viewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_delegate tableView:self viewForTableColumn:aTableColumn row:aRow];
}

- (CPView)_dataViewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_delegate tableView:self dataViewForTableColumn:aTableColumn row:aRow];
}

/*!
    @ignore
*/
- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    var view = nil;

    if (_viewForTableColumnRowSelector)
        view = objj_msgSend(self, _viewForTableColumnRowSelector, aTableColumn, aRow);

    if (!view)
    {
        var columnIdentifier = [aTableColumn identifier];

        // For Pre-Lion nibs, there is no automatic identifier for table column; use UID as identifier.
        if (!columnIdentifier)
            columnIdentifier = [aTableColumn UID];

        view = [self makeViewWithIdentifier:columnIdentifier owner:_delegate];

        if (!view)
            view = [aTableColumn _newDataView];

        [view setIdentifier:columnIdentifier];
    }

    return view;
}

/*
    Returns a view with the specified identifier.

    @param identifier The view identifier. Must not be nil.
    @param owner The owner of the CIB that may be loaded and instituted to create a new view with the particular identifier.
    @return A view for the row.

    @discussion
    Typically identifier is associated with an external CIB and the table view will automatically instantiate the CIB with the provided owner. The owner of the CIB that may be loaded and instantiated to create a new view with the particular identifier is typically the table view’s delegate. The owner is useful in setting up outlets and target and actions from the view.

    This method will typically be called by the delegate in tableView:viewForTableColumn:row:, but it can also be overridden to provide custom views for the identifier. This method may also return a reused view with the same identifier that was no longer available on screen.
*/
- (id)makeViewWithIdentifier:(CPString)anIdentifier owner:(id)anOwner
{
    if (!anIdentifier)
        return nil;

    var view,
        // See if we have some reusable view available
        reusableViews = _cachedDataViews[anIdentifier];

    if (reusableViews && reusableViews.length)
        view = reusableViews.pop();
    // Otherwise see if we have a view in the cib with this identifier
    else if (_isViewBased)
        view = [self _unarchiveViewWithIdentifier:anIdentifier owner:anOwner];

    return view;
}

/*!
    @ignore
*/
- (CPView)_unarchiveViewWithIdentifier:(CPString)anIdentifier owner:(id)anOwner
{
    var cib = [_archivedDataViews objectForKey:anIdentifier];

    if (!cib && !_unavailable_custom_cibs[anIdentifier])
    {
        var bundle = anOwner ? [CPBundle bundleForClass:[anOwner class]] : [CPBundle mainBundle];
        cib = [[CPCib alloc] initWithCibNamed:anIdentifier bundle:bundle];
    }

    if (!cib)
    {
        _unavailable_custom_cibs[anIdentifier] = YES;
        return nil;
    }

    var objects = [],
        load = [cib instantiateCibWithOwner:anOwner topLevelObjects:objects];

    if (!load)
        return nil;

    var count = objects.length;

    while (count--)
    {
        var obj = objects[count];

        if ([obj isKindOfClass:[CPView class]])
        {
            [obj setIdentifier:anIdentifier];
            [obj setAutoresizingMask:CPViewNotSizable];

            return obj;
        }
    }

    return nil;
}

- (void)_updateIsViewBased
{
    if ([self _delegateRespondsToViewForTableColumn])
        _viewForTableColumnRowSelector = @selector(_viewForTableColumn:row:);
    else if ([self _delegateRespondsToDataViewForTableColumn])
        _viewForTableColumnRowSelector = @selector(_dataViewForTableColumn:row:);

     _isViewBased = (_viewForTableColumnRowSelector !== nil || _archivedDataViews !== nil);
}

/*!
    @ignore
*/
- (void)_enqueueReusableDataView:(CPView)aDataView
{
    if (!aDataView)
        return;

    // FIXME: yuck!
    var identifier = [aDataView identifier];

    if (!_cachedDataViews[identifier])
        _cachedDataViews[identifier] = [aDataView];
    else
        _cachedDataViews[identifier].push(aDataView);
}

/*!
    @ignore
    // we override here because we have to adjust the header
*/
- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    if (_headerView)
        [_headerView setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), CGRectGetHeight([_headerView frame]))];

    _exposedRect = nil;
}

/*!
    @ignore
*/
- (void)setFrameOrigin:(CGPoint)aPoint
{
    [super setFrameOrigin:aPoint];

    _exposedRect = nil;
}

/*!
    @ignore
*/
- (void)setBoundsOrigin:(CGPoint)aPoint
{
    [super setBoundsOrigin:aPoint];

    _exposedRect = nil;
}

/*!
    @ignore
*/
- (void)setBoundsSize:(CGSize)aSize
{
    [super setBoundsSize:aSize];

    _exposedRect = nil;
}

/*!
    @ignore
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    [super setNeedsDisplay:aFlag];
    [_tableDrawView setNeedsDisplay:aFlag];

    [[self headerView] setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (void)setNeedsLayout
{
    [super setNeedsLayout];
    [[self headerView] setNeedsLayout];
}

/*!
    @ignore
*/
- (BOOL)_isFocused
{
    var isEditing = _editingRow !== CPNotFound || _editingCellIndex;

    return [[self window] isKeyWindow] && ([[self window] firstResponder] === self || isEditing);
}

/*!
    @ignore
*/
- (void)_drawRect:(CGRect)aRect
{
    // FIX ME: All three of these methods will likely need to be rewritten for 1.0
    // We've got grid drawing in highlightSelection and crap everywhere.

    var exposedRect = [self exposedRect];

    [self drawBackgroundInClipRect:exposedRect];
    [self highlightSelectionInClipRect:exposedRect];
    [self drawGridInClipRect:exposedRect];

    if (_implementsCustomDrawRow)
        [self _drawRows:_exposedRows clipRect:exposedRect];
}

/*!
    Draws the background in a given clip rect.
    This method should only be overridden if you want something other than a solid color or alternating row colors.
    @note this method should not be called directly, instead use \c setNeedsDisplay:
*/
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

    var exposedRows = [self _unboundedRowsInRect:aRect],
        firstRow = FLOOR(exposedRows.location / colorCount) * colorCount,
        lastRow = CPMaxRange(exposedRows),
        colorIndex = 0,
        groupRowRects = [];

    //loop through each color so we only draw once for each color
    while (colorIndex < colorCount)
    {
        CGContextBeginPath(context);

        for (var row = firstRow + colorIndex; row <= lastRow; row += colorCount)
        {
            // if it's not a group row draw it otherwise we draw it later
            if (![_groupRows containsIndex:row])
                CGContextAddRect(context, CGRectIntersection(aRect, [self _rectOfRow:row checkRange:NO]));
            else
                groupRowRects.push(CGRectIntersection(aRect, [self _rectOfRow:row checkRange:NO]));
        }

        CGContextClosePath(context);

        CGContextSetFillColor(context, rowColors[colorIndex]);
        CGContextFillPath(context);

        colorIndex++;
    }

    [self _drawGroupRowsForRects:groupRowRects];
}

/*!
    Draws the grid for the tableview based on the set grid mask in a given clip rect.
    @note this method should not be called directly, instead use setNeedsDisplay:
*/
- (void)drawGridInClipRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        gridStyleMask = [self gridStyleMask];

    if (!(gridStyleMask & (CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask)))
        return;

    CGContextBeginPath(context);

    if (gridStyleMask & CPTableViewSolidHorizontalGridLineMask)
    {
        var exposedRows = [self _unboundedRowsInRect:aRect],
            row = exposedRows.location,
            lastRow = CPMaxRange(exposedRows) - 1,
            rowY = -0.5,
            minX = CGRectGetMinX(aRect),
            maxX = CGRectGetMaxX(aRect);

        for (; row <= lastRow; ++row)
        {
            // grab each row rect and add the top and bottom lines
            var rowRect = [self _rectOfRow:row checkRange:NO],
                rowY = CGRectGetMaxY(rowRect) - 0.5;

            CGContextMoveToPoint(context, minX, rowY);
            CGContextAddLineToPoint(context, maxX, rowY);
        }

        if (_rowHeight > 0.0)
        {
            var rowHeight = _rowHeight + _intercellSpacing.height,
                totalHeight = CGRectGetMaxY(aRect);

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
            minY = CGRectGetMinY(aRect),
            maxY = CGRectGetMaxY(aRect);

        for (; columnArrayIndex < columnArrayCount; ++columnArrayIndex)
        {
            var columnRect = [self rectOfColumn:columnsArray[columnArrayIndex]],
                columnX = CGRectGetMaxX(columnRect) - 0.5;

            CGContextMoveToPoint(context, columnX, minY);
            CGContextAddLineToPoint(context, columnX, maxY);
        }
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, [self gridColor]);
    CGContextStrokePath(context);
}

/*!
    Draws the selection with the set selection highlight style in a given clip rect.
    You can change the highlight style to a source list style gradient in setSelectionHighlightStyle:
    @note this method should not be called directly, instead use \c setNeedsDisplay:
*/
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

    var count,
        count2 = count = [indexes count];

    if (!count)
        return;

    var drawGradient = (CPFeatureIsCompatible(CPHTMLCanvasFeature) && _selectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList && [_selectedRowIndexes count] >= 1),
        deltaHeight = 0.5 * (_gridStyleMask & CPTableViewSolidHorizontalGridLineMask),
        focused = [self _isFocused];

    CGContextBeginPath(context);

    if (drawGradient)
    {
        var gradientCache = focused ? [self selectionGradientColors] : [self unfocusedSelectionGradientColors],
            topLineColor = [gradientCache objectForKey:CPSourceListTopLineColor],
            bottomLineColor = [gradientCache objectForKey:CPSourceListBottomLineColor],
            gradientColor = [gradientCache objectForKey:CPSourceListGradient];
    }

    var normalSelectionHighlightColor = focused ? [self selectionHighlightColor] : [self unfocusedSelectionHighlightColor];

    // don't do these lookups if there are no group rows
    if ([_groupRows count])
    {
        var topGroupLineColor = [CPColor colorWithCalibratedWhite:212.0 / 255.0 alpha:1.0],
            bottomGroupLineColor = [CPColor colorWithCalibratedWhite:185.0 / 255.0 alpha:1.0],
            gradientGroupColor = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [212.0 / 255.0, 212.0 / 255.0, 212.0 / 255.0, 1.0, 197.0 / 255.0, 197.0 / 255.0, 197.0 / 255.0, 1.0], [0, 1], 2);
    }

    while (count--)
    {
        var currentIndex = indexes[count],
            rowRect = CGRectIntersection(objj_msgSend(self, rectSelector, currentIndex), aRect);

        // group rows get the same highlight style as other rows if they're source list...
        if (!drawGradient)
            var shouldUseGroupGradient = [_groupRows containsIndex:currentIndex];

        if (drawGradient || shouldUseGroupGradient)
        {
            var minX = CGRectGetMinX(rowRect),
                minY = CGRectGetMinY(rowRect),
                maxX = CGRectGetMaxX(rowRect),
                maxY = CGRectGetMaxY(rowRect) - deltaHeight;

            if (!drawGradient)
            {
                //If there is no source list gradient we need to close the selection path and fill it now
                [normalSelectionHighlightColor setFill];
                CGContextClosePath(context);
                CGContextFillPath(context);
                CGContextBeginPath(context);
            }

            CGContextAddRect(context, rowRect);

            CGContextDrawLinearGradient(context, (shouldUseGroupGradient) ? gradientGroupColor : gradientColor, rowRect.origin, CGPointMake(minX, maxY), 0);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, minY + .5);
            CGContextAddLineToPoint(context, maxX, minY + .5);
            CGContextSetStrokeColor(context, (shouldUseGroupGradient) ? topGroupLineColor : topLineColor);
            CGContextStrokePath(context);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, maxY - .5);
            CGContextAddLineToPoint(context, maxX, maxY - .5);
            CGContextSetStrokeColor(context, (shouldUseGroupGradient) ? bottomGroupLineColor : bottomLineColor);
            CGContextStrokePath(context);
        }
        else
        {
            var radius = [self currentValueForThemeAttribute:@"selection-radius"];

            if (radius > 0)
            {
                var minX = CGRectGetMinX(rowRect),
                    maxX = CGRectGetMaxX(rowRect),
                    minY = CGRectGetMinY(rowRect),
                    maxY = CGRectGetMaxY(rowRect);

                CGContextMoveToPoint(context, minX + radius, minY);
                CGContextAddArcToPoint(context, maxX, minY, maxX, minY + radius, radius);
                CGContextAddArcToPoint(context, maxX, maxY, maxX - radius, maxY, radius);
                CGContextAddArcToPoint(context, minX, maxY, minX, maxY - radius, radius);
                CGContextAddArcToPoint(context, minX, minY, minX + radius, minY, radius);
            }
            else
                CGContextAddRect(context, rowRect);
        }
    }

    CGContextClosePath(context);

    if (!drawGradient)
    {
        [normalSelectionHighlightColor setFill];
        CGContextFillPath(context);
    }

    CGContextBeginPath(context);

    var gridStyleMask = [self gridStyleMask];

    for (var i = 0; i < count2; i++)
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
    CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:@"highlighted-grid-color"]);
    CGContextStrokePath(context);
}

/*!
    @ignore
    Draws the group rows
    FIX ME: this should be themed...
*/
- (void)_drawGroupRowsForRects:(CPArray)rects
{
    if ((CPFeatureIsCompatible(CPHTMLCanvasFeature) && _selectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList) || !rects.length)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        i = rects.length;

    CGContextBeginPath(context);

    var gradientCache = [self selectionGradientColors],
        topLineColor = [CPColor colorWithHexString:"d3d3d3"],
        bottomLineColor = [CPColor colorWithHexString:"bebebd"],
        gradientColor = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [220.0 / 255.0, 220.0 / 255.0, 220.0 / 255.0, 1.0,
                                                                                            199.0 / 255.0, 199.0 / 255.0, 199.0 / 255.0, 1.0], [0, 1], 2),
        drawGradient = YES;

    while (i--)
    {
        var rowRect = rects[i];

        CGContextAddRect(context, rowRect);

        if (drawGradient)
        {
            var minX = CGRectGetMinX(rowRect),
                minY = CGRectGetMinY(rowRect),
                maxX = CGRectGetMaxX(rowRect),
                maxY = CGRectGetMaxY(rowRect);

            CGContextDrawLinearGradient(context, gradientColor, rowRect.origin, CGPointMake(minX, maxY), 0);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, minY);
            CGContextAddLineToPoint(context, maxX, minY);
            CGContextSetStrokeColor(context, topLineColor);
            CGContextStrokePath(context);

            CGContextBeginPath(context);
            CGContextMoveToPoint(context, minX, maxY);
            CGContextAddLineToPoint(context, maxX, maxY - 1);
            CGContextSetStrokeColor(context, bottomLineColor);
            CGContextStrokePath(context);
        }
    }
}

/*!
    @ignore
*/
- (void)_drawRows:(CPIndexSet)rowsIndexes clipRect:(CGRect)clipRect
{
    var row = [rowsIndexes firstIndex];

    while (row !== CPNotFound)
    {
        [self drawRow:row clipRect:CGRectIntersection(clipRect, [self rectOfRow:row])];
        row = [rowsIndexes indexGreaterThanIndex:row];
    }
}

/*!
    While this method doesn't do anything in Cappuccino, subclasses can override it to customize the
    appearance of a row.

    @note \c tableView:willDisplayView:forTableColumn:row is sent to the delegate before drawing
*/
- (void)drawRow:(CPInteger)row clipRect:(CGRect)rect
{
    // This method does currently nothing in cappuccino. Can be overridden by subclasses.

}

/*!
    @ignore
*/
- (void)layoutSubviews
{
    [self load];
}

/*!
    @ignore
*/
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

    if ([aView isKindOfClass:[CPClipView class]])
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

/*!
    @ignore
*/
- (void)superviewBoundsChanged:(CPNotification)aNotification
{
    _exposedRect = nil;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*!
    @ignore
*/
- (void)superviewFrameChanged:(CPNotification)aNotification
{
    _exposedRect = nil;

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
    // Try to become the first responder, but if we can't, that's okay.
    [[self window] makeFirstResponder:self];

    var row = [self rowAtPoint:aPoint];

    // If the user clicks outside a row then deselect everything.
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

    return YES;
}

/*!
    @ignore
*/
- (CPMenu)menuForEvent:(CPEvent)theEvent
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableViewMenuForTableColumn_Row_))
        return [super menuForEvent:theEvent];

    var location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        row = [self rowAtPoint:location],
        column = [self columnAtPoint:location],
        tableColumn = [[self tableColumns] objectAtIndex:column];

    return [_delegate tableView:self menuForTableColumn:tableColumn row:row];
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
                    offset = CGPointMakeZero(),
                    tableColumns = [_tableColumns objectsAtIndexes:_exposedColumns];

                // We deviate from the default Cocoa implementation here by asking for a view in stead of an image
                // We support both, but the view preferred over the image because we can mimic the rows we are dragging
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
                    view = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, [image size].height)];
                    [view setImage:image];
                }

                var bounds = [view bounds],
                    viewLocation = CGPointMake(aPoint.x - CGRectGetWidth(bounds) / 2 + offset.x, aPoint.y - CGRectGetHeight(bounds) / 2 + offset.y);
                [self dragView:view at:viewLocation offset:CGPointMakeZero() event:[CPApp currentEvent] pasteboard:pboard source:self slideBack:YES];
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
        columnIndex = -1,
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

    // Accept either tableView:setObjectValue:forTableColumn:row: delegate method, or a binding.
    if (!_isViewBased && mouseIsUp
        && !_trackingPointMovedOutOfClickSlop
        && ([[CPApp currentEvent] clickCount] > 1)
        && ((_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
            || [self infoForBinding:@"content"]))
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
        _clickedColumn = [self columnAtPoint:lastPoint];
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

/*!
    @ignore
*/
- (void)_draggingEnded
{
    _retargetedDropOperation = nil;
    _retargetedDropRow = nil;
    _draggedRowIndexes = [CPIndexSet indexSet];
    [_dropOperationFeedbackView removeFromSuperview];
    [self _enqueueDraggingViews];
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

    // If there is no (the default) or too little inter-cell spacing we create some room for the CPTableViewDropAbove indicator
    // This probably doesn't work if the row height is smaller than or around 5.0
    if ([self intercellSpacing].height < 5.0)
        rowRect = CGRectInset(rowRect, 0.0, 5.0 - [self intercellSpacing].height);

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
    var row = [self rowAtPoint:dragPoint],
        // Determine if the mouse is currently closer to this row or the row below it
        lowerRow = row + 1,
        rect = [self rectOfRow:row],
        bottomPoint = CGRectGetMaxY(rect),
        bottomThirty = bottomPoint - ((bottomPoint - CGRectGetMinY(rect)) * 0.3),
        numberOfRows = [self numberOfRows];

    if (row < 0)
        row = (CGRectGetMaxY(rect) < dragPoint.y) ? numberOfRows : row;
    else if (dragPoint.y > MAX(bottomThirty, bottomPoint - 6))
        row = lowerRow;

    row = MIN(numberOfRows, row);

    return row;
}

/*!
    @ignore
*/
- (void)_validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)dropOperation
{
    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_)
        return [_dataSource tableView:self validateDrop:info proposedRow:row proposedDropOperation:dropOperation];

    return CPDragOperationNone;
}

/*!
    @ignore
*/
- (CGRect)_rectForDropHighlightViewOnRow:(int)theRowIndex
{
    if (theRowIndex >= [self numberOfRows])
        theRowIndex = [self numberOfRows] - 1;

    return [self _rectOfRow:theRowIndex checkRange:NO];
}

/*!
    @ignore
*/
- (CGRect)_rectForDropHighlightViewBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex offset:(CGPoint)theOffset
{
    if (theLowerRowIndex > [self numberOfRows])
        theLowerRowIndex = [self numberOfRows];

    return [self _rectOfRow:theLowerRowIndex checkRange:NO];
}

/*!
    @ignore
*/
- (CPDragOperation)draggingUpdated:(id)sender
{
    _retargetedDropRow = nil;
    _retargetedDropOperation = nil;

    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        dropOperation = [self _proposedDropOperationAtPoint:location],
        numberOfRows = [self numberOfRows],
        row = [self _proposedRowAtPoint:location],
        dragOperation = [self _validateDrop:sender proposedRow:row proposedDropOperation:dropOperation];

    if (_retargetedDropRow !== nil)
        row = _retargetedDropRow;
    if (_retargetedDropOperation !== nil)
        dropOperation = _retargetedDropOperation;


    if (dropOperation === CPTableViewDropOn && row >= numberOfRows)
        row = numberOfRows - 1;

    var rect = CGRectMakeZero();

    if (row === -1)
        rect = [self exposedRect];

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
    // actual validation is called in draggingUpdated:
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
    This method is sent to the data source for convenience...
*/
- (void)draggedImage:(CPImage)anImage endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    if ([_dataSource respondsToSelector:@selector(tableView:didEndDraggedImage:atPosition:operation:)])
        [_dataSource tableView:self didEndDraggedImage:anImage atPosition:aLocation operation:anOperation];
}

/*
    @ignore
    We're using this because we drag views instead of images so we can get the rows themselves to actually drag.
*/
- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    [self _draggingEnded];
    [self draggedImage:aView endedAt:aLocation operation:anOperation];
}

- (void)_enqueueDraggingViews
{
    [_draggingViews enumerateObjectsUsingBlock:function(dataView, idx)
    {
        [self _enqueueReusableDataView:dataView];
    }];

    [_draggingViews removeAllObjects];
}

/*!
    @ignore
*/
- (void)_updateSelectionWithMouseAtRow:(CPInteger)aRow
{
    //check to make sure the row exists
    if (aRow < 0)
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
        if (_selectionAnchorRow == CPNotFound)
            _selectionAnchorRow = [self numberOfRows] - 1;

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

    _lastSelectedRow = [newSelection containsIndex:aRow] ? aRow : [newSelection lastIndex];
}

/*!
    @ignore
*/
- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

/*!
    @ignore
*/
- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
}

/*!
    @ignore
*/
- (void)becomeKeyWindow
{
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (void)resignKeyWindow
{
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
    return YES;
}

/*!
    @ignore
*/
- (BOOL)resignFirstResponder
{
    [self setNeedsDisplay:YES];
    return YES;
}

/*!
    @ignore
*/
- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*!
    @ignore
*/
- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

/*!
    @ignore
*/
- (id)hitTest:(CGPoint)aPoint
{
    var hit = [super hitTest:aPoint];

    if ([[CPApp currentEvent] type] == CPLeftMouseDown && [hit acceptsFirstResponder] && ![self isRowSelected:[self rowForView:hit]])
        return self;

    return hit;
}

- (void)_startObservingFirstResponder
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_firstResponderDidChange:) name:_CPWindowDidChangeFirstResponderNotification object:[self window]];
}

- (void)_stopObservingFirstResponder
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:_CPWindowDidChangeFirstResponderNotification object:[self window]];
}

- (void)_firstResponderDidChange:(CPNotification)aNotification
{
    var responder = [[self window] firstResponder];

    if (![responder isKindOfClass:[CPView class]] || ![responder isDescendantOf:self])
    {
        _editingRow = CPNotFound;
        _editingColumn = CPNotFound;
        return;
    }

    _editingRow = [self rowForView:responder];
    _editingColumn = [self columnForView:responder];

    if (_editingRow !== CPNotFound && [responder isKindOfClass:[CPTextField class]] && ![responder isBezeled])
    {
        [responder setBezeled:YES];
        [self _registerForEndEditingNote:responder];
    }
}

- (void)_registerForEndEditingNote:(CPView)aTextField
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_textFieldEditingDidEnd:) name:CPControlTextDidEndEditingNotification object:aTextField];
}

- (void)_unregisterForEndEditingNote:(CPView)aTextField
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPControlTextDidEndEditingNotification object:aTextField];
}

- (void)_textFieldEditingDidEnd:(CPNotification)aNote
{
    // FIXME: When you edit a text field and hit enter without any text modification, the CPControlTextDidEndEditingNotification
    // is NOT sent. This is a bug in CPTextField or CPControl according to cocoa.
    var textField = [aNote object];

    [self _unregisterForEndEditingNote:textField];
    [textField setBezeled:NO];

    var action = [self _disableActionIfExists:textField];
    [textField resignFirstResponder];
    [textField setAction:action];
}

- (SEL)_disableActionIfExists:(CPView)aView
{
    // TODO: We disable action to prevent it from beeing sent twice when we resign the FR inside a textEndEditing notification.
    // Check if this is due to a bug in CPTextField.
    var action = nil;
    if ([aView respondsToSelector:@selector(action)] && (action = [aView action]))
        [aView setAction:nil];

    return action;
}

/*!
    @ignore
*/
- (void)keyDown:(CPEvent)anEvent
{
    var character = [anEvent charactersIgnoringModifiers],
        modifierFlags = [anEvent modifierFlags];

    // Check for the key events manually, as opposed to waiting for CPWindow to sent the actual action message
    // in _processKeyboardUIKey:, because we might not want to handle the arrow events.
    if (character === CPUpArrowFunctionKey || character === CPDownArrowFunctionKey)
    {
        // We're not interested in the arrow keys if there are no rows.
        // Technically we should also not be interested if we can't scroll,
        // but Cocoa doesn't handle that situation either.
        if ([self numberOfRows] !== 0)
        {
            [self _moveSelectionWithEvent:anEvent upward:(character === CPUpArrowFunctionKey)];

            return;
        }
    }
    else if (character === CPDeleteCharacter || character === CPDeleteFunctionKey)
    {
        // Don't call super if the delegate is interested in the delete key
        if ([self _sendDelegateDeleteKeyPressed])
            return;
    }

    [super keyDown:anEvent];
}

/*!
    @ignore
    Determines if the selection is broken. A broken selection
    is a non-continuous selection of rows.
*/
- (BOOL)_selectionIsBroken
{
    return [self selectedRowIndexes]._ranges.length !== 1;
}

/*!
    @ignore
    Selection behaviour depends on two things:
    _lastSelectedRow and the anchored selection (the last row selected by itself)
*/
- (void)_moveSelectionWithEvent:(CPEvent)theEvent upward:(BOOL)shouldGoUpward
{
    if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ && ![_delegate selectionShouldChangeInTableView:self])
        return;
    var selectedIndexes = [self selectedRowIndexes];

    if ([selectedIndexes count] > 0)
    {
        var extend = (([theEvent modifierFlags] & CPShiftKeyMask) && _allowsMultipleSelection),
            i = [self selectedRow];

        if ([self _selectionIsBroken])
        {
            while ([selectedIndexes containsIndex:i])
            {
                shouldGoUpward ? i-- : i++;
            }
            _wasSelectionBroken = true;
        }
        else if (_wasSelectionBroken && ((shouldGoUpward && i !== [selectedIndexes firstIndex]) || (!shouldGoUpward && i !== [selectedIndexes lastIndex])))
        {
            shouldGoUpward ? i = [selectedIndexes firstIndex] - 1 : i = [selectedIndexes lastIndex];
            _wasSelectionBroken = false;
        }
        else
        {
            shouldGoUpward ? i-- : i++;
        }
    }
    else
    {
        var extend = NO;
        //no rows are currently selected
        if ([self numberOfRows] > 0)
            var i = shouldGoUpward ? [self numberOfRows] - 1 : 0; // if we select upward select the last row, otherwise select the first row
    }

    if (i >= [self numberOfRows] || i < 0)
        return;

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
    {
        var shouldSelect = [_delegate tableView:self shouldSelectRow:i];

        /* If shouldSelect returns NO it means this row cannot be selected.
            The proper behaviour is to then try to see if the next/previous
            row(s) can be selected, until we hit the first one that can be.
        */
        while (!shouldSelect && (i < [self numberOfRows] && i > 0))
        {
            shouldGoUpward ? --i : ++i; //check to see if the row can be selected. If it can't be then see if the next row can be selected.
            shouldSelect = [_delegate tableView:self shouldSelectRow:i];
        }

        if (!shouldSelect)
            return;
    }

    // If we go upward and see that this row is already selected we should deselect the row below.
    if (extend && [selectedIndexes containsIndex:i])
    {
        // The row we're on is the last to be selected.
        var differedLastSelectedRow = i;

        // no remove the one before/after it
        shouldGoUpward ? i++ : i--;

        [selectedIndexes removeIndex:i];

        //we're going to replace the selection
        extend = NO;
    }
    else if (extend)
    {
        if ([selectedIndexes containsIndex:i])
        {
            i = shouldGoUpward ? [selectedIndexes firstIndex] -1 : [selectedIndexes lastIndex] + 1;
            i = MIN(MAX(i, 0), [self numberOfRows] - 1);
        }

        [selectedIndexes addIndex:i];
        var differedLastSelectedRow = i;
    }
    else
    {
        selectedIndexes = [CPIndexSet indexSetWithIndex:i];
        var differedLastSelectedRow = i;
    }

    [self selectRowIndexes:selectedIndexes byExtendingSelection:extend];

    // we differ because selectRowIndexes: does its own thing which would set the wrong index
    _lastSelectedRow = differedLastSelectedRow;

    if (i !== CPNotFound)
        [self scrollRowToVisible:i];
}

@end


@implementation CPTableView (Bindings)

+ (id)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == @"content")
        return [CPTableContentBinder class];

    return [super _binderClassForBinding:aBinding];
}

/*!
    @ignore
*/
- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding === @"selectionIndexes")
        return @"selectedRowIndexes";

    return [super _replacementKeyPathForBinding:aBinding];
}

/*!
    @ignore
*/
- (void)_establishBindingsIfUnbound:(id)destination
{
    if ([[self infoForBinding:@"content"] objectForKey:CPObservedObjectKey] !== destination)
    {
        [super bind:@"content" toObject:destination withKeyPath:@"arrangedObjects" options:nil];
        _contentBindingExplicitlySet = NO;
    }

    // If the content binding was set manually assume the user is taking manual control of establishing bindings.
    if (!_contentBindingExplicitlySet)
    {
        if ([[self infoForBinding:@"selectionIndexes"] objectForKey:CPObservedObjectKey] !== destination)
            [self bind:@"selectionIndexes" toObject:destination withKeyPath:@"selectionIndexes" options:nil];

        if ([[self infoForBinding:@"sortDescriptors"] objectForKey:CPObservedObjectKey] !== destination)
            [self bind:@"sortDescriptors" toObject:destination withKeyPath:@"sortDescriptors" options:nil];
    }
}

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];

    if (aBinding == @"content")
        _contentBindingExplicitlySet = YES;
}

@end


@implementation CPTableContentBinder : CPBinder
{
    id _content @accessors(property=content);
}

- (void)setValueFor:(id)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey];

    _content = [destination valueForKey:keyPath];

    [_source reloadData];
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
    CPTableViewCornerViewKey                = @"CPTableViewCornerViewKey",
    CPTableViewAutosaveNameKey              = @"CPTableViewAutosaveNameKey",
    CPTableViewArchivedReusableViewsKey     = @"CPTableViewArchivedReusableViewsKey";

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

        _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey] || [self valueForThemeAttribute:@"default-row-height"];
        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey];

        if (CGSizeEqualToSize(_intercellSpacing, CGSizeMakeZero()))
            _intercellSpacing = CGSizeMake(3.0, 2.0);

        [self setGridColor:[aCoder decodeObjectForKey:CPTableViewGridColorKey]];
        _gridStyleMask = [aCoder decodeIntForKey:CPTableViewGridStyleMaskKey];

        _usesAlternatingRowBackgroundColors = [aCoder decodeObjectForKey:CPTableViewUsesAlternatingBackgroundKey];
        [self setAlternatingRowBackgroundColors:[aCoder decodeObjectForKey:CPTableViewAlternatingRowColorsKey]];

        _headerView = [aCoder decodeObjectForKey:CPTableViewHeaderViewKey];
        _cornerView = [aCoder decodeObjectForKey:CPTableViewCornerViewKey];

        [self setDataSource:[aCoder decodeObjectForKey:CPTableViewDataSourceKey]];
        [self setDelegate:[aCoder decodeObjectForKey:CPTableViewDelegateKey]];

        [self _init];

        if ([aCoder containsValueForKey:CPTableViewArchivedReusableViewsKey])
            _archivedDataViews = [aCoder decodeObjectForKey:CPTableViewArchivedReusableViewsKey];

        [self _updateIsViewBased];

        [self viewWillMoveToSuperview:[self superview]];

        // Do this as late as possible to make sure the tableview is fully configured
        [self setAutosaveName:[aCoder decodeObjectForKey:CPTableViewAutosaveNameKey]];
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
    [aCoder encodeObject:[self alternatingRowBackgroundColors] forKey:CPTableViewAlternatingRowColorsKey];

    [aCoder encodeObject:_cornerView forKey:CPTableViewCornerViewKey];
    [aCoder encodeObject:_headerView forKey:CPTableViewHeaderViewKey];

    [aCoder encodeObject:_autosaveName forKey:CPTableViewAutosaveNameKey];

    if (_archivedDataViews)
        [aCoder encodeObject:_archivedDataViews forKey:CPTableViewArchivedReusableViewsKey];
}

@end


@implementation CPIndexSet (tableview)

- (void)removeMatches:(CPIndexSet)otherSet
{
    var firstindex = [self firstIndex],
        index = MIN(firstindex, [otherSet firstIndex]),
        switchFlag = (index == firstindex);

    while (index != CPNotFound)
    {
        var indexSet = (switchFlag) ? otherSet : self,
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
    if (tableView._destinationDragStyle === CPTableViewDraggingDestinationFeedbackStyleNone || isBlinking)
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
            newRect = CGRectMake(aRect.origin.x + 2, aRect.origin.y + 2, aRect.size.width - 4, aRect.size.height - 5);

        if ([selectedRows containsIndex:currentRow])
        {
            CGContextSetLineWidth(context, 2);
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
        }
        else
        {
            CGContextSetFillColor(context, [CPColor colorWithRed:72 / 255 green:134 / 255 blue:202 / 255 alpha:0.25]);
            CGContextFillRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);
        }

        CGContextStrokeRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);

    }
    else if (dropOperation === CPTableViewDropAbove)
    {
        //reposition the view up a tad
        [self setFrameOrigin:CGPointMake(_frame.origin.x, _frame.origin.y - 8)];

        var selectedRows = [tableView selectedRowIndexes];

        if ([selectedRows containsIndex:currentRow - 1] || [selectedRows containsIndex:currentRow])
        {
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
            CGContextSetLineWidth(context, 4);
            //draw the circle thing
            CGContextStrokeEllipseInRect(context, CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
            //then draw the line
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
            CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
            CGContextStrokePath(context);

            CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
            CGContextSetLineWidth(context, 3);
        }

        //draw the circle thing
        CGContextStrokeEllipseInRect(context, CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
        //then draw the line
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
        CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
        CGContextStrokePath(context);
        //CGContextStrokeLineSegments(context, [aRect.origin.x + 8,  aRect.origin.y + 8, 300 , aRect.origin.y + 8]);
    }
}

- (void)blink
{
    if (dropOperation !== CPTableViewDropOn)
        return;

    isBlinking = YES;

    var showCallback = function()
    {
        objj_msgSend(self, "setHidden:", NO)
        isBlinking = NO;
    };

    var hideCallback = function()
    {
        objj_msgSend(self, "setHidden:", YES)
        isBlinking = YES;
    };

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
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
        _lineColor = aColor;

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, _lineColor);

    var points = [
                    CGPointMake(0.5, 0),
                    CGPointMake(0.5, aRect.size.height)
                 ];

    CGContextStrokeLineSegments(context, points, 2);

    points = [
                CGPointMake(aRect.size.width - 0.5, 0),
                CGPointMake(aRect.size.width - 0.5, aRect.size.height)
             ];

    CGContextStrokeLineSegments(context, points, 2);
}

@end


@implementation CPTableCellView : CPView
{
    id _objectValue         @accessors(property=objectValue);

    CPTextField _textField  @accessors(property=textField);
    CPImageView _imageView  @accessors(property=imageView);
}

- (void)awakeFromCib
{
    [self setThemeState:CPThemeStateTableDataView];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    [self recursivelyPerformSelector:@selector(setThemeState:) withObject:aState startingFrom:self];
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    [self recursivelyPerformSelector:@selector(unsetThemeState:) withObject:aState startingFrom:self];
}

- (void)recursivelyPerformSelector:(SEL)selector withObject:(id)anObject startingFrom:(id)aView
{
    [[aView subviews] enumerateObjectsUsingBlock:function(view, idx)
    {
        [view performSelector:selector withObject:anObject];

        if (![view isKindOfClass:[self class]]) // Avoid infinite loop if a subview is a CPTableCellView.
            [self recursivelyPerformSelector:selector withObject:anObject startingFrom:view];
    }];
}

- (CPString)description
{
    return "<" + [self className] + " 0x" + [CPString stringWithHash:[self UID]] + " identifier=" + [self identifier] + ">";
}

@end
