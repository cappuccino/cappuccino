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
@import "CPTableView.j"
@import "CPView.j"
@import <AppKit/CGGradient.j>

var _headerGradient = nil,
    _selectedHeaderGradient = nil,
    _pressedHeaderGradient = nil,
    _selectedPressedHeaderGradient = nil,
    
    supportsCanvasGradient = NO;

@implementation _CPTableColumnHeaderView : CPView
{
    BOOL        _isPressed;
    CPTextField _textField;
}

+ (void)initialize
{
    supportsCanvasGradient = CPFeatureIsCompatible(CPHTMLCanvasFeature);
}

+ (CGGradient)headerGradient
{
    if (!_headerGradient)
        _headerGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),[1.0,1.0,1.0,1.0,0.929,0.929,0.929,1.0], [0.3,1], 2);
        
    return _headerGradient;
}

+ (CGGradient)selectedHeaderGradient
{
    if (!_selectedHeaderGradient)
        _selectedHeaderGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [0.804,0.851,0.918,1.0,0.655,0.718,0.8,1.0], [0.3,1], 2);
        
    return _selectedHeaderGradient;
}

+ (CGGradient)pressedHeaderGradient
{
    if (!_pressedHeaderGradient)
        _pressedHeaderGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),[0.929,0.929,0.929,1.0,1.0,1.0,1.0,1.0], [0.3,1], 2);
        
    return _pressedHeaderGradient;
}

+ (CGGradient)selectedPressedHeaderGradient
{
    if (!_selectedPressedHeaderGradient)
        _selectedPressedHeaderGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [0.655,0.718,0.8,1.0,0.804,0.851,0.918,1.0], [0.3,1], 2);
        
    return _selectedPressedHeaderGradient;
}

- (void)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {   
        _isPressed = NO;        
        _textField = [[CPTextField alloc] initWithFrame:[self bounds]];
        [_textField setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        [self addSubview:_textField];
        
        if (!supportsCanvasGradient)
             [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 22.0))]];
            
        //[self setValue:headerColor forThemeAttribute:@"background-color" inState:CPThemeStateNormal];
        //[self setValue:headerHighlightedColor forThemeAttribute:@"background-color" inState:CPThemeStateHighlighted];
    }
    
    return self;
}

- (void)setPressed:(BOOL)flag
{
    _isPressed = flag;
    [self setNeedsDisplay:YES];
}

- (BOOL)setThemeState:(CPThemeState)aState
{
    if (supportsCanvasGradient)
        [super setThemeState:aState];
    else if (aState & CPThemeStateHighlighted)
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview-highlighted.png", CGSizeMake(1.0, 22.0))]];
}

- (BOOL)unsetThemeState:(CPThemeState)aState
{
    if (supportsCanvasGradient)
        [super unsetThemeState:aState];
    else if (aState & CPThemeStateHighlighted)
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 22.0))]];
}

- (void)setStringValue:(CPString)string
{
    [_textField setStringValue:string];
}

- (CPString)stringValue
{
    return [_textField stringValue];
}

- (void)textField
{
    return _textField;
}

- (void)sizeToFit
{
}

- (void)drawRect:(CGRect)rect
{
    if (!supportsCanvasGradient)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        isSelected = ([self themeState] & CPThemeStateSelected);

    if (_isPressed && isSelected)
        gradient = [_CPTableColumnHeaderView selectedPressedHeaderGradient];
    else if (isSelected)
        gradient = [_CPTableColumnHeaderView selectedHeaderGradient];
    else if (_isPressed)
        gradient = [_CPTableColumnHeaderView pressedHeaderGradient];
    else 
        gradient = [_CPTableColumnHeaderView headerGradient];
    
    CGContextBeginPath(context);
    CGContextAddRect(context, bounds);
    CGContextDrawLinearGradient(context, gradient, CGPointMakeZero(), CGPointMake(0, CGRectGetHeight(bounds)), 0);
    CGContextClosePath(context);
}

@end

@implementation CPTableHeaderView : CPView
{
    int _resizedColumn @accessors(readonly, property=resizedColumn);
    int _draggedColumn @accessors(readonly, property=draggedColumn);
    int _pressedColumn @accessors(readonly, property=pressedColumn);
    
    float _draggedDistance @accessors(readonly, property=draggedDistance);
    
    CPTableView _tableView @accessors(property=tableView);
}

- (void)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _resizedColumn = CPNotFound;
        _draggedColumn = CPNotFound;
        _pressedColumn = CPNotFound;
        _draggedDistance = 0.0;
    }

    return self;
}

- (int)columnAtPoint:(CGPoint)aPoint
{
    if (!CGRectContainsPoint([self bounds], aPoint))
        return CPNotFound;

    // at this point, we can essentially ignore height, because all columns have equal heights
    // and that height is equal to the height of our own bounds, which we know we are inside of

    var index = 0,
        count = [[_tableView tableColumns] count],
        tableSpacing = [_tableView intercellSpacing],
        tableColumns = [_tableView tableColumns],
        leftOffset = 0,
        pointX = aPoint.x;

    for (; index < count; index++)
    {
        var width = [tableColumns[index] width] + tableSpacing.width;

        if (pointX >= leftOffset && pointX < leftOffset + width)
            return index;

        leftOffset += width;
    }

    return CPNotFound;
}

