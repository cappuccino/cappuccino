/*
 * _CGGeometry.j
 * Foundation
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

/*

CGGeometry is not a part of Foundation. The reason _CGGeometry.j exists, and is in Foundation, is that CPGeometry and CGGeometry both use the same code so the shared basis needs to be in the lowest layer. If for some reason Cappuccino was ever reimplemented such that CPRect !== CGRect etc, this class could be removed and CPGeometry.j and CGGeometry.j updated with relevant functions without breaking any client code.

*/

function CGPointMake(x, y)
{
    return { x:x, y:y };
}

function CGPointMakeZero()
{
    return { x:0, y:0 };
}

function CGPointMakeCopy(aPoint)
{
    return { x:aPoint.x, y:aPoint.y };
}

CGPointCreateCopy = CGPointMakeCopy;

function CGPointEqualToPoint(lhsPoint, rhsPoint)
{
    return (lhsPoint.x == rhsPoint.x && lhsPoint.y == rhsPoint.y);
}

function CGStringFromPoint(aPoint)
{
    return "{" + aPoint.x + ", " + aPoint.y + "}";
}


function CGSizeMake(width, height)
{
    return { width:width, height:height };
}

function CGSizeMakeZero()
{
    return { width:0, height:0 };
}

function CGSizeMakeCopy(aSize)
{
    return { width:aSize.width, height:aSize.height };
}

CGSizeCreateCopy = CGSizeMakeCopy;

function CGSizeEqualToSize(lhsSize, rhsSize)
{
    return (lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height);
}

function CGStringFromSize(aSize)
{
    return "{" + aSize.width + ", " + aSize.height + "}";
}


function CGRectMake(x, y, width, height)
{
    return { origin:{ x:x, y:y }, size:{ width:width, height:height } };
}

function CGRectMakeZero()
{
    return { origin:{ x:0, y:0 }, size:{ width:0, height:0 } };
}

function CGRectMakeCopy(aRect)
{
    return { origin:{ x:aRect.origin.x, y:aRect.origin.y }, size:{ width:aRect.size.width, height:aRect.size.height } };
}

CGRectCreateCopy = CGRectMakeCopy;

function CGRectEqualToRect(lhsRect, rhsRect)
{
    return (lhsRect.origin.x == rhsRect.origin.x &&
            lhsRect.origin.y == rhsRect.origin.y &&
            lhsRect.size.width == rhsRect.size.width &&
            lhsRect.size.height == rhsRect.size.height);
}

function CGStringFromRect(aRect)
{
    return "{" + CGStringFromPoint(aRect.origin) + ", " + CGStringFromSize(aRect.size) + "}";
}


function CGRectOffset(aRect, dX, dY)
{
    return { origin:{ x:aRect.origin.x + dX, y:aRect.origin.y + dY }, size:{ width:aRect.size.width, height:aRect.size.height } };
}

function CGRectInset(aRect, dX, dY)
{
    return { origin:{ x:aRect.origin.x + dX, y:aRect.origin.y + dY }, size:{ width:aRect.size.width - 2 * dX, height:aRect.size.height - 2 * dY } };
}


function CGRectGetHeight(aRect)
{
    return aRect.size.height;
}

function CGRectGetMaxX(aRect)
{
    return aRect.origin.x + aRect.size.width;
}

function CGRectGetMaxY(aRect)
{
    return aRect.origin.y + aRect.size.height;
}

function CGRectGetMidX(aRect)
{
    return aRect.origin.x + (aRect.size.width / 2.0);
}

function CGRectGetMidY(aRect)
{
    return aRect.origin.y + (aRect.size.height / 2.0);
}

function CGRectGetMinX(aRect)
{
    return aRect.origin.x;
}

function CGRectGetMinY(aRect)
{
    return aRect.origin.y;
}

function CGRectGetWidth(aRect)
{
    return aRect.size.width;
}


function CGRectIsEmpty(aRect)
{
    return (aRect.size.width <= 0.0 || aRect.size.height <= 0.0 || aRect.origin.x === Infinity || aRect.origin.y === Infinity);
}

