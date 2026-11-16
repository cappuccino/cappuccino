/*
 * CPTableView+Editing.j
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


@implementation CPTableView (Editing)


- (void)_resignFirstResponderWithoutSendingAction:(CPView)aView
{
    var action = [self _disableActionIfExists:aView];

    [[self window] makeFirstResponder:self];

    if (action)
        [aView setAction:action];
}

- (void)_resignEditedView
{
    var view = [[self window] firstResponder];

    if ([view respondsToSelector:@selector(selectText:)])
        [view selectText:nil];

    if (!_isViewBased)
    {
        [self _unregisterForEndEditingNote:view];
        [self _setEditingState:NO forView:view];
    }

    [self _resignFirstResponderWithoutSendingAction:view];
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
    The action for any dataview that supports editing. This will only be called when the value was changed.
    The table view becomes the first responder after user is done editing a dataview.
*/
- (void)_commitDataViewObjectValue:(id)aDataView forColumn:(CPInteger)column andRow:(CPInteger)row
{
    var editingTableColumn = _tableColumns[column];

    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        [_dataSource tableView:self setObjectValue:[aDataView objectValue] forTableColumn:editingTableColumn row:row];

    // Allow the column binding to do a reverse set. Note that we do this even if the data source method above
    // is implemented.
    [editingTableColumn _reverseSetDataView:aDataView forRow:row];

    if (row !== CPNotFound && column !== CPNotFound)
        [self _reloadDataForRowIndexes:[CPIndexSet indexSetWithIndex:row] columnIndexes:[CPIndexSet indexSetWithIndex:column]];
}

- (void)_setEditingState:(BOOL)editingState forView:(CPView)aView
{
    if ([aView respondsToSelector:@selector(setEditable:)])
        [aView setEditable:editingState];

    if ([aView respondsToSelector:@selector(setSelectable:)])
        [aView setSelectable:editingState];

    if ([aView isKindOfClass:[CPTextField class]])
        [aView setBezeled:editingState];
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
    if (![self isRowSelected:rowIndex])
        [[CPException exceptionWithName:@"Error" reason:@"Attempt to edit row " + rowIndex + " when not selected." userInfo:nil] raise];

    [self _reloadDataViewsSynchronously];
    [self scrollRowToVisible:rowIndex];
    [self scrollColumnToVisible:columnIndex];

    // Force layout to update exposed rows/views after scrolling
    // This prevents the view from being unloaded/reloaded during the makeFirstResponder call
    [self layoutIfNeeded];

    // TODO Do something with flag.

    _editingRow = rowIndex;
    _editingColumn = columnIndex;

    var editingTableColumnUID = [_tableColumns[_editingColumn] UID],
        editingView = _dataViewsForRows[_editingRow][editingTableColumnUID];

    [self _setEditingState:YES forView:editingView];
    [[self window] makeFirstResponder:editingView];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    if (context === "editing" && [object superview] === self)
    {
        [object removeObserver:self forKeyPath:keyPath];

        var row,
            column;

        [self getColumn:@ref(column) row:@ref(row) forView:object];
        [self _commitDataViewObjectValue:object forColumn:column andRow:row];
    }
}

/*!
    Returns the column of the currently edited cell, or CPNotFound if none.
*/
- (CPInteger)editedColumn
{
    return _editingColumn;
}

/*!
    Returns the row of the currently edited cell, or CPNotFound if none.
*/
- (CPInteger)editedRow
{
    return _editingRow;
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
    if (![self _sendDelegateSelectionShouldChangeInTableView])
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

    if ([self _delegateRespondsToSelectionIndexesForProposedSelection] || [self _delegateRespondsToShouldSelectRow])
    {
        var shouldSelect = !![[self _cleanUpSelectionRowIndexes:[CPIndexSet indexSetWithIndex:i]] count];

        /* If shouldSelect returns NO it means this row cannot be selected.
            The proper behaviour is to then try to see if the next/previous
            row(s) can be selected, until we hit the first one that can be.
        */
        while (!shouldSelect && (i < [self numberOfRows] && i > 0))
        {
            shouldGoUpward ? --i : ++i; //check to see if the row can be selected. If it can't be then see if the next row can be selected.
            shouldSelect = !![[self _cleanUpSelectionRowIndexes:[CPIndexSet indexSetWithIndex:i]] count];
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

    selectedIndexes = [self _sendDelegateSelectionIndexesForProposedSelection:selectedIndexes];

    [self selectRowIndexes:selectedIndexes byExtendingSelection:extend];

    // we differ because selectRowIndexes: does its own thing which would set the wrong index
    _lastSelectedRow = differedLastSelectedRow;

    if (i !== CPNotFound)
        [self scrollRowToVisible:i];
}

- (void)_updateDataViewsFocusState
{
    var isFocused = [self _isFocused];

    // enumerateAvailableViewsUsingBlock calls [self reloadData], which is destructive
    // during a focus change (causes editing session to reset).
    [self _enumerateViewsInRows:_exposedRows columns:_exposedColumns usingBlock:function(view, row, column, stop)
    {
        // Only selected rows need to toggle between White and Black text
        if ([self isRowSelected:row] || [self isColumnSelected:column])
        {
            if (isFocused)
                [view setThemeState:CPThemeStateFirstResponder];
            else
                [view unsetThemeState:CPThemeStateFirstResponder];
        }
    }];
}

@end
