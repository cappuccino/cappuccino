/*
 * CPTableView+Dragging.j
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


@implementation CPTableView (Dragging)


/*
    @ignore
*/
- (CPTableViewDropOperation)_proposedDropOperationAtPoint:(CGPoint)theDragPoint
{
    if (_retargetedDropOperation != nil)
        return _retargetedDropOperation;

    var row = [self _proposedRowAtPoint:theDragPoint],
        rowRect = [self rectOfRow:row];

    // If there is no (the default) or too little inter-cell spacing we create some room for the CPTableViewDropAbove indicator
    // This probably doesn't work if the row height is smaller than or around 5.0
    if ([self intercellSpacing].height < 5.0)
        rowRect = CGRectInset(rowRect, 0.0, 5.0 - [self intercellSpacing].height);

    // If the altered row rect contains the drag point we show the drop on
    // We don't show the drop on indicator if we are dragging below the last row
    // in that case we always want to show the drop above indicator
    if (CGRectContainsPoint(rowRect, theDragPoint) && row < _numberOfRows)
        return CPTableViewDropOn;

    return CPTableViewDropAbove;
}

/*
    @ignore
*/
- (CPInteger)_proposedRowAtPoint:(CGPoint)dragPoint
{
    var row = [self rowAtPoint:dragPoint],
        // Determine if the mouse is currently closer to this row or the row below it
        lowerRow = row + 1,
        rect = [self rectOfRow:row],
        bottomPoint = CGRectGetMaxY(rect),
        bottomThirty = bottomPoint - ((bottomPoint - CGRectGetMinY(rect)) * 0.3),
        numberOfRows = [self numberOfRows];

    if (row < 0)
        row = (CGRectGetMaxY(rect) < dragPoint.y) ? numberOfRows : row;
    else if (dragPoint.y > MAX(bottomThirty, bottomPoint - 6))
        row = lowerRow;

    row = MIN(numberOfRows, row);

    return row;
}

/*
    Records aRow as the row that a drag proposes a drop on, or CPNotFound for none, and
    configures the row views of the old and the new row.
*/
- (void)_setDropTargetRow:(CPInteger)aRow
{
    if (_dropTargetRow === aRow)
        return;

    var oldRow = _dropTargetRow,
        oldRowView = _visibleRowViews[oldRow],
        newRowView = _visibleRowViews[aRow];

    _dropTargetRow = aRow;

    if (oldRowView)
        [self _configureRowView:oldRowView forRow:oldRow];

    if (newRowView)
        [self _configureRowView:newRowView forRow:aRow];
}

/*!
    @ignore
*/
- (CGRect)_rectForDropHighlightViewOnRow:(CPInteger)theRowIndex
{
    if (theRowIndex >= [self numberOfRows])
        theRowIndex = [self numberOfRows] - 1;

    return [self _rectOfRow:theRowIndex checkRange:NO];
}

/*!
    @ignore
*/
- (CGRect)_rectForDropHighlightViewBetweenUpperRow:(CPInteger)theUpperRowIndex andLowerRow:(CPInteger)theLowerRowIndex offset:(CGPoint)theOffset
{
    if (theLowerRowIndex > [self numberOfRows])
        theLowerRowIndex = [self numberOfRows];

    return [self _rectOfRow:theLowerRowIndex checkRange:NO];
}

/*!
    @ignore
*/
- (CPDragOperation)draggingUpdated:(id)sender
{
    _retargetedDropRow = nil;
    _retargetedDropOperation = nil;

    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        dropOperation = [self _proposedDropOperationAtPoint:location],
        numberOfRows = [self numberOfRows],
        row = [self _proposedRowAtPoint:location],
        dragOperation = [self _sendDataSourceValidateDrop:sender proposedRow:row proposedDropOperation:dropOperation];

    if (_retargetedDropRow != nil)
        row = _retargetedDropRow;

    if (_retargetedDropOperation != nil)
        dropOperation = _retargetedDropOperation;

    if (dropOperation === CPTableViewDropOn && row >= numberOfRows)
        row = numberOfRows - 1;

    var rect = CGRectMakeZero();

    if (row === -1)
        rect = [self exposedRect];
    else if (dropOperation === CPTableViewDropAbove)
        rect = [self _rectForDropHighlightViewBetweenUpperRow:row - 1 andLowerRow:row offset:location];
    else
        rect = [self _rectForDropHighlightViewOnRow:row];

    [self _setDropTargetRow:(row !== -1 && dropOperation === CPTableViewDropOn && dragOperation !== CPDragOperationNone) ? row : CPNotFound];

    [_dropOperationFeedbackView setDropOperation:row !== -1 ? dropOperation : CPDragOperationNone];
    [_dropOperationFeedbackView setHidden:(dragOperation == CPDragOperationNone)];
    [_dropOperationFeedbackView setFrame:rect];
    [_dropOperationFeedbackView setCurrentRow:row];
    [self addSubview:_dropOperationFeedbackView];

    return dragOperation;
}

