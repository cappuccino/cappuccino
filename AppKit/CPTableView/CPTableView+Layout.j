/*
 * CPTableView+Layout.j
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


@implementation CPTableView (Layout)


/*!
    Returns a range of indices for the rows that lie wholly or partially within the vertical boundaries of a given rectangle.

    @param aRect A rectangle in the coordinate system of the receiver.
*/
- (CPRange)rowsInRect:(CGRect)aRect
{
    // Complexity:
    // O(1)

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

    if (firstRow > lastRow)
        return CPMakeRange(0, 0);

    return CPMakeRange(firstRow, lastRow - firstRow + 1);
}

/*
    Return the range of rows that lie wholly or partially within aRect.
    If the bottom of the last real row is above the bottom of aRect,
    synthesized rows of the default height are added to fill aRect.
*/
- (CPRange)_exposedRowsInRect:(CGRect)aRect
{
    var rowRange = [self rowsInRect:aRect],
        lastRealRow = CPMaxRange(rowRange) - 1,
        rectOfLastRealRow = [self _rectOfRow:lastRealRow checkRange:NO],
        bottomOfRealRows = CGRectGetMaxY(rectOfLastRealRow),
        rectBottom = CGRectGetMaxY(aRect);

    // If the bottom of the last real row is at or below the bottom of aRect, we are done
    if (bottomOfRealRows >= rectBottom)
        return rowRange;

    var numberOfSynthesizedRows = CEIL((rectBottom - bottomOfRealRows) / [self _fullRowHeight]);

    rowRange.length += numberOfSynthesizedRows;

    return rowRange;
}

/*!
    Returns the indexes of the receiver's columns that intersect the specified rectangle.

    @param aRect a rectangle in the coordinate system of the receiver.
*/
- (CPIndexSet)columnIndexesInRect:(CGRect)aRect
{
    // Complexity:
    // O(log numberOfColumns) if table view contains no hidden columns
    // O(numberOfColumns) if table view contains hidden columns

    if ([self _numberOfColumns] === 0)
        return [CPIndexSet indexSet];

    var column = MAX(0, [self columnAtPoint:CGPointMake(aRect.origin.x, 0.0)]),
        lastColumn = [self columnAtPoint:CGPointMake(CGRectGetMaxX(aRect), 0.0)];

    if (lastColumn === CPNotFound)
        lastColumn = [self _numberOfColumns] - 1;

    if (column > lastColumn || lastColumn < 0)
        return [CPIndexSet indexSet];

    // Don't bother doing the expensive removal of hidden indexes if we have no hidden columns.
    if (_numberOfHiddenColumns <= 0)
        return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(column, lastColumn - column + 1)];

    var indexSet = [CPIndexSet indexSet];

    for (; column <= lastColumn; ++column)
    {
        var tableColumn = _tableColumns[column];

        if (![tableColumn isHidden])
            [indexSet addIndex:column];
    }

    return indexSet;
}

