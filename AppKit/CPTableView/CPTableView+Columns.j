/*
 * CPTableView+Columns.j
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


@implementation CPTableView (Columns)


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
        _dirtyTableColumnRangeIndex = [self _numberOfColumns] - 1;
    else
        _dirtyTableColumnRangeIndex = MIN([self _numberOfColumns] - 1, _dirtyTableColumnRangeIndex);

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

    /*
        The load removes the column, at the end of this method. Until then the table view keeps a
        reference to it, for the data views of the column.
    */
    [_differedColumnDataToRemove addObject:{"column":aTableColumn, "shouldBeHidden": [aTableColumn isHidden]}];
    _needsDifferedTableColumnRemove = YES;

    [aTableColumn setHidden:YES];
    [aTableColumn setTableView:nil];

    var tableColumnUID = [aTableColumn UID];

    if (_objectValues[tableColumnUID])
        _objectValues[tableColumnUID] = nil;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = index;
    else
        _dirtyTableColumnRangeIndex = MIN(index, _dirtyTableColumnRangeIndex);

    [self reloadData];

    /*
        The load removes the column, so the reload must be done before this method returns. A
        run loop pass did this, and also ran the timers, the delayed performs and the display
        server at this point. The layout does the load alone.
    */
    [self layoutIfNeeded];
}

/*!
    @ignore
    Internally used to set a column that will be dragged
*/
- (void)_setDraggedColumn:(CPInteger)columnIndex
{
    if (_draggedColumnIndex === columnIndex)
        return;

    // If ending a column drag, reselect the column if it was selected before the drag
    if (columnIndex === -1 && _draggedColumnIsSelected)
        [_selectedColumnIndexes addIndex:_draggedColumnIndex];

    _draggedColumnIndex = columnIndex;
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

    var tableColumn = _tableColumns[fromIndex],
        selectedTableColumns = [_tableColumns objectsAtIndexes:_selectedColumnIndexes];

    [_tableColumns removeObjectAtIndex:fromIndex];
    [_tableColumns insertObject:tableColumn atIndex:toIndex];

    [[self headerView] setNeedsLayout];
    [[self headerView] setNeedsDisplay:YES];

    var range = CPMakeRange(MIN(fromIndex, toIndex), ABS(fromIndex - toIndex) + 1),
        layoutColumnIndexes = [CPIndexSet indexSetWithIndexesInRange:range],
        selectedColumnIndexes = [CPIndexSet indexSet];

    [_tableColumns enumerateObjectsUsingBlock:function(tableColumn, idx, stop)
    {
        if ([selectedTableColumns containsObjectIdenticalTo:tableColumn])
            [selectedColumnIndexes addIndex:idx];
    }];

    if ([_selectedColumnIndexes containsIndex:fromIndex] || (_draggedColumnIndex === fromIndex && _draggedColumnIsSelected))
        [selectedColumnIndexes addIndex:toIndex];

    if (_draggedColumnIndex !== -1)
        [layoutColumnIndexes removeIndex:toIndex];

    [self _layoutViewsForRowIndexes:_exposedRows columnIndexes:layoutColumnIndexes];
    [self selectColumnIndexes:selectedColumnIndexes byExtendingSelection:NO];
    [self setNeedsDisplay:YES];

    // Notify even if programmatically moving a column as in Cocoa.
    // TODO Only notify when a column drag operation ends, not each time a column reaches a new slot?
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewColumnDidMoveNotification
                                                        object:self
                                                      userInfo:@{  @"CPOldColumn": fromIndex, @"CPNewColumn": toIndex }];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableViewColumnDidMove_)
        [_delegate tableViewColumnDidMove:[[CPNotification alloc] initWithName:CPTableViewColumnDidMoveNotification object:self userInfo:@{  @"CPOldColumn": fromIndex, @"CPNewColumn": toIndex }]];
}

