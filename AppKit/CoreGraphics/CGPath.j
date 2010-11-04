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

@import "CGGeometry.j"
@import "CGAffineTransform.j"


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
    return { count:0, start:NULL, current:NULL, elements:[] };
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
    if (aTransform && !_CGAffineTransformIsIdentity(aTransform))
    {
        var center = _CGPointMake(x, y),
            end = _CGPointMake(COS(anEndAngle), SIN(anEndAngle)),
            start = _CGPointMake(COS(aStartAngle), SIN(aStartAngle));

        end = _CGPointApplyAffineTransform(end, aTransform);
        start = _CGPointApplyAffineTransform(start, aTransform);
        center = _CGPointApplyAffineTransform(center, aTransform);

        x = center.x;
        y = center.y;

        var oldEndAngle = anEndAngle,
            oldStartAngle = aStartAngle;

        anEndAngle = ATAN2(end.y - aTransform.ty, end.x - aTransform.tx);
        aStartAngle = ATAN2(start.y - aTransform.ty, start.x - aTransform.tx);

        // Angles that equal "modulo" 2 pi return as equal after transforming them,
        // so we have to make sure to make them different again if they were different 
        // to start out with.  It's the difference between no circle and a full circle.
        if (anEndAngle == aStartAngle && oldEndAngle != oldStartAngle)
            if (oldStartAngle > oldEndAngle)
                anEndAngle = anEndAngle - PI2;
            else
                aStartAngle = aStartAngle - PI2;

        aRadius = _CGSizeMake(aRadius, 0);
        aRadius = _CGSizeApplyAffineTransform(aRadius, aTransform);
        aRadius = SQRT(aRadius.width * aRadius.width + aRadius.height * aRadius.height);
    }
    
    aPath.current = _CGPointMake(x + aRadius * COS(anEndAngle), y + aRadius * SIN(anEndAngle));
    aPath.elements[aPath.count++] = { type:kCGPathElementAddArc, x:x, y:y, radius:aRadius, startAngle:aStartAngle, endAngle:anEndAngle };
}

function CGPathAddArcToPoint(aPath, aTransform, x1, y1, x2, y2, aRadius)
{
}

function CGPathAddCurveToPoint(aPath, aTransform, cp1x, cp1y, cp2x, cp2y, x, y)
{
    var cp1 = _CGPointMake(cp1x, cp1y),
        cp2 = _CGPointMake(cp2x, cp2y),
        end = _CGPointMake(x, y);
        
    if (aTransform)
    {
        cp1 = _CGPointApplyAffineTransform(cp1, aTransform);
        cp2 = _CGPointApplyAffineTransform(cp2, aTransform);
        end = _CGPointApplyAffineTransform(end, aTransform);
    }
   
   aPath.current = end;
   aPath.elements[aPath.count++] = { type:kCGPathElementAddCurveToPoint, cp1x:cp1.x, cp1y:cp1.y, cp2x:cp2.x, cp2y:cp2.y, x:end.x, y:end.y };
}

function CGPathAddLines(aPath, aTransform, points, count)
{
    var i = 1;
    
    if (arguments["count"] == NULL)
        var count = points.length;
        
    if (!aPath || count < 2)
        return;
        
    CGPathMoveToPoint(aPath, aTransform, points[0].x, points[0].y);

    for (; i < count; ++i)
        CGPathAddLineToPoint(aPath, aTransform, points[i].x, points[i].y);
}

function CGPathAddLineToPoint(aPath, aTransform, x, y)
{
    var point = _CGPointMake(x, y);
    
    if (aTransform != NULL)
        point = _CGPointApplyAffineTransform(point, aTransform);

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
            case kCGPathElementAddLineToPoint:      CGPathAddLineToPoint(aPath, aTransform, element.x, element.y);
                                                    break;

            case kCGPathElementAddCurveToPoint:     CGPathAddCurveToPoint(aPath, aTransform,
                                                                          element.cp1x, element.cp1y,
                                                                          element.cp2x, element.cp2y,
                                                                          element.x, element.y);
                                                    break;

            case kCGPathElementAddArc:              CGPathAddArc(aPath, aTransform, element.x, element.y,
                                                                 element.radius, element.startAngle,
                                                                 element.endAngle, element.isClockwise);
                                                    break;

            case kCGPathElementAddQuadCurveToPoint: CGPathAddQuadCurveToPoint(aPath, aTransform,
                                                                              element.cpx, element.cpy,
                                                                              element.x, element.y);
                                                    break;

            case kCGPathElementMoveToPoint:         CGPathMoveToPoint(aPath, aTransform, element.x, element.y);
                                                    break;

            case kCGPathElementCloseSubpath:        CGPathCloseSubpath(aPath);
                                                    break;
        }
    }
}

