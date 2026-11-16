/*
 * CPTableViewCore.j
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
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView

@global CPApp


CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";

CPTableViewDataSource_numberOfRowsInTableView_                                                      = 1 << 0,
    CPTableViewDataSource_tableView_objectValueForTableColumn_row_                                      = 1 << 1,
    CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2,
    CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_                                       = 1 << 3,
    CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_ = 1 << 4,
    CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_                     = 1 << 5,
    CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_                                  = 1 << 6,
    CPTableViewDataSource_tableView_sortDescriptorsDidChange_                                           = 1 << 7;

CPTableViewDelegate_selectionShouldChangeInTableView_                                               = 1 << 0,
    CPTableViewDelegate_tableView_viewForTableColumn_row_                                               = 1 << 1,
    CPTableViewDelegate_tableView_dataViewForTableColumn_row_                                           = 1 << 2,
    CPTableViewDelegate_tableView_didClickTableColumn_                                                  = 1 << 3,
    CPTableViewDelegate_tableView_didDragTableColumn_                                                   = 1 << 4,
    CPTableViewDelegate_tableView_heightOfRow_                                                          = 1 << 5,
    CPTableViewDelegate_tableView_isGroupRow_                                                           = 1 << 6,
    CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_                                       = 1 << 7,
    CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_                           = 1 << 8,
    CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_                                 = 1 << 9,
    CPTableViewDelegate_tableView_shouldEditTableColumn_row_                                            = 1 << 10,
    CPTableViewDelegate_tableView_shouldSelectRow_                                                      = 1 << 11,
    CPTableViewDelegate_tableView_shouldSelectTableColumn_                                              = 1 << 12,
    CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_                            = 1 << 13,
    CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_                                   = 1 << 14,
    CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_                     = 1 << 15,
    CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_                    = 1 << 16,
    CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_                                   = 1 << 17,
    CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_                                   = 1 << 18,
    CPTableViewDelegate_tableView_willRemoveView_forTableColumn_row_                                    = 1 << 19,
    CPTableViewDelegate_tableViewColumnDidMove_                                                         = 1 << 20,
    CPTableViewDelegate_tableViewColumnDidResize_                                                       = 1 << 21,
    CPTableViewDelegate_tableViewSelectionDidChange_                                                    = 1 << 22,
    CPTableViewDelegate_tableViewSelectionIsChanging_                                                   = 1 << 23,
    CPTableViewDelegate_tableViewMenuForTableColumn_row_                                                = 1 << 24,
    CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_                                         = 1 << 25;

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

@protocol CPTableViewDataSource <CPObject>

@optional
- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id <CPDraggingInfo>)info row:(CPInteger)aRowIndex dropOperation:(CPTableViewDropOperation)operation;
- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard;
- (CPArray)tableView:(CPTableView)aTableView namesOfPromisedFilesDroppedAtDestination:(CPURL)dropDestination forDraggedRowsWithIndexes:(CPIndexSet)anIndexSet;
- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id <CPDraggingInfo>)info proposedRow:(CPInteger)aRowIndex proposedDropOperation:(CPTableViewDropOperation)anOperation;
- (CPInteger)numberOfRowsInTableView:(CPTableView)aTableView;
- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObjectValue forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors;

@end

@protocol CPTableViewDelegate <CPObject>

@optional
- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView;
- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(CPInteger)aRowIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aTableView row:(CPInteger)aRowIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldReorderColumn:(CPInteger)columnIndex toColumn:(NSInteger)newColumnIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(CPInteger)aRowIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldSelectTableColumn:(CPTableColumn)aTableColumn;
- (BOOL)tableView:(CPTableView)aTableView shouldShowViewExpansionForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldTrackView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (BOOL)tableView:(CPTableView)aTableView shouldTypeSelectForEvent:(CPEvent)anEvent withCurrentSearchString:(CPString)searchString;
- (CPIndexSet)tableView:(CPTableView)aTableView selectionIndexesForProposedSelection:(CPIndexSet)proposedSelectionIndexes;
- (CPInteger)tableView:(CPTableView)aTableView nextTypeSelectMatchFromRow:(CPInteger)startRow toRow:(CPInteger)endRow forString:(CPString)searchString;
- (CPMenu)tableViewMenuForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (CPString)tableView:(CPTableView)aTableView toolTipForView:(CPView)aView rect:(CGRect)aRect tableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex mouseLocation:(CGPoint)mouseLocation;
- (CPString)tableView:(CPTableView)aTableView typeSelectStringForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (CPView)tableView:(CPTableView)aTableView dataViewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (CPView)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (float)tableView:(CPTableView)aTableView heightOfRow:(CPInteger)aRowIndex;
- (void)tableView:(CPTableView)aTableView didClickTableColumn:(CPTableColumn)aTableColumn;
- (void)tableView:(CPTableView)aTableView didDragTableColumn:(CPTableColumn)aTableColumn;
- (void)tableView:(CPTableView)aTableView mouseDownInHeaderOfTableColumn:(CPTableColumn)aTableColumn;
- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (void)tableView:(CPTableView)aTableView willRemoveView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex;
- (void)tableViewSelectionDidChange:(CPNotification)aNotification;
- (void)tableViewSelectionIsChanging:(CPNotification)aNotification;

@end

/*!
    @ingroup appkit
    @class CPTableView

    A table view control displays record-oriented data in a table and
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
    id <CPTableViewDataSource>  _dataSource;
    CPInteger                   _implementedDataSourceMethods;

    id <CPTableViewDelegate>    _delegate;
    CPInteger                   _implementedDelegateMethods;

    CPArray                     _tableColumns;
    CPArray                     _tableColumnRanges;
    CPInteger                   _dirtyTableColumnRangeIndex;
    CPInteger                   _numberOfHiddenColumns;

    BOOL                        _reloadAllRows;
    BOOL                        _invalidateObjectValuesCache;
    Object                      _objectValues;

    CGRect                      _exposedRect;
    CPIndexSet                  _exposedRows;
    CPIndexSet                  _exposedColumns;

    Object                      _dataViewsForRows;
    Object                      _cachedDataViews;
    CPDictionary                _archivedDataViews;
    Object                      _unavailable_custom_cibs;

    // Row View Management (DOM Composition)
    Object                      _visibleRowViews;
    CPArray                     _cachedRowViews;

    //Configuring Behavior
    BOOL                        _allowsColumnReordering;
    BOOL                        _allowsColumnResizing;
    BOOL                        _allowsColumnSelection;
    BOOL                        _allowsMultipleSelection;
    BOOL                        _allowsEmptySelection;

    CPArray                     _sortDescriptors;

    //Setting Display Attributes
    CGSize                      _intercellSpacing;
    float                       _rowHeight;

    BOOL                        _usesAlternatingRowBackgroundColors;
    CPArray                     _alternatingRowBackgroundColors;
    BOOL                        _usesDefaultBackgroundColor;

    unsigned                    _selectionHighlightStyle;
    CPColor                     _unfocusedSelectionHighlightColor;
    CPDictionary                _unfocusedSourceListSelectionColor;
    CPTableColumn               _currentHighlightedTableColumn;
    unsigned                    _gridStyleMask;

    unsigned                    _numberOfRows;
    CPIndexSet                  _groupRows;

    CPArray                     _cachedRowHeights;

    // Persistence
    CPString                    _autosaveName;
    BOOL                        _autosaveTableColumns;

    CPTableHeaderView           _headerView;
    _CPCornerView               _cornerView;

    CPIndexSet                  _selectedColumnIndexes;
    CPIndexSet                  _selectedRowIndexes;
    CPInteger                   _selectionAnchorRow;
    CPInteger                   _lastSelectedRow;
    CPIndexSet                  _previouslySelectedRowIndexes;
    CGPoint                     _startTrackingPoint;
    CPDate                      _startTrackingTimestamp;
    BOOL                        _trackingPointMovedOutOfClickSlop;
    CPInteger                   _editingRow;
    CPInteger                   _editingColumn;

    SEL                         _doubleAction;
    id                          _doubleClickTarget @accessors(property=doubleClickTarget);
    id                          _doubleClickArgument @accessors(property=doubleClickArgument);
    CPInteger                   _clickedRow;
    CPInteger                   _clickedColumn;
    unsigned                    _columnAutoResizingStyle;

    int                         _lastTrackedRowIndex;
    CGPoint                     _originalMouseDownPoint;
    BOOL                        _verticalMotionCanDrag;
    unsigned                    _destinationDragStyle;
    BOOL                        _isSelectingSession;
    CPIndexSet                  _draggedRowIndexes;
    BOOL                        _wasSelectionBroken;

    _CPDropOperationDrawingView _dropOperationFeedbackView;
    CPDragOperation             _dragOperationDefaultMask;
    int                         _retargetedDropRow;
    CPDragOperation             _retargetedDropOperation;

    BOOL                        _disableAutomaticResizing @accessors(property=disableAutomaticResizing);
    BOOL                        _lastColumnShouldSnap;
    BOOL                        _implementsCustomDrawRow;
    BOOL                        _isViewBased;
    BOOL                        _contentBindingExplicitlySet;

    SEL                         _viewForTableColumnRowSelector;

    CPInteger                   _draggedColumnIndex;
    BOOL                        _draggedColumnIsSelected;
    BOOL                        _needsDifferedTableColumnRemove;
    CPArray                     _differedColumnDataToRemove;
    CPArray                     _selectedColumnBackgroundViews;

    Function                    _BlockDeselectView;
    Function                    _BlockSelectView;

    CPView                      _observedClipView;
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
+ (CPDictionary)themeAttributes
{
    return @{
            @"alternating-row-colors": [CPNull null],
            @"grid-color": [CPNull null],
            @"grid-line-thickness": 1.0,
            @"highlighted-grid-color": [CPNull null],
            @"selection-color": [CPNull null],
            @"unfocused-selection-color": [CPNull null],
            @"sourcelist-selection-color": [CPNull null],
            @"sort-image": [CPNull null],
            @"sort-image-reversed": [CPNull null],
            @"selection-radius": [CPNull null],
            @"image-generic-file": [CPNull null],
            @"default-row-height": 25.0,
            @"dropview-on-background-color": [CPNull null],
            @"dropview-on-border-color": [CPNull null],
            @"dropview-on-border-width": [CPNull null],
            @"dropview-on-border-radius": [CPNull null],
            @"dropview-on-selected-background-color": [CPNull null],
            @"dropview-on-selected-border-color": [CPNull null],
            @"dropview-on-selected-border-width": [CPNull null],
            @"dropview-on-selected-border-radius": [CPNull null],
            @"dropview-above-border-color": [CPNull null],
            @"dropview-above-border-width": [CPNull null],
            @"dropview-above-selected-border-color": [CPNull null],
            @"dropview-above-selected-border-width": [CPNull null],
            @"background-color": [CPNull null],
            @"group-row-background-color": [CPNull null],
            @"header-view-height": 25
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
        [self setBackgroundColor:nil];

        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setAlternatingRowBackgroundColors:[self valueForThemeAttribute:@"alternating-row-colors"]];

        _tableColumns = [];
        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = CPNotFound;
        _numberOfHiddenColumns = 0;

        _intercellSpacing = CGSizeMake(3.0, 2.0);
        _rowHeight = [self valueForThemeAttribute:@"default-row-height"];

        [self setGridColor:[self valueForThemeAttribute:@"grid-color"]];
        [self setGridStyleMask:CPTableViewGridNone];

        [self setHeaderView:[[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, [self valueForThemeAttribute:@"header-view-height"])]];
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
    _invalidateObjectValuesCache = NO;
    _dataViewsForRows = { };
    _numberOfRows = 0;
    _exposedRows = [CPIndexSet indexSet];
    _exposedColumns = [CPIndexSet indexSet];
    _cachedDataViews = { };
    _archivedDataViews = nil;
    _viewForTableColumnRowSelector = nil;
    _unavailable_custom_cibs = { };
    _cachedRowHeights = [];

    _groupRows = [CPIndexSet indexSet];

    // Row View Initialization for DOM rendering
    _visibleRowViews = { };
    _cachedRowViews = [];

    _draggedColumnIndex = -1;
    _draggedColumnIsSelected = NO;

    _editingRow = CPNotFound;
    _editingColumn = CPNotFound;

/*      //gradients for the source list when CPTableView is NOT first responder or the window is NOT key
    // FIX ME: we need to actually implement this.
    _sourceListInactiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [168.0/255.0,183.0/255.0,205.0/255.0,1.0,157.0/255.0,174.0/255.0,199.0/255.0,1.0], [0,1], 2);
    _sourceListInactiveTopLineColor = [CPColor colorWithCalibratedRed:(173.0/255.0) green:(187.0/255.0) blue:(209.0/255.0) alpha:1.0];
    _sourceListInactiveBottomLineColor = [CPColor colorWithCalibratedRed:(150.0/255.0) green:(161.0/255.0) blue:(183.0/255.0) alpha:1.0];*/
    _differedColumnDataToRemove = [];
    _needsDifferedTableColumnRemove = NO;
    _implementsCustomDrawRow = [self implementsSelector:@selector(drawRow:clipRect:)];

    if (!_sortDescriptors)
        _sortDescriptors = [];

    [self _initSubclass];
}

