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

/*!
  Creates a copy of a specified point and returns the copy
  @group CGPoint
  @param the point to be copied
  @return CGPoint the copy of the provided CGPoint
  */
function CPPointCreateCopy(aPoint)
{
    return { x: aPoint.x, y: aPoint.y };
}

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
    Makes a CGRect with an origin and size equal to <code>aRect</code> less the <code>dX/dY</code> insets specified.
    @param dX the size of the inset in the x-axis
    @param dY the size of the inset in the y-axis
    @group CGRect
    @return CGRect a rectangle like <code>aRect</code> with an inset
*/
function CPRectInset(aRect, dX, dY)
{
    return CPRectMake(  aRect.origin.x + dX, aRect.origin.y + dY, 
                        aRect.size.width - 2 * dX, aRect.size.height - 2*dY);
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
    Returns the intersection of the two provided rectangles as a new rectangle
    @group CGRect
    @param lhsRect the first rectangle used for calculation
    @param rhsRect the second rectangle used for calculation
    @return CGRect the intersection of the two rectangles
*/
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
    Creates a new rectangle with its origin offset by <code>dX</code> and <code>dY</code>.
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
    Returns the smallest rectangle that can contain the two argument <code>CGRect</code>s.
    @group CGRect
    @param lhsRect the first CGRect to use for the union calculation
    @param rhsRect the second CGRect to use for the union calculation
    @return CGRect the union rectangle
*/
function CPRectUnion(lhsRect, rhsRect)
{
    var minX = Math.min(CPRectGetMinX(lhsRect), CPRectGetMinX(rhsRect)),
        minY = Math.min(CPRectGetMinY(lhsRect), CPRectGetMinY(rhsRect)),
        maxX = Math.max(CPRectGetMaxX(lhsRect), CPRectGetMaxX(rhsRect)),
        maxY = Math.max(CPRectGetMaxY(lhsRect), CPRectGetMaxY(rhsRect));
    
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
    Returns <code>YES</code> if the <objj>CGRect</objj>, <code>aRect</code>, contains
    the <objj>CGPoint</objj>, <code>aPoint</code>.
    @param aRect the rectangle to test with
    @param aPoint the point to test with
    @group CGRect
    @return BOOL <code>YES</code> if the rectangle contains the point, <code>NO</code> otherwise.
*/
function CPRectContainsPoint(aRect, aPoint)
{
    return  aPoint.x >= CPRectGetMinX(aRect) &&
            aPoint.y >= CPRectGetMinY(aRect) &&
   			aPoint.x < CPRectGetMaxX(aRect) &&
   			aPoint.y < CPRectGetMaxY(aRect);
}

/*!
    Returns a <code>BOOL</code> indicating whether <objj>CGRect</objj> <code>possibleOuter</code>
    contains <objj>CGRect</objj> <code>possibleInner</code>.
    @group CGRect
    @param possibleOuter the <objj>CGRect</objj> to test if <code>possibleInner</code> is inside of
    @param possibleInner the <objj>CGRect</objj> to test if it fits inside <code>possibleOuter</code>.
    @return BOOL <code>YES</code> if <code>possibleInner</code> fits inside <code>possibleOuter</code>.
*/
function CPRectContainsRect(lhsRect, rhsRect)
{
    return CPRectEqualToRect(CPUnionRect(lhsRect, rhsRect), rhsRect);
}

/*!
    Tests whether the two <objj>CGPoint</objj>s are equal to each other by comparing their
    <code>x</code> and <code>y</code> members.
    @group @CGPoint
    @param lhsPoint the first <objj>CGPoint</objj> to check
    @param rhsPoint the second <objj>CGPoint</objj> to check
    @return BOOL <code>YES</code> if the two points have the same x's, and the same y's.
*/
function CPPointEqualToPoint(lhsPoint, rhsPoint)
{
    return lhsPoint.x == rhsPoint.x && lhsPoint.y == rhsPoint.y;
}

/*!
    Test whether the two <objj>CGRect</objj>s have the same origin and size
    @group CGRect
    @param lhsRect the first <objj>CGRect</objj> to compare
    @param rhsRect the second <objj>CGRect</objj> to compare
    @return BOOL <code>YES</code> if the two rectangles have the same origin and size. <code>NO</code>, otherwise.
*/
function CPRectEqualToRect(lhsRect, rhsRect)
{
    return  CPPointEqualToPoint(lhsRect.origin, rhsRect.origin) && 
            CPSizeEqualToSize(lhsRect.size, rhsRect.size);
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetHeight(aRect)
{
    return aRect.size.height;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetMaxX(aRect)
{
    return aRect.origin.x + aRect.size.width;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetMaxY(aRect)
{
    return aRect.origin.y + aRect.size.height;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return float
*/
function CPRectGetMidX(aRect)
{
    return aRect.origin.x + (aRect.size.width) / 2.0;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return float
*/
function CPRectGetMidY(aRect)
{
    return aRect.origin.y + (aRect.size.height) / 2.0;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetMinX(aRect)
{
    return aRect.origin.x;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetMinY(aRect)
{
    return aRect.origin.y;
}

/*!
    @group CGRect
    @param aRect a <objj>CGRect</objj>
    @return int
*/
function CPRectGetWidth(aRect)
{
    return aRect.size.width;
}

/*!
    Returns <code>YES</code> if the two rectangles intersect
    @group CGRect
    @param lhsRect the first <objj>CGRect</objj>
    @param rhsRect the second <objj>CGRect</objj>
    @return BOOL <code>YES</code> if the two rectangles have any common spaces, and <code>NO</code>, otherwise.
*/
function CPRectIntersectsRect(lhsRect, rhsRect)
{
    return !CPRectIsEmpty(CPRectIntersection(lhsRect, rhsRect));
}

/*!
    Returns <code>YES</code> if the <objj>CGRect</objj> has no area.
    The test is performed by checking if the width and height are both zero.
    @group CGRect
    @param aRect the <objj>CGRect</objj> to test
    @return BOOL <code>YES</code> if the <objj>CGRect</objj> has no area, and <code>NO</code>, otherwise.
*/
function CPRectIsEmpty(aRect)
{
    return aRect.size.width <= 0.0 || aRect.size.height <= 0.0;
}

/*!
    Returns <code>YES</code> if the <objj>CGRect</objj> has no area.
    The test is performed by checking if the width and height are both zero.
    @group CGRect
    @return BOOL <code>YES</code> if the <objj>CGRect</objj> has no area, and <code>NO</code>, otherwise.
*/
function CPRectIsNull(aRect)
{
    return aRect.size.width <= 0.0 || aRect.size.height <= 0.0;
}

/*!
    Returns <code>YES</code> if the two <objj>CGSize</objj>s are identical.
    @group CGSize
    @param lhsSize the first <objj>CGSize</objj> to compare
    @param rhsSize the second <objj>CGSize</objj> to compare
    @return BOOL <code>YES</code> if the two sizes are identical. <code>NO</code>, otherwise.
*/
function CPSizeEqualToSize(lhsSize, rhsSize)
{
    return lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height;
}

/*!
    Returns a human readable string of the provided <objj>CGPoint</objj>.
    @group CGPoint
    @param aPoint the point to represent
    @return CGPoint a string representation of the <objj>CGPoint</objj>
*/
function CPStringFromPoint(aPoint)
{
    return "{" + aPoint.x + ", " + aPoint.y + "}";
}

/*!
    Returns a human readable string of the provided <objj>CGSize</objj>.
    @group CGSize
    @param aSize the size to represent
    @return CGSize a string representation of the <objj>CGSize</objj>
*/
function CPStringFromSize(aSize)
{
    return "{" + aSize.width + ", " + aSize.height + "}";
}

/*!
    Returns a human readable string of the provided <objj>CGRect</objj>.
    @group CGRect
    @param aRect the rectangle to represent
    @return CGString the string representation of the rectangle
*/
function CPStringFromRect(aRect)
{
    return "{" + CPStringFromPoint(aRect.origin) + ", " + CPStringFromSize(aRect.size) + "}";
}

/*!
    Returns a <objj>CGPoint</objj> from a string with a comma separated pair of integers.
    @group CGPoint
    @param aString a string containing two comma separated integers
    @return CGPoint the point object created from the string
*/
function CPPointFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { x:parseInt(aString.substr(1, comma - 1)), y:parseInt(aString.substring(comma + 1, aString.length)) };
}

/*!
    Returns a <objj>CGSize</objj> from a string containing a pair of comma separated integers.
    @group CGSize
    @param aString a string containing two comma separated integers
    @return CGSize the size object created from the string
*/
function CPSizeFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { width:parseInt(aString.substr(1, comma - 1)), height:parseInt(aString.substring(comma + 1, aString.length)) };
}

/*!
    Returns a <objj>CGRect</objj> created from a string.
    @group CGRect
    @param aString a string in the form generated by <code>CPStringFromRect</code>
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
    Returns a zero sized <objj>CGSize</objj>.
    @group CGSize
    @return CGSize a size object with zeros for <code>width</code> and <code>height</code>
*/
function CPSizeMakeZero()
{
    return CPSizeMake(0, 0);
}

/*!
    Returns a rectangle at origin <code>(0,0)</code> and size of <code>(0,0)</code>.
    @group CGRect
    @return CGRect a zeroed out CGRect
*/
function CPRectMakeZero()
{
    return CPRectMake(0, 0, 0, 0);
}

/*!
    Returns a point located at <code>(0, 0)</code>.
    @group CGPoint
    @return CGPoint a point located at <code>(0, 0)</code>
*/
function CPPointMakeZero()
{
    return CPPointMake(0, 0, 0);
}
