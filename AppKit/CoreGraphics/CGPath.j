/*
 * CGPath.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "CGAffineTransform.j"
@import "CGGeometry.j"


kCGPathElementMoveToPoint           = 0;
kCGPathElementAddLineToPoint        = 1;
kCGPathElementAddQuadCurveToPoint   = 2;
kCGPathElementAddCurveToPoint       = 3;
kCGPathElementCloseSubpath          = 4;

kCGPathElementAddArc                = 5;
kCGPathElementAddArcToPoint         = 6;

/*!
    @addtogroup coregraphics
    @{
*/

/*!
    Returns a new CGPath object.
*/
function CGPathCreateMutable()
{
    return { count:0, start:CGPointMake(0, 0), current:CGPointMake(0, 0), elements:[] };
}

/*!
    Returns a copy of the given path object.
*/

function CGPathCreateMutableCopy(aPath)
{
    var path = CGPathCreateMutable();

    CGPathAddPath(path, aPath);

    return path;
}

/*!
    Returns a copy of the given path object.
*/

function CGPathCreateCopy(aPath)
{
    return CGPathCreateMutableCopy(aPath);
}

function CGPathRelease(aPath)
{
}

function CGPathRetain(aPath)
{
    return aPath;
}

function CGPathAddArc(aPath, aTransform, x, y, aRadius, aStartAngle, anEndAngle, isClockwise)
{
    if (aTransform && !CGAffineTransformIsIdentity(aTransform))
    {
        var center = CGPointMake(x, y),
            end = CGPointMake(COS(anEndAngle), SIN(anEndAngle)),
            start = CGPointMake(COS(aStartAngle), SIN(aStartAngle));

        end = CGPointApplyAffineTransform(end, aTransform);
        start = CGPointApplyAffineTransform(start, aTransform);
        center = CGPointApplyAffineTransform(center, aTransform);

        x = center.x;
        y = center.y;

        var oldEndAngle = anEndAngle,
            oldStartAngle = aStartAngle;

        anEndAngle = ATAN2(end.y - aTransform.ty, end.x - aTransform.tx);
        aStartAngle = ATAN2(start.y - aTransform.ty, start.x - aTransform.tx);

        // Angles that equal "modulo" 2 pi return as equal after transforming them,
        // so we have to make sure to make them different again if they were different
        // to start out with.  It's the difference between no circle and a full circle.
        if (anEndAngle === aStartAngle && oldEndAngle !== oldStartAngle)
            if (oldStartAngle > oldEndAngle)
                anEndAngle = anEndAngle - PI2;
            else
                aStartAngle = aStartAngle - PI2;

        aRadius = CGSizeMake(aRadius, 0);
        aRadius = CGSizeApplyAffineTransform(aRadius, aTransform);
        aRadius = SQRT(aRadius.width * aRadius.width + aRadius.height * aRadius.height);
    }

    /*
        From the Cocoa docs:

        If the specified path already contains a subpath, Quartz implicitly adds a line connecting the subpath’s current point to the beginning of the arc. If the path is empty, Quartz creates a new subpath with a starting point set to the starting point of the arc.

        The ending point of the arc becomes the new current point of the path.
    */
    var arcEndX = x + aRadius * COS(anEndAngle),
        arcEndY = y + aRadius * SIN(anEndAngle);

    if (aPath.count)
    {
        if (aPath.current.x !== arcEndX || aPath.current.y !== arcEndY)
            CGPathAddLineToPoint(aPath, aTransform, arcEndX, arcEndY);
    }
    else
    {
        var arcStartX = x + aRadius * COS(aStartAngle),
            arcStartY = y + aRadius * SIN(aStartAngle);

        aPath.start = CGPointMake(arcStartX, arcStartY);
    }

    aPath.current = CGPointMake(arcEndX, arcEndY);
    aPath.elements[aPath.count++] = { type:kCGPathElementAddArc, x:x, y:y, radius:aRadius, startAngle:aStartAngle, endAngle:anEndAngle, clockwise:isClockwise };
}

function CGPathAddArcToPoint(aPath, aTransform, x1, y1, x2, y2, aRadius)
{
    var p1 = CGPointMake(x1, y1),
        p2 = CGPointMake(x2, y2);

    if (aTransform)
    {
        p1 = CGPointApplyAffineTransform(p1, aTransform);
        p2 = CGPointApplyAffineTransform(p2, aTransform);
    }

    /*
        From the Cocoa docs:

        If the current point and the first tangent point of the arc (the starting point) are not equal, Quartz appends a straight line segment from the current point to the first tangent point.

        The ending point of the arc becomes the new current point of the path.
    */
    if (aPath.count)
    {
        if (aPath.current.x !== p1.x || aPath.current.y !== p1.y)
            CGPathAddLineToPoint(aPath, aTransform, p1.x, p1.y);
    }
    else
        aPath.start = p1;

    aPath.current = p2;
    aPath.elements[aPath.count++] = { type:kCGPathElementAddArcToPoint, p1x:p1.x, p1y:p1.y, p2x:p2.x, p2y:p2.y, radius:aRadius };
}

