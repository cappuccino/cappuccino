/*
 * CPTableView+DataSource.j
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



@implementation CPTableView (TableViewDataSource)

/*!
    @ignore
    Return YES if the dataSource implements tableView:objectValueForTableColumn:row
*/
- (BOOL)_dataSourceRespondsToObjectValueForTableColumn
{
    return _implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_;
}

/*!
    @ignore
    Return YES if the dataSource implements tableView:writeRowsWithIndexes:toPasteboard:
*/
- (BOOL)_dataSourceRespondsToWriteRowsWithIndexesToPasteboard
{
    return _implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_;
}

/*!
    @ignore
    Return YES if the dataSource implements tableView:setObjectValue:forTableColumn:row:
*/
- (BOOL)_dataSourceRespondsToSetObjectValueForTableColumnRow
{
    return CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_;
}

/*!
    @ignore
    Return YES if the dataSource implements tableView:validateDrop:proposedRow:proposedDropOperation:;
*/
- (BOOL)_dataSourceRespondsToValidateDropProposedRowProposedDropOperation
{
    return _implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_;
}

/*!
    @ignore
    Return YES if the dataSource implements numberOfRowsInTableView
*/
- (BOOL)_dataSourceRespondsToNumberOfRowsinTableView
{
    return _implementedDataSourceMethods & CPTableViewDataSource_numberOfRowsInTableView_;
}

/*!
    @ignore
    Return the number of rows of the tableView
    By default return 0.
*/
- (int)_sendDataSourceNumberOfRowsInTableView
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_numberOfRowsInTableView_))
        return 0;

    return [_dataSource numberOfRowsInTableView:self];
}

/*!
    @ignore
    Return the objectValue for the given column and row.
    By default return nil.
*/
- (id)_sendDataSourceObjectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_objectValueForTableColumn_row_))
        return nil;

    return [_dataSource tableView:self objectValueForTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Call the method tableView:setObjectValue:ForTableColum:row: of the dataSource
*/
- (void)_sendDataSourceSetObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_))
        return;

    [_dataSource tableView:self setObjectValue:anObject forTableColumn:aTableColumn row:aRowIndex];
}

/*!
    @ignore
    Call the method tableView:sortDescriptorsDidChange: of the dataSource
*/
- (void)_sendDataSourceSortDescriptorsDidChange:(CPArray)descriptors
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_sortDescriptorsDidChange_))
        return;

    [_dataSource tableView:self sortDescriptorsDidChange:descriptors];
}

/*!
    @ignore
    Return if the drop is accepted or not for the given dropOperation, info and row. By default return NO.
*/
- (BOOL)_sendDataSourceAcceptDrop:(id)info row:(CPInteger)aRowIndex dropOperation:(CPTableViewDropOperation)operation
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_))
        return NO;

    return [_dataSource tableView:self acceptDrop:info row:aRowIndex dropOperation:operation];
}

/*!
    @ignore
    Return the dragOperation for the given row and dropOperation. By default return CPDragOperationNone.
*/
- (CPDragOperation)_sendDataSourceValidateDrop:(id)info proposedRow:(CPInteger)aRowIndex proposedDropOperation:(CPTableViewDropOperation)operation
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_))
        return CPDragOperationNone;

    return [_dataSource tableView:self validateDrop:info proposedRow:aRowIndex proposedDropOperation:operation];
}

/*!
    @ignore
    Return a boolean for writeRowsWithIndexes:toPasteroard for the given pasteboard and row. By default return NO
*/
- (BOOL)_sendDataSourceWriteRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_))
        return NO;

    return [_dataSource tableView:self writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
}

/*
    This method is sent to the data source for convenience...
*/
- (void)draggedImage:(CPImage)anImage endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    if ([_dataSource respondsToSelector:@selector(tableView:didEndDraggedImage:atPosition:operation:)])
        [_dataSource tableView:self didEndDraggedImage:anImage atPosition:aLocation operation:anOperation];
}


// MARK: -
// MARK: DataSource methods to implement

/*!
    @ignore
    Not yet implemented
*/
- (CPArray)_sendDataSourceNamesOfPromisedFilesDroppedAtDestination:(CPURL)dropDestination forDraggedRowsWithIndexes:(CPIndexSet)indexSet
{
    if (!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_))
        return [];

    return [_dataSource tableView:self namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedRowsWithIndexes:indexSet];
}

@end