/*
    @ignore
*/
- (BOOL)prepareForDragOperation:(id)sender
{
    // FIX ME: is there anything else that needs to happen here?
    // actual validation is called in draggingUpdated:
    [_dropOperationFeedbackView removeFromSuperview];
    [self _setDropTargetRow:CPNotFound];

    return [self _dataSourceRespondsToValidateDropProposedRowProposedDropOperation];
}

/*
    @ignore
*/
- (BOOL)performDragOperation:(id)sender
{
    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        operation = [self _proposedDropOperationAtPoint:location],
        row = _retargetedDropRow;

    if (row == nil)
        row = [self _proposedRowAtPoint:location];

    return [self _sendDataSourceAcceptDrop:sender row:row dropOperation:operation];
}

/*
    @ignore
*/
- (void)concludeDragOperation:(id)sender
{
    [self _reloadDataViews];
}

/*
    @ignore
    We're using this because we drag views instead of images so we can get the rows themselves to actually drag.
*/
- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    [self _draggingEnded];
    [self draggedImage:aView endedAt:aLocation operation:anOperation];
}

/*!
    @ignore
*/
- (void)_updateSelectionWithMouseAtRow:(CPInteger)aRow
{
    //check to make sure the row exists
    if (aRow < 0)
        return;

    var newSelection,
        shouldExtendSelection = NO;

    // If cmd/ctrl was held down XOR the old selection with the proposed selection
    if ([self mouseDownFlags] & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        if ([_selectedRowIndexes containsIndex:aRow])
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection removeIndex:aRow];
        }
        else if (_allowsMultipleSelection)
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection addIndex:aRow];
        }
        else
            newSelection = [CPIndexSet indexSetWithIndex:aRow];
    }
    else if (_allowsMultipleSelection)
    {
        if (_selectionAnchorRow == CPNotFound)
            _selectionAnchorRow = [self numberOfRows] - 1;

        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionAnchorRow), ABS(aRow - _selectionAnchorRow) + 1)];
        shouldExtendSelection = [self mouseDownFlags] & CPShiftKeyMask &&
                                ((_lastSelectedRow == [_selectedRowIndexes lastIndex] && aRow > _lastSelectedRow) ||
                                (_lastSelectedRow == [_selectedRowIndexes firstIndex] && aRow < _lastSelectedRow));
    }
    else if (aRow >= 0 && aRow < _numberOfRows)
        newSelection = [CPIndexSet indexSetWithIndex:aRow];
    else
        newSelection = [CPIndexSet indexSet];

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes] && [_selectedColumnIndexes count] === 0)
        return;

    if (![self _sendDelegateSelectionShouldChangeInTableView])
        return;

    newSelection = [self _sendDelegateSelectionIndexesForProposedSelection:newSelection];

    if (![self _delegateRespondsToSelectionIndexesForProposedSelection] && [self _delegateRespondsToShouldSelectRow])
    {
        var indexArray = [];

        [newSelection getIndexes:indexArray maxCount:-1 inIndexRange:nil];

        var indexCount = indexArray.length;

        while (indexCount--)
        {
            var index = indexArray[indexCount];

            if (![self _sendDelegateShouldSelectRow:index])
                [newSelection removeIndex:index];
        }

        // as per cocoa
        if ([newSelection count] === 0)
            return;
    }

    // if empty selection is not allowed and the new selection has nothing selected, abort
    if (!_allowsEmptySelection && [newSelection count] === 0)
        return;

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    [self _noteSelectionIsChanging];
    [self selectRowIndexes:newSelection byExtendingSelection:shouldExtendSelection];

    _lastSelectedRow = [newSelection containsIndex:aRow] ? aRow : [newSelection lastIndex];
}