/*!
    Sets the background colour of the table view. A \c nil colour gives the default
    background: the theme's background colour in the table view's current state, else
    \c +[CPColor controlBackgroundColor], as in AppKit. For a transparent table view, set
    \c +[CPColor clearColor].
    @param aColor the background colour, or \c nil for the default background
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    if (aColor === [CPNull null])
        aColor = nil;

    _usesDefaultBackgroundColor = !aColor;

    [super setBackgroundColor:aColor || [self _defaultBackgroundColor]];
}

/*
    Returns the default background: the theme's background colour in the receiver's current
    state, else the control background colour, AppKit's default.
*/
- (CPColor)_defaultBackgroundColor
{
    return [self currentValueForThemeAttribute:@"background-color"] || [CPColor controlBackgroundColor];
}

/*
    Applies the default background again when the receiver has no background colour of its
    own.

    The table view set a white background, or a clear one in the HUD state, at each change of
    theme state, over the colour that the application had set. A change of appearance, key
    window or first responder is a change of theme state, so no colour of the application,
    the theme or AppKit could show. A change of theme state now marks the table view for
    layout, as for every view, and the layout applies the default only to a table view
    without a colour of its own.
*/
- (void)_updateDefaultBackgroundColor
{
    if (_usesDefaultBackgroundColor)
        [super setBackgroundColor:[self _defaultBackgroundColor]];
}

