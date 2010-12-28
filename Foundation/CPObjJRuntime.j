/*
 * CPObjJRuntime.j
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

function CPStringFromSelector(aSelector)
{
    return sel_getName(aSelector);
}

function CPSelectorFromString(aSelectorName)
{
    return sel_registerName(aSelectorName);
}

function CPClassFromString(aClassName)
{
    return objj_getClass(aClassName);
}

function CPStringFromClass(aClass)
{
    return class_getName(aClass);
}

/*!
    The left operand is smaller than the right.
    @global
    @group CPComparisonResult
*/
CPOrderedAscending      = -1;
/*!
    The left and right operands are equal.
    @global
    @group CPComparisonResult
*/
CPOrderedSame           =  0;
/*!
    The left operand is greater than the right.
    @global
    @group CPComparisonResult
*/
CPOrderedDescending     =  1;

CPNotFound              = -1;