/*!
    @ignore
*/
- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableViewSelectionIsChanging_)
        [_delegate tableViewSelectionIsChanging:[[CPNotification alloc] initWithName:CPTableViewSelectionIsChangingNotification object:self userInfo:nil]];
}

/*!
    @ignore
*/
- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableViewSelectionDidChange_)
        [_delegate tableViewSelectionDidChange:[[CPNotification alloc] initWithName:CPTableViewSelectionDidChangeNotification object:self userInfo:nil]];
}

@end

@implementation _CPDropOperationDrawingView : CPView
{
    unsigned    dropOperation @accessors;
    CPTableView tableView @accessors;
    int         currentRow @accessors;
    BOOL        isBlinking @accessors;
}

- (void)drawRect:(CGRect)aRect
{
    if (tableView._destinationDragStyle === CPTableViewDraggingDestinationFeedbackStyleNone || isBlinking)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        borderRadius,
        borderColor,
        borderWidth,
        backgroundColor;

    if (currentRow === -1)
    {
        borderColor = [tableView valueForThemeAttribute:@"dropview-on-border-color"];
        borderWidth = [tableView valueForThemeAttribute:@"dropview-on-border-width"];

        CGContextSetStrokeColor(context, borderColor);
        CGContextSetLineWidth(context, borderWidth);
        CGContextStrokeRect(context, [self bounds]);
    }

    else if (dropOperation === CPTableViewDropOn)
    {
        //if row is selected don't fill and stroke white
        var selectedRows = [tableView selectedRowIndexes],
            newRect = CGRectMake(aRect.origin.x + 2, aRect.origin.y + 2, aRect.size.width - 4, aRect.size.height - 5);

        if ([selectedRows containsIndex:currentRow])
        {
            borderRadius = [tableView valueForThemeAttribute:@"dropview-on-selected-border-radius"];
            borderColor = [tableView valueForThemeAttribute:@"dropview-on-selected-border-color"];
            borderWidth = [tableView valueForThemeAttribute:@"dropview-on-selected-border-width"];
            backgroundColor = [tableView valueForThemeAttribute:@"dropview-on-selected-background-color"];
        }
        else
        {
            borderRadius = [tableView valueForThemeAttribute:@"dropview-on-border-radius"];
            borderColor = [tableView valueForThemeAttribute:@"dropview-on-border-color"];
            borderWidth = [tableView valueForThemeAttribute:@"dropview-on-border-width"];
            backgroundColor = [tableView valueForThemeAttribute:@"dropview-on-background-color"];
        }

        CGContextSetStrokeColor(context, borderColor);
        CGContextSetLineWidth(context, borderWidth);
        CGContextSetFillColor(context, backgroundColor);
        CGContextFillRoundedRectangleInRect(context, newRect, borderRadius, YES, YES, YES, YES);
        CGContextStrokeRoundedRectangleInRect(context, newRect, borderRadius, YES, YES, YES, YES);

    }
    else if (dropOperation === CPTableViewDropAbove)
    {
        //reposition the view up a tad
        [self setFrameOrigin:CGPointMake(_frame.origin.x, _frame.origin.y - 8)];

        var selectedRows = [tableView selectedRowIndexes];

        if ([selectedRows containsIndex:currentRow - 1] || [selectedRows containsIndex:currentRow])
        {
            borderColor = [tableView valueForThemeAttribute:@"dropview-above-selected-border-color"];
            borderWidth = [tableView valueForThemeAttribute:@"dropview-above-selected-border-width"];
        }
        else
        {
            borderColor = [tableView valueForThemeAttribute:@"dropview-above-border-color"];
            borderWidth = [tableView valueForThemeAttribute:@"dropview-above-border-width"];
        }

        CGContextSetStrokeColor(context, borderColor);
        CGContextSetLineWidth(context, borderWidth);
        CGContextStrokeEllipseInRect(context, CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8)); // circle

        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
        CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
        CGContextStrokePath(context);
    }
}

- (void)blink
{
    if (dropOperation !== CPTableViewDropOn)
        return;

    isBlinking = YES;

    var showCallback = function()
    {
        [self setHidden: NO];
        isBlinking = NO;
    };

    var hideCallback = function()
    {
        [self setHidden: YES];
        isBlinking = YES;
    };

    [self setHidden: YES];
    [CPTimer scheduledTimerWithTimeInterval:0.1 callback:showCallback repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.19 callback:hideCallback repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.27 callback:showCallback repeats:NO];
}

@end
