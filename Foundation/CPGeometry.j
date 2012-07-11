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

@import "CGGeometry.j"


CPMinXEdge = 0;
CPMinYEdge = 1;
CPMaxXEdge = 2;
CPMaxYEdge = 3;

// FIXME: the rest!
CPMakePoint = CGPointMake;
CPMakeSize = CGSizeMake;
CPMakeRect = CGRectMake;

CPPointCreateCopy = CGPointMakeCopy;

CPPointEqualToPoint = CGPointEqualToPoint;
CPRectEqualToRect = CGRectEqualToRect;

CPRectIsEmpty = CGRectIsEmpty;

CPRectContainsRect = CGRectContainsRect;
CPRectIntersection = CGRectIntersection;

/*!
    @addtogroup appkit
    @{
*/

/*!
  Makes a CGPoint object out of two numbers provided as arguments
  @group CGPoint
  @param x the x-coordinate of the CGPoint
  @param y the y-coordinate of the CGPoint
  @return CGPoint a CGPoint with an X and Y coordinate equal to the function arguments
  */
function CPPointMake(x, y)
{
    return { x: x, y: y };
}

/*!
    Makes a CGRect with an origin and size equal to \c aRect less the \c dX/dY insets specified.
    @param dX the size of the inset in the x-axis
    @param dY the size of the inset in the y-axis
    @group CGRect
    @return CGRect a rectangle like \c aRect with an inset
*/
function CPRectInset(aRect, dX, dY)
{
    return CPRectMake(  aRect.origin.x + dX, aRect.origin.y + dY,
                        aRect.size.width - 2 * dX, aRect.size.height - 2 * dY);
}

/*!
    @group CGRect
    @ignore
    @return void
    @deprecated
*/
function CPRectIntegral(aRect)
{
    // FIXME!!!
    alert("CPRectIntegral unimplemented");
}

/*!
    Creates a copy of the provided rectangle
    @group CGRect
    @param aRect the CGRect that will be copied
    @return CGRect the rectangle copy
*/
function CPRectCreateCopy(aRect)
{
    return { origin: CPPointCreateCopy(aRect.origin), size: CPSizeCreateCopy(aRect.size) };
}

/*!
    Returns a CGRect made of the specified arguments
    @group CGRect
    @param x the x-coordinate of the rectangle's origin
    @param y the y-coordinate of the rectangle's origin
    @param width the width of the new rectangle
    @param height the height of the new rectangle
    @return CGRect the new rectangle
*/
function CPRectMake(x, y, width, height)
{
    return { origin: CPPointMake(x, y), size: CPSizeMake(width, height) };
}

