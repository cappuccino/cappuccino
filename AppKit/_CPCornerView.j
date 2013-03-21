/*
 * _CPCornerView.j
 * AppKit
 *
 * Created by Ross Boucher.
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

@implementation _CPCornerView : CPView
{
}

+ (CPString)defaultThemeClass
{
    return @"cornerview";
}

+ (id)themeAttributes
{
    return @{
        @"background-color": [CPNull null],
        @"divider-color": [CPNull null],
    };
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        color = [self currentValueForThemeAttribute:@"divider-color"];

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:@"divider-color"]);

    CGContextMoveToPoint(context, CGRectGetMinX(aRect) + 0.5, ROUND(CGRectGetMinY(aRect)));
    CGContextAddLineToPoint(context, CGRectGetMinX(aRect) + 0.5, ROUND(CGRectGetMaxY(aRect)) - 1.0);

    CGContextClosePath(context);
    CGContextStrokePath(context);
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (void)_init
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _init];

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self _init];

    return self;
}

@end
