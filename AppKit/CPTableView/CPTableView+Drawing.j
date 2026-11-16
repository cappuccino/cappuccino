/*
 * CPTableView+Drawing.j
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


@implementation CPTableView (Drawing)


- (void)_updateSelectedColumnBackgrounds
{
    if (!CPDOMAvailable)
        return;

    // 1. Remove existing column background views
    [_selectedColumnBackgroundViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_selectedColumnBackgroundViews removeAllObjects];

    // 2. If no highlighting style, stop here
    if ([self selectionHighlightStyle] === CPTableViewSelectionHighlightStyleNone)
        return;

    var color = [self _isFocused] ? [self selectionHighlightColor] : [self unfocusedSelectionHighlightColor],
        bounds = [self bounds];

    // 3. Create a view for each selected column index
    [_selectedColumnIndexes enumerateIndexesUsingBlock:function(idx, stop)
    {
        var rect = [self rectOfColumn:idx];
        
        // Ensure the highlight spans the full height of the table
        rect.size.height = MAX(CGRectGetHeight(bounds), [self frame].size.height);

        var view = [[CPView alloc] initWithFrame:rect];
        [view setBackgroundColor:color];
        [view setHitTests:NO];

        // Add to the table view at the bottom of the stack
        [self addSubview:view positioned:CPWindowBelow relativeTo:nil];
        [_selectedColumnBackgroundViews addObject:view];
    }];

    // 4. Z-Order Correction:
    // _CPTableRowViews (alternating row colors) are also added "Below nil". 
    // To ensure the Column selection appears ON TOP of the row alternating colors,
    // we must push the currently visible row views to the very back.
    for (var rowIndex in _visibleRowViews)
    {
        if (_visibleRowViews.hasOwnProperty(rowIndex))
            [self addSubview:_visibleRowViews[rowIndex] positioned:CPWindowBelow relativeTo:nil];
    }
}

/*!
    @ignore
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    [super setNeedsDisplay:aFlag];

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
    return [[self window] isKeyWindow] && ([[self window] firstResponder] === self || _editingRow !== CPNotFound);
}

/*!
    @ignore
*/
- (void)_drawRect:(CGRect)aRect
{
    // NO-OP: We no longer draw on canvas. DOM composition handles background, grid and selection.
    if (_implementsCustomDrawRow)
        [self _drawRows:_exposedRows clipRect:aRect];
}

/*!
    Draws the background in a given clip rect.
    Deprecated: Handled by _CPTableRowView
*/
- (void)drawBackgroundInClipRect:(CGRect)aRect
{
}

/*!
    Draws the grid for the tableview.
    Deprecated: Handled by _CPTableRowView
*/
- (void)drawGridInClipRect:(CGRect)aRect
{
}

/*!
    Draws the selection.
    Deprecated: Handled by _CPTableRowView
*/
- (void)highlightSelectionInClipRect:(CGRect)aRect
{
}

/*!
    @ignore
    Draws the group rows
    FIX ME: this should be themed...
*/
- (void)_drawGroupRowsForRects:(CPArray)rects
{
    // TODO: Implement Group Row styling in _CPTableRowView
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

@end