function CGRectIsNull(aRect)
{
    return (aRect.origin.x === Infinity || aRect.origin.y === Infinity);
}


function CGRectContainsPoint(aRect, aPoint)
{
    return (aPoint.x >= aRect.origin.x &&
            aPoint.y >= aRect.origin.y &&
            aPoint.x < CGRectGetMaxX(aRect) &&
            aPoint.y < CGRectGetMaxY(aRect));
}


function CGInsetMake(top, right, bottom, left)
{
    return { top:top, right:right, bottom:bottom, left:left };
}

function CGInsetMakeZero()
{
    return { top:0, right:0, bottom:0, left:0 };
}

function CGInsetMakeCopy(anInset)
{
    return { top:anInset.top, right:anInset.right, bottom:anInset.bottom, left:anInset.left };
}

function CGInsetMakeInvertedCopy(anInset)
{
    return { top:-anInset.top, right:-anInset.right, bottom:-anInset.bottom, left:-anInset.left };
}

function CGInsetIsEmpty(anInset)
{
    return (anInset.top === 0 &&
            anInset.right === 0 &&
            anInset.bottom === 0 &&
            anInset.left === 0);
}

function CGInsetEqualToInset(lhsInset, rhsInset)
{
    return (lhsInset.top === (rhsInset).top &&
            lhsInset.right === rhsInset.right &&
            lhsInset.bottom === rhsInset.bottom &&
            lhsInset.left === rhsInset.left);
}

CGMinXEdge = 0;
CGMinYEdge = 1;
CGMaxXEdge = 2;
CGMaxYEdge = 3;

CGRectNull = CGRectMake(Infinity, Infinity, 0.0, 0.0);

/*!
    @addtogroup appkit
    @{
*/

/*!
    Creates two rectangles -- slice and rem -- from inRect, by dividing inRect
    with a line that's parallel to the side of inRect specified by edge.
    The size of slice is determined by amount, which specifies the distance from edge.

    slice and rem must not be NULL, must not be the same object, and must not be the
    same object as inRect.

    @group CGRect
*/
function CGRectDivide(inRect, slice, rem, amount, edge)
{
    slice.origin = CGPointMakeCopy(inRect.origin);
    slice.size = CGSizeMakeCopy(inRect.size);
    rem.origin = CGPointMakeCopy(inRect.origin);
    rem.size = CGSizeMakeCopy(inRect.size);

    switch (edge)
    {
        case CGMinXEdge:
            slice.size.width = amount;
            rem.origin.x += amount;
            rem.size.width -= amount;
            break;

        case CGMaxXEdge:
            slice.origin.x = CGRectGetMaxX(slice) - amount;
            slice.size.width = amount;
            rem.size.width -= amount;
            break;

        case CGMinYEdge:
            slice.size.height = amount;
            rem.origin.y += amount;
            rem.size.height -= amount;
            break;

        case CGMaxYEdge:
            slice.origin.y = CGRectGetMaxY(slice) - amount;
            slice.size.height = amount;
            rem.size.height -= amount;
    }
}

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

    return CGRectEqualToRect(union, lhsRect);
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

    return !CGRectIsEmpty(intersection);
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
    var x = FLOOR(CGRectGetMinX(aRect)),
        y = FLOOR(CGRectGetMinY(aRect));

    aRect.size.width = CEIL(CGRectGetMaxX(aRect)) - x;
    aRect.size.height = CEIL(CGRectGetMaxY(aRect)) - y;

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
    var intersection = CGRectMake(MAX(CGRectGetMinX(lhsRect), CGRectGetMinX(rhsRect)),
                                  MAX(CGRectGetMinY(lhsRect), CGRectGetMinY(rhsRect)),
                                  0, 0);

    intersection.size.width = MIN(CGRectGetMaxX(lhsRect), CGRectGetMaxX(rhsRect)) - CGRectGetMinX(intersection);
    intersection.size.height = MIN(CGRectGetMaxY(lhsRect), CGRectGetMaxY(rhsRect)) - CGRectGetMinY(intersection);

    return CGRectIsEmpty(intersection) ? CGRectMakeZero() : intersection;
}

