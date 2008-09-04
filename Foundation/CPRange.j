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

function CPMakeRange(location, length)
{
    return { location: location, length: length };
}

function CPCopyRange(aRange)
{
    return { location: aRange.location, length: aRange.length };
}

function CPMakeRangeCopy(aRange)
{
    return { location:aRange.location, length:aRange.length };
}

function CPEmptyRange(aRange)
{
    return aRange.length == 0;
}

function CPMaxRange(aRange)
{
    return aRange.location + aRange.length;
}

function CPEqualRanges(lhsRange, rhsRange)
{
    return ((lhsRange.location == rhsRange.location) && (lhsRange.length == rhsRange.length));
}

function CPLocationInRange(aLocation, aRange)
{
    return (aLocation >= aRange.location) && (aLocation < CPMaxRange(aRange));
}

function CPUnionRange(lhsRange, rhsRange)
{
    var location = Math.min(lhsRange.location, rhsRange.location);
   	return CPMakeRange(location, Math.max(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

function CPIntersectionRange(lhsRange, rhsRange)
{
    if(CPMaxRange(lhsRange) < rhsRange.location || CPMaxRange(rhsRange) < lhsRange.location)
        return CPMakeRange(0, 0);
	
    var location = Math.max(lhsRange.location, rhsRange.location);
    return CPMakeRange(location, Math.min(CPMaxRange(lhsRange), CPMaxRange(rhsRange)) - location);
}

function CPStringFromRange(aRange)
{
    return "{" + aRange.location + ", " + aRange.length + "}";
}

function CPRangeFromString(aString)
{
    var comma = aString.indexOf(',');
    
    return { location:parseInt(aString.substr(1, comma - 1)), length:parseInt(aString.substring(comma + 1, aString.length)) };
}
