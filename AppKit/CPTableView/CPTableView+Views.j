/*
 * CPTableView+Views.j
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

@import "CPTableViewCore.j"


@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView
@class CPTableContentBinder


@implementation CPTableView (Views)


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
        exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self _exposedRowsInRect:exposedRect]],
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

    // Remove old draw view call
    // [_tableDrawView setFrame:exposedRect];

    // [self setNeedsDisplay:YES]; // Not needed for structure changes

    // if we have any columns to remove do that here

    if (_needsDifferedTableColumnRemove)
    {
        var removeCount = [_differedColumnDataToRemove count],
            removeIndexes = [CPIndexSet indexSet];

        for (var i = 0; i < removeCount; i++)
        {
            var data = _differedColumnDataToRemove[i],
                tableColumn = data.column,
                columnIdx = [_tableColumns indexOfObject:tableColumn];

            if (columnIdx !== CPNotFound)
                [removeIndexes addIndex:columnIdx];
        }

        if ([removeIndexes count] > 0)
        {
            var rowIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])];
            [self _unloadDataViewsInRows:rowIndexes columns:removeIndexes];

            [_tableColumns removeObjectsAtIndexes:removeIndexes];

            _dirtyTableColumnRangeIndex = 0;
            [self _recalculateTableColumnRanges];

            // Shift cached index sets downwards to account for the removed columns
            var shiftIndexSet = function(indexSet)
            {
                var newSet = [CPIndexSet indexSet];
                [indexSet enumerateIndexesUsingBlock:function(idx, stop)
                {
                    if (![removeIndexes containsIndex:idx])
                    {
                        var shift = 0,
                            remIdx = [removeIndexes firstIndex];

                        while (remIdx !== CPNotFound && remIdx < idx)
                        {
                            shift++;
                            remIdx = [removeIndexes indexGreaterThanIndex:remIdx];
                        }

                        [newSet addIndex:idx - shift];
                    }
                }];
                return newSet;
            };

            _exposedColumns = shiftIndexSet(_exposedColumns);
            _selectedColumnIndexes = shiftIndexSet(_selectedColumnIndexes);

            // Shift individual index variables
            var shiftIndex = function(idx)
            {
                if (idx === CPNotFound || idx === -1)
                    return idx;
                
                if ([removeIndexes containsIndex:idx])
                    return CPNotFound;
                
                var shift = 0,
                    remIdx = [removeIndexes firstIndex];

                while (remIdx !== CPNotFound && remIdx < idx)
                {
                    shift++;
                    remIdx = [removeIndexes indexGreaterThanIndex:remIdx];
                }

                return idx - shift;
            };

            _editingColumn = shiftIndex(_editingColumn);
            
            _draggedColumnIndex = shiftIndex(_draggedColumnIndex);
            if (_draggedColumnIndex === CPNotFound)
                _draggedColumnIndex = -1;
                
            _clickedColumn = shiftIndex(_clickedColumn);
            if (_clickedColumn === CPNotFound)
                _clickedColumn = -1;
        }

        [_differedColumnDataToRemove removeAllObjects];
        _needsDifferedTableColumnRemove = NO;
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
- (void)_unloadDataViewsInRows:(CPIndexSet)rowIndexes columns:(CPIndexSet)columnIndexes
{
    // Recycle Row Views
    [rowIndexes enumerateIndexesUsingBlock:function(rowIndex, stop) {
        var rowView = _visibleRowViews[rowIndex];

        if (rowView)
        {
             [rowView removeFromSuperview];
             _cachedRowViews.push(rowView);
             delete _visibleRowViews[rowIndex];
        }
    }];

    if (![rowIndexes count] || ![columnIndexes count] || [columnIndexes lastIndex] >=  [_tableColumns count])
        return;

    // If and edited view is about to be unloaded, cleanup its state before enqueuing.
    if ([columnIndexes containsIndex:_editingColumn] && [rowIndexes containsIndex:_editingRow])
        [self _resignEditedView];

    var tableColumns = [_tableColumns objectsAtIndexes:columnIndexes];

    [self _enumerateViewsInRows:rowIndexes tableColumns:tableColumns usingBlock:function(dataView, row, tableColumn, stop)
    {
        var dataViewsForRows = _dataViewsForRows[row],
            tableColumnUID = [tableColumn UID];

        delete (dataViewsForRows[tableColumnUID]);

        [self _sendDelegateWillRemoveView:dataView forTableColumn:tableColumn row:row];
        [self _enqueueReusableDataView:dataView];
    }];
}

/*!
    @ignore
*/
- (void)_loadDataViewsInRows:(CPIndexSet)rowIndexes columns:(CPIndexSet)columnIndexes
{
    // Load Row Views
    var focused = [self _isFocused],
        visibleWidth = MAX([self bounds].size.width, CGRectGetWidth([self exposedRect])),
        delegateRespondsToGroupRow = (_implementedDelegateMethods & CPTableViewDelegate_tableView_isGroupRow_);

    [rowIndexes enumerateIndexesUsingBlock:function(rowIndex, stop) {
        
        var isGroupRow = delegateRespondsToGroupRow && [_delegate tableView:self isGroupRow:rowIndex];

        if (!_visibleRowViews[rowIndex])
        {
            var rowView = [self _dequeueRowView];
            if (!rowView)
                rowView = [[_CPTableRowView alloc] initWithTableView:self];

            [rowView setIsGroupRow:isGroupRow];
            [rowView setRowIndex:rowIndex];
            [rowView setSelected:[self isRowSelected:rowIndex] focused:focused];

            // Set frame to span the entire width
            var rowRect = [self _rectOfRow:rowIndex checkRange:NO];
            rowRect.size.width = visibleWidth;
            rowRect.origin.x = 0;

            [rowView setFrame:rowRect];

            // Add behind data views
            [self addSubview:rowView positioned:CPWindowBelow relativeTo:nil];
            _visibleRowViews[rowIndex] = rowView;
        }
        else
        {
            // Update state of existing view
            [_visibleRowViews[rowIndex] setIsGroupRow:isGroupRow];
        }
    }];

    if (![rowIndexes count] || ![columnIndexes count])
        return;

    [self _updateColumnRangesIfNecessary];

    if (_numberOfHiddenColumns > 0)
        columnIndexes = [columnIndexes indexesPassingTest:function(idx, stop)
        {
            return ![_tableColumns[idx] isHidden];
        }];

    [rowIndexes enumerateIndexesUsingBlock:function(rowIndex, stopRow)
    {

        if (rowIndex >= [self numberOfRows])
            return;

        if (!_dataViewsForRows[rowIndex])
            _dataViewsForRows[rowIndex] = {};

        var dataViewsForRow = _dataViewsForRows[rowIndex],
            isRowSelected = [self isRowSelected:rowIndex],
            row = rowIndex;

        // Note: Even for group rows, we iterate all columns to render their data.
        // The background styling is handled by the _CPTableRowView above.
        [columnIndexes enumerateIndexesUsingBlock:function(columnIndex, stopCol)
        {
            var tableColumn = _tableColumns[columnIndex],
                tableColumnUID = [tableColumn UID],
                dataView = [self _preparedViewAtColumn:columnIndex row:row isRowSelected:isRowSelected];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            if (focused && (isRowSelected || [self isColumnSelected:columnIndex]))
                [dataView setThemeState:CPThemeStateFirstResponder];

            dataViewsForRow[tableColumnUID] = dataView;
        }];
    }];
}