- (CGRect)headerRectOfColumn:(int)aColumnIndex
{
    var tableColumns = [_tableView tableColumns],
        tableSpacing = [_tableView intercellSpacing],
        bounds = [self bounds];

    if (aColumnIndex < 0 || aColumnIndex > [tableColumns count])
        [CPException raise:"invalid" reason:"tried to get headerRectOfColumn: on invalid column"];

    bounds.size.width = [tableColumns[aColumnIndex] width] + tableSpacing.width;

    while (--aColumnIndex >= 0)
        bounds.origin.x += [tableColumns[aColumnIndex] width] + tableSpacing.width;

    return bounds;
}

- (CPRect)_resizeRectBeforeColumn:(CPInteger)column
{
    var rect = [self headerRectOfColumn:column];

    rect.origin.x -= 10;
    rect.size.width = 20;

    return rect;
}

- (void)_updatePressed:(BOOL)flag
{
    var headerView = [_tableView._tableColumns[_pressedColumn] headerView];
    if ([headerView respondsToSelector:@selector(setPressed:)])
        [headerView setPressed:flag];
}

- (void)mouseDown:(CPEvent)theEvent
{
    var location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        aPoint = CGPointMakeCopy(location),
        clickedColumn = [self columnAtPoint:aPoint];    
    
    if (clickedColumn == -1)
        return;
        
    // Error, can't find var CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_ !?
    if (_tableView._implementedDelegateMethods & (1 << 6))
        [[_tableView delegate] tableView:_tableView
          mouseDownInHeaderOfTableColumn:[[_tableView tableColumns] objectAtIndex:clickedColumn]];
    
    _pressedColumn = clickedColumn;
    [self _updatePressed:YES];
}

- (void)mouseUp:(CPEvent)theEvent
{
    var location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        clickedColumn = [self columnAtPoint:location];

    if (clickedColumn == -1)
        return;

    if (_pressedColumn != CPNotFound)
    {
        [self _updatePressed:NO];
        _pressedColumn = CPNotFound;
    }

    if ([_tableView allowsColumnSelection])
    {        
        if ([theEvent modifierFlags] & CPCommandKeyMask)
        {
            if ([_tableView isColumnSelected:clickedColumn])
                [_tableView deselectColumn:clickedColumn];
            else if ([_tableView allowsMultipleSelection] == YES)
                [_tableView selectColumnIndexes:[CPIndexSet indexSetWithIndex:clickedColumn]  byExtendingSelection:YES];
        }
        else if ([theEvent modifierFlags] & CPShiftKeyMask)
        {
        // should be from clickedColumn to lastClickedColum with extending:(direction == previous selection)
            var selectedIndexes = [_tableView selectedColumnIndexes],
                startColumn = MIN(clickedColumn, [selectedIndexes lastIndex]),
                endColumn = MAX(clickedColumn, [selectedIndexes firstIndex]);
        
            [_tableView selectColumnIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(startColumn, endColumn - startColumn + 1)] byExtendingSelection:YES];
        }
        else
            [_tableView selectColumnIndexes:[CPIndexSet indexSetWithIndex:clickedColumn] byExtendingSelection:NO];
    }
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
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        exposedColumnIndexes = [_tableView columnIndexesInRect:aRect],
        columnsArray = [],
        tableColumns = [_tableView tableColumns],
        exposedTableColumns = _tableView._exposedColumns,
        firstIndex = [exposedTableColumns firstIndex],
        exposedRange = CPMakeRange(firstIndex, [exposedTableColumns lastIndex] - firstIndex + 1);

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColor(context, [_tableView gridColor]);

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
            
        columnMaxX = CGRectGetMaxX(columnToStroke);
        
        CGContextMoveToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(CGRectGetMinY(columnToStroke)));
        CGContextAddLineToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(CGRectGetMaxY(columnToStroke)) - 1);
    }
    
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    var maxY = CGRectGetMaxY([self bounds]);
    // draw normal gradient for remaining space
    if (supportsCanvasGradient)
    {
        aRect.origin.x = columnMaxX - 0.5;
        aRect.size.width -= columnMaxX;
        CGContextBeginPath(context);
        CGContextAddRect(context, CGRectMake(columnMaxX + 1, 0, CGRectGetMaxX([self bounds]) - columnMaxX, CGRectGetHeight([self bounds])));
        CGContextClosePath(context);    
        CGContextDrawLinearGradient(context, [_CPTableColumnHeaderView headerGradient], CGPointMake(0,0), CGPointMake(0, maxY - 1),0);
    }   
   
    // Draw bottom line
    CGContextBeginPath(context);    
    CGContextMoveToPoint(context, 0, maxY - 0.5);
    CGContextAddLineToPoint(context, CGRectGetMaxX([self bounds]), maxY - 0.5);
    CGContextClosePath(context);
    CGContextStrokePath(context);   
}

@end
