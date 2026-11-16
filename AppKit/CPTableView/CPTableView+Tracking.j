/*
 * CPTableView+Tracking.j
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


@implementation CPTableView (Tracking)


/*
    @ignore
*/
- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    // Try to become the first responder, but if we can't, that's okay.
    [[self window] makeFirstResponder:self];

    var row = [self rowAtPoint:aPoint];

    _clickedRow = row;
    _clickedColumn = [self columnAtPoint:aPoint];

    // If the user clicks outside a row then deselect everything.
    if (row < 0 && _allowsEmptySelection)
    {
        if ([self _sendDelegateSelectionShouldChangeInTableView])
        {
            var indexSet = [self _sendDelegateSelectionIndexesForProposedSelection:[CPIndexSet indexSet]];

            [self _noteSelectionIsChanging];
            [self selectRowIndexes:indexSet byExtendingSelection:NO];
        }
    }

    if ([self mouseDownFlags] & CPShiftKeyMask)
        _selectionAnchorRow = (ABS([_selectedRowIndexes firstIndex] - row) < ABS([_selectedRowIndexes lastIndex] - row)) ?
            [_selectedRowIndexes firstIndex] : [_selectedRowIndexes lastIndex];
    else
        _selectionAnchorRow = row;

    //set ivars for startTrackingPoint and time...
    _startTrackingPoint = aPoint;
    _startTrackingTimestamp = new Date();

    if ([self _dataSourceRespondsToSetObjectValueForTableColumnRow])
        _trackingPointMovedOutOfClickSlop = NO;

    // if the table has drag support then we use mouseUp to select a single row.
    // otherwise it uses mouse down.
    if (row >= 0 && !([self _dataSourceRespondsToWriteRowsWithIndexesToPasteboard]))
        [self _updateSelectionWithMouseAtRow:row];

    return YES;
}

/*!
    @ignore
*/
- (CPMenu)menuForEvent:(CPEvent)theEvent
{
    if (!([self _delegateRespondsToMenuForTableColumnRow]))
        return [super menuForEvent:theEvent];

    var location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        row = [self rowAtPoint:location],
        column = [self columnAtPoint:location],
        tableColumn = [[self tableColumns] objectAtIndex:column];

    return [self _sendDelegateMenuForTableColumn:tableColumn row:row];
}

/*
    @ignore
*/
- (void)trackMouse:(CPEvent)anEvent
{
    // Prevent CPControl from eating the mouse events when we are in a drag session
    if (![_draggedRowIndexes count])
    {
        [self autoscroll:anEvent];
        [super trackMouse:anEvent];
    }
    else
        [CPApp sendEvent:anEvent];

    if ([anEvent type] == CPLeftMouseUp)
    {
        _clickedRow = CPNotFound;
        _clickedColumn = CPNotFound;
    }
}

/*
    @ignore
*/
- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    _clickedRow = row;
    _clickedColumn = [self columnAtPoint:aPoint];

    // begin the drag is the datasource lets us, we've move at least +-3px vertical or horizontal,
    // or we're dragging from selected rows and we haven't begun a drag session
    if (!_isSelectingSession && [self _dataSourceRespondsToWriteRowsWithIndexesToPasteboard])
    {
        if (row >= 0 && (ABS(_startTrackingPoint.x - aPoint.x) > 3 || (_verticalMotionCanDrag && ABS(_startTrackingPoint.y - aPoint.y) > 3)) ||
            ([_selectedRowIndexes containsIndex:row]))
        {
            if ([_selectedRowIndexes containsIndex:row])
                _draggedRowIndexes = [[CPIndexSet alloc] initWithIndexSet:_selectedRowIndexes];
            else
                _draggedRowIndexes = [CPIndexSet indexSetWithIndex:row];

            //ask the datasource for the data
            var pboard = [CPPasteboard pasteboardWithName:CPDragPboard];

            if ([self canDragRowsWithIndexes:_draggedRowIndexes atPoint:aPoint] && [self _sendDataSourceWriteRowsWithIndexes:_draggedRowIndexes toPasteboard:pboard])
            {
                var currentEvent = [CPApp currentEvent],
                    offset = CGPointMakeZero(),
                    tableColumns = [_tableColumns objectsAtIndexes:_exposedColumns];

                // We deviate from the default Cocoa implementation here by asking for a view in stead of an image
                // We support both, but the view preferred over the image because we can mimic the rows we are dragging
                // by re-creating the data views for the dragged rows
                var view = [self dragViewForRowsWithIndexes:_draggedRowIndexes
                                               tableColumns:tableColumns
                                                      event:currentEvent
                                                     offset:offset];

                if (!view)
                {
                    var image = [self dragImageForRowsWithIndexes:_draggedRowIndexes
                                                     tableColumns:tableColumns
                                                            event:currentEvent
                                                           offset:offset];
                    view = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, [image size].height)];
                    [view setImage:image];
                }

                var bounds = [view bounds],
                    firstRowFrame = [self frameOfDataViewAtColumn:0 row:[_draggedRowIndexes firstIndex]],
                    viewLocation = CGPointMake(aPoint.x - CGRectGetWidth(bounds) / 2 + offset.x, aPoint.y - CGRectGetHeight(bounds) / 2 + offset.y + CGRectGetMinY(firstRowFrame));

                [self dragView:view at:viewLocation offset:CGPointMakeZero() event:[CPApp currentEvent] pasteboard:pboard source:self slideBack:YES];
                _startTrackingPoint = nil;

                return NO;
            }

            // The delegate disallowed the drag so clear the dragged row indexes
            _draggedRowIndexes = [CPIndexSet indexSet];
        }
        else if (ABS(_startTrackingPoint.x - aPoint.x) < 5 && ABS(_startTrackingPoint.y - aPoint.y) < 5)
            return YES;
    }

    _isSelectingSession = YES;
    if (row >= 0 && row !== _lastTrackedRowIndex)
    {
        _lastTrackedRowIndex = row;
        [self _updateSelectionWithMouseAtRow:row];
    }

    if ([self _dataSourceRespondsToSetObjectValueForTableColumnRow]
        && !_trackingPointMovedOutOfClickSlop)
    {
        var CLICK_SPACE_DELTA = 5.0; // Stolen from AppKit/Platform/DOM/CPPlatformWindow+DOM.j
        if (ABS(aPoint.x - _startTrackingPoint.x) > CLICK_SPACE_DELTA
            || ABS(aPoint.y - _startTrackingPoint.y) > CLICK_SPACE_DELTA)
        {
            _trackingPointMovedOutOfClickSlop = YES;
        }
    }

    return YES;
}