- (CPView)_dequeueRowView
{
    if (_cachedRowViews.length > 0)
        return _cachedRowViews.pop();
    return nil;
}

- (void)_updateAllVisibleRowViews
{
    var focused = [self _isFocused];
    for (var idx in _visibleRowViews)
    {
        if (_visibleRowViews.hasOwnProperty(idx))
            [_visibleRowViews[idx] setSelected:[self isRowSelected:+idx] focused:focused];
    }
}

- (void)_updateAllVisibleRowViewsFrames
{
    var visibleWidth = MAX([self bounds].size.width, CGRectGetWidth([self exposedRect]));
    for (var idx in _visibleRowViews)
    {
        if (_visibleRowViews.hasOwnProperty(idx))
        {
             var rowView = _visibleRowViews[idx],
                 rect = [rowView frame];
             rect.size.width = visibleWidth;
             [rowView setFrame:rect];
        }
    }
}

- (CPView)preparedViewAtColumn:(CPInteger)column row:(CPInteger)row
{
    return [self _preparedViewAtColumn:column row:row isRowSelected:[self isRowSelected:row]];
}

- (CPView)_preparedViewAtColumn:(CPInteger)column row:(CPInteger)row isRowSelected:(BOOL)isRowSelected
{
    var tableColumn = _tableColumns[column],
        tableColumnUID = [tableColumn UID],
        dataView = [self _newDataViewForRow:row tableColumn:tableColumn];

    [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];

    [self _setObjectValueForTableColumn:tableColumn row:row forView:dataView];

    if (_selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone && (isRowSelected || [self isColumnSelected:column]))
    {
        _BlockSelectView(dataView, row, column);

        if ([self _isFocused])
            [dataView setThemeState:CPThemeStateFirstResponder];
        else
            [dataView unsetThemeState:CPThemeStateFirstResponder];
    }
    else
    {
        _BlockDeselectView(dataView, row, column);
        // Ensure we clear this state if a view is reused
        [dataView unsetThemeState:CPThemeStateFirstResponder]; 
    }
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

    if (!_isViewBased)
    {
        // We use the 'row' and 'column' arguments here to check against the instance variables
        var isEditing = (row === _editingRow && column === _editingColumn);
        [self _setEditingState:isEditing forView:dataView];
    }

    [self _sendDelegateWillDisplayView:dataView forTableColumn:tableColumn row:row];
    [self _applyToolTipToDataView:dataView forTableColumn:tableColumn row:row];

    return dataView;
}

