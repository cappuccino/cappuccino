/*
 * CPEnumerator.j
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

/*! 
    
*/

/*! 
    @class CPEnumerator
    @ingroup foundation
    @brief Defines an interface for enumerators.
    
    CPEnumerator is a superclass (with useless method bodies)
    that defines an interface for subclasses to follow. The purpose of an
    enumerator is to be a convenient system for traversing over the elements
    of a collection of objects.
*/
@implementation CPEnumerator : CPObject

/*!
    Returns the next object in the collection.
    No particular ordering is guaranteed.
*/
- (id)nextObject
{
    return nil;
}

/*!
    Returns all objects in the collection in an array.
    No particular ordering is guaranteed.
*/
- (CPArray)allObjects
{
    return [];
}

@end
