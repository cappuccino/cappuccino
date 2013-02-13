/*
 * CPGeometry.j
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

@import "_CGGeometry.j"

CPMinXEdge = 0;
CPMinYEdge = 1;
CPMaxXEdge = 2;
CPMaxYEdge = 3;

/*!
    Makes a CGPoint object out of two numbers provided as arguments
    @group CGPoint
    @param x the x-coordinate of the CGPoint
    @param y the y-coordinate of the CGPoint
    @return CGPoint a CGPoint with an X and Y coordinate equal to the function arguments
*/
CPMakePoint = CGPointMake;

/*!
    Creates and returns a new CGSize object from the provided dimensions.
    @group CGSize
    @param width the width for the new CGSize
    @param height the height for the new CGSize
    @return CGSize the new CGSize
*/
CPMakeSize = CGSizeMake;

/*!
    Returns a CGRect made of the specified arguments
    @group CGRect
    @param x the x-coordinate of the rectangle's origin
    @param y the y-coordinate of the rectangle's origin
    @param width the width of the new rectangle
    @param height the height of the new rectangle
    @return CGRect the new rectangle
*/
CPMakeRect = CGRectMake;

/*!
    Creates a copy of a specified point and returns the copy
    @group CGPoint
    @param the point to be copied
    @return CGPoint the copy of the provided CGPoint
*/
CPPointCreateCopy = CGPointMakeCopy;

/*!
    Tests whether the two CGPoints are equal to each other by comparing their
    \c x and \c y members.
    @group @CGPoint
    @param lhsPoint the first CGPoint to check
    @param rhsPoint the second CGPoint to check
    @return BOOL \c YES if the two points have the same x's, and the same y's.
*/
CPPointEqualToPoint = CGPointEqualToPoint;

/*!
    Tests whether the CGPoint is contained by the CGRect.
    @group CGPoint
    @param aPoint the CGPoint to check
    @param aRect the CGRect to check
    @return BOOL \c YES if the rect contains the point.
*/
CPPointInRect = function(aPoint, aRect)
{
    return CGRectContainsPoint(aRect, aPoint)
};

/*!
    Test whether the two CGRects have the same origin and size
    @group CGRect
    @param lhsRect the first CGRect to compare
    @param rhsRect the second CGRect to compare
    @return BOOL \c YES if the two rectangles have the same origin and size. \c NO, otherwise.
*/
CPRectEqualToRect = CGRectEqualToRect;

/*!
    Returns \c YES if the CGRect has no area.
    The test is performed by checking if the width and height are both zero.
    @group CGRect
    @param aRect the CGRect to test
    @return BOOL \c YES if the CGRect has no area, and \c NO, otherwise.
*/
CPRectIsEmpty = CGRectIsEmpty;

/*!
    Returns a \c BOOL indicating whether CGRect \c possibleOuter
    contains CGRect \c possibleInner.
    @group CGRect
    @param possibleOuter the CGRect to test if \c possibleInner is inside of
    @param possibleInner the CGRect to test if it fits inside \c possibleOuter.
    @return BOOL \c YES if \c possibleInner fits inside \c possibleOuter.
*/
CPRectContainsRect = CGRectContainsRect;

/*!
    Returns the intersection of the two provided rectangles as a new rectangle
    @group CGRect
    @param lhsRect the first rectangle used for calculation
    @param rhsRect the second rectangle used for calculation
    @return CGRect the intersection of the two rectangles
*/
CPRectIntersection = CGRectIntersection;

/*!
  Makes a CGPoint object out of two numbers provided as arguments
  @group CGPoint
  @param x the x-coordinate of the CGPoint
  @param y the y-coordinate of the CGPoint
  @return CGPoint a CGPoint with an X and Y coordinate equal to the function arguments
*/
CPPointMake = CGPointMake;

/*!
    Makes a CGRect with an origin and size equal to \c aRect less the \c dX/dY insets specified.
    @param dX the size of the inset in the x-axis
    @param dY the size of the inset in the y-axis
    @group CGRect
    @return CGRect a rectangle like \c aRect with an inset
*/
CPRectInset = CGRectInset;

/*!
    @group CGRect
    @ignore
    @return void
    @deprecated
*/
CPRectIntegral = CGRectIntegral;

/*!
    Creates a copy of the provided rectangle
    @group CGRect
    @param aRect the CGRect that will be copied
    @return CGRect the rectangle copy
*/
CPRectCreateCopy = CGRectCreateCopy;

/*!
    Returns a CGRect made of the specified arguments
    @group CGRect
    @param x the x-coordinate of the rectangle's origin
    @param y the y-coordinate of the rectangle's origin
    @param width the width of the new rectangle
    @param height the height of the new rectangle
    @return CGRect the new rectangle
*/
CPRectMake = CGRectMake;

/*!
    Creates a new rectangle with its origin offset by \c dX and \c dY.
    @group CGRect
    @param aRect the rectangle to copy the origin and size from
    @param dX the amount added to the x-size of the new rectangle
    @param dY the amount added to the y-size of the new rectangle
    @return CGRect the new rectangle with modified size
*/
CPRectOffset = CGRectOffset;

