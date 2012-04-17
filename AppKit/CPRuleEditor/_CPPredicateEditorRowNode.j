/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

@class _CPPredicateEditorTree;
@implementation _CPPredicateEditorRowNode : CPObject
{
    _CPPredicateEditorTree                   tree @accessors;
    CPMutableArray                  templateViews @accessors;
    CPMutableArray        copiedTemplateContainer @accessors;
    CPArray                              children @accessors(copy);
}

+ (id)rowNodeFromTree:(id)aTree
{
    var mapTable = {};
    return [_CPPredicateEditorRowNode _rowNodeFromTree:aTree withTemplateTable:mapTable];
}

+ (id)_rowNodeFromTree:(id)aTree withTemplateTable:(id)templateTable
{
    var node,
        views,
        copiedContainer;

    node = [[_CPPredicateEditorRowNode alloc] init];
    node.tree = aTree;

    var template = [aTree template],
        uuid = [template UID],
        cachedNode = templateTable[uuid];

    if (cachedNode === nil)
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

    node.templateViews = views;
    node.copiedTemplateContainer = copiedContainer;

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
    var t = [tree template];

    if (t !== template)
    {
        [templateViews setArray:views];
        [copiedTemplateContainer removeAllObjects];
        [copiedTemplateContainer addObject:template];
    }

    var count = [children count];

    for (var i; i < count; i++)
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
        CPLogConsole("COPYING TEMPLATE");
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