/*!
    Returns the index of a column at a given point. If no column is there CPNotFound is returned.

    @param aPoint a CGPoint
*/
- (CPInteger)columnAtPoint:(CGPoint)aPoint
{
    // Complexity:
    // O(log numberOfColumns) if table view contains no hidden columns
    // O(numberOfColumns) if table view contains hidden columns

    var bounds = [self bounds];

    if (!CGRectContainsPoint(bounds, aPoint))
        return CPNotFound;

    [self _updateColumnRangesIfNecessary];

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

/*!
    Returns the index of a row at a particular point. If no row exists at that point -1 is returned.

    @param aPoint a CGPoint
*/
- (CPInteger)rowAtPoint:(CGPoint)aPoint
{
    // Complexity:
    // O(1) for fixed height rows or point out of bounds
    // O(log numberOfRows) for variable height rows

    // aPoint.x must be within our bounds
    var bounds = [self bounds];

    if (aPoint.x < CGRectGetMinX(bounds) || aPoint.x >= CGRectGetMaxX(bounds))
        return -1;

    // aPoint.x is in bounds, now we just have to check aPoint.y

    if ([self _hasVariableRowHeights])
    {
        // First make sure aPoint.y is above the bottom of the last row, otherwise we might
        // search the (potentially large number of) rows for nothing.
        var heightInfo = [_cachedRowHeights lastObject];

        if (!heightInfo || aPoint.y >= [self _rowBottomOfHeightInfo:heightInfo])
            return -1;

        return [_cachedRowHeights indexOfObject:aPoint
                                  inSortedRange:nil
                                        options:0
                                usingComparator:function(aPoint, heightInfo)
                {
                    if (aPoint.y < heightInfo.y)
                        return CPOrderedAscending;

                    if (aPoint.y > [self _rowBottomOfHeightInfo:heightInfo])
                        return CPOrderedDescending;

                    return CPOrderedSame;
                }];
    }
    else
    {
        var row = FLOOR(aPoint.y / [self _fullRowHeight]);

        return row >= _numberOfRows ? -1 : row;
    }
}

/*!
    Returns the index of the row for the specified view.

    @param view The view.
    @return The index of the row corresponding to the view. Returns -1 if the view is not a dataView or a row view, or a subview of one.
    @discussion This is typically needed in the action method for a CPButton (or CPControl) to find out what row (and column) the action should be performed on.
                The implementation is O(rxc) where r is the number of visible rows, and c is the number of visible columns, so this method should generally not be called within a loop.
*/
- (CPInteger)rowForView:(CPView)aView
{
    var row;

    [self getColumn:nil row:@ref(row) forView:aView];

    if (row === -1)
        row = [self _rowOfRowViewContainingView:aView];

    return row;
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
    var column;

    [self getColumn:@ref(column) row:nil forView:aView];

    return column;
}

/*!
    @ignore
*/
- (void)getColumn:(Function)columnRef row:(Function)rowRef forView:(CPView)aView
{
    var columnResult = -1,
        rowResult = -1;

    if (aView && [aView isKindOfClass:[CPView class]] && ![aView isKindOfClass:[CPTableView class]])
    {
        var cellView = aView,
            contentView = [[self window] contentView],
            found = NO,
            max_rec = 100;

        while (max_rec--)
        {
            if (!cellView || cellView === contentView)
            {
                found = NO;
                break;
            }
            else
            {
                var superview = [cellView superview];

                if ([superview isKindOfClass:[CPTableView class]])
                {
                    found = YES;
                    break;
                }

                cellView = superview;
            }
        }

        if (found)
        {
            [self _enumerateViewsInRows:_exposedRows columns:_exposedColumns usingBlock:function(view, row, column, stop)
            {

                if (view === cellView)
                {
                    columnResult = column;
                    rowResult = row;
                    stop(YES);
                }
            }];
        }
    }

    if (columnRef)
        columnRef(columnResult);

    if (rowRef)
        rowRef(rowResult);
}

/*!
    Returns a rect for the dataview / cell at the column and row given.
    If the column or row index is greater than the number of columns or rows a CGZeroRect is returned

    @param aColumn index of the column
    @param aRow index of the row
*/
- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    [self _updateColumnRangesIfNecessary];

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

    Gives the change in the width of the receiver to its columns, by its column autoresizing
    style. In a clip view the receiver is as wide as the clip view, so the change is the new
    width of the clip view less the width of the receiver before the resize.

    The method resized the columns to fill the clip view, except with the uniform style, and
    only when a heuristic guessed that the columns had filled it before. A table view with a
    gap after its columns lost the gap, the sequential styles did nothing, and the uniform
    style missed the clip view by the intercell spacing. 2026-11-24
*/
- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    var oldWidth = CGRectGetWidth([self frame]);

    [super resizeWithOldSuperviewSize:aSize];

    var superview = [self superview];

    if (_disableAutomaticResizing || ![superview isKindOfClass:[CPClipView class]])
        return;

    var clipWidth = CGRectGetWidth([superview bounds]);

    if (clipWidth === aSize.width)
        return;

    /*
        Before its first tile the receiver can be narrower than the clip view was. It was then
        as wide as the clip view for the purpose of the change.
    */
    [self _autoresizeColumnsByWidth:clipWidth - MAX(oldWidth, aSize.width)];
}

