@import <AppKit/CPControl.j>

var CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2  

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


@implementation NEWCPTableView : CPControl
{
    id          _dataSource;
    unsigned    _implementedDataSourceMethods;
    CPArray     _tableColumns;

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
    unsigned    _numberOfColumns;

}

- (void)_init
{
    //Configuring Behavior
    _allowsColumnReordering = YES;
    _allowsColumnResizing = YES;
    _allowsMultipleSelection = NO;
    _allowsEmptySelection = YES;
    _allowsColumnSelection = NO;
    
    //Setting Display Attributes
    _selectionHighlightMask = CPTableViewSelectionHighlightStyleRegular;
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
                reason:[aDataSource description] " does not implement numberOfRowsInTableView:."];

    if (![_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] " does not implement tableView:objectValueForTableColumn:row:"];

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
}

- (id)dataSource
{
    return _dataSource;
}

//Loading Data

    * Ð reloadData

//Target-action Behavior

    * Ð setDoubleAction:
    * Ð doubleAction
    * Ð clickedColumn
    * Ð clickedRow

//Configuring Behavior

Ð (void)setAllowsColumnReordering:(BOOL)allowsColumnReordering
{
    _allowsColumnReordering = allowsColumnReordering;
}

Ð (BOOL)allowsColumnReordering
{
    return _allowsColumnReordering;
}

Ð (void)setAllowsColumnResizing:(BOOL)allowsColumnResizing
{
    _allowsColumnResizing = allowsColumnResizing;
}

Ð (BOOL)allowsColumnResizing
{
    return _allowsColumnResizing;
}

Ð (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _allowsMultipleSelection = allowsMultipleSelection;
}