/*
    The receiver archives only a background colour of its own, so that a decoded copy takes
    the default background from its theme again.
*/
- (CPColor)_archivedBackgroundColor
{
    return _usesDefaultBackgroundColor ? nil : [super _archivedBackgroundColor];
}

- (void)_initSubclass
{
    _selectedColumnBackgroundViews = [];

    _BlockDeselectView = function(view, row, column)
    {
        [view unsetThemeState:CPThemeStateSelectedDataView];
        // Ensure we clear the focus state so the text goes back to normal color
        [view unsetThemeState:CPThemeStateFirstResponder];
    };

    _BlockSelectView = function(view, row, column)
    {
        [view setThemeState:CPThemeStateSelectedDataView];
        
        // If the table is focused, apply the state that turns text white immediately
        if ([self _isFocused])
            [view setThemeState:CPThemeStateFirstResponder];
        else
            [view unsetThemeState:CPThemeStateFirstResponder];
    };
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
- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRowIndex;
    @endcode


@section editing Editing:
Sets the data object for an item in a given row and column. This needs to be implemented if you want inline editing support
    @code
- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)rowIndex;
    @endcode


@section sorting Sorting:
The tableview will call this method if you click the tableheader. You should sort the datasource based off of the new sort descriptors and reload the data
    @code
- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors;
    @endcode


@section draganddrop Drag and Drop:
@note In order for the tableview to receive drops don't forget to first register the tableview for drag types like you do with every other view.

Return the drag operation (move, copy, etc) that should be performed if a registered drag type is over the tableview
        The data source can retarget a drop if you want by calling <pre>-(void)setDropRow:(CPInteger)aRow dropOperation:(CPTableViewDropOperation)anOperation;</pre>
    @code
- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(CPDraggingInfo)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)operation;
    @endcode

Returns YES if the drop operation is allowed otherwise NO. This method is invoked by the tableview after a drag should begin, but before it is started. If you don't want the drag to being return NO. If you want the drag to begin you should return YES and place the drag data on the pboard.
    @code
- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard;
    @endcode

Return YES if the operation was successful otherwise return NO. The data source should incorporate the data from the dragging pasteboard in this method implementation. To get this data use the draggingPasteboard method on the CPDraggingInfo object.
    @code
- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(CPDraggingInfo)info row:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation;
    @endcode

NOT YET IMPLEMENTED
    @code
- (CPArray)tableView:(CPTableView)aTableView namesOfPromisedFilesDroppedAtDestination:(CPURL)dropDestination forDraggedRowsWithIndexes:(CPIndexSet)indexSet;
    @endcode