/*!
    Moves the column and heading at a given index to a new given index.
    @param theColumnIndex The current index of the column to move.
    @param theToIndex The new index for the moved column.
*/
- (void)moveColumn:(CPInteger)theColumnIndex toColumn:(CPInteger)theToIndex
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
    [self _layoutViewsForRowIndexes:rowIndexes columnIndexes:[CPIndexSet indexSetWithIndex:columnIndex]];

    // The layout places the vertical grid lines and the column selection again.
    [self setNeedsLayout];
    [self _markDrawingPassForDisplay];
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
        count = [self _numberOfColumns];

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
- (void)_didResizeTableColumn:(CPTableColumn)theColumn oldWidth:(int)oldWidth
{
    [self _autosave];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewColumnDidResizeNotification
                      object:self
                    userInfo:@{ @"CPTableColumn": theColumn, @"CPOldWidth": oldWidth }];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableViewColumnDidResize_)
        [_delegate tableViewColumnDidResize:[[CPNotification alloc] initWithName:CPTableViewColumnDidResizeNotification object:self userInfo:@{ @"CPTableColumn": theColumn, @"CPOldWidth": oldWidth }]];
}

/*!
    Sets the column autoresizing style of the receiver to a given style.

    When the width of the receiver changes, the change goes to its autoresizable columns: the
    visible columns whose resizing mask includes CPTableColumnAutoresizingMask.

    @param aStyle the column autoresizing style for the receiver. Valid values are:
<pre>
        CPTableViewNoColumnAutoresizing                     no column changes
        CPTableViewUniformColumnAutoresizingStyle           each column takes an equal share
        CPTableViewSequentialColumnAutoresizingStyle        the last column first, then the one before it
        CPTableViewReverseSequentialColumnAutoresizingStyle the first column first, then the one after it
        CPTableViewLastColumnOnlyAutoresizingStyle          the last column only (the default)
        CPTableViewFirstColumnOnlyAutoresizingStyle         the first column only
</pre>
    A column takes the change until it reaches its minimum or maximum width.
*/
- (void)setColumnAutoresizingStyle:(unsigned)style
{
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
    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    [self _updateColumnRangesIfNecessary];

    var count = [self _numberOfColumns];

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
    Gives the visible columns equal widths that fill the enclosing clip view, so that all of
    them are visible. A column whose minimum or maximum width the equal width passes keeps that
    limit, and the other columns share the rest.
*/
- (void)sizeToFit
{
    var superview = [self superview],
        width = [superview isKindOfClass:[CPClipView class]] ? CGRectGetWidth([superview bounds]) : CGRectGetWidth([self bounds]),
        open = [];

    for (var i = 0, count = [self _numberOfColumns]; i < count; i++)
        if (![_tableColumns[i] isHidden])
            open.push(_tableColumns[i]);

    var remainingWidth = width - open.length * _intercellSpacing.width;

    /*
        Each pass gives the open columns an equal width. The columns that the width puts
        outside their limits take their limits and leave the pass, until no column does.
    */
    while (open.length)
    {
        var equalWidth = remainingWidth / open.length,
            stillOpen = [];

        for (var i = 0; i < open.length; i++)
        {
            var column = open[i],
                limit = equalWidth > [column maxWidth] ? [column maxWidth] : (equalWidth < [column minWidth] ? [column minWidth] : nil);

            if (limit === nil)
                stillOpen.push(column);
            else
            {
                [column setWidth:limit];
                remainingWidth -= limit;
            }
        }

        if (stillOpen.length === open.length)
        {
            for (var i = 0; i < open.length; i++)
                [open[i] setWidth:equalWidth];

            break;
        }

        open = stillOpen;
    }

    [self tile];
}

/*!
    Informs the receiver that the number of records in the datasource has changed.
*/
- (void)noteNumberOfRowsChanged
{
    var oldNumberOfRows = _numberOfRows;

    _numberOfRows = [self _numberOfRows];

    _cachedRowHeights = [];

    // this line serves two purposes
    // 1. it updates the _numberOfRows cache with the -numberOfRows call
    // 2. it updates the row height cache if needed
    [self _noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, _numberOfRows)]];

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

