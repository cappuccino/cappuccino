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

CPCalibratedWhiteColorSpace = @"CalibratedWhiteColorSpace";
CPCalibratedBlackColorSpace = @"CalibratedBlackColorSpace";
CPCalibratedRGBColorSpace   = @"CalibratedRGBColorSpace";
CPDeviceWhiteColorSpace     = @"DeviceWhiteColorSpace";
CPDeviceBlackColorSpace     = @"DeviceBlackColorSpace";
CPDeviceRGBColorSpace       = @"DeviceRGBColorSpace";
CPDeviceCMYKColorSpace      = @"DeviceCMYKColorSpace";
CPNamedColorSpace           = @"NamedColorSpace";
CPPatternColorSpace         = @"PatternColorSpace";
CPCustomColorSpace          = @"CustomColorSpace";

function CPDrawTiledRects(
   /* CGRect */ boundsRect,
   /* CGRect */ clipRect,
   /* CPRectEdge[] */ sides,
   /* float[] */ grays)
{
    if (sides.length != grays.length)
        [CPException raise:CPInvalidArgumentException reason:@"sides (length: " + sides.length + ") and grays (length: " + grays.length + ") must have the same length."];

    var colors = [];

    for (var i = 0; i < grays.length; ++i)
        colors.push([CPColor colorWithCalibratedWhite:grays[i] alpha:1.0]);

    return CPDrawColorTiledRects(boundsRect, clipRect, sides, colors);
}

function CPDrawColorTiledRects(
   /* CGRect */ boundsRect,
   /* CGRect */ clipRect,
   /* CPRectEdge[] */ sides,
   /* CPColor[] */ colors)
{
    if (sides.length != colors.length)
        [CPException raise:CPInvalidArgumentException reason:@"sides (length: " + sides.length + ") and colors (length: " + colors.length + ") must have the same length."];

    var resultRect = CGRectMakeCopy(boundsRect),
        slice = CGRectMakeZero(),
        remainder = CGRectMakeZero(),
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0);

    for (var sideIndex = 0; sideIndex < sides.length; ++sideIndex)
    {
        var side = sides[sideIndex];

        CGRectDivide(resultRect, slice, remainder, 1.0, side);
        resultRect = remainder;
        slice = CGRectIntersection(slice, clipRect);

        // Cocoa docs say that only slices that are within the clipRect are actually drawn
        if (CGRectIsEmpty(slice))
            continue;

        var minX,
            maxX,
            minY,
            maxY;

        if (side == CPMinXEdge || side == CPMaxXEdge)
        {
            // Make sure we have at least 1 pixel to draw a line
            if (CGRectGetWidth(slice) < 1.0)
                continue;

            minX = CGRectGetMinX(slice) + 0.5;
            maxX = minX;
            minY = CGRectGetMinY(slice);
            maxY = CGRectGetMaxY(slice);
        }
        else // CPMinYEdge || CPMaxYEdge
        {
            // Make sure we have at least 1 pixel to draw a line
            if (CGRectGetHeight(slice) < 1.0)
                continue;

            minX = CGRectGetMinX(slice);
            maxX = CGRectGetMaxX(slice);
            minY = CGRectGetMinY(slice) + 0.5;
            maxY = minY;
        }

        CGContextBeginPath(context);
        CGContextMoveToPoint(context, minX, minY);
        CGContextAddLineToPoint(context, maxX, maxY);
        CGContextSetStrokeColor(context, colors[sideIndex]);
        CGContextStrokePath(context);
    }

    CGContextRestoreGState(context);

    return resultRect;
}
