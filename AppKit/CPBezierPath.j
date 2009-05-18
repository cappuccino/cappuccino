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

@import <AppKit/CPGraphicsContext.j>
@import <Foundation/CPObject.j>


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

+ (CPBezierPath)bezierPath
{
    return [[[self class] alloc] init];
}

+ (CPBezierPath)bezierPathWithOvalInRect:(CGRect)rect
{
    var path = [[self class] bezierPath];
    
    [path appendBezierPathWithOvalInRect:rect];
    
    return path;
}

+ (CPBezierPath)bezierPathWithRect:(CGRect)rect
{
    var path = [[self class] bezierPath];
    
    [path appendBezierPathWithRect:rect];
    
    return path;
}

+ (float)defaultLineWidth
{
    return DefaultLineWidth;
}

+ (void)setDefaultLineWidth:(float)width
{
    DefaultLineWidth = width;
}

+ (void)fillRect:(CGRect)rect
{
    [[[self class] bezierPathWithRect:rect] fill];
}

+ (void)strokeRect:(CGRect)rect
{
    [[[self class] bezierPathWithRect:rect] stroke];
}

+ (void)strokeLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2
{
    var path = [[self class] bezierPath];

    [path moveToPoint:point1];
    [path lineToPoint:point2];

    [path stroke];
}

- (id)init
{
    if (self = [super init])
    {
        _path = CGPathCreateMutable();
        _lineWidth = [[self class] defaultLineWidth];
    }

    return self;
}

- (void)moveToPoint:(CGPoint)point
{
    CGPathMoveToPoint(_path, nil, point.x, point.y);
}

- (void)lineToPoint:(CGPoint)point
{
    CGPathAddLineToPoint(_path, nil, point.x, point.y);
}

- (void)curveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2
{
    CGPathAddCurveToPoint(_path, nil, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);
}

- (void)closePath
{
    CGPathCloseSubpath(_path);
}

- (void)stroke
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, _path);
    CGContextSetLineWidth(ctx, [self lineWidth]);
    CGContextClosePath(ctx);
    CGContextStrokePath(ctx);
}

- (void)fill
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, _path);
    CGContextSetLineWidth(ctx, [self lineWidth]);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

- (float)lineWidth
{
    return _lineWidth;
}

- (void)setLineWidth:(float)lineWidth
{
    _lineWidth = lineWidth;
}

- (unsigned)elementCount
{
    return _path.count;
}

- (BOOL)isEmpty
{
    return CGPathIsEmpty(_path);
}

- (CGPoint)currentPoint
{
    return CGPathGetCurrentPoint(_path);
}

- (void)appendBezierPathWithPoints:(CPArray)points count:(unsigned)count
{
    CGPathAddLines(_path, nil, points, count);
}

- (void)appendBezierPathWithRect:(CGRect)rect
{
    CGPathAddRect(_path, nil, rect);
}

- (void)appendBezierPathWithOvalInRect:(CGRect)rect
{
    CGPathAddPath(_path, nil, CGPathWithEllipseInRect(rect));
}

- (void)appendBezierPathWithRoundedRect:(CGRect)rect xRadius:(float)xRadius yRadius:(float)yRadius
{
    CGPathAddPath(_path, nil, CGPathWithRoundedRectangleInRect(rect, xRadius, yRadius, YES, YES, YES, YES));
}

- (void)appendBezierPath:(NSBezierPath *)other
{
    CGPathAddPath(_path, nil, other._path);
}

- (void)removeAllPoints
{
    _path = CGPathCreateMutable();
}

@end
