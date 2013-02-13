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

@implementation _CPPredicateEditorRowNode : CPObject
{
    _CPPredicateEditorTree                   tree @accessors;
    CPMutableArray                  templateViews @accessors;
    CPMutableArray        copiedTemplateContainer @accessors;
    CPArray                              children @accessors(copy);
}

+ (id)rowNodeFromTree:(id)aTree
{
    return [_CPPredicateEditorRowNode _rowNodeFromTree:aTree withTemplateTable:{}];
}

+ (id)_rowNodeFromTree:(id)aTree withTemplateTable:(id)templateTable
{
    var views,
        copiedContainer;

    var uuid = [[aTree template] UID],
        cachedNode = templateTable[uuid],
        node = [[_CPPredicateEditorRowNode alloc] init];

    [node setTree:aTree];

    if (!cachedNode)
    {
        views = [CPMutableArray array];
        copiedContainer = [CPMutableArray array];
        templateTable[uuid] = node;
    }
    else
    {
        views = [cachedNode templateViews];
        copiedContainer = [cachedNode copiedTemplateContainer];
    }

    [node setTemplateViews:views];
    [node setCopiedTemplateContainer:copiedContainer];

    var nodeChildren = [CPMutableArray array],
        treeChildren = [aTree children],
        count = [treeChildren count];

    for (var i = 0; i < count; i++)
    {
        var treeChild = treeChildren[i],
            child = [_CPPredicateEditorRowNode _rowNodeFromTree:treeChild withTemplateTable:templateTable];

        [nodeChildren addObject:child];
    }

    [node setChildren:nodeChildren];

    return node;
}

- (BOOL)applyTemplate:(id)template withViews:(id)views forOriginalTemplate:(id)originalTemplate
{
    var t = [tree template],
        count = [children count];

    if (t !== template)
    {
        [templateViews setArray:views];
        [copiedTemplateContainer removeAllObjects];
        [copiedTemplateContainer addObject:template];
    }

    for (var i = 0; i < count; i++)
        [children[i] applyTemplate:template withViews:views forOriginalTemplate:originalTemplate];
}

- (BOOL)isEqual:(id)node
{
    if (![node isKindOfClass:[_CPPredicateEditorRowNode class]])
        return NO;

    return (tree === [node tree]);
}

- (void)copyTemplateIfNecessary
{
    if ([copiedTemplateContainer count] === 0)
    {
        var copy = [[tree template] copy];
        [copiedTemplateContainer addObject:copy];
        [templateViews addObjectsFromArray:[copy templateViews]];
    }
}

- (CPView)templateView
{
    [self copyTemplateIfNecessary];
    return [templateViews objectAtIndex:[tree indexIntoTemplate]];
}

- (id)templateForRow
{
    [self copyTemplateIfNecessary];
    return [copiedTemplateContainer lastObject];
}

- (CPString)title
{
    return [tree title];
}

- (id)displayValue
{
    var title = [self title];

    if (title !== nil)
        return title;

    return [self templateView];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<%@ %@ %@ tree:%@ tviews:%@", [self className],[self UID], [self title], [tree UID], [templateViews description]];
}

@end
