/*
 * CPTableView+Selection.j
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


@implementation CPTableView (Selection)


//Selecting Columns and Rows

/*!
    Sets the column selection using indexes.

    @param columns a CPIndexSet of columns to select
    @param aFlag should extend the selection thereby retaining the previous selection
*/
- (void)selectColumnIndexes:(CPIndexSet)columns byExtendingSelection:(BOOL)shouldExtendSelection
{
    // If we're out of range, just return
    if (([columns firstIndex] != CPNotFound && [columns firstIndex] < 0) || [columns lastIndex] >= [self numberOfColumns] || (!shouldExtendSelection && [columns isEqualToIndexSet:_selectedColumnIndexes]) || (shouldExtendSelection && [columns count] === 0))
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
    if (([rows isEqualToIndexSet:_selectedRowIndexes] && [_selectedColumnIndexes count] === 0) ||
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
    cleanup a an indexset from the indexes that cannot be selected
    according to the table view delegate.
*/
- (CPIndexSet)_cleanUpSelectionRowIndexes:(CPIndexSet)anIndexSet
{
    if ([self _delegateRespondsToSelectionIndexesForProposedSelection])
    {
        return [self _sendDelegateSelectionIndexesForProposedSelection:anIndexSet];
    }
    else if ([self _delegateRespondsToShouldSelectRow])
    {
        var indexesToRemove = [CPIndexSet new],
            currentIndex = [anIndexSet firstIndex];

        while (currentIndex != CPNotFound)
        {
            if (![self _sendDelegateShouldSelectRow:currentIndex])
                [indexesToRemove addIndex:currentIndex];

            currentIndex = [anIndexSet indexGreaterThanIndex:currentIndex];
        }

        [anIndexSet removeIndexes:indexesToRemove];

        return anIndexSet;
    }
    else
        return anIndexSet;
}

/*!
    @ignore
*/
- (void)_updateHighlightWithOldRows:(CPIndexSet)oldRows newRows:(CPIndexSet)newRows
{
    [self _enumerateViewsInRows:oldRows columns:_exposedColumns usingBlock:_BlockDeselectView];

    if (_selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone)
        [self _enumerateViewsInRows:newRows columns:_exposedColumns usingBlock:_BlockSelectView];

    [self _configureRowViewsForSelectionChangeFromRows:oldRows toRows:newRows];
    [self _markDrawingPassForDisplay];
}

/*!
    @ignore
*/
- (void)_updateHighlightWithOldColumns:(CPIndexSet)oldColumns newColumns:(CPIndexSet)newColumns
{
    var blockDeselectHeader = function(column, stop)
    {
         var headerView = [_tableColumns[column] headerView];
         [headerView unsetThemeState:CPThemeStateSelected];
    };

    var showSelection = _selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone;

    [self _enumerateViewsInRows:_exposedRows columns:oldColumns usingBlock:_BlockDeselectView];
    [oldColumns enumerateIndexesUsingBlock:blockDeselectHeader];

    if (_selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone)
    {
        [self _enumerateViewsInRows:_exposedRows columns:newColumns usingBlock:_BlockSelectView];
        [newColumns enumerateIndexesUsingBlock:function(column, stop)
        {
             var headerView = [_tableColumns[column] headerView];
             [headerView setThemeState:CPThemeStateSelected];
        }];
    }

    // The layout places the column selection views.
    [self setNeedsLayout];
    [self _markDrawingPassForDisplay];
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
        if (![self _sendDelegateSelectionShouldChangeInTableView])
            return;

        if ([[self selectedColumnIndexes] count])
            [self selectColumnIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfColumns])] byExtendingSelection:NO];
        else
        {
            var range = [self _cleanUpSelectionRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])]];
            [self selectRowIndexes:range byExtendingSelection:NO];
        }
    }
}

- (void)deselectAll:(id)sender
{
    if ([self allowsEmptySelection])
    {
        if (![self _sendDelegateSelectionShouldChangeInTableView])
            return;

        [self deselectAll];
    }
}

/*!
    Returns the number of columns in the table
*/
- (int)numberOfColumns
{
    return [self _numberOfColumns];
}

/*!
    Returns the number of rows in the receiver.
*/
- (int)numberOfRows
{
    return _numberOfRows;
}

- (int)_numberOfRows
{
    var numberOfRows,
        contentBindingInfo = [self infoForBinding:@"content"];

    if (contentBindingInfo)
    {
        var destination = [contentBindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [contentBindingInfo objectForKey:CPObservedKeyPathKey];

        numberOfRows = [[destination valueForKeyPath:keyPath] count];
    }
    else if (_dataSource && (_implementedDataSourceMethods & CPTableViewDataSource_numberOfRowsInTableView_))
        numberOfRows = [_dataSource numberOfRowsInTableView:self] || 0;
    else
    {
        if (_dataSource)
                CPLog(@"no content binding established and data source " + [_dataSource description] + " does not implement numberOfRowsInTableView:");
        numberOfRows = 0;
    }

    return numberOfRows;
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

@end