- (void)_applyToolTipToDataView:(CPView)aDataView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    var tooltip = nil;

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_)
        tooltip = [self _sendDelegateToolTipForView:aDataView rect:[aDataView frame] tableColumn:aTableColumn row:aRow mouseLocation:CGPointMakeZero()];

    [aDataView setToolTip:tooltip];
}

- (void)_setObjectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow forView:(CPView)aDataView
{
    [self _setObjectValueForTableColumn:aTableColumn row:aRow forView:aDataView useCache:!_invalidateObjectValuesCache];
}

- (void)_setObjectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow forView:(CPView)aDataView useCache:(BOOL)useCache
{
    var providedByDataSource = NO;

    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_)
    {
        var objectValue = [self _objectValueForTableColumn:aTableColumn row:aRow useCache:useCache];
        [aDataView setObjectValue:objectValue];
        providedByDataSource = YES;
    }

    // This gives the table column an opportunity to apply its bindings.
    // It will override the value set above if there is an explicit column binding.
    var columnHasBindings = [[[CPBinder allBindingsForObject:aTableColumn] allKeys] count] > 0;

    if (columnHasBindings)
    {
        [aTableColumn _prepareDataView:aDataView forRow:aRow];
    }
    // Only forcefully bind the raw content object if the data source didn't already provide a formatted value
    else if (_contentBindingExplicitlySet && !providedByDataSource)
    {
        [self _prepareContentBindedDataView:aDataView forRow:aRow];
    }
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
- (void)_layoutViewsForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self _enumerateViewsInRows:rowIndexes columns:columnIndexes usingBlock:function(view, row, column, stop)
    {
        [view setFrame:[self frameOfDataViewAtColumn:column row:row]];
    }];

    // Also layout row views if needed (usually handled by resize)
    var visibleWidth = MAX([self bounds].size.width, CGRectGetWidth([self exposedRect]));
    [rowIndexes enumerateIndexesUsingBlock:function(row, stop) {
        if (_visibleRowViews[row])
        {
             var rect = [self _rectOfRow:row checkRange:NO];
             rect.size.width = visibleWidth;
             rect.origin.x = 0;
             [_visibleRowViews[row] setFrame:rect];
        }
    }];
}

