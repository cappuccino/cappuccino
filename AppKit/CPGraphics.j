/*
 * CPGraphics.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

@import "CPColor.j"
@import "CPGraphicsContext.j"

#include "CoreGraphics/CGGeometry.h"


function CPDrawGrayBezel(aRect)
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:142.0/255.0 alpha:1.0]);

    var y = _CGRectGetMinY(aRect) + 0.5;

    CGContextMoveToPoint(context, _CGRectGetMinX(aRect), y);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect) + 1.0, y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:192.0/255.0 alpha:1.0]);
    CGContextMoveToPoint(context, _CGRectGetMinX(aRect) + 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:142.0/255.0 alpha:1.0]);
    CGContextMoveToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect), y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:190.0/255.0 alpha:1.0]);

    var x = _CGRectGetMaxX(aRect) - 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMinY(aRect) + 1.0);
    CGContextAddLineToPoint(context, x, _CGRectGetMaxY(aRect));

    CGContextMoveToPoint(context, x - 0.5, _CGRectGetMaxY(aRect) - 0.5);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect), _CGRectGetMaxY(aRect) - 0.5);

    x = _CGRectGetMinX(aRect) + 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMaxY(aRect));
    CGContextAddLineToPoint(context, x, _CGRectGetMinY(aRect) + 1.0);

    CGContextStrokePath(context);
}

function CPDrawGroove(aRect, drawTopBorder)
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:159.0/255.0 alpha:1.0]);

    var y = _CGRectGetMinY(aRect) + 0.5;

    CGContextMoveToPoint(context, _CGRectGetMinX(aRect), y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect), y);

    var x = _CGRectGetMaxX(aRect) - 1.5;

    CGContextMoveToPoint(context, x, _CGRectGetMinY(aRect) + 2.0);
    CGContextAddLineToPoint(context, x, _CGRectGetMaxY(aRect) - 1.0);

    y = _CGRectGetMaxY(aRect) - 1.5;

    CGContextMoveToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect) + 2.0, y);

    x = _CGRectGetMinX(aRect) + 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMaxY(aRect));
    CGContextAddLineToPoint(context, x, _CGRectGetMinY(aRect));

    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);

    var rect = _CGRectOffset(aRect, 1.0, 1.0);

    rect.size.width -= 1.0;
    rect.size.height -= 1.0;
    CGContextStrokeRect(context, _CGRectInset(rect, 0.5, 0.5));

    if (drawTopBorder)
    {
        CGContextBeginPath(context);
        CGContextSetStrokeColor(context, [CPColor colorWithWhite:192.0/255.0 alpha:1.0]);

        y = _CGRectGetMinY(aRect) + 2.5;

        CGContextMoveToPoint(context, _CGRectGetMinX(aRect) + 2.0, y);
        CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect) - 2.0, y);
        CGContextStrokePath(context);
    }
}