/*!
    @ignore
*/
- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _isSelectingSession = NO;

    var CLICK_TIME_DELTA = 1000,
        columnIndex = -1,
        column,
        rowIndex,
        shouldEdit = YES;

    _clickedRow = [self rowAtPoint:aPoint];
    _clickedColumn = [self columnAtPoint:aPoint];

    if ([self _dataSourceRespondsToWriteRowsWithIndexesToPasteboard])
    {
        rowIndex = _clickedRow;

        if (rowIndex !== -1)
        {
            if ([_draggedRowIndexes count] > 0)
            {
                _draggedRowIndexes = [CPIndexSet indexSet];
                return;
            }
            // if the table has drag support then we use mouseUp to select a single row.
             _previouslySelectedRowIndexes = [_selectedRowIndexes copy];
            [self _updateSelectionWithMouseAtRow:rowIndex];
        }
    }

    // Accept either tableView:setObjectValue:forTableColumn:row: delegate method, or a binding.
    if (!_isViewBased && mouseIsUp
        && !_trackingPointMovedOutOfClickSlop
        && ([[CPApp currentEvent] clickCount] > 1)
        && ([self _dataSourceRespondsToSetObjectValueForTableColumnRow]
            || [self infoForBinding:@"content"]))
    {
        columnIndex = _clickedColumn;

        if (columnIndex !== -1)
        {
            column = _tableColumns[columnIndex];

            if ([column isEditable])
            {
                rowIndex = [self rowAtPoint:aPoint];

                if (rowIndex !== -1)
                {
                    if ([self _sendDelegateShouldEditTableColumn:column row:rowIndex])
                    {
                        [self editColumn:columnIndex row:rowIndex withEvent:[CPApp currentEvent] select:YES];
                        return;
                    }
                }
            }
        }

    } //end of editing conditional

    //double click actions
    if ([[CPApp currentEvent] clickCount] === 2 && _doubleAction)
    {
        var target = _doubleClickTarget || _target,
            argument = [self infoForBinding:@"doubleClickArgument"] ? _doubleClickArgument : self;

        [CPApp sendAction:_doubleAction to:target from:argument];
    }
}

/*
    @ignore
*/
- (CPDragOperation)draggingEntered:(id)sender
{
    var location = [self convertPoint:[sender draggingLocation] fromView:nil],
        dropOperation = [self _proposedDropOperationAtPoint:location],
        row = [self _proposedRowAtPoint:location];

    if (_retargetedDropRow != nil)
        row = _retargetedDropRow;

    var draggedTypes = [self registeredDraggedTypes],
        count = [draggedTypes count],
        i = 0;

    for (; i < count; i++)
    {
        if ([[[sender draggingPasteboard] types] containsObject:[draggedTypes objectAtIndex: i]])
            return [self _sendDataSourceValidateDrop:sender proposedRow:row proposedDropOperation:dropOperation];
    }

    return CPDragOperationNone;
}

/*
    @ignore
*/
- (void)draggingExited:(id)sender
{
    [_dropOperationFeedbackView removeFromSuperview];
    [self _setDropTargetRow:CPNotFound];
}

/*
    @ignore
*/
- (void)draggingEnded:(id)sender
{
    [self _draggingEnded];
}

/*!
    @ignore
*/
- (void)_draggingEnded
{
    _retargetedDropOperation = nil;
    _retargetedDropRow = nil;
    _draggedRowIndexes = [CPIndexSet indexSet];
    [_dropOperationFeedbackView removeFromSuperview];
    [self _setDropTargetRow:CPNotFound];
}

/*
    @ignore
*/
- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

@end