/*
    Gives aDelta points of width to the autoresizable columns by the column autoresizing style.
*/
- (void)_autoresizeColumnsByWidth:(float)aDelta
{
    if (!aDelta || _columnAutoResizingStyle === CPTableViewNoColumnAutoresizing)
        return;

    var visibleColumns = [],
        autoresizableColumns = [];

    for (var i = 0, count = [self _numberOfColumns]; i < count; i++)
    {
        var column = _tableColumns[i];

        if ([column isHidden])
            continue;

        visibleColumns.push(column);

        if ([column resizingMask] & CPTableColumnAutoresizingMask)
            autoresizableColumns.push(column);
    }

    var firstColumn = visibleColumns[0],
        lastColumn = visibleColumns[visibleColumns.length - 1];

    switch (_columnAutoResizingStyle)
    {
        case CPTableViewUniformColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns uniformlyByWidth:aDelta];
            break;

        case CPTableViewSequentialColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns.reverse() sequentiallyByWidth:aDelta];
            break;

        case CPTableViewReverseSequentialColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns sequentiallyByWidth:aDelta];
            break;

        case CPTableViewLastColumnOnlyAutoresizingStyle:
            if (lastColumn && [autoresizableColumns containsObjectIdenticalTo:lastColumn])
                [self _resizeColumns:[lastColumn] sequentiallyByWidth:aDelta];
            break;

        case CPTableViewFirstColumnOnlyAutoresizingStyle:
            if (firstColumn && [autoresizableColumns containsObjectIdenticalTo:firstColumn])
                [self _resizeColumns:[firstColumn] sequentiallyByWidth:aDelta];
            break;
    }
}

/*
    Gives aDelta points of width to the autoresizable columns after the column at anIndex, by
    the column autoresizing style, and returns the part of aDelta they could not take. The
    header view calls it while the user resizes the column at anIndex, with the opposite of
    that column's change, so the columns keep their total width where they can:

    - no column autoresizing: no column changes;
    - uniform: the columns after it take equal shares;
    - sequential: the last column first, then the one before it, back to the resized column;
    - reverse sequential: the column after it first, then the next;
    - last column only: the last column, unless it is the resized column;
    - first column only: the first column after it.

    2026-11-26: a column resized by the user took the whole change, whatever the style. The
    other columns kept their widths, so the change became a gap after the last column, or an
    overflow, which every later change of the table's width kept, since autoresizing applies
    only the change. In People, making Salary narrower left a gap after Email with the last
    column only style. As in AppKit, the columns after the resized column now take the change.
*/
- (float)_autoresizeColumnsAfterColumn:(CPInteger)anIndex byWidth:(float)aDelta
{
    if (!aDelta || _columnAutoResizingStyle === CPTableViewNoColumnAutoresizing)
        return aDelta;

    var autoresizableColumns = [],
        lastVisibleColumn = nil;

    for (var i = anIndex + 1, count = [self _numberOfColumns]; i < count; i++)
    {
        var column = _tableColumns[i];

        if ([column isHidden])
            continue;

        lastVisibleColumn = column;

        if ([column resizingMask] & CPTableColumnAutoresizingMask)
            autoresizableColumns.push(column);
    }

    var oldWidths = 0;

    for (var i = 0; i < autoresizableColumns.length; i++)
        oldWidths += [autoresizableColumns[i] width];

    switch (_columnAutoResizingStyle)
    {
        case CPTableViewUniformColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns uniformlyByWidth:aDelta];
            break;

        case CPTableViewSequentialColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns.slice().reverse() sequentiallyByWidth:aDelta];
            break;

        case CPTableViewReverseSequentialColumnAutoresizingStyle:
            [self _resizeColumns:autoresizableColumns sequentiallyByWidth:aDelta];
            break;

        case CPTableViewLastColumnOnlyAutoresizingStyle:
            if (lastVisibleColumn && [autoresizableColumns containsObjectIdenticalTo:lastVisibleColumn])
                [self _resizeColumns:[lastVisibleColumn] sequentiallyByWidth:aDelta];
            break;

        case CPTableViewFirstColumnOnlyAutoresizingStyle:
            if (autoresizableColumns.length)
                [self _resizeColumns:[autoresizableColumns[0]] sequentiallyByWidth:aDelta];
            break;
    }

    var newWidths = 0;

    for (var i = 0; i < autoresizableColumns.length; i++)
        newWidths += [autoresizableColumns[i] width];

    return aDelta - (newWidths - oldWidths);
}

