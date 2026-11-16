/*
 * CPTableView+Delegate.j
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



@implementation CPTableView (TableViewDelegate)

/*!
    @ignore
    Return YES if the delegate implements tableView:dataViewFortableColumn:row:
*/
- (BOOL)_delegateRespondsToDataViewForTableColumn
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_dataViewForTableColumn_row_;
}

/*!
    @ignore
    Return YES if the delegate implements tableView:viewFortableColumn:row:
*/
- (BOOL)_delegateRespondsToViewForTableColumn
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_viewForTableColumn_row_;
}

/*!
    @ignore
    Return YES if the delegate implements tableView:shouldSelectRow:
*/
- (BOOL)_delegateRespondsToShouldSelectRow
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_;
}

/*!
    @ignore
    Return YES if the delegate implements tableView:selectionShouldChangeInTableView
*/
- (BOOL)_delegateRespondsToSelectionShouldChangeInTableView
{
    return _implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_;
}

/*!
    @ignore
    Return YES if the delegate implements tableView:selectionIndexesForProposedSelection
*/
- (BOOL)_delegateRespondsToSelectionIndexesForProposedSelection
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_;
}

/*!
    @ignore
    Return YES if the delegate implements tableView:menuForTableColumn:row
*/
- (BOOL)_delegateRespondsToMenuForTableColumnRow
{
    return _implementedDelegateMethods & CPTableViewDelegate_tableViewMenuForTableColumn_row_;
}

/*!
    @ignore
    Call the delegate didClickTableColumn with the given tableColumn
*/
- (void)_sendDelegateDidClickTableColumn:(CPInteger)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_didClickTableColumn_)
        [_delegate tableView:self didClickTableColumn:_tableColumns[column]];
}

/*!
    @ignore
    Call the delegate didDragTableColumn with the given tableColumn
*/
- (void)_sendDelegateDidDragTableColumn:(CPTableColumn)aTableColumn
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_didDragTableColumn_)
        [_delegate tableView:self didDragTableColumn:aTableColumn];
}

/*!
    @ignore
    Call the delegate mouseDownInHeaderOfTableColumn with the given tableColumn
*/
- (void)_sendDelegateMouseDownInHeaderOfTableColumn:(CPInteger)column
{
    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_)
        [_delegate tableView:self mouseDownInHeaderOfTableColumn:_tableColumns[column]];
}

/*
    @ignore
    Call the delegate tableViewDeleteKeyPressed
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
    Return if the selection should change. By default return YES
*/
- (BOOL)_sendDelegateSelectionShouldChangeInTableView
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_))
        return YES;

    return [_delegate selectionShouldChangeInTableView:self];
}

/*!
    @ignore
    Return if the given row is a group or not. By default return NO.
*/
- (BOOL)_sendDelegateIsGroupRow:(CPInteger)anIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_isGroupRow_))
        return NO;

    return [_delegate tableView:self isGroupRow:anIndex];
}

/*!
    @ignore
    Return is we should select the given row. By Default return YES
*/
- (BOOL)_sendDelegateShouldSelectRow:(CPInteger)anIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_))
        return YES;

    return [_delegate tableView:self shouldSelectRow:anIndex];
}

/*!
    @ignore
    Call the delegate tableView:willDisplayView:forTableColumn:row:
*/
- (void)_sendDelegateWillDisplayView:(id)aCell forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_))
        return;

    [_delegate tableView:self willDisplayView:aCell forTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Call the delegate tableView:willRemoveView:forTableColumn:row:
*/
- (void)_sendDelegateWillRemoveView:(id)aCell forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_willRemoveView_forTableColumn_row_))
        return;

    [_delegate tableView:self willRemoveView:aCell forTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Return a CPMenu for the given tableColumn and row. By default return the menu of super.
*/
- (CPMenu)_sendDelegateMenuForTableColumn:(CPTableColumn)aTableColumn row:aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableViewMenuForTableColumn_row_))
        return nil;

    return [_delegate tableView:self menuForTableColumn:aTableColumn row:aRowIndex];
}

/*
    @ignore
    Returns YES if the column at columnIndex can be reordered.
    It can be possible if column reordering is allowed and if the table view
    delegate also accept the reordering
*/
- (BOOL)_sendDelegateShouldReorderColumn:(CPInteger)columnIndex toColumn:(CPInteger)newColumnIndex
{
    if ([self allowsColumnReordering] &&
        _implementedDelegateMethods & CPTableViewDelegate_tableView_shouldReorderColumn_toColumn_)
    {
        return [_delegate tableView:self shouldReorderColumn:columnIndex toColumn:newColumnIndex];
    }

    return [self allowsColumnReordering];
}

