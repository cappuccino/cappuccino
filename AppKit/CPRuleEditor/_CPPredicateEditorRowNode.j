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

- (BOOL)applyTemplate:(id)template withViews:(id)views forOriginalTemplate:(id)arg3
{
    return YES; // not in use
}

+ (id)rowNodeFromTree:(id)aTree
{
    return [_CPPredicateEditorRowNode _rowNodeFromTree:aTree withTemplate:[aTree template]];
}

+ (id)_rowNodeFromTree:(id)aTree withTemplate:(id)template
{
    var nodeChildren = [CPArray array],
        treeChildren = [aTree children],
        count = [treeChildren count];

    for (var i = 0; i < count; i++)
    {
        var childnode = [self _rowNodeFromTree:treeChildren[i] withTemplate:template];
        [nodeChildren addObject:childnode];
    }

    var node = [_CPPredicateEditorRowNode new];
    [node setTree:aTree];
    [node setCopiedTemplateContainer:[CPMutableArray arrayWithObject:template]];
    [node setTemplateViews:[template templateViews]];
    [node setChildren:nodeChildren];

    return node;
}


- (BOOL)isEqual:(id)node
{
    return (self === node || tree === [node tree]);
}

- (void)copyTemplateIfNecessary
{
    if ([[self templateForRow] rightIsWildcard])
    {
        var copy = [[tree template] copy];
        [self setCopiedTemplateContainer:[CPMutableArray arrayWithObject:copy]];
        [self setTemplateViews:[copy templateViews]];
    }
}

- (CPView)templateView
{
    return [templateViews objectAtIndex:[tree indexIntoTemplate]];
}

- (id)templateForRow
{
    return [copiedTemplateContainer lastObject];
}

- (CPString)title
{
    return [tree title];
}

- (id)displayValue
{
    var title = [self title];
    if (title == nil)
        return [self templateView];

    return title;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<%@ %@ %@ %p>", [self className], [self title], [self displayValue], self];
}

@end