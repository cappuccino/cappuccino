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

/*
    Makes a <objj>CPRange</objj>.
    @param location the location for new range
    @param length the length of the new range
    @group CPRange
    @return CPRange the new range object
*/
function CPMakeRange(location, length)
{
    return { location: location, length: length };
}

/*
    Makes a copy of a <objj>CPRange</objj>.
    @param aRange the <objj>CPRange</objj> to copy
    @group CPRange
    @return CPRange the copy of the range
*/
function CPCopyRange(aRange)
{
    return { location: aRange.location, length: aRange.length };
}

/*
    Makes a copy of a <objj>CPRange</objj>.
    @param aRange the <objj>CPRange</objj> to copy
    @group CPRange
    @return CPRange the copy of the range
*/
function CPMakeRangeCopy(aRange)
{
    return { location:aRange.location, length:aRange.length };
}

/*
    Sets a range's <code>length</code> to 0.
    @param aRange the range to empty
    @group CPRange
    @return CPRange the empty range (same as the argument)
*/
function CPEmptyRange(aRange)
{
    return aRange.length == 0;
}

/*
    Finds the range maximum. (<code>location + length</code>)
    @param aRange the range to calculate a maximum from
    @group CPRange
    @return int the range maximum
*/
function CPMaxRange(aRange)
{
    return aRange.location + aRange.length;
}

/*
    Determines if two <objj>CPRange</objj>s are equal.
    @param lhsRange the first <objj>CPRange</objj>
    @param rhsRange the second <objj>CPRange</objj>
    @return BOOL <code>YES</code> if the two <objj>CPRange</objj>s are equal.
*/
function CPEqualRanges(lhsRange, rhsRange)
{
    return ((lhsRange.location == rhsRange.location) && (lhsRange.length == rhsRange.length));
}

/*
    Determines if a number is within a specified <objj>CPRange</objj>.
    @param aLocation the number to check
    @param aRange the <objj>CPRange</objj> to check within
    @group CPRange
    @return BOOL <code>YES</code> if <code>aLocation/code> is within the range
*/
function CPLocationInRange(aLocation, aRange)
{
    return (aLocation >= aRange.location) && (aLocation < CPMaxRange(aRange));
}

/*
    Creates a new range with the minimum <code>location</code> and a <code>length</code> 
    that extends to the maximum <code>length</code>.
    @param lhsRange the first <objj>CPRange</objj>
    @param rhsRange the second <objj>CPRange</objj>
    @group CPRange
    @return CPRange the new <objj>CPRange</objj>
*/
function CPUnionRange(lhsRange, rhsRange)
{
    var location = Math.min(lhsRange.location, rhsRange.location);
   	return CPMakeRange(location, Math.max(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

/*
    Creates a new <objj>CPRange</objj> that spans the common range of two <objj>CPRange</objj>s
    @param lhsRange the first <objj>CPRange</objj>
    @param rhsRange the second <objj>CPRange</objj>
    @group CPRange
    @return CPRange the new <objj>CPRange</objj>
*/
function CPIntersectionRange(lhsRange, rhsRange)
{
    if(CPMaxRange(lhsRange) < rhsRange.location || CPMaxRange(rhsRange) < lhsRange.location)
        return CPMakeRange(0, 0);
	
    var location = Math.max(lhsRange.location, rhsRange.location);
    return CPMakeRange(location, Math.min(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

/*
    Returns a string describing a range.
    @param aRange the range to describe
    @group CPRange
    @return CPString a describing string
*/
function CPStringFromRange(aRange)
{
    return "{" + aRange.location + ", " + aRange.length + "}";
}

/*
    Creates a <objj>CPRange</objj> from the contents of a <objj>CPString</objj>.
    @param aString the string to create a <objj>CPRange</objj> from
    @group CPRange
    @return CPRange the new range
*/
function CPRangeFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { location:parseInt(aString.substr(1, comma - 1)), length:parseInt(aString.substring(comma + 1, aString.length)) };
}