/*!
    @ignore
    Return the height of the given row. By default return [self rowHeight].
*/
- (float)_sendDelegateHeightOfRow:(CPInteger)anIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_))
        return [self rowHeight];

    return [_delegate tableView:self heightOfRow:anIndex];
}

/*!
    @ignore
    Return a boolean to know if we should or not edit the given row. By default return YES.
*/
- (BOOL)_sendDelegateShouldEditTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldEditTableColumn_row_))
        return YES;

    return [_delegate tableView:self shouldEditTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Return a new CPIndexSet instead of the proposedSelection. By default return the proposedSelection.
*/
- (CPIndexSet)_sendDelegateSelectionIndexesForProposedSelection:(CPIndexSet)anIndexSet
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_))
        return anIndexSet;

    return [_delegate tableView:self selectionIndexesForProposedSelection:anIndexSet];
}

/*!
    @ignore
    Return a view for the given tableColumn and row. By default return nil.
*/
- (CPView)_sendDelegateViewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_viewForTableColumn_row_))
        return nil;

    return [_delegate tableView:self viewForTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Return a view for the given tableColumn and row. By default return nil.
*/
- (CPView)_sendDelegateDataViewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_dataViewForTableColumn_row_))
        return nil;

    return [_delegate tableView:self dataViewForTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Return the row view that the delegate gives for the row. By default return nil.
*/
- (CPTableRowView)_sendDelegateRowViewForRow:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_rowViewForRow_))
        return nil;

    return [_delegate tableView:self rowViewForRow:aRowIndex];
}

/*!
    @ignore
    Call the delegate tableView:didAddRowView:forRow:
*/
- (void)_sendDelegateDidAddRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_didAddRowView_forRow_))
        return;

    [_delegate tableView:self didAddRowView:aRowView forRow:aRowIndex];
}

/*!
    @ignore
    Call the delegate tableView:didRemoveRowView:forRow:
*/
- (void)_sendDelegateDidRemoveRowView:(CPTableRowView)aRowView forRow:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_didRemoveRowView_forRow_))
        return;

    [_delegate tableView:self didRemoveRowView:aRowView forRow:aRowIndex];
}


// MARK: -
// MARK: Delegate methods to implement

/*!
    @ignore
    Not yet implemented !
*/
- (BOOL)_sendDelegateShouldSelectTableColumn:(CPTableColumn)aTableColumn
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectTableColumn_))
        return YES;

    return [_delegate tableView:self shouldSelectTableColumn:aTableColumn];
}

/*!
    @ignore
*/
- (CPString)_sendDelegateToolTipForView:(id)aView rect:(CGRect)aRect tableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex mouseLocation:(CGPoint)aPoint
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_))
        return nil;

    return [_delegate tableView:self toolTipForView:aView rect:aRect tableColumn:aTableColumn row:aRowIndex mouseLocation:aPoint];
}

/*!
    @ignore
    Not yet implemented
*/
- (BOOL)_sendDelegateShouldTrackView:(id)aView forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_))
        return YES;

    return [_delegate tableView:self shouldTrackView:aView forTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Not yet implemented
*/
- (BOOL)_sendDelegateShouldShowViewExpansionForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_))
        return YES;

    return [_delegate tableView:self shouldShowViewExpansionForTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Not yet implemented
*/
- (BOOL)_sendDelegateShouldTypeSelectForEvent:(CPEvent)anEvent withCurrentSearchString:(CPString)aString
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_))
        return NO;

    return [_delegate tableView:self shouldTypeSelectForEvent:anEvent withCurrentSearchString:aString];
}

/*!
    @ignore
    Not yet implemented
*/
- (CPString)_sendDelegateTypeSelectStringForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_))
        return nil;

    return [_delegate tableView:self typeSelectStringForTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Not yet implemented !
*/
- (int)_sendDelegateNextTypeSelectMatchFromRow:(CPInteger)aRowIndex toRow:(CPInteger)aSecondRowIndex forString:(CPString)aString
{
    if (!(_implementedDelegateMethods & CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_))
        return -1;

    return [_delegate tableView:self nextTypeSelectMatchFromRow:aRowIndex toRow:aSecondRowIndex forString:aString];
}

@end