function CGPathAddQuadCurveToPoint(aPath, aTransform, cpx, cpy, x, y)
{
    var cp = _CGPointMake(cpx, cpy),
        end = _CGPointMake(x, y);
        
    if (aTransform)
    {
        cp = _CGPointApplyAffineTransform(cp, aTransform);
        end = _CGPointApplyAffineTransform(end, aTransform);
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
    
    if (arguments["count"] == NULL)
        var count = rects.length;
        
    for (; i < count; ++i)
    {
        var rect = rects[i];
            
        CGPathMoveToPoint(aPath, aTransform, _CGRectGetMinX(rect), _CGRectGetMinY(rect));
        CGPathAddLineToPoint(aPath, aTransform, _CGRectGetMaxX(rect), _CGRectGetMinY(rect));
        CGPathAddLineToPoint(aPath, aTransform, _CGRectGetMaxX(rect), _CGRectGetMaxY(rect));
        CGPathAddLineToPoint(aPath, aTransform, _CGRectGetMinX(rect), _CGRectGetMaxY(rect));
    
        CGPathCloseSubpath(aPath);
    }
}

function CGPathMoveToPoint(aPath, aTransform, x, y)
{
    var point = _CGPointMake(x, y),
        count = aPath.count;
    
    if (aTransform != NULL)
        point = _CGPointApplyAffineTransform(point, aTransform);

    aPath.start = point;
    aPath.current = point;
    
    var previous = aPath.elements[count - 1];
    
    if (count != 0 && previous.type == kCGPathElementMoveToPoint)
    {
        previous.x = point.x;
        previous.y = point.y;
    }
    else
        aPath.elements[aPath.count++] = { type:kCGPathElementMoveToPoint, x:point.x, y:point.y };
}

var KAPPA = 4.0 * ((SQRT2 - 1.0) / 3.0);

function CGPathWithEllipseInRect(aRect)
{
    var path = CGPathCreateMutable();
	
	if (_CGRectGetWidth(aRect) == _CGRectGetHeight(aRect))
        CGPathAddArc(path, nil, _CGRectGetMidX(aRect), _CGRectGetMidY(aRect), _CGRectGetWidth(aRect) / 2.0, 0.0, 2 * PI, YES);
	else
	{
	    var axis = _CGSizeMake(_CGRectGetWidth(aRect) / 2.0, _CGRectGetHeight(aRect) / 2.0),
	        center = _CGPointMake(_CGRectGetMinX(aRect) + axis.width, _CGRectGetMinY(aRect) + axis.height);

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
        xMin = _CGRectGetMinX(aRect),
        xMax = _CGRectGetMaxX(aRect),
        yMin = _CGRectGetMinY(aRect),
        yMax = _CGRectGetMaxY(aRect);

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
	} else
		CGPathAddLineToPoint(path, nil, xMin, yMin);

    CGPathCloseSubpath(path);

    return path;
}

function CGPathCloseSubpath(aPath)
{
    var count = aPath.count;
    
    // Don't bother closing this subpath if there aren't any current elements, or the last element already closed the subpath.
    if (count == 0 || aPath.elements[count - 1].type == kCGPathElementCloseSubpath)
        return;
    
    aPath.elements[aPath.count++] = { type:kCGPathElementCloseSubpath, points:[aPath.start] };
}

function CGPathEqualToPath(aPath, anotherPath)
{
    if (aPath == anotherPath)
        return YES;
    
    if (aPath.count != anotherPath.count || !_CGPointEqualToPoint(aPath.start, anotherPath.start) || !_CGPointEqualToPoint(aPath.current, anotherPath.current))
        return NO;
        
    var i = 0,
        count = aPath.count;
        
    for (; i < count; ++i)
    {
        var element = aPath[i],
            anotherElement = anotherPath[i];
        
        if (element.type != anotherElement.type)
            return NO;
        
        if ((element.type == kCGPathElementAddArc || element.type == kCGPathElementAddArcToPoint) && 
            element.radius != anotherElement.radius)
            return NO;
        
        var j = element.points.length;
        
        while (j--)
            if (!_CGPointEqualToPoint(element.points[j], anotherElement.points[j]))
                return NO;
    }
    
    return YES;
}

function CGPathGetCurrentPoint(aPath)
{
    return _CGPointCreateCopy(aPath.current);
}

function CGPathIsEmpty(aPath)
{
    return !aPath || aPath.count == 0;
}

/*!
    @}
*/