*/
- (void)setDataSource:(id <CPTableViewDataSource>)aDataSource
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

    [self _reloadDataViews];
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
    Reloads the data for visible data views.
*/
- (void)reloadData
{
    [self _reloadDataViews];
}

/*!
    Reloads the data for only the specified rows and columns.
    @param rowIndexes The indexes of the rows to update.
    @param columnIndexes The indexes of the columns to update.
*/
- (void)reloadDataForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self reloadData];
}

// Reloads the data, not the views
- (void)_reloadDataForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self _enumerateViewsInRows:rowIndexes columns:columnIndexes usingBlock:function(view, row, column, stop)
    {
        var tableColumn = [_tableColumns objectAtIndex:column];
        [self _setObjectValueForTableColumn:tableColumn row:row forView:view useCache:NO];
    }];
}

- (void)_setupReload
{
    _reloadAllRows = YES;
    _objectValues = { };
    _cachedRowHeights = [];

    // Otherwise, if we have a row marked as group with a
    // index greater than the new number or rows
    // it keeps the the graphical group style.
    [_groupRows removeAllIndexes];

    // This updates the size too.
    [self noteNumberOfRowsChanged];
}

// Reloads the views AND the data
- (void)_reloadDataViews
{
    [self _setupReload];
    [self setNeedsLayout];
    // No more manual draw rect
    // [self setNeedsDisplay:YES];
}

// Reloads the views AND the data
- (void)_reloadDataViewsSynchronously
{
    [self _setupReload];
    [self layout];
    [self display];
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

    [_headerView setNeedsDisplay:YES];
    [_headerView setNeedsLayout];

    [self _reloadDataViews];
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
    [self _updateAllVisibleRowViews];
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
    [self _updateAllVisibleRowViews];
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
    As in AppKit, the source-list style also sets the background colour to the source-list
    background colour. A background colour set after the style replaces it.

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

    /*
        The source-list style changed only the dragging feedback style. The table view kept
        its background, so a source list had the background of a plain table, and the
        System catalog's source-list background colour had no reader.
    */
    if (aSelectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList)
    {
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleSourceList;
        [self setBackgroundColor:[CPColor colorWithCatalogName:@"System" colorName:@"_sourceListBackgroundColor"]];
    }
    else
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;

    [self _updateHighlightWithOldRows:[CPIndexSet indexSet] newRows:_selectedRowIndexes];
    [self _updateHighlightWithOldColumns:[CPIndexSet indexSet] newColumns:_selectedColumnIndexes];
    [self _updateAllVisibleRowViews];
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
    [self _updateAllVisibleRowViews];
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
    {
        // Check theme attributes first.
        // This ensures 'unfocused-selection-color' from ThemeDescriptors.j is used.
        _unfocusedSelectionHighlightColor = [self currentValueForThemeAttribute:@"unfocused-selection-color"];

        if (!_unfocusedSelectionHighlightColor)
            _unfocusedSelectionHighlightColor = [self _unfocusedSelectionColorFromColor:[self selectionHighlightColor] saturation:0];
    }

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

- (CPColor)unfocusedSelectionGradientColors
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
    [self _updateAllVisibleRowViews];
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
    [self _updateAllVisibleRowViews];
}