function CGPathAddCurveToPoint(aPath, aTransform, cp1x, cp1y, cp2x, cp2y, x, y)
{
    var cp1 = CGPointMake(cp1x, cp1y),
        cp2 = CGPointMake(cp2x, cp2y),
        end = CGPointMake(x, y);

    if (aTransform)
    {
        cp1 = CGPointApplyAffineTransform(cp1, aTransform);
        cp2 = CGPointApplyAffineTransform(cp2, aTransform);
        end = CGPointApplyAffineTransform(end, aTransform);
    }

    aPath.current = end;
    aPath.elements[aPath.count++] = { type:kCGPathElementAddCurveToPoint, cp1x:cp1.x, cp1y:cp1.y, cp2x:cp2.x, cp2y:cp2.y, x:end.x, y:end.y };
}

function CGPathAddLines(aPath, aTransform, points, count)
{
    if (count === null || count === undefined)
        count = points.length;

    if (!aPath || count < 1)
        return;

    CGPathMoveToPoint(aPath, aTransform, points[0].x, points[0].y);

    for (var i = 1; i < count; ++i)
        CGPathAddLineToPoint(aPath, aTransform, points[i].x, points[i].y);
}

function CGPathAddLineToPoint(aPath, aTransform, x, y)
{
    var point = CGPointMake(x, y);

    if (aTransform !== NULL)
        point = CGPointApplyAffineTransform(point, aTransform);

    aPath.elements[aPath.count++] = { type: kCGPathElementAddLineToPoint, x:point.x, y:point.y };
    aPath.current = point;
}

function CGPathAddPath(aPath, aTransform, anotherPath)
{
    for (var i = 0, count = anotherPath.count; i < count; ++i)
    {
        var element = anotherPath.elements[i];

        switch (element.type)
        {
            case kCGPathElementAddLineToPoint:
                CGPathAddLineToPoint(aPath, aTransform, element.x, element.y);
                break;

            case kCGPathElementAddCurveToPoint:
                CGPathAddCurveToPoint(aPath, aTransform,
                                      element.cp1x, element.cp1y,
                                      element.cp2x, element.cp2y,
                                      element.x, element.y);
                break;

            case kCGPathElementAddArc:
                CGPathAddArc(aPath, aTransform, element.x, element.y,
                             element.radius, element.startAngle,
                             element.endAngle, element.clockwise);
                break;

            case kCGPathElementAddArcToPoint:
                CGPathAddArcToPoint(aPath, aTransform,
                                    element.p1x, element.p1y,
                                    element.p2x, element.p2y,
                                    element.radius);
                break;

            case kCGPathElementAddQuadCurveToPoint:
                CGPathAddQuadCurveToPoint(aPath, aTransform,
                                          element.cpx, element.cpy,
                                          element.x, element.y);
                break;

            case kCGPathElementMoveToPoint:
                CGPathMoveToPoint(aPath, aTransform, element.x, element.y);
                break;

            case kCGPathElementCloseSubpath:
                CGPathCloseSubpath(aPath);
                break;
        }
    }
}

function CGPathAddQuadCurveToPoint(aPath, aTransform, cpx, cpy, x, y)
{
    var cp = CGPointMake(cpx, cpy),
        end = CGPointMake(x, y);

    if (aTransform)
    {
        cp = CGPointApplyAffineTransform(cp, aTransform);
        end = CGPointApplyAffineTransform(end, aTransform);
    }

    aPath.elements[aPath.count++] = { type:kCGPathElementAddQuadCurveToPoint, cpx:cp.x, cpy:cp.y, x:end.x, y:end.y }
    aPath.current = end;
}

function CGPathAddRect(aPath, aTransform, aRect)
{
    CGPathAddRects(aPath, aTransform, [aRect], 1);
}

