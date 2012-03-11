/*
 * CPGradient.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2012, SlevenBits Ltd.
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

CPGradientDrawsBeforeStartingLocation   = kCGGradientDrawsBeforeStartLocation;
CPGradientDrawsAfterEndingLocation      = kCGGradientDrawsAfterEndLocation;

/*!
    A class for drawing linear and radial gradients with a convenient API.
*/
@implementation CPGradient : CPObject
{
    CGGradient _gradient;
}

- (id)initWithColors:(CPArray)someColors atLocations:(CPArray)someLocations colorSpace:(CPColorSpace)aColorSpace
{
    if (self = [super init])
    {
        var cgColors = [],
            count = [someColors count],
            colorSpace = [aColorSpace CGColorSpace] || CGColorSpaceCreateDeviceRGB;
        for (var i = 0; i < count; i++)
            cgColors.push(CGColorCreate(colorSpace, [someColors[i] components]));
        _gradient = CGGradientCreateWithColors(colorSpace, cgColors, someLocations);
    }

    return self;
}

- (void)drawInRect:(CGRect)rect angle:(float)angle
{
    if (angle !== 0)
        [CPException raise:CPInvalidArgumentException reason:@"angle != 0 not yet implemented"];

    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, rect);
    CGContextAddRect(ctx, rect);

    [self drawFromPoint:rect.origin toPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)) options:CPGradientDrawsBeforeStartingLocation | CPGradientDrawsAfterEndingLocation];
    CGContextRestoreGState(ctx);
}

- (void)drawFromPoint:(NSPoint)startingPoint toPoint:(NSPoint)endingPoint options:(NSGradientDrawingOptions)options
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    // TODO kCGGradientDrawsBeforeStartLocation and kCGGradientDrawsAfterEndLocation are not actually supported
    // by CGContextDrawLinearGradient yet.
    CGContextDrawLinearGradient(ctx, _gradient, startingPoint, endingPoint, options);
}

@end
