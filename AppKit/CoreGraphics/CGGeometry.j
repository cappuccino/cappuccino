/*
 * CGGeometry.j
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

#include "CGGeometry.h"

#define _function(inline) function inline { return _##inline; }

_function(CGPointMake(x, y))
_function(CGPointMakeZero())
_function(CGPointMakeCopy(aPoint))
_function(CGPointCreateCopy(aPoint))

_function(CGPointEqualToPoint(lhsPoint, rhsPoint))
_function(CGStringFromPoint(aPoint))

_function(CGSizeMake(width, height))
_function(CGSizeMakeZero())
_function(CGSizeMakeCopy(aSize))
_function(CGSizeCreateCopy(aSize))

_function(CGSizeEqualToSize(lhsSize, rhsSize))
_function(CGStringFromSize(aSize))

_function(CGRectMake(x, y, width, height))
_function(CGRectMakeZero())
_function(CGRectMakeCopy(aRect))
_function(CGRectCreateCopy(aRect))

_function(CGRectEqualToRect(lhsRect, rhsRect))
_function(CGStringFromRect(aRect))

_function(CGRectOffset(aRect, dX, dY))
_function(CGRectInset(aRect, dX, dY))

_function(CGRectGetHeight(aRect))
_function(CGRectGetMaxX(aRect))
_function(CGRectGetMaxY(aRect))
_function(CGRectGetMidX(aRect))
_function(CGRectGetMidY(aRect))
_function(CGRectGetMinX(aRect))
_function(CGRectGetMinY(aRect))
_function(CGRectGetWidth(aRect))

_function(CGRectIsEmpty(aRect))
_function(CGRectIsNull(aRect))

_function(CGRectContainsPoint(aRect, aPoint))

_function(CGInsetMake(top, right, bottom, left))
_function(CGInsetMakeZero())
_function(CGInsetMakeCopy(anInset))
_function(CGInsetIsEmpty(anInset))

CGRectNull = _CGRectMake(Infinity, Infinity, 0.0, 0.0);

/*!
    @addtogroup appkit
    @{
*/

/*!
    Returns a \c BOOL indicating whether CGRect \c lhsRect
    contains CGRect \c rhsRect.
    @group CGRect
    @param lhsRect the CGRect to test if \c rhsRect is inside of
    @param rhsRect the CGRect to test if it fits inside \c lhsRect.
    @return BOOL \c YES if \c rhsRect fits inside \c lhsRect.
*/
function CGRectContainsRect(lhsRect, rhsRect)
{
    var union = CGRectUnion(lhsRect, rhsRect);
    
    return _CGRectEqualToRect(union, lhsRect);
}

/*!
    Returns \c YES if the two rectangles intersect
    @group CGRect
    @param lhsRect the first CGRect
    @param rhsRect the second CGRect
    @return BOOL \c YES if the two rectangles have any common spaces, and \c NO, otherwise.
*/
function CGRectIntersectsRect(lhsRect, rhsRect)
{
    var intersection = CGRectIntersection(lhsRect, rhsRect);
    
    return !_CGRectIsEmpty(intersection);
}

/*!
    Makes the origin and size of a CGRect all integers. Specifically, by making 
    the southwest corner the origin (rounded down), and the northeast corner a CGSize (rounded up).
    @param aRect the rectangle to operate on
    @return CGRect the modified rectangle (same as the input)
    @group CGRect
*/
function CGRectIntegral(aRect)
{
    aRect = CGRectStandardize(aRect);

    // Store these out separately, if not the GetMaxes will return incorrect values.
    var x = FLOOR(_CGRectGetMinX(aRect)),
        y = FLOOR(_CGRectGetMinY(aRect));
    
    aRect.size.width = CEIL(_CGRectGetMaxX(aRect)) - x;
    aRect.size.height = CEIL(_CGRectGetMaxY(aRect)) - y;

    aRect.origin.x = x;
    aRect.origin.y = y;

    return aRect;
}

/*!
    Returns the intersection of the two provided rectangles as a new rectangle.
    @param lhsRect the first rectangle used for calculation
    @param rhsRect the second rectangle used for calculation
    @return CGRect the intersection of the two rectangles
    @group CGRect
*/
function CGRectIntersection(lhsRect, rhsRect)
{
    var intersection = _CGRectMake(
        MAX(_CGRectGetMinX(lhsRect), _CGRectGetMinX(rhsRect)), 
        MAX(_CGRectGetMinY(lhsRect), _CGRectGetMinY(rhsRect)), 
        0, 0);
    
    intersection.size.width = MIN(_CGRectGetMaxX(lhsRect), _CGRectGetMaxX(rhsRect)) - _CGRectGetMinX(intersection);
    intersection.size.height = MIN(_CGRectGetMaxY(lhsRect), _CGRectGetMaxY(rhsRect)) - _CGRectGetMinY(intersection);
    
    return _CGRectIsEmpty(intersection) ? _CGRectMakeZero() : intersection;
}

/*
    
*/
function CGRectStandardize(aRect)
{
    var width = _CGRectGetWidth(aRect),
        height = _CGRectGetHeight(aRect),
        standardized = _CGRectMakeCopy(aRect);

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

function CGRectUnion(lhsRect, rhsRect)
{
    var lhsRectIsNull = !lhsRect || lhsRect === CGRectNull,
        rhsRectIsNull = !rhsRect || rhsRect === CGRectNull;

    if (lhsRectIsNull)
        return rhsRectIsNull ? CGRectNull : rhsRect;

    if (rhsRectIsNull)
        return lhsRectIsNull ? CGRectNull : lhsRect;

    var minX = MIN(_CGRectGetMinX(lhsRect), _CGRectGetMinX(rhsRect)),
        minY = MIN(_CGRectGetMinY(lhsRect), _CGRectGetMinY(rhsRect)),
        maxX = MAX(_CGRectGetMaxX(lhsRect), _CGRectGetMaxX(rhsRect)),
        maxY = MAX(_CGRectGetMaxY(lhsRect), _CGRectGetMaxY(rhsRect));
    
    return _CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

function CGPointFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { x:parseInt(aString.substr(1, comma - 1)), y:parseInt(aString.substring(comma + 1, aString.length)) };
}

function CGSizeFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { width:parseInt(aString.substr(1, comma - 1)), height:parseInt(aString.substring(comma + 1, aString.length)) };
}

function CGRectFromString(aString)
{
    var comma = aString.indexOf(',', aString.indexOf(',') + 1);
    
    return { origin:CGPointFromString(aString.substr(1, comma - 1)), size:CGSizeFromString(aString.substring(comma + 2, aString.length)) };
}

function CGPointFromEvent(anEvent)
{
    return _CGPointMake(anEvent.clientX, anEvent.clientY);
}

function CGInsetFromString(aString)
{
    var numbers = aString.substr(1, aString.length - 2).split(',');

    return _CGInsetMake(parseFloat(numbers[0]), parseFloat(numbers[1]), parseFloat(numbers[2]), parseFloat(numbers[3]));
}

CGInsetFromCPString = CGInsetFromString;

function CPStringFromCGInset(anInset)
{
    return '{' + anInset.top + ", " + anInset.left + ", " + anInset.bottom + ", " + anInset.right + '}';
}

/*! 
    @} 
*/
