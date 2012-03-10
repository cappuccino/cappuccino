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
            colorspace = CGColorSpaceCreateDeviceRGB;
        while (count--)
            cgColors.push(CGColorCreate(colorspace, [someColors[count] components]));
        _gradient = CGGradientCreateWithColors(aColorSpace, cgColors, someLocations);
    }

    return self;
}

- (void)drawInRect:(CGRect)rect angle:(float)angle
{
    if (angle !== 0)
        [CPException raise:CPInvalidArgumentException reason:@"angle != 0 not yet implemented"];

    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(ctx);
    CGContextAddRect(ctx, rect);
    CGContextDrawLinearGradient(ctx, _gradient, rect.origin, CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)), 0);
    CGContextRestoreGState(ctx);

    //[self drawFromPoint:rect.origin toPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)) options:0];
}

@end