Ð (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

Ð (void)setAllowsEmptySelection:(BOOL)allowsEmptySelection
{
    _allowsEmptySelection = allowsEmptySelection;
}

Ð (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

Ð (void)setAllowsColumnSelection:(BOOL)allowsColumnSelection
{
    _allowsColumnSelection = allowsColumnSelection;
}

Ð (BOOL)allowsColumnSelection
{
    return allowsColumnSelection;
}

//Setting Display Attributes

Ð (void)setIntercellSpacing:(CGSize)aSize
{
    if (_intercellSpacing.width != aSize.width)
    {
        var i = 1,
            delta = aSize.width - _intercellSpacing.width;
            total = delta;
        
        for (; i < _tableColumns.length; ++i, total += delta)
        {
            var origin = [_tableColumnViews[i] frame].origin;
            [_tableColumnViews[i] setFrameOrigin:CGPointMake(origin.x + total, origin.y)];
        }
    }

    if (_intercellSpacing.height != aSize.height)
    {
        var i = 0;
        
        for (; i < _tableColumns.length; ++i, total += delta)
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

    _intercellSpacing = _CGSizeCreateCopy(aSize);
}

Ð (CPSize)intercellSpacing
{
    return _intercellSpacing;
}


Ð (void)setRowHeight:(unsigned)aRowHeight
{
    if (_rowHeight == aRowHeight)
        return;
    
    _rowHeight = aRowHeight;
}

- (unsigned)rowHeight
{
    return _rowHeight;
}



// TODO: confirm: comes from superclass CPView
//Ð setBackgroundColor:
//Ð backgroundColor


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

//Column Management

    * Ð addTableColumn:
    * Ð removeTableColumn:
    * Ð moveColumn:toColumn:
    * Ð tableColumns
    * Ð columnWithIdentifier:
    * Ð tableColumnWithIdentifier:

//Selecting Columns and Rows

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

//Table Dimensions

Ð (int)numberOfColumns
{
    return _numberOfColumns;
}

/*
    Returns the number of rows in the receiver.
*/
Ð (int)numberOfRows
{
    return _numberOfRows;
}

//Displaying Cell

    * Ð tableView:willDisplayCell:forTableColumn:row:  delegate method
    * Ð preparedCellAtColumn:row:
    * Ð tableView:dataCellForTableColumn:row:  delegate method
    * Ð tableView:shouldShowCellExpansionForTableColumn:row:  delegate method
    * Ð tableView:isGroupRow:  delegate method

//Editing Cells

    * Ð editColumn:row:withEvent:select:
    * Ð editedColumn
    * Ð editedRow
    * Ð tableView:shouldEditTableColumn:row:  delegate method

//Setting Auxiliary Views

    * Ð setHeaderView:
    * Ð headerView
    * Ð setCornerView:
    * Ð cornerView

//Layout Support

    * Ð rectOfColumn:
    * Ð rectOfRow:
    * Ð rowsInRect:
    * Ð columnIndexesInRect:
    * Ð columnAtPoint:
    * Ð rowAtPoint:
    * Ð frameOfCellAtColumn:row:
    * Ð columnAutoresizingStyle
    * Ð setColumnAutoresizingStyle:
    * Ð sizeLastColumnToFit
    * Ð noteNumberOfRowsChanged
    * Ð tile
    * Ð sizeToFit
    * Ð noteHeightOfRowsWithIndexesChanged:
    * Ð tableView:heightOfRow:  delegate method
    * Ð columnsInRect: Deprecated in Mac OS X v10.5 

//Drawing

    * Ð drawRow:clipRect:
    * Ð drawGridInClipRect:
    * Ð highlightSelectionInClipRect:
    * Ð drawBackgroundInClipRect:

//Scrolling

    * Ð scrollRowToVisible:
    * Ð scrollColumnToVisible:

//Persistence

    * Ð autosaveName
    * Ð autosaveTableColumns
    * Ð setAutosaveName:
    * Ð setAutosaveTableColumns:

//Selecting in the Tableview

    * Ð selectionShouldChangeInTableView:  delegate method
    * Ð tableView:shouldSelectRow:  delegate method
    * Ð tableView:selectionIndexesForProposedSelection:  delegate method
    * Ð tableView:shouldSelectTableColumn:  delegate method
    * Ð tableViewSelectionIsChanging:  delegate method
    * Ð tableViewSelectionDidChange:  delegate method
    * Ð tableView:shouldTypeSelectForEvent:withCurrentSearchString:  delegate method
    * Ð tableView:typeSelectStringForTableColumn:row:  delegate method
    * Ð tableView:nextTypeSelectMatchFromRow:toRow:forString:  delegate method

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

    if ([_delegate respondsToSelector:@selector(tableView:nextTypeSelectMatchFromRow:toRow:forString:)
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

Ð (CPTableColumn)highlightedTableColumn
{
    
}

    * Ð setHighlightedTableColumn:

//Dragging

    * Ð dragImageForRowsWithIndexes:tableColumns:event:offset:
    * Ð canDragRowsWithIndexes:atPoint:
    * Ð setDraggingSourceOperationMask:forLocal:
    * Ð setDropRow:dropOperation:
    * Ð setVerticalMotionCanBeginDrag:
    * Ð verticalMotionCanBeginDrag

//Sorting

    * Ð setSortDescriptors:
    * Ð sortDescriptors

//Moving and Resizing Columns

    * Ð tableView:didDragTableColumn:  delegate method
    * Ð tableViewColumnDidMove:  delegate method
    * Ð tableViewColumnDidResize:  delegate method

//Responding to Mouse Events

    * Ð tableView:didClickTableColumn:  delegate method
    * Ð tableView:mouseDownInHeaderOfTableColumn:  delegate method
    * Ð tableView:shouldTrackCell:forTableColumn:row:  delegate method

//Text Delegate Methods

    * Ð textShouldBeginEditing:
    * Ð textDidBeginEditing:
    * Ð textDidChange:
    * Ð textShouldEndEditing:
    * Ð textDidEndEditing:

//Displaying Tooltips

    * Ð tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:  delegate method




@end