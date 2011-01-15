/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

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

