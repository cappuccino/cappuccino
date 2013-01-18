/*
 * CPCountedSet.j
 * Foundation
 *
 * Created by .
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

@import "CPObject.j"
@import "_CPConcreteMutableSet.j"

/*!
    @class CPCountedSet
    @ingroup foundation
    @brief An mutable collection which may contain a specific object
    numerous times.
*/
@implementation CPCountedSet : _CPConcreteMutableSet
{
    Object  _counts;
}

- (void)addObject:(id)anObject
{
    if (!_counts)
        _counts = {};

    [super addObject:anObject];

    var UID = [anObject UID];

    if (_counts[UID] === undefined)
        _counts[UID] = 1;
    else
        ++_counts[UID];
}

- (void)removeObject:(id)anObject
{
    if (!_counts)
        return;

    var UID = [anObject UID];

    if (_counts[UID] === undefined)
        return;

    else
    {
        --_counts[UID];

        if (_counts[UID] === 0)
        {
            delete _counts[UID];
            [super removeObject:anObject];
        }
    }
}

- (void)removeAllObjects
{
    [super removeAllObjects];
    _counts = {};
}

/*
    Returns the number of times anObject appears in the receiver.
    @param anObject The object to check the count for.
*/
- (unsigned)countForObject:(id)anObject
{
    if (!_counts)
        _counts = {};

    var UID = [anObject UID];

    if (_counts[UID] === undefined)
        return 0;

    return _counts[UID];
}


/*

Eventually we should see what these are supposed to do, and then do that.

- (void)intersectSet:(CPSet)set

- (void)minusSet:(CPSet)set

- (void)unionSet:(CPSet)set

*/

@end
