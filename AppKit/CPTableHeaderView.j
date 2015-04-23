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

@import "CPTableColumn.j"
@import "CPView.j"
@import "CPCursor.j"
@import "_CPImageAndTextView.j"

@class CPTableView

@global CPApp

@implementation _CPTableColumnHeaderView : CPView
{
    _CPImageAndTextView     _textField;
}

+ (CPString)defaultThemeClass
{
    return @"columnHeader";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"background-color": [CPNull null],
            @"text-alignment": CPLeftTextAlignment,
            @"line-break-mode": CPLineBreakByTruncatingTail,
            @"text-inset": CGInsetMakeZero(),
            @"text-color": [CPNull null],
            @"font": [CPNull null],
            @"text-shadow-color": [CPNull null],
            @"text-shadow-offset": CGSizeMakeZero()
        };
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
        [self _init];

    return self;
}

- (void)_init
{
    _textField = [[_CPImageAndTextView alloc] initWithFrame:
        CGRectMake(5.0, 0.0, CGRectGetWidth([self bounds]) - 10.0, CGRectGetHeight([self bounds]))];

    [_textField setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [_textField setLineBreakMode:CPLineBreakByTruncatingTail];
    [_textField setTextColor:[CPColor colorWithRed:51.0 / 255.0 green:51.0 / 255.0 blue:51.0 / 255.0 alpha:1.0]];
    [_textField setFont:[CPFont boldSystemFontOfSize:12.0]];
    [_textField setAlignment:CPLeftTextAlignment];
    [_textField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_textField setTextShadowColor:[CPColor whiteColor]];
    [_textField setTextShadowOffset:CGSizeMake(0,1)];

    [self addSubview:_textField];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];

    var inset = [self currentValueForThemeAttribute:@"text-inset"],
        bounds = [self bounds];

    [_textField setFrame:CGRectMake(inset.right, inset.top, bounds.size.width - inset.right - inset.left, bounds.size.height - inset.top - inset.bottom)];
    [_textField setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
    [_textField setFont:[self currentValueForThemeAttribute:@"font"]];
    [_textField setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
    [_textField setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
    [_textField setAlignment:[self currentValueForThemeAttribute:@"text-alignment"]];
    [_textField setLineBreakMode:[self currentValueForThemeAttribute:@"line-break-mode"]];
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
    [self setValue:aFont forThemeAttribute:@"font"];
}

- (CPFont)font
{
    return [self currentValueForThemeAttribute:@"font"];
}

- (void)setAlignment:(CPTextAlignment)alignment
{
    [self setValue:alignment forThemeAttribute:@"text-alignment"];
}

- (CPTextAlignment)alignment
{
    return [self currentValueForThemeAttribute:@"text-alignment"];
}

- (void)setLineBreakMode:(CPLineBreakMode)mode
{
    [self setValue:mode forThemeAttribute:@"line-break-mode"];
}

- (CPLineBreakMode)lineBreakMode
{
    return [self currentValueForThemeAttribute:@"line-break-mode"];
}

- (void)setTextColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-color"];
}

- (CPColor)textColor
{
    return [self currentValueForThemeAttribute:@"text-color"];
}

- (void)setTextShadowColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-shadow-color"];
}

- (CPColor)textShadowColor
{
    return [self currentValueForThemeAttribute:@"text-shadow-color"];
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

- (CPImage)_indicatorImage
{
    return [_textField imagePosition] === CPNoImage ? nil : [_textField image];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds];

    if (!CGRectIntersectsRect(aRect, bounds))
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        maxX = CGRectGetMaxX(bounds) - 0.5;

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:192.0 / 255.0 alpha:1.0]);

    CGContextBeginPath(context);

    CGContextMoveToPoint(context, maxX, CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, maxX, CGRectGetMaxY(bounds));

    CGContextStrokePath(context);
}

@end

var _CPTableColumnHeaderViewStringValueKey = @"_CPTableColumnHeaderViewStringValueKey",
    _CPTableColumnHeaderViewFontKey = @"_CPTableColumnHeaderViewFontKey",
    _CPTableColumnHeaderViewImageKey = @"_CPTableColumnHeaderViewImageKey",
    _CPTableColumnHeaderViewIsDraggingKey = @"_CPTableColumnHeaderViewIsDraggingKey";

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

