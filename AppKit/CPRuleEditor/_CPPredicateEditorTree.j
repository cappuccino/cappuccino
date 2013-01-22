/*
 * Created by cacaodev@gmail.com.
 * Copyright (c) 2011 Pear, Inc. All rights reserved.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@implementation _CPPredicateEditorTree : CPObject
{
    CPPredicateEditorRowTemplate         template @accessors;
    CPString                                title @accessors(copy);
    CPArray                              children @accessors(copy);
    CPInteger                   indexIntoTemplate @accessors;
    CPInteger                       menuItemIndex @accessors;
}

- (id)copy
{
    var tree = [[_CPPredicateEditorTree alloc] init];
    [tree setTemplate:template];
    [tree setTitle:title];
    [tree setMenuItemIndex:menuItemIndex];
    [tree setIndexIntoTemplate:indexIntoTemplate];
    [tree setChildren:children];

    return tree;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<%@: %p (%@) [%d-%d] T:%p at:%d> [\r%@\r]", [self className], self, title, indexIntoTemplate, menuItemIndex, template, [template rightExpressionAttributeType], children];
}

@end