/*

*/
function CGRectStandardize(aRect)
{
    var width = CGRectGetWidth(aRect),
        height = CGRectGetHeight(aRect),
        standardized = CGRectMakeCopy(aRect);

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

    var minX = MIN(CGRectGetMinX(lhsRect), CGRectGetMinX(rhsRect)),
        minY = MIN(CGRectGetMinY(lhsRect), CGRectGetMinY(rhsRect)),
        maxX = MAX(CGRectGetMaxX(lhsRect), CGRectGetMaxX(rhsRect)),
        maxY = MAX(CGRectGetMaxY(lhsRect), CGRectGetMaxY(rhsRect));

    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

/*!
    Returns the specified rectangle inset by the given CGInset as a new rectangle.
    @param aRect the rect to inset
    @param anInset a CGInset to inset by
    @return CGRect aRect inset by anInset
*/
function CGRectInsetByInset(aRect, anInset)
{
    return CGRectMake(aRect.origin.x + anInset.left,
                      aRect.origin.y + anInset.top,
                      aRect.size.width - anInset.left - anInset.right,
                      aRect.size.height - anInset.top - anInset.bottom);
}

function CGPointFromString(aString)
{
    var comma = aString.indexOf(',');

    return { x:parseFloat(aString.substr(1, comma - 1)), y:parseFloat(aString.substring(comma + 1, aString.length)) };
}

function CGSizeFromString(aString)
{
    var comma = aString.indexOf(',');

    return { width:parseFloat(aString.substr(1, comma - 1)), height:parseFloat(aString.substring(comma + 1, aString.length)) };
}

function CGRectFromString(aString)
{
    var comma = aString.indexOf(',', aString.indexOf(',') + 1);

    return { origin:CGPointFromString(aString.substr(1, comma - 1)), size:CGSizeFromString(aString.substring(comma + 2, aString.length)) };
}

function CGPointFromEvent(anEvent)
{
    return CGPointMake(anEvent.clientX, anEvent.clientY);
}

/*!
    Combines two insets by adding their individual elements and returns the result.

    @group CGInset
*/
function CGInsetUnion(lhsInset, rhsInset)
{
    return CGInsetMake(lhsInset.top + rhsInset.top,
                       lhsInset.right + rhsInset.right,
                       lhsInset.bottom + rhsInset.bottom,
                       lhsInset.left + rhsInset.left);
}

/*!
    Subtract one inset from another by subtracting their individual elements and returns the result.

    @group CGInset
*/
function CGInsetDifference(lhsInset, rhsInset)
{
    return CGInsetMake(lhsInset.top - rhsInset.top,
                       lhsInset.right - rhsInset.right,
                       lhsInset.bottom - rhsInset.bottom,
                       lhsInset.left - rhsInset.left);
}

function CGInsetFromString(aString)
{
    var numbers = aString.substr(1, aString.length - 2).split(',');

    return CGInsetMake(parseFloat(numbers[0]), parseFloat(numbers[1]), parseFloat(numbers[2]), parseFloat(numbers[3]));
}

CGInsetFromCPString = CGInsetFromString;

function CPStringFromCGInset(anInset)
{
    return "{" + anInset.top + ", " + anInset.left + ", " + anInset.bottom + ", " + anInset.right + "}";
}

/*!
    When drawing lines in a canvas, they have to be aligned to half the stroke width.
    This function aligns an x or y coordinate so that drawing a line along the opposite
    coordinate will draw correctly.
*/
function CGAlignStroke(coord, strokeWidth)
{
    return FLOOR(coord) === (coord) ? (coord) + (strokeWidth / 2) : (coord);
}

/*!
    Ensure a coordinate falls exactly on a pixel boundary.
*/
function CGAlignCoordinate(coord)
{
    return FLOOR(coord);
}

/*!
    @}
*/