/*!
    @group CGRect
    @param aRect a CGRect
    @return CGRect
*/
CPRectStandardize = CGRectStandardize;

/*!
    Returns the smallest rectangle that can contain the two argument \c CGRects.
    @group CGRect
    @param lhsRect the first CGRect to use for the union calculation
    @param rhsRect the second CGRect to use for the union calculation
    @return CGRect the union rectangle
*/
CPRectUnion = CGRectUnion;

/*!
    Creates and returns a copy of the provided CGSize
    @group CGSize
    @param aSize the CGSize to copy
    @return CGSize the copy of the CGSize
*/
CPSizeCreateCopy = CGSizeCreateCopy;

/*!
    Creates and returns a new CGSize object from the provided dimensions.
    @group CGSize
    @param width the width for the new CGSize
    @param height the height for the new CGSize
    @return CGSize the new CGSize
*/
CPSizeMake = CGSizeMake;

/*!
    Returns \c YES if the CGRect, \c aRect, contains
    the CGPoint, \c aPoint.
    @param aRect the rectangle to test with
    @param aPoint the point to test with
    @group CGRect
    @return BOOL \c YES if the rectangle contains the point, \c NO otherwise.
*/
CPRectContainsPoint = CGRectContainsPoint;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetHeight = CGRectGetHeight;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetMaxX = CGRectGetMaxX;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetMaxY = CGRectGetMaxY;

/*!
    @group CGRect
    @param aRect a CGRect
    @return float
*/
CPRectGetMidX = CGRectGetMidX;

/*!
    @group CGRect
    @param aRect a CGRect
    @return float
*/
CPRectGetMidY = CGRectGetMidY;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetMinX = CGRectGetMinX;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetMinY = CGRectGetMinY;

/*!
    @group CGRect
    @param aRect a CGRect
    @return int
*/
CPRectGetWidth = CGRectGetWidth;

/*!
    Returns \c YES if the two rectangles intersect
    @group CGRect
    @param lhsRect the first CGRect
    @param rhsRect the second CGRect
    @return BOOL \c YES if the two rectangles have any common spaces, and \c NO, otherwise.
*/
CPRectIntersectsRect = CGRectIntersectsRect;

/*!
    Returns \c YES if the CGRect has no area.
    The test is performed by checking if the width and height are both zero.
    @group CGRect
    @return BOOL \c YES if the CGRect has no area, and \c NO, otherwise.
*/
CPRectIsNull = CGRectIsNull;

/*!
    Creates two rectangles -- slice and rem -- from inRect, by dividing inRect
    with a line that's parallel to the side of inRect specified by edge.
    The size of slice is determined by amount, which specifies the distance from edge.

    slice and rem must not be NULL.

    @group CGRect
*/
CPDivideRect = CGRectDivide;

/*!
    Returns \c YES if the two CGSizes are identical.
    @group CGSize
    @param lhsSize the first CGSize to compare
    @param rhsSize the second CGSize to compare
    @return BOOL \c YES if the two sizes are identical. \c NO, otherwise.
*/
CPSizeEqualToSize = CGSizeEqualToSize;

/*!
    Returns a human readable string of the provided CGPoint.
    @group CGPoint
    @param aPoint the point to represent
    @return CGPoint a string representation of the CGPoint
*/
CPStringFromPoint = CGStringFromPoint;

/*!
    Returns a human readable string of the provided CGSize.
    @group CGSize
    @param aSize the size to represent
    @return CGSize a string representation of the CGSize
*/
CPStringFromSize = CGStringFromSize;

/*!
    Returns a human readable string of the provided CGRect.
    @group CGRect
    @param aRect the rectangle to represent
    @return CGString the string representation of the rectangle
*/
CPStringFromRect = CGStringFromRect;

/*!
    Returns a CGPoint from a string with a comma separated pair of integers.
    @group CGPoint
    @param aString a string containing two comma separated integers
    @return CGPoint the point object created from the string
*/
CPPointFromString = CGPointFromString;

/*!
    Returns a CGSize from a string containing a pair of comma separated integers.
    @group CGSize
    @param aString a string containing two comma separated integers
    @return CGSize the size object created from the string
*/
CPSizeFromString = CGSizeFromString;

/*!
    Returns a CGRect created from a string.
    @group CGRect
    @param aString a string in the form generated by \c CPStringFromRect
    @return CGRect the rectangle created from the string
*/
CPRectFromString = CGRectFromString;

/*!
    @group CGPoint
    @param anEvent
    @return CGPoint
*/
CPPointFromEvent = CGPointFromEvent;

/*!
    Returns a zero sized CGSize.
    @group CGSize
    @return CGSize a size object with zeros for \c width and \c height
*/
CPSizeMakeZero = CGSizeMakeZero;

/*!
    Returns a rectangle at origin \c (0,0) and size of \c (0,0).
    @group CGRect
    @return CGRect a zeroed out CGRect
*/
CPRectMakeZero = CGRectMakeZero;

/*!
    Returns a point located at \c (0, 0).
    @group CGPoint
    @return CGPoint a point located at \c (0, 0)
*/
CPPointMakeZero = CGPointMakeZero;