/*!
    Creates a new rectangle with its origin offset by \c dX and \c dY.
    @group CGRect
    @param aRect the rectangle to copy the origin and size from
    @param dX the amount added to the x-size of the new rectangle
    @param dY the amount added to the y-size of the new rectangle
    @return CGRect the new rectangle with modified size
*/
function CPRectOffset(aRect, dX, dY)
{
    return CPRectMake(aRect.origin.x + dX, aRect.origin.y + dY, aRect.size.width, aRect.size.height);
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return CGRect
*/
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

/*!
    Returns the smallest rectangle that can contain the two argument \c CGRects.
    @group CGRect
    @param lhsRect the first CGRect to use for the union calculation
    @param rhsRect the second CGRect to use for the union calculation
    @return CGRect the union rectangle
*/
function CPRectUnion(lhsRect, rhsRect)
{
    var minX = MIN(CPRectGetMinX(lhsRect), CPRectGetMinX(rhsRect)),
        minY = MIN(CPRectGetMinY(lhsRect), CPRectGetMinY(rhsRect)),
        maxX = MAX(CPRectGetMaxX(lhsRect), CPRectGetMaxX(rhsRect)),
        maxY = MAX(CPRectGetMaxY(lhsRect), CPRectGetMaxY(rhsRect));

    return CPRectMake(minX, minY, maxX - minX, maxY - minY);
}

/*!
    Creates and returns a copy of the provided CGSize
    @group CGSize
    @param aSize the CGSize to copy
    @return CGSize the copy of the CGSize
*/
function CPSizeCreateCopy(aSize)
{
    return { width: aSize.width, height: aSize.height };
}

/*!
    Creates and returns a new CGSize object from the provided dimensions.
    @group CGSize
    @param width the width for the new CGSize
    @param height the height for the new CGSize
    @return CGSize the new CGSize
*/
function CPSizeMake(width, height)
{
    return { width: width, height: height };
}

/*!
    Returns \c YES if the CGRect, \c aRect, contains
    the CGPoint, \c aPoint.
    @param aRect the rectangle to test with
    @param aPoint the point to test with
    @group CGRect
    @return BOOL \c YES if the rectangle contains the point, \c NO otherwise.
*/
function CPRectContainsPoint(aRect, aPoint)
{
    return  aPoint.x >= CPRectGetMinX(aRect) &&
            aPoint.y >= CPRectGetMinY(aRect) &&
            aPoint.x < CPRectGetMaxX(aRect) &&
            aPoint.y < CPRectGetMaxY(aRect);
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetHeight(aRect)
{
    return aRect.size.height;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetMaxX(aRect)
{
    return aRect.origin.x + aRect.size.width;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetMaxY(aRect)
{
    return aRect.origin.y + aRect.size.height;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return float
*/
function CPRectGetMidX(aRect)
{
    return aRect.origin.x + (aRect.size.width) / 2.0;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return float
*/
function CPRectGetMidY(aRect)
{
    return aRect.origin.y + (aRect.size.height) / 2.0;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetMinX(aRect)
{
    return aRect.origin.x;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetMinY(aRect)
{
    return aRect.origin.y;
}

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
function CPRectGetWidth(aRect)
{
    return aRect.size.width;
}

/*!
    Returns \c YES if the two rectangles intersect
    @group CGRect
    @param lhsRect the first CGRect
    @param rhsRect the second CGRect
    @return BOOL \c YES if the two rectangles have any common spaces, and \c NO, otherwise.
*/
function CPRectIntersectsRect(lhsRect, rhsRect)
{
    return !CPRectIsEmpty(CPRectIntersection(lhsRect, rhsRect));
}

/*!
    Returns \c YES if the CGRect has no area.
    The test is performed by checking if the width and height are both zero.
    @group CGRect
    @return BOOL \c YES if the CGRect has no area, and \c NO, otherwise.
*/
function CPRectIsNull(aRect)
{
    return aRect.size.width <= 0.0 || aRect.size.height <= 0.0;
}

/*!
    Creates two rectangles -- slice and rem -- from inRect, by dividing inRect
    with a line that's parallel to the side of inRect specified by edge.
    The size of slice is determined by amount, which specifies the distance from edge.

    slice and rem must not be NULL.

    @group CGRect
*/
function CPDivideRect(inRect, slice, rem, amount, edge)
{
    CGRectDivide(inRect, slice, rem, amount, edge);
}

/*!
    Returns \c YES if the two CGSizes are identical.
    @group CGSize
    @param lhsSize the first CGSize to compare
    @param rhsSize the second CGSize to compare
    @return BOOL \c YES if the two sizes are identical. \c NO, otherwise.
*/
function CPSizeEqualToSize(lhsSize, rhsSize)
{
    return lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height;
}

/*!
    Returns a human readable string of the provided CGPoint.
    @group CGPoint
    @param aPoint the point to represent
    @return CGPoint a string representation of the CGPoint
*/
function CPStringFromPoint(aPoint)
{
    return "{" + aPoint.x + ", " + aPoint.y + "}";
}

/*!
    Returns a human readable string of the provided CGSize.
    @group CGSize
    @param aSize the size to represent
    @return CGSize a string representation of the CGSize
*/
function CPStringFromSize(aSize)
{
    return "{" + aSize.width + ", " + aSize.height + "}";
}

/*!
    Returns a human readable string of the provided CGRect.
    @group CGRect
    @param aRect the rectangle to represent
    @return CGString the string representation of the rectangle
*/
function CPStringFromRect(aRect)
{
    return "{" + CPStringFromPoint(aRect.origin) + ", " + CPStringFromSize(aRect.size) + "}";
}

/*!
    Returns a CGPoint from a string with a comma separated pair of integers.
    @group CGPoint
    @param aString a string containing two comma separated integers
    @return CGPoint the point object created from the string
*/
function CPPointFromString(aString)
{
    var comma = aString.indexOf(',');

    return { x:parseFloat(aString.substr(1, comma - 1), 10), y:parseFloat(aString.substring(comma + 1, aString.length), 10) };
}

/*!
    Returns a CGSize from a string containing a pair of comma separated integers.
    @group CGSize
    @param aString a string containing two comma separated integers
    @return CGSize the size object created from the string
*/
function CPSizeFromString(aString)
{
    var comma = aString.indexOf(',');

    return { width:parseFloat(aString.substr(1, comma - 1), 10), height:parseFloat(aString.substring(comma + 1, aString.length), 10) };
}

/*!
    Returns a CGRect created from a string.
    @group CGRect
    @param aString a string in the form generated by \c CPStringFromRect
    @return CGRect the rectangle created from the string
*/
function CPRectFromString(aString)
{
    var comma = aString.indexOf(',', aString.indexOf(',') + 1);

    return { origin:CPPointFromString(aString.substr(1, comma - 1)), size:CPSizeFromString(aString.substring(comma + 2, aString.length)) };
}

/*!
    @group CGPoint
    @param anEvent
    @return CGPoint
*/
function CPPointFromEvent(anEvent)
{
    return CPPointMake(anEvent.clientX, anEvent.clientY, 0);
}

/*!
    Returns a zero sized CGSize.
    @group CGSize
    @return CGSize a size object with zeros for \c width and \c height
*/
function CPSizeMakeZero()
{
    return CPSizeMake(0, 0);
}

/*!
    Returns a rectangle at origin \c (0,0) and size of \c (0,0).
    @group CGRect
    @return CGRect a zeroed out CGRect
*/
function CPRectMakeZero()
{
    return CPRectMake(0, 0, 0, 0);
}

/*!
    Returns a point located at \c (0, 0).
    @group CGPoint
    @return CGPoint a point located at \c (0, 0)
*/
function CPPointMakeZero()
{
    return CPPointMake(0, 0, 0);
}

/*!
    @}
*/
