/*
 * CPBezierPath.j
 *
 * Created by Ross Boucher.
 * Copyright 2009, 280 North, Inc.
 *
 * Adapted from Kevin Wojniak, portions Copyright 2009 Kevin Wojniak.
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
 * Copyright 2009 280 North, Inc.

 */

@import <Foundation/CPObject.j>

@import "CPGraphicsContext.j"


// Class defaults

var DefaultLineWidth = 1.0;


/*!
    @ingroup appkit
    @class CPBezierPath

    A CPBezierPath allows you to create paths for drawing to the screen using a simpler API than CoreGraphics.
    Paths can form any shape, including regular polgyons like squares and triangles; circles, arcs; or complex
    line segments.

    A path can be stroked and filled using the relevant method. The currently active fill and stroke color will
    be used, which can be set by calling setFill: and setStroke: on any CPColor object (or set: for both).
*/

@implementation CPBezierPath : CPObject
{
    CGPath  _path;
    float   _lineWidth;
}

/*!
    Create a new CPBezierPath object.
*/
+ (CPBezierPath)bezierPath
{
    return [[self alloc] init];
}

/*!
    Create a new CPBezierPath object initialized with an oval path drawn within a rectangular path.
*/
+ (CPBezierPath)bezierPathWithOvalInRect:(CGRect)rect
{
    var path = [self bezierPath];

    [path appendBezierPathWithOvalInRect:rect];

    return path;
}

/*!
    Create a new CPBezierPath object initialized with a rectangular path.
*/
+ (CPBezierPath)bezierPathWithRect:(CGRect)rect
{
    var path = [self bezierPath];

    [path appendBezierPathWithRect:rect];

    return path;
}

/*!
    Get default line width.
*/
+ (float)defaultLineWidth
{
    return DefaultLineWidth;
}

/*!
    Set default line width.
*/
+ (void)setDefaultLineWidth:(float)width
{
    DefaultLineWidth = width;
}

/*!
    Fill rectangular path with current fill color.
*/
+ (void)fillRect:(CGRect)aRect
{
    [[self bezierPathWithRect:aRect] fill];
}

/*!
    Using the current stroke color and default drawing attributes, strokes a counterclockwise path beginning at the rectangle's origin.
*/
+ (void)strokeRect:(CGRect)aRect
{
    [[self bezierPathWithRect:aRect] stroke];
}

/*!
    Using the current stroke color and default drawing attributes, strokes a line between two points.
*/
+ (void)strokeLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2
{
    var path = [self bezierPath];

    [path moveToPoint:point1];
    [path lineToPoint:point2];

    [path stroke];
}

/*!
    Create a new CPBezierPath object using the default line width.
*/
- (id)init
{
    if (self = [super init])
    {
        _path = CGPathCreateMutable();
        _lineWidth = [[self class] defaultLineWidth];
    }

    return self;
}

/*!
    Moves the current point to another location.
*/
- (void)moveToPoint:(CGPoint)point
{
    CGPathMoveToPoint(_path, nil, point.x, point.y);
}

/*!
    Append a straight line to the path.
*/
- (void)lineToPoint:(CGPoint)point
{
    CGPathAddLineToPoint(_path, nil, point.x, point.y);
}

/*!
    Add a cubic Bezier curve to the path.
*/
- (void)curveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2
{
    CGPathAddCurveToPoint(_path, nil, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);
}

/*!
    Create a line segment between the first and last points in the subpath, closing it.
*/
- (void)closePath
{
    CGPathCloseSubpath(_path);
}

/*!
    Draw a line along the path with the current stroke color and default drawing attributes.
*/
- (void)stroke
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, _path);
    CGContextSetLineWidth(ctx, [self lineWidth]);
    CGContextClosePath(ctx);
    CGContextStrokePath(ctx);
}

/*!
    Fill the path with the current fill color.
*/
- (void)fill
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, _path);
    CGContextSetLineWidth(ctx, [self lineWidth]);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

/*!
    Get the line width.
*/
- (float)lineWidth
{
    return _lineWidth;
}

/*!
    Set the line width.
*/
- (void)setLineWidth:(float)lineWidth
{
    _lineWidth = lineWidth;
}

/*!
    Get the total number of elements.
*/
- (unsigned)elementCount
{
    return _path.count;
}

/*!
    Check if receiver is empty, returns appropriate Boolean value.
*/
- (BOOL)isEmpty
{
    return CGPathIsEmpty(_path);
}

/*!
    Get the current point.
*/
- (CGPoint)currentPoint
{
    return CGPathGetCurrentPoint(_path);
}

/*!
    Append a series of line segments.
*/
- (void)appendBezierPathWithPoints:(CPArray)points count:(unsigned)count
{
    CGPathAddLines(_path, nil, points, count);
}

/*!
    Append a rectangular path.
*/
- (void)appendBezierPathWithRect:(CGRect)rect
{
    CGPathAddRect(_path, nil, rect);
}

/*!
    Append an oval path; oval is drawn within the rectangular path.
*/
- (void)appendBezierPathWithOvalInRect:(CGRect)rect
{
    CGPathAddPath(_path, nil, CGPathWithEllipseInRect(rect));
}

/*!
    Append a rounded rectangular path.
*/
- (void)appendBezierPathWithRoundedRect:(CGRect)rect xRadius:(float)xRadius yRadius:(float)yRadius
{
    CGPathAddPath(_path, nil, CGPathWithRoundedRectangleInRect(rect, xRadius, yRadius, YES, YES, YES, YES));
}

/*!
    Append the contents of a CPBezierPath object.
*/
- (void)appendBezierPath:(NSBezierPath *)other
{
    CGPathAddPath(_path, nil, other._path);
}
/*!
    Remove all path elements; clears path.
*/
- (void)removeAllPoints
{
    _path = CGPathCreateMutable();
}

@end
