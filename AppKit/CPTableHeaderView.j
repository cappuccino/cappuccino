/*
 * CPTableHeaderView.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2009 280 North, Inc.
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

@import <Foundation/CPIndexSet.j>

@import "CPTableColumn.j"
@import "CPTableView.j"
@import "CPView.j"


@implementation _CPTableColumnHeaderView : CPView
{
    _CPImageAndTextView     _textField;
}

+ (CPString)defaultThemeClass
{
    return @"columnHeader";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], CGInsetMakeZero(), [CPNull null], [CPNull null], [CPNull null], CGSizeMakeZero()]
                                       forKeys:[@"background-color", @"text-alignment", @"text-inset", @"text-color", @"text-font", @"text-shadow-color", @"text-shadow-offset"]];
}

- (void)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self _init];

    return self;
}

- (void)_init
{
    _textField = [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];

    [_textField setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    [_textField setLineBreakMode:CPLineBreakByTruncatingTail];
    [_textField setAlignment:CPLeftTextAlignment];
    [_textField setVerticalAlignment:CPCenterVerticalTextAlignment];

    [self addSubview:_textField];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];

    var inset = [self currentValueForThemeAttribute:@"text-inset"],
        bounds = [self bounds];

    [_textField setFrame:_CGRectMake(inset.right, inset.top, bounds.size.width - inset.right - inset.left, bounds.size.height - inset.top - inset.bottom)];
    [_textField setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
    [_textField setFont:[self currentValueForThemeAttribute:@"text-font"]];
    [_textField setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
    [_textField setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
    [_textField setAlignment:[self currentValueForThemeAttribute:@"text-alignment"]];
}

- (void)setStringValue:(CPString)string
{
    [_textField setText:string];
}

- (CPString)stringValue
{
    return [_textField text];
}

- (void)textField
{
    return _textField;
}

- (void)sizeToFit
{
    [_textField sizeToFit];
}

- (void)setFont:(CPFont)aFont
{
    [_textField setFont:aFont];
}

- (void)_setIndicatorImage:(CPImage)anImage
{
	if (anImage)
	{
		[_textField setImage:anImage];
		[_textField setImagePosition:CPImageRight];
	}
	else
	{
		[_textField setImagePosition:CPNoImage];
	}
}

@end

var _CPTableColumnHeaderViewStringValueKey = @"_CPTableColumnHeaderViewStringValueKey",
    _CPTableColumnHeaderViewFontKey = @"_CPTableColumnHeaderViewFontKey",
    _CPTableColumnHeaderViewImageKey = @"_CPTableColumnHeaderViewImageKey";

@implementation _CPTableColumnHeaderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        [self _setIndicatorImage:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewImageKey]];
        [self setStringValue:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewStringValueKey]];
        [self setFont:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewFontKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:[_textField text] forKey:_CPTableColumnHeaderViewStringValueKey];
    [aCoder encodeObject:[_textField image] forKey:_CPTableColumnHeaderViewImageKey];
    [aCoder encodeObject:[_textField font] forKey:_CPTableColumnHeaderViewFontKey];
}

@end

@implementation CPTableHeaderView : CPView
{
    CGPoint                 _mouseDownLocation;
    CGPoint                 _previousTrackingLocation;
    int                     _activeColumn;
    int                     _pressedColumn;

    BOOL                    _isResizing;
    BOOL                    _isDragging;
    BOOL                    _isTrackingColumn;
    BOOL                    _drawsColumnLines;

    float                   _columnOldWidth;

    CPTableView             _tableView @accessors(property=tableView);
}

+ (CPString)defaultThemeClass
{
    return @"tableHeaderRow";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPColor grayColor]]
                                       forKeys:[@"background-color", @"divider-color"]];
}

- (void)_init
{
    _mouseDownLocation = _CGPointMakeZero();
    _previousTrackingLocation = _CGPointMakeZero();
    _activeColumn = -1;
    _pressedColumn = -1;

    _isResizing = NO;
    _isDragging = NO;
    _isTrackingColumn = NO;
    _drawsColumnLines = YES;

    _columnOldWidth = 0.0;

    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _init];

    return self;
}

- (int)columnAtPoint:(CGPoint)aPoint
{
    return [_tableView columnAtPoint:CGPointMake(aPoint.x, aPoint.y)];
}

- (CGRect)headerRectOfColumn:(int)aColumnIndex
{
    var headerRect = [self bounds],
        columnRect = [_tableView rectOfColumn:aColumnIndex];

    headerRect.origin.x = _CGRectGetMinX(columnRect);
    headerRect.size.width = _CGRectGetWidth(columnRect);

    return headerRect;
}

- (void)setDrawsColumnLines:(BOOL)aFlag
{
    _drawsColumnLines = aFlag;
}

- (BOOL)drawsColumnLines
{
    return _drawsColumnLines;
}

- (CGRect)_cursorRectForColumn:(int)column
{
    if (column == -1 || !([_tableView._tableColumns[column] resizingMask] & CPTableColumnUserResizingMask))
        return _CGRectMakeZero();

    var rect = [self headerRectOfColumn:column];

    rect.origin.x = _CGRectGetMaxX(rect) - 5;
    rect.size.width = 20;

    return rect;
}

- (void)_setPressedColumn:(CPInteger)column
{
    if (_pressedColumn != -1)
    {
        var headerView = [_tableView._tableColumns[_pressedColumn] headerView];
        [headerView unsetThemeState:CPThemeStateHighlighted];
    }

    if (column != -1)
    {
        var headerView = [_tableView._tableColumns[column] headerView];
        [headerView setThemeState:CPThemeStateHighlighted];
    }

    _pressedColumn = column;
}

- (void)mouseDown:(CPEvent)theEvent
{
    [self trackMouse:theEvent];
}

- (void)trackMouse:(CPEvent)theEvent
{
    var type = [theEvent type],
        currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    // Take the right columns resize tracking area into account
    currentLocation.x -= 5.0;

    var columnIndex = [self columnAtPoint:currentLocation],
        shouldResize = [self shouldResizeTableColumn:columnIndex at:_CGPointMake(currentLocation.x + 5.0, currentLocation.y)];

    if (type === CPLeftMouseUp)
    {
        if (shouldResize)
            [self stopResizingTableColumn:_activeColumn at:currentLocation];
        else if ([self _shouldStopTrackingTableColumn:columnIndex at:currentLocation])
        {
            [_tableView _didClickTableColumn:columnIndex modifierFlags:[theEvent modifierFlags]];
            [self stopTrackingTableColumn:columnIndex at:currentLocation];

            _isTrackingColumn = NO;
        }

        [self _updateResizeCursor:[CPApp currentEvent]];

        _activeColumn = CPNotFound;
        return;
    }

    if (type === CPLeftMouseDown)
    {
        if (columnIndex === -1)
            return;

        _mouseDownLocation = currentLocation;
        _activeColumn = columnIndex;

        [_tableView _sendDelegateDidMouseDownInHeader:columnIndex];

        if (shouldResize)
            [self startResizingTableColumn:columnIndex at:currentLocation];
        else
        {
            [self startTrackingTableColumn:columnIndex at:currentLocation];
            _isTrackingColumn = YES;
        }
    }
    else if (type === CPLeftMouseDragged)
    {
        if (shouldResize)
            [self continueResizingTableColumn:_activeColumn at:currentLocation];
        else
        {
            if (_activeColumn === columnIndex && _CGRectContainsPoint([self headerRectOfColumn:columnIndex], currentLocation))
            {
                if (_isTrackingColumn && _pressedColumn !== -1)
                {
                    if (![self continueTrackingTableColumn:columnIndex at:currentLocation])
                        return; // Stop tracking the column, because it's being dragged
                } else
                    [self startTrackingTableColumn:columnIndex at:currentLocation];

            } else if (_isTrackingColumn && _pressedColumn !== -1)
                [self stopTrackingTableColumn:_activeColumn at:currentLocation];
        }
    }

    _previousTrackingLocation = currentLocation;
    [CPApp setTarget:self selector:@selector(trackMouse:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)startTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    [self _setPressedColumn:aColumnIndex];
}

- (BOOL)continueTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    if ([self _shouldDragTableColumn:aColumnIndex at:aPoint])
    {
        var columnRect = [self headerRectOfColumn:aColumnIndex],
            offset = _CGPointMakeZero(),
            view = [_tableView _dragViewForColumn:aColumnIndex event:[CPApp currentEvent] offset:offset],
            viewLocation = _CGPointMakeZero();

        viewLocation.x = ( _CGRectGetMinX(columnRect) + offset.x ) + ( aPoint.x - _mouseDownLocation.x );
        viewLocation.y = _CGRectGetMinY(columnRect) + offset.y;

        [self dragView:view at:viewLocation offset:_CGSizeMakeZero() event:[CPApp currentEvent]
            pasteboard:[CPPasteboard pasteboardWithName:CPDragPboard] source:self slideBack:YES];

        return NO;
    }

    return YES;
}

- (BOOL)_shouldStopTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    return _isTrackingColumn && _activeColumn === aColumnIndex &&
        _CGRectContainsPoint([self headerRectOfColumn:aColumnIndex], aPoint);
}

- (void)stopTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    [self _setPressedColumn:CPNotFound];
    [self _updateResizeCursor:[CPApp currentEvent]];
}

- (BOOL)_shouldDragTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    return [_tableView allowsColumnReordering] && ABS(aPoint.x - _mouseDownLocation.x) >= 10.0;
}

- (CGRect)_headerRectOfLastVisibleColumn
{
    var tableColumns = [_tableView tableColumns],
        columnIndex = [tableColumns count];

    while (columnIndex--)
    {
        var tableColumn = [tableColumns objectAtIndex:columnIndex];

        if (![tableColumn isHidden])
            return [self headerRectOfColumn:columnIndex];
    }

    return nil;
}

- (void)_constrainDragView:(CPView)theDragView at:(CGPoint)aPoint
{
    var tableColumns = [_tableView tableColumns],
        lastColumnRect = [self _headerRectOfLastVisibleColumn],
        activeColumnRect = [self headerRectOfColumn:_activeColumn],
        dragWindow = [theDragView window],
        frame = [dragWindow frame];

    // Convert the frame origin from the global coordinate system to the windows' coordinate system
    frame.origin = [[self window] convertGlobalToBase:frame.origin];
    // the from the window to the view
    frame.origin = [self convertPoint:frame.origin fromView:nil];

    // This effectively clamps the value between the minimum and maximum
    frame.origin.x = MAX(0.0, MIN(_CGRectGetMinX(frame), _CGRectGetMaxX(lastColumnRect) - _CGRectGetWidth(activeColumnRect)));

    // Make sure the column cannot move vertically
    frame.origin.y = _CGRectGetMinY(lastColumnRect);

    // Convert the calculated origin back to the window coordinate system
    frame.origin = [self convertPoint:frame.origin toView:nil];
    // Then back to the global coordinate system
    frame.origin = [[self window] convertBaseToGlobal:frame.origin];

    [dragWindow setFrame:frame];
}

- (void)_moveColumn:(int)aFromIndex toColumn:(int)aToIndex
{
    [_tableView moveColumn:aFromIndex toColumn:aToIndex];
    _activeColumn = aToIndex;
    _pressedColumn = _activeColumn;
}

- (void)draggedView:(CPView)aView beganAt:(CGPoint)aPoint
{
    _isDragging = YES;

    var column = [[_tableView tableColumns] objectAtIndex:_activeColumn];

    [[column headerView] setHidden:YES];
    [_tableView _setDraggedColumn:column];

    [self setNeedsDisplay:YES];
}

- (void)draggedView:(CPView)aView movedTo:(CGPoint)aPoint
{
    [self _constrainDragView:aView at:aPoint];

    var dragWindow = [aView window],
        dragWindowFrame = [dragWindow frame];

    var hoverPoint = CGPointCreateCopy(aPoint);

    if (aPoint.x < _previousTrackingLocation.x)
        hoverPoint = _CGPointMake(_CGRectGetMinX(dragWindowFrame), _CGRectGetMinY(dragWindowFrame));
    else if (aPoint.x > _previousTrackingLocation.x)
        hoverPoint = _CGPointMake(_CGRectGetMaxX(dragWindowFrame), _CGRectGetMinY(dragWindowFrame));

    // Convert the hover point from the global coordinate system to windows' coordinate system
    hoverPoint = [[self window] convertGlobalToBase:hoverPoint];
    // then to the view
    hoverPoint = [self convertPoint:hoverPoint fromView:nil];

    var hoveredColumn = [self columnAtPoint:hoverPoint];

    if (hoveredColumn !== -1)
    {
        var columnRect = [self headerRectOfColumn:hoveredColumn],
            columnCenterPoint = [self convertPoint:CGPointMake(_CGRectGetMidX(columnRect), _CGRectGetMidY(columnRect)) fromView:self];
        if (hoveredColumn < _activeColumn && hoverPoint.x < columnCenterPoint.x)
            [self _moveColumn:_activeColumn toColumn:hoveredColumn];
        else if (hoveredColumn > _activeColumn && hoverPoint.x > columnCenterPoint.x)
            [self _moveColumn:_activeColumn toColumn:hoveredColumn];
    }

    _previousTrackingLocation = aPoint;
}

- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    _isDragging = NO;
    _isTrackingColumn = NO; // We need to do this explicitly because the mouse up section of trackMouse is never reached

    [_tableView _setDraggedColumn:nil];
    [[[[_tableView tableColumns] objectAtIndex:_activeColumn] headerView] setHidden:NO];
    [self stopTrackingTableColumn:_activeColumn at:aLocation];

    [self setNeedsDisplay:YES];
}

- (BOOL)shouldResizeTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    if (_isResizing)
        return YES;

    if (_isTrackingColumn)
        return NO;

    return [_tableView allowsColumnResizing] && _CGRectContainsPoint([self _cursorRectForColumn:aColumnIndex], aPoint);
}

- (void)startResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    _isResizing = YES;

    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex];

    [tableColumn setDisableResizingPosting:YES];
    [_tableView setDisableAutomaticResizing:YES];
}

- (void)continueResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex],
        newWidth = [tableColumn width] + aPoint.x - _previousTrackingLocation.x;

    if (newWidth < [tableColumn minWidth])
        [[CPCursor resizeRightCursor] set];
    else if (newWidth > [tableColumn maxWidth])
        [[CPCursor resizeLeftCursor] set];
    else
    {
        _tableView._lastColumnShouldSnap = NO;
        [tableColumn setWidth:newWidth];

        [[CPCursor resizeLeftRightCursor] set];
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
}

- (void)stopResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex];
    [tableColumn _postDidResizeNotificationWithOldWidth:_columnOldWidth];
    [tableColumn setDisableResizingPosting:NO];
    [_tableView setDisableAutomaticResizing:NO];

    _isResizing = NO;
}

- (void)_updateResizeCursor:(CPEvent)theEvent
{
    // never get stuck in resize cursor mode (FIXME take out when we turn on tracking rects)
    if (![_tableView allowsColumnResizing] || ([theEvent type] === CPLeftMouseUp && ![[self window] acceptsMouseMovedEvents]))
    {
        [[CPCursor arrowCursor] set];
        return;
    }

    var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        mouseOverLocation = CGPointMake(mouseLocation.x - 5, mouseLocation.y),
        overColumn = [self columnAtPoint:mouseOverLocation];

    if (overColumn >= 0 && _CGRectContainsPoint([self _cursorRectForColumn:overColumn], mouseLocation))
    {
        var tableColumn = [[_tableView tableColumns] objectAtIndex:overColumn],
            width = [tableColumn width];

        if (width == [tableColumn minWidth])
            [[CPCursor resizeRightCursor] set];
        else if (width == [tableColumn maxWidth])
            [[CPCursor resizeLeftCursor] set];
        else
            [[CPCursor resizeLeftRightCursor] set];
    }
    else
        [[CPCursor arrowCursor] set];
}

- (void)mouseEntered:(CPEvent)theEvent
{
    [self _updateResizeCursor:theEvent];
}

- (void)mouseMoved:(CPEvent)theEvent
{
    [self _updateResizeCursor:theEvent];
}

- (void)mouseExited:(CPEvent)theEvent
{
    // FIXME: we should use CPCursor push/pop (if previous currentCursor != arrow).
    [[CPCursor arrowCursor] set];
}

- (void)layoutSubviews
{
    var tableColumns = [_tableView tableColumns],
        count = [tableColumns count];

    for (var i = 0; i < count; i++)
    {
        var column = [tableColumns objectAtIndex:i],
            headerView = [column headerView];

        var frame = [self headerRectOfColumn:i];
        frame.size.height -= 0.5;
        if (i > 0)
        {
            frame.origin.x += 0.5;
            frame.size.width -= 1;
        }

        [headerView setFrame:frame];

        if([headerView superview] != self)
            [self addSubview:headerView];
    }

    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (void)drawRect:(CGRect)aRect
{
    if (!_tableView || ![self drawsColumnLines])
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        exposedColumnIndexes = [_tableView columnIndexesInRect:aRect],
        columnsArray = [],
        tableColumns = [_tableView tableColumns],
        exposedTableColumns = _tableView._exposedColumns,
        firstIndex = [exposedTableColumns firstIndex],
        exposedRange = CPMakeRange(firstIndex, [exposedTableColumns lastIndex] - firstIndex + 1);

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:@"divider-color"]);

    [exposedColumnIndexes getIndexes:columnsArray maxCount:-1 inIndexRange:exposedRange];

    var columnArrayIndex = 0,
        columnArrayCount = columnsArray.length,
        columnMaxX;

    CGContextBeginPath(context);
    for(; columnArrayIndex < columnArrayCount; columnArrayIndex++)
    {
        // grab each column rect and add vertical lines
        var columnIndex = columnsArray[columnArrayIndex],
            columnToStroke = [self headerRectOfColumn:columnIndex];

        columnMaxX = _CGRectGetMaxX(columnToStroke);

        CGContextMoveToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(_CGRectGetMinY(columnToStroke)));
        CGContextAddLineToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(_CGRectGetMaxY(columnToStroke)));
    }

    CGContextClosePath(context);
    CGContextStrokePath(context);

    /*if (_isDragging)
    {
        CGContextSetFillColor(context, [CPColor grayColor]);
        CGContextFillRect(context, [self headerRectOfColumn:_activeColumn])
    }*/
}

@end

var CPTableHeaderViewTableViewKey = @"CPTableHeaderViewTableViewKey",
    CPTableHeaderViewDrawsColumnLines = @"CPTableHeaderViewDrawsColumnLines";

@implementation CPTableHeaderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        _tableView = [aCoder decodeObjectForKey:CPTableHeaderViewTableViewKey];
        _drawsColumnLines = [aCoder decodeBoolForKey:CPTableHeaderViewDrawsColumnLines];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_tableView forKey:CPTableHeaderViewTableViewKey];
    [aCoder encodeBool:_drawsColumnLines forKey:CPTableHeaderViewDrawsColumnLines];
}

@end