/*!
    @ignore
*/
- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    var view = nil;

    if (_viewForTableColumnRowSelector)
        view = self.isa.objj_msgSend2(self, _viewForTableColumnRowSelector, aTableColumn, aRow);

    if (!view)
    {
        // For cell-based tables, use the dataView prototype identifier as view identifier
        // instead of column identifier because 1/ the column identifier may be nil
        // and 2/ the tableColumn dataView may change after the column identifier was set.
        var identifier;

        if (_isViewBased)
        {
            identifier = [aTableColumn identifier];
            view = [self makeViewWithIdentifier:identifier owner:_delegate];
        }
        else
        {
            identifier = [[aTableColumn dataView] UID];
            view = [self makeViewWithIdentifier:identifier owner:_delegate];

            if (!view)
                view = [aTableColumn _newDataView];
        }

        [view setIdentifier:identifier];
    }

    return view;
}

/*
    Returns a view with the specified identifier.

    @param identifier The view identifier. Must not be nil.
    @param owner The owner of the CIB that may be loaded and instantiated to create a new view with the particular identifier.
    @return A view for the row.

    @discussion
    Typically identifier is associated with an external CIB and the table view will automatically instantiate the CIB with the provided owner. The owner of the CIB that may be loaded and instantiated to create a new view with the particular identifier is typically the table view’s delegate. The owner is useful in setting up outlets and target and actions from the view.

    This method will typically be called by the delegate in tableView:viewForTableColumn:row:, but it can also be overridden to provide custom views for the identifier. This method may also return a reused view with the same identifier that was no longer available on screen.
*/
- (id)makeViewWithIdentifier:(CPString)anIdentifier owner:(id)anOwner
{
    if (!anIdentifier)
        return nil;

    var view = nil,
        // See if we have some reusable views available
        reusableViews = _cachedDataViews[anIdentifier];

    if (reusableViews && reusableViews.length)
        view = reusableViews.pop();
    // Otherwise see if we have a view in the cib with this identifier
    else if (_isViewBased)
        view = [self _unarchiveViewWithIdentifier:anIdentifier owner:anOwner];

    return view;
}