/*
    Gives aDelta points to someColumns in order. Each column takes what it can within its
    minimum and maximum widths, and the next column takes the rest.
*/
- (void)_resizeColumns:(CPArray)someColumns sequentiallyByWidth:(float)aDelta
{
    var remaining = aDelta;

    for (var i = 0; i < someColumns.length && remaining; i++)
    {
        var column = someColumns[i],
            oldWidth = [column width];

        [column _tryToResizeToWidth:oldWidth + remaining];
        remaining -= [column width] - oldWidth;
    }
}

/*
    Gives aDelta points to someColumns in equal shares at the same time. The shares are whole
    points that add up to the change. A column that reaches its minimum or maximum width leaves,
    and the columns still open share what it could not take.
*/
- (void)_resizeColumns:(CPArray)someColumns uniformlyByWidth:(float)aDelta
{
    var remaining = aDelta,
        open = someColumns.slice();

    while (Math.abs(remaining) >= 0.5 && open.length)
    {
        var count = open.length,
            given = 0,
            stillOpen = [];

        for (var i = 0; i < count; i++)
        {
            var column = open[i],
                share = Math.round(remaining * (i + 1) / count) - Math.round(remaining * i / count),
                oldWidth = [column width];

            [column _tryToResizeToWidth:oldWidth + share];
            given += [column width] - oldWidth;

            if (remaining > 0 ? [column width] < [column maxWidth] : [column width] > [column minWidth])
                stillOpen.push(column);
        }

        remaining -= given;

        if (!given && stillOpen.length === count)
            break;

        open = stillOpen;
    }
}

/*!
    Informs the receiver that the rows specified in indexSet have changed height.

    @param anIndexSet an index set containing the indexes of the rows which changed height
*/
- (void)noteHeightOfRowsWithIndexesChanged:(CPIndexSet)anIndexSet
{
    [self _noteHeightOfRowsWithIndexesChanged:anIndexSet];
    [self _reloadDataViews];
}

/*!
    Lays out the dataviews and resizes the tableview so that everything fits.
*/
- (void)tile
{
    [self _updateColumnRangesIfNecessary];

    var width = _tableColumnRanges.length > 0 ? CPMaxRange([_tableColumnRanges lastObject]) : 0.0,
        superview = [self superview],
        height = 0;

    if (![self _hasVariableRowHeights])
        height = [self _fullRowHeight] * _numberOfRows;
    else if (_numberOfRows > 0)
    {
        [self _populateRowHeightCacheIfNeeded];

        var heightInfo = _cachedRowHeights[_cachedRowHeights.length - 1];

        height = [self _rowBottomOfHeightInfo:heightInfo];
    }

    if ([superview isKindOfClass:[CPClipView class]])
    {
        var superviewSize = [superview bounds].size;

        width = MAX(superviewSize.width, width);
        height = MAX(superviewSize.height, height);
    }

    [self setFrameSize:CGSizeMake(width, height)];

    /*
        The row views span the new width. They took the width in -resizeWithOldSuperviewSize:,
        before this method changed it, so they kept the width of the table view before a
        resize. 2026-11-24
    */
    [self _updateAllVisibleRowViewsFrames];

    [self setNeedsLayout];
    [self _markDrawingPassForDisplay];
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

- (int)_numberOfColumns
{
    return _tableColumns.length;
}

- (void)_updateColumnRangesIfNecessary
{
    if (_dirtyTableColumnRangeIndex !== CPNotFound)
        [self _recalculateTableColumnRanges];
}

- (CGFloat)_fullRowHeight
{
    return (_rowHeight + _intercellSpacing.height);
}

- (CGFloat)_rowBottomOfHeightInfo:(JSObject)heightInfo
{
    return (heightInfo.y + heightInfo.height + _intercellSpacing.height);
}

- (BOOL)_hasVariableRowHeights
{
    return (_implementedDelegateMethods & CPTableViewDelegate_tableView_heightOfRow_);
}

@end
