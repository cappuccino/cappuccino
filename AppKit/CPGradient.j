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

- (id)initWithColors:(CPArray)someColors
{
    var count = [someColors count];

    if (count < 2)
        [CPException raise:CPInvalidArgumentException reason:@"at least 2 colors required"];

    var distance = 1.0 / (count - 1),
        locations = [CPMutableArray array],
        location = 0.0;

    for (var i = 0; i < count; i++)
    {
        [locations addObject:location];
        location += distance;
    }

    return [self initWithColors:someColors atLocations:locations colorSpace:nil];
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
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, rect);
    CGContextAddRect(ctx, rect);

    var startPoint,
        endPoint;

    // Modulo of negative values doesn't work as expected in JS.
    angle = ((angle % 360.0) + 360.0) % 360.0;

    if (angle < 90.0)
        startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    else if (angle < 180.0)
        startPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    else if (angle < 270.0)
        startPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    else
        startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));

    // A line segment comes out of the starting point at the given angle, with the first colour
    // at the starting point and the last at the end. To do what drawInRect: is supposed to do
    // we want the opposite corner of the starting corner to just reach the final colour stop.
    // So when the angle isn't a right angle, the segment has to extend beyond the edge of the
    // rectangle just far enough. This is hard to describe without a picture but if we place
    // another line through the opposite corner at -90 degrees, it'll cross through our
    // gradient segment just where it should end and form a right triangle with the right edge.
    // of the rect. One leg of this triangle is how far the gradient line should stick out,
    // and the length of that leg is (in the first quadrant) width * cos(a) + height * sin(a).
    var radians = PI * angle / 180.0,
        length = ABS(CGRectGetWidth(rect) * COS(radians)) + ABS(CGRectGetHeight(rect) * SIN(radians));

    endPoint = CGPointMake(startPoint.x + length * COS(radians),
                           startPoint.y + length * SIN(radians));

    [self drawFromPoint:startPoint toPoint:endPoint options:CPGradientDrawsBeforeStartingLocation | CPGradientDrawsAfterEndingLocation];
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
