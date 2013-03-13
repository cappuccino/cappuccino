/*
 * CPRange.j
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

/*!
    @addtogroup foundation
    @{
*/

/*!
    Makes a CPRange.
    @param location the location for new range
    @param length the length of the new range
    @group CPRange
    @return CPRange the new range object
*/
function CPMakeRange(location, length)
{
    return { location:location, length:length };
}

/*!
    Makes a copy of a CPRange.
    @param aRange the CPRange to copy
    @group CPRange
    @return CPRange the copy of the range
*/
function CPMakeRangeCopy(aRange)
{
    return { location:aRange.location, length:aRange.length };
}

/*!
    Determines if a range is empty \c length is 0.
    @param aRange the range to test
    @group CPRange
    @return YES if the range is empty
*/
function CPEmptyRange(aRange)
{
    return aRange.length === 0;
}

/*!
    Finds the range maximum. (\c location + length)
    @param aRange the range to calculate a maximum from
    @group CPRange
    @return int the range maximum
*/
function CPMaxRange(aRange)
{
    return aRange.location + aRange.length;
}

/*!
    Determines if two CPRanges are equal.
    @param lhsRange the first CPRange
    @param rhsRange the second CPRange
    @return BOOL \c YES if the two CPRanges are equal.
*/
function CPEqualRanges(lhsRange, rhsRange)
{
    return ((lhsRange.location === rhsRange.location) && (lhsRange.length === rhsRange.length));
}

/*!
    Determines if a number is within a specified CPRange.
    @param aLocation the number to check
    @param aRange the CPRange to check within
    @group CPRange
    @return BOOL \c YES if \c aLocation is within the range
*/
function CPLocationInRange(aLocation, aRange)
{
    return ((aLocation >= aRange.location) && (aLocation < CPMaxRange(aRange)));
}

/*!
    Creates a new range with the minimum \c location and a \c length
    that extends to the maximum \c length.
    @param lhsRange the first CPRange
    @param rhsRange the second CPRange
    @group CPRange
    @return CPRange the new CPRange
*/
function CPUnionRange(lhsRange, rhsRange)
{
    var location = MIN(lhsRange.location, rhsRange.location);

    return CPMakeRange(location, MAX(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

/*!
    Creates a new CPRange that spans the common range of two CPRanges
    @param lhsRange the first CPRange
    @param rhsRange the second CPRange
    @group CPRange
    @return CPRange the new CPRange
*/
function CPIntersectionRange(lhsRange, rhsRange)
{
    if (CPMaxRange(lhsRange) < rhsRange.location || CPMaxRange(rhsRange) < lhsRange.location)
        return CPMakeRange(0, 0);

    var location = MAX(lhsRange.location, rhsRange.location);

    return CPMakeRange(location, MIN(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

/*!
    Checks if a range completely contains another range. In other words, if one range is the "super range" of another.
    @param lhsRange the containing range
    @param rhsRange the range we are testing to see if lhsRange contains it
    @group CPRange
    @return BOOL whether or not lhsRange completely contains rhsRange
*/
function CPRangeInRange(lhsRange, rhsRange)
{
    return (lhsRange.location <= rhsRange.location && CPMaxRange(lhsRange) >= CPMaxRange(rhsRange));
}

/*!
    Returns a string describing a range.
    @param aRange the range to describe
    @group CPRange
    @return CPString a describing string
*/
function CPStringFromRange(aRange)
{
    return "{" + aRange.location + ", " + aRange.length + "}";
}

/*!
    Creates a CPRange from the contents of a CPString.
    @param aString the string to create a CPRange from
    @group CPRange
    @return CPRange the new range
*/
function CPRangeFromString(aString)
{
    var comma = aString.indexOf(',');

    return { location:parseInt(aString.substr(1, comma - 1)), length:parseInt(aString.substring(comma + 1, aString.length)) };
}

/*!
    @}
*/