function CGPathAddRects(aPath, aTransform, rects, count)
{
    var i = 0;

    if (count === NULL)
        var count = rects.length;

    for (; i < count; ++i)
    {
        var rect = rects[i];

        CGPathMoveToPoint(aPath, aTransform, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGPathAddLineToPoint(aPath, aTransform, CGRectGetMaxX(rect), CGRectGetMinY(rect));
        CGPathAddLineToPoint(aPath, aTransform, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGPathAddLineToPoint(aPath, aTransform, CGRectGetMinX(rect), CGRectGetMaxY(rect));

        CGPathCloseSubpath(aPath);
    }
}

function CGPathMoveToPoint(aPath, aTransform, x, y)
{
    var point = CGPointMake(x, y);

    if (aTransform !== NULL)
        point = CGPointApplyAffineTransform(point, aTransform);

    aPath.start = aPath.current = point;

    // If the previous op was a move, just update that point
    if (aPath.count)
    {
        var previous = aPath.elements[aPath.count - 1];

        if (previous.type === kCGPathElementMoveToPoint)
        {
            previous.x = point.x;
            previous.y = point.y;
            return;
        }
    }

    aPath.elements[aPath.count++] = { type:kCGPathElementMoveToPoint, x:point.x, y:point.y };
}

var KAPPA = 4.0 * ((SQRT2 - 1.0) / 3.0);

function CGPathWithEllipseInRect(aRect)
{
    var path = CGPathCreateMutable();

    if (CGRectGetWidth(aRect) === CGRectGetHeight(aRect))
        CGPathAddArc(path, nil, CGRectGetMidX(aRect), CGRectGetMidY(aRect), CGRectGetWidth(aRect) / 2.0, 0.0, 2 * PI, YES);
    else
    {
        var axis = CGSizeMake(CGRectGetWidth(aRect) / 2.0, CGRectGetHeight(aRect) / 2.0),
            center = CGPointMake(CGRectGetMinX(aRect) + axis.width, CGRectGetMinY(aRect) + axis.height);

        CGPathMoveToPoint(path, nil, center.x, center.y - axis.height);

        CGPathAddCurveToPoint(path, nil, center.x + (KAPPA * axis.width), center.y - axis.height,  center.x + axis.width, center.y - (KAPPA * axis.height), center.x + axis.width, center.y);
        CGPathAddCurveToPoint(path, nil, center.x + axis.width, center.y + (KAPPA * axis.height), center.x + (KAPPA * axis.width), center.y + axis.height, center.x, center.y + axis.height);
        CGPathAddCurveToPoint(path, nil, center.x - (KAPPA * axis.width), center.y + axis.height, center.x - axis.width, center.y + (KAPPA * axis.height), center.x - axis.width, center.y);
        CGPathAddCurveToPoint(path, nil, center.x - axis.width, center.y - (KAPPA * axis.height), center.x - (KAPPA * axis.width), center.y - axis.height, center.x, center.y - axis.height);
    }

    CGPathCloseSubpath(path);

    return path;
}

function CGPathWithRoundedRectangleInRect(aRect, xRadius, yRadius/*not currently supported*/, ne, se, sw, nw)
{
    var path = CGPathCreateMutable(),
        xMin = CGRectGetMinX(aRect),
        xMax = CGRectGetMaxX(aRect),
        yMin = CGRectGetMinY(aRect),
        yMax = CGRectGetMaxY(aRect);

    CGPathMoveToPoint(path, nil, xMin + xRadius, yMin);

    if (ne)
    {
        CGPathAddLineToPoint(path, nil, xMax - xRadius, yMin);
        CGPathAddCurveToPoint(path, nil, xMax - xRadius, yMin, xMax, yMin, xMax, yMin + xRadius);
    }
    else
        CGPathAddLineToPoint(path, nil, xMax, yMin);

    if (se)
    {
        CGPathAddLineToPoint(path, nil, xMax, yMax - xRadius);
        CGPathAddCurveToPoint(path, nil, xMax, yMax - xRadius, xMax, yMax, xMax - xRadius, yMax);
    }
    else
        CGPathAddLineToPoint(path, nil, xMax, yMax);

    if (sw)
    {
        CGPathAddLineToPoint(path, nil, xMin + xRadius, yMax);
        CGPathAddCurveToPoint(path, nil, xMin + xRadius, yMax, xMin, yMax, xMin, yMax - xRadius);
    }
    else
        CGPathAddLineToPoint(path, nil, xMin, yMax);

    if (nw)
    {
        CGPathAddLineToPoint(path, nil, xMin, yMin + xRadius);
        CGPathAddCurveToPoint(path, nil, xMin, yMin + xRadius, xMin, yMin, xMin + xRadius, yMin);
    }
    else
        CGPathAddLineToPoint(path, nil, xMin, yMin);

    CGPathCloseSubpath(path);

    return path;
}

function CGPathCloseSubpath(aPath)
{
    var count = aPath.count;

    // Don't bother closing this subpath if there aren't any current elements, or the last element already closed the subpath.
    if (count === 0 || aPath.elements[count - 1].type === kCGPathElementCloseSubpath)
        return;

    // After closing, the current point is the previous path's starting point
    aPath.current = CGPointCreateCopy(aPath.start);
    aPath.elements[aPath.count++] = { type:kCGPathElementCloseSubpath, start:aPath.start };
}

function CGPathEqualToPath(aPath, anotherPath)
{
    if (aPath === anotherPath)
        return YES;

    if (aPath.count !== anotherPath.count || !CGPointEqualToPoint(aPath.start, anotherPath.start) || !CGPointEqualToPoint(aPath.current, anotherPath.current))
        return NO;

    var i = 0,
        count = aPath.count;

    for (; i < count; ++i)
    {
        var element = aPath[i],
            anotherElement = anotherPath[i];

        if (element.type !== anotherElement.type)
            return NO;

        switch (element.type)
        {
            case kCGPathElementAddArc:
                if (element.x !== anotherElement.x ||
                    element.y !== anotherElement.y ||
                    element.radius !== anotherElement.radius ||
                    element.startAngle !== anotherElement.startAngle ||
                    element.endAngle !== anotherElement.endAngle ||
                    element.clockwise !== anotherElement.clockwise)
                {
                    return NO;
                }
                break;

            case kCGPathElementAddArcToPoint:
                if (element.p1x !== anotherElement.p1x ||
                    element.p1y !== anotherElement.p1y ||
                    element.p2x !== anotherElement.p2x ||
                    element.p2y !== anotherElement.p2y ||
                    element.radius !== anotherElement.radius)
                {
                    return NO;
                }
                break;

            case kCGPathElementAddCurveToPoint:
                if (element.cp1x !== anotherElement.cp1x ||
                    element.cp1y !== anotherElement.cp1y ||
                    element.cp2x !== anotherElement.cp2x ||
                    element.cp2y !== anotherElement.cp2y ||
                    element.x !== anotherElement.x ||
                    element.y !== anotherElement.y)
                {
                    return NO;
                }
                break;

            case kCGPathElementAddLineToPoint:
            case kCGPathElementMoveToPoint:
                if (element.x !== anotherElement.x ||
                    element.y !== anotherElement.y)
                {
                    return NO;
                }
                break;

            case kCGPathElementAddQuadCurveToPoint:
                if (element.cpx !== anotherElement.cpx ||
                    element.cpy !== anotherElement.cpy ||
                    element.x !== anotherElement.x ||
                    element.y !== anotherElement.y)
                {
                    return NO;
                }
                break;

            case kCGPathElementCloseSubpath:
                if (!CGPointEqualToPoint(element.start, anotherElement.start))
                    return NO;
                break;
        }
    }

    return YES;
}

function CGPathGetCurrentPoint(aPath)
{
    return CGPointCreateCopy(aPath.current);
}

function CGPathIsEmpty(aPath)
{
    return !aPath || aPath.count === 0;
}

/*!
    Calculate the smallest rectangle to contain both the path of the receiver and all control points.
*/
function CGPathGetBoundingBox(aPath)
{
    if (!aPath || !aPath.count)
        return CGRectMakeZero();

    var ox = 0,
        oy = 0,
        rx = 0,
        ry = 0,
        movePoint = nil;

    function addPoint(x, y)
    {
        ox = MIN(ox, x);
        oy = MIN(oy, y);
        rx = MAX(rx, x);
        ry = MAX(ry, y);
    }

    for (var i = 0, count = aPath.count; i < count; ++i)
    {
        var element = aPath.elements[i];

        // Just enclose all the control points. The curves must be inside of the control points.
        // This won't work for CGPathGetBoundingBox.
        switch (element.type)
        {
            case kCGPathElementAddLineToPoint:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                addPoint(element.x, element.y);
                break;

            case kCGPathElementAddCurveToPoint:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                addPoint(element.cp1x, element.cp1y);
                addPoint(element.cp2x, element.cp2y);
                addPoint(element.x, element.y);
                break;

            case kCGPathElementAddArc:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                addPoint(element.x, element.y);
                break;

            case kCGPathElementAddArcToPoint:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                addPoint(element.p1x, element.p1y);
                addPoint(element.p2x, element.p2y);
                break;

            case kCGPathElementAddQuadCurveToPoint:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                addPoint(element.cpx, element.cpy);
                addPoint(element.x, element.y);
                break;

            case kCGPathElementMoveToPoint:
                movePoint = CGPointMake(element.x, element.y);
                break;

            case kCGPathElementCloseSubpath:
                if (movePoint)
                {
                    addPoint(movePoint.x, movePoint.y);
                    movePoint = nil;
                }

                break;
        }
    }

    return CGRectMake(ox, oy, rx - ox, ry - oy);
}

/*!
    @}
*/

