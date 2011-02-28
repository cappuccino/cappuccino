/*
 * CPNull.j
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

@import "CPObject.j"

var CPNullSharedNull = nil;

/*!
    @class CPNull
    @ingroup foundation
    @brief An object representation of \c nil.

    This class is used as an object representation of \c nil. This is handy when a collection
    only accepts objects as values, but you would like a \c nil representation in there.
*/
@implementation CPNull : CPObject
{
}

/*+ (id)alloc
{
    if (CPNullSharedNull)
        return CPNullSharedNull;

    return [super alloc];
}*/

/*!
    Returns the singleton instance of the CPNull
    object. While CPNull and \c nil should
    be <i>interpreted</i> as the same, they are not equal ('==').
*/
+ (CPNull)null
{
    if (!CPNullSharedNull)
        CPNullSharedNull = [[CPNull alloc] init];

    return CPNullSharedNull;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    return [anObject isKindOfClass:[CPNull class]];
}

/*!
    Returns CPNull null.
    @param aCoder the coder from which to do nothing
    @return [CPNull null]
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [CPNull null];
}

/*!
    Writes out nothing to the specified coder.
    @param aCoder the coder to which nothing will
    be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
}

@end