/*
    Populates the row height cache if necessary.
*/
- (void)_populateRowHeightCacheIfNeeded
{
    if ([self numberOfRows] !== _cachedRowHeights.length)
        [self noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, _numberOfRows)]];
}

/*!
    Informs the receiver that the rows specified in indexSet have changed height.

    @param anIndexSet an index set containing the indexes of the rows which changed height
*/
- (void)_noteHeightOfRowsWithIndexesChanged:(CPIndexSet)anIndexSet
{
    if (![self _hasVariableRowHeights])
        return;

    // Update the height of the given rows by calling the delegate. Since the row height cache also contains
    // y coordinates, we have to update the y coordinates of all rows below the first valid row in the range.
    var i = [anIndexSet indexGreaterThanOrEqualToIndex:0];

    if (i === CPNotFound)
        return;

    var y = i < _cachedRowHeights.length ? _cachedRowHeights[i].y : 0;

    for (var count = [self numberOfRows]; i < count; ++i)
    {
        var height;

        if ([anIndexSet containsIndex:i])
            height = [self _sendDelegateHeightOfRow:i];
        else
            height = _cachedRowHeights[i].height || _rowHeight;  // in case the cache entry is empty

        _cachedRowHeights[i] = {y:y, height:height};
        y += height + _intercellSpacing.height;
    }
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
    var firstRowFrame  = [self frameOfDataViewAtColumn:0 row:[theDraggedRows firstIndex]],
        lastRowFrame   = [self frameOfDataViewAtColumn:0 row:[theDraggedRows lastIndex]],
        dragViewHeight = CGRectGetMaxY(lastRowFrame) - CGRectGetMinY(firstRowFrame);

    var bounds = CGRectMake(0, 0, CGRectGetWidth([self bounds]), dragViewHeight),
        dragView = [[CPView alloc] initWithFrame:bounds];

    [dragView setAlphaValue:0.7];
//    [dragView setBackgroundColor:[CPColor colorWithWhite:1 alpha:0.5]];

    // We have to fetch all the data views for the selected rows and columns
    // After that we can copy these add them to a transparent drag view and use that drag view
    // to make it appear we are dragging images of those rows (as you would do in regular Cocoa)
    [self _enumerateViewsInRows:theDraggedRows tableColumns:theTableColumns usingBlock:function(v, row, tableColumn, stop)
    {
        var column = [_tableColumns indexOfObjectIdenticalTo:tableColumn],
            newDataView = [self preparedViewAtColumn:column row:row],
            origin = [newDataView frame].origin;

        origin.y -= CGRectGetMinY(firstRowFrame);
        [newDataView setFrameOrigin:origin];

        [dragView addSubview:newDataView];
    }];

    var dragPoint = [self convertPoint:[theDragEvent locationInWindow] fromView:nil];
    dragViewOffset.x = CGRectGetWidth(bounds) / 2 - dragPoint.x;
    dragViewOffset.y = CGRectGetHeight(bounds) / 2 - dragPoint.y;

    return dragView;
}

- (CPView)_animationViewForColumn:(CPInteger)columnIndex
{
    return [self _makeGhostViewForColumn:columnIndex forDragging:NO];
}

- (CPView)_dragViewForColumn:(CPInteger)columnIndex
{
    return [self _makeGhostViewForColumn:columnIndex forDragging:YES];
}