/*!
    Returns an instance of CPView

    @param column The index of the column in the tableColumn array
    @param row The index of the row
    @param makeIfNecessary YES if a view is required, NO if you want to update properties on a view, if one is available.

    @discussion
    This method first attempts to return an available view, which is generally in the visible area. If there is no available view, and makeIfNecessary is YES, a prepared temporary view is returned. If makeIfNecessary is NO, and the view is not available, nil will be returned.

    An exception will be thrown if row is an invalid row index and if column is an invalid column index
*/
- (id)viewAtColumn:(CPInteger)column row:(CPInteger)row makeIfNecessary:(BOOL)makeIfNecessary
{
    if (row > (_numberOfRows - 1))
        [CPException raise:CPInvalidArgumentException
                    reason:@"Row " + row + " out of row range [0-" + (_numberOfRows - 1) + "] for rowViewAtRow:createIfNeeded:"];

    if (column > ([self _numberOfColumns] - 1))
        [CPException raise:CPInvalidArgumentException
                    reason:@"Column " + column + " out of row range [0-" + ([self _numberOfColumns]- 1) + "] for rowViewAtRow:createIfNeeded:"];

    var dataViewsForRow = _dataViewsForRows[row],
        tableColumn = _tableColumns[column],
        tableColumnUID = [tableColumn UID],
        view = dataViewsForRow ? dataViewsForRow[tableColumnUID] : nil;

    if (!makeIfNecessary)
        return view || nil;

    if (!view)
    {
        if (!dataViewsForRow)
        {
            dataViewsForRow = {};
            _dataViewsForRows[row] = dataViewsForRow;
        }

        // Here we will add this view to the tableView and add it to the exposedRows adn columns.
        // The view will be deleted if necessary during the next run loop cycle of the table view
        // This is how cocoa works
        view = [self preparedViewAtColumn:column row:row];

        if ([view superview] !== self)
            [self addSubview:view];

        dataViewsForRow[tableColumnUID] = view;

        [_exposedRows addIndex:row];
        [_exposedColumns addIndex:column];

        // Make sure to layout the tableView again
        [self setNeedsLayout];
    }

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
        _viewForTableColumnRowSelector = @selector(_sendDelegateViewForTableColumn:row:);
    else if ([self _delegateRespondsToDataViewForTableColumn])
        _viewForTableColumnRowSelector = @selector(_sendDelegateDataViewForTableColumn:row:);

     _isViewBased = (_viewForTableColumnRowSelector != nil || _archivedDataViews != nil);
}

/*!
    Allows the enumeration of all the table views that are known to the table view.

    @param handler The function to apply to elements in the set.

    The function takes three arguments:

    @param dataView
    The view for the column and row.
    @param column
    The column index of the view.
    @param row
    The row index of the view.
*/

- (void)enumerateAvailableViewsUsingBlock:(Function/*CPView *dataView, CPInteger row, CPInteger column*, @ref stop*/)handler
{
    [self reloadData];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self _enumerateViewsInRows:_exposedRows columns:_exposedColumns usingBlock:handler];
}

/*!
    @ignore
*/

- (void)_enumerateViewsInRows:(CPIndexSet)rowIndexes columns:(CPIndexSet)columnIndexes usingBlock:(Function/*CPView dataView, CPInteger row, CPInteger column, @ref stop*/)handler
{
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [rowIndexes enumerateIndexesUsingBlock:function(rowIndex, stopRow)
    {
        var dataViewsForRow = _dataViewsForRows[rowIndex];

        if (!dataViewsForRow)
            return;

        var row = rowIndex;

        [columnIndexes enumerateIndexesUsingBlock:function(columnIndex, stopCol)
        {
            var tableColumnUID = [_tableColumns[columnIndex] UID],
                view = dataViewsForRow[tableColumnUID];

            if (view)
                handler(view, row, columnIndex, stopCol);

            if (stopCol())
                stopRow(YES);
        }];
    }];
}

- (void)_enumerateViewsInRows:(CPIndexSet)rowIndexes tableColumns:(CPArray)tableColumns usingBlock:(Function/*CPView dataView, CPInteger row, CPtableColumn tableColumn, CPInteger column, @ref stop*/)handler
{
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [rowIndexes enumerateIndexesUsingBlock:function(rowIndex, stopRow)
    {
        var dataViewsForRow = _dataViewsForRows[rowIndex];

        if (!dataViewsForRow)
            return;

        var row = rowIndex;

        [tableColumns enumerateObjectsUsingBlock:function(tableColumn, idx, stopCol)
        {
            var tableColumnUID = [tableColumn UID],
                view = dataViewsForRow[tableColumnUID];

            if (view)
                handler(view, row, tableColumn, stopCol);

            if (stopCol())
                stopRow(YES);
        }];
    }];
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

    if ([aDataView hasThemeState:CPThemeStateSelectedDataView])
        [aDataView unsetThemeState:CPThemeStateSelectedDataView];

    if (!_cachedDataViews[identifier])
        _cachedDataViews[identifier] = [aDataView];
    else
        _cachedDataViews[identifier].push(aDataView);
}

@end
