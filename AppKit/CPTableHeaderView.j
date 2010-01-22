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


@implementation CPTableHeaderView : CPView
{
    int _resizedColumn @accessors(readonly, property=resizedColumn);
    int _draggedColumn @accessors(readonly, property=draggedColumn);
    
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

- (void)layoutSubviews
{
    var tableColumns    = [_tableView tableColumns],
        count = [tableColumns count],
        columnRect = [self bounds],
        spacing = [_tableView intercellSpacing];
 
    for (i = 0; i < count; ++i) 
    {
        var column = [tableColumns objectAtIndex:i],
            headerView = [column headerView];

        columnRect.size.width = [column width] + spacing.width;

        [headerView setFrame:columnRect];

        columnRect.origin.x += [column width] + spacing.width;

        [self addSubview:headerView];
    }
}

- (void)drawRect:(CGRect)aRect
{
    [[_tableView gridColor] setStroke];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        exposedColumnIndexes = exposedColumnIndexes = [_tableView columnIndexesInRect:aRect],
        columnsArray = [];

    [exposedColumnIndexes getIndexes:columnsArray maxCount:-1 inIndexRange:nil];

    var columnArrayIndex = 0,
        columnArrayCount = columnsArray.length;

    for(; columnArrayIndex < columnArrayCount; ++columnArrayIndex)
    {
        // grab each column rect and add horizontal lines
        var columnToStroke = [self headerRectOfColumn:columnArrayIndex];

        CGContextBeginPath(context);
        CGContextMoveToPoint(context, ROUND(columnToStroke.origin.x + columnToStroke.size.width) + 0.5, ROUND(columnToStroke.origin.y) + 0.5);
        CGContextAddLineToPoint(context, ROUND(columnToStroke.origin.x + columnToStroke.size.width) + 0.5, ROUND(columnToStroke.origin.y + columnToStroke.size.height) + 0.5);
        CGContextSetLineWidth(context, 1);
        CGContextStrokePath(context);
    }
}

@end