- (CPView)_makeGhostViewForColumn:(CPInteger)columnIndex forDragging:(BOOL)isForDragging
{
    var headerFrame = [_headerView frame],
        visibleRect = [self visibleRect],
        visibleRows = [self rowsInRect:visibleRect],
        columnRect = [self rectOfColumn:columnIndex],
        tableColumn = [[self tableColumns] objectAtIndex:columnIndex],
        tableColumnUID = [tableColumn UID],
        columnHeaderView = [tableColumn headerView],
        columnHeaderFrame = [columnHeaderView frame],
        frame = CGRectMake(MAX(CGRectGetMinX(columnRect)/* - CGRectGetMinX(visibleRect)*/, 0.0),
                            0.0,
                            CGRectGetWidth(columnHeaderFrame),
                            CGRectGetHeight(visibleRect) + CGRectGetHeight(headerFrame));

    // We need a wrapper view around the header and column, this is what will be dragged
    var dragView = [[_CPColumnDragDrawingView alloc] initWithFrame:frame];

    [dragView setTableView:self];
    [dragView setColumnIndex:columnIndex];
    [dragView setBackgroundColor:[CPColor clearColor]];
    [dragView setAlphaValue:(isForDragging ? 0.6 : 1.0)];
    [dragView setShouldDrawBorders:isForDragging];
    [dragView setIsSelected:[self isColumnSelected:columnIndex]];

    // Now a view that clips the column data views, which itself is clipped to the content view
    var columnVisRect = CGRectIntersection(columnRect, visibleRect);

    frame = CGRectMake(0.0, CGRectGetHeight(headerFrame), CGRectGetWidth(columnRect), CGRectGetHeight(columnVisRect));

    var columnClipView = [[CPView alloc] initWithFrame:frame];

    [dragView addSubview:columnClipView];
    [dragView setColumnClipView:columnClipView];

    if (isForDragging)
        _draggedColumnIsSelected = [self isColumnSelected:columnIndex];

    var columnLeft = CGRectGetMinX(columnRect),
        offset = CGPointMake(columnLeft, CGRectGetMinY(visibleRect));

    [self _enumerateViewsInRows:_exposedRows columns:[CPIndexSet indexSetWithIndex:columnIndex] usingBlock:function(dataView, row, column, stop)
    {
        [self _addDraggedDataView:dataView toView:columnClipView forColumn:column row:row offset:offset];
        delete (_dataViewsForRows[row][tableColumnUID]);
    }];

    // Add the column header view
    columnHeaderFrame.origin = CGPointMakeZero();

    var dragColumnHeaderView = [[_CPTableColumnHeaderView alloc] initWithFrame:columnHeaderFrame],
        image = [columnHeaderView _indicatorImage];

    [dragColumnHeaderView setStringValue:[columnHeaderView stringValue]];
    [dragColumnHeaderView setThemeState:[columnHeaderView themeState]];
    
    // Explicitly force the selected state on the ghost header if the original column is selected
    if ([self isColumnSelected:columnIndex])
        [dragColumnHeaderView setThemeState:CPThemeStateSelected];

    [dragColumnHeaderView _setIndicatorImage:image];

    if (isForDragging)
        // Give it a tag so it can be found later
        [dragColumnHeaderView setTag:1];

    [dragView addSubview:dragColumnHeaderView];

    // While dragging, the column is deselected in the table view
    [_selectedColumnIndexes removeIndex:columnIndex];
    [self setNeedsDisplay:YES];

    return dragView;
}

- (void)_addDraggedDataView:(CPView)aDataView toView:(CPView)aSuperview forColumn:(CPInteger)column row:(CPInteger)row offset:(CGPoint)offset
{
    var dataViewFrame = [self frameOfDataViewAtColumn:column row:row];

    dataViewFrame.origin.x -= offset.x;
    // Offset by table header height - scroll position
    dataViewFrame.origin.y -= offset.y;

    [aDataView setFrame:dataViewFrame];
    [aSuperview addSubview:aDataView];
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

@end


@implementation _CPColumnDragDrawingView : CPView
{
    CPTableView tableView         @accessors;
    int         columnIndex       @accessors;
    CPView      columnClipView    @accessors;
    BOOL        shouldDrawBorders @accessors;
    BOOL        isSelected        @accessors;
}

@end
