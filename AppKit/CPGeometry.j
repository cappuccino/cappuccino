/*
 * CPGeometry.j
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

import "CGGeometry.j"

CPMinXEdge = 0;
CPMinYEdge = 1;
CPMaxXEdge = 2;
CPMaxYEdge = 3;

// FIXME: the rest!
CPMakePoint = CGPointMake;
CPMakeSize = CGSizeMake;
CPMakeRect = CGRectMake;

function CPPointCreateCopy(aPoint)
{
    return { x: aPoint.x, y: aPoint.y };
}

function CPPointMake(x, y)
{
    return { x: x, y: y };
}

function CPRectInset(aRect, dX, dY)
{
    return CPRectMake(  aRect.origin.x + dX, aRect.origin.y + dY, 
                        aRect.size.width - 2 * dX, aRect.size.height - 2*dY);
}

function CPRectIntegral(aRect)
{
    // FIXME!!!
    alert("CPRectIntegral unimplemented");
}

function CPRectIntersection(lhsRect, rhsRect)
{
    var intersection = CPRectMake(
        Math.max(CPRectGetMinX(lhsRect), CPRectGetMinX(rhsRect)), 
        Math.max(CPRectGetMinY(lhsRect), CPRectGetMinY(rhsRect)), 
        0, 0);
    
    intersection.size.width = Math.min(CPRectGetMaxX(lhsRect), CPRectGetMaxX(rhsRect)) - CPRectGetMinX(intersection);
    intersection.size.height = Math.min(CPRectGetMaxY(lhsRect), CPRectGetMaxY(rhsRect)) - CPRectGetMinY(intersection);
    
    return CPRectIsEmpty(intersection) ? CPRectMakeZero() : intersection;
}

function CPRectCreateCopy(aRect)
{
    return { origin: CPPointCreateCopy(aRect.origin), size: CPSizeCreateCopy(aRect.size) };
}

function CPRectMake(x, y, width, height)
{
    return { origin: CPPointMake(x, y), size: CPSizeMake(width, height) };
}

function CPRectOffset(aRect, dX, dY)
{
    return CPRectMake(aRect.origin.x + dX, aRect.origin.y + dY, aRect.size.width, aRect.size.height);
}

function CPRectStandardize(aRect)
{
    var width = CPRectGetWidth(aRect),
        height = CPRectGetHeight(aRect),
        standardized = CPRectCreateCopy(aRect);

    if (width < 0.0)
    {
        standardized.origin.x += width;
        standardized.size.width = -width;
    }
    
    if (height < 0.0)
    {
        standardized.origin.y += height;
        standardized.size.height = -height;
    }
    
    return standardized;
}

function CPRectUnion(lhsRect, rhsRect)
{
    var minX = Math.min(CPRectGetMinX(lhsRect), CPRectGetMinX(rhsRect)),
        minY = Math.min(CPRectGetMinY(lhsRect), CPRectGetMinY(rhsRect)),
        maxX = Math.max(CPRectGetMaxX(lhsRect), CPRectGetMaxX(rhsRect)),
        maxY = Math.max(CPRectGetMaxY(lhsRect), CPRectGetMaxY(rhsRect));
    
    return CPRectMake(minX, minY, maxX - minX, maxY - minY);
}

function CPSizeCreateCopy(aSize)
{
    return { width: aSize.width, height: aSize.height };
}

function CPSizeMake(width, height)
{
    return { width: width, height: height };
}

function CPRectContainsPoint(aRect, aPoint)
{
    return  aPoint.x >= CPRectGetMinX(aRect) &&
            aPoint.y >= CPRectGetMinY(aRect) &&
   			aPoint.x < CPRectGetMaxX(aRect) &&
   			aPoint.y < CPRectGetMaxY(aRect);
}

function CPRectContainsRect(lhsRect, rhsRect)
{
    return CPRectEqualToRect(CPUnionRect(lhsRect, rhsRect), rhsRect);
}

function CPPointEqualToPoint(lhsPoint, rhsPoint)
{
    return lhsPoint.x == rhsPoint.x && lhsPoint.y == rhsPoint.y;
}

function CPRectEqualToRect(lhsRect, rhsRect)
{
    return  CPPointEqualToPoint(lhsRect.origin, rhsRect.origin) && 
            CPSizeEqualToSize(lhsRect.size, rhsRect.size);
}

function CPRectGetHeight(aRect)
{
    return aRect.size.height;
}

function CPRectGetMaxX(aRect)
{
    return aRect.origin.x + aRect.size.width;
}

function CPRectGetMaxY(aRect)
{
    return aRect.origin.y + aRect.size.height;
}

function CPRectGetMidX(aRect)
{
    return aRect.origin.x + (aRect.size.width) / 2.0;
}

function CPRectGetMidY(aRect)
{
    return aRect.origin.y + (aRect.size.height) / 2.0;
}

function CPRectGetMinX(aRect)
{
    return aRect.origin.x;
}

function CPRectGetMinY(aRect)
{
    return aRect.origin.y;
}

function CPRectGetWidth(aRect)
{
    return aRect.size.width;
}

function CPRectIntersectsRect(lhsRect, rhsRect)
{
    return !CPRectIsEmpty(CPRectIntersection(lhsRect, rhsRect));
}

function CPRectIsEmpty(aRect)
{
    return aRect.size.width <= 0.0 || aRect.size.height <= 0.0;
}

function CPRectIsNull(aRect)
{
    return aRect.size.width <= 0.0 || aRect.size.height <= 0.0;
}

function CPSizeEqualToSize(lhsSize, rhsSize)
{
    return lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height;
}

function CPStringFromPoint(aPoint)
{
    return "{" + aPoint.x + ", " + aPoint.y + "}";
}

function CPStringFromSize(aSize)
{
    return "{" + aSize.width + ", " + aSize.height + "}";
}

function CPStringFromRect(aRect)
{
    return "{" + CPStringFromPoint(aRect.origin) + ", " + CPStringFromSize(aRect.size) + "}";
}

function CPPointFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { x:parseInt(aString.substr(1, comma - 1)), y:parseInt(aString.substring(comma + 1, aString.length)) };
}

function CPSizeFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { width:parseInt(aString.substr(1, comma - 1)), height:parseInt(aString.substring(comma + 1, aString.length)) };
}

function CPRectFromString(aString)
{
    var comma = aString.indexOf(',', aString.indexOf(',') + 1);
    
    return { origin:CPPointFromString(aString.substr(1, comma - 1)), size:CPSizeFromString(aString.substring(comma + 2, aString.length)) };
}

function CPPointFromEvent(anEvent)
{
    return CPPointMake(anEvent.clientX, anEvent.clientY, 0);
}

function CPSizeMakeZero()
{
    return CPSizeMake(0, 0);
}

function CPRectMakeZero()
{
    return CPRectMake(0, 0, 0, 0);
}

function CPPointMakeZero()
{
    return CPPointMake(0, 0, 0);
}
