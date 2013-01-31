/*
 * _CPMenuItemSeparatorView.j
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

@import "CPView.j"

@class _CPMenuItemStandardView


@implementation _CPMenuItemSeparatorView : CPView
{
}

+ (id)view
{
    return [[self alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 10.0)];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self setAutoresizingMask:CPViewWidthSizable];

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];

    CGContextBeginPath(context);

    CGContextMoveToPoint(context, CGRectGetMinX(bounds), FLOOR(CGRectGetMidY(bounds)) - 0.5);
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), FLOOR(CGRectGetMidY(bounds)) - 0.5);

    CGContextSetStrokeColor(context, [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-item-separator-color" forClass:_CPMenuItemStandardView]);
    CGContextStrokePath(context);
}

@end