/*!
    Returns a grid mask
*/
- (unsigned)gridStyleMask
{
    return _gridStyleMask;
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

/*!
    @ignore
*/
- (void)_recalculateTableColumnRanges
{
    // Complexity:
    // O(Columns)

    if (_dirtyTableColumnRangeIndex < 0)
        return;

    _numberOfHiddenColumns = 0;

    var index = _dirtyTableColumnRangeIndex,
        count = [self _numberOfColumns],
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

/*!
    Returns a CGRect with the location and size of the column
    If aColumnIndex lies outside the range of the table columns a CGZeroRect is returned

    @param aColumnIndex the index of the column to return the rect of
*/
- (CGRect)rectOfColumn:(CPInteger)aColumnIndex
{
    // Complexity:
    // O(1)

    // Coerce aColumnIndex to a number in case it is a string.
    aColumnIndex = +aColumnIndex;

    if (aColumnIndex < 0 || aColumnIndex >= [self _numberOfColumns])
        return CGRectMakeZero();

    if ([[_tableColumns objectAtIndex:aColumnIndex] isHidden])
        return CGRectMakeZero();

    [self _updateColumnRangesIfNecessary];

    var range = _tableColumnRanges[aColumnIndex];

    return CGRectMake(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}

/*!
    @ignore
    Returns a CGRect with the location and size of the row

    @param aRowIndex the index of the row to return the rect of
    @param checkRange if YES this method will return a zero rect if aRowIndex is outside of the range of valid indices
*/
- (CGRect)_rectOfRow:(CPInteger)aRowIndex checkRange:(BOOL)checkRange
{
    // Complexity:
    // O(1)

    var lastIndex = [self numberOfRows] - 1,
        validIndex = aRowIndex >= 0 && aRowIndex <= lastIndex;

    if (checkRange && !validIndex)
        return CGRectMakeZero();

    var y = 0,
        height,
        fixedHeightRows = 0;

    if ([self _hasVariableRowHeights])
    {
        [self _populateRowHeightCacheIfNeeded];

        // If the index is valid, we use the y and height of the given row.
        // If the index is invalid, we start from the bottom of the last row and use the default row height.
        var heightInfo;

        if (validIndex)
        {
            heightInfo = _cachedRowHeights[aRowIndex];
            y = heightInfo.y;
            height = heightInfo.height + _intercellSpacing.height;
        }
        else
        {
            height = [self _fullRowHeight];

            if (_numberOfRows > 0)
            {
                heightInfo = _cachedRowHeights[lastIndex];
                y = [self _rowBottomOfHeightInfo:heightInfo];

                // y is now at the top of the first row beyond the last valid row.
                // Add the height of any rows beyond that.
                fixedHeightRows = aRowIndex - _numberOfRows;
            }
        }
    }
    else
    {
        fixedHeightRows = aRowIndex;
        height = [self _fullRowHeight];
    }

    y += fixedHeightRows * [self _fullRowHeight];

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
- (void)tableView:(CPTableView)aTableView willDisplayView:(id)aView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)rowIndex;
@endcode

Group rows are a way to separate a groups of data in a tableview. Return YES if the given row is a group row, otherwise NO.
@code
- (BOOL)tableView:(CPTableView)tableView isGroupRow:(CPInteger)row;
@endcode


@section editingcells Editing Cells:

Return YES if the dataview at a given index and column should be edited, otherwise NO.
@code
- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)rowIndex;
@endcode


@section sizes Setting Row and Column Size:

Return the height of the row at a given index. Only implement this if you want variable row heights. Otherwise use setRowHeight: on the tableview.
@code
- (float)tableView:(CPTableView)tableView heightOfRow:(CPInteger)row;
@endcode


@section selection Selecting in the TableView:
@note These methods are only called when the user does something.@endnote

Return YES if the selection of the tableview should change, otherwise NO to keep the current selection.
@code
- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView;
@endcode

Return YES if the row at a given index should be selected, other NO to deny the selection.
@code
- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(CPInteger)rowIndex;
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
- (BOOL)tableView:(CPTableView)tableView shouldReorderColumn:(CPInteger)columnIndex toColumn:(CPInteger)newColumnIndex;
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
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow;
@endcode


@section deletekey Delete Key
Called when the user presses the delete key. Many times you will want to delete data (or prompt for deletion) when the user presses the delete key.
Your delegate can implement this method to avoid subclassing the tableview to add this behaviour.

@code
- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView;
@endcode
*/
- (void)setDelegate:(id <CPTableViewDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

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

    if ([_delegate respondsToSelector:@selector(tableView:willRemoveView:forTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_willRemoveView_forTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:menuForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewMenuForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldReorderColumn:toColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_;

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewColumnDidMove_;

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewColumnDidResize_;

    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewSelectionDidChange_;

    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableViewSelectionIsChanging_;
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
- (void)_didClickTableColumn:(CPInteger)clickedColumn modifierFlags:(unsigned)modifierFlags
{
    [self _changeSortDescriptorsForClickOnColumn:clickedColumn];

    if (_allowsColumnSelection)
    {
        if ([self _sendDelegateSelectionShouldChangeInTableView] && [self _sendDelegateShouldSelectTableColumn:clickedColumn])
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

    [self _sendDelegateDidClickTableColumn:clickedColumn];
}

// From GNUSTEP
/*!
    @ignore
*/

- (void)_changeSortDescriptorsForClickOnColumn:(CPInteger)column
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

    if (sortDescriptors != nil)
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

/*!
    @ignore
*/
- (id)_objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex useCache:(BOOL)useCache
{
    var objectValue;

    var tableColumnUID = [aTableColumn UID],
        tableColumnObjectValues = _objectValues[tableColumnUID];

    if (!tableColumnObjectValues)
    {
        tableColumnObjectValues = [];
        _objectValues[tableColumnUID] = tableColumnObjectValues;
    }

    if (useCache)
        objectValue = tableColumnObjectValues[aRowIndex];

    // tableView:objectValueForTableColumn:row: is optional if content bindings are in place.
    if (objectValue == nil)
    {
        if ([self _dataSourceRespondsToObjectValueForTableColumn])
        {
            objectValue = [self _sendDataSourceObjectValueForTableColumn:aTableColumn row:aRowIndex];
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
- (void)layoutSubviews
{
    [self _updateDefaultBackgroundColor];
    [self load];
}

/*!
    @ignore
*/
- (void)viewWillMoveToSuperview:(CPView)aView
{
    if ([aView isKindOfClass:[CPClipView class]])
    {
        _observedClipView = aView;
    }
    else
    {
        [self _stopObservingClipView];
        _observedClipView = nil;
    }

    [super viewWillMoveToSuperview:aView];
}

/*!
    @ignore
*/
- (void)superviewBoundsChanged:(CPNotification)aNotification
{
    _exposedRect = nil;

    // No need to setNeedsDisplay for canvas
    // [self setNeedsDisplay:YES];
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
@end