CPTableHeaderViewDragColumnHeaderTag = 1;

var CPTableHeaderViewResizeZone = 3.0,
    CPTableHeaderViewDragTolerance = 10.0;

@implementation CPTableHeaderView : CPView
{
    CGPoint     _mouseDownLocation;
    CGPoint     _columnMouseDownLocation;
    CGPoint     _mouseEnterExitLocation;
    CGPoint     _previousTrackingLocation;

    int         _activeColumn;
    int         _pressedColumn;

    BOOL        _isResizing;
    BOOL        _isDragging;
    BOOL        _canDragColumn;

    CPView      _columnDragView;
    CPView      _columnDragHeaderView;
    CPView      _columnDragClipView;

    float       _columnOldWidth;

    CPTableView _tableView @accessors(property=tableView);
}

+ (CPString)defaultThemeClass
{
    return @"tableHeaderRow";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"background-color": [CPNull null],
            @"divider-color": [CPColor grayColor],
            @"divider-thickness": 1.0
        };
}

- (void)_init
{
    _mouseDownLocation = CGPointMakeZero();
    _columnMouseDownLocation = CGPointMakeZero();
    _mouseEnterExitLocation = CGPointMakeZero();
    _previousTrackingLocation = CGPointMakeZero();

    _activeColumn = -1;
    _pressedColumn = -1;

    _isResizing = NO;
    _isDragging = NO;
    _canDragColumn = NO;

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

// Checking Altered Columns

- (CPInteger)draggedColumn
{
    return _isDragging ? _activeColumn : -1;
}

- (float)draggedDistance
{
    if (_isDragging)
        return (CGRectGetMinX(_columnDragClipView) - _columnMouseDownLocation.x);
    else
        return -1;
}

- (CPInteger)resizedColumn
{
    if (_isResizing)
        return _activeColumn;
    else
        return -1;
}

// Utility Methods

- (CPInteger)columnAtPoint:(CGPoint)aPoint
{
    return [_tableView columnAtPoint:aPoint];
}

- (CGRect)headerRectOfColumn:(CPInteger)aColumnIndex
{
    var headerRect = [self bounds],
        columnRect = [_tableView rectOfColumn:aColumnIndex];

    headerRect.origin.x = CGRectGetMinX(columnRect);
    headerRect.size.width = CGRectGetWidth(columnRect);

    return headerRect;
}

// CPView Overrides

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];

    [[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)layoutSubviews
{
    var tableColumns = [_tableView tableColumns],
        count = [tableColumns count];

    for (var i = 0; i < count; i++)
    {
        var column = [tableColumns objectAtIndex:i],
            headerView = [column headerView],
            frame = [self headerRectOfColumn:i];

        [headerView setFrame:frame];

        if ([headerView superview] != self)
            [self addSubview:headerView];
    }
}

// CPResponder Overrides

- (void)mouseDown:(CPEvent)theEvent
{
    var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        adjustedLocation = CGPointMake(MAX(currentLocation.x - CPTableHeaderViewResizeZone, 0.0), currentLocation.y),
        columnIndex = [self columnAtPoint:adjustedLocation];

    if (columnIndex === -1)
        return;

    _mouseDownLocation = currentLocation;
    _activeColumn = columnIndex;
    _canDragColumn = YES;

        [_tableView _sendDelegateMouseDownInHeaderOfTableColumn:columnIndex];

    if ([self _shouldResizeTableColumn:columnIndex at:currentLocation])
        [self _startResizingTableColumn:columnIndex at:currentLocation];
    else
        [self _setPressedColumn:columnIndex];
}

- (void)mouseDragged:(CPEvent)theEvent
{
    var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        adjustedLocation = CGPointMake(MAX(currentLocation.x - CPTableHeaderViewResizeZone, 0.0), currentLocation.y),
        columnIndex = [self columnAtPoint:adjustedLocation];

    if (_isResizing)
    {
        [self _autoscroll:theEvent localLocation:currentLocation];
        [self _continueResizingTableColumn:_activeColumn at:currentLocation];
    }
    else if (_isDragging)
    {
        // Disable autoscrolling until it behaves correctly.
        //[self _autoscroll:theEvent localLocation:currentLocation];
        [self _dragTableColumn:_activeColumn to:currentLocation];
    }
    else // tracking a press, could become a drag
    {
        if (CGRectContainsPoint([self headerRectOfColumn:_activeColumn], currentLocation))
        {
            if ([self _shouldDragTableColumn:columnIndex at:currentLocation])
                [self _startDraggingTableColumn:columnIndex at:currentLocation];
            else
                [self _setPressedColumn:_activeColumn];
        }
        else
            [self _setPressedColumn:-1];
    }
}

- (void)mouseUp:(CPEvent)theEvent
{
    if (_isResizing)
    {
        [self _stopResizingTableColumn:_activeColumn];
    }
    else if (_isDragging)
    {
        [self _stopDraggingTableColumn:_activeColumn];
    }
    else if (_activeColumn != -1)
    {
        var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

        if (CGRectContainsPoint([self headerRectOfColumn:_activeColumn], currentLocation))
            [_tableView _didClickTableColumn:_activeColumn modifierFlags:[theEvent modifierFlags]];
    }

    [self _setPressedColumn:-1];
    [self _updateResizeCursor:[CPApp currentEvent]];

    _activeColumn = -1;
}

- (void)mouseEntered:(CPEvent)theEvent
{
    var location = [theEvent globalLocation];

    if (CGPointEqualToPoint(location, _mouseEnterExitLocation))
        return;

    _mouseEnterExitLocation = location;

    [self _updateResizeCursor:theEvent];
}

- (void)mouseMoved:(CPEvent)theEvent
{
    [self _updateResizeCursor:theEvent];
}

- (void)mouseExited:(CPEvent)theEvent
{
    var location = [theEvent globalLocation];

    if (CGPointEqualToPoint(location, _mouseEnterExitLocation))
        return;

    _mouseEnterExitLocation = location;

    // FIXME: we should use CPCursor push/pop (if previous currentCursor != arrow).
    [[CPCursor arrowCursor] set];
}

@end

@implementation CPTableHeaderView (CPTableHeaderViewPrivate)

- (CGRect)_cursorRectForColumn:(CPInteger)column
{
    if (column == -1 || !([_tableView._tableColumns[column] resizingMask] & CPTableColumnUserResizingMask))
        return CGRectMakeZero();

    var rect = [self headerRectOfColumn:column];

    rect.origin.x = (CGRectGetMaxX(rect) - CPTableHeaderViewResizeZone) - 1.0;
    rect.size.width = (CPTableHeaderViewResizeZone * 2.0) + 1.0;  // + 1 for resize line

    return rect;
}

- (void)_setPressedColumn:(CPInteger)column
{
    if (_pressedColumn === column)
        return;

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
    else
    {
        // Once the mouse leaves the pressed column, it can no longer drag
        _canDragColumn = NO;
    }

    _pressedColumn = column;
}

- (BOOL)_shouldDragTableColumn:(CPInteger)aColumnIndex at:(CGPoint)aPoint
{
    return _canDragColumn && [_tableView allowsColumnReordering] && ABS(aPoint.x - _mouseDownLocation.x) >= CPTableHeaderViewDragTolerance;
}

- (void)_autoscroll:(CPEvent)theEvent localLocation:(CGPoint)theLocation
{
    // Constrain the y coordinate so we don't autoscroll vertically
    var constrainedLocation = CGPointMake(theLocation.x, CGRectGetMinY([_tableView visibleRect])),
        constrainedEvent = [CPEvent mouseEventWithType:CPLeftMouseDragged
                                             location:[self convertPoint:constrainedLocation toView:nil]
                                        modifierFlags:[theEvent modifierFlags]
                                            timestamp:[theEvent timestamp]
                                         windowNumber:[theEvent windowNumber]
                                              context:nil
                                          eventNumber:0
                                           clickCount:[theEvent clickCount]
                                             pressure:[theEvent pressure]];

    [self autoscroll:constrainedEvent];
    [_tableView autoscroll:constrainedEvent];
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

- (CGPoint)_constrainDragPoint:(CGPoint)aPoint
{
    // This effectively clamps the value between the minimum and maximum
    var visibleRect = [_tableView visibleRect],
        lastColumnRect = [self _headerRectOfLastVisibleColumn],
        activeColumnRect = [self headerRectOfColumn:_activeColumn],
        maxX = CGRectGetMaxX(lastColumnRect) - CGRectGetWidth(activeColumnRect) - CGRectGetMinX(visibleRect),
        point = CGPointMake(MAX(MIN(aPoint.x, maxX), -CGRectGetMinX(visibleRect)), aPoint.y);

    return point;
}

- (void)_moveColumn:(CPInteger)aFromIndex toColumn:(CPInteger)aToIndex
{
    [_tableView moveColumn:aFromIndex toColumn:aToIndex];
    _activeColumn = aToIndex;
    _pressedColumn = _activeColumn;

    [_tableView _setDraggedColumn:_activeColumn];

    [self setNeedsDisplay:YES];
}

- (BOOL)isDragging
{
    return _isDragging;
}

- (void)_startDraggingTableColumn:(CPInteger)aColumnIndex at:(CGPoint)aPoint
{
    _isDragging = YES;
    _columnDragView = [_tableView _dragViewForColumn:aColumnIndex];
    _previousTrackingLocation = aPoint;

    // Create a new clip view for the drag view that clips to the header + visible content
    var headerHeight = CGRectGetHeight([self frame]),
        scrollView = [self enclosingScrollView],
        contentFrame = [[scrollView contentView] frame];

    contentFrame.origin.y -= headerHeight;
    contentFrame.size.height += headerHeight;

    _columnDragClipView = [[CPView alloc] initWithFrame:contentFrame];

    [_columnDragClipView addSubview:_columnDragView];

    // Insert the clip view above the table header (and content)
    [scrollView addSubview:_columnDragClipView positioned:CPWindowAbove relativeTo:self];

    // Hide the underlying column header subviews, we just want to draw the chrome
    var headerView = [[[_tableView tableColumns] objectAtIndex:aColumnIndex] headerView];

    [[headerView subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:YES];

    // The underlying column header shows normal state
    [headerView unsetThemeState:CPThemeStateHighlighted | CPThemeStateSelected];

    // Keep track of the location within the column header where the original mousedown occurred
    _columnDragHeaderView = [_columnDragView viewWithTag:CPTableHeaderViewDragColumnHeaderTag];

    _columnMouseDownLocation = [self convertPoint:_mouseDownLocation toView:_columnDragHeaderView];

    [_tableView _setDraggedColumn:aColumnIndex];

    [[CPCursor closedHandCursor] set];

    [self setNeedsDisplay:YES];
}

- (void)_dragTableColumn:(CPInteger)aColumnIndex to:(CGPoint)aPoint
{
    var delta = aPoint.x - _previousTrackingLocation.x,
        columnPoint = [_columnDragHeaderView convertPoint:aPoint fromView:self];

    // Only move if the mouse is past the original click point in the direction of movement
    if ((delta > 0 && columnPoint.x > _columnMouseDownLocation.x) || (delta < 0 && columnPoint.x < _columnMouseDownLocation.x))
    {
        var dragFrame = [_columnDragView frame],
            newOrigin = [self _constrainDragPoint:CGPointMake(CGRectGetMinX(dragFrame) + delta, CGRectGetMinY(dragFrame))];

        [_columnDragView setFrameOrigin:newOrigin];

        // When the edge of the dragged column passes the midpoint of an adjacent column, they swap
        var hoverPoint = CGPointMakeCopy(aPoint);

        // The drag frame is in content view coordinates, we need it to be in our coordinates
        dragFrame = [self convertRect:dragFrame fromView:[_columnDragView superview]];

        if (delta > 0)
            hoverPoint.x = CGRectGetMaxX(dragFrame);
        else
            hoverPoint.x = CGRectGetMinX(dragFrame);

        var hoveredColumn = [self columnAtPoint:hoverPoint];

        if (hoveredColumn !== -1)
        {
            var columnRect = [self headerRectOfColumn:hoveredColumn],
                columnCenterPoint = CGPointMake(CGRectGetMidX(columnRect), CGRectGetMidY(columnRect));

            if (hoveredColumn < _activeColumn && hoverPoint.x < columnCenterPoint.x)
                [self _moveColumn:_activeColumn toColumn:hoveredColumn];
            else if (hoveredColumn > _activeColumn && hoverPoint.x > columnCenterPoint.x)
                [self _moveColumn:_activeColumn toColumn:hoveredColumn];
        }
    }

    _previousTrackingLocation = aPoint;
}

- (void)_stopDraggingTableColumn:(CPInteger)aColumnIndex
{
    _isDragging = NO;

    [_columnDragClipView removeFromSuperview];
    [_tableView _setDraggedColumn:-1];

    var headerView = [[[_tableView tableColumns] objectAtIndex:aColumnIndex] headerView];

    [[headerView subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:NO];

    if (_tableView._draggedColumnIsSelected)
        [headerView setThemeState:CPThemeStateSelected];

    var columnRect = [_tableView rectOfColumn:aColumnIndex];

    [_tableView _reloadDataViews];
    [[_tableView headerView] setNeedsLayout];

    [[CPCursor arrowCursor] set];
}

- (BOOL)_shouldResizeTableColumn:(CPInteger)aColumnIndex at:(CGPoint)aPoint
{
    if (_isResizing)
        return YES;

    return [_tableView allowsColumnResizing] && CGRectContainsPoint([self _cursorRectForColumn:aColumnIndex], aPoint);
}

- (void)_startResizingTableColumn:(CPInteger)aColumnIndex at:(CGPoint)aPoint
{
    _isResizing = YES;
    _previousTrackingLocation = aPoint;
    _activeColumn = aColumnIndex;

    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex];

    _columnOldWidth = [tableColumn width];

    [tableColumn setDisableResizingPosting:YES];
    [_tableView setDisableAutomaticResizing:YES];
}

- (void)_continueResizingTableColumn:(CPInteger)aColumnIndex at:(CGPoint)aPoint
{
    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex],
        delta = aPoint.x - _previousTrackingLocation.x,
        spacing = [_tableView intercellSpacing].width,
        newWidth = [tableColumn width] + spacing + delta,
        minWidth = [tableColumn minWidth] + spacing,
        maxWidth = [tableColumn maxWidth] + spacing;

    if (newWidth <= minWidth)
        [[CPCursor resizeRightCursor] set];
    else if (newWidth >= maxWidth)
        [[CPCursor resizeLeftCursor] set];
    else
        [[CPCursor resizeLeftRightCursor] set];

    var columnRect = [_tableView rectOfColumn:aColumnIndex],
        columnWidth = CGRectGetWidth(columnRect);

    if ((delta > 0 && columnWidth == maxWidth) || (delta < 0 && columnWidth == minWidth))
        return;

    var columnMinX = CGRectGetMinX(columnRect),
        columnMaxX = CGRectGetMaxX(columnRect);

    if ((delta > 0 && aPoint.x > columnMaxX) || (delta < 0 && aPoint.x < columnMaxX))
    {
        [tableColumn setWidth:newWidth - spacing];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    _previousTrackingLocation = aPoint;
}

- (void)_stopResizingTableColumn:(CPInteger)aColumnIndex
{
    var tableColumn = [[_tableView tableColumns] objectAtIndex:aColumnIndex];

    if ([tableColumn width] != _columnOldWidth)
        [_tableView _didResizeTableColumn:tableColumn oldWidth:_columnOldWidth];

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
        mouseOverLocation = CGPointMake(MAX(mouseLocation.x - CPTableHeaderViewResizeZone, 0.0), mouseLocation.y),
        overColumn = [self columnAtPoint:mouseOverLocation];

    if (overColumn >= 0 && CGRectContainsPoint([self _cursorRectForColumn:overColumn], mouseLocation))
    {
        var tableColumn = [[_tableView tableColumns] objectAtIndex:overColumn],
            spacing = [_tableView intercellSpacing].width,
            width = [tableColumn width];

        if (width <= [tableColumn minWidth])
            [[CPCursor resizeRightCursor] set];
        else if (width >= [tableColumn maxWidth])
            [[CPCursor resizeLeftCursor] set];
        else
            [[CPCursor resizeLeftRightCursor] set];
    }
    else
        [[CPCursor arrowCursor] set];
}

@end // CPTableView (CPTableViewPrivate)

var CPTableHeaderViewTableViewKey = @"CPTableHeaderViewTableViewKey";

@implementation CPTableHeaderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        _tableView = [aCoder decodeObjectForKey:CPTableHeaderViewTableViewKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_tableView forKey:CPTableHeaderViewTableViewKey];
}

@end
