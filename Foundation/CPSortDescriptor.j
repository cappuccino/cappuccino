/*
 * CPSortDescriptor.j
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

import "CPObject.j"
import "CPObjJRuntime.j"

@implementation CPSortDescriptor : CPObject
{
    CPString    _key;
    SEL         _selector;
    BOOL        _ascending;
}

// Initializing a sort descriptor

- (id)initWithKey:(CPString)aKey ascending:(BOOL)isAscending
{
    return [self initWithKey:aKey ascending:isAscending selector:@selector(compare:)];
}
    
- (id)initWithKey:(CPString)aKey ascending:(BOOL)isAscending selector:(SEL)aSelector
{
    self = [super init];
    
    if (self)
    {
        _key = aKey;
        _ascending = isAscending;
        _selector = aSelector;
    }
    
    return self;
}

// Getting information about a sort descriptor

- (BOOL)ascending
{
    return _ascending;
}

- (CPString)key
{
    return _key;
}

- (SEL)selector
{
    return _selector;
}

// Using sort descriptors

- (CPComparisonResult)compareObject:(id)lhsObject withObject:(id)rhsObject
{
    return (_ascending ? 1 : -1) * [[lhsObject valueForKey:_key] performSelector:_selector withObject:[rhsObject valueForKey:_key]];
}
    
- (id)reversedSortDescriptor
{
    return [[[self class] alloc] initWithKey:_key ascending:!_ascending selector:_selector];
}

@end